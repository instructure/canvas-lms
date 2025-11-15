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
  module CssAttributesHelper
    def parse_inline_styles(style_str)
      return nil unless style_str

      parser = CssParser::Parser.new
      parser.add_block!("placeholder { #{style_str} }")
      rule_sets = parser.find_rule_sets(["placeholder"])
      return nil if rule_sets.empty?

      rule_sets.first
    end

    def extract_font_size(style_str)
      rule_set = parse_inline_styles(style_str)
      return nil unless rule_set

      font_size = rule_set["font-size"]
      return nil unless font_size

      size_str = font_size.strip.delete_suffix(";")

      if size_str.end_with?("px")
        size_str.to_f
      elsif size_str.end_with?("pt")
        size_str.to_f * 1.333
      elsif size_str.end_with?("em", "rem")
        size_str.to_f * 16
      end
    end

    def extract_font_weight(style_str)
      rule_set = parse_inline_styles(style_str)
      return nil unless rule_set

      font_weight = rule_set["font-weight"]
      return nil unless font_weight

      font_weight.strip.delete_suffix(";")
    end

    def extract_color(style_str, property)
      rule_set = parse_inline_styles(style_str)
      return nil unless rule_set

      value = rule_set[property]
      return nil unless value

      value = value.strip.delete_suffix(";")

      if property == "background"
        value_without_functions = value.gsub(/url\([^)]+\)/, "")
                                       .gsub(/(?:linear|radial|conic)-gradient\([^)]+\)/, "")
                                       .gsub(/repeating-(?:linear|radial)-gradient\([^)]+\)/, "")

        if value_without_functions =~ /#([0-9a-fA-F]{3,6})\b/
          return $1.upcase
        end

        return nil
      end

      color = value

      if color.start_with?("#")
        color.delete_prefix("#").upcase
      else
        nil
      end
    end

    def extract_background_color(style_str, default: "FFFFFF")
      rule_set = parse_inline_styles(style_str)
      return default unless rule_set

      return nil if rule_set["background-image"].present?

      if rule_set["background"].present?
        return extract_color(style_str, "background").presence
      end

      if rule_set["background-color"].present?
        return extract_color(style_str, "background-color").presence
      end

      default
    end
  end
end
