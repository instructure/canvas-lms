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

module YARD::Templates::Helpers::BaseHelper
  def linkify_with_api(*args)
    if args.first.is_a?(String) && args.first =~ %r{^api:([^#]+)#(.*)}
      topic = options[:resources].find { |r,cs| cs.any? { |c| c.name.to_s == $1 } }
      if topic
        controller = topic.last.find { |c| c.name.to_s == $1 }
        html_file = "#{topicize topic.first}.html"
        action = $2
        link_url("#{html_file}#method.#{topicize(controller.name.to_s).sub("_controller", "")}.#{action}", args[1])
      else
        raise "couldn't find API link for #{args.first}"
      end
    elsif args.first.is_a?(String) && args.first =~ %r{^api:([^:]+):(.*)}
      link_url("#{$1.downcase}.html##{$2.gsub('+', ' ')}", args[1])
    else
      linkify_without_api(*args)
    end
  end
  alias_method :linkify_without_api, :linkify
  alias_method :linkify, :linkify_with_api
end

def init
  options[:objects] = run_verifier(options[:objects])
  options[:resources] = options[:objects].
    group_by { |o| o.tags('API').first.text }.
    sort_by  { |o| o.first }

  options[:page_title] = "Canvas LMS REST API Documentation"

  build_json_objects_map
  generate_assets
  serialize_index
  serialize_static_pages

  options.delete(:objects)

  options[:all_resources] = true
  options[:object] = "all_resources.html"
  Templates::Engine.with_serializer("all_resources.html", options[:serializer]) do
    T('layout').run(options)
  end
  options.delete(:all_resources)

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
  options[:file] = "doc/api/README.md"
  serialize('index.html')
  options.delete(:file)
end

def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

def generate_assets
  require 'pathname'
  asset_root = Pathname.new(File.dirname(__FILE__))
  (Dir[asset_root + "css/**/*.css"] + Dir[asset_root + "js/**/*.js"]).each do |file|
    file = Pathname.new(file).relative_path_from(asset_root).to_s
    asset(file, file(file, true))
  end
end

# we used to put .md files at just filename.html, but it turns out that
# deep within Yard, there is hard-coded assumptions about static files
# being named file.filename.html, so we moved them over, and this makes
# a redirect at the old name so people's old bookmarks don't 404
def serialize_redirect(filename)
  path = File.join(options[:serializer].basepath, filename)
  File.open(path, "wb") do |file|
    file.write <<-HTML
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title>#{options[:page_title]}</title>
<meta http-equiv="REFRESH" content="0;url=file.#{filename}"></HEAD>
<BODY>
This page has moved. You will be redirected automatically, or you can <a href="file.#{filename}">click here</a> to go to the new page.
</BODY>
</HTML>
HTML
  end
end

def serialize_static_pages
  Dir.glob("doc/api/*.md").each do |file|
    options[:file] = file
    filename = File.split(file).last.sub(/\..*$/, '.html')
    serialize("file." + filename)
    serialize_redirect(filename)
    options.delete(:file)
  end
end

def build_json_objects_map
  obj_map = {}
  resource_obj_list = {}
  options[:resources].each do |r,cs|
    cs.each do |controller|
      controller.tags(:object).each do |obj|
        name, json = obj.text.split(%r{\n+}, 2).map(&:strip)
        obj_map[name] = topicize r
        resource_obj_list[r] ||= []
        resource_obj_list[r] << [name, json]
      end
    end
  end
  options[:json_objects_map] = obj_map
  options[:json_objects] = resource_obj_list
end
