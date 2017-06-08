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

# @API Planner override
#
# API for creating, accessing and updating planner override. PlannerOverrides are used
# to control the visibility of objects displayed on the Planner.
#
# @model PlannerOverride
#     {
#       "id": "PlannerOverride",
#       "description": "User-controlled setting for whether an item should be displayed on the planner or not",
#       "properties": {
#         "id": {
#           "description": "The ID of the planner override",
#           "example": 234,
#           "type": "integer"
#         },
#         "plannable_type": {
#           "description": "The type of the associated object for the planner override",
#           "example": "Assignment",
#           "type": "string"
#         },
#         "plannable_id": {
#           "description": "The id of the associated object for the planner override",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "The id of the associated user for the planner override",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "The current published state of the item, synced with the associated object",
#           "example": "published",
#           "type": "string"
#         },
#         "visible": {
#           "description": "Controls whether or not the associated plannable item is displayed on the planner",
#           "example": false,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "The datetime of when the planner override was created",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The datetime of when the planner override was updated",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "deleted_at": {
#           "description": "The datetime of when the planner override was deleted, if applicable",
#           "example": "2017-05-15T12:12:00Z",
#           "type": "datetime"
#         }
#       }
#     }
#

class PlannerOverridesController < ApplicationController
  include Api::V1::PlannerItem

  before_action :require_user
  before_action :set_date_range

  attr_reader :start_date, :end_date
  # @API List planner items
  #
  # Retrieve the list of objects to be shown on the planner for the current user
  # with the associated planner override to override an item's visibility if set.
  #
  # @argument start_date [Date]
  #   Only return items starting from the given date.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument end_date [Date]
  #   Only return items up to the given date.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument filter [String, "new_activity"]
  #   Only return items that have new or unread activity
  #
  # @example_response
  # [
  #   {
  #     "context_type": "Course",
  #     "course_id": 1,
  #     "type": "viewing", // Whether it has been or needs to be graded, submitted, viewed (e.g. ungraded)
  #     "ignore": "http://canvas.instructure.com/api/v1/users/self/todo/discussion_topic_8/viewing?permanent=0", // For hiding on the todo list
  #     "ignore_permanently": "http://canvas.instructure.com/api/v1/users/self/todo/discussion_topic_8/viewing?permanent=1",
  #     "visible_in_planner": true, // Whether or not it is displayed on the student planner
  #     "planner_override": { ... planner override object ... }, // Associated PlannerOverride object if user has toggled visibility for the object on the planner
  #     "submissions": false, // The statuses of the user's submissions for this object
  #     "plannable_type": "discussion_topic",
  #     "plannable": { ... discussion topic object },
  #     "html_url": "/courses/1/discussion_topics/8"
  #   },
  #   {
  #     "context_type": "Course",
  #     "course_id": 1,
  #     "type": "submitting",
  #     "ignore": "http://canvas.instructure.com/api/v1/users/self/todo/assignment_1/submitting?permanent=0",
  #     "ignore_permanently": "http://canvas.instructure.com/api/v1/users/self/todo/assignment_1/submitting?permanent=1",
  #     "visible_in_planner": true,
  #     "planner_override": {
  #         "id": 3,
  #         "plannable_type": "Assignment",
  #         "plannable_id": 1,
  #         "user_id": 2,
  #         "workflow_state": "active",
  #         "visible": true, // A user-defined setting for minimizing/hiding objects on the planner
  #         "deleted_at": null,
  #         "created_at": "2017-05-18T18:35:55Z",
  #         "updated_at": "2017-05-18T18:35:55Z"
  #     },
  #     "submissions": { // The status as it pertains to the current user
  #       "excused": false,
  #       "graded": false,
  #       "late": false,
  #       "missing": true,
  #       "needs_grading": false,
  #       "with_feedback": false
  #     },
  #     "plannable_type": "assignment",
  #     "plannable": { ... assignment object ...  },
  #     "html_url": "http://canvas.instructure.com/courses/1/assignments/1#submit"
  #   },
  #   {
  #     "type": "viewing",
  #     "ignore": "http://canvas.instructure.com/api/v1/users/self/todo/planner_note_1/viewing?permanent=0",
  #     "ignore_permanently": "http://canvas.instructure.com/api/v1/users/self/todo/planner_note_1/viewing?permanent=1",
  #     "visible_in_planner": true,
  #     "planner_override": null,
  #     "submissions": false, // false if no associated assignment exists for the plannable item
  #     "plannable_type": "planner_note",
  #     "plannable": {
  #       "id": 1,
  #       "todo_date": "2017-05-30T06:00:00Z",
  #       "title": "hello",
  #       "details": "world",
  #       "user_id": 2,
  #       "course_id": null,
  #       "workflow_state": "active",
  #       "created_at": "2017-05-30T16:29:04Z",
  #       "updated_at": "2017-05-30T16:29:15Z"
  #     },
  #     "html_url": "http://canvas.instructure.com/api/v1/planner_notes.1"
  #   }
  # ]
  def items_index
    items = if params[:filter] == 'new_activity'
              unread_items
            else
              planner_items
            end

    items_json = items.map { |item| planner_item_json(item, @current_user, session, item.todo_type, default_opts) }

    render json: items_json
  end

  # @API List planner overrides
  #
  # Retrieve a planner override for the current user
  #
  # @returns [PlannerOverride]
  def index
    render :json => PlannerOverride.for_user(@current_user)
  end

  # @API Show a planner override
  #
  # Retrieve a planner override for the current user
  #
  # @returns PlannerOverride
  def show
    planner_override = PlannerOverride.find(params[:id])

    if planner_override.present?
      render json: planner_override
    else
      not_found
    end
  end

  # @API Update a planner override
  #
  # Update a planner override's visibilty for the current user
  #
  # @returns PlannerOverride
  def update
    planner_override = PlannerOverride.find(params[:id])
    planner_override.visible = value_to_boolean(params[:visible])

    if planner_override.save
      render json: planner_override, status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  # @API Create a planner override
  #
  # Create a planner override for the current user
  #
  # @returns PlannerOverride
  def create
    planner_override = PlannerOverride.new(plannable_type: params[:plannable_type],
                                       plannable_id: params[:plannable_id],
                                       visible: value_to_boolean(params[:visible]),
                                       user: @current_user)

    if planner_override.save
      render json: planner_override, status: :created
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  # @API Delete a planner override
  #
  # Delete a planner override for the current user
  #
  # @returns PlannerOverride
  def destroy
    planner_override = PlannerOverride.find(params[:id])

    if planner_override.destroy
      render json: planner_override, status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  private

  def planner_items
    @planner_items ||= Api.paginate(ungraded_discussion_items + page_items + assignment_items + planner_note_items, self, api_v1_planner_items_url)
  end

  def unread_items
    # Combines unread items from the Recent Activity stream (which doesn't
    # contain submission data) with unread submission updates,
    # like new grades or comments.
    supported_types = %w(Assignment DiscussionTopic Announcement Quizzes::Quiz WikiPage)
    stream_items = @current_user.cached_recent_stream_items.
                    select { |si| si.unread && supported_types.include?(si.asset_type) }.
                    map { |si| si.data(@current_user.id) }.
                    each { |si| si.todo_type = 'viewing' }
    submitted_assignment_items = Submission.with_assignment.
                                  where(user_id: @current_user).
                                  select { |s| s.unread?(@current_user) }.
                                  map(&:assignment).
                                  each { |a| a.todo_type = 'viewing' }
    @unread_items ||= Api.paginate(stream_items + submitted_assignment_items, self, api_v1_planner_items_url)
  end

  def assignment_items
    grading = @current_user.assignments_needing_grading(default_opts).each { |a| a.todo_type = 'grading' }
    submitting = @current_user.assignments_needing_submitting(default_opts).each { |a| a.todo_type = 'submitting' }
    moderation = @current_user.assignments_needing_moderation(default_opts).each { |a| a.todo_type = 'moderation' }
    ungraded_quiz = @current_user.ungraded_quizzes_needing_submitting(default_opts).each { |a| a.todo_type = 'submitting' }
    submitted = @current_user.submitted_assignments(default_opts).each { |a| a.todo_type = 'submitted' }
    @assignments ||= grading + submitted + ungraded_quiz + submitting + moderation
  end

  def planner_note_items
    @planner_notes ||= PlannerNote.where(user: @current_user, todo_date: @start_date...@end_date).each { |pn| pn.todo_type = 'viewing' }
  end

  def page_items
    @pages ||= @current_user.wiki_pages_needing_viewing(default_opts).each { |p| p.todo_type = 'viewing' }
  end

  def ungraded_discussion_items
    @ungraded_discussions ||= @current_user.discussion_topics_needing_viewing(default_opts).each { |t| t.todo_type = 'viewing' }
  end

  def set_date_range
    @end_date, @start_date = if [params[:end_date], params[:start_date]].all?(&:blank?)
                                [2.weeks.from_now, 2.weeks.ago]
                              else
                                [params[:end_date], params[:start_date]]
                              end
    # Since a range is needed, set values that weren't passed to a date
    # in the far past/future as to get all values before or after whichever
    # date was passed
    @end_date ||= 10.years.from_now
    @start_date ||= 10.years.ago
  end

  def require_user
    render_unauthorized_action if !@current_user || !@domain_root_account.feature_enabled?(:student_planner)
  end

  def default_opts
    {
      include_ignored: true,
      include_ungraded: true,
      include_concluded: true,
      include_locked: true,
      due_before: end_date,
      due_after: start_date,
      limit: (params[:limit]&.to_i || 50)
    }
  end
end
