import docs/lib/djot_renderer
import docs/views/page
import envie
import frontmatter
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/element/html
import lustre/ssg
import simplifile
import tailwind
import tom

pub fn main() {
  build_static()
  build_css()
}

fn get_pages(dir: String) {
  let directory = "./src/content" <> dir

  let assert Ok(files) = simplifile.read_directory(directory)
    as "Failed to get all markdown files"

  files
  |> list.filter_map(fn(entry) {
    let file_path = directory <> "/" <> entry

    case simplifile.is_file(file_path) {
      Ok(True) -> Ok(file_path)
      _ -> Error(Nil)
    }
  })
  |> list.filter(fn(file_path) { string.ends_with(file_path, ".dj") })
  |> list.map(fn(file_path) {
    let path =
      string.replace(file_path, directory <> "/", "")
      |> string.replace(".dj", "")

    let current_path =
      string.replace(file_path, "./src/content", "")
      |> string.replace(".dj", "")
      |> string.replace("index", "")

    let assert Ok(file_contents) = simplifile.read(file_path)

    let extracted = frontmatter.extract(file_contents)

    let assert Ok(parsed) = case extracted.frontmatter {
      option.Some(f) -> tom.parse(f) |> result.replace_error(Nil)
      option.None -> Ok(dict.new())
    }
      as "Failed to parse toml"

    let parsed_content = djot_renderer.parse(extracted.content)

    #(
      path,
      page.Page(
        frontmatter: parsed,
        content: parsed_content,
        current_path: current_path,
      ),
    )
  })
  |> dict.from_list
}

fn get_content_dirs() {
  let assert Ok(entries) = simplifile.read_directory("./src/content")
    as "Failed to get content directories"

  entries
  |> list.filter(fn(entry) {
    let full_path = "./src/content/" <> entry
    case simplifile.is_directory(full_path) {
      Ok(True) -> True
      _ -> False
    }
  })
  |> list.map(fn(dir) { "/" <> dir })
}

fn build_static() {
  let root_pages = get_pages("")
  let build =
    get_content_dirs()
    |> list.fold(
      ssg.new("./dist") |> ssg.add_dynamic_route("/", root_pages, page.element),
      fn(build, dir) {
        let pages = get_pages(dir)

        build
        |> ssg.add_dynamic_route(dir, pages, page.element)
      },
    )
    |> ssg.add_static_route(
      "/404",
      html.html([], [
        html.script([], "window.location.replace(\"/\");"),
      ]),
    )
    |> ssg.add_static_dir("./public")
    |> ssg.build
    |> result.map_error(fn(e) { string.inspect(e) })

  case build {
    Ok(_) -> io.println("Build succeeded!")
    Error(e) -> {
      echo e
      io.println("Build failed!")
    }
  }
}

fn build_css() {
  let is_dev = envie.get_string("NODE_ENV", "production") == "development"

  let result =
    tailwind.install_and_run([
      "-i",
      "./src/docs.css",
      "-o",
      "./dist/docs.css",
      ..case is_dev {
        True -> []
        False -> ["--minify"]
      }
    ])

  case result {
    Ok(_) -> io.println("CSS built successfully")
    Error(e) -> {
      echo e
      panic as "Failed to build CSS"
    }
  }
}
