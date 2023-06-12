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
  class GroupMembershipsProvider < MembershipsProvider
    def context
      @_context ||= GroupContextDecorator.new(super)
    end

    protected

    def find_memberships
      scope = users_scope
      enrollments, metadata = paginate(scope)
      enrollments = preload_enrollments(enrollments)
      preload_past_lti_ids(enrollments)

      memberships = to_memberships(enrollments)
      [memberships, metadata]
    end

    def base_users_scope
      context.participating_group_memberships.order(:user_id).preload(:user)
    end

    def rlid_users_scope
      scope = base_users_scope
      if assignment? && !nonsense_role_filter?
        scope = scope.where(correlated_assignment_submissions("group_memberships.user_id").arel.exists)
      end
      apply_role_filter(scope)
    end

    def apply_role_filter(scope)
      return scope unless role?

      enrollment_types = queryable_roles(role)
      if enrollment_types.present? && group_role?(enrollment_types)
        (enrollment_types == [:group_leader]) ? scope.where(user: context.leader_id) : scope
      else
        scope.none
      end
    end

    def course
      context.course
    end

    private

    def group_role?(enrollment_types)
      enrollment_types.intersect?([:group_leader, :group_member])
    end

    def to_memberships(enrollments)
      enrollments.map { |e| GroupMembershipDecorator.new(e, tool) }
    end

    # *Decorators fix up models to conforms to interface expected by Lti::IMS::NamesAndRolesSerializer
    class GroupMembershipDecorator < SimpleDelegator
      def initialize(membership, tool)
        super(membership)
        @tool = tool
      end

      def unwrap
        __getobj__
      end

      def context
        @_context ||= GroupContextDecorator.new(super)
      end

      def group
        @_group ||= GroupContextDecorator.new(super)
      end

      def lti_roles
        @_lti_roles ||= (user.id == context.leader_id) ? group_leader_role_urns : group_member_role_urns
      end

      private

      def group_leader_role_urns
        Lti::SubstitutionsHelper::LIS_V2_LTI_ADVANTAGE_ROLE_MAP[:group_leader]
      end

      def group_member_role_urns
        Lti::SubstitutionsHelper::LIS_V2_LTI_ADVANTAGE_ROLE_MAP[:group_member]
      end
    end

    class GroupContextDecorator < SimpleDelegator
      def unwrap
        __getobj__
      end

      def context_label
        nil
      end

      def context_title
        name
      end
    end
  end
end
