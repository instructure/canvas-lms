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
  include SearchHelper
  include Api::V1::Submission
  include Api::V1::Attachment

  before_filter :require_user, :except => [:public_feed]
  before_filter :reject_student_view_student
  before_filter :set_avatar_size
  before_filter :get_conversation, :only => [:show, :update, :destroy, :add_recipients, :remove_messages]
  before_filter :load_all_contexts, :except => [:public_feed]
  before_filter :infer_scope, :only => [:index, :show, :create, :update, :add_recipients, :add_message, :remove_messages]
  before_filter :normalize_recipients, :only => [:create, :add_recipients]
  before_filter :infer_tags, :only => [:create, :add_message, :add_recipients]
  add_crumb(proc { I18n.t 'crumbs.messages', "Conversations" }) { |c| c.send :conversations_url }

  # @API List conversations
  # Returns the list of conversations for the current user, most recent ones first.
  #
  # @argument scope [optional, "unread"|"starred"|"archived"]
  #   When set, only return conversations of the specified type. For example,
  #   set to "unread" to return only conversations that haven't been read.
  #   The default behavior is to return all non-archived conversations (i.e.
  #   read and unread).
  #
  # @argument filter [optional, course_id|group_id|user_id]
  #   When set, only return conversations for the specified course, group
  #   or user. The id should be prefixed with its type, e.g. "user_123" or
  #   "course_456"
  #
  # @argument interleave_submissions Boolean, default false. If true, the
  #   message_count will also include these submission-based messages in the
  #   total. See the show action for more information.
  #
  # @argument include_all_conversation_ids Boolean, default false. If true,
  #   the top-level element of the response will be an object rather than
  #   an array, and will have the keys "conversations" which will contain the
  #   paged conversation data, and "conversation_ids" which will contain the
  #   ids of all conversations under this scope/filter in the same order.
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
  # @response_field starred Whether the conversation is starred
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
  # @response_field visible Boolean, indicates whether the conversation is
  #   visible under the current scope and filter. This attribute is always
  #   true in the index API response, and is primarily useful in create/update
  #   responses so that you can know if the record should be displayed in
  #   the UI. The default scope is assumed, unless a scope or filter is passed
  #   to the create/update API call.
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
  #       "starred": false,
  #       "properties": ["attachments"],
  #       "audience": [2],
  #       "audience_contexts": {"courses": {"1": ["StudentEnrollment"]}, "groups": {}},
  #       "avatar_url": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
  #       "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}]
  #       "visible": true
  #     }
  #   ]
  def index
    if request.format == :json
      conversations = Api.paginate(@conversations_scope, self, request.request_uri.gsub(/(per_)?page=[^&]*(&|\z)/, '').sub(/[&?]\z/, ''))
      # optimize loading the most recent messages for each conversation into a single query
      ConversationParticipant.preload_latest_messages(conversations, @current_user.id)
      @conversations_json = conversations.map{ |c| jsonify_conversation(c, :include_participant_avatars => false, :include_participant_contexts => false, :visible => true) }
  
      if params[:include_all_conversation_ids]
        @conversations_json = {:conversations => @conversations_json, :conversation_ids => @conversations_scope.conversation_ids}
      end
      render :json => @conversations_json
    else
      return redirect_to conversations_path(:scope => params[:redirect_scope]) if params[:redirect_scope]
      notes_enabled = @current_user.associated_accounts.any?{|a| a.enable_user_notes }
      can_add_notes_for_account = notes_enabled && @current_user.associated_accounts.any?{|a| a.grants_right?(@current_user, nil, :manage_students) }
      js_env(:CONVERSATIONS => {
        :USER => jsonify_users([@current_user], :include_participant_contexts => false).first,
        :CONTEXTS => @contexts,
        :NOTES_ENABLED => notes_enabled,
        :CAN_ADD_NOTES_FOR_ACCOUNT => can_add_notes_for_account,
        :SHOW_INTRO => !@current_user.watched_conversations_intro?,
        :FOLDER_ID => @current_user.conversation_attachments_folder.id
      })
    end
  end

  # @API Create a conversation
  # Create a new conversation with one or more recipients. If there is already
  # an existing private conversation with the given recipients, it will be
  # reused.
  #
  # @argument recipients[] An array of recipient ids. These may be user ids
  #   or course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. recipients[]=1&recipients[]=2&recipients[]=course_3
  # @argument body The message to be sent
  # @argument group_conversation [true|false] Ignored if there is just one
  #   recipient, defaults to false. If true, this will be a group conversation
  #   (i.e. all recipients will see all messages and replies). If false,
  #   individual private conversations will be started with each recipient.
  # @argument attachment_ids[] An array of attachments ids. These must be
  #   files that have been previously uploaded to the sender's "conversation
  #   attachments" folder.
  # @argument media_comment_id Media comment id of an audio of video file to
  #   be associated with this message.
  # @argument media_comment_type ["audio"|"video"] Type of the associated
  #   media file
  # @argument scope [optional, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
  # @argument filter [optional, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
  def create
    return render_error('recipients', 'blank') if params[:recipients].blank?
    return render_error('recipients', 'invalid') if @recipients.blank?
    return render_error('body', 'blank') if params[:body].blank?

    batch_private_messages = !value_to_boolean(params[:group_conversation]) && @recipients.size > 1
    recipient_ids = @recipients.keys

    # whether it's a bulk private message, or a big group conversation,
    # batch up all delayed jobs to make this more responsive to the user
    Delayed::Batch.serial_batch do
      if batch_private_messages
        conversations = []
        existing_conversations = Conversation.find_all_private_conversations(@current_user.id, recipient_ids)
        ModelCache.with_cache(:conversations => existing_conversations, :users => {:id => @recipients.update(@current_user.id => @current_user)}) do
          recipient_ids.each do |recipient_id|
            conversations << conversation = @current_user.initiate_conversation([recipient_id])
            create_message_on_conversation(conversation, false)
          end
        end

        # reload and preload stuff
        conversations = ConversationParticipant.find(:all, :conditions => {:id => conversations.map(&:id)}, :include => [:conversation], :order => "visible_last_authored_at DESC, last_message_at DESC, id DESC")
        Conversation.preload_participants(conversations.map(&:conversation))
        ConversationParticipant.preload_latest_messages(conversations, @current_user.id)
        visibility_map = infer_visibility(*conversations)
        render :json => conversations.map{ |c| jsonify_conversation(c, :include_participant_avatars => false, :include_participant_contexts => false, :visible => visibility_map[c.conversation_id]) }
      else
        @conversation = @current_user.initiate_conversation(recipient_ids)
        message = create_message_on_conversation(@conversation)
        render :json => [jsonify_conversation(@conversation.reload, :include_indirect_participants => true, :messages => [message])]
      end
    end
  end

  def render_error(attribute, message)
    render :json => [{
        :attribute => attribute,
        :message => message,
      }],
      :status => :bad_request
  end

  # @API Get a single conversation
  # Returns information for a single conversation. Response includes all
  # fields that are present in the list/index action, as well as messages,
  # submissions, and extended participant information.
  #
  # @argument interleave_submissions Boolean, default false. If true,
  #   submission data will be returned as first class messages interleaved
  #   with other messages. The submission details (comments, assignment, etc.)
  #   will be stored as the submission property on the message. Note that if
  #   set, the message_count will also include these messages in the total.
  # @argument scope [optional, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
  # @argument filter [optional, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
  # @argument auto_mark_as_read Boolean, default true. If true, unread
  #   conversations will be automatically marked as read. This will default
  #   to false in a future API release, so clients should explicitly send
  #   true if that is the desired behavior.
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
  #   media_comment:: Audio/video comment data for this message (if applicable). Fields include: display_name, content-type, media_id, media_type, url
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
  #     "starred": false,
  #     "properties": ["attachments"],
  #     "audience": [2],
  #     "audience_contexts": {"courses": {"1": []}, "groups": {}},
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
    unless request.xhr? || params[:format] == 'json'
      scope = if @conversation.archived?
        'archived'
      elsif @conversation.visible_last_authored_at && !@conversation.last_message_at
        'sent'
      else
        'default'
      end
      return redirect_to conversations_path(:scope => scope, :id => @conversation.conversation_id, :message => params[:message])
    end

    @conversation.update_attribute(:workflow_state, "read") if @conversation.unread? && auto_mark_as_read?
    messages = @conversation.messages
    ConversationMessage.send(:preload_associations, messages, :asset)
    submissions = messages.map(&:submission).compact
    Submission.send(:preload_associations, submissions, [:assignment, :submission_comments])
    if interleave_submissions
      submissions = nil
    else
      messages = messages.select{ |message| message.submission.nil? }
    end
    render :json => jsonify_conversation(@conversation,
                                         :include_indirect_participants => true,
                                         :messages => messages,
                                         :submissions => submissions)
  end

  # @API Edit a conversation
  # Updates attributes for a single conversation.
  #
  # @argument conversation[workflow_state] ["read"|"unread"|"archived"] Change the state of this conversation
  # @argument conversation[subscribed] [true|false] Toggle the current user's subscription to the conversation (only valid for group conversations). If unsubscribed, the user will still have access to the latest messages, but the conversation won't be automatically flagged as unread, nor will it jump to the top of the inbox.
  # @argument conversation[starred] [true|false] Toggle the starred state of the current user's view of the conversation.
  # @argument scope [optional, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
  # @argument filter [optional, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the index API action
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
  #     "starred": false,
  #     "properties": ["attachments"],
  #     "audience": [2],
  #     "audience_contexts": {"courses": {"1": []}, "groups": {}},
  #     "avatar_url": "https://canvas.instructure.com/images/messages/avatar-50.png",
  #     "participants": [{"id": 1, "name": "Joe TA"}]
  #   }
  def update
    if @conversation.update_attributes(params[:conversation])
      render :json => jsonify_conversation(@conversation)
    else
      render :json => @conversation.errors, :status => :bad_request
    end
  end

  # @API Mark all as read
  # Mark all conversations as read.
  def mark_all_as_read
    @current_user.mark_all_conversations_as_read!
    render :json => {}
  end

  # @API Delete a conversation
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
  #     "starred": false,
  #     "properties": []
  #   }
  def destroy
    @conversation.remove_messages(:all)
    render :json => jsonify_conversation(@conversation, :visible => false)
  end

  # @API Add recipients
  # Add recipients to an existing group conversation. Response is similar to
  # the GET/show action, except that omits submissions and only includes the
  # latest message (e.g. "joe was added to the conversation by bob")
  #
  # @argument recipients[] An array of recipient ids. These may be user ids
  #   or course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. recipients[]=1&recipients[]=2&recipients[]=course_3
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
  #     "starred": null,
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
    if @recipients.present?
      @conversation.add_participants(@recipients.keys, :tags => @tags, :root_account_id => @domain_root_account.id)
      render :json => jsonify_conversation(@conversation.reload, :messages => [@conversation.messages.first])
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API Add a message
  # Add a message to an existing conversation. Response is similar to the
  # GET/show action, except that omits submissions and only includes the
  # latest message (i.e. what we just sent)
  #
  # @argument body The message to be sent
  # @argument attachment_ids[] An array of attachments ids. These must be
  #   files that have been previously uploaded to the sender's "conversation
  #   attachments" folder.
  # @argument media_comment_id Media comment id of an audio of video file to
  #   be associated with this message.
  # @argument media_comment_type ["audio"|"video"] Type of the associated
  #   media file
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
  #     "starred": null,
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

  # @API Delete a message
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
  #     "starred": null,
  #     "properties": ["attachments"]
  #   }
  def remove_messages
    if params[:remove]
      to_delete = []
      @conversation.messages.each do |message|
        to_delete << message if params[:remove].include?(message.id.to_s)
      end
      @conversation.remove_messages(*to_delete)
      render :json => jsonify_conversation(@conversation)
    end
  end

  def public_feed
    return unless get_feed_context(:only => [:user])
    @current_user = @context
    load_all_contexts
    feed = Atom::Feed.new do |f|
      f.title = t('titles.rss_feed', "Conversations Feed")
      f.links << Atom::Link.new(:href => conversations_url, :rel => 'self')
      f.updated = Time.now
      f.id = conversations_url
    end
    @entries = []
    @conversation_contexts = {}
    @current_user.conversations.each do |conversation|
      @entries.concat(conversation.messages.human)
      if @conversation_contexts[conversation.conversation.id].blank?
        @conversation_contexts[conversation.conversation.id] = feed_context_content(conversation)
      end
    end
    @entries = @entries.sort_by{|e| e.created_at}.reverse
    @entries.each do |entry|
      feed.entries << entry.to_atom(:additional_content => @conversation_contexts[entry.conversation.id])
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def feed_context_content(conversation)
    content = ""
    audience = conversation.other_participants
    audience_names = audience.map(&:name)
    audience_contexts = contexts_for(audience, conversation.context_tags) # will be 0, 1, or 2 contexts
    audience_context_names = [:courses, :groups].inject([]) { |ary, context_key|
      ary + audience_contexts[context_key].keys.map { |k| @contexts[context_key][k] && @contexts[context_key][k][:name] }
    }.reject(&:blank?)

    content += "<hr />"
    content += "<div>#{t('conversation_context', "From a conversation with")} "
    participant_list_cutoff = 2
    if audience_names.length <= participant_list_cutoff
      content += "#{ERB::Util.h(audience_names.to_sentence)}"
    else
      others_string = t('other_recipients', {
        :one => "and 1 other",
        :other => "and %{count} others"
      },
        :count => audience_names.length - participant_list_cutoff)
      content += "#{ERB::Util.h(audience_names[0...participant_list_cutoff].join(", "))} #{others_string}"
    end

    if !audience_context_names.empty?
      content += " (#{ERB::Util.h(audience_context_names.to_sentence)})"
    end
    content += "</div>"
    content
  end

  def watched_intro
    unless @current_user.watched_conversations_intro?
      @current_user.watched_conversations_intro
      @current_user.save
    end
    render :json => {}
  end

  private

  def infer_scope
    @conversations_scope = case params[:scope]
      when 'unread'
        @current_user.conversations.unread
      when 'starred'
        @current_user.conversations.starred
      when 'sent'
        @current_user.all_conversations.sent
      when 'archived'
        @current_user.conversations.archived
      else
        params[:scope] = 'inbox'
        @current_user.conversations.default
    end

    filters = Array(params[:filter]).compact
    @conversations_scope = @conversations_scope.for_masquerading_user(@real_current_user) if @real_current_user
    @conversations_scope = @conversations_scope.tagged(*filters) if filters.present?
  end

  def infer_visibility(*conversations)
    infer_scope unless @conversations_scope

    result = Hash.new(false)
    visible_conversations = @conversations_scope.find(:all,
      :select => "conversation_id",
      :conditions => {:conversation_id => conversations.map(&:conversation_id)}
    )
    visible_conversations.each { |c| result[c.conversation_id] = true }
    if conversations.size == 1
      result[conversations.first.conversation_id]
    else
      result
    end
  end

  def normalize_recipients
    if params[:recipients]
      recipient_ids = params[:recipients]
      if recipient_ids.is_a?(String)
        params[:recipients] = recipient_ids = recipient_ids.split(/,/)
      end
      recipients = @current_user.messageable_users(:ids => recipient_ids.grep(/\A\d+\z/), :conversation_id => params[:from_conversation_id])
      recipient_ids.grep(User::MESSAGEABLE_USER_CONTEXT_REGEX).map do |context|
        recipients.concat @current_user.messageable_users(:context => context)
      end
      @recipients = recipients.inject({}){ |hash, user|
        hash[user.id] ||= user
        hash
      }
    end
  end

  def infer_tags
    tags = Array(params[:tags] || []).concat(params[:recipients] || [])
    tags = SimpleTags.normalize_tags(tags)
    tags += tags.grep(/\Agroup_(\d+)\z/){ g = Group.find_by_id($1.to_i) and g.context.asset_string }.compact
    @tags = tags.uniq
  end

  def get_conversation(allow_deleted = false)
    scope = @current_user.all_conversations
    scope = scope.scoped(:conditions => "message_count > 0") unless allow_deleted
    @conversation = scope.find_by_conversation_id(params[:id] || params[:conversation_id] || 0)
    raise ActiveRecord::RecordNotFound unless @conversation
  end

  def create_message_on_conversation(conversation=@conversation, update_for_sender=true)
    message = conversation.add_message(
                params[:body],
                :attachment_ids => params[:attachment_ids],
                :forwarded_message_ids => params[:forwarded_message_ids],
                :update_for_sender => update_for_sender,
                :root_account_id => @domain_root_account.id,
                :tags => @tags,
                :media_comment => infer_media_comment
              )
    message.generate_user_note if params[:user_note]
    message
  end

  def infer_media_comment
    media_id = params[:media_comment_id]
    media_type = params[:media_comment_type]
    if media_id.present? && media_type.present?
      media_comment = MediaObject.by_media_id(media_id).by_media_type(media_type).first
      unless media_comment
        media_comment ||= MediaObject.new
        media_comment.media_type = media_type
        media_comment.media_id = media_id
        media_comment.root_account_id = @domain_root_account.id
        media_comment.user = @current_user
      end
      media_comment.context = @current_user
      media_comment.save
      media_comment
    end
  end

  def jsonify_conversation(conversation, options = {})
    options = {
      :include_participant_contexts => true
    }.merge(options)
    result = conversation.as_json(options)
    participants = conversation.participants(options.slice(:include_participant_contexts, :include_indirect_participants))
    explicit_participants = conversation.participants({:include_participant_contexts => include_private_conversation_enrollments})
    audience = conversation.other_participants(explicit_participants)
    result[:messages] = jsonify_messages(options[:messages]) if options[:messages]
    result[:submissions] = options[:submissions].map { |s| submission_json(s, s.assignment, @current_user, session, nil, ['assignment', 'submission_comments']) } if options[:submissions]
    unless interleave_submissions
      result['message_count'] = result[:submissions] ?
        result['message_count'] - result[:submissions].size :
        conversation.messages.human.scoped(:conditions => "asset_id IS NULL").size
    end
    result[:audience] = audience.map(&:id)
    result[:audience_contexts] = contexts_for(audience, conversation.context_tags)
    result[:avatar_url] = avatar_url_for(conversation, explicit_participants)
    result[:participants] = jsonify_users(participants, options)
    result[:visible] = options.key?(:visible) ? options[:visible] : infer_visibility(conversation)
    result
  end

  def jsonify_messages(messages)
    messages.map{ |message|
      result = message.as_json
      result['media_comment'] = media_comment_json(result['media_comment']) if result['media_comment']
      result['attachments'] = result['attachments'].map{ |attachment| attachment_json(attachment) }
      result['forwarded_messages'] = jsonify_messages(result['forwarded_messages'])
      result['submission'] = submission_json(message.submission, message.submission.assignment, @current_user, session, nil, ['assignment', 'submission_comments']) if message.submission
      result
    }
  end

  # TODO API v2: default to true, like we do in the UI
  def interleave_submissions
    params[:interleave_submissions] || !api_request?
  end

  def include_private_conversation_enrollments
    enabled = params[:include_private_conversation_enrollments] || api_request?
    ["1", "true"].include?(enabled.to_s)
  end

  # TODO API v2: default to false, like we do in the UI
  def auto_mark_as_read?
    params[:auto_mark_as_read] ||= api_request?
    value_to_boolean(params[:auto_mark_as_read])
  end

end
