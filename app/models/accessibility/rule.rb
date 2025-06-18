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
  class Rule
    class << self
      attr_accessor :id, :link

      def registry
        rules = [
          Accessibility::Rules::AdjacentLinksRule,
          Accessibility::Rules::HeadingsSequenceRule,
          Accessibility::Rules::HeadingsStartAtH2Rule,
          Accessibility::Rules::ImgAltFilenameRule,
          Accessibility::Rules::ImgAltLengthRule,
          Accessibility::Rules::ImgAltRule,
          Accessibility::Rules::LargeTextContrastRule,
          Accessibility::Rules::ListStructureRule,
          Accessibility::Rules::ParagraphsForHeadingsRule,
          Accessibility::Rules::SmallTextContrastRule,
          Accessibility::Rules::TableCaptionRule,
          Accessibility::Rules::TableHeaderRule,
          Accessibility::Rules::TableHeaderScopeRule
        ]

        rules.index_by(&:id)
      end

      def pdf_registry
        [
          Accessibility::Rules::HasLangEntryRule,
        ]
      end

      # Tests if an element passes this accessibility rule
      # @param elem [Nokogiri::XML::Element] The element to test
      # @return [Boolean] True if the element passes, false if there's an issue
      def test(elem)
        raise NotImplementedError, "#{self} must implement/override test"
      end

      # Gets a form definition for correcting the issue
      # @param _elem [Nokogiri::XML::Element] The element in the content to fix
      # @return [FormField] Form field for correcting the issue
      def form(_elem)
        {}
      end

      # Fixes the issue in content, returning the updated element
      # @param _elem [Nokogiri::XML::Element] The element in the content to fix
      # @param _value [String] The value received back from the correction form
      # @return [Nokogiri::XML::Element] The updated element
      def fix(_elem, _value)
        raise NotImplementedError, "#{self} must implement fix"
      end

      # Gets the message for users about this rule
      # @return [String] The message about this issue
      def message
        raise NotImplementedError, "#{self} must implement message"
      end

      # Gets the explanation of why this issue is important
      # @return [String] The explanation of the issue
      def why
        raise NotImplementedError, "#{self} must implement/override why"
      end

      # Gets text for the link to documentation
      # @return [String] The link text
      def link_text
        ""
      end
    end
  end
end
