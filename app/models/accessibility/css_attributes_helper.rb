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
    def extract_font_size(style_str)
      return nil unless style_str

      if style_str =~ /font-size:\s*([^;]+)/
        size_str = $1.strip

        if size_str.end_with?("px")
          return size_str.to_f
        elsif size_str.end_with?("pt")
          return size_str.to_f * 1.333
        elsif size_str.end_with?("em", "rem")
          return size_str.to_f * 16 # Assume 1em = 16px
        end
      end

      nil
    end

    def extract_font_weight(style_str)
      return nil unless style_str

      if style_str =~ /font-weight:\s*([^;]+)/
        $1.strip
      else
        nil
      end
    end

    def extract_color(style_str, property)
      return nil unless style_str

      match = style_str.match(/(?:^|;)\s*#{Regexp.escape(property)}:\s*([^;]+)/)
      return nil unless match

      color = match[1].strip

      if color.start_with?("#")
        color.delete_prefix("#").upcase
      else
        color.upcase
      end
    end
  end
end
