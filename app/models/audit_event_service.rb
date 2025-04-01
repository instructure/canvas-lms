# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AuditEventService
  def initialize(submission)
    @submission = submission
  end

  def call
    AnonymousOrModerationEvent.events_for_submission(
      assignment_id: @submission.assignment.id,
      submission_id: @submission.id
    )
  end

  # Returns enriched version of the audit events for aggregated API response (used by SG1)
  def enrich(audit_events)
    user_data = User.find(audit_events.pluck(:user_id).compact)
    tool_data = Lti::ToolFinder.find(audit_events.pluck(:context_external_tool_id).compact)
    quiz_data = Quizzes::Quiz.find(audit_events.pluck(:quiz_id).compact)

    {
      audit_events: audit_events.as_json(include_root: false),
      users: audit_event_data(data: user_data),
      tools: audit_event_data(data: tool_data, role: "grader"),
      quizzes: audit_event_data(data: quiz_data, role: "grader", name_field: :title),
    }
  end

  private

  def audit_event_data(data:, role: nil, name_field: :name)
    data.map do |it|
      {
        id: it.id,
        name: it.public_send(name_field),
        role: role.presence || AnonymousOrModerationEvent.auditing_user_role(
          user: it, submission: @submission, assignment: @submission.assignment
        ),
      }
    end
  end
end
