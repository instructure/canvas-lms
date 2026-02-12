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
  # SyllabusResource is a wrapper around Course that makes it behave like
  # a scannable resource for accessibility checking purposes.
  # This is necessary because syllabus is not a separate model but a field on Course.
  class SyllabusResource
    include Accessibility::Concerns::AccessibilityCheckable

    attr_reader :course

    delegate :id, :syllabus_body, :updated_at, :global_id, to: :course

    def initialize(course)
      @course = course
    end

    # Delegate any undefined methods to the underlying Course object
    # This ensures SyllabusResource can respond to any Course method
    def method_missing(method, *, &)
      if course.respond_to?(method)
        course.send(method, *, &)
      else
        super
      end
    end

    # Properly implement respond_to? for delegated methods
    def respond_to_missing?(method, include_private = false)
      course.respond_to?(method, include_private) || super
    end

    # Implementation of AccessibilityCheckable interface

    def scannable_content_column
      :syllabus_body
    end

    def title
      "Course Syllabus"
    end

    def scannable_workflow_state
      course.published? ? "published" : "unpublished"
    end

    def scannable_resource_tag
      "accessibility.syllabus_scanned"
    end

    def resource_class_name
      "Syllabus"
    end
  end
end
