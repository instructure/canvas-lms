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
    class HeadingsSequenceRule < Accessibility::Rule
      self.id = "headings-sequence"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/G141.html"

      # Accessibility::Rule methods

      def test(elem)
        test_tags = {
          "h2" => true,
          "h3" => true,
          "h4" => true,
          "h5" => true,
          "h6" => true
        }

        return nil if test_tags[elem.tag_name.downcase] != true

        valid_headings = self.class.get_valid_headings(elem)
        prior_heading = self.class.get_prior_heading(elem)

        if prior_heading
          return I18n.t("Headings are not in sequence.") unless valid_headings[prior_heading.tag_name.downcase]
        end

        nil
      end

      def form(_elem)
        Accessibility::Forms::RadioInputGroupField.new(
          label: I18n.t("How would you like to proceed?"),
          undo_text: I18n.t("Heading hierarchy is now correct"),
          value: I18n.t("Fix heading hierarchy"),
          options: [
            I18n.t("Fix heading hierarchy"),
            I18n.t("Remove heading style")
          ],
          action: I18n.t("Reformat")
        )
      end

      def fix!(elem, value)
        case value
        when I18n.t("Fix heading hierarchy")
          prior_h = self.class.get_prior_heading(elem)
          h_idx = prior_h ? prior_h.tag_name[1..].to_i : 0
          elem.name = "h#{h_idx + 1}"
        when I18n.t("Remove heading style")
          elem.name = "p"
        end
        { changed: elem }
      end

      def display_name
        I18n.t("Heading order")
      end

      def message
        I18n.t(
          "Make sure heading levels follow a logical order (for example, H2, then H3, then H4)." \
          "This helps screen reader users understand the structure of the page."
        )
      end

      def why
        [I18n.t(
          "Sighted users scan web pages quickly by looking for large or bolded headings. Similarly, screen reader users rely on properly structured headings to scan the content and jump directly to key sections. Using correct heading levels in a logical order (like H2, H3, etc.) ensures your course is clear, organized, and accessible to everyone."
        ),
         I18n.t("Tip: Each page already has a main title (H1), so start your content with an H2 to keep the structure clear.")]
      end

      # Helper methods

      def self.h_tag?(elem)
        elem&.tag_name&.downcase&.match?(/^h[1-6]$/)
      end

      def self.get_highest_order_h_for_elem(elem)
        all_h_for_elem = elem.query_selector_all("h1,h2,h3,h4,h5,h6").to_a
        return all_h_for_elem.last if all_h_for_elem.any?
        return elem if h_tag?(elem)

        nil
      end

      def self.get_prev_siblings(elem)
        ret = []
        return ret if !elem || !elem.parent_element || !elem.parent_element.children

        sibs = elem.parent_element.children
        sibs.each do |sib|
          break if sib == elem

          ret.unshift(sib)
        end

        ret
      end

      def self.search_prev_siblings(elem)
        sibs = get_prev_siblings(elem)
        sibs.each do |sib|
          ret = get_highest_order_h_for_elem(sib)
          return ret if ret
        end

        nil
      end

      def self._walk_up_tree(elem)
        return nil if !elem || elem.tag_name == "body"
        return elem if h_tag?(elem)

        ret = search_prev_siblings(elem)
        return ret if ret

        _walk_up_tree(elem.parent_element)
      end

      def self.walk_up_tree(elem)
        ret = search_prev_siblings(elem)
        return ret if ret

        _walk_up_tree(elem.parent_element)
      end

      def self.get_prior_heading(elem)
        walk_up_tree(elem)
      end

      def self.get_valid_headings(elem)
        h_num = elem.tag_name[1..].to_i
        ret = {}

        ((h_num - 1)..6).each do |i|
          ret["h#{i}"] = true
        end

        ret
      end
    end
  end
end
