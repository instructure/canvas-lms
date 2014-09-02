#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
    :only => %w(id title conference_type description
      duration ended_at started_at user_ids long_running
      recordings join_url has_advanced_settings)
  }

  def api_conferences_json(conferences, user, session)
    json = conferences.map do |c|
      api_json(c, user, session, API_CONFERENCE_JSON_OPTS)
    end
    json.each do |j|
      j['has_advanced_settings'] = value_to_boolean(j['has_advanced_settings'])
      j['long_running'] = value_to_boolean(j['long_running'])
      j['duration'] = j['duration'].to_i if j['duration']
      j['users'] = Array(j.delete('user_ids'))
    end
    {'conferences' => json}
  end

  def ui_conferences_json(conferences, context, user, session)
    conferences.map do |c|
      c.as_json(
        permissions: {
          user: user,
          session: session,
        },
        url: named_context_url(context, :context_conference_url, c)
      )
    end
  end

  def default_conference_json(context, user, sesssion)
    conference = context.web_conferences.build(
      :title => I18n.t(:default_conference_title, "%{course_name} Conference", :course_name => context.name),
      :duration => WebConference::DEFAULT_DURATION,
    )

    conference.as_json(
      permissions: {
        user: user,
        session: session,
        },
      url: named_context_url(context, :context_conferences_url),
    )
  end

  def conference_types_json(conference_types)
    conference_types.map do |conference_type|
      {
        name: conference_type[:plugin].name,
        type: conference_type[:conference_type],
        settings: conference_user_setting_fields_json(conference_type[:user_setting_fields]),
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
    object.each_with_object({}) do |(k, v), h|
      if v.is_a? Array
        h[k] = v.map{|a| translate_strings(a)}
      else
        h[k] = v.respond_to?(:call) ? v.call() : v
      end
    end
  end

end
