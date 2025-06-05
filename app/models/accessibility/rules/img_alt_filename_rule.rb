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
        return true if elem.tag_name != "img"
        return true unless elem.attribute?("alt") && elem.attribute?("src")

        alt = elem.get_attribute("alt")
        return true if alt.blank?

        src = elem.get_attribute("src")
        filename = src.split("/").last.split("?").first
        filename_without_extension = filename.split(".").first

        alt != filename && alt != filename_without_extension
      end

      def self.message
        "Image alt text should not just be the filename."
      end

      def self.why
        "Using the filename as alt text does not provide meaningful information about the image content. " \
          "Screen reader users need descriptive alt text that explains the purpose and content of the image."
      end

      def self.link_text
        "Learn more about providing meaningful alt text"
      end

      def self.form(elem)
        Accessibility::Forms::TextInputField.new(
          label: "Change alt text",
          value: elem.get_attribute("alt") || ""
        )
      end

      def self.fix(elem, value)
        elem["alt"] = value
      end
    end
  end
end
