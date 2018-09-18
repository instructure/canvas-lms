#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Ims::Helpers
  class CourseMembershipsFinder < MembershipsFinder

    def context
      CourseContextDecorator.new(super)
    end

    protected

    def memberships_scope
      context.participating_enrollments.order(:user_id)
    end

    def membership(membership)
      CourseMembershipDecorator.new(membership)
    end

    # *Decorators fix up models to conforms to interface expected by Lti::Ims::NamesAndRolesSerializer
    class CourseMembershipDecorator < SimpleDelegator
      def lti_roles
        Lti::SubstitutionsHelper::LIS_ADVANTAGE_ROLE_MAP.fetch(__getobj__.class, [])
      end
    end

    class CourseContextDecorator < SimpleDelegator
      def context_label
        course_code
      end

      def context_title
        name
      end
    end
  end
end
