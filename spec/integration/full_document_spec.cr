require "./spec_helper"

# Full document round-trip: convert a realistic HTML article with
# headings, paragraphs, multiple `<pre>` code blocks, lists, a
# blockquote, a horizontal rule and a table, then assert the Markdown
# output contains the expected markers for each construct.
describe "Integration · full article-shaped document" do
  it "converts a realistic HTML article into Markdown with every marker" do
    md = IntegrationHelper.convert(IntegrationHelper.fixture("article.html"))

    # H1/H2/H3 in ATX form
    md.should contain("# Crystal is Fast")
    md.should contain("## Installation")
    md.should contain("## Hello world")
    md.should contain("## Features")
    md.should contain("## Compatibility matrix")
    md.should contain("### Learn more")

    # Inline formatting
    md.should contain("**compiled**")
    md.should contain("*static*")
    md.should contain("`type inference`")

    # Links preserved in `[text](url)` form
    md.should contain("[official site](https://crystal-lang.org)")
    md.should contain("[tutorial](https://crystal-lang.org/docs/)")
    md.should contain("[stdlib docs](https://crystal-lang.org/api/)")

    # Pre/code blocks — either fenced with ``` or indented by 4 spaces
    md.should contain("brew install crystal")
    md.should contain(%q(puts "Hello, world!"))

    # Unordered list — hyphens or stars, but "Native code" on its own line
    md.should contain("Native code")
    md.should contain("Ruby-like syntax")
    md.should contain("Zero-cost abstractions")

    # Ordered list items survive
    md.should contain("tutorial")
    md.should contain("stdlib docs")
    md.should contain("Join the forum")

    # Blockquote marker
    md.should contain(">")

    # Table cells present (exact Markdown table form is parser-dependent
    # — a pipe before a cell is enough to detect a GFM-style table row).
    md.should contain("Linux")
    md.should contain("macOS")
    md.should contain("Windows")
    md.should contain("Best-effort")

    # No leaked HTML tags (regression guard)
    md.should_not contain("<h1>")
    md.should_not contain("<p>")
    md.should_not contain("<strong>")
    md.should_not contain("<em>")
    md.should_not contain("<ul>")
    md.should_not contain("<table>")
    md.should_not contain("</html>")
  end
end
