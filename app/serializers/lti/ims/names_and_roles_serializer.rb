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
        id: lti_id(page[:context]),
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
      member(enrollment).merge!(message(enrollment)).compact
    end

    def member(enrollment)
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
        user_id: lti_id(enrollment.user),
        roles: enrollment.lti_roles
      }
    end

    def message(enrollment)
      return {} if page[:opts].blank? || page[:opts][:rlid].blank?
      orig_locale = I18n.locale
      orig_time_zone = Time.zone
      begin
        I18n.locale = enrollment.user.locale || orig_locale
        Time.zone = enrollment.user.time_zone || orig_time_zone
        launch = Lti::Messages::ResourceLinkRequest.new(
          tool: page[:tool],
          context: unwrap(page[:context]),
          user: enrollment.user,
          expander: enrollment.user.expander,
          return_url: nil,
          opts: {
            # See Lti::Ims::Providers::MembershipsProvider for additional constraints on custom param expansion
            # already baked into `enrollment.user.expander`
            claim_group_whitelist: [ :custom_params, :i18n ]
          }
        ).generate_post_payload_message
      ensure
        I18n.locale = orig_locale
        Time.zone = orig_time_zone
      end

      # One straggler field we can't readily control via white/blacklists
      launch_hash = launch.to_h.except!("#{LtiAdvantage::Serializers::JwtMessageSerializer::IMS_CLAIM_PREFIX}version")
      { message: [ launch_hash ] }
    end

    def lti_id(entity)
      Lti::Asset.opaque_identifier_for(unwrap(entity))
    end

    def unwrap(wrapped)
      wrapped&.respond_to?(:unwrap) ? wrapped.unwrap : wrapped
    end

    attr_reader :page
  end
end
