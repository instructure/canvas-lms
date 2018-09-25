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

    def find_memberships
      # Users can have more than once active Enrollment in a Course. So first find all Users with such an
      # Enrollment, page on *those*, then find and flatten the enrollments for each.
      user_ids, users_metadata =
        Api.jsonapi_paginate(context.active_users.order(:id).select(:id), controller, base_url, pagination_args)

      enrollments = context.participating_enrollments.where(user_id: user_ids).order(:user_id)
      user_json_preloads(enrollments.map(&:user), true, { accounts: false })
      memberships = enrollments.
        group_by(&:user_id).
        values.
        map { |user_enrollments| CourseEnrollmentsDecorator.new(user_enrollments) }
      [ memberships, users_metadata ]
    end

    # *Decorators fix up models to conforms to interfaces expected by Lti::Ims::NamesAndRolesSerializer
    class CourseEnrollmentsDecorator
      attr_reader :enrollments

      def initialize(enrollments)
        @enrollments = enrollments
      end

      def user
        enrollments.first.user
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
