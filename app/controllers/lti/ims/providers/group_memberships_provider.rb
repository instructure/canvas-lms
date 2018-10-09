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
  class GroupMembershipsProvider < MembershipsProvider

    def context
      @_context ||= GroupContextDecorator.new(super)
    end

    protected

    def find_memberships
      # TODO: queries likely change dramatically if rlid matches an Assignment ResourceLink b/c scope needs to be
      # further narrowed to only those users having access to the Assignment.
      scope = base_scope
      scope = apply_role_param(scope) if controller.params.key?(:role)
      enrollments, metadata = paginate(scope)
      enrollments = preload_enrollments(enrollments)

      memberships = to_memberships(enrollments)
      [ memberships, metadata ]
    end

    def course
      context.course
    end

    private

    def base_scope
      context.participating_group_memberships.order(:user_id).preload(:user)
    end

    def apply_role_param(scope)
      enrollment_type = Lti::SubstitutionsHelper::INVERTED_LIS_ADVANTAGE_ROLE_MAP[controller.params[:role]]
      if enrollment_type
        # using context.leader_id instead of context.leader saves one redundant User query
        (enrollment_type == [:group_leader] ? scope.where(user: context.leader_id) : scope)
      else scope.none
      end
    end

    def to_memberships(enrollments)
      enrollments.map { |e| GroupMembershipDecorator.new(e, tool, self) }
    end

    # *Decorators fix up models to conforms to interface expected by Lti::Ims::NamesAndRolesSerializer
    class GroupMembershipDecorator < SimpleDelegator

      def initialize(membership, tool, user_factory)
        super(membership)
        @tool = tool
        @user_factory = user_factory
      end

      def context
        @_context ||= GroupContextDecorator.new(super)
      end

      def group
        @_group ||= GroupContextDecorator.new(super)
      end

      def user
        @_user ||= @user_factory.user(super)
      end

      def lti_roles
        @_lti_roles ||= user.id == context.leader_id ? group_leader_role_urns : group_member_role_urns
      end

      private

      def group_leader_role_urns
        Lti::SubstitutionsHelper::LIS_ADVANTAGE_ROLE_MAP[:group_leader]
      end

      def group_member_role_urns
        Lti::SubstitutionsHelper::LIS_ADVANTAGE_ROLE_MAP[:group_member]
      end
    end

    class GroupContextDecorator < SimpleDelegator
      def context_label
        nil
      end

      def context_title
        name
      end
    end
  end
end
