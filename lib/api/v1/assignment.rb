#
# Copyright (C) 2011 Instructure, Inc.
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

module Api::V1::Assignment
  include Api::V1::Json
  include Api::V1::DiscussionTopics

  def assignment_json(assignment, user, session, includes = [], show_admin_fields = false)
    # no includes supported right now
    hash = api_json(assignment, user, session, :only => %w(id grading_type points_possible position due_at description assignment_group_id group_category_id))

    hash['course_id'] = assignment.context_id
    hash['name'] = assignment.title
    hash['description'] = api_user_content(hash['description'], @context || assignment.context)
    hash['html_url'] = course_assignment_url(assignment.context_id, assignment)

    if show_admin_fields
      hash['needs_grading_count'] = assignment.needs_grading_count
    end

    hash['submission_types'] = assignment.submission_types.split(',')

    if assignment.quiz
      hash['anonymous_submissions'] = !!(assignment.quiz.anonymous_submissions)
    end

    hash['muted'] = assignment.muted?

    if assignment.allowed_extensions.present?
      hash['allowed_extensions'] = assignment.allowed_extensions
    end

    if assignment.rubric_association
      hash['use_rubric_for_grading'] =
        !!assignment.rubric_association.use_for_grading
      if assignment.rubric_association.rubric
        hash['free_form_criterion_comments'] =
          !!assignment.rubric_association.rubric.free_form_criterion_comments
      end
    end

    if assignment.rubric
      rubric = assignment.rubric
      hash['rubric'] = rubric.data.map do |row|
        row_hash = row.slice(:id, :points, :description, :long_description)
        row_hash["ratings"] = row[:ratings].map { |c| c.slice(:id, :points, :description) }
        row_hash
      end
      hash['rubric_settings'] = {
        'points_possible' => rubric.points_possible,
        'free_form_criterion_comments' => !!rubric.free_form_criterion_comments,
      }
    end

    if assignment.discussion_topic
      hash['discussion_topic'] = discussion_topic_api_json(assignment.discussion_topic, assignment.discussion_topic.context, user, session)
    end

    hash
  end

  API_ALLOWED_ASSIGNMENT_FIELDS = %w(name position points_possible grading_type due_at description)

  def create_api_assignment(context, assignment_params)
    assignment = context.assignments.build
    update_api_assignment(assignment, assignment_params)
  end

  def update_api_assignment(assignment, assignment_params)
    return nil unless assignment_params.is_a?(Hash)
    update_params = assignment_params.slice(*API_ALLOWED_ASSIGNMENT_FIELDS)
    update_params["time_zone_edited"] = Time.zone.name if update_params["due_at"]

    assignment.update_attributes(update_params)
    assignment.infer_due_at
    # TODO: allow rubric creation

    if custom_vals = assignment_params[:set_custom_field_values]
      assignment.set_custom_field_values = custom_vals
    end
    return assignment
  end
end
