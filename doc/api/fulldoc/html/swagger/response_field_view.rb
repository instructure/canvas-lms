#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative 'canvas_api/deprecatable'
require 'hash_view'

class ResponseFieldView < HashView
  include CanvasAPI::Deprecatable

  attr_reader :types, :effective_date, :notice_date

  def initialize(tag)
    line = tag.text
    @deprecated = tag.tag_name == 'deprecated_response_field'
    @deprecated_date_key = :NOTICE
    @effective_date_key = :EFFECTIVE
    @tag_declaration_line = line
    @name, @description = parse_line(line)
    @types = tag.types
  end

  def parse_line(line)
    if deprecated?
      parse_deprecation_info(line)
      name_and_remaining = line_without_deprecation_tags(line)
    else
      name_and_remaining = line
    end

    name, remaining = (name_and_remaining || "").split(/\s+/, 2)
    raise(ArgumentError, "param name missing:\n#{line}") unless name

    raise(ArgumentError, "Expected a description to be present, but it was not provided.\n#{line}") if remaining.nil?
    description = remaining.strip
    [name, description]
  end

  def name
    format(@name)
  end

  def description
    format(@description)
  end

  def to_swagger
    {
      "name" => name,
      "description" => description,
      "deprecated" => deprecated?
    }
  end
end
