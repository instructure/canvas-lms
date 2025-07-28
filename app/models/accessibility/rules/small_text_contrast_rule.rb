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
      SMALL_TEXT_MAX_SIZE_PX = 18.5
      SMALL_TEXT_MAX_SIZE_BOLD_PX = 14.0

      def self.test(elem)
        tag_name = elem.tag_name.downcase
        return nil if %w[img br hr input select textarea button script style svg canvas iframe].include?(tag_name)
        return nil if elem.text_content.strip.empty?

        return nil if elem.text_content.strip.length < 3

        style_str = elem.attribute("style")&.value.to_s
        return nil if style_str.include?("display: none") || style_str.include?("visibility: hidden")

        return nil unless small_text?(style_str)

        foreground = extract_color(style_str, "color") || "000000"
        background = extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        if contrast_ratio < CONTRAST_THRESHOLD
          I18n.t("Contrast ratio for small text is smaller than threshold %{value}.", { value: CONTRAST_THRESHOLD })
        end
      end

      def self.display_name
        I18n.t("Small text contrast")
      end

      def self.message
        I18n.t("Text smaller than 18pt (or bold 14pt) should display a minimum contrast ratio of 4.5:1.")
      end

      def self.why
        I18n.t("Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision.")
      end

      def self.small_text?(style_str)
        font_size = extract_font_size(style_str) || 16
        font_weight = extract_font_weight(style_str) || "normal"

        is_bold = %w[bold bolder 700 800 900].include?(font_weight.to_s.downcase)

        font_size < if is_bold
                      SMALL_TEXT_MAX_SIZE_BOLD_PX
                    else
                      SMALL_TEXT_MAX_SIZE_PX
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

        match = style_str.match(/(?:^|;)\s*#{Regexp.escape(property)}:\s*([^;]+)/)
        return nil unless match

        color = match[1].strip

        if color.start_with?("rgb")
          rgb_to_hex(color)
        elsif color.start_with?("#")
          color.delete_prefix("#").upcase
        else
          color.upcase
        end
      end

      def self.rgb_to_hex(rgb)
        if rgb =~ /rgb\((\d+),\s*(\d+),\s*(\d+)\)/
          r, g, b = $1.to_i, $2.to_i, $3.to_i
          return format("#%02X%02X%02X", r, g, b)
        end
        "#000000"
      end

      def self.form(elem)
        style_str = elem.attribute("style")&.value.to_s
        foreground = extract_color(style_str, "color") || "000000"
        background = extract_color(style_str, "background-color") || "FFFFFF"

        Accessibility::Forms::ColorPickerField.new(
          title_label: I18n.t("Contrast Ratio"),
          input_label: I18n.t("New Color"),
          label: I18n.t("Change Color"),
          options: ["normal"],
          background_color: "##{background}",
          undo_text: I18n.t("Color changed"),
          value: "##{foreground}",
          contrast_ratio: WCAGColorContrast.ratio(foreground, background)
        )
      end

      def self.fix!(elem, value)
        style_str = elem.attribute("style")&.value.to_s
        styles = style_str.split(";").to_h { |s| s.strip.split(":") }

        styles["color"] = value

        new_style = styles.map { |k, v| "#{k.strip}: #{v.strip}" }.join("; ") + ";"
        return nil if new_style == style_str

        elem.set_attribute("style", new_style)

        foreground = extract_color(new_style, "color") || "000000"
        background = extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        raise StandardError, "Insufficient contrast ratio (#{contrast_ratio})." if contrast_ratio < CONTRAST_THRESHOLD

        elem
      end
    end
  end
end
