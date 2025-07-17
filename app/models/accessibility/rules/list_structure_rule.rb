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

      def self.list_check_helper?(elem, regex)
        if elem.tag_name.downcase == "p"
          return true if regex.match?(elem.content)

          elem.children.each do |child|
            return true if regex.match?(child.content)
          end
        end

        false
      end

      def self.list?(elem)
        list_check_helper?(elem, LIST_LIKE_REGEX)
      end

      def self.ordered_list?(elem)
        list_check_helper?(elem, ORDERED_LIST_REGEX)
      end

      def self.unordered_list?(elem)
        list_check_helper?(elem, UNORDERED_LIST_REGEX)
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
        is_element = elem.is_a?(Nokogiri::XML::Element)
        is_first = (is_element && elem.previous_element_sibling) ? !list?(elem.previous_element_sibling) : true

        return I18n.t("Lists shall be formatted as lists.") if is_first && is_list

        nil
      end

      def self.display_name
        I18n.t("Misformatted list")
      end

      def self.message
        I18n.t("Lists should be formatted as lists.")
      end

      def self.why
        I18n.t("When markup is used that visually formats items as a list but does not indicate the list relationship, users may have difficulty in navigating the information.")
      end

      # TODO: define undo text
      def self.form(_elem)
        Accessibility::Forms::Button.new(
          label: I18n.t("Format as list"),
          undo_text: I18n.t("List structure fixed"),
          value: "false"
        )
      end

      def self.strip_list_marker_from_node(node)
        if node.text?
          node.content = node.content.sub(LIST_LIKE_REGEX, "")
        elsif node.element?
          node.children.each { |child| strip_list_marker_from_node(child) }
        end
      end

      def self.fix!(elem, value)
        return nil unless list?(elem) && value == "true"

        # Find the first and last consecutive list-like siblings
        first_elem = elem
        first_elem = first_elem.previous_element_sibling while first_elem.previous_element_sibling && list?(first_elem.previous_element_sibling)
        list_elems = []
        current_elem = first_elem
        while current_elem && list?(current_elem)
          list_elems << current_elem
          current_elem = current_elem.next_element_sibling
        end

        # Determine list type and start index
        match_data = LIST_LIKE_REGEX.match(list_elems.first.content)
        is_ordered = !!match_data&.captures&.first
        start_index = is_ordered ? match_data.captures.first : nil
        list_tag = is_ordered ? "ol" : "ul"
        list_container = elem.document.create_element(list_tag)
        list_container["start"] = start_index if is_ordered && start_index =~ /^\d+$/ && start_index.to_i > 1

        # Add <li> for each list-like element
        list_elems.each do |le|
          if br_children?(le)
            le.inner_html.split(%r{<br\s*/?>}).each do |text|
              text = text.gsub(LIST_LIKE_REGEX, "").strip
              next if text.empty?

              li = elem.document.create_element("li")
              li.content = text
              list_container.add_child(li)
            end
          else
            li = elem.document.create_element("li")
            le.children.each do |child|
              strip_list_marker_from_node(child)
              li.add_child(child)
            end
            list_container.add_child(li)
          end
        end

        first_elem.add_previous_sibling(list_container)
        list_elems.each(&:unlink)
        first_elem
      end
    end
  end
end
