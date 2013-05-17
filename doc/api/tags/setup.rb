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
  generic_tag :response_field
end

def argument
  generic_tag :argument, :no_types => false, :label => "Request Parameters"
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

