#
# Copyright (C) 2017 - present Instructure, Inc.
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


module PlannerHelper
  PLANNABLE_TYPES = {
    'discussion_topic' => 'DiscussionTopic',
    'announcement' => 'DiscussionTopic',
    'quiz' => 'Quizzes::Quiz',
    'assignment' => 'Assignment',
    'wiki_page' => 'WikiPage',
    'planner_note' => 'PlannerNote',
    'calendar_event' => 'CalendarEvent'
  }.freeze

  def planner_meta_cache_key
    ['planner_items_meta', @current_user].cache_key
  end

  def formatted_planner_date(input, val, default = nil, end_of_day: false)
    @errors ||= {}
    if val.present? && val.is_a?(String)
      if val =~ Api::DATE_REGEX
        if end_of_day
          Time.zone.parse(val).end_of_day
        else
          Time.zone.parse(val).beginning_of_day
        end
      elsif val =~ Api::ISO8601_REGEX
        Time.zone.parse(val)
      else
        @errors[input] = t('Invalid date or invalid datetime for %{attr}', attr: input)
      end
    else
      default
    end
  end

  def ensure_valid_planner_params
    if @errors.empty?
      true
    else
      render json: {errors: @errors.as_json}, status: :bad_request
      false
    end
  end
end
