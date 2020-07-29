require "dbdoc/constants"
require_relative "../confluence/api"

module Dbdoc
  class Uploader
    def initialize(config: {})
      @config = config
      @confluence_api = Confluence::Api.new
      @doc_folder = File.join(Dir.pwd, "doc")
    end

    def upload
      create_or_updates_pages
      delete_pages_for_dropped_schemas_or_tables
    end

    def clear_confluence_space
      # TODO paginate and fetch all Confluence pages
      # TODO ask user to Yn if they want to proceed with deletion
      # TODO iterate over each page_id, unlog it from page_ids.yml and @confluence_api.delete_page(page_id:)
    end

    private

    def delete_pages_for_dropped_schemas_or_tables
      uploaded_pages = YAML.load(File.read(page_ids_file))

      uploaded_pages.each do |key, params|
        next if key == "root"

        if key.start_with?("schema:")
          schema_name = key.gsub("schema:", "")

          unless Dir.exists?(File.join(@doc_folder, schema_name))
            page_id = uploaded_pages[key][:page_id]
            puts "--> delete page #{key}: #{page_id}"
            @confluence_api.delete_page(page_id: page_id)
            unlog_page_id(key: key)
          end
        elsif key.start_with?("table:")
          schema_name, table_name = key.gsub("table:", "").split(".")

          unless Dir.exists?(File.join(@doc_folder, schema_name, table_name))
            page_id = uploaded_pages[key][:page_id]
            puts "--> delete page #{key}: #{page_id}"
            @confluence_api.delete_page(page_id: page_id)
            unlog_page_id(key: key)
          end
        end
      end
    end

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

      unless File.exists?(file)
        File.open(file, "w") do |f|
          f.puts("--- {}")
        end
      end

      file
    end

    def latest_page_id(key:)
      page_ids = YAML.load(File.read(page_ids_file))
      page_ids.dig(key, :page_id)
    end

    def latest_page_version(key:)
      page_ids = YAML.load(File.read(page_ids_file))
      page_ids.dig(key, :version)
    end

    def log_page_id(key:, page_id:)
      page_ids = YAML.load(File.read(page_ids_file))
      page_ids[key] ||= {
        page_id: page_id,
        version: 0
      }

      if page_ids[key][:version] == 0
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
      page_ids = YAML.load(File.read(page_ids_file))

      page_ids.delete(key)

      File.open(page_ids_file, "w") do |f|
        f.puts(page_ids.to_yaml)
      end
    end

    def create_root_db_page
      page_id = latest_page_id(key: "root")

      return {
        page_id: page_id
      } if page_id

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

    def upload_table(schema_name:, table_name:, schema_page_id:)
      table_folder = File.join(@doc_folder, schema_name, table_name)

      table_description = File.read(File.join(table_folder, "description.md"))

      examples_folder = File.join(table_folder, "examples")
      table_examples = Dir[File.join(examples_folder, "*.md")].map { |f| File.read(f) }

      columns_markdown_template_file = File.join(DBDOC_HOME, "doc_files", "columns.md.erb")

      columns_table_template = ERB.new(
        File.read(columns_markdown_template_file),
        nil,
        "-"
      )
      columns_table = columns_table_template.result_with_hash({
        columns: YAML.load(File.read(File.join(table_folder, "columns.yml")))
      })

      page_body = <<-MARKDOWN
h2. Description

#{table_description}

h2. Columns

#{columns_table}

h2. Examples

#{table_examples.join("\n") }
      MARKDOWN

      page_title = schema_name == "public" ? table_name : "#{schema_name}.#{table_name}"

      page_key = "table:#{schema_name}.#{table_name}"
      page_id = latest_page_id(key: page_key)

      if page_id
        response = @confluence_api.update_page(
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
  end
end
