require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'model_view'

describe ModelView do
  let(:text) { "Example\n{ \"properties\": [] }" }
  let(:model) { stub('Model', :text => text) }

  it "is created from model" do
    view = ModelView.new_from_model(model)
    view.name.should == "Example"
    view.properties.should == []
  end

  it "generates a schema" do
    view = ModelView.new("Example", {"name" => {"type" => "string"}})
    view.json_schema.should == {
      "Example" => {
        "id" => "Example",
        "properties" => {
          "name" => {
            "type" => "string"
          }
        }
      }
    }
  end
end