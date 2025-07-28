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
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H37.html"

      MAX_LENGTH = 120

      def self.test(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("alt")

        alt = elem.get_attribute("alt")
        role = elem.attribute?("role") ? elem.get_attribute("role") : nil

        return nil if alt == "" && role == "presentation"
        return nil if alt.blank?

        I18n.t("Alt text is longer than 120.") if alt.length > MAX_LENGTH
      end

      def self.message
        I18n.t("The alt text is too long. Alt text should ideally be under 120 characters,
        so people using screen readers can quickly understand the important content of the image.")
      end

      def self.why
        I18n.t("Alt text should be concise. When it's unnecessarily long, it can break the flow of screen reader users.
        Unless the image conveys complex information, aim for 120 characters or fewer.")
      end

      def self.display_name
        I18n.t("Alt text is too long")
      end

      def self.form(elem)
        Accessibility::Forms::TextInputWithCheckboxField.new(
          checkbox_label: I18n.t("This image is decorative"),
          checkbox_subtext: I18n.t("This image is for visual decoration only and screen readers can skip it."),
          input_label: I18n.t("Alt text"),
          undo_text: I18n.t("Alt text fixed"),
          input_description: I18n.t("Describe what's on the picture."),
          input_max_length: MAX_LENGTH,
          can_generate_fix: true,
          generate_button_label: I18n.t("Generate alt text"),
          value: elem.get_attribute("alt") || ""
        )
      end

      def self.generate_fix(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("src")

        src = elem.get_attribute("src")
        ImgAltRuleHelper.generate_alt_text(src)
      end

      def self.fix!(elem, value)
        if value == "" || value.nil?
          elem["role"] = "presentation"
        elsif value.length > MAX_LENGTH
          raise StandardError, I18n.t("Too long alt text. It should be less than 120 characters.")
        end

        return nil if elem["alt"] == value

        elem["alt"] = value
        elem
      end
    end
  end
end
