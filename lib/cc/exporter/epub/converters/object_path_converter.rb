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

module CC::Exporter::Epub::Converters
  module ObjectPathConverter
    include CC::CCHelper

    # Find `<a>` tags whose hrefs contain either the OBJECT_TOKEN or the
    # WIKI_TOKEN, and replace them with a link to the xhtml page based
    # on the path part between the placeholder and the identifer (in the
    # example below, this means `assignments`), and an anchor of the
    # identifier itself.
    #
    # Turns this:
    #
    # "$CANVAS_OBJECT_REFERENCE$/assignments/i5f4cd2e04f1089c1c5060e9761400516"
    #
    # into this:
    #
    # "assignments.xhtml#i5f4cd2e04f1089c1c5060e9761400516"
    def convert_object_paths!(html_node)
      html_node.tap do |node|
        node.search(object_path_selector).each do |tag|
          tag["href"] = href_for_tag(tag)
          replace_missing_content!(tag) unless tag["href"].present?
        end
      end
    end

    def href_for_tag(tag)
      match = tag["href"].match(%r{([a-z]+)/(.+)})
      return nil unless match.present?

      if sort_by_content
        match[1].include?("module") ? nil : "#{match[1]}.xhtml##{match[2]}"
      else
        item = get_item(match[1], match[2])
        item[:href]
      end
    end

    def replace_missing_content!(tag)
      tag.replace(<<~HTML)
        <span>
          #{tag.content}
          #{I18n.t(<<~TEXT)
            (Link has been removed because content is not present or cannot be resolved.)
          TEXT
          }
        </span>
      HTML
    end

    def object_path_selector
      [
        "a",
        [
          "[href*='#{OBJECT_TOKEN.delete("$")}']",
          "[href*='#{WIKI_TOKEN.delete("$")}']"
        ].join(",")
      ].join
    end

    def sort_by_content
      true
    end
  end
end
