# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative "canvas_api/deprecatable"
require "hash_view"

class ArgumentView < HashView
  include CanvasAPI::Deprecatable

  attr_reader :line, :http_verb, :path_variables, :effective_date, :notice_date
  attr_reader :type

  DEFAULT_TYPE = "[String]"
  DEFAULT_DESC = "no description"

  def initialize(line, http_verb = "get", path_variables = [], deprecated: false)
    super()
    @deprecated = deprecated
    @deprecated_date_key = :NOTICE
    @effective_date_key = :EFFECTIVE
    @tag_declaration_line = line
    @line, @name, @type, @desc = parse_line(line)
    @http_verb = http_verb
    @path_variables = path_variables
    parse_line(@line)
  end

  def parse_line(line)
    if deprecated?
      parse_deprecation_info(line)
      name_and_remaining = line_without_deprecation_tags(line)
    else
      name_and_remaining = line
    end

    name, remaining = (name_and_remaining || "").split(/\s/, 2)
    raise(ArgumentError, "param name missing:\n#{line}") unless name

    type, desc = split_type_desc(remaining || "")
    [line, name.strip, type.strip, desc.strip]
  end

  def split_type_desc(str)
    # This regex is impossible to read, basically we're splitting the string up
    # into the first [bracketed] section, which might contain internal brackets,
    # and then the rest of the string.
    md = str.strip.match(/\A(\[[\w ,\[\]|"]+\])?\s*(.+)?/m)
    [md[1] || DEFAULT_TYPE, md[2] || DEFAULT_DESC]
  end

  def name(json: true)
    name = json ? @name.gsub("[]", "") : @name
    format(name)
  end

  def desc
    format(@desc)
  end

  def remove_outer_square_brackets(str)
    str.sub(/^\[/, "").sub(/\]$/, "")
  end

  def metadata_parts
    remove_outer_square_brackets(@type)
      .split(/\s*[,|]\s*/).map { |t| t.force_encoding("UTF-8") }
  end

  def enum_and_types
    metadata_parts.partition { |t| t.include? '"' }
  end

  def enums
    enum_and_types.first.map { |e| e.delete('"') }
  end

  def types
    enum_and_types.last.reject do |t|
      %w[optional required].include?(t.downcase)
    end
  end

  def swagger_param_type
    if @path_variables.include? name
      "path"
    else
      case @http_verb.downcase
      when "get", "delete" then "query"
      when "put", "post", "patch" then "form"
      else
        raise "Unknown HTTP verb: #{@http_verb}"
      end
    end
  end

  def swagger_type
    type = types.first || "string"
    type = "number" if type.casecmp?("float")
    builtin?(type) ? type.downcase : type
  end

  def swagger_format
    type = types.first || "string"
    return "int64" if swagger_type == "integer"

    "float" if type.casecmp?("float")
  end

  def optional?
    !required?
  end

  def required?
    types = enum_and_types.last.map(&:downcase)
    swagger_param_type == "path" || types.include?("required")
  end

  def array?
    @name.include?("[]")
  end

  def builtin?(type)
    %w[string integer boolean number].include?(type.downcase)
  end

  def to_swagger
    swagger = {
      "paramType" => swagger_param_type,
      "name" => name,
      "description" => desc,
      "type" => swagger_type,
      "format" => swagger_format,
      "required" => required?,
      "deprecated" => deprecated?,
    }
    swagger["enum"] = enums unless enums.empty?
    if array?
      swagger["type"] = "array"
      items = {}
      if builtin?(swagger_type)
        items["type"] = swagger_type
      else
        items["$ref"] = swagger_type
      end
      swagger["items"] = items
    end
    swagger
  end

  def to_hash
    {
      "name" => name,
      "desc" => desc,
      "types" => types,
      "optional" => optional?,
    }
  end
end
