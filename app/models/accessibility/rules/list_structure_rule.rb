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
    class ListStructureRule < Accessibility::Rule
      self.id = "list-structure"
      self.link = "https://www.w3.org/TR/2016/NOTE-WCAG20-TECHS-20161007/H48"

      ORDERED_CHARS = ["[A-Z]", "[a-z]", "[0-9]"].map { |pattern| "#{pattern}{1,4}" }.join("|")
      BULLET_MARKERS = ["*", "-"].map { |c| "\\#{c}" }.join("|")
      ORDERED_MARKERS = [".", ")"].map { |c| "\\#{c}" }.join("|")

      LIST_LIKE_REGEX = /^\s*(?:(?:[#{BULLET_MARKERS}])|(?:(#{ORDERED_CHARS})[#{ORDERED_MARKERS}]))\s+/

      def self.text_list?(elem)
        elem.tag_name.downcase == "p" && LIST_LIKE_REGEX.match?(elem.text_content)
      end

      def self.clean_list_item(elem)
        if elem.node_type == 3 # TEXT_NODE
          elem.text_content = elem.text_content.gsub(LIST_LIKE_REGEX, "")
          return true
        end

        elem.child_nodes.each do |child_element|
          found = clean_list_item(child_element)
          return true if found
        end

        false
      end

      def self.move_contents(from, to)
        while from.first_child
          to.append_child(from.first_child)
        end
      end

      def self.test(elem)
        is_list = text_list?(elem)
        is_first = elem.previous_element_sibling ? !text_list?(elem.previous_element_sibling) : true

        !(is_list && is_first)
      end

      def self.root_node(elem)
        elem.parent_node
      end

      def self.message
        I18n.t("Lists should be formatted as lists.")
      end

      def self.why
        I18n.t("When markup is used that visually formats items as a list but does not indicate the list relationship, users may have difficulty in navigating the information.")
      end

      def self.link_text
        I18n.t("Learn more about using lists")
      end

      def self.form(_elem)
        Accessibility::Forms::CheckboxField.new(
          label: "Format as list",
          value: "false"
        )
      end
    end
  end
end
