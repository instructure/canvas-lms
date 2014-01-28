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
  if options[:all_resources]
    options[:controllers] = options[:resources].map { |r,c| c }.flatten
    sections :header, :method_details_list, [T('method_details')]
  else
    sections :header, [:topic_doc, :method_details_list, [T('method_details')]]
    @resource = object
    @beta = options[:controllers].any? { |c| c.tag('beta') }
  end
end

def method_details_list
  @meths = options[:controllers].map { |c| c.meths(:inherited => false, :included => false) }.flatten
  @meths = run_verifier(@meths)
  erb(:method_details_list)
end

def topic_doc
  @docstring = options[:controllers].map { |c| c.docstring }.join("\n\n")
  @object = @object.dup
  def @object.source_type; nil; end
  @json_objects = options[:json_objects][@resource] || []
  erb(:topic_doc)
end

def properties_of_model(json)
  require 'json'
  JSON::parse(json)['properties']
rescue JSON::ParserError
  nil
end

def word_wrap(text, col_width=80)
   text.gsub!( /(\S{#{col_width}})(?=\S)/, '\1 ' )
   text.gsub!( /(.{1,#{col_width}})(?:\s+|$)/, "\\1\n" )
   text
end

def indent(str, amount = 2, char = ' ')
  str.gsub(/^/, char * amount)
end

def render_comment(string, wrap = 75)
  if string
    indent(word_wrap(string), 2, '/')
  else
    ""
  end
end

def render_value(value, type = 'string')
  case type
  when 'integer', 'number' then value.to_s
  else %{"#{value}"}
  end
end

def render_properties(json)
  if properties = properties_of_model(json)
    "{\n" + indent(
    properties.map do |name, prop|
      "\n" + render_comment(prop['description']) +
      %{"#{name}": } + render_value(prop['example'], prop['type'])
    end.join(",\n")) +
    "\n}"
  end
end