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
#         "deleted_at": {
#           "description": "The datetime of when the planner override was deleted, if applicable",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         }
#       }
#     }
#

class PlannerOverridesController < ApplicationController
  include Api::V1::PlannerItem

  before_action :require_user
  before_action :set_date_range
  before_action :set_planner_items, only: [:items_index]

  attr_reader :start_date, :end_date

  # @API List planner items
  #
  # Retrieve the list of objects to be shown on the planner for the current user
  # with the associated planner override to override an item's visibility if set.
  #
  # @argument date [Date]
  #   Only return items since the given date.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @example_response
  #   [
  #     {
  #       'type': 'grading',        // an assignment that needs grading
  #       'assignment': { .. assignment object .. },
  #       'ignore': '.. url ..',
  #       'ignore_permanently': '.. url ..',
  #       'visible_in_planner': true
  #       'html_url': '.. url ..',
  #       'needs_grading_count': 3, // number of submissions that need grading
  #       'context_type': 'course', // course|group
  #       'course_id': 1,
  #       'group_id': null,
  #     },
  #     {
  #       'type' => 'submitting',   // an assignment that needs submitting soon
  #       'assignment' => { .. assignment object .. },
  #       'ignore' => '.. url ..',
  #       'ignore_permanently' => '.. url ..',
  #       'visible_in_planner': true
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     },
  #     {
  #       'type' => 'submitting',   // a quiz that needs submitting soon
  #       'quiz' => { .. quiz object .. },
  #       'ignore' => '.. url ..',
  #       'ignore_permanently' => '.. url ..',
  #       'visible_in_planner': true
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     },
  #   ]
  def items_index
    pi_json = @planner_items.map { |item| planner_item_json(item, @current_user, session, item.todo_type) }
    render json: pi_json
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

  def set_planner_items
    set_assignments
    set_pages
    set_planner_notes
    set_ungraded_discussions
    @planner_items = Api.paginate(@discussions + @pages + @assignments + @planner_notes, self, api_v1_planner_items_url)
  end

  def set_assignments
    @grading = @current_user.assignments_needing_grading(default_opts).each { |a| a.todo_type = 'grading' }
    @submitting = @current_user.assignments_needing_submitting(default_opts).each { |a| a.todo_type = 'submitting' }
    @moderation = @current_user.assignments_needing_moderation(default_opts).each { |a| a.todo_type = 'moderation' }
    @ungraded_quiz = @current_user.ungraded_quizzes_needing_submitting(default_opts).each { |a| a.todo_type = 'submitting' }
    @submitted = @current_user.submitted_assignments(default_opts).each { |a| a.todo_type = 'submitted' }
    @assignments = @grading + @submitted + @ungraded_quiz + @submitting + @moderation
  end

  def set_planner_notes
    @planner_notes = PlannerNote.where(user: @current_user, todo_date: @start_date...@end_date).each { |pn| pn.todo_type = 'viewing' }
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

  def set_pages
    @pages = @current_user.wiki_pages_needing_viewing(default_opts).each { |p| p.todo_type = 'viewing' }
  end

  def set_ungraded_discussions
    @discussions = @current_user.discussion_topics_needing_viewing(default_opts).each { |t| t.todo_type = 'viewing' }
  end

  def require_user
    render_unauthorized_action if !@current_user || !@domain_root_account.feature_enabled?(:student_planner)
  end

  def default_opts
    {
      include_ignored: true,
      include_ungraded: true,
      due_before: end_date,
      due_after: start_date,
      limit: (params[:limit]&.to_i || 50)
    }
  end
end
