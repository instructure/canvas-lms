# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require "active_support/core_ext/module"

module CanvasLinkMigrator
  class ImportedHtmlConverter
    attr_reader :link_parser, :link_resolver, :migration_id_converter

    def initialize(resource_map: nil, migration_id_converter: nil)
      @migration_id_converter = migration_id_converter || ResourceMapService.new(resource_map)
      @link_parser = LinkParser.new(@migration_id_converter)
      @link_resolver = LinkResolver.new(@migration_id_converter)
    end

    delegate :convert, to: :link_parser
    delegate :resolver_links!, to: :link_resolver

    def convert_exported_html(input_html)
      new_html = link_parser.convert(input_html, "type", "lookup_id", "field")
      replace!(new_html)

      # missing links comes back as a list for all types and fields, but if the user's only
      # sending one piece of html at a time, we only need the first set of missing links,
      # and only the actual missing links, not the look up information we set in this method
      bad_links = missing_links&.first&.dig(:missing_links)
      link_parser.reset!
      [new_html, bad_links]
    end

    def replace!(placeholder_html)
      link_map = link_parser.unresolved_link_map
      return unless link_map.present?

      link_resolver.resolve_links!(link_map)
      LinkReplacer.sub_placeholders!(placeholder_html, link_map.values.map(&:values).flatten)
      placeholder_html
    end

    def missing_links
      link_parser.unresolved_link_map.each_with_object([]) do |(item_key, field_links), bad_links|
        field_links.each do |field, links|
          unresolved_links = links.select { |link| link[:replaced] && (link[:missing_url] || !link[:new_value]) }
          unresolved_links = unresolved_links.map { |link| link.slice(:link_type, :missing_url) }
          next unless unresolved_links.any?

          bad_links << { object_lookup_id: item_key[:migration_id], object_type: item_key[:type], object_field: field, missing_links: unresolved_links }
        end
      end
    end
  end
end
