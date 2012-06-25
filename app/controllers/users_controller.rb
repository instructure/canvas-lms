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

# @API Users
# API for accessing information on the current and other users.
#
# Throughout this API, the `:user_id` parameter can be replaced with `self` as
# a shortcut for the id of the user accessing the API. For instance,
# `users/:user_id/page_views` can be accessed as `users/self/page_views` to
# access the current user's page views.
class UsersController < ApplicationController
  include GoogleDocs
  include Twitter
  include LinkedIn
  include DeliciousDiigo
  before_filter :require_user, :only => [:grades, :delete_user_service, :create_user_service, :confirm_merge, :merge, :kaltura_session, :ignore_item, :close_notification, :mark_avatar_image, :user_dashboard, :masquerade, :external_tool]
  before_filter :reject_student_view_student, :only => [:delete_user_service, :create_user_service, :confirm_merge, :merge, :user_dashboard, :masquerade]
  before_filter :require_open_registration, :only => [:new, :create]

  def grades
    @user = User.find_by_id(params[:user_id]) if params[:user_id].present?
    @user ||= @current_user
    if authorized_action(@user, @current_user, :read)
      @current_active_enrollments = @user.current_enrollments.scoped(:include => :course)
      @prior_enrollments = []; @current_enrollments = []
      @current_active_enrollments.each do |e|
        case e.state_based_on_date
        when :active
          @current_enrollments << e
        when :completed
          #@prior_enrollments << e
        end
      end
      #@prior_enrollments.concat @user.concluded_enrollments.select{|e| e.is_a?(StudentEnrollment) }

      @student_enrollments = @current_enrollments.
        select{ |e| e.student? }.
        inject({}){ |hash, e| hash[e.course] = e; hash }

      @observer_enrollments = @current_enrollments.select{|e| e.is_a?(ObserverEnrollment) && e.associated_user_id }
      @observed_enrollments = []
      @observer_enrollments.each do |e|
        @observed_enrollments << StudentEnrollment.active.find_by_user_id_and_course_id(e.associated_user_id, e.course_id)
      end
      @observed_enrollments = @observed_enrollments.uniq.compact

      @teacher_enrollments = @current_enrollments.select{|e| e.instructor? }

      if @student_enrollments.length + @teacher_enrollments.length + @observed_enrollments.length == 1# && @prior_enrollments.empty?
        enrollment = @student_enrollments.first.try(:last) || @teacher_enrollments.first || @observed_enrollments.first
        redirect_to course_grades_url(enrollment.course_id)
        return
      end

      Enrollment.send(:preload_associations, @observed_enrollments, :course)
      #Enrollment.send(:preload_associations, @prior_enrollments, :course)

      @course_grade_summaries = {}
      @teacher_enrollments.each do |enrollment|
        @course_grade_summaries[enrollment.course_id] = Rails.cache.fetch(['computed_avg_grade_for', enrollment.course].cache_key) do
          goodies = enrollment.course.student_enrollments.map(&:computed_current_score).compact
          score = (goodies.sum.to_f * 100.0 / goodies.length.to_f).round.to_f / 100.0 rescue nil
          {:score => score, :students => goodies.length }
        end
      end
    end
  end

  def oauth
    if !feature_and_service_enabled?(params[:service])
      flash[:error] = t('service_not_enabled', "That service has not been enabled")
      return redirect_to(profile_url)
    end
    return_to_url = params[:return_to] || profile_url
    if params[:service] == "google_docs"
      redirect_to google_docs_request_token_url(return_to_url)
    elsif params[:service] == "twitter"
      redirect_to twitter_request_token_url(return_to_url)
    elsif params[:service] == "linked_in"
      redirect_to linked_in_request_token_url(return_to_url)
    elsif params[:service] == "facebook"
      oauth_request = OauthRequest.create(
        :service => 'facebook',
        :secret => AutoHandle.generate("fb", 10),
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
      redirect_to (@current_user ? profile_url : root_url)
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
          google_docs_get_access_token(oauth_request, params[:oauth_verifier])
          flash[:notice] = t('google_docs_added', "Google Docs access authorized!")
        rescue => e
          flash[:error] = t('google_docs_fail', "Google Docs authorization failed. Please try again")
        end
      elsif params[:service] == "linked_in"
        begin
          linked_in_get_access_token(oauth_request, params[:oauth_verifier])
          flash[:notice] = t('linkedin_added', "LinkedIn account successfully added!")
        rescue => e
          flash[:error] = t('linkedin_fail', "LinkedIn authorization failed. Please try again")
        end
      else
        begin
          token = twitter_get_access_token(oauth_request, params[:oauth_verifier])
          flash[:notice] = t('twitter_added', "Twitter access authorized!")
        rescue => e
          flash[:error] = t('twitter_fail_whale', "Twitter authorization failed. Please try again")
        end
      end
      return_to(oauth_request.return_url, profile_url)
    end
  end

  # @API List users
  # Retrieve the list of users associated with this account.
  #
  # @example_response
  #   [
  #     { "id": 1, "name": "Dwight Schrute", "sortable_name": "Schrute, Dwight", "short_name": "Dwight", "login_id": "dwight@example.com", "sis_user_id": "12345", "sis_login_id": null },
  #     { "id": 2, "name": "Gob Bluth", "sortable_name": "Bluth, Gob", "short_name": "Gob Bluth", "login_id": "gob@example.com", "sis_user_id": "67890", "sis_login_id": null }
  #   ]
  def index
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      @root_account = @context.root_account
      @users = []
      @query = (params[:user] && params[:user][:name]) || params[:term]
      if @context && @context.is_a?(Account) && @query
        @users = @context.users_name_like(@query)
      elsif params[:enrollment_term_id].present? && @root_account == @context
        @users = @context.fast_all_users.scoped(:joins => :courses, :conditions => ["courses.enrollment_term_id = ?", params[:enrollment_term_id]], :group => @context.connection.group_by('users.id', 'users.name', 'users.sortable_name'))
      else
        @users = @context.fast_all_users
      end

      @users = api_request? ?
        Api.paginate(@users, self, api_v1_account_users_path, :order => :sortable_name) :
        @users.paginate(:page => params[:page], :per_page => @per_page, :total_entries => @users.size)
      respond_to do |format|
        if @users.length == 1 && params[:term]
          format.html {
            redirect_to(named_context_url(@context, :context_user_url, @users.first))
          }
        else
          @enrollment_terms = []
          if @root_account == @context
            @enrollment_terms = @context.enrollment_terms.active
          end
          format.html
        end
        format.json  {
          cancel_cache_buster
          expires_in 30.minutes
          api_request? ?
            render(:json => @users.map { |u| user_json(u, @current_user, session) }) :
            render(:json => @users.map { |u| { :label => u.name, :id => u.id } })
        }
      end
    end
  end

  def masquerade
    @user = User.find(:first, :conditions => {:id => params[:user_id]})
    return render_unauthorized_action(@user) unless @user.can_masquerade?(@real_current_user || @current_user, @domain_root_account)
    if request.post?
      if @user == @real_current_user
        session.delete(:become_user_id)
      else
        session[:become_user_id] = params[:user_id]
      end
      return_url = session[:masquerade_return_to]
      session.delete(:masquerade_return_to)
      return return_to(return_url, request.referer || dashboard_url)
    end
  end

  def user_dashboard
    get_context

    # dont show crubms on dashboard because it does not make sense to have a breadcrumb
    # trail back to home if you are already home
    clear_crumbs

    if request.path =~ %r{\A/dashboard\z}
      return redirect_to(dashboard_url, :status => :moved_permanently)
    end
    disable_page_views if @current_pseudonym && @current_pseudonym.unique_id == "pingdom@instructure.com"
    if @show_recent_feedback = (@current_user.student_enrollments.active.size > 0)
      @recent_feedback = (@current_user && @current_user.recent_feedback) || []
    end
    @announcements = AccountNotification.for_user_and_account(@current_user, @domain_root_account)
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
  #   !!!javascript
  #   {
  #     'type': 'Submission',
  #     'grade': '12',
  #     'score': 12,
  #     'assignment': {
  #       'title': 'Assignment 3',
  #       'id': 5678,
  #       'points_possible': 15
  #     }
  #   }
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
  # CollectionItem:
  #
  #   !!!javascript
  #   {
  #     'type': 'CollectionItem',
  #     'collection_item' { ... full CollectionItem data ... }
  #   }
  def activity_stream
    if @current_user
      api_render_stream_for_contexts(nil, :api_v1_user_activity_stream_url)
    else
      render_unauthorized_action
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
        :account_name => c.enrollment_term.root_account.name, :account_id => c.enrollment_term.root_account.id }
    }.to_json
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
    unless @current_user
      return render_unauthorized_action
    end

    grading = @current_user.assignments_needing_grading().map { |a| todo_item_json(a, @current_user, session, 'grading') }
    submitting = @current_user.assignments_needing_submitting().map { |a| todo_item_json(a, @current_user, session, 'submitting') }
    render :json => (grading + submitting)
  end

  def ignore_item
    unless %w[grading submitting].include?(params[:purpose])
      return render(:json => { :ignored => false }, :status => 400)
    end
    @current_user.ignore_item!(params[:asset_string], params[:purpose], params[:permanent] == '1')
    render :json => { :ignored => true }
  end

  def ignore_stream_item
    StreamItemInstance.update_all({ :hidden => true }, { :stream_item_id => params[:id], :user_id => @current_user.id })
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
    @attachment = Attachment.new(:context => @user)
    if authorized_action(@attachment, @current_user, :create)
      api_attachment_preflight(@current_user, request)
    end
  end

  def close_notification
    @current_user.close_announcement(AccountNotification.find(params[:id]))
    render :json => @current_user.to_json
  end

  def delete_user_service
    @current_user.user_services.find(params[:id]).destroy
    render :json => {:deleted => true}
  end

  def create_user_service
    begin
      user_name = params[:user_service][:user_name]
      password = params[:user_service][:password]
      service = OpenObject.new(:service_user_name => user_name, :decrypted_password => password)
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
      render :json => @service.to_json
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
      @services.to_json(:only => [:service_user_id, :service_user_url, :service_user_name, :service, :type, :id])
    end
    render :json => json
  end

  def bookmark_search
    @service = @current_user.user_services.find_by_type_and_service('BookmarkService', params[:service_type]) rescue nil
    res = nil
    res = @service.find_bookmarks(params[:q]) if @service
    render :json => res.to_json
  end

  def show
    get_context
    @context_account = @context.is_a?(Account) ? @context : @domain_root_account
    @user = params[:id] && params[:id] != 'self' ? User.find(params[:id]) : @current_user
    if authorized_action(@user, @current_user, :view_statistics)
      add_crumb(t('crumbs.profile', "%{user}'s profile", :user => @user.short_name), @user == @current_user ? profile_path : user_path(@user) )
      @page_views = @user.page_views.paginate :page => params[:page], :order => 'created_at DESC', :per_page => 50, :without_count => true

      # course_section and enrollment term will only be used if the enrollment dates haven't been cached yet;
      # maybe should just look at the first enrollment and check if it's cached to decide if we should include
      # them here
      @enrollments = @user.enrollments.scoped(:conditions => "workflow_state<>'deleted'", :include => [{:course => { :enrollment_term => :enrollment_dates_overrides }}, :associated_user, :course_section]).select{|e| e.course && !e.course.deleted? }.sort_by{|e| [e.state_sortable, e.rank_sortable, e.course.name] }
      # pre-populate the reverse association
      @enrollments.each { |e| e.user = @user }
      @group_memberships = @user.group_memberships.scoped(:include => :group)

      respond_to do |format|
        format.html
      end
    end
  end

  def external_tool
    @tool = ContextExternalTool.find_for(params[:id], @domain_root_account, :user_navigation)
    @resource_title = @tool.label_for(:user_navigation)
    @resource_url = @tool.settings[:user_navigation][:url]
    @opaque_id = @current_user.opaque_identifier(:asset_string)
    @context = UserProfile.new(@current_user)
    @resource_type = 'user_navigation'
    @return_url = profile_url(:include_host => true)
    @launch = BasicLTI::ToolLaunch.new(:url => @resource_url, :tool => @tool, :user => @current_user, :context => @context, :link_code => @opaque_id, :return_url => @return_url, :resource_type => @resource_type)
    @tool_settings = @launch.generate
    @active_tab = @tool.asset_string
    add_crumb(@current_user.short_name, profile_path)
    render :template => 'external_tools/tool_show'
  end

  def new
    @user = User.new
    @pseudonym = @current_user ? @current_user.pseudonyms.build(:account => @context) : Pseudonym.new(:account => @context)
    render :action => "new"
  end

  include Api::V1::User
  include Api::V1::Avatar

  # @API Create a user
  # Create and return a new user and pseudonym for an account.
  #
  # @argument user[name] [Optional] The full name of the user. This name will be used by teacher for grading.
  # @argument user[short_name] [Optional] User's name as it will be displayed in discussions, messages, and comments.
  # @argument user[sortable_name] [Optional] User's name as used to sort alphabetically in lists.
  # @argument user[time_zone] [Optional] The time zone for the user. Allowed time zones are listed in {http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/TimeZone The Ruby on Rails documentation}.
  # @argument user[locale] [Optional] The user's preferred language as a two-letter ISO 639-1 code. Current supported languages are English ("en") and Spanish ("es").
  # @argument pseudonym[unique_id] User's login ID.
  # @argument pseudonym[password] [Optional] User's password.
  # @argument pseudonym[sis_user_id] [Optional] [Integer] SIS ID for the user's account. To set this parameter, the caller must be able to manage SIS permissions.
  # @argument pseudonym[:send_confirmation] [Optional, 0|1] [Integer] Send user notification of account creation if set to 1.
  def create
    # Look for an incomplete registration with this pseudonym
    @pseudonym = @context.pseudonyms.active.custom_find_by_unique_id(params[:pseudonym][:unique_id])
    # Setting it to nil will cause us to try and create a new one, and give user the login already exists error
    @pseudonym = nil if @pseudonym && !['creation_pending', 'pre_registered', 'pending_approval'].include?(@pseudonym.user.workflow_state)

    notify = params[:pseudonym].delete(:send_confirmation) == '1'
    notify = :self_registration unless @context.grants_right?(@current_user, session, :manage_user_logins)
    email = params[:pseudonym].delete(:path) || params[:pseudonym][:unique_id]

    sis_user_id = params[:pseudonym].delete(:sis_user_id)
    sis_user_id = nil unless @context.grants_right?(@current_user, session, :manage_sis)

    @user = @pseudonym && @pseudonym.user
    @user ||= User.new
    @user.attributes = params[:user]
    @user.name ||= params[:pseudonym][:unique_id]
    @user.workflow_state = notify == :self_registration && @user.registration_approval_required? ? 'pending_approval' : 'pre_registered' unless @user.registered?
    @user.save!

    @pseudonym ||= @user.pseudonyms.build(:account => @context)
    # pre-populate the reverse association
    @pseudonym.user = @user
    # don't require password_confirmation on api calls
    params[:pseudonym][:password_confirmation] = params[:pseudonym][:password] if api_request?
    @pseudonym.attributes = params[:pseudonym]
    @pseudonym.sis_user_id = sis_user_id

    @pseudonym.account = @context
    @pseudonym.workflow_state = 'active'
    @cc = @user.communication_channels.email.by_path(email).first
    @cc ||= @user.communication_channels.build(:path => email)
    @cc.user = @user
    @cc.workflow_state = 'unconfirmed' unless @cc.workflow_state == 'confirmed'
    if @pseudonym.valid?
      @pseudonym.save_without_session_maintenance
      @cc.save!
      message_sent = false
      if notify == :self_registration
        unless @user.workflow_state == 'pending_approval'
          message_sent = true
          @pseudonym.send_confirmation!
        end
        @user.new_teacher_registration((params[:user] || {}).merge({:remote_ip  => request.remote_ip}))
      elsif notify && !@user.registered?
        message_sent = true
        @pseudonym.send_registration_notification!
      else
        other_cc_count = CommunicationChannel.email.active.by_path(@cc.path).count(:all, :joins => { :user => :pseudonyms }, :conditions => ["communication_channels.user_id<>? AND pseudonyms.workflow_state='active'", @user.id])
        @cc.send_merge_notification! if other_cc_count != 0
      end

      data = { :user => @user, :pseudonym => @pseudonym, :channel => @cc, :message_sent => message_sent }
      respond_to do |format|
        flash[:user_id] = @user.id
        flash[:pseudonym_id] = @pseudonym.id
        format.html { redirect_to registered_url }
        format.json {
          if api_request?
            render(:json => user_json(@user, @current_user, session, %w{locale}))
          else
            render(:json => data)
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => @pseudonym.errors.to_json, :status => :bad_request }
      end
    end
  end

  def registered
    @pseudonym_session.destroy if @pseudonym_session
    @pseudonym = Pseudonym.find_by_id(flash[:pseudonym_id]) if flash[:pseudonym_id].present?
    if flash[:user_id] && (@user = User.find(flash[:user_id]))
      @email_address = @pseudonym && @pseudonym.communication_channel && @pseudonym.communication_channel.path
      @email_address ||= @user.email
      @pseudonym ||= @user.pseudonym
      @cc = @pseudonym.communication_channel || @user.communication_channel
    else
      redirect_to root_url
    end
  end

  # @API Edit a user
  # Modify an existing user. To modify a user's login, see the documentation for logins.
  #
  # @argument user[name] [Optional] The full name of the user. This name will be used by teacher for grading.
  # @argument user[short_name] [Optional] User's name as it will be displayed in discussions, messages, and comments.
  # @argument user[sortable_name] [Optional] User's name as used to sort alphabetically in lists.
  # @argument user[time_zone] [Optional] The time zone for the user. Allowed time zones are listed in {http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/TimeZone The Ruby on Rails documentation}.
  # @argument user[locale] [Optional] The user's preferred language as a two-letter ISO 639-1 code. Current supported languages are English ("en") and Spanish ("es").
  # @argument user[avatar][token] [Optional] A unique representation of the avatar record to assign as the user's current avatar. This token can be obtained from the user avatars endpoint. This supersedes the user[avatar][url] argument, and if both are included the url will be ignored. Note: this is an internal representation and is subject to change without notice. It should be consumed with this api endpoint and used in the user update endpoint, and should not be constructed by the client.
  # @argument user[avatar][url] [Optional] To set the user's avatar to point to an external url, do not include a token and instead pass the url here. Warning: For maximum compatibility, please use 50 px square images.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/users/133.json' \ 
  #        -X PUT \ 
  #        -F 'user[name]=Sheldon Cooper' \ 
  #        -F 'user[short_name]=Shelly' \ 
  #        -F 'user[time_zone]=Pacific Time (US & Canada)' \ 
  #        -F 'user[avatar][token]=<opaque_token>' \ 
  #        -H "Authorization: Bearer <token>"
  #
  # @example_response
  #
  #   {
  #     "id":133,
  #     "login_id":"sheldor@example.com",
  #     "name":"Sheldon Cooper",
  #     "short_name":"Shelly",
  #     "sortable_name":"Cooper, Sheldon",
  #     "avatar_url":"http://<canvas>/images/users/133-..."
  #   }
  def update
    @user = api_request? ?
      api_find(User, params[:id]) :
      params[:id] ? User.find(params[:id]) : @current_user

    if params[:default_pseudonym_id] && authorized_action(@user, @current_user, :manage)
      @default_pseudonym = @user.pseudonyms.find(params[:default_pseudonym_id])
      @default_pseudonym.move_to_top
    end

    managed_attributes = []
    managed_attributes.concat [:name, :short_name, :sortable_name] if @user.grants_right?(@current_user, nil, :rename)
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

      respond_to do |format|
        if @user.update_attributes(user_params)
          if admin_avatar_update
            @user.avatar_state = (old_avatar_state == :locked ? old_avatar_state : 'approved')
            @user.save
          end
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
      render_unauthorized_action(@user)
    end
  end

  def media_download
    url = Rails.cache.fetch(['media_download_url', params[:entryId], params[:type]].cache_key, :expires_in => 30.minutes) do
      client = Kaltura::ClientV3.new
      client.startSession(Kaltura::SessionType::ADMIN)
      assets = client.flavorAssetGetByEntryId(params[:entryId])
      asset = assets.find {|a| a[:fileExt] == params[:type] }
      if asset
        client.flavorAssetGetDownloadUrl(asset[:id])
      else
        nil
      end
    end

    if url
      if params[:redirect] == '1'
        if %w(mp3 mp4).include?(params[:type])
          # hack alert -- iTunes (and maybe others who follow the same podcast
          # spec) requires that the download URL for podcast items end in .mp3
          # or another supported media type. Normally, the Kaltura download URL
          # doesn't end in .mp3. But Kaltura's first download URL redirects to
          # the same download url with /relocate/filename.ext appended, so we're
          # just going to explicitly append that to skip the first redirect, so
          # that iTunes will download the podcast items. This doesn't appear to
          # be documented anywhere though, so we're talking with Kaltura about
          # a more official solution.
          url = "#{url}/relocate/download.#{params[:type]}"
        end
        redirect_to url
      else
        render :json => { 'url' => url }
      end
    else
      render :status => 404, :text => t('could_not_find_url', "Could not find download URL")
    end
  end

  def merge
    @user_about_to_go_away = User.find_by_uuid(session[:merge_user_uuid]) if session[:merge_user_uuid].present?
    @user_about_to_go_away = nil unless @user_about_to_go_away.id == params[:user_id].to_i

    if params[:new_user_uuid] && @true_user = User.find_by_uuid(params[:new_user_uuid])
      if @true_user.grants_right?(@current_user, session, :manage_logins) && @user_about_to_go_away.grants_right?(@current_user, session, :manage_logins)
        @user_that_will_still_be_around = @true_user
      else
        @user_that_will_still_be_around = nil
      end
    else
      @user_that_will_still_be_around = @current_user
    end

    if @user_about_to_go_away && @user_that_will_still_be_around && @user_about_to_go_away.id.to_s == params[:user_id]
      @user_about_to_go_away.move_to_user(@user_that_will_still_be_around)
      @user_that_will_still_be_around.touch
      session.delete(:merge_user_uuid)
      flash[:notice] = t('user_merge_success', "User merge succeeded! %{first_user} and %{second_user} are now one and the same.", :first_user => @user_that_will_still_be_around.name, :second_user => @user_about_to_go_away.name)
    else
      flash[:error] = t('user_merge_fail', "User merge failed. Please make sure you have proper permission and try again.")
    end
    if @user_that_will_still_be_around == @current_user
      redirect_to profile_url
    elsif @user_that_will_still_be_around
      redirect_to user_url(@user_that_will_still_be_around)
    else
      redirect_to dashboard_url
    end
  end

  def admin_merge
    @user = User.find(params[:user_id])
    pending_user_id = params[:pending_user_id] || session[:pending_user_id]
    @pending_other_user = User.find_by_id(pending_user_id) if pending_user_id.present?
    @pending_other_user = nil if @pending_other_user == @user
    @other_user = User.find_by_id(params[:new_user_id]) if params[:new_user_id].present?
    if authorized_action(@user, @current_user, :manage_logins)
      if @user && (params[:clear] || !@pending_other_user)
        session[:pending_user_id] = @user.id
        @pending_other_user = nil
      end
      if @other_user && @other_user.grants_right?(@current_user, session, :manage_logins)
        session[:merge_user_id] = @user.id
        session[:merge_user_uuid] = @user.uuid
        session.delete(:pending_user_id)
      else
        @other_user = nil
      end
      render :action => 'admin_merge'
    end
  end

  def confirm_merge
    @user = User.find_by_uuid(session[:merge_user_uuid]) if session[:merge_user_uuid].present?
    @user = nil unless @user && @user.id == session[:merge_user_id]
    if @user && @user != @current_user
      render :action => 'confirm_merge'
    else
      session[:merge_user_uuid] = @current_user.uuid
      session[:merge_user_id] = @current_user.id
      store_location(user_confirm_merge_url(@current_user.id))
      render :action => 'merge'
    end
  end

  def assignments_needing_grading
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :read)
      res = @user.assignments_needing_grading
      render :json => res.to_json
    end
  end

  def assignments_needing_submitting
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :read)
      render :json => @user.assignments_needing_submitting.to_json
    end
  end

  def mark_avatar_image
    if params[:remove]
      if authorized_action(@user, @current_user, :remove_avatar)
        @user.avatar_image = {}
        @user.save
        render :json => @user.to_json
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
      render :json => {:reported => true}.to_json
    end
  end

  def delete
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, [:manage, :manage_logins])
      if @user.pseudonyms.any? {|p| p.managed_password? }
        unless @user.grants_right?(@current_user, session, :manage_logins)
          flash[:error] = t('no_deleting_sis_user', "You cannot delete a system-generated user")
          redirect_to profile_url
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
  # @example_response
  #   {
  #     "id":133,
  #     "login_id":"bieber@example.com",
  #     "name":"Justin Bieber",
  #     "short_name":"The Biebs",
  #     "sortable_name":"Bieber, Justin"
  #   }
  def destroy
    @user = api_request? ? api_find(User, params[:id]) : User.find(params[:id])
    if authorized_action(@user, @current_user, [:manage, :manage_logins])
      @user.destroy(@user.grants_right?(@current_user, session, :manage_logins))
      if @user == @current_user
        @pseudonym_session.destroy rescue true
        reset_session
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
      render :json => @user.to_json(:include_root => false)
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
    @context.courses.each do |context|
      @entries.concat context.assignments.active
      @entries.concat context.calendar_events.active
      @entries.concat context.discussion_topics.active
      @entries.concat context.default_wiki_wiki_pages.select{|p| !p.deleted? }
    end
    @entries = @entries.select{|e| e.updated_at > 1.weeks.ago }
    @entries.each do |entry|
      feed.entries << entry.to_atom(:include_context => true, :context => @context)
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def require_open_registration
    get_context
    @context = @domain_root_account || Account.default unless @context.is_a?(Account)
    @context = @context.root_account
    if !@context.grants_right?(@current_user, session, :manage_user_logins) && (!@context.open_registration? || !@context.no_enrollments_can_create_courses? || @context != Account.default)
      flash[:error] = t('no_open_registration', "Open registration has not been enabled for this account")
      respond_to do |format|
        format.html { redirect_to root_url }
        format.json { render :json => {}, :status => 403 }
      end
      return false
    end
  end

  def menu_courses
    render :json => Rails.cache.fetch(['menu_courses', @current_user].cache_key) {
      @template.map_courses_for_menu(@current_user.menu_courses)
    }
  end

  def all_menu_courses
    render :json => Rails.cache.fetch(['menu_courses', @current_user].cache_key) {
      @template.map_courses_for_menu(@current_user.courses_with_primary_enrollment)
    }
  end

  protected :require_open_registration

  def teacher_activity
    @teacher = User.find(params[:user_id])
    if @teacher == @current_user || authorized_action(@teacher, @current_user, :view_statistics)
      @courses = {}

      if params[:student_id]
        student = User.find(params[:student_id])
        enrollments = student.student_enrollments.active.all(:include => :course)
        enrollments.each do |enrollment|
          should_include = enrollment.course.user_has_been_teacher?(@teacher) && 
                           enrollment.course.enrollments_visible_to(@teacher, true).find_by_id(enrollment.id) && 
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
        if !course.user_has_been_teacher?(@teacher)
          flash[:error] = t('errors.user_not_teacher', "That user is not a teacher in this course")
          redirect_to_referrer_or_default(root_url)
        elsif authorized_action(course, @current_user, :read_reports)
          Enrollment.recompute_final_score_if_stale(course)
          @courses[course] = teacher_activity_report(@teacher, course, course.enrollments_visible_to(@teacher, true))
        end
      end

    end
  end

  def avatar_image
    cancel_cache_buster
    return redirect_to(params[:fallback] || '/images/no_pic.gif') unless service_enabled?(:avatars)
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
    url = Rails.cache.fetch(Cacher.avatar_cache_key(user_id, account_avatar_setting)) do
      user = User.find_by_id(user_id) if user_id.present?
      if user && account_avatar_setting != 'disabled'
        user.avatar_url(nil, account_avatar_setting, "%{fallback}")
      else
        ''
      end
    end
    fallback = User.avatar_fallback_url(params[:fallback], request)
    redirect_to (url.blank? || url == "%{fallback}") ?
      fallback :
      url.sub(CGI.escape("%{fallback}"), CGI.escape(fallback))
  end

  include Api::V1::UserFollow

  # @API Follow a user
  # @beta
  #
  # Follow this user. If the current user is already following the
  # target user, nothing happens. The target user must have a public profile in
  # order to follow it.
  #
  # On success, returns the User object. Responds with a 401 if the user
  # doesn't have permission to follow the target user, or a 400 if the user
  # can't follow the target user (if the user and target user are the same, for
  # example).
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/followers/self \ 
  #          -X PUT \ 
  #          -H 'Content-Length: 0' \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       following_user_id: 5,
  #       followed_user_id: 6,
  #       created_at: <timestamp>
  #     }
  def follow
    @user = api_find(User, params[:user_id])
    if authorized_action(@user, @current_user, :follow)
      user_follow = UserFollow.create_follow(@current_user, @user)
      if !user_follow.new_record?
        render :json => user_follow_json(user_follow, @current_user, session)
      else
        render :json => user_follow.errors, :status => :bad_request
      end
    end
  end

  # @API Un-follow a user
  # @beta
  #
  # Stop following this user. If the current user is not already
  # following the target user, nothing happens.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/followers/self \ 
  #          -X DELETE \ 
  #          -H 'Authorization: Bearer <token>'
  def unfollow
    @user = api_find(User, params[:user_id])
    if authorized_action(@user, @current_user, :follow)
      user_follow = @current_user.user_follows.find(:first, :conditions => { :followed_item_id => @user.id, :followed_item_type => 'User' })
      user_follow.try(:destroy)
      render :json => { "ok" => true }
    end
  end

  protected

  def teacher_activity_report(teacher, course, student_enrollments)
    ids = student_enrollments.map(&:user_id)
    data = {}
    student_enrollments.each { |e| data[e.user.id] = { :enrollment => e, :ungraded => [] } }

    # find last interactions
    last_comment_dates = SubmissionComment.for_context(course).maximum(
      :created_at,
      :group => 'recipient_id',
      :conditions => ["author_id = ? AND recipient_id IN (?)", teacher.id, ids])
    last_comment_dates.each do |user_id, date|
      next unless student = data[user_id]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end
    last_message_dates = ConversationMessage.maximum(
      :created_at,
      :joins => 'INNER JOIN conversation_participants ON conversation_participants.conversation_id=conversation_messages.conversation_id',
      :group => ['conversation_participants.user_id', 'conversation_messages.author_id'],
      :conditions => [ 'conversation_messages.author_id = ? AND conversation_participants.user_id IN (?) AND NOT conversation_messages.generated', teacher.id, ids ])
    last_message_dates.each do |key, date|
      next unless student = data[key.first.to_i]
      student[:last_interaction] = [student[:last_interaction], date].compact.max
    end

    # find all ungraded submissions in one query
    ungraded_submissions = course.submissions.all(
      :include => :assignment,
      :conditions => ["user_id IN (?) AND #{Submission.needs_grading_conditions}", ids])
    ungraded_submissions.each do |submission|
      next unless student = data[submission.user_id]
      student[:ungraded] << submission
    end

    if course.root_account.enable_user_notes?
      data.each { |k,v| v[:last_user_note] = nil }
      # find all last user note times in one query
      note_dates = UserNote.active.maximum(
        :created_at,
        :group => 'user_id',
        :conditions => ["created_by_id = ? AND user_id IN (?)", teacher.id, ids])
      note_dates.each do |user_id, date|
        next unless student = data[user_id]
        student[:last_user_note] = date
      end
    end

    data.values.sort_by { |e| e[:enrollment].user.sortable_name.downcase }
  end
  

end
