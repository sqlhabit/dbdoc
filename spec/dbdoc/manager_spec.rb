# frozen_string_literal: true

require "spec_helper"

describe Dbdoc::Manager do
  describe "#plan" do
    context "when user imports fresh schema" do
      it "returns true" do
        FakeFS.with_fresh do
          config = File.expand_path("../fixtures/dbdoc_folder_without_documentation", __dir__)

          FakeFS::FileSystem.clone(config)

          manager = Dbdoc::Manager.new(local_path: config)

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
  end
end
