require 'json'
require 'hash_view'
require 'object_part_view'
require 'model_view'

class ObjectView < HashView
  SEP = '=|='

  attr_reader :object

  # The 'object' passed in is a YARD element with a #text method that
  # returns the full JSON text of the @object being described by the API docs.
  # It's possible that 'object' has multiple JSON parts.
  def initialize(object)
    @object = object
  end

  def text
    @object.text
  end

  def name
    text.lines.first.chomp
  end

  def json_text
    text.sub(/^.*$/, '')
  end

  def clean_json_text
    ObjectView.strip_comments(json_text)
  end

  # Some @object descriptions have multiple JSON parts.
  # See e.g. AccountAuthorizationConfig
  def clean_json_text_parts
    clean_json_text.gsub(/(\})\s+(\{)/, "\\1#{SEP}\\2").split(SEP)
  end

  def clean_json_parts
    clean_json_text_parts.map{ |text| JSON::parse(text) }
  end

  def parts
    @parts ||= clean_json_parts.map{ |part| ObjectPartView.new(name, part) }
  end

  def properties
    parts.inject({}) do |base, view|
      base.merge(view.properties)
    end
  end

  def to_model
    ModelView.new(name, properties)
  end

  def self.strip_comments(str)
    str.gsub(%r(//[^\n\"]+$), '')
  end
end