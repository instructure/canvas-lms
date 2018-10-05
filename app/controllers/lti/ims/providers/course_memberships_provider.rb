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

module Lti::Ims::Providers
  class CourseMembershipsProvider < MembershipsProvider

    def context
      CourseContextDecorator.new(super)
    end

    protected

    def find_memberships
      # Users can have more than once active Enrollment in a Course. So first find all Users with such an
      # Enrollment, page on *those*, then find and group the enrollments for each.
      scope = base_users_scope
      scope = apply_role_param(scope) if controller.params.key?(:role)
      user_ids, users_metadata = paginate(scope)

      enrollments = base_enrollments_scope(user_ids)
      enrollments = preload_enrollments(enrollments)

      memberships = to_memberships(enrollments)
      [ memberships, users_metadata ]
    end

    private

    def base_users_scope
      context.active_users.order(:id).select(:id)
    end

    def apply_role_param(users_scope)
      enrollment_type = Lti::SubstitutionsHelper::INVERTED_LIS_ADVANTAGE_ROLE_MAP[controller.params[:role]]
      enrollment_type ? users_scope.where(enrollments: { type: enrollment_type }) : users_scope.none
    end

    def base_enrollments_scope(user_ids)
      context.participating_enrollments.where(user_id: user_ids).order(:user_id)
    end

    def to_memberships(enrollments)
      enrollments.
        group_by(&:user_id).
        values.
        map { |user_enrollments| CourseEnrollmentsDecorator.new(user_enrollments, tool) }
    end

    # *Decorators fix up models to conforms to interfaces expected by Lti::Ims::NamesAndRolesSerializer
    class CourseEnrollmentsDecorator
      attr_reader :enrollments

      def initialize(enrollments, tool)
        @enrollments = enrollments
        @tool = tool
      end

      def user
        MembershipsProvider::UserDecorator.new(enrollments.first.user, @tool)
      end

      def context
        CourseContextDecorator.new(enrollments.first.context)
      end

      def course
        CourseContextDecorator.new(enrollments.first.course)
      end

      def lti_roles
        enrollments.map { |e| Lti::SubstitutionsHelper::LIS_ADVANTAGE_ROLE_MAP[e.class] }.compact.flatten.uniq
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
