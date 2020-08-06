# frozen_string_literal: true

require "spec_helper"

describe Dbdoc::Manager do
  describe "#plan" do
    context "when user imports fresh schema" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_without_documentation" do
          manager = Dbdoc::Manager.new(local_path: tmp_folder("dbdoc_folder_without_documentation"))

          expect(manager.plan).to eq({
            new_columns: [
              "public:users:id:integer",
              "public:users:name:text",
              "public:users:email:text",
              "public:users:created_at:timestamp without time zone",
              "public:purchases:user_id:bigint",
              "public:purchases:product_name:text",
              "public:purchases:amount:integer",
              "public:purchases:created_at:timestamp without time zone"
            ],
            columns_to_drop: []
          })
        end
      end
    end

    context "when user imports the same schema that was already documented" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_with_documented_schema" do
          manager = Dbdoc::Manager.new(local_path: tmp_folder("dbdoc_folder_with_documented_schema"))

          expect(manager.plan).to eq({
            new_columns: [],
            columns_to_drop: []
          })
        end
      end
    end

    context "when user imports the same schema with deleted schema" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_with_dropped_schema" do
          manager = Dbdoc::Manager.new(local_path: tmp_folder("dbdoc_folder_with_dropped_schema"))

          expect(manager.plan).to eq({
            new_columns: [],
            columns_to_drop: [
              "purchases:purchases:user_id:bigint",
              "purchases:purchases:product_name:text",
              "purchases:purchases:amount:integer",
              "purchases:purchases:created_at:timestamp without time zone"
            ]
          })
        end
      end
    end

    context "when user imports the same schema with deleted table" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_with_dropped_table" do
          manager = Dbdoc::Manager.new(local_path: tmp_folder("dbdoc_folder_with_dropped_table"))

          expect(manager.plan).to eq({
            new_columns: [],
            columns_to_drop: [
              "public:purchases:user_id:bigint",
              "public:purchases:product_name:text",
              "public:purchases:amount:integer",
              "public:purchases:created_at:timestamp without time zone"
            ]
          })
        end
      end
    end

    context "when user imports the same schema with deleted column" do
      it "returns true" do
        with_dbdoc_folder "dbdoc_folder_with_dropped_column" do
          manager = Dbdoc::Manager.new(local_path: tmp_folder("dbdoc_folder_with_dropped_column"))

          expect(manager.plan).to eq({
            new_columns: [],
            columns_to_drop: [
              "public:purchases:product_name:text"
            ]
          })
        end
      end
    end
  end
end
