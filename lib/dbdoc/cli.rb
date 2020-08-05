# frozen_string_literal: true

require "optparse"

$LOAD_PATH << File.expand_path(__dir__)

module Dbdoc
  class CLI
    COMMANDS = {
      install: %(
        Generates all necessary config files and documentation folders.

        Run this command in an empty directory.
      ),
      query: %(
        Prints a query that you need to run in the database \
        you're going to document.

        Export the result of this query to the "schema.csv" file \
        and copy it over to the "schema" folder for processing.
      ),
      plan: %(
        Shows you what columns/tables/schemas are new and \
        going to be added/deleted from the documentation.
      ),
      apply: %(
        Generates boilerplate documentation for newly added \
        columns/tables/schemas.

        Drops documentation for columns/tables/schemas that \
        were deleted from the database.
      ),
      "confluence:upload": %(
        Uploads current documentation to Confluence: pages for \
        new tables/schemas will be added, pages for dropped tables/schemas \
        will be deleted from your Confluence space.
      ),
      "confluece:pages": %(
        Lists all pages in your dbdoc Confluence space \
        (created manually or via dbdoc).
      ),
      "confluence:clear": %(
        IMPORTANT This command will delete ALL pages from \
        the Confluence space (pages created via dbdoc AND pages that were added manually).
      ),
      todo: %(
        Shows you the documentation that needs to be written.
      )
    }.freeze

    def run(args = [])
      if args.first == "install"
        manager.install
      elsif args.first == "query"
        puts manager.query
      elsif args.first == "plan"
        manager.plan
      elsif args.first == "apply"
        manager.apply
      elsif args.first == "confluence:upload"
        uploader.upload
      elsif args.first == "confluence:pages"
        uploader.print_space_pages
      elsif args.first == "confluence:clear"
        uploader.clear_confluence_space
      elsif args.first == "todo"
        manager.todo
      elsif args.first == "help"
        print_help
      elsif args.first == "version"
        puts Dbdoc::VERSION
      end

      0
    end

    private

    def unindent(str)
      str.gsub(/^#{str.scan(/^[ \t]+(?=\S)/).min}/, "")
    end

    def manager
      @manager ||= Dbdoc::Manager.new
    end

    def uploader
      @uploader ||= Confluence::Uploader.new
    end

    def print_help
      puts unindent <<-TEXT
        Usage: dbdoc [command]
      TEXT
      puts

      COMMANDS.each do |command, description|
        puts "dbdoc #{command}"
        puts
        puts unindent(description)
      end
    end
  end
end
