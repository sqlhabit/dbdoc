require "optparse"

$LOAD_PATH << File.expand_path(__dir__)

module Dbdoc
  class CLI
    def run(args = [])
      if args.first == "init"
        require "fileutils"

        schema_folder = File.join(Dir.pwd, "schema")
        unless Dir.exists?(schema_folder)
          Dir.mkdir(schema_folder)
        end

        doc_folder = File.join(Dir.pwd, "doc")
        unless Dir.exists?(doc_folder)
          Dir.mkdir(doc_folder)
        end

        target_file = File.join(Dir.pwd, "config.yml")
        config_file = File.join(File.expand_path(__dir__), "../..", "config", "default.yml")

        FileUtils.cp(config_file, target_file) unless File.exists?(target_file)

        target_file = File.join(Dir.pwd, ".gitignore")
        config_file = File.join(File.expand_path(__dir__), "../..", "config", "gitignore.template")

        FileUtils.cp(config_file, target_file) unless File.exists?(target_file)

        target_file = File.join(Dir.pwd, "confluence.yml")
        config_file = File.join(File.expand_path(__dir__), "../..", "config", "confluence.yml")

        FileUtils.cp(config_file, target_file) unless File.exists?(target_file)

        0
      elsif args.first == "query"
        options = extract_options(args)

        config = Dbdoc::Config.load
        config.merge!(options)

        db_type = config["db"]["type"]
        query_file = File.join(File.expand_path(__dir__), "../..", "config", "schema_queries", "#{db_type}.sql")
        query = File.read(query_file)

        puts query

        0
      elsif args.first == "plan"
        options = extract_options(args)

        config = Dbdoc::Config.load
        config.merge!(options)

        manager = Dbdoc::Manager.new(config: config)
        manager.plan

        0
      elsif args.first == "apply"
        options = extract_options(args)

        config = Dbdoc::Config.load
        config.merge!(options)

        manager = Dbdoc::Manager.new(config: config)
        manager.apply

        0
      elsif args.first == "upload"
        options = extract_options(args)

        config = Dbdoc::Config.load
        config.merge!(options)

        uploader = Dbdoc::Uploader.new(config: config)
        uploader.upload

        0
      elsif args.first == "help"
        puts "--> SOME HELP"

        0
      end

      0
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
