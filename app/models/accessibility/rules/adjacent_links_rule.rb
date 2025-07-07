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

      def self.test(elem)
        return nil if elem.tag_name != "a"

        next_elem = elem.next_element_sibling
        return nil unless next_elem && next_elem.tag_name == "a"

        elem_href = elem.get_attribute("href")
        next_href = next_elem.get_attribute("href")

        "Adjacent links contain the same URL." if elem_href == next_href
      end

      def self.message
        "These are two links that go to the same place. Turn them into one link to avoid repetition."
      end

      def self.why
        "When two or more links are next to each other and lead to the same destination, " \
          "screen readers interpret them as two separate links, even though the intent is usually displaying a single link. " \
          "This creates unnecessary repetition and is confusing."
      end

      def self.link_text
        "Learn more about combining adjacent links"
      end

      def self.root_node(elem)
        elem.parent_node
      end

      def self.form(_elem)
        Accessibility::Forms::Button.new(
          label: "Merge links"
        )
      end

      def self.fix!(elem, value)
        return nil if test(elem).nil?
        return nil unless value == "true" || elem.tag_name == "a"

        next_elem = elem.next_element_sibling

        return elem unless next_elem && next_elem.tag_name == "a" && elem.get_attribute("href") == next_elem.get_attribute("href")

        left_image = single_child_image(elem)
        right_image = single_child_image(next_elem)

        if left_image && !right_image && normalize_text(left_image.get_attribute("alt")) == normalize_text(next_elem.text_content)
          left_image.set_attribute("alt", "")
        elsif right_image && !left_image && normalize_text(right_image.get_attribute("alt")) == normalize_text(elem.text_content)
          right_image.set_attribute("alt", "")
        end

        elem.inner_html += " " + next_elem.inner_html

        next_elem.remove

        elem
      end

      def self.single_child_image(link)
        parent = link
        child = only_child(parent)
        while child
          return child if child.tag_name == "img"

          parent = child
          child = only_child(parent)
        end
        nil
      end

      def self.only_child(parent)
        child = parent.first_element_child
        return nil unless child

        non_whitespace_children = parent.child_nodes.select { |node| not_whitespace(node) }
        return nil if non_whitespace_children.length > 1

        child
      end

      def self.not_whitespace(node)
        node.node_type != 3 || node.text_content.match(/\S/)
      end

      def self.normalize_text(text)
        text.gsub(/\s+/, " ").strip
      end
    end
  end
end
