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
    class ImgAltFilenameRule < Accessibility::Rule
      self.id = "img-alt-filename"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/F30.html"

      # Accessibility::Rule methods

      def test(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("alt")

        alt = elem.get_attribute("alt")
        role = elem.attribute?("role") ? elem.get_attribute("role") : nil

        return nil if alt == "" && role == "presentation"
        return nil if alt.blank?

        ImgAltRuleHelper.validation_error_filename if ImgAltRuleHelper.filename_like?(alt)
      end

      def form(elem)
        Accessibility::Forms::TextInputWithCheckboxField.new(
          checkbox_label: I18n.t("This image is decorative"),
          checkbox_subtext: I18n.t("Screen readers should skip purely decorative images."),
          undo_text: I18n.t("Alt text updated"),
          input_label: I18n.t("Alt text"),
          input_description: I18n.t("Describe what this image is meant to convey."),
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
        I18n.t("Alt text is filename")
      end

      def message
        I18n.t("Alt text is just the filename. Replace it with a description that tells users who can't see or load the image what it's meant to convey.")
      end

      def issue_preview(elem)
        return nil unless elem.tag_name == "img"

        ImgAltRuleHelper.adjust_img_style(elem)
      end

      def why
        I18n.t("Alt text is a description of an image only visible to screen readers.
        Screen readers are software to help people who are blind or have low vision interact with websites and computers.
        The filename is not an adequate description of an image.")
      end
    end
  end
end
