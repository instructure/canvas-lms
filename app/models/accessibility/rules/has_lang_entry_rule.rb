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
    class HasLangEntryRule < Accessibility::Rule
      self.id = "has-lang-entry"
      self.link = "https://www.w3.org/WAI/WCAG21/Techniques/pdf/PDF19"

      def self.test(elem)
        info = elem.info || {}

        # Language can be stored in different fields depending on the PDF creator
        info.values_at(:Lang, :Language, "Lang", "Language").any?
      end

      def self.message
        "PDF language is not specified in the document properties."
      end

      def self.why
        "The objective of this technique is to specify the language of a passage, phrase, " \
          "or word using the /Lang entry to provide information in the PDF document that user " \
          "agents need to present text and other linguistic content correctly. "
      end

      def self.link_text
        "Learn more about specifying language in PDF documents"
      end
    end
  end
end
