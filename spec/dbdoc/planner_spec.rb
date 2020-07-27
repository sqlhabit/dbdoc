require "spec_helper"

describe Dbdoc::Planner do
  let(:planner) { Dbdoc::Planner.new }

  describe "#plan" do
    it "returns true" do
      expect(planner.plan).to be true
    end
  end
end
