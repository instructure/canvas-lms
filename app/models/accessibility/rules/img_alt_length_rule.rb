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
    class ImgAltLengthRule < Accessibility::Rule
      self.id = "img-alt-length"
      self.link = nil

      def test(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("alt")

        alt = elem.get_attribute("alt")
        role = elem.attribute?("role") ? elem.get_attribute("role") : nil

        return nil if alt == "" && role == "presentation"
        return nil if alt.blank?

        ImgAltRuleHelper.validation_error_too_long if alt.length > ImgAltRuleHelper::MAX_LENGTH
      end

      def form(elem)
        Accessibility::Forms::TextInputWithCheckboxField.new(
          checkbox_label: I18n.t("This image is decorative"),
          checkbox_subtext: I18n.t("This image is for visual decoration only and screen readers can skip it."),
          input_label: I18n.t("Alt text"),
          undo_text: I18n.t("Alt text fixed"),
          input_description: I18n.t("Describe what's on the picture."),
          input_max_length: ImgAltRuleHelper::MAX_LENGTH,
          can_generate_fix: true,
          generate_button_label: I18n.t("Generate alt text"),
          value: elem.get_attribute("alt") || ""
        )
      end

      def generate_fix(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("src")

        src = elem.get_attribute("src")
        ImgAltRuleHelper.generate_alt_text(src)
      end

      def fix!(elem, value)
        ImgAltRuleHelper.fix_alt_text!(elem, value)
      end

      def display_name
        I18n.t("Alt text is too long")
      end

      def message
        I18n.t("The alt text is too long. Alt text should ideally be under 120 characters,
        so people using screen readers can quickly understand the important content of the image.")
      end

      def why
        I18n.t("Alt text should be concise. When it's unnecessarily long, it can break the flow of screen reader users.
        Unless the image conveys complex information, aim for 120 characters or fewer.")
      end
    end
  end
end
