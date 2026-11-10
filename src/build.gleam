import docs/lib/markdown_renderer
import docs/views/not_found
import docs/views/page
import envie
import frontmatter
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/ssg
import simplifile
import tailwind
import tom

const static_dir = "./dist/static"

const docs_url = "https://docs.giolt.com"

/// Crashes on failure so `just build` and `just deploy` stop rather than
/// shipping a half-built site.
pub fn main() -> Nil {
  let assert Ok(_) = build_all() as "Build failed"
  Nil
}

fn build_all() -> Result(Nil, String) {
  use _ <- result.try(build_static())
  use _ <- result.try(build_css())
  Ok(Nil)
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
  |> list.filter(fn(file_path) { string.ends_with(file_path, ".md") })
  |> list.map(fn(file_path) {
    let path =
      string.replace(file_path, directory <> "/", "")
      |> string.replace(".md", "")

    let current_path =
      string.replace(file_path, "./src/content", "")
      |> string.replace(".md", "")
      |> string.replace("index", "")

    let assert Ok(file_contents) = simplifile.read(file_path)

    let extracted = frontmatter.extract(file_contents)

    let assert Ok(parsed) = case extracted.frontmatter {
      option.Some(f) -> tom.parse(f) |> result.replace_error(Nil)
      option.None -> Ok(dict.new())
    }
      as "Failed to parse toml"

    let rendered = markdown_renderer.parse(extracted.content)

    #(
      path,
      page.Page(
        frontmatter: parsed,
        content: rendered.html,
        headings: rendered.headings,
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

fn build_static() -> Result(Nil, String) {
  let root_pages = get_pages("")
  let build =
    get_content_dirs()
    |> list.fold(
      ssg.new(static_dir)
        |> ssg.add_dynamic_route("/", root_pages, page.element),
      fn(build, dir) {
        let pages = get_pages(dir)

        build
        |> ssg.add_dynamic_route(dir, pages, page.element)
      },
    )
    |> ssg.add_static_route("/404", not_found.element())
    |> ssg.add_static_dir("./public")
    |> ssg.build
    |> result.map_error(fn(e) { string.inspect(e) })

  case build {
    Ok(_) -> {
      use _ <- result.try(build_llms_txt())
      io.println("Static pages built successfully")
      Ok(Nil)
    }
    Error(e) -> Error("Failed to build static pages: " <> e)
  }
}

// The agent page's markdown, then a link to every page. The text is read from
// `agents.md`, so the file and the page can't differ, and the index is built
// from the same frontmatter the site renders, so it can't miss a page.
fn build_llms_txt() -> Result(Nil, String) {
  use agents <- result.try(
    simplifile.read("./src/content/agents.md")
    |> result.map_error(fn(e) {
      "Failed to read agents.md: " <> string.inspect(e)
    }),
  )

  let index =
    ["", ..get_content_dirs()]
    |> list.flat_map(fn(dir) { dict.values(get_pages(dir)) })
    |> list.sort(fn(a, b) { string.compare(a.current_path, b.current_path) })
    |> list.map(fn(page) {
      let title =
        tom.get_string(page.frontmatter, ["title"]) |> result.unwrap("Giolt")
      "- [" <> title <> "](" <> docs_url <> page.current_path <> ")"
    })
    |> string.join("\n")

  // Links in the page are site-relative, which a plain-text reader can't resolve.
  let page_text =
    string.trim_end(frontmatter.extract(agents).content)
    |> string.replace("](/", "](" <> docs_url <> "/")

  let text = page_text <> "\n\n## All pages\n\n" <> index <> "\n"

  simplifile.write(static_dir <> "/llms.txt", text)
  |> result.map_error(fn(e) {
    "Failed to write llms.txt: " <> string.inspect(e)
  })
}

fn build_css() -> Result(Nil, String) {
  let is_dev = envie.get_string("NODE_ENV", "production") == "development"

  let result =
    tailwind.install_and_run([
      "-i",
      "./src/docs.css",
      "-o",
      static_dir <> "/docs.css",
      ..case is_dev {
        True -> []
        False -> ["--minify"]
      }
    ])

  case result {
    Ok(_) -> {
      io.println("CSS built successfully")
      Ok(Nil)
    }
    Error(e) -> Error("Failed to build CSS: " <> string.inspect(e))
  }
}
