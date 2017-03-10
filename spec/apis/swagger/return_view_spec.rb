require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'return_view'

describe ReturnView do
  context "with no type" do
    it "raises an exception" do
      expect { ReturnView.new nil }.to raise_error("@return type required")
    end
  end

  context "with type" do
    let(:view) { ReturnView.new "Type" }

    it "tells its type" do
      expect(view.type).to eq "Type"
    end

    it "is not an array" do
      expect(view.array?).not_to be_truthy
    end

    it "converts to swagger hash" do
      expect(view.to_swagger).to eq({ "type" => "Type" })
    end
  end

  context "with array" do
    let(:view) { ReturnView.new "[Type]" }

    it "tells its type" do
      expect(view.type).to eq "Type"
    end

    it "is an array" do
      expect(view.array?).to be_truthy
    end

    it "converts to swagger hash" do
      expect(view.to_swagger).to eq({ "type" => "array", "items" => { "$ref" => "Type" } })
    end
  end
end
