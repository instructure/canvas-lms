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

# @API Assignments
#
# API for accessing assignment information.
class AssignmentsApiController < ApplicationController
  before_filter :require_context

  include Api::V1::Assignment

  # @API List assignments
  # Returns the list of assignments for the current context.
  #
  # @response_field id The unique identifier for the assignment.
  # @response_field assignment_group_id The unique identifier of the assignment's group.
  # @response_field name The name of the assignment.
  # @response_field needs_grading_count [Integer] If the requesting user has grading rights, the number of submissions that need grading.
  # @response_field position [Integer] The sorting order of this assignment in
  #   the group.
  # @response_field points_possible The maximum possible points for the
  #   assignment.
  # @response_field grading_type [Optional, "pass_fail"|"percent"|"letter_grade"|"points"]
  #   The type of grade the assignment receives.
  # @response_field use_rubric_for_grading [Boolean] If true, the rubric is
  #   directly tied to grading the assignment. Otherwise, it is only advisory.
  # @response_field rubric [Rubric]
  #   A list of rows and ratings for each row. TODO: need more discussion of the
  #   rubric data format and usage for grading.
  # @response_field rubric_settings
  #   An object describing the basic attributes of the rubric, including the point total.
  # @response_field group_category_id [Integer] The unique identifier of the assignment's group set (if this is a group assignment)
  # @response_field html_url The URL to the Canvas web UI page for the assignment.
  #
  # @example_response
  #   [
  #     {
  #       "id": 4,
  #       "assignment_group_id": 2,
  #       "name": "some assignment",
  #       "points_possible": 12,
  #       "grading_type": "points",
  #       "due_at": "2011-05-26T23:59:00-06:00",
  #       "submission_types" : [
  #         "online_upload",
  #         "online_text_entry",
  #         "online_url",
  #         "media_recording"
  #        ],
  #       "use_rubric_for_grading": true,
  #       "html_url": "https://...",
  #       "rubric_settings": {
  #         "points_possible": 12
  #       }
  #       "rubric": [
  #         {
  #           "ratings": [
  #             {
  #               "points": 10,
  #               "id": "rat1",
  #               "description": "A"
  #             },
  #             {
  #               "points": 7,
  #               "id": "rat2",
  #               "description": "B"
  #             },
  #             {
  #               "points": 0,
  #               "id": "rat3",
  #               "description": "F"
  #             }
  #           ],
  #           "points": 10,
  #           "id": "crit1",
  #           "description": "Crit1"
  #         },
  #         {
  #           "ratings": [
  #             {
  #               "points": 2,
  #               "id": "rat1",
  #               "description": "Pass"
  #             },
  #             {
  #               "points": 0,
  #               "id": "rat2",
  #               "description": "Fail"
  #             }
  #           ],
  #           "points": 2,
  #           "id": "crit2",
  #           "description": "Crit2"
  #         }
  #       ],
  #       "group_category_id: 1
  #     }
  #   ]
  def index
    if authorized_action(@context, @current_user, :read)
      @assignments = @context.active_assignments.find(:all,
          :include => [:assignment_group, :rubric_association, :rubric],
          :order => 'assignment_groups.position, assignments.position')

      hashes = @assignments.map { |assignment|
        assignment_json(assignment, @current_user, session) }

      render :json => hashes.to_json
    end
  end

  def show
    if authorized_action(@context, @current_user, :read)
      @assignment = @context.active_assignments.find(params[:id],
          :include => [:assignment_group, :rubric_association, :rubric])

      render :json => assignment_json(@assignment, @current_user, session).to_json
    end
  end

  # @API Create an assignment
  # Create a new assignment for this course. The assignment is created in the
  # active state.
  #
  # @argument assignment[name] The assignment name.
  # @argument assignment[position] [Integer] The position of this assignment in the
  #   group when displaying assignment lists.
  # @argument assignment[points_possible] [Float] The maximum points possible on
  #   the assignment.
  # @argument assignment[grading_type] [Optional, "pass_fail"|"percent"|"letter_grade"|"points"] The strategy used for grading the assignment. The assignment is ungraded if this field is omitted.
  # @argument assignment[due_at] [Timestamp] The day/time the assignment is due. Accepts
  #   times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  # @argument assignment[description] [String] The assignment's description, supports HTML.
  def create
    @assignment = create_api_assignment(@context, params[:assignment])

    if authorized_action(@assignment, @current_user, :create)
      if @assignment.save
        render :json => assignment_json(@assignment, @current_user, session).to_json, :status => 201
      else
        # TODO: we don't really have a strategy in the API yet for returning
        # errors.
        render :json => 'error'.to_json, :status => 400
      end
    end
  end

  # @API Edit an assignment
  # Modify an existing assignment. See the documentation for assignment
  # creation.
  def update
    @assignment = @context.assignments.find(params[:id])

    if authorized_action(@assignment, @current_user, :update_content)
      if @assignment.frozen?
        render :json => {:message => t('errors.no_edit_frozen', "You cannot edit a frozen assignment.")}.to_json, :status => 400
      else
        update_api_assignment(@assignment, params[:assignment])

        if @assignment.save
          render :json => assignment_json(@assignment, @current_user, session).to_json, :status => 201
        else
          # TODO: we don't really have a strategy in the API yet for returning
          # errors.
          render :json => 'error'.to_json, :status => 400
        end
      end
    end
  end

end
