#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require 'atom'

# @API Users
# API for accessing information on the current and other users.
#
# Throughout this API, the `:user_id` parameter can be replaced with `self` as
# a shortcut for the id of the user accessing the API. For instance,
# `users/:user_id/page_views` can be accessed as `users/self/page_views` to
# access the current user's page views.
#
# @model UserDisplay
#     {
#       "id": "UserDisplay",
#       "description": "This mini-object is used for secondary user responses, when we just want to provide enough information to display a user.",
#       "properties": {
#         "id": {
#           "description": "The ID of the user.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "short_name": {
#           "description": "A short name the user has selected, for use in conversations or other less formal places through the site.",
#           "example": "Shelly",
#           "type": "string"
#         },
#         "avatar_image_url": {
#           "description": "If avatars are enabled, this field will be included and contain a url to retrieve the user's avatar.",
#           "example": "https://en.gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "URL to access user, either nested to a context or directly.",
#           "example": "https://school.instructure.com/courses/:course_id/users/:user_id",
#           "type": "string"
#         }
#       }
#     }
#
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
#           "type": "integer",
#           "format": "int64"
#         },
#         "sis_login_id": {
#           "description": "DEPRECATED: The SIS login ID associated with the user. Please use the sis_user_id or login_id. This field will be removed in a future version of the API.",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "The integration_id associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
#           "example": "ABC59802",
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
#           "description": "Optional: This field can be requested with certain API calls, and will return the users locale in RFC 5646 format.",
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
#           "description": "Optional: This field is only returned in certain API calls, and will return the IANA time zone name of the user's preferred timezone.",
#           "example": "America/Denver",
#           "type": "string"
#         },
#         "bio": {
#           "description": "Optional: The user's bio.",
#           "example": "I like the Muppets.",
#           "type": "string"
#         }
#       }
#     }
#
#
#
class UsersController < ApplicationController
  include Delicious
  include SearchHelper
  include SectionTabHelper
  include I18nUtilities
  include CustomColorHelper

  before_filter :require_user, :only => [:grades, :merge, :kaltura_session,
    :ignore_item, :ignore_stream_item, :close_notification, :mark_avatar_image,
    :user_dashboard, :toggle_recent_activity_dashboard, :masquerade, :external_tool,
    :dashboard_sidebar, :settings, :all_menu_courses, :activity_stream, :activity_stream_summary]
  before_filter :require_registered_user, :only => [:delete_user_service,
    :create_user_service]
  before_filter :reject_student_view_student, :only => [:delete_user_service,
    :create_user_service, :merge, :user_dashboard, :masquerade]
  skip_before_filter :load_user, :only => [:create_self_registered_user]
  before_filter :require_self_registration, :only => [:new, :create, :create_self_registered_user]

  def grades
    @user = User.where(id: params[:user_id]).first if params[:user_id].present?
    @user ||= @current_user
    if authorized_action(@user, @current_user, :read_grades)
      crumb_url = polymorphic_url([@current_user]) if @user.grants_right?(@current_user, session, :view_statistics)
      add_crumb(@current_user.short_name, crumb_url)
      add_crumb(t('crumbs.grades', 'Grades'), grades_path)

      current_active_enrollments = @user.enrollments.current.preload(:course, :enrollment_state).shard(@user).to_a

      @presenter = GradesPresenter.new(current_active_enrollments)

      if @presenter.has_single_enrollment?
        redirect_to course_grades_url(@presenter.single_enrollment.course_id)
        return
      end

      @grading_periods = collected_grading_periods_for_presenter(
        @presenter, params[:course_id], params[:grading_period_id])
      @grades = grades_for_presenter(@presenter, @grading_periods)
      js_env :grades_for_student_url => grades_for_student_url

      ActiveRecord::Associations::Preloader.new.preload(@observed_enrollments, :course)
    end
  end

  def grades_for_student
    enrollment = Enrollment.active.find(params[:enrollment_id])
    return render_unauthorized_action unless enrollment.grants_right?(@current_user, session, :read_grades)

    course = enrollment.course
    grading_period_id = params[:grading_period_id].to_i
    grading_period = GradingPeriod.for(course).find_by(id: grading_period_id)
    grading_periods = {
      course.id => {
        periods: [grading_period],
        selected_period_id: grading_period_id
      }
    }
    calculator = grade_calculator([enrollment.user_id], course, grading_periods)
    totals = calculator.compute_scores.first[:current]
    totals[:hide_final_grades] = course.hide_final_grades?
    render json: totals
  end

  def oauth
    if !feature_and_service_enabled?(params[:service])
      flash[:error] = t('service_not_enabled', "That service has not been enabled")
      return redirect_to(user_profile_url(@current_user))
    end
    return_to_url = params[:return_to] || user_profile_url(@current_user)
    if params[:service] == "google_drive"
      redirect_uri = oauth_success_url(:service => 'google_drive')
      session[:oauth_gdrive_nonce] = SecureRandom.hex
      state = Canvas::Security.create_jwt(redirect_uri: redirect_uri, return_to_url: return_to_url, nonce: session[:oauth_gdrive_nonce])
      redirect_to GoogleDrive::Client.auth_uri(google_drive_client, state)
    elsif params[:service] == "twitter"
      success_url = oauth_success_url(:service => 'twitter')
      request_token = Twitter::Connection.request_token(success_url)
      OauthRequest.create(
        :service => 'twitter',
        :token => request_token.token,
        :secret => request_token.secret,
        :return_url => return_to_url,
        :user => @current_user,
        :original_host_with_port => request.host_with_port
      )
      redirect_to request_token.authorize_url
    elsif params[:service] == "linked_in"
      linkedin_connection = LinkedIn::Connection.new

      request_token = linkedin_connection.request_token(oauth_success_url(:service => 'linked_in'))

      session[:oauth_linked_in_request_token_token] = request_token.token
      session[:oauth_linked_in_request_token_secret] = request_token.secret
      OauthRequest.create(
        :service => 'linked_in',
        :token => request_token.token,
        :secret => request_token.secret,
        :return_url => return_to_url,
        :user => @current_user,
        :original_host_with_port => request.host_with_port
      )

      redirect_to request_token.authorize_url
    end
  end

  def oauth_success
    oauth_request = nil
    if params[:oauth_token]
      oauth_request = OauthRequest.where(token: params[:oauth_token], service: params[:service]).first
    elsif params[:code] &&  params[:state] && params[:service] == 'google_drive'

      begin

        client = google_drive_client
        client.authorization.code = params[:code]
        client.authorization.fetch_access_token!

        # we should look into consolidating this and connection.rb
        drive = Rails.cache.fetch(['google_drive_v2'].cache_key) do
          client.discovered_api('drive', 'v2')
        end

        result = client.execute!(:api_method => drive.about.get)

        if result.status == 200
          user_info = result.data
        else
          raise "Error getting user info from Google"
        end

        json = Canvas::Security.decode_jwt(params[:state])
        render_unauthorized_action and return unless json['nonce'] && json['nonce'] == session[:oauth_gdrive_nonce]
        session.delete(:oauth_gdrive_nonce)

        if logged_in_user
          UserService.register(
            :service => "google_drive",
            :service_domain => "drive.google.com",
            :token => client.authorization.refresh_token,
            :secret => client.authorization.access_token,
            :user => logged_in_user,
            :service_user_id => user_info['permissionId'],
            :service_user_name => user_info['user']['emailAddress']
          )
        else
          session[:oauth_gdrive_access_token] = client.authorization.access_token
          session[:oauth_gdrive_refresh_token] = client.authorization.refresh_token
        end

        flash[:notice] = t('google_drive_added', "Google Drive account successfully added!")
        return redirect_to(json['return_to_url'])
      rescue Google::APIClient::ClientError => e
        Canvas::Errors.capture_exception(:oauth, e)

        flash[:error] = e.to_s
      end
      return redirect_to(user_profile_url(@current_user))
    end

    if !oauth_request || (request.host_with_port == oauth_request.original_host_with_port && oauth_request.user != @current_user)
      flash[:error] = t('oauth_fail', "OAuth Request failed. Couldn't find valid request")
      redirect_to (@current_user ? user_profile_url(@current_user) : root_url)
    elsif request.host_with_port != oauth_request.original_host_with_port
      url = url_for request.parameters.merge(:host => oauth_request.original_host_with_port, :only_path => false)
      redirect_to url
    else
     if params[:service] == "linked_in"
        begin
          linkedin_connection = LinkedIn::Connection.new
          token = session.delete(:oauth_linked_in_request_token_token)
          secret = session.delete(:oauth_linked_in_request_token_secret)
          access_token = linkedin_connection.get_access_token(token, secret, params[:oauth_verifier])
          service_user_id, service_user_name, service_user_url = linkedin_connection.get_service_user_info(access_token)

          if oauth_request.user
            UserService.register(
              :service => "linked_in",
              :access_token => access_token,
              :user => oauth_request.user,
              :service_domain => "linked_in.com",
              :service_user_id => service_user_id,
              :service_user_name => service_user_name,
              :service_user_url => service_user_url
            )
          else
            session[:oauth_linked_in_access_token_token] = access_token.token
            session[:oauth_linked_in_access_token_secret] = access_token.secret
          end

          flash[:notice] = t('linkedin_added', "LinkedIn account successfully added!")
        rescue => e
          Canvas::Errors.capture_exception(:oauth, e)
          flash[:error] = t('linkedin_fail', "LinkedIn authorization failed. Please try again")
        end
      else
        begin
          twitter = Twitter::Connection.new(oauth_request.token, oauth_request.secret)
          access_token = twitter.get_access_token(oauth_request.token, oauth_request.secret, params[:oauth_verifier])
          service_user_id, service_user_name = twitter.get_service_user(access_token)
          if oauth_request.user
            UserService.register(
              :service => "twitter",
              :access_token => access_token,
              :user => oauth_request.user,
              :service_domain => "twitter.com",
              :service_user_id => service_user_id,
              :service_user_name => service_user_name
            )
            oauth_request.destroy
          else
            session[:oauth_twitter_access_token_token] = access_token.token
            session[:oauth_twitter_access_token_secret] = access_token.secret
          end

          flash[:notice] = t('twitter_added', "Twitter access authorized!")
        rescue => e
          Canvas::Errors.capture_exception(:oauth, e)
          flash[:error] = t('twitter_fail_whale', "Twitter authorization failed. Please try again")
        end
      end
      return_to(oauth_request.return_url, user_profile_url(@current_user))
    end
  end

  # @API List users in account
  # Retrieve the list of users associated with this account.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the
  #   results list. Must be at least 3 characters.
  #
  #   Note that the API will prefer matching on canonical user ID if the ID has
  #   a numeric form. It will only search against other fields if non-numeric
  #   in form, or if the numeric value doesn't yield any matches. Queries by
  #   administrative users will search on SIS ID, name, or email address; non-
  #   administrative queries will only be compared against name.
  #
  #  @example_request
  #    curl https://<canvas>/api/v1/accounts/self/users?search_term=<search value> \
  #       -X GET \
  #       -H 'Authorization: Bearer <token>'
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
                where(Enrollment::QueryBuilder.new(:active).conditions).
                where(courses: { enrollment_term_id: params[:enrollment_term_id]}))
        elsif !api_request?
          @users = @context.fast_all_users
        end

        if api_request?
          search_term = params[:search_term].presence
          page_opts = {}
          if search_term
            users = UserSearch.for_user_in_context(search_term, @context, @current_user, session)
            page_opts[:total_entries] = nil # doesn't calculate a total count
          else
            users = UserSearch.scope_for(@context, @current_user)
          end

          includes = (params[:include] || []) & %w{avatar_url email last_login time_zone}
          users = users.with_last_login if includes.include?('last_login')
          users = Api.paginate(users, self, api_v1_account_users_url, page_opts)
          user_json_preloads(users, includes.include?('email'))
          return render :json => users.map { |u| user_json(u, @current_user, session, includes)}
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
        session.delete(:enrollment_uuid)
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
    session.delete(:parent_registration) if session[:parent_registration]
    check_incomplete_registration
    get_context

    # dont show crumbs on dashboard because it does not make sense to have a breadcrumb
    # trail back to home if you are already home
    clear_crumbs

    @show_footer = true

    if request.path =~ %r{\A/dashboard\z}
      return redirect_to(dashboard_url, :status => :moved_permanently)
    end
    disable_page_views if @current_pseudonym && @current_pseudonym.unique_id == "pingdom@instructure.com"

    js_env({
      :DASHBOARD_SIDEBAR_URL => dashboard_sidebar_url,
      :PREFERENCES => {
        :recent_activity_dashboard => @current_user.preferences[:recent_activity_dashboard],
        :custom_colors => @current_user.custom_colors
      }
    })

    @announcements = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
    @pending_invitations = @current_user.cached_invitations(:include_enrollment_uuid => session[:enrollment_uuid], :preload_course => true)
    @stream_items = @current_user.try(:cached_recent_stream_items) || []
  end

  def cached_upcoming_events(user)
    Rails.cache.fetch(['cached_user_upcoming_events', user].cache_key,
      :expires_in => 3.minutes) do
      user.upcoming_events :context_codes => ([user.asset_string] + user.cached_context_codes)
    end
  end

  def cached_submissions(user, upcoming_events)
    Rails.cache.fetch(['cached_user_submissions2', user].cache_key,
      :expires_in => 3.minutes) do
      assignments = upcoming_events.select{ |e| e.is_a?(Assignment) }
      Shard.partition_by_shard(assignments) do |shard_assignments|
        Submission.
          select([:id, :assignment_id, :score, :grade, :workflow_state, :updated_at]).
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

      if @show_recent_feedback = (@current_user.student_enrollments.active.exists?)
        @recent_feedback = (@current_user && @current_user.recent_feedback) || []
      end
    end

    render :layout => false
  end

  def toggle_recent_activity_dashboard
    @current_user.preferences[:recent_activity_dashboard] =
      !@current_user.preferences[:recent_activity_dashboard]
    @current_user.save!
    render json: {}
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
  #     'type': 'DiscussionTopic|Conversation|Message|Submission|Conference|Collaboration|AssessmentRequest...',
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
  #
  # AssessmentRequest:
  #
  #   !!!javascript
  #   {
  #     'type': 'AssessmentRequest',
  #     'assessment_request_id': 1234
  #   }
  def activity_stream
    if @current_user
      # this endpoint has undocumented params (context_code, submission_user_id and asset_type) to
      # support submission comments in the conversations inbox.
      # please replace this with a more reasonable solution at your earliest convenience
      opts = {paginate_url: :api_v1_user_activity_stream_url}
      opts[:asset_type] = params[:asset_type] if params.has_key?(:asset_type)
      opts[:context] = Context.find_by_asset_string(params[:context_code]) if params[:context_code]
      opts[:submission_user_id] = params[:submission_user_id] if params.has_key?(:submission_user_id)
      api_render_stream(opts)
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
    @courses = @courses.select("courses.*,#{Course.best_unicode_collation_key('name')} AS sort_key").order('sort_key')

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
  # @argument include[] [String, "ungraded_quizzes"]
  #   "ungraded_quizzes":: Optionally include ungraded quizzes (such as practice quizzes and surveys) in the list.
  #                        These will be returned under a +quiz+ key instead of an +assignment+ key in response elements.
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
  #     },
  #     {
  #       'type' => 'submitting',   // a quiz that needs submitting soon
  #       'quiz' => { .. quiz object .. },
  #       'ignore' => '.. url ..',
  #       'ignore_permanently' => '.. url ..',
  #       'html_url': '.. url ..',
  #       'context_type': 'course',
  #       'course_id': 1,
  #     },
  #   ]
  def todo_items
    return render_unauthorized_action unless @current_user

    grading = @current_user.assignments_needing_grading().map { |a| todo_item_json(a, @current_user, session, 'grading') }
    submitting = @current_user.assignments_needing_submitting(include_ungraded: true).map { |a| todo_item_json(a, @current_user, session, 'submitting') }
    if Array(params[:include]).include? 'ungraded_quizzes'
      submitting += @current_user.ungraded_quizzes_needing_submitting.map { |q| todo_item_json(q, @current_user, session, 'submitting') }
      submitting.sort_by! { |j| (j[:assignment] || j[:quiz])[:due_at] }
    end
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

  # @API List Missing Submissions
  # returns past-due assignments for which the student does not have a submission.
  # The user sending the request must either be an admin or a parent observer using the parent app
  #
  # @argument user_id
  #   the student's ID
  #
  # @returns [Assignment]
  def missing_submissions
    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless @current_user && user.grants_right?(@current_user, :read)

    assignments = []
    Shackles.activate(:slave) do
      preloaded_submitted_assignment_ids = user.submissions.pluck(:assignment_id)
      assignments = user.assignments_needing_submitting due_before: Time.zone.now
      assignments.reject {|as| preloaded_submitted_assignment_ids.include? as.id }
    end

    render json: assignments.map {|as| assignment_json(as, user, session) }
  end

  def ignore_item
    unless %w[grading submitting reviewing moderation].include?(params[:purpose])
      return render(:json => { :ignored => false }, :status => 400)
    end
    @current_user.ignore_item!(ActiveRecord::Base.find_by_asset_string(params[:asset_string], ['Assignment', 'AssessmentRequest', 'Quizzes::Quiz']),
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
    if deleted.service == "google_drive"
      Rails.cache.delete(['google_drive_tokens', @current_user].cache_key)
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
          Diigo::Connection.diigo_get_bookmarks(service)
        when 'skype'
          true
        when 'yo'
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
    @service = @current_user.user_services.where(type: 'BookmarkService', service: params[:service_type]).first rescue nil
    res = nil
    res = @service.find_bookmarks(params[:q]) if @service
    render :json => res
  end

  def show
    get_context
    @context_account = @context.is_a?(Account) ? @context : @domain_root_account
    @user = params[:id] && params[:id] != 'self' ? User.find(params[:id]) : @current_user
    if authorized_action(@user, @current_user, :read_full_profile)
      add_crumb(t('crumbs.profile', "%{user}'s profile", :user => @user.short_name), @user == @current_user ? user_profile_path(@current_user) : user_path(@user) )

      @group_memberships = @user.current_group_memberships

      # course_section and enrollment term will only be used if the enrollment dates haven't been cached yet;
      # maybe should just look at the first enrollment and check if it's cached to decide if we should include
      # them here
      @enrollments = @user.enrollments.
        shard(@user).
        where("enrollments.workflow_state<>'deleted' AND courses.workflow_state<>'deleted'").
        eager_load(:course).
        preload(:associated_user, :course_section, :enrollment_state, course: { enrollment_term: :enrollment_dates_overrides }).to_a

      # restrict view for other users
      if @user != @current_user
        @enrollments = @enrollments.select{|e| e.grants_right?(@current_user, session, :read)}
      end

      @enrollments = @enrollments.sort_by {|e| [e.state_sortable, e.rank_sortable, e.course.name] }
      # pre-populate the reverse association
      @enrollments.each { |e| e.user = @user }

      respond_to do |format|
        format.html
        format.json {
          render :json => user_json(@user, @current_user, session, %w{locale avatar_url},
                                    @current_user.pseudonym.account) }
      end
    end
  end

  # @API Show user details
  #
  # Shows details for user.
  #
  # Also includes an attribute "permissions", a non-comprehensive list of permissions for the user.
  # Example:
  #   !!!javascript
  #   "permissions": {
  #    "can_update_name": true, // Whether the user can update their name.
  #    "can_update_avatar": false // Whether the user can update their avatar.
  #   }
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/self \
  #       -X GET \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def api_show
    @user = api_find(User, params[:id])
    if @user.grants_any_right?(@current_user, session, :manage, :manage_user_details)
      render :json => user_json(@user, @current_user, session, %w{locale avatar_url permissions}, @current_user.pseudonym.account)
    else
      render_unauthorized_action
    end
  end

  def external_tool
    @tool = ContextExternalTool.find_for(params[:id], @domain_root_account, :user_navigation)
    @opaque_id = @tool.opaque_identifier_for(@current_user)
    @resource_type = 'user_navigation'

    success_url = user_profile_url(@current_user)
    @return_url = named_context_url(@current_user, :context_external_content_success_url, 'external_tool_redirect', {include_host: true})
    @redirect_return = true
    js_env(:redirect_return_success_url => success_url,
           :redirect_return_cancel_url => success_url)

    @lti_launch = @tool.settings['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    opts = {
        resource_type: @resource_type,
        link_code: @opaque_id
    }
    variable_expander = Lti::VariableExpander.new(@domain_root_account, @context, self,{
                                                                        current_user: @current_user,
                                                                        current_pseudonym: @current_pseudonym,
                                                                        tool: @tool})
    adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @domain_root_account).prepare_tool_launch(@return_url, variable_expander,  opts)
    @lti_launch.params = adapter.generate_post_payload

    @lti_launch.resource_url = @tool.user_navigation(:url)
    @lti_launch.link_text = @tool.label_for(:user_navigation, I18n.locale)
    @lti_launch.analytics_id = @tool.tool_id

    @active_tab = @tool.asset_string
    add_crumb(@current_user.short_name, user_profile_path(@current_user))
    render Lti::AppUtil.display_template
  end

  def new
    return redirect_to(root_url) if @current_user
    run_login_hooks
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
  # @argument user[name] [String]
  #   The full name of the user. This name will be used by teacher for grading.
  #   Required if this is a self-registration.
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[birthdate] [Date]
  #   The user's birth date.
  #
  # @argument user[terms_of_use] [Boolean]
  #   Whether the user accepts the terms of use. Required if this is a
  #   self-registration and this canvas instance requires users to accept
  #   the terms (on by default).
  #
  #   If this is true, it will mark the user as having accepted the terms of use.
  #
  # @argument user[skip_registration] [Boolean]
  #   Automatically mark the user as registered.
  #
  #   If this is true, it is recommended to set <tt>"pseudonym[send_confirmation]"</tt> to true as well.
  #   Otherwise, the user will not receive any messages about their account creation.
  #
  #   The users communication channel confirmation can be skipped by setting
  #   <tt>"communication_channel[skip_confirmation]"</tt> to true as well.
  #
  # @argument pseudonym[unique_id] [Required, String]
  #   User's login ID. If this is a self-registration, it must be a valid
  #   email address.
  #
  # @argument pseudonym[password] [String]
  #   User's password. Cannot be set during self-registration.
  #
  # @argument pseudonym[sis_user_id] [String]
  #   SIS ID for the user's account. To set this parameter, the caller must be
  #   able to manage SIS permissions.
  #
  # @argument pseudonym[integration_id] [String]
  #   Integration ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions. The Integration ID is a secondary
  #   identifier useful for more complex SIS integrations.
  #
  # @argument pseudonym[send_confirmation] [Boolean]
  #   Send user notification of account creation if true.
  #   Automatically set to true during self-registration.
  #
  # @argument pseudonym[force_self_registration] [Boolean]
  #   Send user a self-registration style email if true.
  #   Setting it means the users will get a notification asking them
  #   to "complete the registration process" by clicking it, setting
  #   a password, and letting them in.  Will only be executed on
  #   if the user does not need admin approval.
  #   Defaults to false unless explicitly provided.
  #
  # @argument pseudonym[authentication_provider_id] [String]
  #   The authentication provider this login is associated with. Logins
  #   associated with a specific provider can only be used with that provider.
  #   Legacy providers (LDAP, CAS, SAML) will search for logins associated with
  #   them, or unassociated logins. New providers will only search for logins
  #   explicitly associated with them. This can be the integer ID of the
  #   provider, or the type of the provider (in which case, it will find the
  #   first matching provider).
  #
  # @argument communication_channel[type] [String]
  #   The communication channel type, e.g. 'email' or 'sms'.
  #
  # @argument communication_channel[address] [String]
  #   The communication channel address, e.g. the user's email address.
  #
  # @argument communication_channel[confirmation_url] [Boolean]
  #   Only valid for account admins. If true, returns the new user account
  #   confirmation URL in the response.
  #
  # @argument communication_channel[skip_confirmation] [Boolean]
  #   Only valid for site admins and account admins making requests; If true, the channel is
  #   automatically validated and no confirmation email or SMS is sent.
  #   Otherwise, the user must respond to a confirmation message to confirm the
  #   channel.
  #
  #   If this is true, it is recommended to set <tt>"pseudonym[send_confirmation]"</tt> to true as well.
  #   Otherwise, the user will not receive any messages about their account creation.
  #
  # @argument force_validations [Boolean]
  #   If true, validations are performed on the newly created user (and their associated pseudonym)
  #   even if the request is made by a privileged user like an admin. When set to false,
  #   or not included in the request parameters, any newly created users are subject to
  #   validations unless the request is made by a user with a 'manage_user_logins' right.
  #   In which case, certain validations such as 'require_acceptance_of_terms' and
  #   'require_presence_of_name' are not enforced. Use this parameter to return helpful json
  #   errors while building users with an admin request.
  #
  # @argument enable_sis_reactivation [Boolean]
  #   When true, will first try to re-activate a deleted user with matching sis_user_id if possible.
  #
  # @returns User
  def create
    create_user
  end

  # @API Self register a user
  # Self register and return a new user and pseudonym for an account.
  #
  # If self-registration is enabled on the account, you can use this
  # endpoint to self register new users.
  #
  # @argument user[name] [Required, String]
  #   The full name of the user. This name will be used by teacher for grading.
  #
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[birthdate] [Date]
  #   The user's birth date.
  #
  # @argument user[terms_of_use] [Required, Boolean]
  #   Whether the user accepts the terms of use.
  #
  # @argument pseudonym[unique_id] [Required, String]
  #   User's login ID. Must be a valid email address.
  #
  # @argument communication_channel[type] [String]
  #   The communication channel type, e.g. 'email' or 'sms'.
  #
  # @argument communication_channel[address] [String]
  #   The communication channel address, e.g. the user's email address.
  #
  # @returns User
  def create_self_registered_user
    create_user
  end

  # @API Update user settings.
  # Update an existing user's settings.
  #
  # @argument manual_mark_as_read [Boolean]
  #   If true, require user to manually mark discussion posts as read (don't
  #   auto-mark as read).
  #
  # @argument collapse_global_nav [Boolean]
  #   If true, the user's page loads with the global navigation collapsed
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
      render(json: {
        manual_mark_as_read: @current_user.manual_mark_as_read?,
        collapse_global_nav: @current_user.collapse_global_nav?
      })
    when request.put?
      return unless authorized_action(user, @current_user, [:manage, :manage_user_details])
      unless params[:manual_mark_as_read].nil?
        mark_as_read = value_to_boolean(params[:manual_mark_as_read])
        user.preferences[:manual_mark_as_read] = mark_as_read
      end
      unless params[:collapse_global_nav].nil?
        collapse_global_nav = value_to_boolean(params[:collapse_global_nav])
        user.preferences[:collapse_global_nav] = collapse_global_nav
      end

      respond_to do |format|
        format.json {
          if user.save
            render(json: {
              manual_mark_as_read: user.manual_mark_as_read?,
              collapse_global_nav: user.collapse_global_nav?
            })
          else
            render(json: user.errors, status: :bad_request)
          end
        }
      end
    end
  end

  # @API Get custom colors
  # Returns all custom colors that have been saved for a user.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/ \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "custom_colors": {
  #       "course_42": "#abc123",
  #       "course_88": "#123abc"
  #     }
  #   }
  #
  def get_custom_colors
    user = api_find(User, params[:id])
    return unless authorized_action(user, @current_user, :read)
    render(json: {custom_colors: user.custom_colors})
  end

  # @API Get custom color
  # Returns the custom colors that have been saved for a user for a given context.
  #
  # The asset_string parameter should be in the format 'context_id', for example
  # 'course_42'.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/<asset_string> \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "hexcode": "#abc123"
  #   }
  def get_custom_color
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, :read)

    if user.custom_colors[params[:asset_string]].nil?
      raise(ActiveRecord::RecordNotFound, "Asset does not have an associated color.")
    end
    render(json: { hexcode: user.custom_colors[params[:asset_string]]})
  end



  # @API Update custom color
  # Updates a custom color for a user for a given context.  This allows
  # colors for the calendar and elsewhere to be customized on a user basis.
  #
  # The asset string parameter should be in the format 'context_id', for example
  # 'course_42'
  #
  # @argument hexcode [String]
  #   The hexcode of the color to set for the context, if you choose to pass the
  #   hexcode as a query parameter rather than in the request body you should
  #   NOT include the '#' unless you escape it first.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/<user_id>/colors/<asset_string> \
  #     -X PUT \
  #     -F 'hexcode=fffeee'
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "hexcode": "#abc123"
  #   }
  def set_custom_color
    user = api_find(User, params[:id])

    return unless authorized_action(user, @current_user, [:manage, :manage_user_details])

    # Make sure the user has rights to the actual context used.
    context = Context.find_by_asset_string(params[:asset_string])

    if context.nil?
      raise(ActiveRecord::RecordNotFound, "Asset does not exist")
    end

    return unless authorized_action(context, @current_user, :read)

    # Check if the hexcode is valid
    unless valid_hexcode?(params[:hexcode])
      return render(json: { :message => "Invalid Hexcode Provided" }, status: :bad_request)
    end

    unless params[:hexcode].nil?
      user.custom_colors[params[:asset_string]] = normalize_hexcode(params[:hexcode])
    end

    respond_to do |format|
      format.json do
        if user.save
          render(json: { hexcode: user.custom_colors[params[:asset_string]]})
        else
          render(json: user.errors, status: :bad_request)
        end
      end
    end
  end

  # @API Edit a user
  # Modify an existing user. To modify a user's login, see the documentation for logins.
  #
  # @argument user[name] [String]
  #   The full name of the user. This name will be used by teacher for grading.
  #
  # @argument user[short_name] [String]
  #   User's name as it will be displayed in discussions, messages, and comments.
  #
  # @argument user[sortable_name] [String]
  #   User's name as used to sort alphabetically in lists.
  #
  # @argument user[time_zone] [String]
  #   The time zone for the user. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument user[email] [String]
  #   The default email address of the user.
  #
  # @argument user[locale] [String]
  #   The user's preferred language, from the list of languages Canvas supports.
  #   This is in RFC-5646 format.
  #
  # @argument user[avatar][token] [String]
  #   A unique representation of the avatar record to assign as the user's
  #   current avatar. This token can be obtained from the user avatars endpoint.
  #   This supersedes the user [avatar] [url] argument, and if both are included
  #   the url will be ignored. Note: this is an internal representation and is
  #   subject to change without notice. It should be consumed with this api
  #   endpoint and used in the user update endpoint, and should not be
  #   constructed by the client.
  #
  # @argument user[avatar][url] [String]
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

    update_email = @user.grants_right?(@current_user, :manage_user_details) && params[:user][:email]
    managed_attributes = []
    managed_attributes.concat [:name, :short_name, :sortable_name, :birthdate] if @user.grants_right?(@current_user, :rename)
    managed_attributes << :terms_of_use if @user == (@real_current_user || @current_user)
    managed_attributes << :email if update_email

    if @user.grants_right?(@current_user, :manage_user_details)
      managed_attributes.concat([:time_zone, :locale])
    end

    if @user.grants_right?(@current_user, :update_avatar)
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

    if managed_attributes.any? && user_params == params[:user]
      # admins can update avatar images even if they are locked
      admin_avatar_update = user_params[:avatar_image] &&
        @user.grants_right?(@current_user, :update_avatar) &&
        @user.grants_right?(@current_user, :manage_user_details)

      if admin_avatar_update
        old_avatar_state = @user.avatar_state
        @user.avatar_state = 'submitted'
      end

      if session[:require_terms]
        @user.require_acceptance_of_terms = true
      end

      if user_params[:birthdate].present? && user_params[:birthdate] !~ Api::ISO8601_REGEX &&
          params[:user][:birthdate] !~ Api::DATE_REGEX
        return render(:json => {:errors => {:birthdate => t(:birthdate_invalid,
          'Invalid date or invalid datetime for birthdate')}}, :status => 400)
      end

      respond_to do |format|
        if @user.update_attributes(user_params)
          @user.avatar_state = (old_avatar_state == :locked ? old_avatar_state : 'approved') if admin_avatar_update
          @user.email = user_params[:email] if update_email
          @user.save if admin_avatar_update || update_email
          session.delete(:require_terms)
          flash[:notice] = t('user_updated', 'User was successfully updated.')
          unless params[:redirect_to_previous].blank?
            return redirect_to :back
          end
          format.html { redirect_to user_url(@user) }
          format.json {
            render :json => user_json(@user, @current_user, session, %w{locale avatar_url email time_zone},
              @current_user.pseudonym.account) }
        else
          format.html { render :edit }
          format.json { render :json => @user.errors, :status => :bad_request }
        end
      end
    else
      render_unauthorized_action
    end
  end

  def media_download
    fetcher = MediaSourceFetcher.new(CanvasKaltura::ClientV3.new)
    extension = params[:type]
    media_type = params[:media_type]
    extension ||= params[:format] if media_type.nil?

    url = fetcher.fetch_preferred_source_url(
       media_id: params[:entryId],
       file_extension: extension,
       media_type: media_type
    )
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
    @source_user = User.find(params[:user_id])
    @target_user = User.where(id: params[:new_user_id]).first if params[:new_user_id]
    @target_user ||= @current_user
    if @source_user.grants_right?(@current_user, :merge) && @target_user.grants_right?(@current_user, :merge)
      UserMerge.from(@source_user).into(@target_user)
      @target_user.touch
      flash[:notice] = t('user_merge_success', "User merge succeeded! %{first_user} and %{second_user} are now one and the same.", :first_user => @target_user.name, :second_user => @source_user.name)
      if @target_user == @current_user
        redirect_to user_profile_url(@current_user)
      else
        redirect_to user_url(@target_user)
      end
    else
      flash[:error] = t('user_merge_fail', "User merge failed. Please make sure you have proper permission and try again.")
      redirect_to dashboard_url
    end
  end

  def admin_merge
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :merge)
      if params[:clear]
        params.delete(:new_user_id)
        params.delete(:pending_user_id)
      end

      if params[:new_user_id].present?
        @other_user = api_find_all(User, [params[:new_user_id]]).first
        if !@other_user || !@other_user.grants_right?(@current_user, :merge)
          @other_user = nil
          flash[:error] = t('user_not_found', "No active user with that ID was found.")
        elsif @other_user == @user
          @other_user = nil
          flash[:error] = t('cant_self_merge', "You can't merge an account with itself.")
        end
      end

      if params[:pending_user_id].present?
        @pending_other_user = api_find_all(User, [params[:pending_user_id]]).first
        if !@pending_other_user || !@pending_other_user.grants_right?(@current_user, :merge)
          @pending_other_user = nil
          flash[:error] = t('user_not_found', "No active user with that ID was found.")
        elsif @pending_other_user == @user
          @pending_other_user = nil
          flash[:error] = t('cant_self_merge', "You can't merge an account with itself.")
        end
      end

      render :admin_merge
    end
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
          @context = nil unless context.respond_to?(:users) && context.users.where(id: @user).first
        end
        @user.report_avatar_image!(@context)
      end
      session["reports_#{@user.id}".to_sym] = true
      render :json => {:reported => true}
    end
  end

  def delete
    @user = User.find(params[:user_id])
    render_unauthorized_action unless @user.allows_user_to_remove_from_account?(@domain_root_account, @current_user)
  end

  def destroy
    @user = api_find(User, params[:id])
    if @user.allows_user_to_remove_from_account?(@domain_root_account, @current_user)
      @user.remove_from_root_account(@domain_root_account)
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
    else
      render_unauthorized_action
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

  def all_menu_courses
    render :json => Rails.cache.fetch(['menu_courses', @current_user].cache_key) {
      map_courses_for_menu(@current_user.courses_with_primary_enrollment)
    }
  end

  def teacher_activity
    @teacher = User.find(params[:user_id])
    if @teacher == @current_user || authorized_action(@teacher, @current_user, :read_reports)
      @courses = {}

      if params[:student_id]
        student = User.find(params[:student_id])
        enrollments = student.student_enrollments.active.preload(:course).shard(student).to_a
        enrollments.each do |enrollment|
          should_include = enrollment.course.user_has_been_instructor?(@teacher) &&
                           enrollment.course.grants_right?(@current_user, :read_reports) &&
                           enrollment.course.apply_enrollment_visibility(enrollment.course.all_student_enrollments, @teacher).where(id: enrollment).first
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
          enrollments = course.apply_enrollment_visibility(course.all_student_enrollments, @teacher)
          @courses[course] = teacher_activity_report(@teacher, course, enrollments)
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
    return redirect_to(User.default_avatar_fallback) unless service_enabled?(:avatars)
    user_id = params[:user_id].to_i
    if params[:user_id].present? && params[:user_id].match(/-/)
      user_id = User.user_id_from_avatar_key(params[:user_id])
    end
    account_avatar_setting = service_enabled?(:avatars) ? @domain_root_account.settings[:avatars] || 'enabled' : 'disabled'
    user_id, user_shard = Shard.local_id_for(user_id)
    user_shard ||= Shard.current
    url = user_shard.activate do
      Rails.cache.fetch(Cacher.avatar_cache_key(user_id, account_avatar_setting)) do
        user = User.where(id: user_id).first if user_id.present?
        if user
          user.avatar_url(nil, account_avatar_setting, "%{fallback}")
        else
          '%{fallback}'
        end
      end
    end
    fallback = User.avatar_fallback_url(nil, request)
    redirect_to (url.blank? || url == "%{fallback}") ?
      User.default_avatar_fallback :
      url.sub(CGI.escape("%{fallback}"), CGI.escape(fallback))
  end

  # @API Merge user into another user
  #
  # Merge a user into another user.
  # To merge users, the caller must have permissions to manage both users. This
  # should be considered irreversible. This will delete the user and move all
  # the data into the destination user.
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
    if authorized_action(user, @current_user, :merge)

      if (account_id = params[:destination_account_id])
        destination_account = Account.find_by_domain(account_id)
        destination_account ||= Account.find(account_id)
      else
        destination_account ||= @domain_root_account
      end

      into_user = api_find(User, params[:destination_user_id], account: destination_account)

      if authorized_action(into_user, @current_user, :merge)
        UserMerge.from(user).into into_user
        render(:json => user_json(into_user,
                                  @current_user,
                                  session,
                                  %w{locale},
                                  destination_account))
      end
    end
  end

  # @API Split merged users into separate users
  #
  # Merged users cannot be fully restored to their previous state, but this will
  # attempt to split as much as possible to the previous state.
  # To split a merged user, the caller must have permissions to manage all of
  # the users logins. If there are multiple users that have been merged into one
  # user it will split each merge into a separate user.
  # A split can only happen within 90 days of a user merge. A user merge deletes
  # the previous user and may be permanently deleted. In this scenario we create
  # a new user object and proceed to move as much as possible to the new user.
  # The user object will not have preserved the name or settings from the
  # previous user. Some items may have been deleted during a user_merge that
  # cannot be restored, and/or the data has become stale because of other
  # changes to the objects since the time of the user_merge.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/split \
  #          -X POST \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def split
    user = api_find(User, params[:id])
    unless UserMergeData.active.where(user_id: user).where('created_at > ?', 90.days.ago).exists?
      return render json: {message: t('Nothing to split off of this user')}, status: :bad_request
    end

    if authorized_action(user, @current_user, :merge)
      users = SplitUsers.split_db_users(user)
      render :json => users.map { |u| user_json(u, @current_user, session) }
    end
  end

  protected

  def teacher_activity_report(teacher, course, student_enrollments)
    ids = student_enrollments.map(&:user_id)
    data = {}
    student_enrollments.each { |e| data[e.user.id] = { :enrollment => e, :ungraded => [] } }

    # find last interactions
    last_comment_dates = SubmissionCommentInteraction.in_course_between(course, teacher.id, ids)
    last_comment_dates.each do |(user_id, author_id), date|
      next unless student = data[user_id.to_i]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end
    scope = ConversationMessage.
        joins("INNER JOIN #{ConversationParticipant.quoted_table_name} ON conversation_participants.conversation_id=conversation_messages.conversation_id").
        where('conversation_messages.author_id = ? AND conversation_participants.user_id IN (?) AND NOT conversation_messages.generated', teacher, ids)
    # fake_arel can't pass an array in the group by through the scope
    last_message_dates = scope.group(['conversation_participants.user_id', 'conversation_messages.author_id']).maximum(:created_at)
    last_message_dates.each do |key, date|
      next unless student = data[key.first.to_i]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end

    # find all ungraded submissions in one query
    ungraded_submissions = course.submissions.
        preload(:assignment).
        where("user_id IN (?) AND #{Submission.needs_grading_conditions}", ids).
        except(:order).
        order(:submitted_at).to_a


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

  protected

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

  private

  def authenticate_observee
    Pseudonym.authenticate(params[:observee] || {},
                           [@domain_root_account.id] + @domain_root_account.trusted_account_ids)
  end

  def grades_for_presenter(presenter, grading_periods)
    grades = {
      student_enrollments: {},
      observed_enrollments: {}
    }
    grouped_observed_enrollments =
      presenter.observed_enrollments.group_by { |enrollment| enrollment[:course_id] }

    grouped_observed_enrollments.each do |course_id, enrollments|
      grades[:observed_enrollments][course_id] = {}

      if grading_periods[course_id].present?
        user_ids = enrollments.map(&:user_id)
        course = enrollments.first.course
        grades[:observed_enrollments][course_id] = grades_from_grade_calculator(user_ids, course, grading_periods)
      else
        grades[:observed_enrollments][course_id] = grades_from_enrollments(enrollments)
      end
    end

    presenter.student_enrollments.each do |enrollment_course_pair|
      course = enrollment_course_pair.first
      enrollment = enrollment_course_pair.second

      if grading_periods[course.id].present?
        computed_score = grades_from_grade_calculator([enrollment.user_id], course, grading_periods)[enrollment.user_id]
        grades[:student_enrollments][course.id] = computed_score
      else
        computed_score = enrollment.computed_current_score
        grades[:student_enrollments][course.id] = computed_score
      end
    end
    grades
  end

  def grades_from_grade_calculator(user_ids, course, grading_periods)
    calculator = grade_calculator(user_ids, course, grading_periods)
    grades = {}
    calculator.compute_scores.each_with_index do |score, index|
      computed_score = score[:current][:grade]
      user_id = user_ids[index]
      grades[user_id] = computed_score
    end
    grades
  end

  def grades_from_enrollments(enrollments)
    grades = {}
    enrollments.each do |enrollment|
      computed_score = enrollment.computed_current_score
      grades[enrollment.user_id] = computed_score
    end
    grades
  end

  def collected_grading_periods_for_presenter(presenter, course_id, grading_period_id)
    observer_courses = presenter.observed_enrollments.map(&:course)
    student_courses = presenter.student_enrollments.map(&:first)
    teacher_courses = presenter.teacher_enrollments.map(&:course)
    courses = observer_courses | student_courses | teacher_courses
    grading_periods = {}

    courses.each do |course|
      next unless course.feature_enabled?(:multiple_grading_periods)

      course_periods = GradingPeriod.for(course)
      grading_period_specified = grading_period_id &&
        course_id && course_id.to_i == course.id

      selected_period_id = if grading_period_specified
        grading_period_id.to_i
      else
        current_period = course_periods.find(&:current?)
        current_period ? current_period.id : 0
      end

      grading_periods[course.id] = {
        periods: course_periods,
        selected_period_id: selected_period_id
      }
    end
    grading_periods
  end

  def grade_calculator(user_ids, course, grading_periods)
    if course.feature_enabled?(:multiple_grading_periods) &&
      grading_periods[course.id][:selected_period_id] != 0

      grading_period = grading_periods[course.id][:periods].find do |period|
        period.id == grading_periods[course.id][:selected_period_id]
      end
      GradeCalculator.new(user_ids, course, grading_period: grading_period)
    else
      GradeCalculator.new(user_ids, course)
    end
  end

  def create_user
    run_login_hooks
    # Look for an incomplete registration with this pseudonym

    sis_user_id = nil
    integration_id = nil
    params[:pseudonym] ||= {}

    if @context.grants_right?(@current_user, session, :manage_sis)
      sis_user_id = params[:pseudonym].delete(:sis_user_id)
      integration_id = params[:pseudonym].delete(:integration_id)
    end

    @pseudonym = nil
    @user = nil
    if sis_user_id && value_to_boolean(params[:enable_sis_reactivation])
      @pseudonym = @context.pseudonyms.where(:sis_user_id => sis_user_id, :workflow_state => 'deleted').first
      if @pseudonym
        @pseudonym.workflow_state = 'active'
        @pseudonym.save!
        @user = @pseudonym.user
        @user.workflow_state = 'registered'
        @user.update_account_associations
      end
    end

    if @pseudonym.nil?
      @pseudonym = @context.pseudonyms.active.by_unique_id(params[:pseudonym][:unique_id]).first
      # Setting it to nil will cause us to try and create a new one, and give user the login already exists error
      @pseudonym = nil if @pseudonym && !['creation_pending', 'pending_approval'].include?(@pseudonym.user.workflow_state)
    end

    @user ||= @pseudonym && @pseudonym.user
    @user ||= User.new

    force_validations = value_to_boolean(params[:force_validations])
    manage_user_logins = @context.grants_right?(@current_user, session, :manage_user_logins)
    self_enrollment = params[:self_enrollment].present?
    allow_non_email_pseudonyms = !force_validations && manage_user_logins || self_enrollment && params[:pseudonym_type] == 'username'
    require_password = self_enrollment && allow_non_email_pseudonyms
    allow_password = require_password || manage_user_logins

    notify_policy = Users::CreationNotifyPolicy.new(manage_user_logins, params[:pseudonym])

    includes = %w{locale}

    cc_params = params[:communication_channel]

    if cc_params
      cc_type = cc_params[:type] || CommunicationChannel::TYPE_EMAIL
      cc_addr = cc_params[:address] || params[:pseudonym][:unique_id]

      can_manage_students = [Account.site_admin, @context].any? do |role|
        role.grants_right?(@current_user, :manage_students)
      end

      if can_manage_students
        skip_confirmation = value_to_boolean(cc_params[:skip_confirmation])
      end

      if can_manage_students && cc_type == CommunicationChannel::TYPE_EMAIL
        includes << 'confirmation_url' if value_to_boolean(cc_params[:confirmation_url])
      end

    else
      cc_type = CommunicationChannel::TYPE_EMAIL
      cc_addr = params[:pseudonym].delete(:path) || params[:pseudonym][:unique_id]
    end

    if params[:user]
      if self_enrollment && params[:user][:self_enrollment_code]
        params[:user][:self_enrollment_code].strip!
      else
        params[:user].delete(:self_enrollment_code)
      end
      if params[:user][:birthdate].present? && params[:user][:birthdate] !~ Api::ISO8601_REGEX &&
          params[:user][:birthdate] !~ Api::DATE_REGEX
        return render(:json => {:errors => {:birthdate => t(:birthdate_invalid,
                                                            'Invalid date or invalid datetime for birthdate')}}, :status => 400)
      end

      @user.attributes = params[:user]
      accepted_terms = params[:user].delete(:terms_of_use)
      @user.accept_terms if value_to_boolean(accepted_terms)
      includes << "terms_of_use" unless accepted_terms.nil?
    end
    @user.name ||= params[:pseudonym][:unique_id]
    skip_registration = value_to_boolean(params[:user].try(:[], :skip_registration))
    unless @user.registered?
      @user.workflow_state = if require_password || skip_registration
                               # no email confirmation required (self_enrollment_code and password
                               # validations will ensure everything is legit)
                               'registered'
                             elsif notify_policy.is_self_registration? && @user.registration_approval_required?
                               'pending_approval'
                             else
                               'pre_registered'
                             end
    end
    if force_validations || !manage_user_logins
      @user.require_acceptance_of_terms = @domain_root_account.terms_required?
      @user.require_presence_of_name = true
      @user.require_self_enrollment_code = self_enrollment
      @user.validation_root_account = @domain_root_account
    end

    @invalid_observee_creds = nil
    if @user.initial_enrollment_type == 'observer'
      if (observee_pseudonym = authenticate_observee)
        @observee = observee_pseudonym.user
      else
        @invalid_observee_creds = Pseudonym.new
        @invalid_observee_creds.errors.add('unique_id', 'bad_credentials')
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
    if params[:pseudonym][:authentication_provider_id]
      @pseudonym.authentication_provider = @context.
          authentication_providers.active.
          find(params[:pseudonym][:authentication_provider_id])
    end
    @pseudonym.attributes = params[:pseudonym]
    @pseudonym.sis_user_id = sis_user_id
    @pseudonym.integration_id = integration_id

    @pseudonym.account = @context
    @pseudonym.workflow_state = 'active'
    if cc_addr.present?
      @cc =
        @user.communication_channels.where(:path_type => cc_type).by_path(cc_addr).first ||
            @user.communication_channels.build(:path_type => cc_type, :path => cc_addr)
      @cc.user = @user
      @cc.workflow_state = skip_confirmation ? 'active' : 'unconfirmed' unless @cc.workflow_state == 'confirmed'
    end

    if @user.valid? && @pseudonym.valid? && @invalid_observee_creds.nil?
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
      if @observee && !@user.user_observees.where(user_id: @observee).exists?
        @user.user_observees << @user.user_observees.create_or_restore(user_id: @observee)
      end

      if notify_policy.is_self_registration?
        registration_params = params.fetch(:user, {}).merge(remote_ip: request.remote_ip, cookies: cookies)
        @user.new_registration(registration_params)
      end
      message_sent = notify_policy.dispatch!(@user, @pseudonym, @cc) if @cc

      data = { :user => @user, :pseudonym => @pseudonym, :channel => @cc, :message_sent => message_sent, :course => @user.self_enrollment_course }
      if api_request?
        render(:json => user_json(@user, @current_user, session, includes))
      else
        render(:json => data)
      end
    else
      errors = {
          :errors => {
              :user => @user.errors.as_json[:errors],
              :pseudonym => @pseudonym ? @pseudonym.errors.as_json[:errors] : {},
              :observee => @invalid_observee_creds ? @invalid_observee_creds.errors.as_json[:errors] : {}
          }
      }
      render :json => errors, :status => :bad_request
    end
  end
end
