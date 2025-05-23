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

      def self.h_tag?(elem)
        all_h_tags = {
          "h1" => true,
          "h2" => true,
          "h3" => true,
          "h4" => true,
          "h5" => true,
          "h6" => true
        }
        elem && all_h_tags[elem.tag_name.downcase] == true
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

        (h_num - 1..6).each do |i|
          ret["h#{i}"] = true
        end

        ret
      end

      def self.test(elem)
        test_tags = {
          "h2" => true,
          "h3" => true,
          "h4" => true,
          "h5" => true,
          "h6" => true
        }

        return true if test_tags[elem.tag_name.downcase] != true

        valid_headings = get_valid_headings(elem)
        prior_heading = get_prior_heading(elem)

        if prior_heading
          return valid_headings[prior_heading.tag_name.downcase]
        end

        true
      end

      def self.form(_elem)
        Accessibility::Forms::DropdownField.new(
          label: "Merge links",
          value: "Leave as is",
          options: ["Leave as is", "Fix heading hierarchy", "Remove heading style"]
        )
      end

      def self.message
        "Headings should not skip levels."
      end

      def self.why
        "When heading levels are skipped (for example, from an H2 to an H4, skipping H3), " \
          "screen reader users may have difficulty understanding the page structure. " \
          "This creates a confusing outline of the page for assistive technology users."
      end

      def self.link_text
        "Learn more about proper heading sequences"
      end

      def self.fix(elem, value)
        case value
        when "Leave as is"
          return elem
        when "Fix heading hierarchy"
          prior_h = get_prior_heading(elem)
          h_idx = prior_h ? prior_h.tag_name[1..].to_i : 0
          elem.name = "h#{h_idx + 1}"
        when "Remove heading style"
          elem.name = "p"
        end
        elem
      end
    end
  end
end
