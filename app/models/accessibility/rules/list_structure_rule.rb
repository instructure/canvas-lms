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
      include Accessibility::NokogiriMethods

      ORDERED_CHARS = ["[A-Z]", "[a-z]", "[0-9]"].map { |pattern| "#{pattern}{1,4}" }.join("|")
      BULLET_MARKERS = ["*", "-"].map { |c| "\\#{c}" }.join("|")
      ORDERED_MARKERS = [".", ")"].map { |c| "\\#{c}" }.join("|")

      NUMBER_REGEX = /^[0-9]+$/
      LOWERCASE_ALPHABET_REGEX = /^[a-z]+$/
      UPPERCASE_ALPHABET_REGEX = /^[A-Z]+$/
      ROMAN_NUMERAL_PATTERN_REGEX = /^(i{1,3}|iv|v|vi{1,3}|ix|x{1,3}|xi{1,3}|xiv|xv|xvi{1,3}|xix|xx)$/i

      UNORDERED_LIST_REGEX = /^\s*(?:[#{BULLET_MARKERS}])\s+/
      ORDERED_LIST_REGEX = /^\s*(?:(#{ORDERED_CHARS})[#{ORDERED_MARKERS}])\s+/
      LIST_LIKE_REGEX = /#{UNORDERED_LIST_REGEX.source}|#{ORDERED_LIST_REGEX.source}/

      self.id = "list-structure"
      self.link = "https://www.w3.org/TR/2016/NOTE-WCAG20-TECHS-20161007/H48"

      # Accessibility::Rule methods

      def test(elem)
        return nil unless self.class.list?(elem)
        return nil unless elem.is_a?(Nokogiri::XML::Element)

        prev = elem.previous_element_sibling
        if prev && self.class.list?(prev)
          return nil if same_list_type?(elem, prev)
        end

        I18n.t("Lists shall be formatted as lists.")
      end

      def form(_elem)
        Accessibility::Forms::Button.new(
          label: I18n.t("Reformat"),
          undo_text: I18n.t("List is now formatted correctly."),
          value: "false"
        )
      end

      def fix!(elem, value)
        return { changed: nil } unless self.class.list?(elem) && value == "true"

        { changed: fix_list_by_type(elem) }
      end

      def fix_list_by_type(elem)
        is_ordered, marker_type, start_value = determine_list_type(elem)
        list_elems = collect_list_sequence(elem)

        list_tag = is_ordered ? "ol" : "ul"

        list_container = elem.document.create_element(list_tag)
        extend_nokogiri_element(list_container)

        if is_ordered && marker_type
          list_container["type"] = marker_type
          list_container["start"] = start_value if marker_type == "1" && start_value.to_i > 1
        end

        # Add <li> for each list-like element
        list_elems.each do |le|
          if self.class.br_children?(le)
            le.inner_html.split(%r{<br\s*/?>}).each do |text|
              text = text.gsub(LIST_LIKE_REGEX, "").strip
              next if text.empty?

              li = elem.document.create_element("li")
              extend_nokogiri_element(li)

              li.content = text
              list_container.add_child(li)
            end
          else
            li = elem.document.create_element("li")
            extend_nokogiri_element(li)

            le.children.each do |child|
              self.class.strip_list_marker_from_node(child)
              li.add_child(child)
            end
            list_container.add_child(li)
          end
        end

        list_elems.first.add_previous_sibling(list_container)
        list_elems.each(&:unlink)

        list_container
      end

      def display_name
        I18n.t("Misformatted list")
      end

      def message
        I18n.t("This looks like a list but isn't formatted as one.")
      end

      def why
        I18n.t("Using correct list formatting helps learners using screen readers understand the content.")
      end

      def issue_preview(elem)
        collect_list_sequence(elem).map(&:to_html).join
      end

      # Helper methods

      def self.list_check_helper?(elem, regex)
        elem.tag_name.downcase == "p" && regex.match?(elem.content)
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

      def self.strip_list_marker_from_node(node)
        if node.text?
          node.content = node.content.sub(LIST_LIKE_REGEX, "")
        elsif node.element?
          node.children.each { |child| strip_list_marker_from_node(child) }
        end
      end

      private

      def determine_list_type(elem)
        match_data = LIST_LIKE_REGEX.match(elem.content)
        is_ordered = !!match_data&.captures&.first

        return [false, nil, nil] unless is_ordered

        start_value = match_data.captures.first
        marker_type = detect_marker_type(start_value)

        [true, marker_type, start_value]
      end

      def detect_marker_type(value)
        return "1" if value.match?(NUMBER_REGEX)
        return value.match?(ROMAN_NUMERAL_PATTERN_REGEX) ? "i" : "a" if value.match?(LOWERCASE_ALPHABET_REGEX)
        return value.match?(ROMAN_NUMERAL_PATTERN_REGEX) ? "I" : "A" if value.match?(UPPERCASE_ALPHABET_REGEX)

        "1"
      end

      def same_list_type?(elem1, elem2)
        determine_list_type(elem1).first(2) == determine_list_type(elem2).first(2)
      end

      def collect_list_sequence(elem)
        first_elem = find_first_of_sequence(elem)

        collect_forward(first_elem)
      end

      def find_first_of_sequence(elem)
        first_elem = elem
        while first_elem.previous_element_sibling && self.class.list?(first_elem.previous_element_sibling)
          prev_elem = first_elem.previous_element_sibling

          break unless same_list_type?(elem, prev_elem)

          first_elem = prev_elem
        end
        first_elem
      end

      def collect_forward(first_elem)
        list_elems = []
        current_elem = first_elem

        while current_elem && self.class.list?(current_elem)
          break unless same_list_type?(first_elem, current_elem)

          list_elems << current_elem
          current_elem = current_elem.next_element_sibling
        end

        list_elems
      end
    end
  end
end
