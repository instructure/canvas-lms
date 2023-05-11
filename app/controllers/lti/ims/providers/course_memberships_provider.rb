# frozen_string_literal: true

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

module Lti::IMS::Providers
  class CourseMembershipsProvider < MembershipsProvider
    def context
      @_context ||= CourseContextDecorator.new(super)
    end

    protected

    def find_memberships
      scope = users_scope

      # Users can have more than once active Enrollment in a Course. So first find all Users with such an
      # Enrollment, page on *those*, then find and group the enrollments for each.
      user_ids, users_metadata = paginate(scope)

      enrollments = base_enrollments_scope(user_ids)
      enrollments = preload_enrollments(enrollments)
      preload_past_lti_ids(enrollments)

      memberships = to_memberships(enrollments)
      [memberships, users_metadata]
    end

    def course
      context
    end

    private

    def base_users_scope
      context.active_users.order(:id).select(:id)
    end

    def rlid_users_scope
      if !assignment? || filter_students? || nonsense_role_filter?
        # No point in applying assignment rlid filter since either:
        #   a) the `rlid` param isn't present or doesn't refer to an assignment, not
        #   a) the `role` param is already excluding all students (assignment rlid filters only impact students), or
        #   b) the `role` param is junk, in which case it filters out *everybody*
        apply_role_filter(base_users_scope)
      else
        # Non-active students get an active ('submitted') Submission, so join on base_users_scope to narrow down
        # Submissions to only active students.
        students_scope = base_users_scope.where(enrollments: { type: student_queryable_roles })
        narrowed_students_scope = students_scope.where(correlated_assignment_submissions("users.id").arel.exists)
        # If we only care about students, this scope is sufficient and can avoid the ugly union down below
        return narrowed_students_scope if filter_non_students?

        non_students_scope = apply_role_filter(base_users_scope.where.not(enrollments: { type: student_queryable_roles }))
        non_students_scope.union(narrowed_students_scope).distinct.order(:id).select(:id)
      end
    end

    def student_queryable_roles
      queryable_roles("http://purl.imsglobal.org/vocab/lis/v2/membership#Learner")
    end

    def filter_students?
      role? && (student_queryable_roles != queryable_roles(role))
    end

    def filter_non_students?
      role? && (student_queryable_roles == queryable_roles(role))
    end

    def apply_role_filter(scope)
      return scope unless role?

      enrollment_types = queryable_roles(role)
      enrollment_types.present? ? scope.where(enrollments: { type: enrollment_types }) : scope.none
    end

    def base_enrollments_scope(user_ids)
      context.participating_enrollments.where(user_id: user_ids).order(:user_id).preload(:sis_pseudonym)
    end

    def to_memberships(enrollments)
      enrollments
        .group_by(&:user_id)
        .values
        .map { |user_enrollments| CourseEnrollmentsDecorator.new(user_enrollments, tool) }
    end

    # *Decorators fix up models to conforms to interfaces expected by Lti::IMS::NamesAndRolesSerializer
    class CourseEnrollmentsDecorator
      attr_reader :enrollments

      def initialize(enrollments, tool)
        @enrollments = enrollments
        @tool = tool
      end

      def unwrap
        enrollments
      end

      def user
        @_user ||= enrollments.first.user
      end

      def context
        @_context ||= CourseContextDecorator.new(enrollments.first.context)
      end

      def course
        @_course ||= CourseContextDecorator.new(enrollments.first.course)
      end

      def lti_roles
        @_lti_roles ||= enrollments.filter_map { |e| Lti::SubstitutionsHelper::LIS_V2_LTI_ADVANTAGE_ROLE_MAP[e.class] }.flatten.uniq
      end
    end

    class CourseContextDecorator < SimpleDelegator
      def unwrap
        __getobj__
      end

      def context_label
        course_code
      end

      def context_title
        name
      end
    end
  end
end
