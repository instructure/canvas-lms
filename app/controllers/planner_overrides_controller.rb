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
#         "marked_complete": {
#           "description": "Controls whether or not the associated plannable item is marked complete on the planner",
#           "example": false,
#           "type": "boolean"
#         },
#         "dismissed": {
#           "description": "Controls whether or not the associated plannable item shows up in the opportunities list",
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
  include Api::V1::PlannerOverride
  include PlannerHelper

  before_action :require_user
  before_action :set_date_range
  before_action :set_params, only: [:items_index]

  attr_reader :start_date, :end_date, :page, :per_page,
              :include_concluded, :only_favorites
  # @API List planner items
  #
  # Retrieve the paginated list of objects to be shown on the planner for the
  # current user with the associated planner override to override an item's
  # visibility if set.
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
  #     "visible_in_planner": true, // Whether or not it is displayed on the student planner
  #     "planner_override": { ... planner override object ... }, // Associated PlannerOverride object if user has toggled visibility for the object on the planner
  #     "submissions": false, // The statuses of the user's submissions for this object
  #     "plannable_id": "123",
  #     "plannable_type": "discussion_topic",
  #     "plannable": { ... discussion topic object },
  #     "html_url": "/courses/1/discussion_topics/8"
  #   },
  #   {
  #     "context_type": "Course",
  #     "course_id": 1,
  #     "visible_in_planner": true,
  #     "planner_override": {
  #         "id": 3,
  #         "plannable_type": "Assignment",
  #         "plannable_id": 1,
  #         "user_id": 2,
  #         "workflow_state": "active",
  #         "marked_complete": true, // A user-defined setting for marking items complete in the planner
  #         "dismissed": false, // A user-defined setting for hiding items from the opportunities list
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
  #     "plannable_id": "456",
  #     "plannable_type": "assignment",
  #     "plannable": { ... assignment object ...  },
  #     "html_url": "http://canvas.instructure.com/courses/1/assignments/1#submit"
  #   },
  #   {
  #     "visible_in_planner": true,
  #     "planner_override": null,
  #     "submissions": false, // false if no associated assignment exists for the plannable item
  #     "plannable_id": "789",
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
    ensure_valid_planner_params or return

    items_json = Rails.cache.fetch(['planner_items', @current_user, page, params[:filter], default_opts].cache_key, expires_in: 120.minutes) do
      items = params[:filter] == 'new_activity' ? unread_items : planner_items
      items = Api.paginate(items, self, api_v1_planner_items_url)
      planner_items_json(items, @current_user, session, {start_at: start_date, due_after: start_date, due_before: end_date})
    end

    render json: items_json
  end

  # @API List planner overrides
  #
  # Retrieve a planner override for the current user
  #
  # @returns [PlannerOverride]
  def index
    planner_overrides = Api.paginate(PlannerOverride.for_user(@current_user).active, self, api_v1_planner_overrides_url)
    render :json => planner_overrides.map { |po| planner_override_json(po, @current_user, session) }
  end

  # @API Show a planner override
  #
  # Retrieve a planner override for the current user
  #
  # @returns PlannerOverride
  def show
    planner_override = PlannerOverride.find_by_id(params[:id])

    if planner_override.present?
      render json: planner_override_json(planner_override, @current_user, session)
    else
      render json: { message: "No object of type #{plannable_override.class} with that ID" }, status: :not_found
    end
  end

  # @API Update a planner override
  #
  # Update a planner override's visibilty for the current user
  #
  # @argument marked_complete
  #   determines whether the planner item is marked as completed
  #
  # @argument dismissed
  #   determines whether the planner item shows in the opportunities list
  #
  # @returns PlannerOverride
  def update
    planner_override = PlannerOverride.find(params[:id])
    planner_override.marked_complete = value_to_boolean(params[:marked_complete])
    planner_override.dismissed = value_to_boolean(params[:dismissed])

    if planner_override.save
      render json: planner_override_json(planner_override, @current_user, session), status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  # @API Create a planner override
  #
  # Create a planner override for the current user
  #
  # @argument plannable_type [String, "announcement"|"assignment"|"discussion_topic"|"quiz"|"wiki_page"|"planner_note"]
  #   Type of the item that you are overriding in the planner
  #
  # @argument plannable_id [Integer]
  #   ID of the item that you are overriding in the planner
  #
  # @argument marked_complete [Boolean]
  #   If this is true, the item will show in the planner as completed
  #
  # @argument dismissed [Boolean]
  #   If this is true, the item will not show in the opportunities list
  #
  #
  # @returns PlannerOverride
  def create
    plannable_type = PLANNABLE_TYPES[params[:plannable_type]]
    plannable = plannable_type.constantize.find_by_id(params[:plannable_id])
    unless plannable
      return render json: { message: "No object of type #{plannable_type} with that ID" }, status: :not_found
    end
    planner_override = PlannerOverride.new(plannable_type: plannable_type,
      plannable_id: params[:plannable_id], marked_complete: value_to_boolean(params[:marked_complete]),
      user: @current_user, dismissed: value_to_boolean(params[:dismissed]))

    if planner_override.save
      render json: planner_override_json(planner_override, @current_user, session), status: :created
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
      render json: planner_override_json(planner_override, @current_user, session), status: :ok
    else
      render json: planner_override.errors, status: :bad_request
    end
  end

  private

  def planner_items
    collections = [*assignment_collections,
                    planner_note_collection,
                    page_collection,
                    ungraded_discussion_collection]
    BookmarkedCollection.merge(*collections)
  end

  def unread_items
    collections = [unread_discussion_topic_collection,
                   unread_submission_collection]

    BookmarkedCollection.merge(*collections)
  end

  def assignment_collections
    # TODO: For Teacher Planner, we'll need to optimize & add
    # the below `grading` and `moderation` collections. Disabled
    # for now to better optimize the Student Planner.
    #
    # grading = @current_user.assignments_needing_grading(default_opts) if @domain_root_account.grants_right?(@current_user, :manage_grades)
    # moderation = @current_user.assignments_needing_moderation(default_opts)
    submitting = @current_user.assignments_needing_submitting(default_opts).
      preload(:quiz, :discussion_topic)
    ungraded_quiz = @current_user.ungraded_quizzes_needing_submitting(default_opts)
    submitted = @current_user.submitted_assignments(default_opts).preload(:quiz, :discussion_topic)
    scopes = {submitted: submitted, ungraded_quiz: ungraded_quiz,
              submitting: submitting}
    # TODO: Add when ready (see above comment)
    # scopes[:grading] = grading if grading
    # scopes[:moderation] = moderation if moderation
    collections = []
    scopes.each do |scope_name, scope|
      next unless scope
      base_model = scope_name == :ungraded_quiz ? Quizzes::Quiz : Assignment
      collections << item_collection(scope_name.to_s, scope, base_model, [:due_at, :created_at], :id)
    end
    collections
  end

  def unread_discussion_topic_collection
    item_collection('unread_discussion_topics',
                    @current_user.discussion_topics_needing_viewing(scope_only: true, include_ignored: true,
                      due_before: end_date, due_after: start_date).
                      unread_for(@current_user),
                    DiscussionTopic, [:todo_date, :posted_at, :delayed_post_at, :last_reply_at, :created_at], :id)
  end

  def unread_submission_collection
    course_ids = @current_user.enrollments.shard(Shard.current).where(:type => %w{StudentEnrollment StudentViewEnrollment}).current.active_by_date.distinct.pluck(:course_id)
    item_collection('unread_assignment_submissions',
                    Assignment.active.where(:context_type => "Course", :context_id => course_ids).
                      where("assignments.muted IS NULL OR NOT assignments.muted").
                      joins(:submissions => :content_participations). # we can assume content participations because they're automatically created when comments are made - see SubmissionComment#update_participation
                      where(:submissions => {:user_id => @current_user}).
                      where(:content_participations => {:user_id => @current_user, :workflow_state => 'unread'}).
                      due_between_with_overrides(start_date, end_date),
                    Assignment, [:due_at, :created_at], :id)
  end

  def planner_note_collection
    item_collection('planner_notes',
                    PlannerNote.active.where(user: @current_user, todo_date: @start_date...@end_date).
                      where("course_id IS NULL OR course_id IN (?)", @current_user.course_ids_for_todo_lists(:student, default_opts)),
                    PlannerNote, [:todo_date, :created_at], :id)
  end

  def page_collection
    item_collection('pages', @current_user.wiki_pages_needing_viewing(default_opts),
      WikiPage, [:todo_date, :created_at], :id)
  end

  def ungraded_discussion_collection
    item_collection('ungraded_discussions', @current_user.discussion_topics_needing_viewing(default_opts),
      DiscussionTopic, [:todo_date, :posted_at, :created_at], :id)
  end

  def item_collection(label, scope, base_model, *order_by)
    descending = params[:order] == 'desc'
    bookmarker = Plannable::Bookmarker.new(base_model, descending, *order_by)
    [label, BookmarkedCollection.wrap(bookmarker, scope)]
  end

  def set_date_range
    @start_date, @end_date = if [params[:start_date], params[:end_date]].all?(&:blank?)
                                [2.weeks.ago.beginning_of_day,
                                 2.weeks.from_now.beginning_of_day]
                              else
                                [params[:start_date], params[:end_date]]
                              end
    # Since a range is needed, set values that weren't passed to a date
    # in the far past/future as to get all values before or after whichever
    # date was passed
    @start_date = formatted_planner_date('start_date', @start_date, 10.years.ago)
    @end_date   = formatted_planner_date('end_date', @end_date, 10.years.from_now)
  end

  def set_params
    includes = Array.wrap(params[:include]) & %w{concluded only_favorites}
    @per_page = params[:per_page] || 50
    @page = params[:page] || 'first'
    @include_concluded = includes.include? 'concluded'
    @only_favorites = includes.include? 'only_favorites'
  end

  def require_user
    render_unauthorized_action if !@current_user || !@domain_root_account.feature_enabled?(:student_planner)
  end

  def default_opts
    {
      include_ignored: true,
      include_ungraded: true,
      include_concluded: include_concluded,
      only_favorites: only_favorites,
      include_locked: true,
      due_before: end_date,
      due_after: start_date,
      scope_only: true,
      limit: per_page.to_i + 1, # needs a + 1 because otherwise folio might think there aren't any more objects
    }
  end
end
