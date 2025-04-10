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
        @registry ||= []
      end

      def inherited(subclass)
        super&.inherited(subclass)
        registry << subclass
      end

      def load_all_rules
        Dir[File.join(File.dirname(__FILE__), "*_rule.rb")].each do |file|
          require_dependency file
        rescue LoadError => e
          Rails.logger.error("Failed to load accessibility rule: #{e}")
        end
        registry
      end

      # Tests if an element passes this accessibility rule
      # @param elem [Nokogiri::XML::Element] The element to test
      # @return [Boolean] True if the element passes, false if there's an issue
      def test(elem)
        raise NotImplementedError, "#{self} must implement test"
      end

      # Gets data needed for rendering and correcting the issue
      # @param elem [Nokogiri::XML::Element] The element that failed the test
      # @return [Hash] Data describing the issue
      def data(_elem)
        {}
      end

      # Gets a form definition for correcting the issue
      # @return [Array<FormField>] Form fields for correcting the issue
      def form
        []
      end

      # Updates an element to fix accessibility issues
      # @param elem [Nokogiri::XML::Element] The element to update
      # @param data [Hash] Data from the form submission
      # @return [Nokogiri::XML::Element] The updated element
      def update(_elem, _data)
        raise NotImplementedError, "#{self} must implement update"
      end

      # Gets the root node for this rule's updates
      # @param elem [Nokogiri::XML::Element] The original element
      # @return [Nokogiri::XML::Element] The root element for updates
      def root_node(elem)
        elem
      end

      # Gets the message for users about this rule
      # @return [String] The message about this issue
      def message
        raise NotImplementedError, "#{self} must implement message"
      end

      # Gets the explanation of why this issue is important
      # @return [String] The explanation of the issue
      def why
        raise NotImplementedError, "#{self} must implement why"
      end

      # Gets text for the link to documentation
      # @return [String] The link text
      def link_text
        I18n.t("Learn more")
      end
    end
  end
end
