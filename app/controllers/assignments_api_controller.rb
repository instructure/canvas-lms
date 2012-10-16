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
#
# @object Assignment
#     {
#       // the ID of the assignment
#       id: 4,
#
#       // the name of the assignment
#       name: "some assignment",
#
#       // the assignment description, in an HTML fragment
#       description: '<p>Do the following:</p>...',
#
#       // the due date
#       due_at: '2012-07-01T23:59:00-06:00',
#
#       // the ID of the course the assignment belongs to
#       course_id: 123,
#
#       // the URL to the assignment's web page
#       html_url: 'http://canvas.example.com/courses/123/assignments/4'
#
#       // the ID of the assignment's group
#       assignment_group_id: 2,
#
#       // the ID of the assignment’s group set (if this is a group assignment)
#       group_category_id: 1
#
#       // if the requesting user has grading rights, the number of submissions that need grading.
#       needs_grading_count: 17,
#
#       // the sorting order of the assignment in the group
#       position: 1,
#
#       // the URL to the Canvas web UI page for the assignment
#       html_url: "https://...",
#
#       // whether the assignment is muted
#       muted: false,
#
#       // (Optional) explanation of lock status
#       lock_explanation: "This assignment is locked until September 1 at 12:00am",
#
#       // (Optional) whether anonymous submissions are accepted (applies only to quiz assignments)
#       anonymous_submissions: false,
#
#       // (Optional) list of file extensions allowed for submissions
#       allowed_extensions: ["doc","xls"],
#
#       // (Optional) the DiscussionTopic associated with the assignment, if applicable
#       discussion_topic: { ... },
#
#       // the maximum points possible for the assignment
#       points_possible: 12,
#
#       // the types of submissions allowed for this assignment
#       // list containing one or more of the following:
#       // "online_text_entry", "online_url", "online_upload", "media_recording"
#       submission_types: ["online_text_entry"]
#
#       // (Optional) the type of grading the assignment receives;
#       // one of 'pass_fail', 'percent', 'letter_grade', 'points'
#       grading_type: "points",
#
#       // if true, the rubric is directly tied to grading the assignment.
#       // Otherwise, it is only advisory.
#       use_rubric_for_grading: true,
#
#       // an object describing the basic attributes of the rubric, including the point total
#       rubric_settings: {
#         points_possible: 12
#       },
#
#       // a list of scoring criteria and ratings for each 
#       rubric: [
#         {
#           "points": 10,
#           "id": "crit1",
#           "description": "Criterion 1",
#           "ratings": [
#             {
#               "points": 10,
#               "id": "rat1",
#               "description": "Full marks"
#             },
#             {
#               "points": 7,
#               "id": "rat2",
#               "description": "Partial answer"
#             },
#             {
#               "points": 0,
#               "id": "rat3",
#               "description": "No marks"
#             }
#           ]
#         },
#         {
#           "points": 2,
#           "id": "crit2",
#           "description": "Criterion 2",
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
#           ]
#         }
#       ]
#     }
#
class AssignmentsApiController < ApplicationController
  before_filter :require_context

  include Api::V1::Assignment

  # @API List assignments
  # Returns the list of assignments for the current context.
  # @returns [Assignment]
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

  # @API Get a single assignment 
  # Returns the assignment with the given id.
  # @returns Assignment
  def show
    if authorized_action(@context, @current_user, :read)
      @assignment = @context.active_assignments.find(params[:id],
          :include => [:assignment_group, :rubric_association, :rubric])

      @assignment.context_module_action(@current_user, :read) unless @assignment.locked_for?(@current_user, :check_policies => true)
      render :json => assignment_json(@assignment, @current_user, session)
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
  # @argument assignment[assignment_group_id] [Integer] The assignment group id to put the assignment in. Defaults to the top assignment group in the course.
  # @returns Assignment
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
  # @returns Assignment
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
