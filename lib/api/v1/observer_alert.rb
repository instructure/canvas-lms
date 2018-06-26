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
#

module Api::V1::ObserverAlert
  include Api::V1::Json
  include ApplicationHelper

  API_ALLOWED_OUTPUT_FIELDS = {
    :only => %w(
      id
      title
      user_id
      observer_id
      observer_alert_threshold_id
      alert_type
      context_type
      context_id
      workflow_state
      action_date
    ).freeze
  }.freeze

  def observer_alert_json(alert, user, session, _opts = {})
    hash = api_json(alert, user, session, API_ALLOWED_OUTPUT_FIELDS)

    url = case alert.context_type
          when 'DiscussionTopic'
            course_discussion_topic_url(alert.context.context_id, alert.context)
          when 'Assignment'
            course_assignment_url(alert.context.context_id, alert.context)
          when 'Course'
            course_url(alert.context)
          when 'Submission'
            assignment = alert.context.assignment
            course_assignment_url(assignment.context_id, assignment)
          end

    hash['html_url'] = url
    hash
  end
end
