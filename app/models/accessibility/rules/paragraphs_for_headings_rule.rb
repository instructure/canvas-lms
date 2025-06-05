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
    class ParagraphsForHeadingsRule < Accessibility::Rule
      self.id = "paragraphs-for-headings"
      self.link = ""

      MAX_HEADING_LENGTH = 120

      IS_HEADING = {
        "h1" => true,
        "h2" => true,
        "h3" => true,
        "h4" => true,
        "h5" => true,
        "h6" => true
      }.freeze

      def self.test(elem)
        return true unless IS_HEADING[elem.tag_name.downcase]

        elem.text_content.length <= MAX_HEADING_LENGTH
      end

      def self.message
        I18n.t("Headings should not contain more than 120 characters.")
      end

      def self.why
        I18n.t("Sighted users browse web pages quickly, looking for large or bolded headings. Screen reader users rely on headers for contextual understanding. Headers should be concise within the proper structure.")
      end

      def self.link_text
        ""
      end

      def self.form(_elem)
        Accessibility::Forms::CheckboxField.new(
          label: "Change heading tag to paragraph",
          value: "false"
        )
      end

      def self.fix(elem, value)
        return elem unless value == "true"

        elem.name = "p"
        elem
      end
    end
  end
end
