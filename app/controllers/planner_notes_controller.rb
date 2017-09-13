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

# @API Planner Note
#
# API for creating, accessing and updating Planner Notes. PlannerNote are used
# to set reminders and notes to self about courses or general events.
#
# @model PlannerNote
#     {
#       "id": "PlannerNote",
#       "description": "A planner note",
#       "properties": {
#         "id": {
#           "description": "The ID of the planner note",
#           "example": 234,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title for a planner note",
#           "example": "Bring books tomorrow",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description of the planner note",
#           "example": "I need to bring books tomorrow for my course on biology",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "The id of the associated user creating the planner note",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current published state of the planner note",
#           "example": "active",
#           "type": "string"
#         },
#         "course_id": {
#           "description": "The course that the note is in relation too, if applicable",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "todo_date": {
#           "description": "The datetime of when the planner note should show up on their planner",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         }
#       }
#     }
#

class PlannerNotesController < ApplicationController
  include Api::V1::PlannerNote

  before_action :require_user

  # @API List planner notes
  #
  # Retrieve the paginated list of planner notes
  #
  # @example_response
  #   [
  #     {
  #       'id': 4,
  #       'title': 'Bring bio book',
  #       'description': 'bring bio book for friend tomorrow',
  #       'user_id': 1238,
  #       'course_id': 4567,  // If the user assigns a note to a course
  #       'todo_date': "2017-05-09T10:12:00Z",
  #       'workflow_state': "active",
  #     },
  #     {
  #       'id': 5,
  #       'title': 'Bring english book',
  #       'description': 'bring english book to class tomorrow',
  #       'user_id': 1234,
  #       'todo_date': "2017-05-09T10:12:00Z",
  #       'workflow_state': "active",
  #     },
  #   ]
  #
  # @API List planner notes
  #
  # Retrieve planner note for a user
  #
  # @returns [PlannerNote]
  def index
    notes = PlannerNote.where(user: @current_user).active
    render :json => planner_notes_json(notes, @current_user, session)
  end

  # @API Show a PlannerNote
  #
  # Retrieve a planner note for the current user
  #
  # @returns PlannerNote
  def show
    note = @current_user.planner_notes.find(params[:id])
    render json: planner_note_json(note, @current_user, session)
  end

  # @API Update a PlannerNote
  #
  # Update a planner note for the current user
  #
  # @returns PlannerNote
  def update
    update_params = params.permit(:title, :details, :course_id, :todo_date)
    note = @current_user.planner_notes.find(params[:id])
    if (course_id = update_params.delete(:course_id))
      course = Course.find(course_id)
      return unless authorized_action(course, @current_user, :read)
      update_params[:course] = course
    end
    if note.update_attributes(update_params)
      render json: planner_note_json(note, @current_user, session), status: :ok
    else
      render json: note.errors, status: :bad_request
    end
  end

  # @API Create a planner note
  #
  # Create a planner note for the current user
  # @example_request
  #
  # @returns PlannerNote
  def create
    create_params = params.permit(:title, :details, :course_id, :todo_date)
    if (course_id = create_params.delete(:course_id))
      course = Course.find(course_id)
      return unless authorized_action(course, @current_user, :read)
      create_params[:course] = course
    end
    note = @current_user.planner_notes.new(create_params)
    if note.save
      render json: planner_note_json(note, @current_user, session), status: :created
    else
      render json: note.errors, status: :bad_request
    end
  end

  # @API Delete a planner note
  #
  # Delete a planner note for the current user
  #
  # @returns PlannerNote
  def destroy
    note = PlannerNote.find(params[:id])

    if note.destroy
      render json: planner_note_json(note, @current_user, session), status: :ok
    else
      render json: note.errors, status: :bad_request
    end
  end

  private

  def require_user
    render_unauthorized_action if !@current_user || !@domain_root_account.feature_enabled?(:student_planner)
  end
end
