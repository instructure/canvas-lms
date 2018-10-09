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

module Lti::Ims
  class NamesAndRolesSerializer
    def initialize(page)
      @page = page
    end

    def as_json
      {
        id: page[:url],
        context: serialize_context,
        members: serialize_memberships,
      }.compact
    end

    private

    def serialize_context
      {
        id: lti_id_for(page[:context]),
        label: page[:context].context_label,
        title: page[:context].context_title,
      }.compact
    end

    def serialize_memberships
      page[:memberships] ? page[:memberships].collect { |m| serialize_membership(m) } : []
    end

    def serialize_membership(enrollment)
      # Inbound model is either an ActiveRecord Enrollment or GroupMembership, with delegations in place
      # to make them behave more or less the same for our purposes
      {
        status: 'Active',
        name: enrollment.user.name,
        picture: enrollment.user.avatar_image_url,
        given_name: enrollment.user.first_name,
        family_name: enrollment.user.last_name,
        email: enrollment.user.email,
        lis_person_sourcedid: enrollment.user.sourced_id,
        # enrollment.user often wrapped for privacy policy reasons, but calculating the LTI ID really needs
        # access to underlying AR model.
        user_id: lti_id_for(enrollment.user.respond_to?(:user) ? enrollment.user.user : enrollment.user),
        roles: enrollment.lti_roles
      }.compact
    end

    def lti_id_for(entity)
      Lti::Asset.opaque_identifier_for(entity)
    end

    attr_reader :page
  end
end
