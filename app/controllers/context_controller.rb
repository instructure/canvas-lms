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
  before_filter :require_user_for_context, :except => [:inbox, :inbox_item, :destroy_inbox_item, :mark_inbox_as_read, :create_media_object, :kaltura_notifications, :context_message_reply, :media_object_redirect, :media_object_inline]
  before_filter :require_user, :only => [:inbox, :inbox_item, :report_avatar_image]
  protect_from_forgery :except => [:kaltura_notifications]
  
  def create_roster_message
    get_context
    if authorized_action(@context, @current_user, :send_messages)
      params[:context_message][:user] = @current_user
      recipients = params[:context_message].delete :recipients
      attachments = params[:context_message].delete :attachments
      root_id = params[:context_message].delete(:root_context_message_id)
      unless root_id.blank?
        params[:context_message][:root_context_message] = @context.context_messages.find(root_id)
        params[:context_message][:root_context_message].read(params[:context_message][:user])
      end
      @message = @context.context_messages.build(params[:context_message])
      @message.recipients = recipients
      @message.attachments = attachments
      respond_to do |format|
        if @message.save
          if params[:also_announcement] == '1'
            @announcement = @context.announcements.build(:title => @message.subject, :message => @message.body, :user => @message.user)
            # NOTE: a ContextMessage can have many attachments. but an Announcement can only have 1, so I am just attaching the first.
            # attachments is a HashWithIndifferentAcess .first will give you an array of ["1", #<File:..>] 
            # so we want the second element of that array
            if (attachments.first[1].size > 0 rescue nil) && @announcement.grants_right?(@current_user, session, :attach)
              @announcement.attachment = @context.attachments.create(:uploaded_data => attachments.first[1])
            end
            @announcement.save_without_broadcasting
          end
          if params[:add_as_user_note] == '1'
            UserNote.send_later :add_from_message, @message
          end
          format.html { redirect_to named_context_url(@context, :context_users_url) }
          format.json { render :json => @message.to_json(:methods => [:formatted_body, :readable_size], :include => [:users, :attachments]) }
          format.text { render :json => @message.to_json(:methods => [:formatted_body, :readable_size], :include => [:users, :attachments]) }
        else
          format.html { redirect_to named_context_url(@context, :context_users_url) }
          format.json { render :json => @message.errors.to_json }
          format.text { render :json => @message.errors.to_json }
        end
      end
    end
  end
  
  def create_media_object
    @context = Context.find_by_asset_string(params[:context_code])
    if authorized_action(@context, @current_user, :read)
      if params[:id] && params[:type] && @context.respond_to?(:media_objects)
        @media_object = @context.media_objects.find_or_initialize_by_media_id_and_media_type(params[:id], params[:type])
        @media_object.title = params[:title] if params[:title]
        @media_object.user = @current_user
        @media_object.media_type = params[:type]
        @media_object.root_account_id = @domain_root_account.id if @domain_root_account && @media_object.respond_to?(:root_account_id)
        @media_object.user_entered_title = params[:user_entered_title] if params[:user_entered_title] && !params[:user_entered_title].empty?
        @media_object.save
      end
      render :json => @media_object.to_json
    end
  end
  
  def media_object_inline
    @show_left_side = false
    @show_right_side = false
    @media_object = MediaObject.find_by_media_id(params[:id])
    render
  end
  
  def media_object_redirect
    mo = MediaObject.find_by_media_id(params[:id])
    mo ||= MediaObject.find_by_old_media_id(params[:id])
    mo.viewed! if mo
    config = Kaltura::ClientV3.config
    if config
      redirect_to Kaltura::ClientV3.new.assetSwfUrl(params[:id])
    else
      render :text => "Media Objects not configured"
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
              user = User.find_by_id(data['puser_id'] && data['puser_id'].split("_").first)
              mo.context ||= context
              mo.user ||= user
              mo.save!
              mo.send_later(:retrieve_details)
            end
          end
        elsif notification[:notification_type] == 'entry_delete'
          entry_id = notification[:entry_id]
          mo = MediaObject.find_by_media_id(entry_id)
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
  
  def context_object
    @context = Context.find_by_asset_string(params[:context_code])
    @asset = @context.find_asset(params[:asset_string])
    @asset = @context if params[:asset_string] == params[:context_code]
    @headers = false
    @show_left_side = false
    @padless = true
    if params[:user_id] && params[:ts] && params[:verifier]
      @user = User.find_by_id(params[:user_id])
      @user = nil unless @user && @user.valid_access_verifier?(params[:ts], params[:verifier])
    end
    raise ActiveRecord::RecordNotFound.new("Invalid context snippet url") unless @asset && @context
    if authorized_action(@asset, @user, :read)
      html = @asset.description rescue nil
      html ||= @asset.body rescue nil
      html ||= @asset.message rescue nil
      html ||= @asset.syllabus_body rescue nil
      dom = Nokogiri::HTML::DocumentFragment.parse(html)
      @snippet = dom.css("object,embed")[params[:key].to_i]
      raise ActiveRecord::RecordNotFound.new("Invalid context snippet url") unless @snippet
    end
  end
  
  def context_message_reply
    @message = ContextMessage.find(params[:id])
    if authorized_action(@message, @current_user, :read)
      hash = {
        :context_code => @message.context_code,
        :recipients => @message.user_id.to_s,
        :subject => "Re: #{@message.subject.sub(/\ARe: /, "")}"
      }
      redirect_to inbox_url(:reply_id => @message.id, :anchor => "reply" + hash.to_json)
    end
  end
  
  def inbox_item
    @item = @current_user.inbox_items.find_by_id(params[:id])
    if !@item
      flash[:error] = "The message you were trying to view has been removed"
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
        elsif @asset.is_a?(ContextMessage)
          redirect_to inbox_url(:message_id => @asset.id)
        elsif @asset.nil?
          flash[:notice] = "This message has been deleted"
          redirect_to inbox_url
        else
          flash[:notice] = "Unknown item type, #{@asset.class.to_s}"
          redirect_to inbox_url
        end
      end
      format.json do
        json_params = {:include => [:attachments, :users], :methods => :formatted_body}
        if @asset.is_a?(ContextMessage) && @asset.protect_recipients && !@asset.cached_context_grants_right?(@current_user, session, :manage_students)
          json_params[:include] = [:attachments]
          json_params[:exclude] = [:recipients]
        end
        if @asset.is_a?(ContextMessage)
          @asset.root_context_message_id ||= @asset.id
        end
        @asset[:is_student] = !!@item.context.enrollments.all_student.find_by_user_id(@item.sender_id) rescue false
        render :json => @asset.to_json(json_params)
      end
    end
  end
  
  def destroy_inbox_item
    @item = @current_user.inbox_items.find_by_id(params[:id])
    @asset = @item && @item.asset
    @item && @item.destroy
    render :json => @item.to_json
  end
  
  def read_roster_message
    get_context
    @message = @context.context_messages.find(params[:id])
    @item = @current_user.inbox_items.find_by_workflow_state('unread').detect{|i| i.asset_id == @message.id && i.asset_type == 'ContextMessage'}
    @item.mark_as_read if @item
    if authorized_action(@message, @current_user, :update)
      respond_to do |format|
        if @message.read(@current_user)
          format.json { render :json => @message.to_json(:include => [:attachments, :users], :methods => :formatted_body) }
        else
          format.json { render :json => @message.errors.to_json }
        end
      end
    end
  end
  
  def roster_message_attachment
    get_context
    @message = @context.context_messages.find(params[:message_id])
    if authorized_action(@message, @current_user, :read)
      @attachment = @message.attachments.find(params[:id])
      begin
        redirect_to @attachment.cacheable_s3_url
      rescue => e
        @not_found_message = "It looks like something went wrong when this file was uploaded, and we can't find the actual file.  You may want to notify the owner of the file and have them re-upload it."
        render :template => 'shared/errors/404_message', :status => :bad_request
      end
    end
  end
  
  def chat
    if !Tinychat.config
      flash[:error] = "Chat has not been enabled for this Canvas site"
      redirect_to named_context_url(@context, :context_url)
      return
    end
    if authorized_action(@context, @current_user, :read_roster)
      return unless tab_enabled?(@context.class::TAB_CHAT)
      
      add_crumb("Chat", named_context_url(@context, :context_chat_url))
      self.active_tab="chat"
      
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
        format.json { render :json => @room_details.to_json }
      end
    end
  end
  
  def inbox
    add_crumb(@current_user.short_name, named_context_url(@current_user, :context_url))
    add_crumb("Inbox", inbox_url)
    case params[:view]
    when 'sentbox'
      @messages_view = :sentbox
      @messages = @current_user.sentbox_context_messages
      @messages_view_header = "Sent Messages"
      @per_page = 10
    when 'inbox'
      @messages_view = :inbox
      @messages = @current_user.inbox_context_messages
      @messages_view_header = "Received Messages"
      @per_page = 10
    else # default view
      @messages_view = :action_items
      @messages = @current_user.inbox_items.active
      @messages_view_header = "Inbox"
      @per_page = 15
    end
    if params[:reply_id]
      @included_message = @current_user.inbox_context_messages.find(params[:reply_id])
      @included_message = nil unless @included_message.grants_right?(@current_user, session, :read)
    end
    if params[:message_id]
      @message = @current_user.inbox_context_messages.find(params[:message_id])
    end
    @messages = @messages.paginate(:page => params[:page], :per_page => @per_page)
    @past_message_contexts = @messages.once_per(&:context_code).map(&:context).compact.uniq rescue []
    @context = @current_user
    get_all_pertinent_contexts(true)
    @contexts << @included_message.context if @included_message && !@contexts.include?(@included_message.context)
    log_asset_access("inbox:#{@context.asset_string}", "inbox", 'other')
    @message_contexts = @contexts.select{|c| c.grants_right?(@current_user, session, :send_messages) }
    @all_message_contexts = (@past_message_contexts + @message_contexts).uniq
    respond_to do |format|
      format.html
      if @messages_view == :action_items
        format.json { render :json => @messages.to_json(:methods => [:sender_name]) }
      else
        format.json { render :json => @messages.to_json(:include => [:attachments, :users], :methods => :formatted_body) }
      end
    end
  end
  
  def mark_inbox_as_read
    flash[:notice] = "Inbox messages all marked as read"
    if @current_user
      InboxItem.update_all({:workflow_state => 'read'}, {:user_id => @current_user.id})
      User.update_all({:unread_inbox_items_count => (@current_user.inbox_items.unread.count rescue 0)}, {:id => @current_user.id})
    end
    respond_to do |format|
      format.html { redirect_to inbox_url }
      format.json { render :json => {:marked_as_read => true}.to_json }
    end
  end
  
  def recipients
    get_context
    if authorized_action(@context, @current_user, :send_messages)
      @users = @context.users.sort_by{|u| u.sortable_name }.uniq
      @default_users = @context.is_a?(Course) ? @context.teachers : @context.users
      res = {:users => @default_users, :teachers => @default_users}
      if @context.grants_right?(@current_user, session, :read_roster)
        if @context.is_a?(Course)
          @visible_students = @context.students_visible_to(@current_user)
          if @context.visibility_limited_to_course_sections?(@current_user)
            @bad_students = @context.students - @visible_students
            @users -= @bad_students
          end
          @groups = @context.groups.active.scoped(:include => {:group_memberships => :user})
          res = {:users => @users.sort_by{|u| u.sortable_name }.uniq,
            :groups => @groups,
            :teachers => @context.teachers.scoped(:select => 'id').map(&:id),
            :students => @visible_students.map(&:id),
            :observers => @context.observers.scoped(:select => 'id').map(&:id)
            }
          res[:group_members] = {}
          @groups.each do |group|
            res[:group_members][group.id] = group.group_memberships.active.map(&:user_id)
          end
        end
      end
      render :json => res.to_json
    end
  end
  
  def roster
    get_context

    if authorized_action(@context, @current_user, :read_roster)
      
      
      log_asset_access("roster:#{@context.asset_string}", "roster", "other")
      if @context.is_a?(Course)
        @enrollments_hash = {}
        @context.enrollments.sort_by{|e| [e.state_sortable, e.rank_sortable] }.each{|e| @enrollments_hash[e.user_id] ||= e }
        @students = @context.students_visible_to(@current_user).find(:all, :order => 'sortable_name').uniq
        @teachers = @context.admins.find(:all, :order => 'sortable_name').uniq
        user_ids = @students.map(&:id) & @teachers.map(&:id)
        if @context.visibility_limited_to_course_sections?(@current_user)
          user_ids = @students.map(&:id) + [@current_user.id]
        end
        @primary_users = {'Students' => @students}
        @secondary_users = {'Teachers & TA\'s' => @teachers}
        @messages = @context.context_messages.find(:all, :order => 'created_at DESC', :include => [:attachments, :context], :limit => 25)
        @messages = @messages.select{|m| !(([m.user_id] + m.recipients || []) & user_ids).empty? }
      elsif @context.is_a?(Group)
        @users = @context.participating_users.find(:all, :order => 'sortable_name').uniq
        @primary_users = {'Group Members' => @users}
        if @context.context && @context.context.is_a?(Course)
          @secondary_users = {'Teachers & TA\'s' => @context.context.admins.find(:all, :order => 'sortable_name').uniq}
        end
        @messages = @context.context_messages.find(:all, :order => 'created_at DESC', :include => [:attachments, :context], :limit => 25)
      end
      @secondary_users ||= {}
      @groups = @context.groups.active rescue []
      @categories = @groups.map{|g| g.category}.uniq
      @messages = @messages.select{|m| m.grants_right?(@current_user, session, :read) }
      @messages = @messages[0..10] unless params[:all_messages]
      respond_to do |format|
        format.html
        format.json { render :json => @messages.to_json(:methods => [:formatted_body, :user_name, :recipient_users], :include => {:attachments => {:methods => :readable_size}}) }
      end
    end
  end
  
  def prior_users
    get_context
    if authorized_action(@context, @current_user, :manage_admin_users)
      @prior_memberships = @context.enrollments.scoped(:conditions => {:workflow_state => 'completed'}, :include => :user).to_a.once_per(&:user_id).sort_by{|e| [e.rank_sortable(true), e.user.sortable_name] }
    end
  end

  def roster_user_services
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      @users = @context.users.order_by_sortable_name
      @users_hash = {}
      @users_order_hash = {}
      @users.each_with_index{|u, i| @users_hash[u.id] = u; @users_order_hash[u.id] = i }
      @current_user_services = {}
      @current_user.user_services.each{|s| @current_user_services[s.service] = s }
      @services = UserService.for_user(@users).sort_by{|s| @users_order_hash[s.user_id] || 9999}
      @services = @services.select{|service|
        !UserService.configured_service?(service.service) || feature_and_service_enabled?(service.service.to_sym)
      }
      @services_hash = @services.to_a.clump_per{|s| s.service }
    end
  end
  
  def roster_user_usage
    get_context
    if authorized_action(@context, @current_user, :manage_students)
      @user = @context.users.find(params[:user_id])
      @accesses = AssetUserAccess.for_user(@user).for_context(@context).most_recent.paginate(:page => params[:page], :per_page => 50)
      respond_to do |format|
        format.html
        format.json { render :json => @accesses.to_json(:methods => [:readable_name]) }
      end
    end
  end
  
  def roster_user
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      if @context.is_a?(Course)
        @membership = @context.enrollments.find_by_user_id(params[:id])
        log_asset_access(@enrollment, "roster", "roster")
      elsif @context.is_a?(Group)
        @membership = @context.group_memberships.find_by_user_id(params[:id])
      end
      @enrollment ||= @membership
      @user = @context.users.find(params[:id]) rescue nil
      if !@user
        flash[:error] = "That user does not exist or is not currently a member of this #{@context.class.to_s.downcase}"
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
      @messages += @user.context_messages.from_user(@user).for_context(@context)
      @messages = @messages.select{|m| m.grants_right?(@current_user, session, :read) }.sort_by{|e| e.created_at }.reverse
    end
  end
    
  def undelete_index
    if authorized_action(@context, @current_user, :manage_content)
      @item_types = {
        :discussion_topics => ['workflow_state = ?', 'deleted'],
        :assignments => ['workflow_state = ?', 'deleted'],
        :assignment_groups => ['workflow_state = ?', 'deleted'],
        :enrollments => ['workflow_state = ?', 'deleted'],
        :default_wiki_wiki_pages => ['workflow_state = ?', 'deleted'],
        :attachments => ['file_state = ?', 'deleted'],
        :rubrics => ['workflow_state = ?', 'deleted'],
        :collaborations => ['workflow_state = ?', 'deleted'],
        :quizzes => ['workflow_state = ?', 'deleted'],
        :context_modules => ['workflow_state = ?', 'deleted']
      }
      @deleted_items = []
      @item_types.each do |type, conditions|
        @deleted_items += @context.send(type).find(:all, :conditions => conditions, :limit => 25) rescue []
      end
      @deleted_items.sort_by{|item| item.read_attribute(:deleted_at) || item.created_at }.reverse
    end
  end
  
  def undelete_item
    if authorized_action(@context, @current_user, :manage_content)
      type = params[:asset_string].split("_")
      id = type.pop
      type = type.join("_")
      type = 'default_wiki_wiki_pages' if type == 'wiki_pages'
      @item = @context.send(type.pluralize).find(id)
      @item.restore
      render :json => @item
    end
  end
end
