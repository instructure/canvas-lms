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

include Helpers::ModuleHelper
include Helpers::FilterHelper

module YARD::Templates::Helpers::HtmlHelper
  def topicize(str)
    str.gsub(' ', '_').underscore
  end
end

def init
  options[:objects] = run_verifier(options[:objects])
  options[:resources] = options[:objects].
    group_by { |o| o.tags('API').first.text }.
    sort_by  { |o| o.first }

  options[:page_title] = "Canvas LMS REST API Documentation"

  generate_assets
  serialize_index
  serialize_static_pages

  options.delete(:objects)

  options[:resources].each do |resource, controllers|
    serialize_resource(resource, controllers)
  end
end

def serialize(object)
  options[:object] = object
  Templates::Engine.with_serializer(object, options[:serializer]) do
    T('layout').run(options)
  end
end

def serialize_resource(resource, controllers)
  options[:object] = resource
  options[:controllers] = controllers
  Templates::Engine.with_serializer("#{topicize resource}.html", options[:serializer]) do
    T('layout').run(options)
  end
  options.delete(:controllers)
end

def serialize_index
  options[:file] = "doc/templates/rest/README.md"
  serialize('index.html')
  options.delete(:file)
end

def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

def generate_assets
  %w( css/common.css ).each do |file|
    asset(file, file(file, true))
  end
end


def serialize_static_pages
  Dir.glob("doc/templates/rest/*.md").each do |file|
    options[:file] = file
    serialize(File.split(file).last.sub(/\..*$/, '.html'))
    options.delete(:file)
  end
end
