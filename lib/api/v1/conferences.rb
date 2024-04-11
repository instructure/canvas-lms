# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api::V1::Conferences
  API_CONFERENCE_JSON_OPTS = {
    only: %w[
      id
      title
      conference_type
      description
      duration
      ended_at
      started_at
      user_ids
      join_url
      conference_key
      context_type
      context_id
      start_at
      end_at
    ].freeze
  }.freeze

  def api_conferences_json(conferences, user, session)
    json = conferences.map { |c| api_conference_json(c, user, session) }
    { "conferences" => json }
  end

  def api_conference_json(conference, user, session)
    api_json(conference, user, session, API_CONFERENCE_JSON_OPTS).tap do |j|
      j["lti_settings"] = conference.lti_settings if Account.site_admin.feature_enabled?(:conference_selection_lti_placement)
      j["has_advanced_settings"] = value_to_boolean(j["has_advanced_settings"])
      j["long_running"] = value_to_boolean(j["long_running"])
      j["duration"] = j["duration"].to_i if j["duration"]
      j["users"] = Array(j.delete("user_ids"))
      j["invitees"] = Array(j.delete("invitees_ids"))
      j["attendees"] = Array(j.delete("attendees_ids"))
      j["url"] = named_context_url(conference.context, :context_conference_url, conference)
    end
  end

  def ui_conferences_json(conferences, context, user, session)
    cs = conferences.map do |c|
      c.as_json(
        permissions: {
          user:,
          session:,
        },
        url: named_context_url(context, :context_conference_url, c)
      )
    rescue => e
      Canvas::Errors.capture_exception(:web_conferences, e)
      @errors ||= []
      @errors << e
      nil
    end
    cs.compact
  end

  def default_conference_json(context, user, session)
    conference = context.web_conferences.build(
      title: I18n.t(:default_conference_title, "%{course_name} Conference", course_name: context.name),
      duration: WebConference::DEFAULT_DURATION
    )

    conference.as_json(
      permissions: {
        user:,
        session:,
      },
      url: named_context_url(context, :context_conferences_url)
    )
  end

  def conference_types_json(conference_types)
    conference_types.map do |conference_type|
      {
        name: conference_type[:name],
        type: conference_type[:conference_type],
        settings: conference_user_setting_fields_json(conference_type[:user_setting_fields]),
        free_trial: !!conference_type[:free_trial],
        send_avatar: !!conference_type[:send_avatar],
        lti_settings: conference_type[:lti_settings].as_json,
        contexts: conference_type[:contexts]&.map(&:asset_string)
      }
    end
  end

  def conference_user_setting_fields_json(user_setting_fields)
    user_setting_fields.inject([]) do |a, (field_name, field_options)|
      visible_field = field_options.delete(:visible)
      visible_field = visible_field.call if visible_field.respond_to?(:call)
      next a unless visible_field

      resolved_field_options = translate_strings(field_options)
      resolved_field_options[:field] = field_name
      a << resolved_field_options
    end
  end

  def translate_strings(object)
    object.transform_values do |v|
      if v.is_a? Array
        v.map { |a| translate_strings(a) }
      else
        v.respond_to?(:call) ? v.call : v
      end
    end
  end

  def signed_id_invalid_json
    { status: I18n.t(:unprocessable_entity, "unprocessable entity"),
      errors: [{ message: I18n.t(:unprocessable_entity_message, "Signed meeting id invalid") }] }.to_json
  end

  def invalid_jwt_token_json
    { status: I18n.t(:unauthorized, "unauthorized"),
      errors: [{ message: I18n.t(:unauthorized_message, "JWT signature invalid") }] }.to_json
  end
end
