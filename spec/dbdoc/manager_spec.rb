require "spec_helper"

describe Dbdoc::Manager do
  let(:manager) { Dbdoc::Manager.new }

  describe "#plan" do
    it "returns true" do
      expect(manager.plan).to be true
    end
  end
end
