require "kramdown"

module Confluence
  class MarkdownConverter
    CONVERTERS = %w(
      convert_h1
      convert_h2
      convert_h3
      convert_h4
      convert_h5
      convert_bold
      convert_italic
      convert_code
      convert_unordered_list
    )

    def convert(original_markdown)
      return if original_markdown.nil?

      output = original_markdown

      CONVERTERS.each do |converter_method|
        output = send(converter_method, output)
      end

      output
    end

    private

    def convert_h1(markdown)
      markdown.gsub(/^(#)([^#].+)$/, 'h1.\2')
    end

    def convert_h2(markdown)
      markdown.gsub(/^(##)([^\#].+)$/, 'h2.\2')
    end

    def convert_h3(markdown)
      markdown.gsub(/^(###)([^\#].+)$/, 'h3.\2')
    end

    def convert_h4(markdown)
      markdown.gsub(/^(####)([^\#].+)$/, 'h4.\2')
    end

    def convert_h5(markdown)
      markdown.gsub(/^(\#)([^\#].+)$/, 'h5.\2')
    end

    def convert_bold(markdown)
      markdown.gsub(/(\*\*)(\w+)(\*\*)/, '*\2*')
    end

    def convert_italic(markdown)
      markdown.gsub(/(\*)(\w+)(\*)/, '_\2_')
    end

    def convert_code(markdown)
      output_lines = []

      markdown.split("\n").each do |line|
        if line =~ /^\~{3}\w+$/
          language = line.gsub("~~~", "").strip

          output_lines.push("{code:language=#{language}}")
        elsif line =~ /^\~{3}$/
          output_lines.push("{code}")
        else
          output_lines.push(line)
        end
      end
    end

    # TODO: add nested list convertion
    # TODO: add numbered list convertion
    def convert_unordered_list(markdown)
      markdown.gsub(/^*\s(.+)$/, '- \2')
    end
  end
end
