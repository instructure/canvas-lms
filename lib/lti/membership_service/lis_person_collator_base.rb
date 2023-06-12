# frozen_string_literal: true

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
    class LisPersonCollatorBase < CollatorBase
      attr_reader :user

      def initialize(context, user, opts = {})
        super(context, opts)
        @user = user
      end

      def memberships
        @memberships ||= begin
          ActiveRecord::Associations.preload(users, :pseudonym)
          ActiveRecord::Associations.preload(users, :communication_channels, CommunicationChannel.email.unretired)
          ActiveRecord::Associations.preload(users, :not_ended_enrollments, Enrollment.where(course_id: context))
          ActiveRecord::Associations.preload(users, :past_lti_ids, UserPastLtiId.where(context:))
          users.map do |user|
            generate_membership(user)
          end
        end
      end

      private

      def membership_type
        User
      end

      def users
        @users ||= bookmarked_collection.paginate(per_page: @per_page)
      end

      def generate_member(user)
        user_id = Lti::Asset.opaque_identifier_for(user, context:)
        ::IMS::LTI::Models::MembershipService::LISPerson.new(
          name: user.name,
          given_name: user.first_name,
          family_name: user.last_name,
          img: user.avatar_image_url,
          email: user.email,
          result_sourced_id: nil,
          user_id:,
          sourced_id: user&.pseudonym&.sis_user_id
        )
      end

      def generate_membership(user)
        ::IMS::LTI::Models::MembershipService::Membership.new(
          status: ::IMS::LIS::Statuses::SimpleNames::Active,
          member: generate_member(user),
          role: generate_roles(user)
        )
      end

      def generate_roles(_user)
        []
      end
    end
  end
end
