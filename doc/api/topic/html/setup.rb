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

def word_wrap(text, col_width=80)
   text.gsub!( /(\S{#{col_width}})(?=\S)/, '\1 ' )
   text.gsub!( /(.{1,#{col_width}})(?:\s+|$)/, "\\1\n" )
   text
end

def indent(str, amount = 2, char = ' ')
  str.gsub(/^/, char * amount)
end

def render_comment(string)
  if string
    indent(word_wrap(string), 1, '// ')
  else
    ""
  end
end

def render_value(prop)
  value = prop['example']

  return "null" if value.nil?

  if prop['$ref']
    # we don't fully support $refs yet in these generated docs, but some of our
    # docs include an example sub-object so let's at least render that
    return JSON.generate(value)
  end

  case prop['type']
  when 'array'
    "[#{value.map { |v| render_value(prop['items'].merge('example' => v)) }.join(', ')}]"
  when 'object'
    JSON.generate(value)
  when 'integer', 'number', 'boolean' then value.to_s
  when 'string', 'datetime' then %{"#{value}"}
  else
    raise ArgumentError, %{invalid or missing "type" in API property: #{prop.inspect}}
  end
end

def render_properties(json)
  json = JSON.parse(json)
  if (properties = json['properties'])
    result = ''
    if json['description'].present?
      result << render_comment(json['description'])
    end
    result << "{\n" + indent(
    properties.map do |name, prop|
      render_comment(prop['description']) +
      %{"#{name}": } + render_value(prop)
    end.join(",\n")) +
    "\n}"
  end
rescue
  puts "error rendering properties for model:\n#{json}"
  raise
end
