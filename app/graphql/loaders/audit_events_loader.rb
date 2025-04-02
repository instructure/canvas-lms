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
#
#
class Loaders::AuditEventsLoader < GraphQL::Batch::Loader
  def perform(submission_ids)
    ids = Submission.where(id: submission_ids)
                    .pluck(:assignment_id, :id)
                    .map { |assignment_id, submission_id| { assignment_id:, submission_id: } }

    assignment_id_to_submission_id_map = ids.group_by { |id_pair| id_pair[:assignment_id] }
                                            .transform_values { |pairs| pairs.map { |pair| pair[:submission_id] } }

    audit_events = AnonymousOrModerationEvent.events_for_submissions(ids)

    data = Hash.new { |hash, key| hash[key] = [] }
    audit_events.each do |it|
      submission_id = it[:submission_id]
      assignment_id = it[:assignment_id]

      if submission_id.nil?
        # If submission_id is nil, add the event to all submission_ids for the matching assignment_id
        submission_ids_for_assignment = assignment_id_to_submission_id_map[assignment_id] || []
        submission_ids_for_assignment.each do |sub_id|
          data[sub_id] << it
        end
      else
        # Otherwise, add the event to the specific submission_id
        data[submission_id] << it
      end
    end

    submission_ids.each do |submission_id|
      fulfill(submission_id, data.fetch(submission_id, []))
    end
  end
end
