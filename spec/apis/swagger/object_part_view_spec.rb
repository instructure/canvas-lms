require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'object_part_view'

describe ObjectPartView do
  let(:name) { "Tag" }
  let(:part) { {"id" => 1, "name" => "Jimmy Wales"} }
  let(:view) { ObjectPartView.new(name, part) }

  it "guesses types" do
    view.guess_type("hey").should == {"type" => "string"}
  end

  it "renders properties" do
    view.properties["id"].should ==
      {
        "type" => "integer",
        "format" => "int64"
      }
    view.properties["name"].should ==
      {
        "type" => "string"
      }
  end
end