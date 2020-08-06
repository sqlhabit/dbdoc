# frozen_string_literal: true

require "spec_helper"

describe Dbdoc::Manager do
  describe "#apply" do
    context "when user imports fresh schema" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_without_documentation" do
          temp_folder = File.join(tmp_folder("dbdoc_folder_without_documentation"))

          manager = Dbdoc::Manager.new(local_path: temp_folder)
          manager.apply

          doc_folder = File.join(temp_folder, "doc")
          users_table_documentation = YAML.load(File.read(File.join(doc_folder, "public/users/columns.yml")))
          expect(users_table_documentation).to eq([{
            name: "id",
            type: "integer",
            position: 1,
            foreign_key: "TODO",
            description: "TODO\n"
          }, {
            name: "name",
            type: "text",
            position: 2,
            foreign_key: "TODO",
            description: "TODO\n"
          }, {
            name: "email",
            type: "text",
            position: 3,
            foreign_key: "TODO",
            description: "TODO\n"
          }, {
            name: "created_at",
            type: "timestamp without time zone",
            position: 4,
            foreign_key: "TODO",
            description: "TODO\n"
          }])
        end
      end
    end
  end
end
