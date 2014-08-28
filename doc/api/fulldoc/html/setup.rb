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

$:.unshift(File.join(File.dirname(__FILE__), 'swagger'))
require 'controller_list_view'

include Helpers::ModuleHelper
include Helpers::FilterHelper

module YARD::Templates::Helpers::BaseHelper

  def linkify_with_api(*args)
    # References to controller actions
    #
    # Syntax: api:ControllerName#method_name [TITLE OVERRIDE]
    #
    # @example Explicit reference with title defaulting to the action
    #  # @see api:Assignments#create
    #  # => <a href="assignments.html#method.assignments_api.create">create</a>
    #
    # @example Inline reference with an overriden title
    #   # Here's a link to absolute {api:Assignments#destroy destruction}
    #   # => <a href="assignments.html#method.assignments_api.destroy">destruction</a>
    #
    # @note Action links inside the All Resources section will be relative.
    if args.first.is_a?(String) && args.first =~ %r{^api:([^#]+)#(.*)}
      topic, controller = *lookup_topic($1.to_s)
      if topic
        html_file = "#{topicize topic.first}.html"
        action = $2
        link_url("#{html_file}#method.#{topicize(controller.name.to_s).sub("_controller", "")}.#{action}", args[1])
      else
        raise "couldn't find API link for #{args.first}"
      end

    # References to API objects defined by @object
    #
    # Syntax: api:ControllerName:Object+Name [TITLE OVERRIDE]
    #
    # @example Explicit resource reference with title defaulting to its name
    #   # @see api:Assignments:Assignment
    #   # => <a href="assignments.html#Assignment">Assignment</a>
    #
    # @example Explicit resource reference with an overriden title
    #   # @return api:Assignments:AssignmentOverride An Assignment Override
    #   # => <a href="assignments.html#Assignment">An Assignment Override</a>
    elsif args.first.is_a?(String) && args.first =~ %r{^api:([^:]+):(.*)}
      scope_name, resource_name = $1.downcase, $2.gsub('+', ' ')
      link_url("#{scope_name}.html##{resource_name}", args[1] || resource_name)
    elsif args.first.is_a?(String) && args.first == 'Appendix:' && args.size > 1
      __errmsg = "unable to locate referenced appendix '#{args[1]}'"

      unless appendix = lookup_appendix(args[1].to_s)
        raise __errmsg
      end

      topic, controller = *lookup_topic(appendix.namespace.to_s)

      if topic
        html_file = "#{topicize topic.first}.html"
        bookmark = "#{appendix.name.to_s.gsub(' ', '+')}-appendix"
        ret = link_url("#{html_file}##{bookmark}", appendix.title)
      else
        raise __errmsg
      end

    # A non-API link, delegate to YARD's HTML linker
    else
      linkify_without_api(*args)
    end
  end

  alias_method :linkify_without_api, :linkify
  alias_method :linkify, :linkify_with_api

  def lookup_topic(controller_path)
    controller = nil
    topic = options[:resources].find { |r,cs|
      cs.any? { |c|
        controller = c if c.path.to_s == controller_path
        !controller.nil?
      }
    }

    [ topic, controller ]
  end

  def lookup_appendix(title)
    appendix = nil

    if object
      # try in the object scope
      appendix = YARD::Registry.at(".appendix.#{object.path}.#{title}")

      # try in the object's namespace scope
      if appendix.nil? && object.respond_to?(:namespace)
        appendix = YARD::Registry.at(".appendix.#{object.namespace.path}.#{title}")
      end
    end

    appendix
  end
end

module YARD::Templates::Helpers::HtmlHelper
  def topicize(str)
    str.gsub(' ', '_').underscore
  end

  def url_for_file(filename, anchor = nil)
    link = filename.filename
    link += (anchor ? '#' + urlencode(anchor) : '')
    link
  end

  # override yard-appendix link_appendix
  def link_appendix(ref)
    __errmsg = "unable to locate referenced appendix '#{ref}'"

    unless appendix = lookup_appendix(ref.to_s)
      raise __errmsg
    end

    topic, controller = *lookup_topic(appendix.namespace.to_s)

    unless topic
      raise __errmsg
    end

    html_file = "#{topicize topic.first}.html"
    bookmark = "#{appendix.name.to_s.gsub(' ', '+')}-appendix"
    link_url("#{html_file}##{bookmark}", appendix.title)
  end
end

def init
  options[:objects] = run_verifier(options[:objects])
  options[:resources] = options[:objects].
    group_by { |o| o.tags('API').first.text }.
    sort_by  { |o| o.first }
  generate_swagger_json

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

def generate_swagger(filename, json)
  output_dir = File.join(%w(public doc api))
  FileUtils.mkdir_p output_dir

  path = File.join(output_dir, filename)
  File.open(path, "w") do |file|
    file.puts JSON.pretty_generate(json)
  end
end

def generate_swagger_json
  api_resources = []
  model_resources = []
  options[:resources].each do |name, controllers|
    view = ControllerListView.new(name, controllers)
    api_resources << view.swagger_reference
    generate_swagger(view.swagger_file, view.swagger_api_listing)
  end

  resource_listing = {
    "apiVersion" => "1.0",
    "swaggerVersion" => "1.2",
    "apis" => api_resources
  }

  generate_swagger("api-docs.json", resource_listing)
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
  (Dir[asset_root + "css/**/*.css"] + Dir[asset_root + "js/**/*.js"] + [asset_root + "live.html"]).each do |file|
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
      (controller.tags(:object) + controller.tags(:model)).each do |obj|
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
