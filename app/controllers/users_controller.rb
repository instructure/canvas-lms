#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

# @API Users
# API for accessing information on the current and other users.
#
# Throughout this API, the `:user_id` parameter can be replaced with `self` as
# a shortcut for the id of the user accessing the API. For instance,
# `users/:user_id/page_views` can be accessed as `users/self/page_views` to
# access the current user's page views.
#
# @model User
#     {
#       "id": "User",
#       "description": "A Canvas user, e.g. a student, teacher, administrator, observer, etc.",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "The ID of the user.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "name": {
#           "description": "The name of the user.",
#           "example": "Sheldon Cooper",
#           "type": "string"
#         },
#         "sortable_name": {
#           "description": "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
#           "example": "Cooper, Sheldon",
#           "type": "string"
#         },
#         "short_name": {
#           "description": "A short name the user has selected, for use in conversations or other less formal places through the site.",
#           "example": "Shelly",
#           "type": "string"
#         },
#         "sis_user_id": {
#           "description": "The SIS ID associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
#           "example": "SHEL93921",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "The id of the SIS import.  This field is only included if the user came from a SIS import and has permissions to manage SIS information.",
#           "example": "18",
#           "type": "int64"
#         },
#         "sis_login_id": {
#           "description": "DEPRECATED: The SIS login ID associated with the user. Please use the sis_user_id or login_id. This field will be removed in a future version of the API.",
#           "type": "string"
#         },
#         "login_id": {
#           "description": "The unique login id for the user.  This is what the user uses to log in to Canvas.",
#           "example": "sheldon@caltech.example.com",
#           "type": "string"
#         },
#         "avatar_url": {
#           "description": "If avatars are enabled, this field will be included and contain a url to retrieve the user's avatar.",
#           "example": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
#           "type": "string"
#         },
#         "enrollments": {
#           "description": "Optional: This field can be requested with certain API calls, and will return a list of the users active enrollments. See the List enrollments API for more details about the format of these records.",
#           "type": "array",
#           "items": { "$ref": "Enrollment" }
#         },
#         "email": {
#           "description": "Optional: This field can be requested with certain API calls, and will return the users primary email address.",
#           "example": "sheldon@caltech.example.com",
#           "type": "string"
#         },
#         "locale": {
#           "description": "Optional: This field can be requested with certain API calls, and will return the users locale.",
#           "example": "tlh",
#           "type": "string"
#         },
#         "last_login": {
#           "description": "Optional: This field is only returned in certain API calls, and will return a timestamp representing the last time the user logged in to canvas.",
#           "example": "2012-05-30T17:45:25Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "time_zone": {
#           "description": "Optional: This field is only returned in ceratin API calls, and will return the IANA time zone name of the user's preferred timezone.",
#           "example": "America/Denver",
#           "type": "string"
#         }
#       }
#     }
class UsersController < ApplicationController
  include Twitter
  include LinkedIn
  include DeliciousDiigo
  include SearchHelper
  include I18nUtilities

  before_filter :require_user, :only => [:grades, :merge, :kaltura_session,
    :ignore_item, :ignore_stream_item, :close_notification, :mark_avatar_image,
    :user_dashboard, :toggle_dashboard, :masquerade, :external_tool,
    :dashboard_sidebar, :settings, :all_menu_courses]
  before_filter :require_registered_user, :only => [:delete_user_service,
    :create_user_service]
  before_filter :reject_student_view_student, :only => [:delete_user_service,
    :create_user_service, :merge, :user_dashboard, :masquerade]
  before_filter :require_self_registration, :only => [:new, :create]

  def grades
    @user = User.find_by_id(params[:user_id]) if params[:user_id].present?
    @user ||= @current_user
    if authorized_action(@user, @current_user, :read)
      current_active_enrollments = @user.current_enrollments.with_each_shard { |scope| scope.includes(:course) }

      @presenter = GradesPresenter.new(current_active_enrollments)

      if @presenter.has_single_enrollment?
        redirect_to course_grades_url(@presenter.single_enrollment.course_id)
        return
      end

      Enrollment.send(:preload_associations, @observed_enrollments, :course)
    end
  end

  def oauth
    if !feature_and_service_enabled?(params[:service])
      flash[:error] = t('service_not_enabled', "That service has not been enabled")
      return redirect_to(user_profile_url(@current_user))
    end
    return_to_url = params[:return_to] || user_profile_url(@current_user)
    if params[:service] == "google_docs"
      redirect_to GoogleDocs.google_docs_request_token_url(return_to_url, session, google_docs_user, request.host_with_port, oauth_success_url(:service => 'google_docs'))
    elsif params[:service] == "twitter"
      redirect_to twitter_request_token_url(return_to_url)
    elsif params[:service] == "linked_in"
      redirect_to linked_in_request_token_url(return_to_url)
    elsif params[:service] == "facebook"
      oauth_request = OauthRequest.create(
        :service => 'facebook',
        :secret => CanvasUuid::Uuid.generate("fb", 10),
        :return_url => return_to_url,
        :user => @current_user,
        :original_host_with_port => request.host_with_port
      )
      redirect_to Facebook.authorize_url(oauth_request)
    end
  end

  def oauth_success
    oauth_request = nil
    if params[:oauth_token]
      oauth_request = OauthRequest.find_by_token_and_service(params[:oauth_token], params[:service])
    elsif params[:state] && params[:service] == 'facebook'
      oauth_request = OauthRequest.find_by_id(Facebook.oauth_request_id(params[:state]))
    end

    if !oauth_request || (request.host_with_port == oauth_request.original_host_with_port && oauth_request.user != @current_user)
      flash[:error] = t('oauth_fail', "OAuth Request failed. Couldn't find valid request")
      redirect_to (@current_user ? user_profile_url(@current_user) : root_url)
    elsif request.host_with_port != oauth_request.original_host_with_port
      url = url_for request.parameters.merge(:host => oauth_request.original_host_with_port, :only_path => false)
      redirect_to url
    else
      if params[:service] == "facebook"
        service = Facebook.authorize_success(@current_user, params[:access_token])
        if service
          flash[:notice] = t('facebook_added', "Facebook account successfully added!")
        else
          flash[:error] = t('facebook_fail', "Facebook authorization failed.")
        end
      elsif params[:service] == "google_docs"
        begin
          GoogleDocs.google_docs_get_access_token(oauth_request, params[:oauth_verifier], session, google_docs_user)
          flash[:notice] = t('google_docs_added', "Google Docs access authorized!")
        rescue => e
          ErrorReport.log_exception(:oauth, e)
          flash[:error] = t('google_docs_fail', "Google Docs authorization failed. Please try again")
        end
      elsif params[:service] == "linked_in"
        begin
          linked_in_get_access_token(oauth_request, params[:oauth_verifier])
          flash[:notice] = t('linkedin_added', "LinkedIn account successfully added!")
        rescue => e
          ErrorReport.log_exception(:oauth, e)
          flash[:error] = t('linkedin_fail', "LinkedIn authorization failed. Please try again")
        end
      else
        begin
          token = twitter_get_access_token(oauth_request, params[:oauth_verifier])
          flash[:notice] = t('twitter_added', "Twitter access authorized!")
        rescue => e
          ErrorReport.log_exception(:oauth, e)
          flash[:error] = t('twitter_fail_whale', "Twitter authorization failed. Please try again")
        end
      end
      return_to(oauth_request.return_url, user_profile_url(@current_user))
    end
  end

  # @API List users in account
  # Retrieve the list of users associated with this account.
  #
  # @argument search_term [Optional, String]
  #   The partial name or full ID of the users to match and return in the
  #   results list. Must be at least 3 characters.
  #
  # @returns [User]
  def index
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      @root_account = @context.root_account
      @query = (params[:user] && params[:user][:name]) || params[:term]
      js_env :ACCOUNT => account_json(@domain_root_account, nil, session, ['registration_settings'])
      Shackles.activate(:slave) do
        if @context && @context.is_a?(Account) && @query
          @users = @context.users_name_like(@query)
        elsif params[:enrollment_term_id].present? && @root_account == @context
          @users = @context.fast_all_users.
              where("EXISTS (?)", Enrollment.where("enrollments.user_id=users.id").
                joins(:course).
                where(User.enrollment_conditions(:active)).
                where(courses: { enrollment_term_id: params[:enrollment_term_id]}))
        elsif !api_request?
          @users = @context.fast_all_users
        end

        if api_request?
          search_term = params[:search_term].presence

          if search_term
            users = UserSearch.for_user_in_context(search_term, @context, @current_user, session)
          else
            users = UserSearch.scope_for(@context, @current_user)
          end

          users = Api.paginate(users, self, api_v1_account_users_url)
          user_json_preloads(users)
          return render :json => users.map { |u| user_json(u, @current_user, session) }
        else
          @users ||= []
          @users = @users.paginate(:page => params[:page])
        end

        respond_to do |format|
          if @users.length == 1 && params[:term]
            format.html {
              redirect_to(named_context_url(@context, :context_user_url, @users.first))
            }
          else
            @enrollment_terms = []
            if @root_account == @context
              @enrollment_terms = @context.enrollment_terms.active.order(EnrollmentTerm.nulls(:first, :start_at))
            end
            format.html
          end
          format.json {
            cancel_cache_buster
            expires_in 30.minutes
            render(:json => @users.map { |u| { :label => u.name, :id => u.id } })
          }
        end
      end
    end
  end


  before_filter :require_password_session, :only => [:masquerade]
  def masquerade
    @user = api_find(User, params[:user_id])
    return render_unauthorized_action unless @user.can_masquerade?(@real_current_user || @current_user, @domain_root_account)
    if request.post?
      if @user == @real_current_user
        session.delete(:become_user_id)
      else
        session[:become_user_id] = params[:user_id]
      end
      return_url = session[:masquerade_return_to]
      session.delete(:masquerade_return_to)
      @current_user.associate_with_shard(@user.shard, :shadow) if PageView.db?
      return return_to(return_url, request.referer || dashboard_url)
    end
  end

  def user_dashboard
    if custom_dash = @domain_root_account.settings[:dashboard_url]
      return redirect_to custom_dash
    end
    check_incomplete_registration
    get_context

    # dont show crumbs on dashboard because it does not make sense to have a breadcrumb
    # trail back to home if you are already home
    clear_crumbs

    if request.path =~ %r{\A/dashboard\z}
      return redirect_to(dashboard_url, :status => :moved_permanently)
    end
    disable_page_views if @current_pseudonym && @current_pseudonym.unique_id == "pingdom@instructure.com"

    js_env :DASHBOARD_SIDEBAR_URL => dashboard_sidebar_url

    @announcements = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
    @pending_invitations = @current_user.cached_current_enrollments(:include_enrollment_uuid => session[:enrollment_uuid]).select { |e| e.invited? }
    @stream_items = @current_user.try(:cached_recent_stream_items) || []
  end

  def cached_upcoming_events(user)
    Rails.cache.fetch(['cached_user_upcoming_events', user].cache_key,
      :expires_in => 3.minutes) do
      user.upcoming_events :contexts => ([user] + user.cached_contexts)
    end
  end

  def cached_submissions(user, upcoming_events)
    Rails.cache.fetch(['cached_user_submissions', user].cache_key,
      :expires_in => 3.minutes) do
      assignments = upcoming_events.select{ |e| e.is_a?(Assignment) }
      Shard.partition_by_shard(assignments) do |shard_assignments|
        Submission.
          select([:id, :assignment_id, :score, :workflow_state]).
          where(:assignment_id => shard_assignments, :user_id => user)
      end
    end
  end

  def prepare_current_user_dashboard_items
    if @current_user
      @upcoming_events =
        cached_upcoming_events(@current_user)
      @current_user_submissions =
        cached_submissions(@current_user, @upcoming_events)
    else
      @upcoming_events = []
    end
  end

  def dashboard_sidebar
    Shackles.activate(:slave) do
      prepare_current_user_dashboard_items

      if @show_recent_feedback = (@current_user.student_enrollments.active.present?)
        @recent_feedback = (@current_user && @current_user.recent_feedback) || []
      end
    end

    render :layout => false
  end

  def toggle_dashboard
    @current_user.preferences[:new_dashboard] = !@current_user.preferences[:new_dashboard]
    @current_user.save!
    render :json => {}
  end

  include Api::V1::StreamItem

  # @API List the activity stream
  # Returns the current user's global activity stream, paginated.
  #
  # There are many types of objects that can be returned in the activity
  # stream. All object types have the same basic set of shared attributes:
  #   !!!javascript
  #   {
  #     'created_at': '2011-07-13T09:12:00Z',
  #     'updated_at': '2011-07-25T08:52:41Z',
  #     'id': 1234,
  #     'title': 'Stream Item Subject',
  #     'message': 'This is the body text of the activity stream item. It is plain-text, and can be multiple paragraphs.',
  #     'type': 'DiscussionTopic|Conversation|Message|Submission|Conference|Collaboration|...',
  #     'read_state': false,
  #     'context_type': 'course', // course|group
  #     'course_id': 1,
  #     'group_id': null,
  #     'html_url': "http://..." // URL to the Canvas web UI for this stream item
  #   }
  #
  # In addition, each item type has its own set of attributes available.
  #
  # DiscussionTopic:
  #
  #   !!!javascript
  #   {
  #     'type': 'DiscussionTopic',
  #     'discussion_topic_id': 1234,
  #     'total_root_discussion_entries': 5,
  #     'require_initial_post': true,
  #     'user_has_posted': true,
  #     'root_discussion_entries': {
  #       ...
  #     }
  #   }
  #
  # For DiscussionTopic, the message is truncated at 4kb.
  #
  # Announcement:
  #
  #   !!!javascript
  #   {
  #     'type': 'Announcement',
  #     'announcement_id': 1234,
  #     'total_root_discussion_entries': 5,
  #     'require_initial_post': true,
  #     'user_has_posted': null,
  #     'root_discussion_entries': {
  #       ...
  #     }
  #   }
  #
  # For Announcement, the message is truncated at 4kb.
  #
  # Conversation:
  #
  #   !!!javascript
  #   {
  #     'type': 'Conversation',
  #     'conversation_id': 1234,
  #     'private': false,
  #     'participant_count': 3,
  #   }
  #
  # Message:
  #
  #   !!!javascript
  #   {
  #     'type': 'Message',
  #     'message_id': 1234,
  #     'notification_category': 'Assignment Graded'
  #   }
  #
  # Submission:
  #
  # Returns an {api:Submissions:Submission Submission} with its Course and Assignment data.
  #
  # Conference:
  #
  #   !!!javascript
  #   {
  #     'type': 'Conference',
  #     'web_conference_id': 1234
  #   }
  #
  # Collaboration:
  #
  #   !!!javascript
  #   {
  #     'type': 'Collaboration',
  #     'collaboration_id': 1234
  #   }
  def activity_stream
    if @current_user
      api_render_stream_for_contexts(nil, :api_v1_user_activity_stream_url)
    else
      render_unauthorized_action
    end
  end

  # @API Activity stream summary
  # Returns a summary of the current user's global activity stream.
  #
  # @example_response
  #   [
  #     {
  #       "type": "DiscussionTopic",
  #       "unread_count": 2,
  #       "count": 7
  #     },
  #     {
  #       "type": "Conversation",
  #       "unread_count": 0,
  #       "count": 3
  #     }
  #   ]
  def activity_stream_summary
    if @current_user
      api_render_stream_summary
    else
      render_unauthorize_action
    end
  end

  def manageable_courses
    get_context
    return unless authorized_action(@context, @current_user, :manage)

    # include concluded enrollments as well as active ones if requested
    include_concluded = params[:include].try(:include?, 'concluded')
    @query   = params[:course].try(:[], :name) || params[:term]
    @courses = @query.present? ?
      @context.manageable_courses_name_like(@query, include_concluded) :
      @context.manageable_courses(include_concluded).limit(500)

    cancel_cache_buster
    expires_in 30.minutes
    render :json => @courses.map { |c|
      { :label => c.name, :id => c.id, :term => c.enrollment_term.name,
        :enrollment_start => c.enrollment_term.start_at,
        :account_name => c.enrollment_term.root_account.name,
        :account_id => c.enrollment_term.root_account.id,
        :start_at => datetime_string(c.start_at, :verbose, nil, true),
        :end_at => datetime_string(c.conclude_at, :verbose, nil, true)
      }
    }
  end

  include Api::V1::TodoItem
  # @API List the TODO items
  # Returns the current user's list of todo items, as seen on the user dashboard.
  #
  # There is a limit to the number of items returned.
  #
  # The `ignore` and `ignore_permanently` URLs can be used to update the user's
  # preferences on what items will be displayed.
  # Performing a DELETE request against the `ignore` URL will hide that item
  # from future todo item requests, until the item changes.
  # Performing a DELETE request against the `ignore_permanently` URL will hide
  # that item forever.
  #
  # @example_response
  #   [
  #     {
  #       'type': 'grading',        // an assignment that needs grading
  #       'assignment': { .. assignment object .. },
  #       'ignore': '.. url ..',
  #       'ignore_permanently': '.. url ..',
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
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     }
  #   ]
  def todo_items
    return render_unauthorized_action unless @current_user

    grading = @current_user.assignments_needing_grading().map { |a| todo_item_json(a, @current_user, session, 'grading') }
    submitting = @current_user.assignments_needing_submitting().map { |a| todo_item_json(a, @current_user, session, 'submitting') }
    render :json => (grading + submitting)
  end

  include Api::V1::Assignment
  include Api::V1::CalendarEvent

  # @API List upcoming assignments, calendar events
  # Returns the current user's upcoming events, i.e. the same things shown
  # in the dashboard 'Coming Up' sidebar.
  #
  # @example_response
  #   [
  #     {
  #       "id"=>597,
  #       "title"=>"Upcoming Course Event",
  #       "description"=>"Attendance is correlated with passing!",
  #       "start_at"=>"2013-04-27T14:33:14Z",
  #       "end_at"=>"2013-04-27T14:33:14Z",
  #       "location_name"=>"Red brick house",
  #       "location_address"=>"110 Top of the Hill Dr.",
  #       "all_day"=>false,
  #       "all_day_date"=>nil,
  #       "created_at"=>"2013-04-26T14:33:14Z",
  #       "updated_at"=>"2013-04-26T14:33:14Z",
  #       "workflow_state"=>"active",
  #       "context_code"=>"course_12938",
  #       "child_events_count"=>0,
  #       "child_events"=>[],
  #       "parent_event_id"=>nil,
  #       "hidden"=>false,
  #       "url"=>"http://www.example.com/api/v1/calendar_events/597",
  #       "html_url"=>"http://www.example.com/calendar?event_id=597&include_contexts=course_12938"
  #     },
  #     {
  #       "id"=>"assignment_9729",
  #       "title"=>"Upcoming Assignment",
  #       "description"=>nil,
  #       "start_at"=>"2013-04-28T14:47:32Z",
  #       "end_at"=>"2013-04-28T14:47:32Z",
  #       "all_day"=>false,
  #       "all_day_date"=>"2013-04-28",
  #       "created_at"=>"2013-04-26T14:47:32Z",
  #       "updated_at"=>"2013-04-26T14:47:32Z",
  #       "workflow_state"=>"published",
  #       "context_code"=>"course_12942",
  #       "assignment"=>{
  #         "id"=>9729,
  #         "name"=>"Upcoming Assignment",
  #         "description"=>nil,
  #         "points_possible"=>10,
  #         "due_at"=>"2013-04-28T14:47:32Z",
  #         "assignment_group_id"=>2439,
  #         "automatic_peer_reviews"=>false,
  #         "grade_group_students_individually"=>nil,
  #         "grading_standard_id"=>nil,
  #         "grading_type"=>"points",
  #         "group_category_id"=>nil,
  #         "lock_at"=>nil,
  #         "peer_reviews"=>false,
  #         "position"=>1,
  #         "unlock_at"=>nil,
  #         "course_id"=>12942,
  #         "submission_types"=>["none"],
  #         "muted"=>false,
  #         "needs_grading_count"=>0,
  #         "html_url"=>"http://www.example.com/courses/12942/assignments/9729"
  #       },
  #       "url"=>"http://www.example.com/api/v1/calendar_events/assignment_9729",
  #       "html_url"=>"http://www.example.com/courses/12942/assignments/9729"
  #     }
  #   ]
  def upcoming_events
    return render_unauthorized_action unless @current_user

    Shackles.activate(:slave) do
      prepare_current_user_dashboard_items

      events = @upcoming_events.map do |e|
        event_json(e, @current_user, session)
      end

      render :json => events
    end
  end

  def ignore_item
    unless %w[grading submitting].include?(params[:purpose])
      return render(:json => { :ignored => false }, :status => 400)
    end
    @current_user.ignore_item!(ActiveRecord::Base.find_by_asset_string(params[:asset_string], ['Assignment']),
                               params[:purpose], params[:permanent] == '1')
    render :json => { :ignored => true }
  end

  # @API Hide a stream item
  # Hide the given stream item.
  #
  # @example_request
  #    curl https://<canvas>/api/v1/users/self/activity_stream/<stream_item_id> \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       "hidden": true
  #     }
  def ignore_stream_item
    @current_user.shard.activate do # can't just pass in the user's shard to relative_id_for, since local ids will be incorrectly scoped to the current shard, not the user's
      if item = @current_user.stream_item_instances.where(stream_item_id: Shard.relative_id_for(params[:id], Shard.current, Shard.current)).first
        item.update_attribute(:hidden, true) # observer handles cache invalidation
      end
    end
    render :json => { :hidden => true }
  end

  # @API Hide all stream items
  # Hide all stream items for the user
  #
  # @example_request
  #    curl https://<canvas>/api/v1/users/self/activity_stream \
  #       -X DELETE \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       "hidden": true
  #     }
  def ignore_all_stream_items
    @current_user.shard.activate do # can't just pass in the user's shard to relative_id_for, since local ids will be incorrectly scoped to the current shard, not the user's
      @current_user.stream_item_instances.where(:hidden => false).each do |item|
        item.update_attribute(:hidden, true) # observer handles cache invalidation
      end
    end
    render :json => { :hidden => true }
  end

  # @API Upload a file
  #
  # Upload a file to the user's personal files section.
  #
  # This API endpoint is the first step in uploading a file to a user's files.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Note that typically users will only be able to upload files to their
  # own files section. Passing a user_id of +self+ is an easy shortcut
  # to specify the current user.
  def create_file
    @user = api_find(User, params[:user_id])
    @attachment = @user.attachments.build
    if authorized_action(@attachment, @current_user, :create)
      @context = @user
      api_attachment_preflight(@current_user, request, :check_quota => true)
    end
  end

  def close_notification
    @current_user.close_announcement(AccountNotification.find(params[:id]))
    render :json => @current_user
  end

  def delete_user_service
    deleted = @current_user.user_services.find(params[:id]).destroy
    if deleted.service == "google_docs"
      Rails.cache.delete(['google_docs_tokens', @current_user].cache_key)
    end
    render :json => {:deleted => true}
  end

  ServiceCredentials = Struct.new(:service_user_name,:decrypted_password)

  def create_user_service
    begin
      user_name = params[:user_service][:user_name]
      password = params[:user_service][:password]
      service = ServiceCredentials.new( user_name, password )
      case params[:user_service][:service]
        when 'delicious'
          delicious_get_last_posted(service)
        when 'diigo'
          diigo_get_bookmarks(service, 1)
        when 'skype'
          true
        else
          raise "Unknown Service"
      end
      @service = UserService.register_from_params(@current_user, params[:user_service])
      render :json => @service
    rescue => e
      render :json => {:errors => true}, :status => :bad_request
    end
  end

  def services
    params[:service_types] ||= params[:service_type]
    json = Rails.cache.fetch(['user_services', @current_user, params[:service_type]].cache_key) do
      @services = @current_user.user_services rescue []
      if params[:service_types]
        @services = @services.of_type(params[:service_types].split(",")) rescue []
      end
      @services.map{ |s| s.as_json(only: [:service_user_id, :service_user_url, :service_user_name, :service, :type, :id]) }
    end
    render :json => json
  end

  def bookmark_search
    @service = @current_user.user_services.find_by_type_and_service('BookmarkService', params[:service_type]) rescue nil
    res = nil
    res = @service.find_bookmarks(params[:q]) if @service
    render :json => res
  end

  def show
    get_context
    @context_account = @context.is_a?(Account) ? @context : @domain_root_account
    @user = params[:id] && params[:id] != 'self' ? User.find(params[:id]) : @current_user
    if authorized_action(@user, @current_user, :view_statistics)
      add_crumb(t('crumbs.profile', "%{user}'s profile", :user => @user.short_name), @user == @current_user ? user_profile_path(@current_user) : user_path(@user) )

      # course_section and enrollment term will only be used if the enrollment dates haven't been cached yet;
      # maybe should just look at the first enrollment and check if it's cached to decide if we should include
      # them here
      @enrollments = @user.enrollments.with_each_shard { |scope| scope.where("enrollments.workflow_state<>'deleted' AND courses.workflow_state<>'deleted'").includes({:course => { :enrollment_term => :enrollment_dates_overrides }}, :associated_user, :course_section) }
      @enrollments = @enrollments.sort_by {|e| [e.state_sortable, e.rank_sortable, e.course.name] }
      # pre-populate the reverse association
      @enrollments.each { |e| e.user = @user }
      @group_memberships = @user.current_group_memberships.includes(:group)

      respond_to do |format|
        format.html
        format.json {
          render :json => user_json(@user, @current_user, session, %w{locale avatar_url},
                                    @current_user.pseudonym.account) }
      end
    end
  end

  def external_tool
    @tool = ContextExternalTool.find_for(params[:id], @domain_root_account, :user_navigation)
    @resource_title = @tool.label_for(:user_navigation)
    @resource_url = @tool.user_navigation(:url)
    @opaque_id = @tool.opaque_identifier_for(@current_user)
    @resource_type = 'user_navigation'
    @return_url = user_profile_url(@current_user, :include_host => true)

    adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @domain_root_account)
    adapter.prepare_tool_launch(@return_url, resource_type: @resource_type, link_code: @opaque_id)
    @tool_settings = adapter.generate_post_payload

    @active_tab = @tool.asset_string
    add_crumb(@current_user.short_name, user_profile_path(@current_user))
    render :template => 'external_tools/tool_show'
  end

  def new
    return redirect_to(root_url) if @current_user
    js_env :ACCOUNT => account_json(@domain_root_account, nil, session, ['registration_settings']),
           :PASSWORD_POLICY => @domain_root_account.password_policy
    render :layout => 'bare'
  end

  include Api::V1::User
  include Api::V1::Avatar
  include Api::V1::Account

  # @API Create a user
  # Create and return a new user and pseudonym for an account.
  #
  # If you don't have the "Modify login details for users" permission, but
  # self-registration is enabled on the account, you can still use this
  # endpoint to register new users. Certain fields will be required, and
  # others will be ignored (see below).
  #
  # @argument user[name] [Optional, String]
  #   The full name of the user. This name will be used by teacher for grading.
  #   Required if this is a self-registration.
  #
  # @argument user[short_name] [Optional, String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [Optional, String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [Optional, String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [Optional, String]
  #   The user's preferred language as a two-letter ISO 639-1 code.
  #
  # @argument user[birthdate] [Optional, Date]
  #   The user's birth date.
  #
  # @argument user[terms_of_use] [Optional, Boolean]
  #   Whether the user accepts the terms of use. Required if this is a
  #   self-registration and this canvas instance requires users to accept
  #   the terms (on by default).
  #
  # @argument pseudonym[unique_id] [String]
  #   User's login ID. If this is a self-registration, it must be a valid
  #   email address.
  #
  # @argument pseudonym[password] [Optional, String]
  #   User's password. Cannot be set during self-registration.
  #
  # @argument pseudonym[sis_user_id] [Optional, String]
  #   SIS ID for the user's account. To set this parameter, the caller must be
  #   able to manage SIS permissions.
  #
  # @argument pseudonym[send_confirmation] [Optional, Boolean]
  #   Send user notification of account creation if true.
  #   Automatically set to true during self-registration.
  #
  # @argument communication_channel[type] [Optional, String]
  #   The communication channel type, e.g. 'email' or 'sms'.
  #
  # @argument communication_channel[address] [Optional, String]
  #   The communication channel address, e.g. the user's email address.
  #
  # @argument skip_confirmation [Optional, Boolean]
  #   Only valid for site admins and account admins making requests; If true, the channel is
  #   automatically validated and no confirmation email or SMS is sent.
  #   Otherwise, the user must respond to a confirmation message to confirm the
  #   channel.
  #
  # @returns User
  def create
    # Look for an incomplete registration with this pseudonym
    @pseudonym = @context.pseudonyms.active.custom_find_by_unique_id(params[:pseudonym][:unique_id])
    # Setting it to nil will cause us to try and create a new one, and give user the login already exists error
    @pseudonym = nil if @pseudonym && !['creation_pending', 'pending_approval'].include?(@pseudonym.user.workflow_state)

    manage_user_logins = @context.grants_right?(@current_user, session, :manage_user_logins)
    self_enrollment = params[:self_enrollment].present?
    allow_non_email_pseudonyms = manage_user_logins || self_enrollment && params[:pseudonym_type] == 'username'
    require_password = self_enrollment && allow_non_email_pseudonyms
    allow_password = require_password || manage_user_logins

    notify = value_to_boolean(params[:pseudonym].delete(:send_confirmation))
    notify = :self_registration unless manage_user_logins

    if params[:communication_channel]
      cc_type = params[:communication_channel][:type] || CommunicationChannel::TYPE_EMAIL
      cc_addr = params[:communication_channel][:address]
      skip_confirmation = value_to_boolean(params[:communication_channel][:skip_confirmation]) &&
          (Account.site_admin.grants_right?(@current_user, :manage_students) || Account.default.grants_right?(@current_user, :manage_students))
    else
      cc_type = CommunicationChannel::TYPE_EMAIL
      cc_addr = params[:pseudonym].delete(:path) || params[:pseudonym][:unique_id]
    end

    sis_user_id = params[:pseudonym].delete(:sis_user_id)
    sis_user_id = nil unless @context.grants_right?(@current_user, session, :manage_sis)

    @user = @pseudonym && @pseudonym.user
    @user ||= User.new
    if params[:user]
      params[:user].delete(:self_enrollment_code) unless self_enrollment
      @user.attributes = params[:user]
    end
    @user.name ||= params[:pseudonym][:unique_id]
    unless @user.registered?
      @user.workflow_state = if require_password
        # no email confirmation required (self_enrollment_code and password
        # validations will ensure everything is legit)
        'registered'
      elsif notify == :self_registration && @user.registration_approval_required?
        'pending_approval'
      else
        'pre_registered'
      end
    end
    if !manage_user_logins # i.e. a new user signing up
      @user.require_acceptance_of_terms = @domain_root_account.terms_required?
      @user.require_presence_of_name = true
      @user.require_self_enrollment_code = self_enrollment
      @user.validation_root_account = @domain_root_account
    end
    
    @observee = nil
    if @user.initial_enrollment_type == 'observer'
      # TODO: SAML/CAS support
      if observee = Pseudonym.authenticate(params[:observee] || {},
          [@domain_root_account.id] + @domain_root_account.trusted_account_ids)
        @user.observed_users << observee.user unless @user.observed_users.include?(observee.user)
      else
        @observee = Pseudonym.new
        @observee.errors.add('unique_id', 'bad_credentials')
      end
    end

    @pseudonym ||= @user.pseudonyms.build(:account => @context)
    @pseudonym.account.email_pseudonyms = !allow_non_email_pseudonyms
    @pseudonym.require_password = require_password
    # pre-populate the reverse association
    @pseudonym.user = @user
    # don't require password_confirmation on api calls
    params[:pseudonym][:password_confirmation] = params[:pseudonym][:password] if api_request?
    # don't allow password setting for new users that are not self-enrolling
    # in a course (they need to go the email route)
    unless allow_password
      params[:pseudonym].delete(:password)
      params[:pseudonym].delete(:password_confirmation)
    end
    @pseudonym.attributes = params[:pseudonym]
    @pseudonym.sis_user_id = sis_user_id

    @pseudonym.account = @context
    @pseudonym.workflow_state = 'active'
    @cc =
      @user.communication_channels.where(:path_type => cc_type).by_path(cc_addr).first ||
      @user.communication_channels.build(:path_type => cc_type, :path => cc_addr)
    @cc.user = @user
    @cc.workflow_state = skip_confirmation ? 'active' : 'unconfirmed' unless @cc.workflow_state == 'confirmed'

    if @user.valid? && @pseudonym.valid? && @observee.nil?
      # saving the user takes care of the @pseudonym and @cc, so we can't call
      # save_without_session_maintenance directly. we don't want to auto-log-in
      # unless the user is registered/pre_registered (if the latter, he still
      # needs to confirm his email and set a password, otherwise he can't get
      # back in once his session expires)
      if !@current_user # automagically logged in
        PseudonymSession.new(@pseudonym).save unless @pseudonym.new_record?
      else
        @pseudonym.send(:skip_session_maintenance=, true)
      end
      @user.save!
      message_sent = false
      if notify == :self_registration
        unless @user.pending_approval? || @user.registered?
          message_sent = true
          @pseudonym.send_confirmation!
        end
        @user.new_registration((params[:user] || {}).merge({:remote_ip  => request.remote_ip, :cookies => cookies}))
      elsif notify && !@user.registered?
        message_sent = true
        @pseudonym.send_registration_notification!
      else
        @cc.send_merge_notification! if @cc.has_merge_candidates?
      end

      data = { :user => @user, :pseudonym => @pseudonym, :channel => @cc, :observee => @observee, :message_sent => message_sent, :course => @user.self_enrollment_course }
      if api_request?
        render(:json => user_json(@user, @current_user, session, %w{locale}))
      else
        render(:json => data)
      end
    else
      errors = {
        :errors => {
          :user => @user.errors.as_json[:errors],
          :pseudonym => @pseudonym ? @pseudonym.errors.as_json[:errors] : {},
          :observee => @observee ? @observee.errors.as_json[:errors] : {}
        }
      }
      render :json => errors, :status => :bad_request
    end
  end

  # @API Update user settings.
  # Update an existing user's settings.
  #
  # @argument manual_mark_as_read [Boolean]
  #   If true, require user to manually mark discussion posts as read (don't
  #   auto-mark as read).
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/settings \
  #     -X PUT \ 
  #     -F 'manual_mark_as_read=true'
  #     -H 'Authorization: Bearer <token>'
  def settings
    user = api_find(User, params[:id])

    case
    when request.get?
      return unless authorized_action(user, @current_user, :read)
      render(json: { manual_mark_as_read: @current_user.manual_mark_as_read? })
    when request.put?
      return unless authorized_action(user, @current_user, [:manage, :manage_user_details])
      unless params[:manual_mark_as_read].nil?
        mark_as_read = value_to_boolean(params[:manual_mark_as_read])
        user.preferences[:manual_mark_as_read] = mark_as_read
      end

      respond_to do |format|
        format.json {
          if user.save
            render(json: { manual_mark_as_read: user.manual_mark_as_read? })
          else
            render(json: user.errors, status: :bad_request)
          end
        }
      end
    end
  end

  # @API Edit a user
  # Modify an existing user. To modify a user's login, see the documentation for logins.
  #
  # @argument user[name] [Optional, String]
  #   The full name of the user. This name will be used by teacher for grading.
  #
  # @argument user[short_name] [Optional, String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [Optional, String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [Optional, String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [Optional, String]
  #   The user's preferred language as a two-letter ISO 639-1 code.
  #
  # @argument user[avatar][token] [Optional, String]
  #   A unique representation of the avatar record to assign as the user's
  #   current avatar. This token can be obtained from the user avatars endpoint.
  #   This supersedes the user[avatar][url] argument, and if both are included
  #   the url will be ignored. Note: this is an internal representation and is
  #   subject to change without notice. It should be consumed with this api
  #   endpoint and used in the user update endpoint, and should not be
  #   constructed by the client.
  #
  # @argument user[avatar][url] [Optional, String]
  #   To set the user's avatar to point to an external url, do not include a
  #   token and instead pass the url here. Warning: For maximum compatibility,
  #   please use 128 px square images.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/133.json' \
  #        -X PUT \ 
  #        -F 'user[name]=Sheldon Cooper' \ 
  #        -F 'user[short_name]=Shelly' \ 
  #        -F 'user[time_zone]=Pacific Time (US & Canada)' \ 
  #        -F 'user[avatar][token]=<opaque_token>' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @returns User
  def update
    params[:user] ||= {}
    @user = api_request? ?
      api_find(User, params[:id]) :
      params[:id] ? api_find(User, params[:id]) : @current_user

    if params[:default_pseudonym_id] && authorized_action(@user, @current_user, :manage)
      @default_pseudonym = @user.pseudonyms.find(params[:default_pseudonym_id])
      @default_pseudonym.move_to_top
    end

    managed_attributes = []
    managed_attributes.concat [:name, :short_name, :sortable_name] if @user.grants_right?(@current_user, nil, :rename)
    managed_attributes << :terms_of_use if @user == (@real_current_user || @current_user)
    if @user.grants_right?(@current_user, nil, :manage_user_details)
      managed_attributes.concat([:time_zone, :locale])
    end

    if @user.grants_right?(@current_user, nil, :update_avatar)
      avatar = params[:user].delete(:avatar)

      # delete any avatar_image passed, because we only allow updating avatars
      # based on [:avatar][:token].
      params[:user].delete(:avatar_image)

      managed_attributes << :avatar_image
      if token = avatar.try(:[], :token)
        if av_json = avatar_for_token(@user, token)
          params[:user][:avatar_image] = { :type => av_json['type'],
            :url => av_json['url'] }
        end
      elsif url = avatar.try(:[], :url)
        params[:user][:avatar_image] = { :type => 'external', :url => url }
      end
    end

    user_params = params[:user].slice(*managed_attributes)

    if user_params == params[:user]
      # admins can update avatar images even if they are locked
      admin_avatar_update = user_params[:avatar_image] &&
        @user.grants_right?(@current_user, nil, :update_avatar) &&
        @user.grants_right?(@current_user, nil, :manage_user_details)

      if admin_avatar_update
        old_avatar_state = @user.avatar_state
        @user.avatar_state = 'submitted'
      end

      if session[:require_terms]
        @user.require_acceptance_of_terms = true
      end

      respond_to do |format|
        if @user.update_attributes(user_params)
          if admin_avatar_update
            @user.avatar_state = (old_avatar_state == :locked ? old_avatar_state : 'approved')
            @user.save
          end
          session.delete(:require_terms)
          flash[:notice] = t('user_updated', 'User was successfully updated.')
          format.html { redirect_to user_url(@user) }
          format.json {
            render :json => user_json(@user, @current_user, session, %w{locale avatar_url},
              @current_user.pseudonym.account) }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @user.errors, :status => :bad_request }
        end
      end
    else
      render_unauthorized_action
    end
  end

  def media_download
    asset = Kaltura::ClientV3.new.media_sources(params[:entryId]).find{|a| a[:fileExt] == params[:type] }
    url = asset && asset[:url]
    if url
      if params[:redirect] == '1'
        redirect_to url
      else
        render :json => { 'url' => url }
      end
    else
      render :status => 404, :text => t('could_not_find_url', "Could not find download URL")
    end
  end

  def merge
    @user_about_to_go_away = User.find(params[:user_id])

    if params[:new_user_id] && @true_user = User.find_by_id(params[:new_user_id])
      if @true_user.grants_right?(@current_user, session, :manage_logins) && @user_about_to_go_away.grants_right?(@current_user, session, :manage_logins)
        @user_that_will_still_be_around = @true_user
      else
        @user_that_will_still_be_around = nil
      end
    else
      @user_that_will_still_be_around = @current_user
    end

    if @user_about_to_go_away && @user_that_will_still_be_around
      UserMerge.from(@user_about_to_go_away).into(@user_that_will_still_be_around)
      @user_that_will_still_be_around.touch
      flash[:notice] = t('user_merge_success', "User merge succeeded! %{first_user} and %{second_user} are now one and the same.", :first_user => @user_that_will_still_be_around.name, :second_user => @user_about_to_go_away.name)
    else
      flash[:error] = t('user_merge_fail', "User merge failed. Please make sure you have proper permission and try again.")
    end

    if @user_that_will_still_be_around == @current_user
      redirect_to user_profile_url(@current_user)
    elsif @user_that_will_still_be_around
      redirect_to user_url(@user_that_will_still_be_around)
    else
      redirect_to dashboard_url
    end
  end

  def admin_merge
    @user = User.find(params[:user_id])
    pending_other_error = get_pending_user_and_error(params[:pending_user_id])
    @other_user = User.find_by_id(params[:new_user_id]) if params[:new_user_id].present?
    if authorized_action(@user, @current_user, :manage_logins)
      flash[:error] = pending_other_error if pending_other_error.present?

      if @user && (params[:clear] || !@pending_other_user)
        @pending_other_user = nil
      end

      unless @other_user && @other_user.grants_right?(@current_user, session, :manage_logins)
        @other_user = nil
      end

      render :action => 'admin_merge'
    end
  end

  def get_pending_user_and_error(pending_user_id)
    pending_other_error = nil

    if pending_user_id.present?
      @pending_other_user = api_find_all(User, [pending_user_id]).first
      @pending_other_user = nil unless @pending_other_user.try(:grants_right?, @current_user, session, :manage_logins)
      if @pending_other_user == @user
        @pending_other_user = nil
        pending_other_error = t('cant_self_merge', "You can't merge an account with itself.")
      elsif @pending_other_user.blank? && pending_other_error.blank?
        pending_other_error = t('user_not_found', "No active user with that ID was found.")
      end
    end

    pending_other_error
  end

  def assignments_needing_grading
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :read)
      res = @user.assignments_needing_grading
      render :json => res
    end
  end

  def assignments_needing_submitting
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :read)
      render :json => @user.assignments_needing_submitting
    end
  end

  def mark_avatar_image
    if params[:remove]
      if authorized_action(@user, @current_user, :remove_avatar)
        @user.avatar_image = {}
        @user.save
        render :json => @user
      end
    else
      if !session["reported_#{@user.id}".to_sym]
        if params[:context_code]
          @context = Context.find_by_asset_string(params[:context_code]) rescue nil
          @context = nil unless context.respond_to?(:users) && context.users.find_by_id(@user.id)
        end
        @user.report_avatar_image!(@context)
      end
      session["reports_#{@user.id}".to_sym] = true
      render :json => {:reported => true}
    end
  end

  def delete
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, [:manage, :manage_logins])
      if @user.pseudonyms.any? {|p| p.managed_password? }
        unless @user.grants_right?(@current_user, session, :manage_logins)
          flash[:error] = t('no_deleting_sis_user', "You cannot delete a system-generated user")
          redirect_to user_profile_url(@current_user)
        end
      end
    end
  end

  # @API Delete a user
  #
  # Delete a user record from Canvas.
  #
  # WARNING: This API will allow a user to delete themselves. If you do this,
  # you won't be able to make API calls or log into Canvas.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/5 \ 
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>' \ 
  #       -X DELETE
  #
  # @returns User
  def destroy
    @user = api_find(User, params[:id])
    if authorized_action(@user, @current_user, [:manage, :manage_logins])
      @user.destroy(@user.grants_right?(@current_user, session, :manage_logins))
      if @user == @current_user
        logout_current_user
      end

      respond_to do |format|
        format.html do
          flash[:notice] = t('user_is_deleted', "%{user_name} has been deleted", :user_name => @user.name)
          redirect_to(@user == @current_user ? root_url : users_url)
        end

        format.json do
          get_context # need the context for user_json
          render :json => user_json(@user, @current_user, session)
        end
      end
    end
  end

  def report_avatar_image
    @user = User.find(params[:user_id])
    key = "reported_#{@user.id}"
    if !session[key]
      session[key] = true
      @user.report_avatar_image!
    end
    render :json => {:ok => true}
  end

  def update_avatar_image
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :remove_avatar)
      @user.avatar_state = params[:avatar][:state]
      @user.save
      render :json => @user.as_json(:include_root => false)
    end
  end

  def public_feed
    return unless get_feed_context(:only => [:user])
    feed = Atom::Feed.new do |f|
      f.title = "#{@context.name} Feed"
      f.links << Atom::Link.new(:href => dashboard_url, :rel => 'self')
      f.updated = Time.now
      f.id = user_url(@context)
    end
    @entries = []
    cutoff = 1.week.ago
    @context.courses.each do |context|
      @entries.concat context.assignments.active.where("updated_at>?", cutoff)
      @entries.concat context.calendar_events.active.where("updated_at>?", cutoff)
      @entries.concat context.discussion_topics.active.where("updated_at>?", cutoff)
      @entries.concat context.wiki.wiki_pages.not_deleted.where("updated_at>?", cutoff)
    end
    @entries.each do |entry|
      feed.entries << entry.to_atom(:include_context => true, :context => @context)
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def require_self_registration
    get_context
    @context = @domain_root_account || Account.default unless @context.is_a?(Account)
    @context = @context.root_account
    unless @context.grants_right?(@current_user, session, :manage_user_logins) ||
        @context.self_registration_allowed_for?(params[:user] && params[:user][:initial_enrollment_type])
      flash[:error] = t('no_self_registration', "Self registration has not been enabled for this account")
      respond_to do |format|
        format.html { redirect_to root_url }
        format.json { render :json => {}, :status => 403 }
      end
      return false
    end
  end

  def all_menu_courses
    render :json => Rails.cache.fetch(['menu_courses', @current_user].cache_key) {
      map_courses_for_menu(@current_user.courses_with_primary_enrollment)
    }
  end

  protected :require_self_registration

  def teacher_activity
    @teacher = User.find(params[:user_id])
    if @teacher == @current_user || authorized_action(@teacher, @current_user, :read_reports)
      @courses = {}

      if params[:student_id]
        student = User.find(params[:student_id])
        enrollments = student.student_enrollments.active.includes(:course).all
        enrollments.each do |enrollment|
          should_include = enrollment.course.user_has_been_instructor?(@teacher) && 
                           enrollment.course.enrollments_visible_to(@teacher, :include_priors => true).find_by_id(enrollment.id) &&
                           enrollment.course.grants_right?(@current_user, :read_reports)
          if should_include
            Enrollment.recompute_final_score_if_stale(enrollment.course, student) { enrollment.reload }
            @courses[enrollment.course] = teacher_activity_report(@teacher, enrollment.course, [enrollment])
          end
        end

        if @courses.all? { |c, e| e.blank? }
          flash[:error] = t('errors.no_teacher_courses', "There are no courses shared between this teacher and student")
          redirect_to_referrer_or_default(root_url)
        end

      else # implied params[:course_id]
        course = Course.find(params[:course_id])
        if !course.user_has_been_instructor?(@teacher)
          flash[:error] = t('errors.user_not_teacher', "That user is not a teacher in this course")
          redirect_to_referrer_or_default(root_url)
        elsif authorized_action(course, @current_user, :read_reports)
          Enrollment.recompute_final_score_if_stale(course)
          @courses[course] = teacher_activity_report(@teacher, course, course.enrollments_visible_to(@teacher, :include_priors => true))
        end
      end

    end
  end

  def avatar_image
    cancel_cache_buster
    # TODO: remove support for specifying user ids by id, require using
    # the encrypted version. We can't do it right away because there are
    # a bunch of places that will have cached fragments using the old
    # style.
    return redirect_to(params[:fallback] || '/images/no_pic.gif') unless service_enabled?(:avatars)
    user_id = params[:user_id].to_i
    if params[:user_id].present? && params[:user_id].match(/-/)
      user_id = User.user_id_from_avatar_key(params[:user_id])
    end
    account_avatar_setting = service_enabled?(:avatars) ? @domain_root_account.settings[:avatars] || 'enabled' : 'disabled'
    user_id, user_shard = Shard.local_id_for(user_id)
    user_shard ||= Shard.current
    url = user_shard.activate do
      Rails.cache.fetch(Cacher.avatar_cache_key(user_id, account_avatar_setting)) do
        user = User.find_by_id(user_id) if user_id.present?
        if user
          user.avatar_url(nil, account_avatar_setting, "%{fallback}")
        else
          '%{fallback}'
        end
      end
    end
    fallback = User.avatar_fallback_url(params[:fallback], request)
    redirect_to (url.blank? || url == "%{fallback}") ?
      fallback :
      url.sub(CGI.escape("%{fallback}"), CGI.escape(fallback))
  end

  # @API Merge user into another user
  #
  # Merge a user into another user.
  # To merge users, the caller must have permissions to manage both users.
  #
  # When finding users by SIS ids in different accounts the
  # destination_account_id is required.
  #
  # The account can also be identified by passing the domain in destination_account_id.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/merge_into/<destination_user_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/merge_into/accounts/<destination_account_id>/users/<destination_user_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def merge_into
    user = api_find(User, params[:id])
    if authorized_action(user, @current_user, :manage_logins)

      if (account_id = params[:destination_account_id])
        destination_account = Account.find_by_domain(account_id)
        destination_account ||= Account.find(account_id)
      else
        destination_account ||= @domain_root_account
      end

      into_user = api_find(User, params[:destination_user_id], account: destination_account)

      if authorized_action(into_user, @current_user, :manage_logins)
        UserMerge.from(user).into into_user
        render(:json => user_json(into_user,
                                  @current_user,
                                  session,
                                  %w{locale},
                                  destination_account))
      end
    end
  end

  protected

  def teacher_activity_report(teacher, course, student_enrollments)
    ids = student_enrollments.map(&:user_id)
    data = {}
    student_enrollments.each { |e| data[e.user.id] = { :enrollment => e, :ungraded => [] } }

    # find last interactions
    last_comment_dates = SubmissionComment.for_context(course).
        group(:recipient_id).
        where("author_id = ? AND recipient_id IN (?)", teacher, ids).
        maximum(:created_at)
    last_comment_dates.each do |user_id, date|
      next unless student = data[user_id]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end
    scope = ConversationMessage.
        joins('INNER JOIN conversation_participants ON conversation_participants.conversation_id=conversation_messages.conversation_id').
        where('conversation_messages.author_id = ? AND conversation_participants.user_id IN (?) AND NOT conversation_messages.generated', teacher, ids)
    # fake_arel can't pass an array in the group by through the scope
    last_message_dates = CANVAS_RAILS2 ?
        scope.maximum(:created_at, :group => ['conversation_participants.user_id', 'conversation_messages.author_id']) :
        scope.group(['conversation_participants.user_id', 'conversation_messages.author_id']).maximum(:created_at)
    last_message_dates.each do |key, date|
      next unless student = data[key.first.to_i]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end

    # find all ungraded submissions in one query
    ungraded_submissions = course.submissions.
        includes(:assignment).
        where("user_id IN (?) AND #{Submission.needs_grading_conditions}", ids).
        all
    ungraded_submissions.each do |submission|
      next unless student = data[submission.user_id]
      student[:ungraded] << submission
    end

    if course.root_account.enable_user_notes?
      data.each { |k,v| v[:last_user_note] = nil }
      # find all last user note times in one query
      note_dates = UserNote.active.
          group(:user_id).
          where("created_by_id = ? AND user_id IN (?)", teacher, ids).
          maximum(:created_at)
      note_dates.each do |user_id, date|
        next unless student = data[user_id]
        student[:last_user_note] = date
      end
    end

    Canvas::ICU.collate_by(data.values) { |e| e[:enrollment].user.sortable_name }
  end
end
