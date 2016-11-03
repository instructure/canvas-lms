#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
    class CourseGroupCollator
      attr_reader :role, :per_page, :page, :context, :user, :memberships

      def initialize(context, opts={})
        @role = opts[:role]
        @per_page = [[opts[:per_page].to_i, Api.per_page].max, Api.max_per_page].min
        @page = [opts[:page].to_i - 1, 0].max
        @context = context
        @memberships = collate_memberships
      end

      def next_page?
        groups.length > @per_page
      end

      private

      def collate_memberships
        groups.slice(0, @per_page).map do |user|
          generate_membership(user)
        end
      end

      def groups
        @groups ||= @context.groups.active
                             .order(:id)
                             .offset(@page * @per_page)
                             .limit(@per_page + 1)
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
