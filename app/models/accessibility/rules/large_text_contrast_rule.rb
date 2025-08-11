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
      extend Accessibility::CssAttributesHelper

      CONTRAST_THRESHOLD = 3.0
      LARGE_TEXT_MIN_SIZE_PX = 18.5
      LARGE_TEXT_MIN_SIZE_BOLD_PX = 14.0

      self.id = "large-text-contrast"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/G17.html"

      # Accessibility::Rule methods

      def test(elem)
        tag_name = elem.tag_name.downcase
        return nil if %w[img br hr input select textarea button script style svg canvas iframe].include?(tag_name)
        return nil if elem.text_content.strip.empty?

        return nil if elem.text_content.strip.length < 3

        style_str = elem.attribute("style")&.value.to_s
        return nil if style_str.include?("display: none") || style_str.include?("visibility: hidden")

        return nil unless self.class.large_text?(style_str)

        foreground = self.class.extract_color(style_str, "color") || "000000"
        background = self.class.extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        if contrast_ratio < CONTRAST_THRESHOLD
          I18n.t("Contrast ratio for large text is smaller than threshold %{value}.", { value: CONTRAST_THRESHOLD })
        end
      end

      def form(elem)
        style_str = elem.attribute("style")&.value.to_s
        foreground = self.class.extract_color(style_str, "color") || "000000"
        background = self.class.extract_color(style_str, "background-color") || "FFFFFF"

        Accessibility::Forms::ColorPickerField.new(
          title_label: I18n.t("Contrast Ratio"),
          input_label: I18n.t("New text color"),
          label: I18n.t("Change text color"),
          undo_text: I18n.t("Color changed"),
          options: ["large"],
          background_color: "##{background}",
          value: "##{foreground}",
          contrast_ratio: WCAGColorContrast.ratio(foreground, background)
        )
      end

      def fix!(elem, value)
        style_str = elem.attribute("style")&.value.to_s
        styles = style_str.split(";").to_h { |s| s.strip.split(":") }

        styles["color"] = value

        new_style = styles.map { |k, v| "#{k.strip}: #{v.strip}" }.join("; ") + ";"
        return nil if new_style == style_str

        elem.set_attribute("style", new_style)

        foreground = self.class.extract_color(new_style, "color") || "000000"
        background = self.class.extract_color(style_str, "background-color") || "FFFFFF"

        contrast_ratio = WCAGColorContrast.ratio(foreground, background)

        raise StandardError, "Insufficient contrast ratio (#{contrast_ratio})." if contrast_ratio < CONTRAST_THRESHOLD

        elem
      end

      def display_name
        I18n.t("Large text contrast")
      end

      def message
        I18n.t("Text larger than 18pt (or bold 14pt) should display a minimum contrast ratio of 3:1.")
      end

      def why
        I18n.t("Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision.")
      end

      # Helper methods

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
    end
  end
end
