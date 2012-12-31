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
  include ApplicationHelper

  API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS = {
    :only => %w(
      id
      position
      points_possible
      grading_type
      due_at
      description
      lock_at
      unlock_at
      assignment_group_id
      peer_reviews
      automatic_peer_reviews
      external_tool_tag_attributes
      grade_group_students_individually
      group_category_id
    )
  }

  def assignment_json(assignment, user, session,include_discussion_topic = true)
    hash = api_json(assignment, user, session, API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS)
    hash['course_id'] = assignment.context_id
    hash['name'] = assignment.title
    hash['description'] = api_user_content(hash['description'], @context || assignment.context)
    hash['html_url'] = course_assignment_url(assignment.context_id, assignment)
    hash['muted'] = assignment.muted?
    hash['submission_types'] = assignment.submission_types_array

    if hash['lock_info']
      hash['lock_explanation'] = lock_explanation(hash['lock_info'], 'assignment', assignment.context)
    end

    if assignment.grants_right?(user, :grade)
      hash['needs_grading_count'] = assignment.needs_grading_count_for_user user
    end

    if assignment.quiz
      hash['anonymous_submissions'] = !!(assignment.quiz.anonymous_submissions)
    end

    if assignment.allowed_extensions.present?
      hash['allowed_extensions'] = assignment.allowed_extensions
    end

    if PluginSetting.settings_for_plugin(:assignment_freezer)
      hash['frozen'] = assignment.frozen?
      hash['frozen_attributes'] = assignment.frozen_attributes_for_user @current_user
    end

    if assignment.context && assignment.context.turnitin_enabled?
      hash['turnitin_enabled'] = assignment.turnitin_enabled
    end

    if assignment.rubric_association
      hash['use_rubric_for_grading'] = !!assignment.rubric_association.use_for_grading
      if assignment.rubric_association.rubric
        hash['free_form_criterion_comments'] = !!assignment.rubric_association.rubric.free_form_criterion_comments
      end
    end

    if assignment.rubric
      rubric = assignment.rubric
      hash['rubric'] = rubric.data.map do |row|
        row_hash = row.slice(:id, :points, :description, :long_description)
        row_hash["ratings"] = row[:ratings].map do |c|
          c.slice(:id, :points, :description)
        end
        row_hash
      end
      hash['rubric_settings'] = {
        'points_possible' => rubric.points_possible,
        'free_form_criterion_comments' => !!rubric.free_form_criterion_comments
      }
    end

    if include_discussion_topic && assignment.discussion_topic
      extend Api::V1::DiscussionTopics
      hash['discussion_topic'] = discussion_topic_api_json(
        assignment.discussion_topic,
        assignment.discussion_topic.context,
        user,
        session,
        !:include_assignment)
    end

    hash
  end

  API_ALLOWED_ASSIGNMENT_INPUT_FIELDS = %w(
    name
    description
    position
    points_possible
    grading_type
    submission_types
    allowed_extensions
    due_at
    lock_at
    unlock_at
    assignment_group_id
    group_category_id
    peer_reviews
    automatic_peer_reviews
    external_tool_tag_attributes
    grade_group_students_individually
    set_custom_field_values
    turnitin_enabled
  )

  def update_api_assignment(assignment, assignment_params, save = true)
    return nil unless assignment_params.is_a?(Hash)
    update_params = assignment_params.slice(*API_ALLOWED_ASSIGNMENT_INPUT_FIELDS)

    if update_params["submission_types"].is_a? Array
      update_params["submission_types"] = update_params["submission_types"].join(',')
    end

    if assignment_params.has_key?("assignment_group_id")
      ag_id = assignment_params["assignment_group_id"]
      if ag_id.nil? || ag_id.is_a?( Numeric )
        assignment.assignment_group = assignment.context.assignment_groups.find_by_id(ag_id)
      end
    end

    if assignment_params.has_key?("group_category_id")
      gc_id = assignment_params["group_category_id"]
      if gc_id.nil? || gc_id.is_a?( Numeric )
        assignment.group_category = assignment.context.group_categories.find_by_id(gc_id)
      end
    end

    if update_params.has_key?("due_at")
      update_params["time_zone_edited"] = Time.zone.name
      # do some fiddling with due_at for fancy midnight
      assignment.due_at = update_params["due_at"]
    end

    # TODO: allow rubric creation

    assignment.updating_user = @current_user
    if save
      assignment.update_attributes(update_params)
    else
      assignment.attributes = update_params
    end
    assignment.infer_due_at

    return assignment
  end
end
