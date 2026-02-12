# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  module Concerns
    # AccessibilityCheckable - Standard Interface for Scannable Resources
    #
    # This concern defines the COMPLETE interface that any resource must implement
    # to be scannable for accessibility issues. This is the single source of truth
    # for what methods a scannable resource must provide.
    #
    # IMPORTANT: If you need to add a new method that differs between resource types
    # (Assignment, DiscussionTopic, WikiPage, Syllabus, etc.), it MUST be defined here.
    # This ensures all scannable resources follow the same interface and prevents
    # fragmentation of the accessibility scanning logic across different models.
    #
    # Current implementations:
    # - Assignment (via model inclusion)
    # - DiscussionTopic (via model inclusion)
    # - WikiPage (via model inclusion)
    # - Announcement (inherits from DiscussionTopic)
    # - SyllabusResource (wrapper around Course, via direct inclusion)
    #
    # To add a new scannable resource:
    # 1. Include this concern in your model or wrapper class
    # 2. Implement all required methods (those that raise NotImplementedError)
    # 3. Override optional methods as needed for your specific resource type
    #
    # MIGRATION STRATEGY:
    # Currently, only SyllabusResource uses this interface directly. Other models
    # (Assignment, WikiPage, DiscussionTopic) still use their legacy implementations.
    # The plan is to gradually migrate each model to use this standardized interface:
    #
    # Step 1 (COMPLETED): Create wrapper for special cases (SyllabusResource for Course.syllabus_body)
    # Step 2a (FUTURE): Create wrappers for existing models:
    #   - Accessibility::AssignmentResource.new(assignment)
    #   - Accessibility::WikiPageResource.new(wiki_page)
    #   - Accessibility::DiscussionTopicResource.new(discussion_topic)
    # Step 2b (ALTERNATIVE): Inject this concern directly into AR models (Assignment, WikiPage, etc.)
    #   - This would keep accessibility logic separate in concern files
    #   - Avoids polluting the main AR model files with accessibility-specific code
    #   - Models would include Accessibility::Concerns::AccessibilityCheckable
    # Step 3: Update ResourceResolvable#resolve_resource to use these wrappers
    # Step 4: Remove legacy code from individual models
    #
    # This gradual migration allows us to:
    # - Maintain backwards compatibility during the transition
    # - Test each resource type individually
    # - Avoid a massive breaking change
    # - Ensure all resources eventually follow the same interface
    #
    # See app/models/accessibility/concerns/resource_resolvable.rb for how resources
    # are resolved and how the migration will be handled.
    #
    module AccessibilityCheckable
      extend ActiveSupport::Concern

      # MANDATORY Methods
      # - Must be implemented by including classes
      #
      # Returns the actual content to be scanned
      def scannable_content
        send(scannable_content_column) if respond_to?(scannable_content_column)
      end

      # The database column containing scannable content
      # Must be implemented by including classes
      def scannable_content_column
        raise NotImplementedError, "#{self.class} must implement scannable_content_column"
      end

      # The workflow state for accessibility scanning purposes
      # Must be implemented by including classes
      def scannable_workflow_state
        raise NotImplementedError, "#{self.class} must implement scannable_workflow_state"
      end

      # OPTIONAL Methods
      # - Can be overridden by including classes -> Currently we treat these as generic defaults
      #
      # Display name for the resource in accessibility reports
      def scannable_display_name
        try(:title) || try(:name) || "Untitled"
      end

      # The type of resource for categorization
      def scannable_resource_type
        self.class.name
      end

      # Size of the scannable content in bytes
      def scannable_content_size
        scannable_content&.size || 0
      end

      # Check if content exceeds the scan size limit
      def exceeds_accessibility_scan_limit?(max_size)
        scannable_content_size > max_size
      end

      # Check if there is content to scan
      def scannable_content?
        scannable_content.present?
      end
    end
  end
end
