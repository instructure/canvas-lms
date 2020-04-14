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
  def find_or_initialize_conference(context, conference_params)
    return nil if conference_params.blank?
    valid_params = conference_params.slice(:title, :description, :conference_type, :lti_settings)

    if conference_params[:id]
      WebConference.find(conference_params[:id]).tap do |conf|
        conf.context = context
        conf.assign_attributes(valid_params)
      end
    elsif conference_params[:title].present?
      context.web_conferences.build(valid_params.merge(user: @current_user))
    end
  end

  def authorize_user_for_conference(user, conference)
    return true if conference.nil?
    if conference.new_record?
      authorized_action(conference, user, :create)
    elsif conference.changed?
      authorized_action(conference, user, :update)
    else
      true
    end
  end

  def add_conference_types_to_js_env(contexts)
    type_to_contexts_map = {}
    conference_types = contexts.flat_map do |context|
      WebConference.conference_types(context).map do |type|
        type_to_contexts_map[type] ||= []
        type_to_contexts_map[type] << context
        type
      end
    end.uniq
    # add contexts at end to preserve object comparison above
    conference_types.each {|t| t['contexts'] = type_to_contexts_map[t]}

    js_env(
      conferences: {
        conference_types: conference_types_json(conference_types),
        root_context: @domain_root_account.asset_string
      }
    )
  end
end
