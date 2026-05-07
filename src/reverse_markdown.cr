require "xml"
require "./reverse_markdown/converter"

# Converts HTML to Markdown.
#
# Crystal port of the [reverse_markdown](https://rubygems.org/gems/reverse_markdown) Ruby gem.
#
# ```
# ReverseMarkdown.convert("<h1>Hello</h1>")
# # => "# Hello\n\n"
# ```
module ReverseMarkdown
  # Lue au compile-time depuis `shard.yml` via le macro `read_file`.
  # Cf. note mémoire `feedback_shard_version_macro.md` (mémoire ALOLI).
  VERSION = {{
              (read_file("#{__DIR__}/../shard.yml")
                .lines
                .find(&.starts_with?("version:")) || "version: 0.0.0")
                .gsub(/^version:\s*/, "")
                .chomp
            }}
  UPSTREAM_VERSION = "3.0.2"

  # Defines how unknown HTML tags are handled.
  enum UnknownTags
    # Pass unknown tags through as raw HTML.
    PassThrough
    # Drop unknown tags and their content.
    Drop
    # Raise an error when an unknown tag is encountered.
    Raise
  end

  # Converts an HTML string to Markdown.
  #
  # Options:
  # - *unknown_tags*: how to handle unknown HTML tags (default: `UnknownTags::PassThrough`)
  def self.convert(html : String, *, unknown_tags : UnknownTags = UnknownTags::PassThrough) : String
    converter = Converter.new(unknown_tags: unknown_tags)
    converter.convert(html)
  end
end
