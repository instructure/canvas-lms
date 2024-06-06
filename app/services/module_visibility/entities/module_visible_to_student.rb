# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module ModuleVisibility
  module Entities
    # When a module is visible to a (student) user
    class ModuleVisibleToStudent
      attr_reader :course_id,
                  :user_id,
                  :context_module_id

      def initialize(course_id:,
                     user_id:,
                     context_module_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "context_module_id cannot be nil" if context_module_id.nil?

        @course_id = course_id
        @user_id = user_id
        @context_module_id = context_module_id
      end

      # two ModuleVisibleToStudent DTOs are equal if all of their attributes are equal
      def ==(other)
        return false unless other.is_a?(ModuleVisibleToStudent)

        course_id == other.course_id &&
          user_id == other.user_id &&
          context_module_id == other.context_module_id
      end

      def eql?(other)
        self == other
      end

      def hash
        [course_id, user_id, context_module_id].hash
      end
    end
  end
end
