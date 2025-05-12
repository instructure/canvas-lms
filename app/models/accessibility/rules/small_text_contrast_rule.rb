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
    class SmallTextContrastRule < Accessibility::Rule
      self.id = "small-text-contrast"
      self.link = "https://www.w3.org/TR/WCAG21/#contrast-minimum"

      CONTRAST_THRESHOLD = 4.5

      def self.test(elem)
        tag_name = elem.tag_name.downcase
        return true if %w[img br hr input select textarea button script style svg canvas iframe].include?(tag_name)
        return true if elem.text_content.strip.empty?

        return true if elem.text_content.strip.length < 3

        style_str = elem.attribute("style")&.value.to_s
        return true if style_str.include?("display: none") || style_str.include?("visibility: hidden")

        foreground = extract_color(style_str, "color") || "000000"
        background = extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        contrast_ratio >= CONTRAST_THRESHOLD
      end

      def self.message
        I18n.t("Small text should have sufficient contrast.")
      end

      def self.why
        I18n.t("When text is too small, users may have difficulty reading it.")
      end

      def self.link_text
        I18n.t("Learn more about small text contrast")
      end

      def self.extract_color(style_str, property)
        return nil unless style_str

        if style_str =~ /#{property}:\s*([^;]+)/
          color = $1.strip

          if color.start_with?("rgb")
            return rgb_to_hex(color)
          elsif color.start_with?("#")
            return color.delete("#").upcase
          else
            return color.upcase
          end
        end

        nil
      end

      def self.rgb_to_hex(rgb)
        if rgb =~ /rgb\((\d+),\s*(\d+),\s*(\d+)\)/
          r, g, b = $1.to_i, $2.to_i, $3.to_i
          return format("#%02X%02X%02X", r, g, b)
        end
        "#000000"
      end

      def self.form(_elem)
        Accessibility::Forms::ColorPickerField.new(
          label: "Change color",
          value: ""
        )
      end
    end
  end
end
