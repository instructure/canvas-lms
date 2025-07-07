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
        return nil if alt.blank?

        "Alt text is longer than #{MAX_LENGTH}." if alt.length > MAX_LENGTH
      end

      def self.message
        "Image alt text should be concise (less than #{MAX_LENGTH} characters)."
      end

      def self.why
        "Excessively long alt text can be overwhelming for screen reader users. " \
          "A concise description is more effective and easier to understand."
      end

      def self.link_text
        "Learn more about writing effective alt text for images"
      end

      def self.form(elem)
        Accessibility::Forms::TextInputField.new(
          label: "Change alt text",
          value: elem.get_attribute("alt") || ""
        )
      end

      def self.fix!(elem, value)
        raise StandardError, "Too long alt text. It should be less than #{MAX_LENGTH} characters." if value.length > MAX_LENGTH

        return nil if elem["alt"] == value

        elem["alt"] = value
        elem
      end
    end
  end
end
