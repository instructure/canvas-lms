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
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H37.html"

      def self.test(elem)
        return nil if elem.tag_name != "img"
        return nil unless elem.attribute?("alt") && elem.attribute?("src")

        alt = elem.get_attribute("alt")
        role = elem.attribute?("role") ? elem.get_attribute("role") : nil

        return nil if alt == "" && role == "presentation"
        return nil if alt.blank?

        src = elem.get_attribute("src")
        filename = src.split("/").last.split("?").first
        filename_without_extension = filename.split(".").first

        I18n.t("Alt text should not be the filename of the image.") if alt == filename || alt == filename_without_extension
      end

      def self.message
        I18n.t("The alt text is just the file name. Add a description for screen readers
        so people who are blind or have low vision can understand what's in the image.")
      end

      def self.why
        I18n.t("Alt text is a description of an image only visible to screen readers.
        Screen readers are software to help people who are blind or have low vision interact with websites and computers.
        The filename is not an adequate description of an image.")
      end

      def self.link_text
        I18n.t("Learn more about providing meaningful alt text")
      end

      def self.display_name
        I18n.t("Alt text is filename")
      end

      def self.form(elem)
        Accessibility::Forms::TextInputWithCheckboxField.new(
          checkbox_label: I18n.t("This image is decorative"),
          checkbox_subtext: I18n.t("This image is for visual decoration only and screen readers can skip it."),
          input_label: I18n.t("Alt text"),
          input_description: I18n.t("Describe what's on the picture."),
          input_max_length: 120,
          input_value: elem.get_attribute("alt") || ""
        )
      end

      def self.fix!(elem, value)
        if value == "" || value.nil?
          elem["role"] = "presentation"
        else
          src = elem.get_attribute("src")
          if src
            filename = src.split("/").last.split("?").first
            filename_without_extension = filename.split(".").first
            if value == filename || value == filename_without_extension
              raise StandardError, I18n.t("Alt text should not be the filename of the image.")
            end
          end
        end

        return nil if elem["alt"] == value

        elem["alt"] = value
        elem
      end
    end
  end
end
