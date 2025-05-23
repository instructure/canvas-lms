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
    class LargeTextContrastRule < Accessibility::Rule
      self.id = "large-text-contrast"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/G17.html"

      CONTRAST_THRESHOLD = 3.0
      LARGE_TEXT_MIN_SIZE_PX = 18.5
      LARGE_TEXT_MIN_SIZE_BOLD_PX = 14.0

      def self.test(elem)
        tag_name = elem.tag_name.downcase
        return true if %w[img br hr input select textarea button script style svg canvas iframe].include?(tag_name)
        return true if elem.text_content.strip.empty?

        return true if elem.text_content.strip.length < 3

        style_str = elem.attribute("style")&.value.to_s
        return true if style_str.include?("display: none") || style_str.include?("visibility: hidden")

        return true unless large_text?(style_str)

        foreground = extract_color(style_str, "color") || "000000"
        background = extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        contrast_ratio >= CONTRAST_THRESHOLD
      end

      def self.message
        I18n.t("Text larger than 18pt (or bold 14pt) should display a minimum contrast ratio of 3:1.")
      end

      def self.why
        I18n.t("Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision.")
      end

      def self.link_text
        I18n.t("Learn more about large text contrast")
      end

      def self.large_text?(style_str)
        font_size = extract_font_size(style_str) || 16
        font_weight = extract_font_weight(style_str) || "normal"

        is_bold = %w[bold bolder 700 800 900].include?(font_weight.to_s.downcase)

        font_size >= if is_bold
                       LARGE_TEXT_MIN_SIZE_BOLD_PX
                     else
                       LARGE_TEXT_MIN_SIZE_PX
                     end
      end

      def self.extract_font_size(style_str)
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

      def self.extract_font_weight(style_str)
        return nil unless style_str

        if style_str =~ /font-weight:\s*([^;]+)/
          $1.strip
        else
          nil
        end
      end

      def self.extract_color(style_str, property)
        return nil unless style_str

        if style_str =~ /#{property}:\s*([^;]+)/
          color = $1.strip

          # Convert rgb() format to hex
          if color.start_with?("rgb")
            return rgb_to_hex(color).upcase
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
        "000000"
      end

      def self.update_style(style_str, property, value)
        style_str ||= ""

        if style_str.include?("#{property}:")
          style_str.gsub(/#{property}:[^;]+;?/, "#{property}: #{value};")
        else
          "#{style_str.chomp(";")};#{property}: #{value};"
        end
      end

      def self.suggest_accessible_colors(foreground, background)
        fg_rgb = WCAGColorContrast.hex_to_rgb(foreground)
        bg_rgb = WCAGColorContrast.hex_to_rgb(background)

        fg_lum = WCAGColorContrast.relative_luminance(fg_rgb)
        bg_lum = WCAGColorContrast.relative_luminance(bg_rgb)

        new_foreground = if fg_lum < bg_lum
                           "#000000"
                         else
                           "#FFFFFF"
                         end
        { foreground: new_foreground, background: }
      end

      def self.form(_elem)
        Accessibility::Forms::ColorPickerField.new(
          label: "Change color",
          value: ""
        )
      end

      def self.fix(elem, value)
        style_str = elem.attribute("style")&.value.to_s
        styles = style_str.split(";").to_h { |s| s.strip.split(":") }

        styles["color"] = value

        new_style = styles.map { |k, v| "#{k.strip}: #{v.strip}" }.join("; ") + ";"
        elem.set_attribute("style", new_style)

        elem
      end
    end
  end
end
