# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Api::V1::ContentExport
  include Api::V1::User
  include Api::V1::Attachment
  include Api::V1::Quiz
  include Api::V1::Assignment
  include Api::V1::QuizzesNext::Quiz

  def content_export_json(export, current_user, session, includes = [])
    json = api_json(export, current_user, session, only: %w[id user_id created_at workflow_state export_type])
    json["course_id"] = export.context_id if export.context_type == "Course"

    if export.attachment && !export.for_course_copy? && !export.expired?
      json[:attachment] = attachment_json(export.attachment, current_user, {}, { can_view_hidden_files: true })
    end

    if export.job_progress
      json["progress_url"] = polymorphic_url([:api_v1, export.job_progress])
    end

    export_quizzes_next(export, current_user, session, includes, json) if request_quiz_json?(includes)
    include_new_quizzes_export_settings(export, json) if request_new_quizzes_export_settings?(includes)

    json
  end

  private

  def request_quiz_json?(includes)
    includes.include?("migrated_quiz") || includes.include?("migrated_assignment")
  end

  def request_new_quizzes_export_settings?(includes)
    includes.include?("new_quizzes_export_settings")
  end

  def export_quizzes_next(export, current_user, session, includes, json)
    return unless export.new_quizzes_page_enabled?

    assignment_id = export.settings.dig(:quizzes2, :assignment, :assignment_id)
    assignment = Assignment.find_by(id: assignment_id)
    return if assignment.blank?

    if includes.include?("migrated_quiz")
      json["migrated_quiz"] = quizzes_next_json([assignment], export.context, current_user, session)
    elsif includes.include?("migrated_assignment")
      json_assignment = assignment_json(assignment, current_user, session)
      json_assignment["new_positions"] = assignment_positions(assignment)
      json["migrated_assignment"] = [json_assignment]
    end
  end

  def include_new_quizzes_export_settings(export, json)
    json["new_quizzes_export_url"] = export.settings&.dig("new_quizzes_export_url")
    json["new_quizzes_export_state"] = export.settings&.dig("new_quizzes_export_state")
  end

  def assignment_positions(assignment)
    positions_in_group = Assignment.active.where(
      assignment_group_id: assignment.assignment_group_id
    ).pluck("id", "position")
    positions_hash = {}
    positions_in_group.each do |id_pos_pair|
      positions_hash[id_pos_pair[0]] = id_pos_pair[1]
    end
    positions_hash
  end
end
