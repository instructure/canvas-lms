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

      def self.test(elem)
        return true if elem.tag_name != "img"

        alt = elem.attribute?("alt") ? elem.get_attribute("alt") : nil
        !alt.nil?
      end

      def self.message
        I18n.t("Images should include an alt attribute describing the image content.")
      end

      def self.why
        I18n.t("Screen readers cannot determine what is displayed in an image without alternative text, which describes the content and meaning of the image.")
      end

      def self.link_text
        I18n.t("Learn more about using alt text for images")
      end

      def self.form(_elem)
        Accessibility::Forms::TextInputField.new(
          label: "Change alt text",
          value: ""
        )
      end

      def self.fix(elem, value)
        elem["alt"] = value
      end
    end
  end
end
