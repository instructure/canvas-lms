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

# @API Planner
# @subtopic Planner Notes
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
#         },
#         "linked_object_type": {
#           "description": "the type of the linked learning object",
#           "example": "assignment",
#           "type": "string"
#         },
#         "linked_object_id": {
#           "description": "the id of the linked learning object",
#           "example": 131072,
#           "type": "integer"
#         },
#         "linked_object_html_url": {
#           "description": "the Canvas web URL of the linked learning object",
#           "example": "https://canvas.example.com/courses/1578941/assignments/131072",
#           "type": "string"
#         },
#         "linked_object_url": {
#           "description": "the API URL of the linked learning object",
#           "example": "https://canvas.example.com/api/v1/courses/1578941/assignments/131072",
#           "type": "string"
#         }
#       }
#     }
#

class PlannerNotesController < ApplicationController
  include Api::V1::PlannerNote

  before_action :require_user
  before_action :require_planner_enabled

  # @API List planner notes
  #
  # Retrieve the paginated list of planner notes
  #
  # @argument start_date [DateTime]
  #   Only return notes with todo dates since the start_date (inclusive).
  #   No default. The value should be formatted as: yyyy-mm-dd or
  #   ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  # @argument end_date [DateTime]
  #   Only return notes with todo dates before the end_date (inclusive).
  #   No default. The value should be formatted as: yyyy-mm-dd or
  #   ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #   If end_date and start_date are both specified and equivalent,
  #   then only notes with todo dates on that day are returned.
  # @argument context_codes[] [String]
  #   List of context codes of courses whose notes you want to see.
  #   If not specified, defaults to all contexts that the user belongs to.
  #   The format of this field is the context type, followed by an
  #   underscore, followed by the context id. For example: course_42
  #   Including a code matching the user's own context code (e.g. user_1)
  #   will include notes that are not associated with any particular course.
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
    notes = @current_user.planner_notes.active.exclude_deleted_courses
    # Format & filter our notes by course code if passed

    if (context_codes = params.delete(:context_codes))
      context_codes = Array(context_codes)

      # Append to our notes scope to include the context codes for courses
      course_codes = context_codes.select{|c| c =~ /course_\d+/}
      contexts = Context.from_context_codes(course_codes)
      accessible_courses = contexts.select { |c| c.grants_right?(@current_user, :read) }

      # include course-less events if the current user is passed in as a context
      accessible_courses << nil if context_codes.include?(@current_user.asset_string)

      notes = accessible_courses.any? ? notes.for_course(accessible_courses) : PlannerNote.none
    end

    start_at = formatted_planner_date('start_date', params.delete(:start_date))
    end_at = formatted_planner_date('end_date', params.delete(:end_date), end_of_day: true)
    notes = notes.after(start_at) if start_at
    notes = notes.before(end_at) if end_at

    render :json => planner_notes_json(notes, @current_user, session)
  rescue InvalidDates => e
    render json: {errors: e.message.as_json}, status: :bad_request
  end

  # @API Show a planner note
  #
  # Retrieve a planner note for the current user
  #
  # @returns PlannerNote
  def show
    note = @current_user.planner_notes.find(params[:id])
    render json: planner_note_json(note, @current_user, session)
  end

  # @API Update a planner note
  #
  # Update a planner note for the current user
  # @argument title [Optional, String]
  #   The title of the planner note.
  # @argument details [Optional, String]
  #   Text of the planner note.
  # @argument todo_date [Optional, Date]
  #   The date where this planner note should appear in the planner.
  #   The value should be formatted as: yyyy-mm-dd.
  # @argument course_id [Optional, Integer]
  #   The ID of the course to associate with the planner note. The caller must be able to view the course in order to
  #   associate it with a planner note. Use a null or empty value to remove a planner note from a course. Note that if
  #   the planner note is linked to a learning object, its course_id cannot be changed.
  #
  # @returns PlannerNote
  def update
    update_params = params.permit(:title, :details, :course_id, :todo_date)
    note = @current_user.planner_notes.find(params[:id])
    if update_params.key?(:course_id)
      course_id = update_params.delete(:course_id)
      if note.linked_object_id.present? && note.course_id != course_id
        return render json: { message: 'course_id cannot be changed for linked planner notes' }, status: :bad_request
      end
      if course_id.present?
        course = Course.find(course_id)
        return unless authorized_action(course, @current_user, :read)
        update_params[:course] = course
      else
        update_params[:course] = nil
      end
    end
    if note.update_attributes(update_params)
      Rails.cache.delete(planner_meta_cache_key)
      render json: planner_note_json(note, @current_user, session), status: :ok
    else
      render json: note.errors, status: :bad_request
    end
  end

  # @API Create a planner note
  #
  # Create a planner note for the current user
  # @argument title [String]
  #   The title of the planner note.
  # @argument details [String]
  #   Text of the planner note.
  # @argument todo_date [Date]
  #   The date where this planner note should appear in the planner.
  #   The value should be formatted as: yyyy-mm-dd.
  # @argument course_id [Optional, Integer]
  #   The ID of the course to associate with the planner note. The caller must be able to view the course in order to
  #   associate it with a planner note.
  # @argument linked_object_type [Optional, String]
  #   The type of a learning object to link to this planner note. Must be used in conjunction wtih linked_object_id
  #   and course_id. Valid linked_object_type values are:
  #   'announcement', 'assignment', 'discussion_topic', 'wiki_page', 'quiz'
  # @argument linked_object_id [Optional, Integer]
  #   The id of a learning object to link to this planner note. Must be used in conjunction with linked_object_type
  #   and course_id. The object must be in the same course as specified by course_id. If the title argument is not
  #   provided, the planner note will use the learning object's title as its title. Only one planner note may be
  #   linked to a specific learning object.
  # @returns PlannerNote
  def create
    create_params = params.permit(:title, :details, :course_id, :todo_date, :linked_object_type, :linked_object_id)
    if (course_id = create_params.delete(:course_id))
      course = Course.find(course_id)
      return unless authorized_action(course, @current_user, :read)
      create_params[:course] = course
    end

    asset_id = create_params.delete(:linked_object_id)
    asset_type = create_params.delete(:linked_object_type)
    if asset_id.present? && asset_type.present?
      return render(json: { message: 'must specify course_id' }, status: :bad_request) unless course_id
      asset_klass = LINKED_OBJECT_TYPES[asset_type]&.constantize
      return render(json: { message: 'invalid linked_object_type' }, status: :bad_request) unless asset_klass
      asset = asset_klass.find_by!(id: asset_id, context_id: course_id, context_type: 'Course')
      return unless authorized_action(asset, @current_user, :read)
      create_params[:linked_object] = asset
      create_params[:title] ||= Context.asset_name(asset)
    end

    note = @current_user.planner_notes.new(create_params)
    begin
      if note.save
        Rails.cache.delete(planner_meta_cache_key)
        render json: planner_note_json(note, @current_user, session), status: :created
      else
        render json: note.errors, status: :bad_request
      end
    rescue ActiveRecord::RecordNotUnique
      render json: { message: 'a planner note linked to that object already exists' }, status: :bad_request
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
      Rails.cache.delete(planner_meta_cache_key)
      render json: planner_note_json(note, @current_user, session), status: :ok
    else
      render json: note.errors, status: :bad_request
    end
  end

  private

  def planner_note_params
    params.permit(:start_date, :end_date, :context_codes)
  end
end
