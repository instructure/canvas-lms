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

module Lti::IMS
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
        id: Lti::Asset.opaque_identifier_for(unwrap(page[:context])),
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
      expander = variable_expander(enrollment)
      member(enrollment, expander).merge!(message(enrollment, expander))
    end

    def variable_expander(enrollment)
      # the variables substitution in the whitelist have the following guards:
      # - @current_user
      # - @context.is_a?(Course)
      # - @tool

      Lti::VariableExpander.new(
        page[:context].root_account,
        Lti::IMS::Providers::MembershipsProvider.unwrap(page[:context]),
        page[:controller],
        {
          current_user: Lti::IMS::Providers::MembershipsProvider.unwrap(enrollment.user),
          tool: page[:tool],
          enrollment:,
          variable_whitelist: %w[
            Caliper.url
            Canvas.course.endAt
            Canvas.course.gradePassbackSetting
            Canvas.course.hideDistributionGraphs
            Canvas.course.id
            Canvas.course.name
            Canvas.course.previousContextIds
            Canvas.course.previousContextIds.recursive
            Canvas.course.previousCourseIds
            Canvas.course.sectionIds
            Canvas.course.sectionRestricted
            Canvas.course.sectionSisSourceIds
            Canvas.course.sisSourceId
            Canvas.course.startAt
            Canvas.course.workflowState
            Canvas.group.contextIds
            Canvas.user.globalId
            Canvas.user.id
            Canvas.user.loginId
            Canvas.user.sisIntegrationId
            Canvas.user.sisSourceId
            Canvas.xapi.url
            Message.locale
            Person.address.timezone
            Person.email.primary
            Person.name.display
            Person.name.family
            Person.name.full
            Person.name.given
            Person.sourcedId
            User.id
            User.image
            User.username
            com.instructure.User.sectionNames
            vnd.Canvas.Person.email.sis
            vnd.instructure.User.uuid
          ]
        }
      )
    end

    def member(enrollment, expander)
      user = enrollment.user
      {
        status: "Active",
        name: (user.name if page[:tool].include_name?),
        picture: (user.avatar_url if page[:tool].public?),
        given_name: (user.first_name if page[:tool].include_name?),
        family_name: (user.last_name if page[:tool].include_name?),
        email: (user.email if page[:tool].include_email?),
        lis_person_sourcedid: (member_sourced_id(expander) if page[:tool].include_name?),
        user_id: user.past_lti_ids.first&.user_lti_id || user.lti_id,
        lti11_legacy_user_id: Lti::Asset.opaque_identifier_for(user),
        roles: enrollment.lti_roles
      }.compact
    end

    def member_sourced_id(expander)
      expanded = expander.expand_variables!({ value: "$Person.sourcedId" })[:value]
      (expanded == "$Person.sourcedId") ? nil : expanded
    end

    def message(enrollment, expander)
      return {} if page[:opts].blank? || page[:opts][:rlid].blank?

      orig_time_zone = Time.zone
      begin
        launch = I18n.with_locale(enrollment.user.locale) do
          Time.zone = enrollment.user.time_zone || orig_time_zone
          Lti::Messages::ResourceLinkRequest.new(
            tool: page[:tool],
            context: unwrap(page[:context]),
            user: enrollment.user,
            expander:,
            return_url: nil,
            opts: {
              # See #variable_expander for additional constraints on custom param expansion
              claim_group_whitelist: %i[public i18n custom_params],
              extension_whitelist: [:canvas_user_id, :canvas_user_login_id],
              resource_link: page[:opts][:rlid].present? ? Lti::ResourceLink.find_by(resource_link_uuid: page[:opts][:rlid]) : nil
            }
          ).generate_post_payload_message(validate_launch: false)
        end
      ensure
        Time.zone = orig_time_zone
      end

      # A few straggler fields we can't readily control via white/blacklists
      launch_hash = launch.to_h
                          .except!("#{LtiAdvantage::Serializers::JwtMessageSerializer::IMS_CLAIM_PREFIX}version")
                          .except!("picture")
      { message: [launch_hash] }
    end

    def unwrap(wrapped)
      Lti::IMS::Providers::MembershipsProvider.unwrap(wrapped)
    end

    attr_reader :page
  end
end
