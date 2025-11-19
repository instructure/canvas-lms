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
        [
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
        ].to_h { |rule_class| [rule_class.id, rule_class.new] }
      end

      def pdf_registry
        [
          Accessibility::Rules::HasLangEntryRule,
        ].map(&:new)
      end
    end

    # Tests if an element passes this accessibility rule
    # @param elem [Nokogiri::XML::Element] The element to test
    # @return [String] nil if the element passes, the validation problem
    # if there's an issue
    def test(elem)
      raise NotImplementedError, "#{self.class} must implement/override test"
    end

    # Gets a form definition for correcting the issue
    # @param _elem [Nokogiri::XML::Element] The element in the content to fix
    # @return [FormField] Form field for correcting the issue
    def form(_elem)
      {}
    end

    # Generates a fix for the issue in the content, to be used in the
    # correction form
    # @param _elem [Nokogiri::XML::Element] The element in the content to fix
    # @return [String] The generated fix, or nil if generation is not supported
    # @throws [StandardError] if the fix cannot be generated for a reason
    def generate_fix(_elem)
      nil
    end

    # Fixes the issue in content, changing it in-place
    # @param _elem [Nokogiri::XML::Element] The element in the content to fix
    # @param _value [String] The value received back from the correction form
    # @throws [StandardError] if the fix cannot be applied for a reason
    # @throws [NotImplementedError] if not implemented in a rule
    # @return [String] Potential error message if the fix fails, or nil if it
    # succeeds
    def fix!(_elem, _value)
      raise NotImplementedError, "#{self.class} must implement fix"
    end

    # Gets the name of this rule
    # @return [String] The name of this rule
    def display_name
      raise NotImplementedError, "#{self.class} must implement display_name"
    end

    # Gets the message for users about this rule
    # @return [String] The message about this issue
    def message
      raise NotImplementedError, "#{self.class} must implement message"
    end

    # Gets the explanation of why this issue is important
    # @return [String] The explanation of the issue
    def why
      raise NotImplementedError, "#{self.class} must implement/override why"
    end

    # Provides a preview of the issue for displaying in the UI
    # @return [String, nil] HTML preview of the issue, or nil if no preview is available
    def issue_preview(_elem)
      nil
    end
  end
end
