# frozen_string_literal: true

require "dbdoc/constants"
require_relative "../confluence/markdown_converter"
require_relative "../confluence/api"

module Confluence
  # Confluence::Uploader class knows how to uploaded
  # documentation to the Confluence Space provided in the config.yml.
  #
  # Uploader creates a root page with the database name from config.yml
  # and creates nested pages for schemas and tables.
  #
  # A Confluence ID of each page created by dbdoc
  # is logged to pages.yml file stored in the user's folder
  # with the documentation.
  class Uploader
    def initialize(local_path: Dir.pwd)
      @config = Dbdoc::Config.new(local_path: local_path).load
      @confluence_api = Confluence::Api.new
      @doc_folder = File.join(Dir.pwd, "doc")
    end

    def upload
      create_or_updates_pages
      delete_pages_for_dropped_schemas_or_tables
    end

    def space_pages
      @confluence_api.existing_pages["results"]
    end

    def print_space_pages
      space_pages.each do |page|
        page_title = page["title"]
        page_id = page["id"]

        puts "#{page_title}: #{page_id}"
      end
    end

    def clear_confluence_space
      YAML.safe_load(File.read(page_ids_file))

      space_pages.each do |page|
        page_key = page["title"]
        page_id = page["id"]

        puts "--> Deleting #{page_key} #{page_id}"

        unlog_page_id(key: page_key) if @confluence_api.delete_page(page_id: page_id)
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def delete_pages_for_dropped_schemas_or_tables
      uploaded_pages = YAML.safe_load(File.read(page_ids_file))

      uploaded_pages.each do |key, _params|
        next if key == "root"

        if key.start_with?("schema:")
          schema_name = key.gsub("schema:", "")

          unless Dir.exist?(File.join(@doc_folder, schema_name))
            page_id = uploaded_pages[key][:page_id]
            puts "--> delete page #{key}: #{page_id}"
            @confluence_api.delete_page(page_id: page_id)
            unlog_page_id(key: key)
          end
        elsif key.start_with?("table:")
          schema_name, table_name = key.gsub("table:", "").split(".")

          unless Dir.exist?(File.join(@doc_folder, schema_name, table_name))
            page_id = uploaded_pages[key][:page_id]
            puts "--> delete page #{key}: #{page_id}"
            @confluence_api.delete_page(page_id: page_id)
            unlog_page_id(key: key)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def create_or_updates_pages
      root_page_id = create_root_db_page[:page_id]

      log_page_id(key: "root", page_id: root_page_id)

      Dir.entries(@doc_folder).each do |schema_name|
        next if schema_name == "."
        next if schema_name == ".."

        next unless File.directory?(File.join(@doc_folder, schema_name))

        upload_schema(
          schema_name: schema_name,
          root_page_id: root_page_id
        )
      end
    end

    def page_ids_file
      file = File.join(Dir.pwd, "page_ids.yml")

      unless File.exist?(file)
        File.open(file, "w") do |f|
          f.puts("--- {}")
        end
      end

      file
    end

    def latest_page_id(key:)
      page_ids = YAML.safe_load(File.read(page_ids_file))
      page_ids.dig(key, :page_id)
    end

    def latest_page_version(key:)
      page_ids = YAML.safe_load(File.read(page_ids_file))
      page_ids.dig(key, :version)
    end

    def log_page_id(key:, page_id:)
      page_ids = YAML.safe_load(File.read(page_ids_file))
      page_ids[key] ||= {
        page_id: page_id,
        version: 0
      }

      if page_ids.dig(key, :version).zero?
        puts "--> create page #{key}: #{page_id}"
      else
        puts "--> update page #{key}: #{page_id}"
      end

      page_ids[key][:version] += 1

      File.open(page_ids_file, "w") do |f|
        f.puts(page_ids.to_yaml)
      end
    end

    def unlog_page_id(key:)
      page_ids = YAML.safe_load(File.read(page_ids_file))

      page_ids.delete(key)

      File.open(page_ids_file, "w") do |f|
        f.puts(page_ids.to_yaml)
      end
    end

    def create_root_db_page
      page_id = latest_page_id(key: "root")

      if page_id
        return {
          page_id: page_id
        }
      end

      db_name = @config["db"]["name"]
      @confluence_api.create_page(
        page_title: db_name,
        body: "#{db_name} database documentation"
      )
    end

    def upload_schema(schema_name:, root_page_id:)
      schema_folder = File.join(@doc_folder, schema_name)

      schema_page_id = latest_page_id(key: "schema:#{schema_name}")

      unless schema_page_id
        schema_page_id = @confluence_api.create_page(
          parent_page_id: root_page_id,
          page_title: schema_name,
          body: "#{schema_name} schema documentation"
        )[:page_id]

        log_page_id(key: "schema:#{schema_name}", page_id: schema_page_id)
      end

      Dir.entries(schema_folder).each do |table_name|
        next if table_name == "."
        next if table_name == ".."
        next unless File.directory?(File.join(schema_folder, table_name))

        upload_table(
          schema_name: schema_name,
          table_name: table_name,
          schema_page_id: schema_page_id
        )
      end
    end

    def markdown(input)
      Confluence::MarkdownConverter.new.convert(input)
    end

    # rubocop:disable Metrics/AbcSize
    def upload_table(schema_name:, table_name:, schema_page_id:)
      table_folder = File.join(@doc_folder, schema_name, table_name)

      table_description = markdown(File.read(File.join(table_folder, "description.md")))

      examples_folder = File.join(table_folder, "examples")
      table_examples = Dir[File.join(examples_folder, "*.md")].map do |f|
        markdown(File.read(f))
      end

      columns_markdown_template_file = File.join(DBDOC_HOME, "doc_files", "columns.md.erb")

      columns_table_template = ERB.new(
        File.read(columns_markdown_template_file),
        nil,
        "-"
      )

      columns_doc = YAML.safe_load(File.read(File.join(table_folder, "columns.yml")))
      columns_doc.each do |col|
        col[:description] = markdown(col[:description])
      end

      columns_table = columns_table_template.result_with_hash({
        columns: columns_doc
      })

      page_body = <<~MARKDOWN
        h2. Description

        #{table_description}

        h2. Columns

        #{columns_table}

        h2. Examples

        #{table_examples.join("\n")}
      MARKDOWN

      page_title = schema_name == "public" ? table_name : "#{schema_name}.#{table_name}"

      page_key = "table:#{schema_name}.#{table_name}"
      page_id = latest_page_id(key: page_key)

      if page_id
        @confluence_api.update_page(
          page_id: page_id,
          page_title: page_title,
          body: page_body,
          version: latest_page_version(key: page_key) + 1
        )

        log_page_id(key: "table:#{schema_name}.#{table_name}", page_id: schema_page_id)
      else
        response = @confluence_api.create_page(
          parent_page_id: schema_page_id,
          page_title: page_title,
          body: page_body
        )

        table_page_id = response[:page_id]

        log_page_id(key: "table:#{schema_name}.#{table_name}", page_id: table_page_id)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
