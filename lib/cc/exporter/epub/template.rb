# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub
  class Template
    include ActionView::Helpers::TagHelper
    include CC::Exporter::Epub::Converters::MediaConverter
    include CC::Exporter::Epub::Converters::ObjectPathConverter
    include TextHelper

    def initialize(content, base_template, exporter)
      @content = content[:resources] || {}
      @reference = content[:reference]
      @base_template = base_template
      @exporter = exporter
      @title = Exporter::RESOURCE_TITLES[@reference] || @content[:title]
      css = File.expand_path("../templates/css_template.css", __FILE__)
      @style = File.read(css)
    end
    attr_reader :content, :base_template, :exporter, :title, :reference, :style
    delegate :get_item, :sort_by_content, :unsupported_files, to: :exporter

    def build(item=nil)
      return if item.try(:empty?)
      template_path = template(item) || base_template
      template = File.expand_path(template_path, __FILE__)
      if File.exist?(template)
        erb = ERB.new(File.read(template))
        erb.result(binding)
      else
        Rails.logger.warn(">>> Trying to use a template that doesn't exist; skipping.")
        Rails.logger.warn(">>> item: #{item}")
        nil
      end
    end

    def parse
      Nokogiri::HTML(build, &:noblanks).to_xhtml.strip
    end

    def template(item)
      return unless item
      Exporter.resource_template(resource_type(item))
    end

    def remove_empty_ids!(node)
      node.search("a[id='']").each do |tag|
        tag.remove_attribute('id')
      end
      node
    end

    def resource_type(item)
      Exporter::LINKED_RESOURCE_KEY[item[:linked_resource_type]] || @reference
    end

    # View helpers
    def convert_placeholder_paths_from_string!(html_string)
      html_node = Nokogiri::HTML5.fragment(html_string)
      html_node.tap do |node|
        convert_media_from_node!(node)
        convert_object_paths!(node)
        remove_empty_ids!(node)
      end
      html_node.to_s
    end

    def display_prerequisites(prerequisites)
      prerequisites.map {|prerequisite| prerequisite[:title] }.join(', ')
    end

    def friendly_date(date)
      return unless date
      datetime_string(Date.parse(date))
    end

    def link_to_content_item(item)
      content = item[:title]

      if item[:href].present?
        content_tag(:a, content, href: item[:href])
      else
        HtmlTextHelper.escape_html(content)
      end
    end

    def item_details_present?(item)
      details = [:due_at, :unlock_at, :lock_at, :grading_type, :points_possible, :submission_types]
      details.any? { |detail| item[detail].present? }
    end
  end
end
