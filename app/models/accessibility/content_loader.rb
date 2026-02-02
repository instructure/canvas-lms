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
  class ContentLoader
    class UnsupportedResourceTypeError < StandardError; end
    class ElementNotFoundError < StandardError; end

    include ::Accessibility::NokogiriMethods

    def initialize(issue_id:)
      @issue = AccessibilityIssue.find(issue_id)
      @resource = @issue.context
      @rule_id = @issue.rule_type
      @path = @issue.node_path
    end

    def content
      if @path.present?
        html, metadata = extract_element_from_content
        { content: html, metadata: }
      else
        { content: full_document, metadata: {} }
      end
    end

    def full_document
      resource_html_content
    end

    def extract_element_from_content
      html_content = resource_html_content

      element = find_element_at_path(html_content, @path)

      raise ElementNotFoundError, "Element not found at path: #{@path}" unless element

      html = generate_preview_html(element)
      metadata = extract_metadata(element)
      [html, metadata]
    end

    private

    def resource_html_content
      case @resource
      when Assignment
        @resource.description
      when WikiPage
        @resource.body
      when DiscussionTopic, Announcement
        @resource.message
      else
        raise UnsupportedResourceTypeError, "Unsupported resource type: #{@resource.class.name}"
      end
    end

    def generate_preview_html(element)
      return element.to_html unless @rule_id

      rule = Accessibility::Rule.registry[@rule_id]
      return element.to_html unless rule

      rule.issue_preview(element) || element.to_html
    end

    def extract_metadata(element)
      return {} unless @rule_id

      rule = Accessibility::Rule.registry[@rule_id]
      return {} unless rule

      rule.respond_to?(:issue_metadata) ? rule.issue_metadata(element) : {}
    end
  end
end
