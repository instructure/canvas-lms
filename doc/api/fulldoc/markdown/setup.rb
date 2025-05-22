# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "html", "swagger"))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "html", "api_scopes"))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "decorator"))

require "controller_list_view"
require "api_scope_mapping_writer"
require "decorator"
require "fileutils"
require "nokogiri"

Rails.root.glob("doc/api/data_services/*.rb").sort.each { |file| require file }

include Helpers::ModuleHelper
include Helpers::FilterHelper
include YARD::Templates::Helpers::HtmlHelper
include Decorator

module YARD::Templates::Helpers::BaseHelper
  def linkify_with_api(*args)
    # References to controller actions
    #
    # Syntax: api:ControllerName#method_name [TITLE OVERRIDE]
    #
    # @example Explicit reference with title defaulting to the action
    #  # @see api:Assignments#create
    #  # => <a href="assignments.md#method.assignments_api.create">create</a>
    #
    # @example Inline reference with an overriden title
    #   # Here's a link to absolute {api:Assignments#destroy destruction}
    #   # => <a href="assignments.md#method.assignments_api.destroy">destruction</a>
    #
    # @note Action links inside the All Resources section will be relative.
    if args.first.is_a?(String) && args.first =~ /^api:([^#]+)#(.*)/
      topic, controller = *lookup_topic($1.to_s)
      if topic
        md_file = "#{topicize topic.first}.md"
        action = $2
        name = controller.name.to_s
        name = "#{controller.namespace.name}/#{name}" if controller.namespace.name != :root
        link_url("#{md_file}#method.#{topicize(name).sub("_controller", "")}.#{action}", args[1])
      else
        raise "couldn't find API link for #{args.first}"
      end

    # References to API objects defined by @object
    #
    # Syntax: api:ControllerName:Object+Name [TITLE OVERRIDE]
    #
    # @example Explicit resource reference with title defaulting to its name
    #   # @see api:Assignments:Assignment
    #   # => <a href="assignments.md#Assignment">Assignment</a>
    #
    # @example Explicit resource reference with an overriden title
    #   # @return api:Assignments:AssignmentOverride An Assignment Override
    #   # => <a href="assignments.md#Assignment">An Assignment Override</a>
    elsif args.first.is_a?(String) && args.first =~ /^api:([^:]+):(.*)/
      scope_name, resource_name = $1.downcase, $2.tr("+", " ")
      link_url("#{scope_name}.md##{resource_name}", args[1] || resource_name)
    elsif args.first.is_a?(String) && args.first == "Appendix:" && args.size > 1
      errmsg = "unable to locate referenced appendix '#{args[1]}'"

      unless (appendix = lookup_appendix(args[1].to_s))
        raise errmsg
      end

      topic, _controller = *lookup_topic(appendix.namespace.to_s)

      if topic
        md_file = "#{topicize topic.first}.md"
        bookmark = "#{appendix.name.to_s.tr(" ", "+")}-appendix"
        link_url("#{md_file}##{bookmark}", appendix.title)
      else
        raise errmsg
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
    topic = options[:resources].find do |_r, cs|
      cs.any? do |c|
        controller = c if c.path.to_s == controller_path
        !controller.nil?
      end
    end

    [topic, controller]
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
  include CanvasAPI::Deprecatable

  def topicize(str)
    str.tr(" ", "_").underscore
  end

  def trim_and_br(str)
    str.strip.gsub(/\n+/, "<br>")
  end

  def make_api_doc_anchors(hash, _)
    anchors = []
    hash.each do |key, val|
      link = url_for(key.to_s)
      anchors << "[#{val}](#{link})"
    end
    anchors
  end

  def url_for_file(filename, anchor = nil)
    link = filename.filename
    link += (anchor ? "#" + urlencode(anchor) : "")
    link
  end

  # override yard-appendix link_appendix
  def link_appendix(ref)
    errmsg = "unable to locate referenced appendix '#{ref}'"

    unless (appendix = lookup_appendix(ref.to_s))
      raise errmsg
    end

    topic, _controller = *lookup_topic(appendix.namespace.to_s)

    unless topic
      raise errmsg
    end

    md_file = "#{topicize topic.first}.md"
    bookmark = "#{appendix.name.to_s.tr(" ", "+")}-appendix"
    link_url("#{md_file}##{bookmark}", appendix.title)
  end
end

def init
  # Target path for generated files
  output_path = options[:serializer].instance_variable_get(:@basepath)

  options[:objects] = run_verifier(options[:objects])
  options[:resources] = options[:objects]
                        .group_by { |o| o.tags("API").first.text }
                        .sort_by  { |o| o.first.downcase }
  generate_data_services_markdown_pages
  scope_writer = ApiScopeMappingWriter.new(options[:resources])
  scope_writer.generate_scope_mapper

  options[:page_title] = "Canvas LMS REST API Documentation"

  build_json_objects_map

  serialize_index
  serialize_markdown_pages

  options.delete(:objects)

  options[:all_resources] = true
  options[:object] = "all_resources.md"
  Templates::Engine.with_serializer("all_resources.md", options[:serializer]) do
    T("layout").run(options)
  end
  options.delete(:all_resources)

  options[:resources].each do |resource, controllers|
    serialize_resource(resource, controllers)
  end

  generate_toc(output_path)

  # Post-processing steps. These should be called after
  # all the Markdown files are generated.
  Dir.glob("#{output_path}/**/*.md").each do |filename|
    content = File.read(filename)
    transformations = [
      method(:transform_html_links),
      method(:transform_warning_divs),
      method(:transform_dls)
    ]

    transformed_content = transformations.reduce(content) do |acc, transform|
      transform.call(acc)
    end

    File.binwrite(filename, transformed_content)
  end
end

def serialize(object, page_title: nil)
  file_opts = {}
  file_opts[:page_title] = page_title + " - " + options[:page_title] if page_title
  options[:object] = object
  Templates::Engine.with_serializer(object, options[:serializer]) do
    T("layout").run(options.merge(file_opts))
  end
end

def serialize_resource(resource, controllers)
  options[:object] = resource
  options[:controllers] = controllers
  Templates::Engine.with_serializer("#{topicize resource}.md", options[:serializer]) do
    T("layout").run(options.merge(page_title: resource + " - " + options[:page_title]))
  end
  options.delete(:controllers)
end

def serialize_index
  options[:file] = "doc/api/README.md"
  serialize("README.md")
  options.delete(:file)
end

def extract_page_title_from_markdown(file)
  File.open(file).readline
end

def generate_data_services_markdown_pages
  DataServicesMarkdownCreator.run
end

def serialize_markdown_pages
  (Dir.glob("doc/api/*.md") + Dir.glob("doc/api/data_services/md/**/*.md")).each do |file|
    options[:file] = file
    filename = File.split(file).last
    serialize("file." + filename, page_title: extract_page_title_from_markdown(file))
    options.delete(:file)
  end
end

def build_json_objects_map
  obj_map = {}
  resource_obj_list = {}
  options[:resources].each do |r, cs|
    cs.each do |controller|
      (controller.tags(:object) + controller.tags(:model)).each do |obj|
        name, json = obj.text.split(/\n+/, 2).map(&:strip)
        obj_map[name] = topicize r
        resource_obj_list[r] ||= []
        resource_obj_list[r] << [name, json]
      end
    end
  end
  options[:json_objects_map] = obj_map
  options[:json_objects] = resource_obj_list
end

def generate_toc(output_path)
  source_template_file = File.read("doc/api/fulldoc/markdown/sidebar/sidebar.md.erb")
  erb_renderer = ERB.new(source_template_file)
  File.binwrite("#{output_path}/toc.md", erb_renderer.result(binding))
end

# Replace all the anchor tags that point to HTML files with links to
# the corresponding markdown file. Also remove the target="_blank" attribute
def transform_html_links(content)
  # matches HTML-style anchors with URLs ending in .html or .html#fragment
  html_link_regex = /<a\s*href="([^"]+\.html(?:#[^"]*)?)"[^>]*>/

  modified_content = content.gsub(html_link_regex) do |match|
    url = $1
    match = match.gsub(".html", ".md") unless url.start_with?("http", "https")
    match
  end

  # matches Markdown-style links with URLs ending in .html or .html#fragment
  markdown_link_regex = /\[([^\]]+)\]\(([^)]+\.html(?:#[^)]+)?)\)/

  modified_content.gsub(markdown_link_regex) do |_|
    text = $1
    url = $2
    url = url.gsub(".html", ".md") unless url.start_with?("http", "https")
    "[#{text}](#{url})"
  end
end

# Replace all the warning divs with hint tags so it can be rendered properly
def transform_warning_divs(content)
  warning_div_regex = %r{<div class="warning-message">(.*?)</div>}m
  content.gsub(warning_div_regex) do |_|
    inner_content = $1.strip
    hint("warning", inner_content)
  end
end

# Convert a <dl> lists to <ul> lists
def transform_dls(content)
  dl_regex = %r{<dl\b[^>]*>(.*?)</dl>}m
  content.gsub(dl_regex) do |dl_match|
    doc = Nokogiri::HTML.fragment(dl_match)
    markdown = "<ul>"

    doc.css("dl").each do |dl|
      dl.css("dt").each do |dt|
        dd = dt.at_xpath("following-sibling::dd")
        if dd
          markdown = "#{markdown}<li>#{dt.text.strip}<p>#{dd.text.strip}</p></li>"
        end
      end
    end

    markdown = "#{markdown}</ul>"
  end
end
