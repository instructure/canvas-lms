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

require_dependency "accessibility/syllabus_resource"

module Accessibility
  module Concerns
    module ResourceResolvable
      extend ActiveSupport::Concern

      # This concern handles the resolution of the actual resource to be scanned.
      # It abstracts the complexity of handling syllabus (which uses is_syllabus flag)
      # vs regular polymorphic resources.

      included do
        attr_writer :resource
      end

      def resource
        @resource ||= resolve_resource
      end

      private

      def resolve_resource
        if is_syllabus?
          Accessibility::SyllabusResource.new(course)
        else
          # later instead of just loading the polymorphic association directly
          # we need to wrap it to provide the AccessibilityCheckable interface
          # like Accessibility::SyllabusResource does for syllabus
          # we can have the same abstraction for Assignment, WikiPage, etc.
          # eg: Accessibility::AssignmentResource.new(assignment) or a more generic one
          # so the scannable records could have a unified interface
          context
        end
      end
    end
  end
end
