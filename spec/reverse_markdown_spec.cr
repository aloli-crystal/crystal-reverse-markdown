require "./spec_helper"

describe ReverseMarkdown do
  describe ".convert" do
    # --- Headings ---

    it "converts h1" do
      ReverseMarkdown.convert("<h1>Title</h1>").should eq "# Title\n"
    end

    it "converts h2" do
      ReverseMarkdown.convert("<h2>Title</h2>").should eq "## Title\n"
    end

    it "converts h3" do
      ReverseMarkdown.convert("<h3>Title</h3>").should eq "### Title\n"
    end

    it "converts h4" do
      ReverseMarkdown.convert("<h4>Title</h4>").should eq "#### Title\n"
    end

    it "converts h5" do
      ReverseMarkdown.convert("<h5>Title</h5>").should eq "##### Title\n"
    end

    it "converts h6" do
      ReverseMarkdown.convert("<h6>Title</h6>").should eq "###### Title\n"
    end

    it "converts heading with inline formatting" do
      ReverseMarkdown.convert("<h1><strong>Bold</strong> heading</h1>").should eq "# **Bold** heading\n"
    end

    # --- Paragraphs ---

    it "converts paragraph" do
      ReverseMarkdown.convert("<p>Hello world</p>").should eq "Hello world\n"
    end

    it "converts multiple paragraphs" do
      ReverseMarkdown.convert("<p>First</p><p>Second</p>").should eq "First\n\nSecond\n"
    end

    it "skips empty paragraphs" do
      ReverseMarkdown.convert("<p>  </p>").should eq "\n"
    end

    # --- Inline formatting ---

    it "converts strong" do
      ReverseMarkdown.convert("<p><strong>bold</strong></p>").should eq "**bold**\n"
    end

    it "converts b" do
      ReverseMarkdown.convert("<p><b>bold</b></p>").should eq "**bold**\n"
    end

    it "converts em" do
      ReverseMarkdown.convert("<p><em>italic</em></p>").should eq "*italic*\n"
    end

    it "converts i" do
      ReverseMarkdown.convert("<p><i>italic</i></p>").should eq "*italic*\n"
    end

    it "converts del" do
      ReverseMarkdown.convert("<p><del>deleted</del></p>").should eq "~~deleted~~\n"
    end

    it "converts s" do
      ReverseMarkdown.convert("<p><s>strike</s></p>").should eq "~~strike~~\n"
    end

    it "converts inline code" do
      ReverseMarkdown.convert("<p><code>puts</code></p>").should eq "`puts`\n"
    end

    it "converts inline code containing backticks" do
      ReverseMarkdown.convert("<p><code>a`b</code></p>").should eq "`` a`b ``\n"
    end

    it "preserves whitespace around bold" do
      ReverseMarkdown.convert("<p>a <strong>bold</strong> b</p>").should eq "a **bold** b\n"
    end

    it "preserves whitespace around italic" do
      ReverseMarkdown.convert("<p>a <em>italic</em> b</p>").should eq "a *italic* b\n"
    end

    # --- Nested inline ---

    it "converts bold inside italic" do
      ReverseMarkdown.convert("<p><em><strong>text</strong></em></p>").should eq "***text***\n"
    end

    it "converts italic inside bold" do
      ReverseMarkdown.convert("<p><strong><em>text</em></strong></p>").should eq "***text***\n"
    end

    # --- Links ---

    it "converts link" do
      ReverseMarkdown.convert(%(<a href="https://example.com">Example</a>)).should eq "[Example](https://example.com)\n"
    end

    it "converts link with title" do
      ReverseMarkdown.convert(%(<a href="https://example.com" title="Title">Example</a>)).should eq "[Example](https://example.com \"Title\")\n"
    end

    it "converts link with nested formatting" do
      ReverseMarkdown.convert(%(<a href="/url"><strong>Bold link</strong></a>)).should eq "[**Bold link**](/url)\n"
    end

    it "handles link without href" do
      ReverseMarkdown.convert(%(<a>text</a>)).should eq "text\n"
    end

    # --- Images ---

    it "converts image" do
      ReverseMarkdown.convert(%(<img src="image.png" alt="Alt text" />)).should eq "![Alt text](image.png)\n"
    end

    it "converts image with title" do
      ReverseMarkdown.convert(%(<img src="image.png" alt="Alt" title="Title" />)).should eq "![Alt](image.png \"Title\")\n"
    end

    it "converts image without alt" do
      ReverseMarkdown.convert(%(<img src="image.png" />)).should eq "![](image.png)\n"
    end

    # --- Code blocks ---

    it "converts pre/code block" do
      ReverseMarkdown.convert("<pre><code>x = 1</code></pre>").should eq "```\nx = 1\n```\n"
    end

    it "converts pre/code block with language" do
      ReverseMarkdown.convert(%(<pre><code class="language-ruby">puts "hi"</code></pre>)).should eq "```ruby\nputs \"hi\"\n```\n"
    end

    it "converts pre/code with lang- prefix" do
      ReverseMarkdown.convert(%(<pre><code class="lang-python">pass</code></pre>)).should eq "```python\npass\n```\n"
    end

    it "converts pre without code" do
      ReverseMarkdown.convert("<pre>raw text</pre>").should eq "```\nraw text\n```\n"
    end

    # --- Lists ---

    it "converts unordered list" do
      html = "<ul><li>one</li><li>two</li><li>three</li></ul>"
      ReverseMarkdown.convert(html).should eq "- one\n- two\n- three\n"
    end

    it "converts ordered list" do
      html = "<ol><li>one</li><li>two</li><li>three</li></ol>"
      ReverseMarkdown.convert(html).should eq "1. one\n2. two\n3. three\n"
    end

    it "converts nested list" do
      html = "<ul><li>one<ul><li>nested</li></ul></li><li>two</li></ul>"
      result = ReverseMarkdown.convert(html)
      result.should contain("- one")
      result.should contain("    - nested")
      result.should contain("- two")
    end

    it "converts list item with formatting" do
      html = "<ul><li><strong>bold</strong> item</li></ul>"
      ReverseMarkdown.convert(html).should eq "- **bold** item\n"
    end

    # --- Blockquote ---

    it "converts blockquote" do
      ReverseMarkdown.convert("<blockquote><p>Quote</p></blockquote>").should eq "> Quote\n"
    end

    it "converts multi-line blockquote" do
      html = "<blockquote><p>Line 1</p><p>Line 2</p></blockquote>"
      result = ReverseMarkdown.convert(html)
      result.should contain("> Line 1")
      result.should contain("> ")
      result.should contain("> Line 2")
    end

    # --- Horizontal rule ---

    it "converts hr" do
      ReverseMarkdown.convert("<hr>").should eq "---\n"
    end

    it "converts hr self-closing" do
      ReverseMarkdown.convert("<hr />").should eq "---\n"
    end

    # --- Line breaks ---

    it "converts br" do
      ReverseMarkdown.convert("<p>Line 1<br>Line 2</p>").should eq "Line 1  \nLine 2\n"
    end

    # --- Tables ---

    it "converts simple table" do
      html = <<-HTML
        <table>
          <thead><tr><th>A</th><th>B</th></tr></thead>
          <tbody><tr><td>1</td><td>2</td></tr></tbody>
        </table>
      HTML
      result = ReverseMarkdown.convert(html)
      result.should contain("| A | B |")
      result.should contain("| --- | --- |")
      result.should contain("| 1 | 2 |")
    end

    it "converts table without thead" do
      html = "<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>"
      result = ReverseMarkdown.convert(html)
      result.should contain("| a | b |")
      result.should contain("| --- | --- |")
      result.should contain("| c | d |")
    end

    it "converts table with formatting in cells" do
      html = "<table><tr><td><strong>bold</strong></td><td><em>italic</em></td></tr></table>"
      result = ReverseMarkdown.convert(html)
      result.should contain("**bold**")
      result.should contain("*italic*")
    end

    # --- Sup ---

    it "passes through sup" do
      ReverseMarkdown.convert("<p>E=mc<sup>2</sup></p>").should eq "E=mc<sup>2</sup>\n"
    end

    # --- Block wrappers ---

    it "converts div" do
      ReverseMarkdown.convert("<div><p>Content</p></div>").should eq "Content\n"
    end

    it "converts nested divs" do
      ReverseMarkdown.convert("<div><div><p>Deep</p></div></div>").should eq "Deep\n"
    end

    # --- Whitespace handling ---

    it "collapses multiple blank lines" do
      ReverseMarkdown.convert("<p>A</p><p></p><p>B</p>").should eq "A\n\nB\n"
    end

    it "strips leading and trailing whitespace" do
      result = ReverseMarkdown.convert("  <p>text</p>  ")
      result.should eq "text\n"
    end

    it "collapses inline whitespace" do
      ReverseMarkdown.convert("<p>hello    world</p>").should eq "hello world\n"
    end

    # --- Empty input ---

    it "handles empty string" do
      ReverseMarkdown.convert("").should eq ""
    end

    # --- Unknown tags ---

    it "passes through unknown tags by default" do
      result = ReverseMarkdown.convert("<custom>content</custom>")
      result.should contain("<custom>content</custom>")
    end

    it "drops unknown tags when configured" do
      result = ReverseMarkdown.convert("<custom>content</custom>", unknown_tags: :drop)
      result.should_not contain("custom")
    end

    it "raises on unknown tags when configured" do
      expect_raises(ReverseMarkdown::Converter::UnknownTagError) do
        ReverseMarkdown.convert("<custom>content</custom>", unknown_tags: :raise)
      end
    end

    # --- Complex documents ---

    it "converts a complex HTML document" do
      html = <<-HTML
        <html>
        <body>
          <h1>Title</h1>
          <p>A <strong>bold</strong> and <em>italic</em> paragraph.</p>
          <ul>
            <li>Item 1</li>
            <li>Item 2</li>
          </ul>
          <pre><code class="language-crystal">puts "hello"</code></pre>
          <blockquote><p>A quote</p></blockquote>
        </body>
        </html>
      HTML
      result = ReverseMarkdown.convert(html)
      result.should contain("# Title")
      result.should contain("**bold**")
      result.should contain("*italic*")
      result.should contain("- Item 1")
      result.should contain("- Item 2")
      result.should contain("```crystal")
      result.should contain("puts \"hello\"")
      result.should contain("> A quote")
    end
  end
end
