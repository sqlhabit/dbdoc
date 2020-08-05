# frozen_string_literal: true

require "yaml"
require "fileutils"
require "dbdoc/constants"

module Dbdoc
  # Dbdoc::FolderInitializer class knows how to turn an emtpy
  # folder into a dbdoc folder.
  #
  class FolderInitializer
    def initialize
      @config = Dbdoc::Config.load
    end

    def init
      create_schema_folder
      create_doc_folder
      create_config_file
      create_gitignore_file
      create_confluence_config_file
    end

    private

    # schema folder is the one user copies the schema.csv to
    # before updating/generating documentation
    def create_schema_folder
      schema_folder = File.join(Dir.pwd, "schema")
      Dir.mkdir(schema_folder) unless Dir.exist?(schema_folder)
    end

    # doc folder stores all the database documentation files
    def create_doc_folder
      doc_folder = File.join(Dir.pwd, "doc")
      Dir.mkdir(doc_folder) unless Dir.exist?(doc_folder)
    end

    def create_file(default_file_name, target_file_name)
      target_file = File.join(Dir.pwd, target_file_name)

      return if File.exist?(target_file)

      config_file = File.join(File.expand_path(__dir__), "../..", "config", default_file_name)

      FileUtils.cp(config_file, target_file)
    end

    def create_config_file
      create_file("default.yml", "config.yml")
    end

    def create_gitignore_file
      create_file("gitignore.template", ".gitignore")
    end

    def create_confluence_config_file
      create_file("confluence.yml", "confluence.yml")
    end
  end
end
