# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Accessibility
  module Rules
    class AdjacentLinksRule < Accessibility::Rule
      self.id = "adjacent-links"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H2.html"

      def self.not_whitespace(node)
        node.node_type != 3 || node.text_content.match(/\S/)
      end

      def self.test(elem)
        return true if elem.tag_name != "a"

        next_elem = elem.next_element_sibling
        return true unless next_elem && next_elem.tag_name == "a"

        elem_href = elem.get_attribute("href")
        next_href = next_elem.get_attribute("href")

        elem_href != next_href
      end

      def self.message
        "Adjacent links with the same URL should be combined."
      end

      def self.why
        "When adjacent links go to the same location, screen reader users have to navigate through " \
          "redundant links. This creates unnecessary repetition and confusion. " \
          "Combining adjacent links with the same destination improves navigation efficiency."
      end

      def self.link_text
        "Learn more about combining adjacent links"
      end

      def self.root_node(elem)
        elem.parent_node
      end

      def self.form(_elem)
        Accessibility::Forms::CheckboxField.new(
          label: "Merge links",
          value: "false"
        )
      end
    end
  end
end
