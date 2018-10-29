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
      expander = variable_expander(enrollment.user)
      member(enrollment, expander).merge!(message(enrollment, expander))
    end

    def variable_expander(user)
      Lti::VariableExpander.new(
        page[:context].root_account,
        Lti::Ims::Providers::MembershipsProvider.unwrap(page[:context]),
        page[:controller],
        {
          current_user: Lti::Ims::Providers::MembershipsProvider.unwrap(user),
          tool: page[:tool],
          variable_whitelist: %w(
            Person.name.full
            Person.name.display
            Person.name.family
            Person.name.given
            User.image
            User.id
            Canvas.user.id
            vnd.instructure.User.uuid
            Canvas.user.globalId
            Canvas.user.sisSourceId
            Person.sourcedId
            Message.locale
            vnd.Canvas.Person.email.sis
            Person.email.primary
            Person.address.timezone
            User.username
            Canvas.user.loginId
            Canvas.user.sisIntegrationId
            Canvas.xapi.url
            Caliper.url
          )
        }
      )
    end

    def member(enrollment, expander)
      {
        status: 'Active',
        name: (enrollment.user.name if page[:tool].include_name?),
        picture: (enrollment.user.avatar_url if page[:tool].public?),
        given_name: (enrollment.user.first_name if page[:tool].include_name?),
        family_name: (enrollment.user.last_name if page[:tool].include_name?),
        email: (enrollment.user.email if page[:tool].include_email?),
        lis_person_sourcedid: (member_sourced_id(expander) if page[:tool].include_name?),
        user_id: lti_id(enrollment.user),
        roles: enrollment.lti_roles
      }.compact
    end

    def member_sourced_id(expander)
      expanded = expander.expand_variables!({value: '$Person.sourcedId'})[:value]
      expanded == '$Person.sourcedId' ? nil : expanded
    end

    def message(enrollment, expander)
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
          expander: expander,
          return_url: nil,
          opts: {
            # See #variable_expander for additional constraints on custom param expansion
            claim_group_whitelist: [ :public, :i18n, :custom_params ],
            extension_whitelist: [ :canvas_user_id, :canvas_user_login_id ]
          }
        ).generate_post_payload_message
      ensure
        I18n.locale = orig_locale
        Time.zone = orig_time_zone
      end

      # A few straggler fields we can't readily control via white/blacklists
      launch_hash = launch.to_h.
        except!("#{LtiAdvantage::Serializers::JwtMessageSerializer::IMS_CLAIM_PREFIX}version").
        except!("picture")
      { message: [ launch_hash ] }
    end

    def lti_id(entity)
      Lti::Asset.opaque_identifier_for(unwrap(entity))
    end

    def unwrap(wrapped)
      Lti::Ims::Providers::MembershipsProvider.unwrap(wrapped)
    end

    attr_reader :page
  end
end
