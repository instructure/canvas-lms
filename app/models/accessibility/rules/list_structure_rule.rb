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

      HTML_TAG_PATTERN = /(?:<[^>]+>\\s*)*/
      UNORDERED_LIST_REGEX = /^\s*(?:[#{BULLET_MARKERS}])\s+/
      ORDERED_LIST_REGEX = /^\s*(?:(#{ORDERED_CHARS})[#{ORDERED_MARKERS}])\s+/

      LIST_LIKE_REGEX = /#{UNORDERED_LIST_REGEX.source}|#{ORDERED_LIST_REGEX.source}/
      LIST_LIKE_REGEX_WITH_HTML_TAG = /#{HTML_TAG_PATTERN.source}#{LIST_LIKE_REGEX.source}/

      def self.list_check_helper(elem, regex)
        if elem.tag_name.downcase == "p"
          return true if regex.match?(elem.content)

          elem.children.each do |child|
            return true if regex.match?(child.content)
          end
        end

        false
      end

      def self.list?(elem)
        list_check_helper(elem, LIST_LIKE_REGEX)
      end

      def self.ordered_list?(elem)
        list_check_helper(elem, ORDERED_LIST_REGEX)
      end

      def self.unordered_list?(elem)
        list_check_helper(elem, UNORDERED_LIST_REGEX)
      end

      def self.just_single_text_child?(elem)
        return true if elem.children.length == 1 && elem.children.first.text?

        false
      end

      def self.br_children?(elem)
        elem.children.each do |child|
          return true if child.tag_name == "br"
        end
        false
      end

      def self.test(elem)
        is_list = list?(elem)
        is_first = elem.previous_element_sibling ? !list?(elem.previous_element_sibling) : true

        !(is_list && is_first)
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

      def self.fix(elem, value)
        return elem unless test(elem) == false
        return elem unless value == "true"

        match_data = LIST_LIKE_REGEX.match(elem.content)
        is_ordered = !!match_data&.captures&.first
        start_index = is_ordered ? match_data.captures.first : nil
        list_container = elem.document.create_element(is_ordered ? "ol" : "ul")

        if is_ordered && start_index && start_index =~ /^\d+$/ && start_index.to_i > 1
          list_container["start"] = start_index
        end

        current_elem = elem
        while current_elem && (is_ordered ? ordered_list?(current_elem) : unordered_list?(current_elem))
          just_single_text_child = just_single_text_child?(current_elem)

          if br_children?(current_elem)
            current_elem.inner_html.split(%r{<br\s*/?>}).each do |text|
              text = text.strip.gsub(LIST_LIKE_REGEX, "")
              list_item = elem.document.create_element("li")
              list_item.content = text
              list_container.add_child(list_item)
            end
          else
            list_item = elem.document.create_element("li")
            current_elem.children.each do |child|
              if child.text?
                child.content = just_single_text_child ? child.content.strip.gsub(LIST_LIKE_REGEX, "") : child.content.gsub(LIST_LIKE_REGEX, "")
              end
              child.children.each do |grandchild|
                grandchild.content = grandchild.content.strip.gsub(LIST_LIKE_REGEX, "")
              end
              list_item.add_child(child)
            end
            list_container.add_child(list_item)
          end

          next_elem = current_elem.next_element_sibling
          current_elem.unlink unless current_elem == elem
          break unless next_elem && list?(next_elem)

          current_elem = next_elem
        end

        elem.replace(list_container)
        list_container
      end
    end
  end
end
