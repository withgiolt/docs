import docs/views/page
import envie
import frontmatter
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import jot
import lustre/element/html
import lustre/ssg
import simplifile
import tailwind
import tom

pub fn main() {
  build_static()
  build_css()
}

fn get_pages() {
  let assert Ok(files) = simplifile.get_files("./src/content")
    as "Failed to get all markdown files"

  list.map(files, fn(file_path) {
    let path =
      string.replace(file_path, "./src/content/", "")
      |> string.replace(".md", "")

    let current_path =
      file_path
      |> string.replace("./src/content", "")
      |> string.replace(".md", "")
      |> string.replace("index", "")

    let assert Ok(file_contents) = simplifile.read(file_path)
    let extracted = frontmatter.extract(file_contents)

    let assert Ok(parsed) = case extracted.frontmatter {
      option.Some(f) -> tom.parse(f) |> result.replace_error(Nil)
      option.None -> Ok(dict.new())
    }
      as "Failed to parse toml"

    let parsed_content = jot.to_html(extracted.content)

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

fn build_static() {
  let pages = get_pages()

  let build =
    ssg.new("./dist")
    |> ssg.add_dynamic_route("/", pages, page.element)
    |> ssg.add_static_route(
      "/404",
      html.html([], [html.script([], "window.location.replace(\"/\");")]),
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
