require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'return_view'

describe ReturnView do
  context "with no type" do
    it "raises an exception" do
      expect { ReturnView.new nil }.to raise_error
    end
  end

  context "with type" do
    let(:view) { ReturnView.new "Type" }

    it "tells its type" do
      view.type.should == "Type"
    end

    it "is not an array" do
      view.array?.should_not be_true
    end

    it "converts to swagger hash" do
      view.to_swagger.should == { "type" => "Type" }
    end
  end

  context "with array" do
    let(:view) { ReturnView.new "[Type]" }

    it "tells its type" do
      view.type.should == "Type"
    end

    it "is an array" do
      view.array?.should be_true
    end

    it "converts to swagger hash" do
      view.to_swagger.should == { "type" => "array", "items" => { "$ref" => "Type" } }
    end
  end
end