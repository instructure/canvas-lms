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

class ConversationsController < ApplicationController
  include ConversationsHelper

  before_filter :require_user
  before_filter lambda { |c| c.avatar_size = 32 }, :only => :find_recipients
  before_filter :get_conversation, :only => [:show, :update, :destroy, :workflow_event, :add_recipients, :remove_messages]
  before_filter :load_all_contexts, :only => [:index, :find_recipients, :create, :add_message]
  before_filter :normalize_recipients, :only => [:create, :add_recipients]
  add_crumb(lambda { I18n.t 'crumbs.messages', "Conversations" }) { |c| c.send :conversations_url }

  def index
    @page_max = params[:count].try(:to_i) || 25
    @page = params[:page].try(:to_i) || 1
    conversations_scope = case params[:scope]
      when 'unread'
        @view_name = I18n.t('index.inbox_views.unread', 'Unread')
        @no_messages = I18n.t('no_unread_messages', 'You have no unread messages')
        @current_user.conversations.unread
      when 'labeled'
        @label, @view_name = ConversationParticipant.labels.detect{ |l| l.first == params[:label] }
        @view_name ||= I18n.t('index.inbox_views.labeled', 'Labeled')
        @no_messages = case @label
          when 'red': I18n.t('no_red_messages', 'You have no red messages')
          when 'orange': I18n.t('no_orange_messages', 'You have no orange messages')
          when 'yellow': I18n.t('no_yellow_messages', 'You have no yellow messages')
          when 'green': I18n.t('no_green_messages', 'You have no green messages')
          when 'blue': I18n.t('no_blue_messages', 'You have no blue messages')
          when 'purple': I18n.t('no_purple_messages', 'You have no purple messages')
          else I18n.t('no_labeled_messages', 'You have no labeled messages')
        end
        @current_user.conversations.labeled(@label)
      when 'archived'
        @view_name = I18n.t('index.inbox_views.archived', 'Archived')
        @no_messages = I18n.t('no_archived_messages', 'You have no archived messages')
        @disallow_messages = true
        @current_user.conversations.archived
      else
        @scope = :inbox
        @view_name = I18n.t('index.inbox_views.inbox', 'Inbox')
        @no_messages = I18n.t('no_messages', 'You have no messages')
        @current_user.conversations.default
    end
    @scope ||= params[:scope].to_sym
    @conversations_count = conversations_scope.count
    conversations = conversations_scope.scoped(:limit => @page_max, :offset => (@page - 1) * @page_max).all
    # optimize loading the most recent messages for each conversation into a single query
    last_messages = ConversationMessage.latest_for_conversations(conversations).human.
                      inject({}) { |hash, message|
                        if !hash[message.conversation_id] || hash[message.conversation_id].id < message.id
                          hash[message.conversation_id] = message
                        end
                        hash
                      }
    @conversations_json = conversations.map{ |c| jsonify_conversation(c, last_messages[c.conversation_id]) }
    @user_cache = Hash[*jsonify_users([@current_user]).map{|u| [u[:id], u] }.flatten]
    respond_to do |format|
      format.html
      format.json { render :json => @conversations_json }
    end
  end

  def create
    if @recipient_ids.present? && params[:body].present?
      batch_private_messages = !params[:group_conversation] && @recipient_ids.size > 1
      conversations = (batch_private_messages ? @recipient_ids : [@recipient_ids]).map do |recipients|
        recipients = Array(recipients)
        @conversation = @current_user.initiate_conversation(recipients)
        @message = create_message_on_conversation(@conversation, !batch_private_messages)
        @conversation
      end
      if batch_private_messages
        render :text => {:conversations => conversations.each(&:reload).select{|c|c.last_message_at}.map{|c|jsonify_conversation(c)}}.to_json
      else
        render :text => {:participants => jsonify_users(@conversation.participants(true, true)),
                         :conversation => jsonify_conversation(@conversation.reload),
                         :message => @message}.to_json
      end
    else
      render :text => {}.to_json, :status => :bad_request
    end
  end

  def show
    return redirect_to "/conversations/#/conversations/#{@conversation.conversation_id}" unless request.xhr?
    
    @conversation.mark_as_read! if @conversation.unread?
    submissions = []
    if @conversation.one_on_one?
      submissions = Submission.for_conversation_participant(@conversation).with_comments.map do |submission|
        assignment = submission.assignment
        recent_comments = submission.submission_comments.last(10).reverse
        {
          :id => submission.id,
          :course_id => assignment.context_id,
          :assignment_id => assignment.id,
          :author_id => submission.user_id,
          :created_at => submission.submitted_at,
          :updated_at => recent_comments.first.created_at,
          :title => assignment.title,
          :score => submission.score && assignment.points_possible ? "#{submission.score} / #{assignment.points_possible}" : submission.score,
          :comment_count => submission.submission_comments_count,
          :recent_comments => recent_comments.map{ |comment| {
            :id => comment.id,
            :author_id => comment.author_id,
            :created_at => comment.created_at,
            :body => comment.comment
          }}
        }
      end
      submissions = submissions.sort_by{ |s| s[:updated_at] }.reverse
    end
    render :json => {:participants => jsonify_users(@conversation.participants(true, true)),
                     :messages => @conversation.messages,
                     :submissions => submissions,
                     :conversation => params[:include_conversation] ? jsonify_conversation(@conversation) : nil}
  end

  def update
    if @conversation.update_attributes(params[:conversation])
      render :json => @conversation
    else
      render :json => @conversation.errors, :status => :bad_request
    end
  end

  def workflow_event
    event = params[:event].to_sym
    if [:mark_as_read, :mark_as_unread, :archive, :unarchive].include?(event) && @conversation.send(event)
      render :json => @conversation
    else
      # TODO: if it was archived/marked_as_read/etc. out-of-band, we should
      # handle it better (perhaps reload the conversation js-side)
      render :json => @conversation.errors, :status => :bad_request
    end
  end

  def mark_all_as_read
    @current_user.mark_all_conversations_as_read!
    render :json => {}
  end

  def destroy
    @conversation.remove_messages(:all)
    render :json => {}
  end

  def add_recipients
    if @recipient_ids.present?
      @conversation.add_participants(@recipient_ids)
      render :json => {:conversation => jsonify_conversation(@conversation.reload), :message => @conversation.messages.first}
    else
      render :json => {}, :status => :bad_request
    end
  end

  def add_message
    get_conversation(true)
    if params[:body].present?
      message = create_message_on_conversation
      render :text => {:conversation => jsonify_conversation(@conversation.reload), :message => message}.to_json
    else
      render :text => {}.to_json, :status => :bad_request
    end
  end

  def remove_messages
    if params[:remove]
      to_delete = []
      @conversation.messages.each do |message|
        to_delete << message if params[:remove].include?(message.id.to_s)
      end
      @conversation.remove_messages(*to_delete)
      render :json => @conversation
    end
  end

  def find_recipients
    max_results = params[:limit] ? params[:limit].to_i : 5
    max_results = nil if max_results < 0
    recipients = []
    exclude = params[:exclude] || []
    if params[:context]
      recipients = matching_participants(:search => params[:search], :context => params[:context], :limit => max_results, :exclude_ids => exclude.grep(/\A\d+\z/).map(&:to_i), :blank_avatar_fallback => true)
    elsif params[:search]
      contexts = params[:type] != 'user' ? matching_contexts(params[:search], exclude.grep(/\A(course|group)_\d+\z/)) : []
      participants = params[:type] != 'context' ? matching_participants(:search => params[:search], :limit => max_results, :exclude_ids => exclude.grep(/\A\d+\z/).map(&:to_i), :blank_avatar_fallback => true) : []
      if max_results
        if contexts.size < max_results / 2
          recipients = contexts + participants
        elsif participants.size < max_results / 2
          recipients = contexts[0, max_results - participants.size] + participants
        else
          recipients = contexts[0, max_results / 2] + participants
        end
        recipients = recipients[0, max_results]
      else
        recipients = contexts + participants
      end
    end
    render :json => recipients
  end

  def watched_intro
    unless @current_user.watched_conversations_intro?
      @current_user.watched_conversations_intro
      @current_user.save
    end
    render :json => {}
  end
  
  attr_writer :avatar_size

  private

  def normalize_recipients
    if params[:recipients]
      recipient_ids = params[:recipients]
      if recipient_ids.is_a?(String)
        recipient_ids = recipient_ids.split(/,/)
      end
      @recipient_ids = (
        matching_participants(:ids => recipient_ids.grep(/\A\d+\z/), :conversation_id => params[:from_conversation_id]).map{ |p| p[:id] } +
        matching_participants(:context => recipient_ids.grep(/\A(course|group)_\d+\z/)).map{ |p| p[:id] }
      ).uniq
    end
  end

  def load_all_contexts
    @contexts = {:courses => {}, :groups => {}}
    @current_user.concluded_courses.each do |course|
      @contexts[:courses][course.id] = {:id => course.id, :name => course.name, :type => :course, :active => course.recently_ended?, :can_add_notes => can_add_notes_to?(course) }
    end
    @current_user.courses.each do |course|
      @contexts[:courses][course.id] = {:id => course.id, :name => course.name, :type => :course, :active => true, :can_add_notes => can_add_notes_to?(course) }
    end
    @current_user.groups.each do |group|
      @contexts[:groups][group.id] = {:id => group.id, :name => group.name, :type => :group, :active => group.active? }
    end
  end

  def can_add_notes_to?(course)
    course.enable_user_notes && course.grants_right?(@current_user, nil, :manage_user_notes)
  end

  def matching_contexts(search, exclude = [])
    avatar_url = avatar_url_for_group(true)
    course_user_counts = @current_user.enrollment_visibility[:user_counts]
    group_user_counts = @contexts[:groups].inject({}){ |hash, group| hash[group.id] = group.users.size; hash }
    @contexts.values.map(&:values).flatten.
      select{ |context| search.downcase.strip.split(/\s+/).all?{ |part| context[:name].downcase.include?(part) } }.
      select{ |context| context[:active] }.
      sort_by{ |context| context[:name] }.
      map{ |context|
        {:id => "#{context[:type]}_#{context[:id]}",
         :name => context[:name],
         :avatar => avatar_url,
         :type => :context,
         :user_count => (context[:type] == :course ? course_user_counts : group_user_counts)[context[:id]]}
      }.
      reject{ |context|
        exclude.include?(context[:id])
      }
  end

  def matching_participants(options)
    jsonify_users(@current_user.messageable_users(options), options.delete(:blank_avatar_fallback))
  end

  def get_conversation(allow_deleted = false)
    @conversation = (allow_deleted ? @current_user.all_conversations : @current_user.conversations).find_by_conversation_id(params[:id] || params[:conversation_id] || 0)
    raise ActiveRecord::RecordNotFound unless @conversation
  end

  def create_message_on_conversation(conversation=@conversation, update_for_sender=true)
    message = conversation.add_message(params[:body], :forwarded_message_ids => params[:forwarded_message_ids], :update_for_sender => update_for_sender, :context => @domain_root_account) do |m|
      if params[:attachments]
        params[:attachments].sort_by{ |k,v| k.to_i }.each do |k,v|
          m.attachments.create(:uploaded_data => v) if v.present?
        end
      end

      media_id = params[:media_comment_id]
      media_type = params[:media_comment_type]
      if media_id.present? && media_type.present?
        media_comment = MediaObject.find_by_media_id_and_media_type(media_id, media_type)
        if media_comment
          media_comment.context = @current_user
          media_comment.save
          m.media_comment = media_comment
          m.save
        end
      end
    end
    message.generate_user_note if params[:user_note]
    message
  end

  def jsonify_conversation(conversation, last_message = nil)
    hash = {:audience => formatted_audience(conversation, 3)}
    hash[:avatar_url] = avatar_url_for(conversation)
    conversation.as_json(:last_message => last_message).merge(hash)
  end

  def jsonify_users(users, blank_avatar_fallback = false)
    ids_present = users.first.respond_to?(:common_courses)
    users.map { |user|
      {:id => user.id,
       :name => user.short_name,
       :avatar => avatar_url_for_user(user, blank_avatar_fallback),
       :common_courses => ids_present ? user.common_courses : [],
       :common_groups => ids_present ? user.common_groups : []
      }
    }
  end

  def avatar_size
    @avatar_size ||= 50
  end
end
