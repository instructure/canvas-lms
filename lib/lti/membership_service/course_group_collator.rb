#
# Copyright (C) 2016 - present Instructure, Inc.
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
#

module Lti
  module MembershipService
    class CourseGroupCollator < CollatorBase
      attr_reader :role, :per_page, :page, :context, :user

      def initialize(context, opts={})
        super()
        @role = opts[:role]
        @per_page = [[opts[:per_page].to_i, Api.per_page].max, Api.max_per_page].min
        @page = [opts[:page].to_i, 1].max
        @context = context
      end

      def memberships
        @_memberships ||= collate_memberships
      end

      private

      def membership_type
        Group
      end

      def collate_memberships
        groups.to_a.slice(0, @per_page).map do |user|
          generate_membership(user)
        end
      end

      def groups
        @groups ||= bookmarked_collection.paginate(per_page: @per_page)
      end

      def scope
        @context.groups.active
      end

      def generate_member(group)
        IMS::LTI::Models::MembershipService::Context.new(
          name: group.name,
          context_id: Lti::Asset.opaque_identifier_for(group)
        )
      end

      def generate_membership(user)
        IMS::LTI::Models::MembershipService::Membership.new(
          status: IMS::LIS::Statuses::SimpleNames::Active,
          member: generate_member(user),
          role: [IMS::LIS::ContextType::URNs::Group]
        )
      end
    end
  end
end
