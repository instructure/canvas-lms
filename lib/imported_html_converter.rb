#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'nokogiri'

class ImportedHtmlConverter
  include TextHelper
  include HtmlTextHelper

  CONTAINER_TYPES = ['div', 'p', 'body']
  LINK_ATTRS = ['rel', 'href', 'src', 'data', 'value']

  attr_reader :link_parser, :link_resolver, :link_replacer

  def initialize(migration)
    @migration = migration
    @link_parser = Importers::LinkParser.new(migration)
    @link_resolver = Importers::LinkResolver.new(migration)
    @link_replacer = Importers::LinkReplacer.new(migration)
  end

  def convert(html, item_type, mig_id, field, opts={})
    mig_id = mig_id.to_s
    doc = Nokogiri::HTML(html || "")
    doc.search("*").each do |node|
      LINK_ATTRS.each do |attr|
        @link_parser.convert_link(node, attr, item_type, mig_id, field)
      end
    end

    node = doc.at_css('body')
    return "" unless node
    if opts[:remove_outer_nodes_if_one_child]
      while node.children.size == 1 && node.child.child
        break unless CONTAINER_TYPES.member?(node.child.name) && node.child.attributes.blank?
        node = node.child
      end
    end

    node.inner_html
  rescue Nokogiri::SyntaxError
    ""
  end

  def convert_text(text)
    format_message(text || "")[0]
  end

  def resolve_content_links!
    link_map = @link_parser.unresolved_link_map
    return unless link_map.present?

    @link_resolver.resolve_links!(link_map)
    @link_replacer.replace_placeholders!(link_map)
    @link_parser.reset!
  end

  def self.relative_url?(url)
    URI.parse(url).relative? && !url.to_s.start_with?("//")
  rescue URI::Error
    # leave the url as it was
    Rails.logger.warn "attempting to translate invalid url: #{url}"
    false
  end

end
