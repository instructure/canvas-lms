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
  class GroupMembershipsFinder < MembershipsFinder

    def context
      GroupContextDecorator.new(super)
    end

    protected

    def find_memberships
      scope = context.participating_group_memberships.order(:user_id).preload(:user)
      enrollments, metadata =
        Api.jsonapi_paginate(scope, controller, base_url, pagination_args)
      user_json_preloads(enrollments.map(&:user), true, { accounts: false })
      memberships = enrollments.map { |e| GroupMembershipDecorator.new(e) }
      [ memberships, metadata ]
    end

    # *Decorators fix up models to conforms to interface expected by Lti::Ims::NamesAndRolesSerializer
    class GroupMembershipDecorator < SimpleDelegator
      def context
        GroupContextDecorator.new(super)
      end

      def group
        GroupContextDecorator.new(super)
      end

      def lti_roles
        # TODO: these URNs should be constantized somewhere... probably when we implement the 'role' query param
        roles = ["http://purl.imsglobal.org/vocab/lis/v2/membership#Member"]
        roles << "http://purl.imsglobal.org/vocab/lis/v2/membership#Manager" if user.id == context.leader_id
        roles
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
