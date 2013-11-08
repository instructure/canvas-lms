require 'hash_view'
require 'json'

class ModelView < HashView
  attr_reader :name, :properties

  def initialize(name, properties)
    @name = name
    @properties = properties
  end

  def self.new_from_model(model)
    lines = model.text.lines.to_a
    json = JSON::parse(lines[1..-1].join)
    new(lines[0].strip, json["properties"])
  end

  def json_schema
    {
      name => {
        "id" => name,
        "properties" => properties
      }
    }
  end
end