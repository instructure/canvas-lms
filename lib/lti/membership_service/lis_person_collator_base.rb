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
    class LisPersonCollatorBase
      attr_reader :role, :per_page, :page

      def initialize(opts={})
        @role = opts[:role]
        @per_page = [[opts[:per_page].to_i, Api.per_page].max, Api.max_per_page].min
        @page = [opts[:page].to_i - 1, 0].max
      end

      def next_page?
        users.length > @per_page
      end

      def memberships
        @memberships ||= users.slice(0, @per_page).map do |user|
          generate_membership(user)
        end
      end

      private

      def users
        []
      end

      def generate_member(user)
        IMS::LTI::Models::MembershipService::LISPerson.new(
          name: user.name,
          given_name: user.first_name,
          family_name: user.last_name,
          img: user.avatar_image_url,
          email: user.email,
          result_sourced_id: nil,
          user_id: Lti::Asset.opaque_identifier_for(user)
        )
      end

      def generate_membership(user)
        IMS::LTI::Models::MembershipService::Membership.new(
          status: IMS::LIS::Statuses::SimpleNames::Active,
          member: generate_member(user),
          role: generate_roles(user)
        )
      end

      def generate_roles(user)
        []
      end
    end
  end
end
