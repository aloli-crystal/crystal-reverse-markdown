module ReverseMarkdown
  class Converter
    # Raised when an unknown tag is encountered and `unknown_tags` is set to `Raise`.
    class UnknownTagError < Exception
      getter tag : String

      def initialize(@tag : String)
        super("Unknown tag: <#{tag}>")
      end
    end

    BLOCK_ELEMENTS = Set{
      "address", "article", "aside", "blockquote", "details", "dialog",
      "dd", "div", "dl", "dt", "fieldset", "figcaption", "figure",
      "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header",
      "hgroup", "hr", "li", "main", "nav", "ol", "p", "pre", "section",
      "table", "ul",
    }

    INLINE_ELEMENTS = Set{
      "a", "abbr", "acronym", "b", "bdo", "big", "br", "button", "cite",
      "code", "del", "dfn", "em", "i", "img", "input", "kbd", "label",
      "map", "object", "output", "q", "s", "samp", "script", "select",
      "small", "span", "strong", "sub", "sup", "textarea", "time", "tt",
      "u", "var", "wbr",
    }

    KNOWN_ELEMENTS = BLOCK_ELEMENTS | INLINE_ELEMENTS | Set{
      "html", "head", "body", "title", "meta", "link", "style",
      "thead", "tbody", "tfoot", "tr", "th", "td", "caption",
      "colgroup", "col",
    }

    @unknown_tags : UnknownTags

    def initialize(*, @unknown_tags : UnknownTags = UnknownTags::PassThrough)
    end

    # Converts an HTML string to Markdown.
    def convert(html : String) : String
      return "" if html.empty?

      doc = XML.parse_html(html, XML::HTMLParserOptions::RECOVER | XML::HTMLParserOptions::NOERROR | XML::HTMLParserOptions::NOWARNING)
      result = process_node(doc, depth: 0, list_type: nil, list_index: nil)
      cleanup(result)
    end

    private def process_node(node : XML::Node, *, depth : Int32, list_type : Symbol?, list_index : Int32?) : String
      case node.type
      when .element_node?
        process_element(node, depth: depth, list_type: list_type, list_index: list_index)
      when .text_node?
        process_text(node, depth: depth)
      when .document_node?, .html_document_node?
        process_children(node, depth: depth, list_type: list_type, list_index: list_index)
      when .cdata_section_node?
        node.content || ""
      when .dtd_node?, .comment_node?
        ""
      else
        ""
      end
    end

    private def process_element(node : XML::Node, *, depth : Int32, list_type : Symbol?, list_index : Int32?) : String
      tag = node.name.downcase

      case tag
      when "h1"          then convert_heading(node, level: 1, depth: depth)
      when "h2"          then convert_heading(node, level: 2, depth: depth)
      when "h3"          then convert_heading(node, level: 3, depth: depth)
      when "h4"          then convert_heading(node, level: 4, depth: depth)
      when "h5"          then convert_heading(node, level: 5, depth: depth)
      when "h6"          then convert_heading(node, level: 6, depth: depth)
      when "p"           then convert_paragraph(node, depth: depth)
      when "br"          then convert_br
      when "hr"          then convert_hr
      when "strong", "b" then convert_strong(node, depth: depth)
      when "em", "i"     then convert_em(node, depth: depth)
      when "del", "s"    then convert_del(node, depth: depth)
      when "code"        then convert_code(node, depth: depth)
      when "pre"         then convert_pre(node, depth: depth)
      when "a"           then convert_link(node, depth: depth)
      when "img"         then convert_image(node)
      when "blockquote"  then convert_blockquote(node, depth: depth)
      when "ul"          then convert_list(node, type: :unordered, depth: depth)
      when "ol"          then convert_list(node, type: :ordered, depth: depth)
      when "li"          then convert_list_item(node, depth: depth, list_type: list_type, list_index: list_index)
      when "table"       then convert_table(node, depth: depth)
      when "sup"         then convert_sup(node, depth: depth)
      when "div", "section", "article", "main", "header", "footer", "nav", "aside",
           "figure", "figcaption", "details", "summary"
        convert_block_wrapper(node, depth: depth)
      when "span", "small", "abbr", "acronym", "dfn", "u", "wbr"
        process_children(node, depth: depth)
      when "html", "body"
        process_children(node, depth: depth)
      when "head", "title", "meta", "link", "style", "script"
        ""
      when "thead", "tbody", "tfoot", "tr", "th", "td", "caption", "colgroup", "col"
        # Handled inside convert_table
        ""
      when "sub"
        convert_sub(node, depth: depth)
      else
        handle_unknown_tag(node, depth: depth)
      end
    end

    private def process_text(node : XML::Node, *, depth : Int32) : String
      text = node.content || ""
      # Check if the parent is a <pre> — preserve whitespace
      parent = node.parent
      if parent && parent.type.element_node?
        parent_name = parent.name.downcase
        if parent_name == "pre" || parent_name == "code" && parent.parent.try(&.name.downcase) == "pre"
          return text
        end
      end
      # Collapse whitespace in inline context
      text = text.gsub(/\s+/, " ")
      text
    end

    private def process_children(node : XML::Node, *, depth : Int32, list_type : Symbol? = nil, list_index : Int32? = nil) : String
      String.build do |io|
        node.children.each do |child|
          io << process_node(child, depth: depth, list_type: list_type, list_index: list_index)
        end
      end
    end

    # --- Converters ---

    private def convert_heading(node : XML::Node, *, level : Int32, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      return "" if content.empty?
      "\n\n#{"#" * level} #{content}\n\n"
    end

    private def convert_paragraph(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      return "" if content.empty?
      "\n\n#{content}\n\n"
    end

    private def convert_br : String
      "  \n"
    end

    private def convert_hr : String
      "\n\n---\n\n"
    end

    private def convert_strong(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth)
      inner = content.strip
      return "" if inner.empty?
      leading = content.starts_with?(' ') ? " " : ""
      trailing = content.ends_with?(' ') ? " " : ""
      "#{leading}**#{inner}**#{trailing}"
    end

    private def convert_em(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth)
      inner = content.strip
      return "" if inner.empty?
      leading = content.starts_with?(' ') ? " " : ""
      trailing = content.ends_with?(' ') ? " " : ""
      "#{leading}*#{inner}*#{trailing}"
    end

    private def convert_del(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth)
      inner = content.strip
      return "" if inner.empty?
      leading = content.starts_with?(' ') ? " " : ""
      trailing = content.ends_with?(' ') ? " " : ""
      "#{leading}~~#{inner}~~#{trailing}"
    end

    private def convert_code(node : XML::Node, *, depth : Int32) : String
      # If inside a <pre>, let convert_pre handle it
      parent = node.parent
      if parent && parent.type.element_node? && parent.name.downcase == "pre"
        return process_children(node, depth: depth)
      end
      content = (node.content || "").strip
      return "" if content.empty?
      if content.includes?('`')
        "`` #{content} ``"
      else
        "`#{content}`"
      end
    end

    private def convert_pre(node : XML::Node, *, depth : Int32) : String
      code_node = node.children.find { |c| c.type.element_node? && c.name.downcase == "code" }
      if code_node
        language = extract_language(code_node)
        content = process_children(code_node, depth: depth)
      else
        language = ""
        content = process_children(node, depth: depth)
      end
      # Strip a single leading/trailing newline from content
      content = content.lstrip('\n').rstrip('\n')
      "\n\n```#{language}\n#{content}\n```\n\n"
    end

    private def extract_language(code_node : XML::Node) : String
      class_attr = code_node["class"]? || ""
      # Match patterns like "language-ruby", "lang-ruby", "ruby"
      if match = class_attr.match(/(?:language-|lang-)(\S+)/)
        match[1]
      elsif class_attr =~ /^[a-zA-Z0-9_+-]+$/
        class_attr
      else
        ""
      end
    end

    private def convert_link(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      href = node["href"]? || ""
      title = node["title"]?

      return content if href.empty?

      if title
        "[#{content}](#{href} \"#{title}\")"
      else
        "[#{content}](#{href})"
      end
    end

    private def convert_image(node : XML::Node) : String
      alt = node["alt"]? || ""
      src = node["src"]? || ""
      title = node["title"]?

      if title
        "![#{alt}](#{src} \"#{title}\")"
      else
        "![#{alt}](#{src})"
      end
    end

    private def convert_blockquote(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      return "" if content.empty?
      quoted = content.split('\n').map { |line| "> #{line}" }.join('\n')
      "\n\n#{quoted}\n\n"
    end

    private def convert_list(node : XML::Node, *, type : Symbol, depth : Int32) : String
      items = String.build do |io|
        index = 0
        node.children.each do |child|
          next unless child.type.element_node? && child.name.downcase == "li"
          index += 1
          io << process_node(child, depth: depth + 1, list_type: type, list_index: index)
        end
      end
      # Add blank lines around the list if at top level
      if depth == 0
        "\n\n#{items.strip}\n\n"
      else
        "\n#{items.rstrip}\n"
      end
    end

    private def convert_list_item(node : XML::Node, *, depth : Int32, list_type : Symbol?, list_index : Int32?) : String
      indent = "    " * (depth - 1)

      marker = case list_type
               when :ordered
                 "#{list_index}. "
               else
                 "- "
               end

      # Separate inline content from nested lists
      text_content = String.build do |io|
        node.children.each do |child|
          if child.type.element_node? && child.name.downcase.in?("ul", "ol")
            # Skip nested lists here; handled below
          else
            io << process_node(child, depth: depth, list_type: list_type, list_index: list_index)
          end
        end
      end.strip

      nested_lists = String.build do |io|
        node.children.each do |child|
          next unless child.type.element_node? && child.name.downcase.in?("ul", "ol")
          type = child.name.downcase == "ol" ? :ordered : :unordered
          nested_index = 0
          child.children.each do |li|
            next unless li.type.element_node? && li.name.downcase == "li"
            nested_index += 1
            io << process_node(li, depth: depth + 1, list_type: type, list_index: nested_index)
          end
        end
      end

      result = "#{indent}#{marker}#{text_content}\n"
      result += nested_lists unless nested_lists.empty?
      result
    end

    private def convert_table(node : XML::Node, *, depth : Int32) : String
      rows = collect_table_rows(node)
      return "" if rows.empty?

      # Determine column count from the widest row
      col_count = rows.max_of(&.size)
      return "" if col_count == 0

      # Determine if first row is header (from <thead> or <th>)
      has_header = has_table_header?(node)

      result = String.build do |io|
        io << "\n\n"
        rows.each_with_index do |row, row_idx|
          # Pad row to col_count
          cells = row + Array.new(col_count - row.size, "")
          io << "| " << cells.join(" | ") << " |\n"

          # Insert separator after header row
          if row_idx == 0
            io << "| " << Array.new(col_count, "---").join(" | ") << " |\n"
          end
        end
        io << "\n"
      end
      result
    end

    private def collect_table_rows(node : XML::Node) : Array(Array(String))
      rows = [] of Array(String)
      # Process thead, tbody, tfoot, or direct tr children
      node.children.each do |child|
        next unless child.type.element_node?
        case child.name.downcase
        when "thead", "tbody", "tfoot"
          child.children.each do |tr|
            next unless tr.type.element_node? && tr.name.downcase == "tr"
            rows << collect_row_cells(tr)
          end
        when "tr"
          rows << collect_row_cells(child)
        end
      end
      rows
    end

    private def collect_row_cells(tr : XML::Node) : Array(String)
      cells = [] of String
      tr.children.each do |td|
        next unless td.type.element_node?
        name = td.name.downcase
        next unless name == "td" || name == "th"
        content = process_children(td, depth: 0).strip
        cells << content
      end
      cells
    end

    private def has_table_header?(node : XML::Node) : Bool
      node.children.any? { |child|
        child.type.element_node? && child.name.downcase == "thead"
      }
    end

    private def convert_sup(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      "<sup>#{content}</sup>"
    end

    private def convert_sub(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth).strip
      "<sub>#{content}</sub>"
    end

    private def convert_block_wrapper(node : XML::Node, *, depth : Int32) : String
      content = process_children(node, depth: depth)
      # Ensure block-level separation
      stripped = content.strip
      return "" if stripped.empty?
      "\n\n#{stripped}\n\n"
    end

    private def handle_unknown_tag(node : XML::Node, *, depth : Int32) : String
      case @unknown_tags
      when .pass_through?
        # Reconstruct opening tag
        attrs = String.build do |io|
          node.attributes.each do |attr|
            io << " " << attr.name << "=\"" << attr.content << "\""
          end
        end
        inner = process_children(node, depth: depth)
        tag = node.name.downcase
        if inner.empty? && self_closing?(tag)
          "<#{tag}#{attrs} />"
        else
          "<#{tag}#{attrs}>#{inner}</#{tag}>"
        end
      when .drop?
        ""
      when .raise?
        raise UnknownTagError.new(node.name.downcase)
      else
        ""
      end
    end

    private def self_closing?(tag : String) : Bool
      tag.in?("area", "base", "br", "col", "embed", "hr", "img", "input",
        "keygen", "link", "meta", "param", "source", "track", "wbr")
    end

    # Post-process the Markdown output.
    private def cleanup(text : String) : String
      text
        .gsub(/\n{3,}/, "\n\n") # Collapse multiple blank lines
        .strip + "\n"           # Ensure single trailing newline
    end
  end
end
