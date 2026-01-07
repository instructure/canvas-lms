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
    class ImgAltRule < Accessibility::Rule
      self.id = "img-alt"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H37.html"

      # Accessibility::Rule methods

      def test(elem)
        return nil if elem.tag_name != "img"

        alt = elem.attribute?("alt") ? elem.get_attribute("alt") : nil
        role = elem.attribute?("role") ? elem.get_attribute("role") : nil
        I18n.t("Alt text should be present for the image.") if alt.nil? && role != "presentation"
      end

      def form(elem)
        Accessibility::Forms::TextInputWithCheckboxField.new(
          checkbox_label: I18n.t("This image is decorative"),
          checkbox_subtext: I18n.t("Screen readers should skip purely decorative images."),
          undo_text: I18n.t("Alt text updated"),
          input_label: I18n.t("Alt text"),
          input_description: I18n.t("Describe the content or purpose of this image."),
          input_max_length: ImgAltRuleHelper::MAX_LENGTH,
          can_generate_fix: true,
          is_canvas_image: Accessibility::AiGenerationService.extract_attachment_id_from_element(elem).present?,
          generate_button_label: I18n.t("Generate alt text"),
          value: elem.get_attribute("alt") || ""
        )
      end

      def fix!(elem, value)
        ImgAltRuleHelper.fix_alt_text!(elem, value)
      end

      def display_name
        I18n.t("Alt text missing")
      end

      def message
        I18n.t("Add a description (alt text) for screen reader users and instances where the image fails to load.")
      end

      def issue_preview(elem)
        return nil unless elem.tag_name == "img"

        ImgAltRuleHelper.adjust_img_style(elem)
      end

      def why
        I18n.t("Alt text is a description of an image only visible to screen readers.
          Screen readers are software to help people who are blind or have low vision interact with websites
          and computers.")
      end
    end
  end
end
