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

class ContextController < ApplicationController
  include SearchHelper

  before_filter :require_context, :except => [:inbox, :inbox_item, :destroy_inbox_item, :mark_inbox_as_read, :create_media_object, :kaltura_notifications, :media_object_redirect, :media_object_inline, :media_object_thumbnail, :object_snippet, :discussion_replies]
  before_filter :require_user, :only => [:inbox, :inbox_item, :report_avatar_image, :discussion_replies]
  before_filter :reject_student_view_student, :only => [:inbox, :inbox_item, :discussion_replies]
  protect_from_forgery :except => [:kaltura_notifications, :object_snippet]

  def create_media_object
    @context = Context.find_by_asset_string(params[:context_code])
    if authorized_action(@context, @current_user, :read)
      if params[:id] && params[:type] && @context.respond_to?(:media_objects)
        self.extend TextHelper
        @media_object = @context.media_objects.find_or_initialize_by_media_id_and_media_type(params[:id], params[:type])
        @media_object.title = truncate_text(params[:title], :max_length => 255) if params[:title]
        @media_object.user = @current_user
        @media_object.media_type = params[:type]
        @media_object.root_account_id = @domain_root_account.id if @domain_root_account && @media_object.respond_to?(:root_account_id)
        @media_object.user_entered_title = truncate_text(params[:user_entered_title], :max_length => 255) if params[:user_entered_title] && !params[:user_entered_title].empty?
        @media_object.save
      end
      render :json => @media_object
    end
  end
  
  def media_object_inline
    @show_embedded_chat = false
    @show_left_side = false
    @show_right_side = false
    @media_object = MediaObject.by_media_id(params[:id]).first
    render
  end
  
  def media_object_redirect
    mo = MediaObject.by_media_id(params[:id]).first
    mo.viewed! if mo
    config = Kaltura::ClientV3.config
    if config
      redirect_to Kaltura::ClientV3.new.assetSwfUrl(params[:id], request.ssl? ? "https" : "http")
    else
      render :text => t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def media_object_thumbnail
    media_id = params[:id]
    # we prefer using the MediaObject if it exists (so that it can give us
    # a different media_id if it wants to), but we will also use the provided
    # media id directly if we can't find a MediaObject. (They don't always get
    # created yet.)
    mo = MediaObject.by_media_id(media_id).first
    width = params[:width]
    height = params[:height]
    type = (params[:type].presence || 2).to_i
    config = Kaltura::ClientV3.config
    if config
      redirect_to Kaltura::ClientV3.new.thumbnail_url(mo.try(:media_id) || media_id,
                                                      :width => width,
                                                      :height => height,
                                                      :type => type,
                                                      :protocol => (request.ssl? ? "https" : "http")),
                  :status => 301
    else
      render :text => t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def kaltura_notifications
    request_params = request.request_parameters.to_a.sort_by{|k, v| k }.select{|k, v| k != 'sig' }
    logger.info('=== KALTURA NOTIFICATON ===')
    logger.info(request_params.to_yaml)
    if params[:signed_fields]
      valid_fields = params[:signed_fields].split(",")
      request_params = request_params.select{|k, v| valid_fields.include?(k.to_s) }
    end
    str = ""
    request_params.each do |k, v|
      str += k.to_s + v.to_s
    end
    hash = Digest::MD5.hexdigest(Kaltura::ClientV3.config['secret_key'] + str)
    if hash == params[:sig]
      notifications = {}
      if params[:multi_notification] != 'true'
        notifications[0] = request.request_parameters
      else
        request.request_parameters.each do |k, value|
          key = k.to_s
          if match = key.match(/\Anot([^_]*)_(.*)\z/)
            num = match[1].to_s
            property = match[2].to_s
            notifications[num] ||= {}
            notifications[num][property] = value
          end
        end
      end
      notifications.each do |key, notification|
        if notification[:notification_type] == 'entry_add'
          entry_id = notification[:entry_id]
          mo = MediaObject.find_or_initialize_by_media_id(entry_id)
          if !mo.new_record? || (notification[:partner_data] && !notification[:partner_data].empty?)
            data = JSON.parse(notification[:partner_data]) rescue nil
            if data && data['root_account_id'] && data['context_code']
              context = Context.find_by_asset_string(data['context_code'])
              context = nil unless context.respond_to?(:is_a_context?) && context.is_a_context?
              user = User.find_by_id(data['puser_id'].split("_").first) if data['puser_id'].present?

              mo.context ||= context
              mo.user ||= user
              mo.save!
              mo.send_later(:retrieve_details)
            end
          end
        elsif notification[:notification_type] == 'entry_delete'
          entry_id = notification[:entry_id]
          mo = MediaObject.by_media_id(entry_id).first
          mo.destroy_without_destroying_attachment
        end
      end
      logger.info(notifications.to_yaml)
      render :text => "ok"
    else
      logger.info("md5 should have been #{hash} but was #{params[:sig]}")
      render :text => "failure"
    end
  rescue => e
    logger.warn("=== KALTURA NOTIFICATON ERROR ===")
    logger.warn(e.to_s)
    logger.warn(e.backtrace.join("\n"))
    render :text => "failure"
  end

  # safely render object and embed tags as part of user content, by using a
  # iframe pointing to the separate files domain that doesn't contain a user's
  # session. see lib/user_content.rb and the user_content calls throughout the
  # views.
  def object_snippet
    if HostUrl.has_file_host? && !HostUrl.is_file_host?(request.host_with_port)
      return render(:nothing => true, :status => 400)
    end

    @snippet = params[:object_data] || ""
    hmac = Canvas::Security.hmac_sha1(@snippet)

    if hmac != params[:s]
      return render :nothing => true, :status => 400
    end

    # http://blogs.msdn.com/b/ieinternals/archive/2011/01/31/controlling-the-internet-explorer-xss-filter-with-the-x-xss-protection-http-header.aspx
    # recent versions of IE and Webkit have added client-side XSS prevention
    # measures. if data that includes potentially dangerous strings like
    # "<script..." or "<object..." is sent to the server and then that exact
    # same string is rendered in the html response, the browser will refuse to
    # render that part of the content. this header tells the browser that we're
    # doing it on purpose, so skip the XSS detection.
    response['X-XSS-Protection'] = '0'
    @snippet = Base64.decode64(@snippet)
    render :layout => false
  end

  def inbox_item
    @item = @current_user.inbox_items.find_by_id(params[:id]) if params[:id].present?
    if !@item
      flash[:error] = t(:message_removed, "The message you were trying to view has been removed")
      redirect_to inbox_url
      return
    else
      @item.mark_as_read
      @asset = @item.asset
    end
    respond_to do |format|
      format.html do
        if @asset.is_a?(DiscussionEntry)
          redirect_to named_context_url(@asset.discussion_topic.context, :context_discussion_topic_url, @asset.discussion_topic_id, :discussion_entry_id => @asset.id)
        elsif @asset.is_a?(SubmissionComment)
          redirect_to named_context_url(@asset.submission.context, :context_assignment_submission_url, @asset.submission.assignment_id, @asset.submission.user_id)
        elsif @asset.nil?
          flash[:notice] = t(:message_deleted, "This message has been deleted")
          redirect_to inbox_url
        else
          flash[:notice] = t(:bad_message, "This message could not be displayed")
          redirect_to inbox_url
        end
      end
      format.json do
        json_params = {
          :include => [:attachments, :users],
          :methods => :formatted_body,
          :user_content => %w(formatted_body),
        }
        @asset[:is_student] = !!@item.context.enrollments.all_student.find_by_user_id(@item.sender_id) rescue false
        render :json => @asset.as_json(json_params)
      end
    end
  end

  def destroy_inbox_item
    @item = @current_user.inbox_items.find_by_id(params[:id]) if params[:id].present?
    @asset = @item && @item.asset
    @item && @item.destroy
    render :json => @item
  end
  
  def chat
    if !Tinychat.config
      flash[:error] = t(:chat_not_enabled, "Chat has not been enabled for this Canvas site")
      redirect_to named_context_url(@context, :context_url)
      return
    end
    if authorized_action(@context, @current_user, :read_roster)
      return unless tab_enabled?(@context.class::TAB_CHAT)

      add_crumb(t('#crumbs.chat', "Chat"), named_context_url(@context, :context_chat_url))
      self.active_tab="chat"

      js_env :tinychat => {
               :room => "inst#{Digest::MD5.hexdigest(@context.asset_string)}",
               :nick => (@current_user.short_name.gsub(/[^\w]+/, '_').sub(/_\z/, '') rescue 'user'),
               :key  => Tinychat.config['api_key']
             }

      res = nil
      begin
        session[:last_chat] ||= {}
        if true || !session[:last_chat][@context.id] || !session[:last_chat][@context.id][:last_check_at] || session[:last_chat][@context.id][:last_check_at] < 5.minutes.ago
          session[:last_chat][@context.id] = {}
          session[:last_chat][@context.id][:last_check_at] = Time.now
          require 'net/http'
          details_url = URI.parse("http://api.tinychat.com/i-#{ Digest::MD5.hexdigest(@context.asset_string) }.json")
          req = Net::HTTP::Get.new(details_url.path)
          data = Net::HTTP.start(details_url.host, details_url.port) {|http|
            http.read_timeout = 1
            http.request(req)
          }
          res = data
        end
      rescue => e
      rescue Timeout::Error => e
      end
      @room_details = session[:last_chat][@context.id][:data] rescue nil
      if res || !@room_details
        @room_details = ActiveSupport::JSON.decode(res.body) rescue nil
      end
      if @room_details
        session[:last_chat][@context.id][:data] = @room_details
      end
      respond_to do |format|
        format.html {
          log_asset_access("chat:#{@context.asset_string}", "chat", "chat")
          render :action => 'chat'
        }
        format.json { render :json => @room_details }
      end
    end
  end

  def chat_iframe
    render :layout => false
  end
  
  def inbox
    redirect_to conversations_url, :status => :moved_permanently
  end

  def discussion_replies
    add_crumb(t('#crumb.conversations', "Conversations"), conversations_url)
    add_crumb(t('#crumb.discussion_replies', "Discussion Replies"), discussion_replies_url)
    @messages = @current_user.inbox_items.active.paginate(:page => params[:page], :per_page => 15)
    log_asset_access("inbox:#{@current_user.asset_string}", "inbox", 'other')
    respond_to do |format|
      format.html { render :action => :inbox }
      format.json { render :json => @messages.map{ |m| m.as_json(methods: [:sender_name]) } }
    end
  end
  
  def mark_inbox_as_read
    flash[:notice] = t(:all_marked_read, "Inbox messages all marked as read")
    if @current_user
      InboxItem.where(:user_id => @current_user).update_all(:workflow_state => 'read')
      User.where(:id => @current_user).update_all(:unread_inbox_items_count => (@current_user.inbox_items.unread.count rescue 0))
    end
    respond_to do |format|
      format.html { redirect_to inbox_url }
      format.json { render :json => {:marked_as_read => true} }
    end
  end

  def roster
    return unless authorized_action(@context, @current_user, [:read_roster, :manage_students, :manage_admin_users])
    log_asset_access("roster:#{@context.asset_string}", 'roster', 'other')

    if @context.is_a?(Course)
      sections = @context.course_sections.active.select([:id, :name])
      all_roles = Role.role_data(@context, @current_user)
      load_all_contexts(:context => @context)
      js_env({
        :ALL_ROLES => all_roles,
        :SECTIONS => sections.map { |s| { :id => s.id.to_s, :name => s.name } },
        :USER_LISTS_URL => polymorphic_path([@context, :user_lists], :format => :json),
        :ENROLL_USERS_URL => course_enroll_users_url(@context),
        :SEARCH_URL => search_recipients_url,
        :COURSE_ROOT_URL => "/courses/#{ @context.id }",
        :CONTEXTS => @contexts,
        :resend_invitations_url => course_re_send_invitations_url(@context),
        :permissions => {
          :manage_students => (manage_students = @context.grants_right?(@current_user, session, :manage_students)),
          :manage_admin_users => (manage_admins = @context.grants_right?(@current_user, session, :manage_admin_users)),
          :add_users => manage_students || manage_admins
        },
        :course => {
          :id => @context.id,
          :completed => (completed = @context.completed?),
          :soft_concluded => (soft_concluded = @context.soft_concluded?),
          :concluded => completed || soft_concluded,
          :teacherless => @context.teacherless?,
          :available => @context.available?,
          :pendingInvitationsCount => @context.invited_count_visible_to(@current_user)
        }
      })
    elsif @context.is_a?(Group)
      @users         = @context.participating_users.order_by_sortable_name.uniq
      @primary_users = { t('roster.group_members', 'Group Members') => @users }
      if course = @context.context.try(:is_a?, Course) && @context.context
        @secondary_users = { t('roster.teachers_and_tas', 'Teachers & TAs') => course.instructors.order_by_sortable_name.uniq }
      end
    end

    @secondary_users ||= {}
    @groups = @context.groups.active rescue []
  end

  def prior_users
    if authorized_action(@context, @current_user, [:manage_students, :manage_admin_users, :read_prior_roster])
      @prior_users = @context.prior_users.
        where(Enrollment.not_fake.proxy_options[:conditions]).
        select("users.*, NULL AS prior_enrollment").
        by_top_enrollment.
        paginate(:page => params[:page], :per_page => 20)

      users = @prior_users.index_by(&:id)
      if users.present?
        # put the relevant prior enrollment on each user
        @context.prior_enrollments.where({:user_id => users.keys}).
          top_enrollment_by(:user_id, :student).
          each { |e| users[e.user_id].write_attribute :prior_enrollment, e }
      end
    end
  end

  def roster_user_services
    if authorized_action(@context, @current_user, :read_roster)
      @users = @context.users.order_by_sortable_name
      @users_hash = {}
      @users_order_hash = {}
      @users.each_with_index{|u, i| @users_hash[u.id] = u; @users_order_hash[u.id] = i }
      @current_user_services = {}
      @current_user.user_services.each{|s| @current_user_services[s.service] = s }
      @services = UserService.for_user(@users).sort_by{|s| @users_order_hash[s.user_id] || SortLast}
      @services = @services.select{|service|
        !UserService.configured_service?(service.service) || feature_and_service_enabled?(service.service.to_sym)
      }
      @services_hash = @services.to_a.clump_per{|s| s.service }
    end
  end

  def roster_user_usage
    if authorized_action(@context, @current_user, :read_reports)
      @user = @context.users.find(params[:user_id])
      @accesses = AssetUserAccess.for_user(@user).for_context(@context).most_recent.paginate(:page => params[:page], :per_page => 50)
      respond_to do |format|
        format.html
        format.json { render :json => @accesses.map{ |a| a.as_json(methods: [:readable_name, :asset_class_name]) } }
      end
    end
  end

  def roster_user
    if authorized_action(@context, @current_user, :read_roster)
      user_id = Shard.relative_id_for(params[:id], @context.shard)
      if @context.is_a?(Course)
        @membership = @context.enrollments.find_by_user_id(user_id)
        log_asset_access(@membership, "roster", "roster")
      elsif @context.is_a?(Group)
        @membership = @context.group_memberships.find_by_user_id(user_id)
      end
      @user = @membership.user rescue nil
      if !@user
        if @context.is_a?(Course)
          flash[:error] = t('no_user.course', "That user does not exist or is not currently a member of this course")
        elsif @context.is_a?(Group)
          flash[:error] = t('no_user.group', "That user does not exist or is not currently a member of this group")
        end
        redirect_to named_context_url(@context, :context_users_url)
        return
      end

      @topics = @context.discussion_topics.active.reject{|a| a.locked_for?(@current_user, :check_policies => true) }
      @entries = []
      @topics.each do |topic|
        @entries << topic if topic.user_id == @user.id
        @entries.concat topic.discussion_entries.active.find_all_by_user_id(@user.id)
      end
      @entries = @entries.sort_by {|e| e.created_at }
      @enrollments = @context.enrollments.for_user(@user) rescue []
      @messages = @entries
      @messages = @messages.select{|m| m.grants_right?(@current_user, session, :read) }.sort_by{|e| e.created_at }.reverse

      if @domain_root_account.enable_profiles?
        @user_data = profile_data(
          @user.profile,
          @current_user,
          session,
          ['links', 'user_services']
        )
        render :action => :new_roster_user
        return false
      end
      true
    end
  end

  def undelete_index
    if authorized_action(@context, @current_user, :manage_content)
      @item_types = [:all_discussion_topics, :assignments, :assignment_groups, :enrollments,
                     :rubrics, :collaborations, :quizzes, :context_modules].map {|assoc| @context.send(assoc) if @context.respond_to?(assoc)}.compact

      @item_types << @context.wiki.wiki_pages if @context.respond_to? :wiki
      @deleted_items = []
      @item_types.each do |scope|
        @deleted_items += scope.where(:workflow_state => 'deleted').limit(25).all
      end
      @deleted_items += @context.attachments.where(:file_state => 'deleted').limit(25).all
      @deleted_items.sort_by{|item| item.read_attribute(:deleted_at) || item.created_at }.reverse
    end
  end

  def undelete_item
    if authorized_action(@context, @current_user, :manage_content)
      type = params[:asset_string].split("_")
      id = type.pop
      type = type.join("_")
      scope = @context
      scope = @context.wiki if type == 'wiki_pages'
      type = 'all_discussion_topic' if type == 'discussion_topic'
      @item = scope.send(type.pluralize).find(id)
      @item.restore
      render :json => @item
    end
  end
end
