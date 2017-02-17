require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'model_view'

describe ModelView do
  let(:text) { "Example\n{ \"properties\": [] }" }
  let(:model) { stub('Model', :text => text) }

  it "is created from model" do
    view = ModelView.new_from_model(model)
    expect(view.name).to eq "Example"
    expect(view.properties).to eq []
  end

  it "generates a schema" do
    view = ModelView.new("Example", {"name" => {"type" => "string"}})
    expect(view.json_schema).to eq({
      "Example" => {
        "id" => "Example",
        "properties" => {
          "name" => {
            "type" => "string"
          }
        },
        "description" => "",
        "required" => []
      }
    })
  end
end
