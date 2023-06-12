# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module CalendarConferencesHelper
  include Api::V1::Conferences

  def find_and_update_or_initialize_calendar_event(context, calendar_event_params, override_params = {})
    return nil if calendar_event_params.blank?

    return nil unless calendar_event_params.respond_to?(:merge)

    valid_params = calendar_event_params.merge(override_params).slice(:web_conference, :title, :context_code, :start_at, :end_at, :description)
    if calendar_event_params[:web_conference].calendar_event
      CalendarEvent.find(calendar_event_params[:web_conference].calendar_event.id).tap do |event|
        if event.grants_right?(@current_user, session, :update)
          event.context = context
          event.assign_attributes(valid_params)
        end
      end
    elsif calendar_event_params[:title].present?
      context.calendar_events.build(valid_params)
    end
  end

  def find_or_initialize_conference(context, conference_params, override_params = {})
    return nil if conference_params.blank?

    return nil unless conference_params.respond_to?(:merge)

    valid_params = conference_params.merge(override_params).slice(:title, :description, :conference_type, :lti_settings, :user_settings, :start_at, :end_at)

    if conference_params[:id]
      WebConference.find(conference_params[:id]).tap do |conf|
        if conf.grants_right?(@current_user, session, :update)
          conf.context = context
          conf.assign_attributes(valid_params)
        end
      end
    else
      context.web_conferences.build(valid_params).tap do |conf|
        conf.user = @current_user
        conf.settings[:default_return_url] = named_context_url(context, :context_url, include_host: true)
      end
    end
  end

  def authorize_user_for_conference(user, conference)
    return true if conference.nil?

    if conference.new_record?
      authorized_action(conference, user, :create)
    elsif conference.changed?
      authorized_action(conference, user, :update)
    else
      authorized_action(conference, user, :read)
    end
  end

  def add_conference_types_to_js_env(contexts)
    allowed_contexts = contexts.select { |c| c.grants_right?(@current_user, session, :create_conferences) }

    type_to_contexts_map = {}
    conference_types = allowed_contexts.flat_map do |context|
      WebConference.conference_types(context).map do |type|
        type_to_contexts_map[type] ||= []
        type_to_contexts_map[type] << context
        type
      end
    end.uniq
    # add contexts at end to preserve object comparison above
    conference_types.each { |t| t["contexts"] = type_to_contexts_map[t] }

    js_env(
      conferences: {
        conference_types: conference_types_json(conference_types)
      }
    )
  end
end
