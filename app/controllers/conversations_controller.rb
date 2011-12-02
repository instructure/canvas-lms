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

# @API Conversations
#
# API for creating, accessing and updating user conversations.
class ConversationsController < ApplicationController
  include ConversationsHelper
  include Api::V1::Submission

  before_filter :require_user
  before_filter :set_avatar_size
  before_filter :get_conversation, :only => [:show, :update, :destroy, :add_recipients, :remove_messages]
  before_filter :load_all_contexts, :only => [:index, :find_recipients, :create, :add_message]
  before_filter :normalize_recipients, :only => [:create, :add_recipients]
  add_crumb(proc { I18n.t 'crumbs.messages', "Conversations" }) { |c| c.send :conversations_url }

  # @API
  # Returns the list of conversations for the current user, most recent ones first.
  #
  # @argument scope [optional, "unread"|"labeled"|"archived"]
  #   When set, only return conversations of the specified type. For example,
  #   set to "unread" to return only conversations that haven't been read.
  #   The default behavior is to return all non-archived conversations (i.e.
  #   read and unread).
  #
  # @argument label [optional, "red"|"orange"|"yellow"|"green"|"blue"|"purple"]
  #   When scope is set to "labeled", you can use this argument to limit the
  #   results to a particular label.
  #
  # @response_field id The unique identifier for the conversation.
  # @response_field workflow_state The current state of the conversation
  #   (read, unread or archived)
  # @response_field last_message A <=100 character preview from the most
  #   recent message
  # @response_field last_message_at The timestamp of the latest message
  # @response_field message_count The number of messages in this conversation
  # @response_field subscribed Indicates whether the user is actively
  #   subscribed to the conversation
  # @response_field private Indicates whether this is a private conversation
  #   (i.e. audience of one)
  # @response_field label Current label for this conversation, if set
  # @response_field properties Additional conversation flags (last_author,
  #   attachments, media_objects). Each listed property means the flag is
  #   set to true (i.e. the current user is the most recent author, there
  #   are attachments, or there are media objects)
  # @response_field audience Array of user ids who are involved in the
  #   conversation, ordered by participation level, then alphabetical.
  #   Excludes current user, unless this is a monologue.
  # @response_field audience_contexts Most relevant shared contexts (courses
  #   and groups) between current user and other participants. If there is
  #   only one participant, it will also include that user's enrollment(s)/
  #   membership type(s) in each course/group
  # @response_field avatar_url URL to appropriate icon for this conversation
  #   (custom, individual or group avatar, depending on audience)
  # @response_field participants Array of users (id, name) participating in
  #   the conversation. Includes current user.
  #
  # @example_response
  #   [
  #     {
  #       "id": 2,
  #       "workflow_state": "unread",
  #       "last_message": "sure thing, here's the file",
  #       "last_message_at": "2011-09-02T12:00:00Z",
  #       "message_count": 2,
  #       "subscribed": true,
  #       "private": true,
  #       "label": null,
  #       "properties": ["attachments"],
  #       "audience": [2],
  #       "audience_contexts": {"courses": {"1": ["StudentEnrollment"]}, "groups": {}},
  #       "avatar_url": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
  #       "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}]
  #     }
  #   ]
  def index
    @page_max = params[:per_page] = 25 if params[:format] != 'json'
    conversations_scope = case params[:scope]
      when 'unread'
        @view_name = I18n.t('index.inbox_views.unread', 'Unread')
        @no_messages = I18n.t('no_unread_messages', 'You have no unread messages')
        @current_user.conversations.unread
      when 'labeled'
        @label, @view_name = ConversationParticipant.labels.detect{ |l| l.first == params[:label] }
        @view_name ||= I18n.t('index.inbox_views.labeled', 'Labeled')
        @no_messages = case @label
          when 'red'; I18n.t('no_red_messages', 'You have no red messages')
          when 'orange'; I18n.t('no_orange_messages', 'You have no orange messages')
          when 'yellow'; I18n.t('no_yellow_messages', 'You have no yellow messages')
          when 'green'; I18n.t('no_green_messages', 'You have no green messages')
          when 'blue'; I18n.t('no_blue_messages', 'You have no blue messages')
          when 'purple'; I18n.t('no_purple_messages', 'You have no purple messages')
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
    conversations = Api.paginate(conversations_scope, self, request.request_uri.gsub(/(per_)?page=[^&]*(&|\z)/, '').sub(/[&?]\z/, ''))
    # optimize loading the most recent messages for each conversation into a single query
    last_messages = ConversationMessage.latest_for_conversations(conversations).human.
                      inject({}) { |hash, message|
                        if !hash[message.conversation_id] || hash[message.conversation_id].id < message.id
                          hash[message.conversation_id] = message
                        end
                        hash
                      }
    @conversations_json = conversations.each{|c| c.instance_variable_set(:@user, @current_user)}.map{ |c| jsonify_conversation(c, :last_message => last_messages[c.conversation_id], :include_participant_avatars => false, :include_participant_contexts => false) }
    @user_cache = Hash[*jsonify_users([@current_user]).map{|u| [u[:id], u] }.flatten]
    respond_to do |format|
      format.html
      format.json { render :json => @conversations_json }
    end
  end

  # @API
  # Create a new conversation with one or more recipients. If there is already
  # an existing private conversation with the given recipients, it will be
  # reused.
  #
  # @argument recipients An array of recipient ids. These may be user ids
  #   or course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. [1, 2, "course_3"].
  # @argument body The message to be sent
  # @argument group_conversation [true|false] Ignored if there is just one
  #   recipient. If true, this will be a group conversation (i.e. all
  #   recipients will see all messages and replies). If false, individual
  #   private conversations will be started with each recipient.
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
        render :json => conversations.each(&:reload).select{|c|c.last_message_at}.map{|c|jsonify_conversation(c)}
      else
        render :json => [jsonify_conversation(@conversation.reload,
                                             :include_context_info => true,
                                             :include_forwarded_participants => true,
                                             :messages => [@message])]
      end
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API
  # Returns information for a single conversation. Response includes all
  # fields that are present in the list/index action, as well as messages,
  # submissions, and extended participant information.
  #
  # @response_field participants Array of relevant users. Includes current
  #   user. If there are forwarded messages in this conversation, the authors
  #   of those messages will also be included, even if they are not
  #   participating in this conversation. Fields include:
  # @response_field messages Array of messages, newest first. Fields include:
  #   id:: The unique identifier for the message
  #   created_at:: The timestamp of the message
  #   body:: The actual message body
  #   author_id:: The id of the user who sent the message (see audience, participants)
  #   generated:: If true, indicates this is a system-generated message (e.g. "Bob added Alice to the conversation")
  #   media_comment:: Audio comment data for this message (if applicable). Fields include: display_name, content-type, media_id, media_type, url
  #   forwarded_messages:: If this message contains forwarded messages, they will be included here (same format as this list). Note that those messages may have forwarded messages of their own, etc.
  #   attachments:: Array of attachments for this message. Fields include: display_name, content-type, filename, url
  # @response_field submissions Array of assignment submissions having
  #   comments relevant to this conversation. These should be interleaved with
  #   the messages when displaying to the user. See the Submissions API
  #   documentation for details on the fields included. This response includes
  #   the submission_comments and assignment associations.
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "unread",
  #     "last_message": "sure thing, here's the file",
  #     "last_message_at": "2011-09-02T12:00:00-06:00",
  #     "message_count": 2,
  #     "subscribed": true,
  #     "private": true,
  #     "label": null,
  #     "properties": ["attachments"],
  #     "audience": [2],
  #     "audience_contexts": {"courses": {"1": ["StudentEnrollment"]}, "groups": {}},
  #     "avatar_url": "https://canvas.instructure.com/images/messages/avatar-50.png",
  #     "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}, {"id": 3, "name": "Bob Student"}],
  #     "messages":
  #       [
  #         {
  #           "id": 3
  #           "created_at": "2011-09-02T12:00:00Z",
  #           "body": "sure thing, here's the file",
  #           "author_id": 2,
  #           "generated": false,
  #           "media_comment": null,
  #           "forwarded_messages": [],
  #           "attachments": [{"id": 1, "display_name": "notes.doc", "uuid": "abcdefabcdefabcdefabcdefabcdef"}]
  #         },
  #         {
  #           "id": 2
  #           "created_at": "2011-09-02T11:00:00Z",
  #           "body": "hey, bob didn't get the notes. do you have a copy i can give him?",
  #           "author_id": 2,
  #           "generated": false,
  #           "media_comment": null,
  #           "forwarded_messages":
  #             [
  #               {
  #                 "id": 1
  #                 "created_at": "2011-09-02T10:00:00Z",
  #                 "body": "can i get a copy of the notes? i was out",
  #                 "author_id": 3,
  #                 "generated": false,
  #                 "media_comment": null,
  #                 "forwarded_messages": [],
  #                 "attachments": []
  #               }
  #             ],
  #           "attachments": []
  #         }
  #       ],
  #     "submissions": []
  #   }
  def show
    return redirect_to "/conversations/#/conversations/#{@conversation.conversation_id}" + (params[:message] ? '?message=' + URI.encode(params[:message], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) : '') unless request.xhr? || params[:format] == 'json'
    
    @conversation.update_attribute(:workflow_state, "read") if @conversation.unread?
    submissions = []
    if @conversation.one_on_one?
      submissions = Submission.for_conversation_participant(@conversation).with_comments
      submissions = submissions.sort_by{ |s| s.submission_comments.last.created_at }.reverse
    end
    render :json => jsonify_conversation(@conversation,
                                         :include_context_info => true,
                                         :include_forwarded_participants => true,
                                         :messages => @conversation.messages,
                                         :submissions => submissions)
  end

  # @API
  # Updates attributes for a single conversation.
  #
  # Response includes only a subset of the fields that are present in the
  # list/index/show actions: id, workflow_state, last_message, last_message_at
  # message_count, subscribed, private, lable, properties
  #
  # @argument conversation[workflow_state] ["read"|"unread"|"archived"] Change the state of this conversation
  # @argument conversation[subscribed] [true|false] Toggle the current user's subscription to the conversation (only valid for group conversations). If unsubscribed, the user will still have access to the latest messages, but the conversation won't be automatically flagged as unread, nor will it jump to the top of the inbox.
  # @argument conversation[label] ["red"|"orange"|"yellow"|"green"|"blue"|"purple"|null] Set/unset a flag on this conversation
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "read",
  #     "last_message": "sure thing, here's the file",
  #     "last_message_at": "2011-09-02T12:00:00-06:00",
  #     "message_count": 2,
  #     "subscribed": true,
  #     "private": true,
  #     "label": null,
  #     "properties": ["attachments"]
  #   }
  def update
    if @conversation.update_attributes(params[:conversation])
      render :json => @conversation
    else
      render :json => @conversation.errors, :status => :bad_request
    end
  end

  # @API
  # Mark all conversations as read.
  def mark_all_as_read
    @current_user.mark_all_conversations_as_read!
    render :json => {}
  end

  # @API
  # Delete this conversation and its messages. Note that this only deletes
  # this user's view of the conversation.
  #
  # Response includes same fields as UPDATE action
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "read",
  #     "last_message": null,
  #     "last_message_at": null,
  #     "message_count": 0,
  #     "subscribed": true,
  #     "private": true,
  #     "label": null,
  #     "properties": []
  #   }
  def destroy
    @conversation.remove_messages(:all)
    render :json => @conversation
  end

  # @API
  # Add recipients to an existing group conversation. Response is similar to
  # the GET/show action, except that omits submissions and only includes the
  # latest message (e.g. "joe was added to the conversation by bob")
  #
  # @argument recipients An array of recipient ids. These may be user ids
  #   or course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. [1, 2, "course_3"].
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "read",
  #     "last_message": "let's talk this over with jim",
  #     "last_message_at": "2011-09-02T12:00:00-06:00",
  #     "message_count": 2,
  #     "subscribed": true,
  #     "private": false,
  #     "label": null,
  #     "properties": [],
  #     "audience": [2, 3, 4],
  #     "audience_contexts": {"courses": {"1": []}, "groups": {}},
  #     "avatar_url": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
  #     "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}, {"id": 3, "name": "Bob Student"}, {"id": 4, "name": "Jim Admin"}],
  #     "messages":
  #       [
  #         {
  #           "id": 4
  #           "created_at": "2011-09-02T12:10:00Z",
  #           "body": "Jim was added to the conversation by Joe TA",
  #           "author_id": 1,
  #           "generated": true,
  #           "media_comment": null,
  #           "forwarded_messages": [],
  #           "attachments": []
  #         }
  #       ]
  #   }
  #
  def add_recipients
    if @recipient_ids.present?
      @conversation.add_participants(@recipient_ids)
      render :json => jsonify_conversation(@conversation.reload, :messages => [@conversation.messages.first])
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API
  # Add a message to an existing conversation. Response is similar to the
  # GET/show action, except that omits submissions and only includes the
  # latest message (i.e. what we just sent)
  #
  # @argument body The message to be sent
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "unread",
  #     "last_message": "let's talk this over with jim",
  #     "last_message_at": "2011-09-02T12:00:00-06:00",
  #     "message_count": 2,
  #     "subscribed": true,
  #     "private": false,
  #     "label": null,
  #     "properties": [],
  #     "audience": [2, 3],
  #     "audience_contexts": {"courses": {"1": []}, "groups": {}},
  #     "avatar_url": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
  #     "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}, {"id": 3, "name": "Bob Student"}],
  #     "messages":
  #       [
  #         {
  #           "id": 3
  #           "created_at": "2011-09-02T12:00:00Z",
  #           "body": "let's talk this over with jim",
  #           "author_id": 2,
  #           "generated": false,
  #           "media_comment": null,
  #           "forwarded_messages": [],
  #           "attachments": []
  #         }
  #       ]
  #   }
  #
  def add_message
    get_conversation(true)
    if params[:body].present?
      message = create_message_on_conversation
      render :json => jsonify_conversation(@conversation.reload, :messages => [message])
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API
  # Delete messages from this conversation. Note that this only affects this user's view of the conversation.
  # If all messages are deleted, the conversation will be as well (equivalent to DELETE)
  #
  # @argument remove Array of message ids to be deleted
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "workflow_state": "read",
  #     "last_message": "sure thing, here's the file",
  #     "last_message_at": "2011-09-02T12:00:00-06:00",
  #     "message_count": 1,
  #     "subscribed": true,
  #     "private": true,
  #     "label": null,
  #     "properties": ["attachments"]
  #   }
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

  # @API
  # Find valid recipients (users, courses and groups) that the current user
  # can send messages to.
  #
  # Pagination is supported if an explicit type is given (but there is no last
  # link). If no type is given, results will be limited to 10 by default (can
  # be overridden via per_page).
  #
  # @argument search Search terms used for matching users/courses/groups (e.g.
  #   "bob smith"). If multiple terms are given (separated via whitespace),
  #   only results matching all terms will be returned.
  # @argument context Limit the search to a particular course/group (e.g.
  #   "course_3" or "group_4").
  # @argument exclude Array of ids to exclude from the search. These may be
  #   user ids or course/group ids prefixed with "course_" or "group_"
  #   respectively, e.g. [1, 2, "course_3"].
  # @argument type ["user"|"context"] Limit the search just to users or contexts (groups/courses).
  # @argument user_id [Integer] Search for a specific user id. This ignores the other above parameters, and will never return more than one result.
  # @argument from_conversation_id [Integer] When searching by user_id, only users that could be normally messaged by this user will be returned. This parameter allows you to specify a conversation that will be referenced for a shared context -- if both the current user and the searched user are in the conversation, the user will be returned. This is used to start new side conversations.
  #
  # @example_response
  #   [
  #     {"id": "group_1", "name": "the group", "type": "context", "user_count": 3},
  #     {"id": 2, "name": "greg", "common_courses": {}, "common_groups": {"1": ["Member"]}}
  #   ]
  #
  # @response_field id The unique identifier for the user/context. For
  #   groups/courses, the id is prefixed by "group_"/"course_" respectively.
  # @response_field name The name of the user/context
  # @response_field avatar_url Avatar image url for the user/context
  # @response_field type ["context"|null] Not set for users, implicitly "user"
  # @response_field user_count Only set for contexts, indicates number of
  #   messageable users
  # @response_field common_courses Only set for users. Hash of course ids and
  #   enrollment types for each course to show what they share with this user
  # @response_field common_groups Only set for users. Hash of group ids and
  #   enrollment types for each group to show what they share with this user
  def find_recipients
    max_results = [params[:per_page].try(:to_i) || 10, 50].min
    if max_results < 1
      if params[:type] == 'context' || params[:context]
        max_results = nil # i.e. all results
      else
        max_results = params[:per_page] = 10
      end
    end
    limit = max_results ? max_results + 1 : nil
    page = params[:page].try(:to_i) || 1
    offset = max_results ? (page - 1) * max_results : 0
    exclude = params[:exclude] || []

    recipients = []
    if params[:user_id]
      recipients = matching_participants(:ids => [params[:user_id]], :conversation_id => params[:from_conversation_id])
    elsif (params[:context] || params[:search]) && ['user', 'context', nil].include?(params[:type])
      options = {:search => params[:search], :context => params[:context], :limit => limit, :offset => offset, :synthetic_contexts => params[:synthetic_contexts]}

      contexts = params[:type] == 'user' ? [] : matching_contexts(options.merge(:exclude_ids => exclude.grep(User::MESSAGEABLE_USER_CONTEXT_REGEX)))
      participants = params[:type] == 'context' || @skip_users ? [] : matching_participants(options.merge(:exclude_ids => exclude.grep(/\A\d+\z/).map(&:to_i)))
      if max_results
        if params[:type]
          recipients = contexts + participants
          has_next_page = recipients.size > max_results
          recipients = recipients[0, max_results]
          recipients.instance_eval <<-CODE
            def paginate(*args); self; end
            def next_page; #{has_next_page ? page + 1 : 'nil'}; end
            def previous_page; #{page > 1 ? page - 1 : 'nil'}; end
            def total_pages; nil; end
            def per_page; #{max_results}; end
          CODE
          recipients = Api.paginate(recipients, self, request.request_uri.gsub(/(per_)?page=[^&]*(&|\z)/, '').sub(/[&?]\z/, ''))
        else
          if contexts.size <= max_results / 2
            recipients = contexts + participants
          elsif participants.size <= max_results / 2
            recipients = contexts[0, max_results - participants.size] + participants
          else
            recipients = contexts[0, max_results / 2] + participants
          end
          recipients = recipients[0, max_results]
        end
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

  attr_reader :avatar_size

  private

  def set_avatar_size
    @avatar_size = params[:avatar_size].to_i
    @avatar_size = 50 unless [32, 50].include?(@avatar_size)
  end

  def normalize_recipients
    if params[:recipients]
      recipient_ids = params[:recipients]
      if recipient_ids.is_a?(String)
        recipient_ids = recipient_ids.split(/,/)
      end
      @recipient_ids = (
        matching_participants(:ids => recipient_ids.grep(/\A\d+\z/), :conversation_id => params[:from_conversation_id]).map{ |p| p[:id] } +
        recipient_ids.grep(User::MESSAGEABLE_USER_CONTEXT_REGEX).map{ |context| matching_participants(:context => context)}.flatten.map{ |p| p[:id] }
      ).uniq
    end
  end

  def load_all_contexts
    @contexts = {:courses => {}, :groups => {}, :sections => {}}

    @current_user.concluded_courses.each do |course|
      @contexts[:courses][course.id] = {
        :id => course.id,
        :name => course.name,
        :type => :course,
        :active => course.recently_ended?,
        :can_add_notes => can_add_notes_to?(course)
      }
    end

    @current_user.courses.each do |course|
      @contexts[:courses][course.id] = {
        :id => course.id,
        :name => course.name,
        :type => :course,
        :active => true,
        :can_add_notes => can_add_notes_to?(course)
      }
    end

    section_ids = @current_user.enrollment_visibility[:section_user_counts].keys
    CourseSection.find(:all, :conditions => {:id => section_ids}).each do |section|
      @contexts[:sections][section.id] = {
        :id => section.id,
        :name => section.name,
        :type => :section,
        :active => @contexts[:courses][section.course_id][:active],
        :parent => {:course => section.course_id},
        :context_name =>  @contexts[:courses][section.course_id][:name]
      }
    end if section_ids.present?

    @current_user.messageable_groups.each do |group|
      @contexts[:groups][group.id] = {
        :id => group.id,
        :name => group.name,
        :type => :group,
        :active => group.active?,
        :parent => group.context_type == 'Course' ? {:course => group.context.id} : nil,
        :context_name => group.context.name
      }
    end
  end

  def can_add_notes_to?(course)
    course.enable_user_notes && course.grants_right?(@current_user, nil, :manage_user_notes)
  end

  def matching_contexts(options)
    context_name = options[:context]
    avatar_url = avatar_url_for_group(params[:blank_avatar_fallback])
    user_counts = {
      :course => @current_user.enrollment_visibility[:user_counts],
      :group => @current_user.group_membership_visibility[:user_counts],
      :section => @current_user.enrollment_visibility[:section_user_counts]
    }
    terms = options[:search].to_s.downcase.strip.split(/\s+/)
    exclude = options[:exclude_ids] || []

    result = []
    if context_name.nil?
      result = if params[:search].blank?
                 courses = @contexts[:courses].values
                 group_ids = @current_user.current_groups.map(&:id)
                 groups = @contexts[:groups].slice(*group_ids).values
                 courses + groups
               else
                 @contexts.values.map(&:values).flatten
               end
    elsif options[:synthetic_contexts]
      if context_name =~ /\Acourse_(\d+)(_(groups|sections))?\z/ && (course = @contexts[:courses][$1.to_i]) && course[:active]
        course = Course.find_by_id(course[:id])
        sections = @contexts[:sections].values.select{ |section| section[:parent] == {:course => course.id} }
        groups = @contexts[:groups].values.select{ |group| group[:parent] == {:course => course.id} }
        case context_name
          when /\Acourse_\d+\z/
            if terms.present? # search all groups and sections (and users)
              result = sections + groups
            else # otherwise we show synthetic contexts
              result = synthetic_contexts_for(course, context_name)
              result << {:id => "#{context_name}_sections", :name => t(:course_sections, "Course Sections"), :item_count => sections.size, :type => :context} if sections.size > 1
              result << {:id => "#{context_name}_groups", :name => t(:student_groups, "Student Groups"), :item_count => groups.size, :type => :context} if groups.size > 0
              return result
            end
          when /\Acourse_\d+_groups\z/
            @skip_users = true # whether searching or just enumerating, we just want groups
            result = groups
          when /\Acourse_\d+_sections\z/
            @skip_users = true # ditto
            result = sections
        end
      elsif context_name =~ /\Asection_(\d+)\z/ && (section = @contexts[:sections][$1.to_i]) && section[:active]
        if terms.present? # we'll just search the users
          result = []
        else
          section = CourseSection.find_by_id(section[:id])
          return synthetic_contexts_for(section.course, context_name)
        end
      end
    end

    result = result.sort_by{ |context| context[:name] }.
    select{ |context| context[:active] }.
    map{ |context|
      ret = {
        :id => "#{context[:type]}_#{context[:id]}",
        :name => context[:name],
        :avatar_url => avatar_url,
        :type => :context,
        :user_count => user_counts[context[:type]][context[:id]]
      }
      ret[:context_name] = context[:context_name] if context[:context_name] && context_name.nil?
      ret
    }
    
    result.reject!{ |context| terms.any?{ |part| !context[:name].downcase.include?(part) } } if terms.present?
    result.reject!{ |context| exclude.include?(context[:id]) }

    offset = options[:offset] || 0
    options[:limit] ? result[offset, offset + options[:limit]] : result
  end

  def synthetic_contexts_for(course, context)
    @skip_users = true
    # TODO: move the aggregation entirely into the DB. we only select a little
    # bit of data per user, but this still isn't ideal
    users = @current_user.messageable_users(:context => context)
    enrollment_counts = {:all => users.size}
    users.each do |user|
      user.common_courses[course.id].uniq.each do |role|
        enrollment_counts[role] ||= 0
        enrollment_counts[role] += 1
      end
    end
    avatar_url = avatar_url_for_group(params[:blank_avatar_fallback])
    result = []
    result << {:id => "#{context}_teachers", :name => t(:enrollments_teachers, "Teachers"), :user_count => enrollment_counts['TeacherEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['TeacherEnrollment'].to_i > 0
    result << {:id => "#{context}_tas", :name => t(:enrollments_tas, "Teaching Assistants"), :user_count => enrollment_counts['TaEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['TaEnrollment'].to_i > 0
    result << {:id => "#{context}_students", :name => t(:enrollments_students, "Students"), :user_count => enrollment_counts['StudentEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['StudentEnrollment'].to_i > 0
    result << {:id => "#{context}_observers", :name => t(:enrollments_observers, "Observers"), :user_count => enrollment_counts['ObserverEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['ObserverEnrollment'].to_i > 0
    result
  end

  def matching_participants(options)
    jsonify_users(@current_user.messageable_users(options), options.merge(:blank_avatar_fallback => params[:blank_avatar_fallback]))
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
        media_comment = MediaObject.by_media_id(media_id).by_media_type(media_type).first
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

  def jsonify_conversation(conversation, options = {})
    result = conversation.as_json(options)
    audience = conversation.participants.reject{ |u| u.id == conversation.user_id }
    result[:messages] = jsonify_messages(options[:messages]) if options[:messages]
    result[:submissions] = options[:submissions].map { |s| submission_json(s, s.assignment, @current_user, session, nil, ['assignment', 'submission_comments']) } if options[:submissions]
    result[:audience] = audience.map(&:id)
    result[:audience_contexts] = contexts_for(audience)
    result[:avatar_url] = avatar_url_for(conversation)
    result[:participants] = jsonify_users(conversation.participants(options), options)
    result
  end

  def jsonify_messages(messages)
    messages.map{ |message|
      message = message.as_json
      message['media_comment'] = media_comment_json(message['media_comment']) if message['media_comment']
      message['attachments'] = message['attachments'].map{ |attachment| attachment_json(attachment) }
      message['forwarded_messages'] = jsonify_messages(message['forwarded_messages'])
      message
    }
  end

  def jsonify_users(users, options = {})
    options = {
      :include_participant_avatars => true,
      :blank_avatar_fallback => false,
      :include_participant_contexts => users.first.respond_to?(:common_courses)
    }.merge(options)
    users.map { |user|
      hash = {
        :id => user.id,
        :name => user.short_name
      }
      if options[:include_participant_contexts]
        hash[:common_courses] = user.common_courses
        hash[:common_groups] = user.common_groups
      end
      hash[:avatar_url] = avatar_url_for_user(user, options[:blank_avatar_fallback]) if options[:include_participant_avatars]
      hash
    }
  end
end
