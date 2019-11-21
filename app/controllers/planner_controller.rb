#
# Copyright (C) 2018 - present Instructure, Inc.
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
#
# API for listing learning objects to display on the student planner and calendar

class PlannerController < ApplicationController
  include Api::V1::PlannerItem

  before_action :require_user, unless: :public_access?
  before_action :set_user
  before_action :require_planner_enabled
  before_action :set_date_range
  before_action :set_params, only: [:index]

  attr_reader :start_date, :end_date, :page, :per_page,
              :include_concluded

  # @API List planner items
  #
  # Retrieve the paginated list of objects to be shown on the planner for the
  # current user with the associated planner override to override an item's
  # visibility if set.
  #
  # Planner items for a student may also be retrieved by a linked observer. Use
  # the path that accepts a user_id and supply the student's id.
  #
  # @argument start_date [Date]
  #   Only return items starting from the given date.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument end_date [Date]
  #   Only return items up to the given date.
  #   The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument context_codes[] [String]
  #   List of context codes of courses and/or groups whose items you want to see.
  #   If not specified, defaults to all contexts associated to the current user.
  #   Note that concluded courses will be ignored unless specified in the includes[]
  #   parameter. The format of this field is the context type, followed by an underscore,
  #   followed by the context id. For example: course_42, group_123
  #
  # @argument filter [String, "new_activity"]
  #   Only return items that have new or unread activity
  #
  # @example_response
  #  [
  #   {
  #     "context_type": "Course",
  #     "course_id": 1,
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
  #  ]
  def index
    Shackles.activate(:slave) do
      # fetch a meta key so we can invalidate just this info and not the whole of the user's cache
      planner_overrides_meta_key = get_planner_cache_id(@current_user)

      composite_cache_key = ['planner_items3',
                             planner_overrides_meta_key,
                             page,
                             params[:filter],
                             default_opts,
                             contexts_cache_key].cache_key
      if stale?(etag: composite_cache_key, template: false)
        items_response = Rails.cache.fetch(composite_cache_key, expires_in: 1.week) do
          items = collection_for_filter(params[:filter])
          items = Api.paginate(items, self, params.key?(:user_id) ? api_v1_user_planner_items_url : api_v1_planner_items_url)
          {
            json: planner_items_json(items, @user, session, {due_after: start_date, due_before: end_date}),
            link: response.headers["Link"].to_s,
          }
        end

        response.headers["Link"] = items_response[:link]
        render json: items_response[:json]
      end
    end
  end

  private

  def set_user
    if params.key?(:user_id)
      @user = api_find(User, params[:user_id])
      return render_unauthorized_action unless @user == @current_user || @user.grants_right?(@current_user, session, :read_as_parent)
    else
      @user = @current_user
    end
  end

  def public_access?
    # this is for things that are visible on courses with a public syllabus
    params[:filter] == 'all_ungraded_todo_items'
  end

  def collection_for_filter(filter)
    case filter
    when 'new_activity'
      unread_items
    when 'ungraded_todo_items'
      ungraded_todo_items
    when 'all_ungraded_todo_items'
      all_ungraded_todo_items
    else
      planner_items
    end
  end

  def planner_items
    collections = [*assignment_collections,
                   ungraded_quiz_collection,
                   planner_note_collection,
                   page_collection,
                   ungraded_discussion_collection,
                   calendar_events_collection,
                   peer_reviews_collection]
    BookmarkedCollection.merge(*collections)
  end

  def unread_items
    collections = [unread_discussion_topic_collection,
                   unread_assignment_collection]

    BookmarkedCollection.merge(*collections)
  end

  def ungraded_todo_items
    collections = [page_collection,
                   ungraded_discussion_collection]
    BookmarkedCollection.merge(*collections)
  end

  # returns all pages and ungraded discussions in supplied contexts with todo dates (no needing-viewing filter)
  def all_ungraded_todo_items
    @unpub_contexts, @pub_contexts = @contexts.partition { |c| c.grants_right?(@user, :view_unpublished_items) }
    collections = []
    wiki_page_todo_scopes.each_with_index do |scope, i|
      collections << item_collection("pages_#{i}", scope, WikiPage, [:todo_date, :created_at], :id)
    end
    discussion_topic_todo_scopes.each_with_index do |scope, i|
      collections << item_collection("discussions_#{i}", scope, DiscussionTopic, [:todo_date, :posted_at, :created_at], :id)
    end
    BookmarkedCollection.merge(*collections)
  end

  def assignment_collections
    # TODO: For Teacher Planner, we'll need to optimize & add
    # the below `grading` and `moderation` collections. Disabled
    # for now to better optimize the Student Planner.
    #
    # grading = @user.assignments_needing_grading(default_opts) if @domain_root_account.grants_right?(@user, :manage_grades)
    # moderation = @user.assignments_needing_moderation(default_opts)
    viewing = @user.assignments_for_student('viewing', default_opts).
      preload(:quiz, :discussion_topic, :wiki_page)
    scopes = {viewing: viewing}
    # TODO: Add when ready (see above comment)
    # scopes[:grading] = grading if grading
    # scopes[:moderation] = moderation if moderation
    collections = []
    scopes.each do |scope_name, scope|
      next unless scope
      collections << item_collection(scope_name.to_s,
        scope,
        Assignment, [:user_due_date, :due_at, :created_at], :id)
    end
    collections
  end

  def ungraded_quiz_collection
    item_collection('ungraded_quizzes',
                    @user.ungraded_quizzes(default_opts),
                    Quizzes::Quiz, [:user_due_date, :due_at, :created_at], :id)
  end

  def unread_discussion_topic_collection
    item_collection('unread_discussion_topics',
                    @user.discussion_topics_needing_viewing(default_opts.except(:include_locked)).
                    unread_for(@user),
                    DiscussionTopic, [:todo_date, :posted_at, :delayed_post_at, :created_at], :id)
  end

  def unread_assignment_collection
    assign_scope = Assignment.active.where(:context_type => "Course", :context_id => @local_course_ids)
    disc_assign_ids = DiscussionTopic.active.where(context_type: 'Course', context_id: @local_course_ids).
      where.not(assignment_id: nil).unread_for(@user).pluck(:assignment_id)
    scope = assign_scope.where("assignments.muted IS NULL OR NOT assignments.muted").
      # we can assume content participations because they're automatically created when comments
      # are made - see SubmissionComment#update_participation
      joins(submissions: :content_participations).
      where(content_participations: {user_id: @user, workflow_state: 'unread'}).union(
        assign_scope.where(id: disc_assign_ids)
      ).due_between_for_user(start_date, end_date, @user)
    item_collection('unread_assignment_submissions',
                    scope,
                    Assignment, [:user_due_date, :due_at, :created_at], :id)
  end

  def planner_note_collection
    user = @user_ids.presence || @user
    shard = @user_ids.present? ? Shard.shard_for(@user_ids.first) : @user.shard # TODO fix to span multiple shards if needed
    course_ids = @course_ids.map{|id| Shard.relative_id_for(id, @user.shard, shard)}
    course_ids += [nil] if @user_ids.present?
    item_collection('planner_notes',
                    shard.activate { PlannerNote.active.where(user: user, todo_date: @start_date...@end_date, course_id: course_ids) },
                    PlannerNote, [:todo_date, :created_at], :id)
  end

  def page_collection
    item_collection('pages', @user.wiki_pages_needing_viewing(default_opts.except(:include_locked)),
      WikiPage, [:todo_date, :created_at], :id)
  end

  def ungraded_discussion_collection
    item_collection('ungraded_discussions', @user.discussion_topics_needing_viewing(default_opts.except(:include_locked)),
      DiscussionTopic, [:todo_date, :posted_at, :created_at], :id)
  end

  def calendar_events_collection
    item_collection('calendar_events',
      CalendarEvent.active.not_hidden.for_user_and_context_codes(@user, @context_codes).
         between(@start_date, @end_date),
      CalendarEvent, [:start_at, :created_at], :id)
  end

  def peer_reviews_collection
    item_collection('peer_reviews',
      @user.submissions_needing_peer_review(default_opts.except(:include_locked)),
      AssessmentRequest, [{submission: {assignment: :peer_reviews_due_at}},
                          {assessor_asset: :cached_due_date}, :created_at], :id)
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
    @start_date = formatted_planner_date('start_date', @start_date, 10.years.ago.beginning_of_day)
    @end_date = formatted_planner_date('end_date', @end_date, 10.years.from_now.beginning_of_day)
  rescue InvalidDates => e
    render json: {errors: e.message.as_json}, status: :bad_request
  end

  def set_params
    includes = Array.wrap(params[:include]) & %w{concluded}
    @per_page = params[:per_page] || 50
    @page = params[:page] || 'first'
    @include_concluded = includes.include? 'concluded'
    if params[:context_codes].present?
      @contexts = Context.from_context_codes(Array(params[:context_codes]))
      perms = public_access? ? [:read, :read_syllabus] : [:read]
      render_json_unauthorized and return false unless @contexts.all? { |c| c.grants_any_right?(@user, session, *perms) }
      (@user&.shard || Shard.current).activate do
        @course_ids = @contexts.select{ |c| c.is_a? Course }.map(&:id)
        @group_ids = @contexts.select{ |c| c.is_a? Group }.map(&:id)
      end
      @user_ids = @contexts.select{ |c| c.is_a? User }.map(&:id)
    else
      @course_ids = @user.course_ids_for_todo_lists(:student, default_opts.slice(:course_ids, :include_concluded))
      @group_ids = @user.group_ids_for_todo_lists(default_opts.slice(:group_ids))
      @user_ids = [@user.id]
    end

    # get ids relative to the current shard, not the user's
    @local_course_ids = @user ? @course_ids.map{|id| Shard.relative_id_for(id, @user.shard, Shard.current)} : @course_ids
    @local_group_ids = @user ? @group_ids.map{|id| Shard.relative_id_for(id, @user.shard, Shard.current)} : @group_ids

    @context_codes = @course_ids.map{|id| "course_#{id}"} || []
    @context_codes += @group_ids.map{|id| "group_#{id}"}
    @context_codes += @user_ids.map{|id| "user_#{id}"}
  end

  def contexts_cache_key
    [Context.last_updated_at(Course, @local_course_ids),
     Context.last_updated_at(User, @user_ids),
     Context.last_updated_at(Group, @local_group_ids)].compact.max || Time.zone.today
  end

  def default_opts
    {
      include_ignored: true,
      include_ungraded: true,
      include_concluded: include_concluded,
      include_locked: true,
      due_before: end_date,
      due_after: start_date,
      scope_only: true,
      course_ids: @course_ids,
      group_ids: @group_ids,
      limit: per_page.to_i + 1, # needs a + 1 because otherwise folio might think there aren't any more objects
    }
  end

  # return pages of the proper state in @pub_/@unpub_contexts, with todo_date: @start_date..@end_date
  def wiki_page_todo_scopes
    scopes = []
    Shard.partition_by_shard(@pub_contexts) do |contexts|
      scopes << WikiPage.where(todo_date: @start_date..@end_date).polymorphic_where(context: contexts).active
    end
    Shard.partition_by_shard(@unpub_contexts) do |contexts|
      scopes << WikiPage.where(todo_date: @start_date..@end_date).polymorphic_where(context: contexts).not_deleted
    end
    scopes
  end

  # return discussions of the proper state in @pub_/@unpub_contexts, with todo_date: @start_date..@end_date
  def discussion_topic_todo_scopes
    scopes = []
    Shard.partition_by_shard(@pub_contexts) do |contexts|
      scopes << DiscussionTopic.where(todo_date: @start_date..@end_date).polymorphic_where(context: contexts).published
    end
    Shard.partition_by_shard(@unpub_contexts) do |contexts|
      scopes << DiscussionTopic.where(todo_date: @start_date..@end_date).polymorphic_where(context: contexts).active
    end
    scopes
  end
end
