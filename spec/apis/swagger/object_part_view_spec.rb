require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'object_part_view'

describe ObjectPartView do
  let(:name) { "Tag" }
  let(:part) { {"id" => 1, "name" => "Jimmy Wales"} }
  let(:view) { ObjectPartView.new(name, part) }

  it "guesses types" do
    expect(view.guess_type("hey")).to eq({"type" => "string"})
  end

  it "renders properties" do
    expect(view.properties["id"]).to eq(
      {
        "type" => "integer",
        "format" => "int64"
      }
    )
    expect(view.properties["name"]).to eq(
      {
        "type" => "string"
      }
    )
  end
end
