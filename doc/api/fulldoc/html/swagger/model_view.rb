require 'hash_view'
require 'json'

class ModelView < HashView
  attr_reader :name, :properties, :description, :required

  def initialize(name, properties, description = "", required = [])
    @name = name
    @properties = properties
    @description = description
    @required = required
  end

  def self.new_from_model(model)
    lines = model.text.lines.to_a
    json = JSON::parse(lines[1..-1].join)
    new(lines[0].strip, 
        json["properties"], 
        json["description"] ? json["description"] : "",
        json["required"] ? json["required"] : [])
  end

  def json_schema
    {
      name => {
        "id" => name,
        "description" => description,
        "required" => required,
        "properties" => properties
      }
    }
  end
end