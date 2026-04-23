require "spec"
require "../../src/reverse_markdown"

# Integration-test helpers: drive `ReverseMarkdown` end-to-end against
# realistic HTML documents loaded from disk and expose primitives for
# structural assertions on the Markdown output.
#
# The unit specs (`spec/reverse_markdown_spec.cr`) already cover each
# HTML tag in isolation; these integration specs complement them by
# round-tripping a full article-shaped HTML blob through the real
# converter and checking document-level invariants (paragraph
# separation, heading ordering, determinism, no leaked tags).
module IntegrationHelper
  # Converts the given HTML source to Markdown.
  def self.convert(html : String) : String
    ReverseMarkdown.convert(html)
  end

  # Reads a fixture file from `spec/integration/fixtures/` and returns
  # its content as a string.
  def self.fixture(name : String) : String
    File.read(File.join(__DIR__, "fixtures", name))
  end
end
