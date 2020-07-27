require "optparse"

$LOAD_PATH << File.expand_path(__dir__)

module Dbdoc
  class CLI
    def run(args = [])
      if args.first == "install"
        require "fileutils"

        target_file = File.join(Dir.pwd, ".dbdoc.yml")
        config_file = File.join(File.expand_path(__dir__), "..", "config", "default.yml")

        FileUtils.cp(config_file, target_file)

        0
      else
        options = extract_options(args)

        config = Dbdoc::Config.load
        config.merge!(options)

        path = config.delete("path")

        linter = Dbdoc::Linter.new(config: config)
        heavy_images = linter.lint(path: path)

        heavy_images.empty? ? 0 : 2
      end
    end

    private

    # This method is needed to unindent
    # ["here document"](https://en.wikibooks.org/wiki/Ruby_Programming/Here_documents)
    # help description.
    #
    def unindent(str)
      str.gsub(/^#{str.scan(/^[ \t]+(?=\S)/).min}/, "")
    end

    def extract_options(args)
      options = {}

      OptionParser.new do |opts|
        opts.banner = unindent(<<-TEXT)
          dbdoc help

          1. dbdoc query

          This will print you a query you need to run to export your database schema.
        TEXT

        opts.on("-v", "--version", "Prints current version of dbdoc") do
          puts Dbdoc::VERSION
          exit 0
        end
      end.parse!(args)

      options
    end
  end
end
