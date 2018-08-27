#
# Copyright (C) 2011 Instructure, Inc.
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

def init
  super
  sections :argument, :request_field, :response_field, :example_request, :example_response, :returns, :see
end

def see
  return unless object.has_tag?(:see)
  erb(:see)
end

def request_field
  generic_tag :request_field
end

def response_field
  return unless object.has_tag?(:response_field) || object.has_tag?(:deprecated_response_field)
  response_field_tags = object.tags.select { |tag| tag.tag_name == 'response_field' || tag.tag_name == 'deprecated_response_field' }
  @response_fields = response_field_tags.map do |tag|
    ResponseFieldView.new(tag)
  end

  erb('response_fields')
end

def argument
  return unless object.has_tag?(:argument) || object.has_tag?(:deprecated_argument)
  argument_tags = object.tags.select { |tag| tag.tag_name == 'argument' || tag.tag_name == 'deprecated_argument' }
  @request_parameters = argument_tags.map do |tag|
    ArgumentView.new(tag.text, deprecated: tag.tag_name == 'deprecated_argument')
  end

  erb('request_parameters')
end

def returns
  return unless object.has_tag?(:returns)
  response_info = object.tag(:returns)
  case response_info.text
  when %r{\[(.*)\]}
    @object_name = $1.strip
    @is_list = true
  else
    @object_name = response_info.text.strip
    @is_list = false
  end
  @resource_name = options[:json_objects_map][@object_name]
  return unless @resource_name
  erb(:returns)
end

def generic_tag(name, opts = {})
  return unless object.has_tag?(name)
  @no_names = true if opts[:no_names]
  @no_types = true if opts[:no_types]
  @label = opts[:label]
  @name = name
  out = erb('generic_tag')
  @no_names, @no_types = nil, nil
  out
end
