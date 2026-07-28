require "../src/reverse_markdown"
require "option_parser"

output_file : String? = nil
unknown_tags = ReverseMarkdown::UnknownTags::PassThrough

parser = OptionParser.new do |p|
  p.banner = "Usage: reverse-markdown [options] [input.html]"

  p.on("-o FILE", "--output FILE", "Write output to FILE instead of stdout") do |file|
    output_file = file
  end

  p.on("--unknown-tags MODE", "How to handle unknown tags: pass_through (default), drop, raise") do |mode|
    case mode.downcase.gsub('-', '_')
    when "pass_through" then unknown_tags = ReverseMarkdown::UnknownTags::PassThrough
    when "drop"         then unknown_tags = ReverseMarkdown::UnknownTags::Drop
    when "raise"        then unknown_tags = ReverseMarkdown::UnknownTags::Raise
    else
      STDERR.puts "Unknown mode: #{mode}. Use pass_through, drop, or raise."
      exit 1
    end
  end

  p.on("-v", "--version", "Show version") do
    puts "reverse-markdown #{ReverseMarkdown::VERSION} (upstream: #{ReverseMarkdown::UPSTREAM_VERSION})"
    exit
  end

  p.on("-h", "--help", "Show this help") do
    puts p
    exit
  end
end

parser.parse

# Read input from file argument or stdin
html = if filename = ARGV.first?
         File.read(filename)
       else
         STDIN.gets_to_end
       end

markdown = ReverseMarkdown.convert(html, unknown_tags: unknown_tags)

if dest = output_file
  File.write(dest, markdown)
else
  print markdown
end
