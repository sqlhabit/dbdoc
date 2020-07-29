require "yaml"
require "dbdoc/constants"

module Dbdoc
  class Manager
    def initialize(config: {})
      @config = Dbdoc::Config.load.merge(config)
    end

    def plan(verbose: true)
      puts "--> PLAN"
      puts
      puts

      input_schema = read_input_schema.map { |r| r.join(":") }
      current_schema = read_documented_schema.map { |r| r.join(":") }

      puts "--> New columns:"
      pp input_schema - current_schema
      puts
      puts

      puts "--> Columns to drop:"
      pp input_schema - current_schema
    end

    def apply(path: Dir.pwd, verbose: true)
      puts "--> APPLY"
      puts
      puts

      input_schema = read_input_schema.map { |r| r.join(":") }
      current_schema = read_documented_schema.map { |r| r.join(":") }

      added_columns = input_schema - current_schema
      dropped_columns = current_schema - input_schema

      doc_folder = File.join(Dir.pwd, "doc")

      ## DROP COLUMNS
      dropped_columns.each do |column|
        schema_name, table_name, column_name, column_type = column.split(":")

        columns_file = File.join(doc_folder, schema_name, table_name, "columns.yml")
        next unless File.exists?(columns_name)

        columns = YAML.load(File.read(columns_file))
        columns.reject! { |c| c[:name] == column_name }
        columns.each { |c| c[:description].strip! }

        File.open(columns_file, "w") do |f|
          f.puts(columns.to_yaml)
        end
      end

      ## DROP EMPTY TABLES
      Dir.entries(doc_folder).each do |schema_name|
        next if schema_name == "."
        next if schema_name == ".."

        schema_folder = File.join(doc_folder, schema_name)
        next unless File.directory?(File.join(doc_folder, schema_name))

        Dir.entries(schema_folder).each do |table_name|
          next if table_name == "."
          next if table_name == ".."

          table_folder = File.join(schema_folder, table_name)
          next unless File.directory?(table_folder)

          columns = YAML.load(File.read(File.join(table_folder, "columns.yml")))

          if columns.empty?
            puts "--> DELETING #{schema_name}.#{table_name}"
            FileUtils.rm_rf(table_folder)
          end
        end
      end

      ## DROP EMPTY SCHEMAS
      Dir.entries(doc_folder).each do |schema_name|
        next if schema_name == "."
        next if schema_name == ".."

        schema_folder = File.join(doc_folder, schema_name)
        next unless File.directory?(schema_folder)

        FileUtils.rm_rf(schema_folder) if Dir.empty?(schema_folder)
      end

      create_new_columns(added_columns)
    end

    private

    def input_schema
      File.read(File.join(Dir.pwd, "schema", "schema.csv"))
    end

    def read_input_schema
      rows = input_schema.split("\n")
      with_header = rows[0].include?("schema_name")

      rows.shift if with_header

      rows.map! do |r|
        r.split(",").map(&:strip).map { |c| c.gsub('"', "") }.first(4)
      end

      config = YAML.load(File.read("config.yml"))

      if @config["ignorelist"]
        @config["ignorelist"].map { |r| r.split(/[\.\#]/) }.each do |b|
          schema_pattern, table_pattern, column_pattern = b

          rows.reject! do |row|
            schema_name, table_name, column_name, _, _ = row

            if column_pattern
              next unless column_name =~ Regexp.new(column_pattern.gsub("*", ".*"))
            end

            if table_pattern
              next unless table_name =~ Regexp.new(table_pattern.gsub("*", ".*"))
            end

            if schema_pattern
              next unless schema_name =~ Regexp.new(schema_pattern.gsub("*", ".*"))
            end

            true
          end
        end
      end

      rows
    end

    def read_documented_schema
      doc_folder = File.join(Dir.pwd, "doc")

      return [] if Dir.empty?(doc_folder)

      keys = []
      Dir.entries(doc_folder).each do |schema_name|
        next if schema_name == "."
        next if schema_name == ".."

        schema_folder = File.join(doc_folder, schema_name)
        next unless File.directory?(schema_folder)

        Dir.entries(schema_folder).each do |table_name|
          next if table_name == "."
          next if table_name == ".."

          table_folder = File.join(schema_folder, table_name)
          next unless File.directory?(table_folder)

          columns = YAML.load(File.read(File.join(table_folder, "columns.yml")))
          columns.each do |column|
            keys.push([
              schema_name,
              table_name,
              column[:name],
              column[:type]
            ].join(":"))
          end
        end
      end

      keys
    end

    def create_new_columns(added_columns)
      doc_folder = File.join(Dir.pwd, "doc")

      added_columns.map! { |r| r.split(":") }
      new_columns = read_input_schema.select do |row|
        added_columns.any? { |r| r == row.first(4) }
      end

      schemas = new_columns.group_by(&:first)

      schemas_and_tables = schemas.each_with_object({}) do |(schema_name, tables), o|
        tables.map(&:shift)

        o[schema_name] = tables.group_by(&:first)
      end

      schemas_and_tables.each do |schema_name, tables|
        schema_folder = File.join(doc_folder, schema_name)

        Dir.mkdir(schema_folder) unless Dir.exist?(schema_folder)

        tables.each do |table_name, columns|
          # 1. create table folder
          table_folder = File.join(schema_folder, table_name)

          Dir.mkdir(table_folder) unless Dir.exist?(table_folder)

          # 2. create examples folder with test example
          table_example_folder = File.join(table_folder, "examples")

          Dir.mkdir(table_example_folder) unless Dir.exist?(table_example_folder)

          # 2a. create example file
          example_file = File.join(table_example_folder, "1_example.md")
          example_table_example_file = File.join(DBDOC_HOME, "doc_files", "table_example.md")

          FileUtils.cp(example_table_example_file, example_file)

          # 3. create table description.md
          table_description_file = File.join(table_folder, "description.md")

          example_table_description_file = File.join(DBDOC_HOME, "doc_files", "table_description.md")
          FileUtils.cp(example_table_description_file, table_description_file)

          # 4. create table columns.yml
          columns_yaml = File.join(table_folder, "columns.yml")

          unless File.exists?(columns_yaml)
            columns_erb_tamplate_file = File.join(DBDOC_HOME, "doc_files", "columns.yml.erb")
            columns_yaml_template = ERB.new(File.read(columns_erb_tamplate_file), nil, "-")
            File.open(columns_yaml, "w") do |f|
              f.puts columns_yaml_template.result_with_hash({
                columns: columns
              })
            end
          end
        end
      end
    end
  end
end
