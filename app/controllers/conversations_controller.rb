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

# @API Conversations
#
# API for creating, accessing and updating user conversations.
#
# @model Conversation
#     {
#       "id": "Conversation",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the conversation.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "subject": {
#           "description": "the subject of the conversation.",
#           "example": 2,
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "The current state of the conversation (read, unread or archived).",
#           "example": "unread",
#           "type": "string"
#         },
#         "last_message": {
#           "description": "A <=100 character preview from the most recent message.",
#           "example": "sure thing, here's the file",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "the date and time at which the last message was sent.",
#           "example": "2011-09-02T12:00:00Z",
#           "type": "datetime"
#         },
#         "message_count": {
#           "description": "the number of messages in the conversation.",
#           "example": 2,
#           "type": "integer"
#         },
#         "subscribed": {
#           "description": "whether the current user is subscribed to the conversation.",
#           "example": true,
#           "type": "boolean"
#         },
#         "private": {
#           "description": "whether the conversation is private.",
#           "example": true,
#           "type": "boolean"
#         },
#         "starred": {
#           "description": "whether the conversation is starred.",
#           "example": true,
#           "type": "boolean"
#         },
#         "properties": {
#           "description": "Additional conversation flags (last_author, attachments, media_objects). Each listed property means the flag is set to true (i.e. the current user is the most recent author, there are attachments, or there are media objects)",
#           "type": "[string]"
#         },
#         "audience": {
#           "description": "Array of user ids who are involved in the conversation, ordered by participation level, then alphabetical. Excludes current user, unless this is a monologue.",
#           "type": "[integer]"
#         },
#         "audience_contexts": {
#           "description": "Most relevant shared contexts (courses and groups) between current user and other participants. If there is only one participant, it will also include that user's enrollment(s)/ membership type(s) in each course/group.",
#           "type": "[string]"
#         },
#         "avatar_url": {
#           "description": "URL to appropriate icon for this conversation (custom, individual or group avatar, depending on audience).",
#           "example": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
#           "type": "string"
#         },
#         "participants": {
#           "description": "Array of users (id, name) participating in the conversation. Includes current user.",
#           "type": "[string]"
#         },
#         "visible": {
#           "description": "indicates whether the conversation is visible under the current scope and filter. This attribute is always true in the index API response, and is primarily useful in create/update responses so that you can know if the record should be displayed in the UI. The default scope is assumed, unless a scope or filter is passed to the create/update API call.",
#           "example": true,
#           "type": "boolean"
#         },
#         "context_name": {
#           "description": "Name of the course or group in which the conversation is occurring.",
#           "example": "Canvas 101",
#           "type": "string"
#         }
#       }
#     }
class ConversationsController < ApplicationController
  include ConversationsHelper
  include SearchHelper
  include KalturaHelper
  include Api::V1::Conversation
  include Api::V1::Progress

  before_filter :require_user, :except => [:public_feed]
  before_filter :reject_student_view_student
  before_filter :get_conversation, :only => [:show, :update, :destroy, :add_recipients, :remove_messages]
  before_filter :infer_scope, :only => [:index, :show, :create, :update, :add_recipients, :add_message, :remove_messages]
  before_filter :normalize_recipients, :only => [:create, :add_recipients]
  before_filter :infer_tags, :only => [:create, :add_message, :add_recipients]

  # whether it's a bulk private message, or a big group conversation,
  # batch up all delayed jobs to make this more responsive to the user
  batch_jobs_in_actions :only => :create

  API_ALLOWED_FIELDS = %w{workflow_state subscribed starred scope filter}

  # @API List conversations
  # Returns the list of conversations for the current user, most recent ones first.
  #
  # @argument scope [Optional, String, "unread"|"starred"|"archived"]
  #   When set, only return conversations of the specified type. For example,
  #   set to "unread" to return only conversations that haven't been read.
  #   The default behavior is to return all non-archived conversations (i.e.
  #   read and unread).
  #
  # @argument filter[] [Optional, String, course_id|group_id|user_id]
  #   When set, only return conversations for the specified courses, groups
  #   or users. The id should be prefixed with its type, e.g. "user_123" or
  #   "course_456". Can be an array (by setting "filter[]") or single value
  #   (by setting "filter")
  #
  # @argument filter_mode [optional, "and"|"or", default "or"]
  #   When filter[] contains multiple filters, combine them with this mode,
  #   filtering conversations that at have at least all of the contexts ("and")
  #   or at least one of the contexts ("or")
  #
  # @argument interleave_submissions [Boolean] (Obsolete) Submissions are no
  #   longer linked to conversations. This parameter is ignored.
  #
  # @argument include_all_conversation_ids [Boolean] Default is false. If true,
  #   the top-level element of the response will be an object rather than
  #   an array, and will have the keys "conversations" which will contain the
  #   paged conversation data, and "conversation_ids" which will contain the
  #   ids of all conversations under this scope/filter in the same order.
  #
  # @response_field id The unique identifier for the conversation.
  # @response_field subject The subject of the conversation.
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
  #       "subject": "conversations api example",
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
  #       "participants": [{"id": 1, "name": "Joe TA"}, {"id": 2, "name": "Jane Teacher"}],
  #       "visible": true,
  #       "context_name": "Canvas 101"
  #     }
  #   ]
  # @returns [Conversation]
  #
  def index
    if request.format == :json
      @conversations_scope = @conversations_scope.where('message_count > 0')
      conversations = Api.paginate(@conversations_scope, self, api_v1_conversations_url)
      # optimize loading the most recent messages for each conversation into a single query
      ConversationParticipant.preload_latest_messages(conversations, @current_user)
      @conversations_json = conversations_json(conversations, @current_user,
        session, include_participant_avatars: false,
        include_participant_contexts: false, visible: true,
        include_context_name: true, include_beta: params[:include_beta])

      if params[:include_all_conversation_ids]
        @conversations_json = {:conversations => @conversations_json, :conversation_ids => @conversations_scope.conversation_ids}
      end
      render :json => @conversations_json
    else
      return redirect_to conversations_path(:scope => params[:redirect_scope]) if params[:redirect_scope]
      load_all_contexts :permissions => [:manage_user_notes]
      notes_enabled = @current_user.associated_accounts.any?{|a| a.enable_user_notes }
      can_add_notes_for_account = notes_enabled && @current_user.associated_accounts.any?{|a| a.grants_right?(@current_user, nil, :manage_students) }
      js_env(:CONVERSATIONS => {
               :ATTACHMENTS_FOLDER_ID => @current_user.conversation_attachments_folder.id,
               :ACCOUNT_CONTEXT_CODE => "account_#{@domain_root_account.id}",
               :CONTEXTS => @contexts,
               :NOTES_ENABLED => notes_enabled,
               :CAN_ADD_NOTES_FOR_ACCOUNT => can_add_notes_for_account,
             })
      return render :template => 'conversations/index_new'
    end
  end

  def toggle_new_conversations
    redirect_to action: 'index'
  end

  # @API Create a conversation
  # Create a new conversation with one or more recipients. If there is already
  # an existing private conversation with the given recipients, it will be
  # reused.
  #
  # @argument recipients[] [String]
  #   An array of recipient ids. These may beuser ids or course/group ids
  #   prefixed with "course_" or "group_" respectively, e.g.
  #   recipients[]=1&recipients[]=2&recipients[]=course_3
  #
  # @argument subject [Optional, String]
  #   The subject of the conversation. This is ignored when reusing a
  #   conversation. Maximum length is 255 characters.
  #
  # @argument body [String]
  #   The message to be sent
  #
  # @argument group_conversation [Boolean]
  #   Defaults to false. If true, this will be a group conversation (i.e. all
  #   recipients may see all messages and replies). If false, individual private
  #   conversations will be started with each recipient.
  #
  # @argument attachment_ids[] [String]
  #   An array of attachments ids. These must be files that have been previously
  #   uploaded to the sender's "conversation attachments" folder.
  #
  # @argument media_comment_id [String]
  #   Media comment id of an audio of video file to be associated with this
  #   message.
  #
  # @argument media_comment_type [String, "audio"|"video"]
  #   Type of the associated media file
  #
  # @argument mode [String, "sync"|"async"]
  #   Determines whether the messages will be created/sent synchronously or
  #   asynchronously. Defaults to sync, and this option is ignored if this is a
  #   group conversation or there is just one recipient (i.e. it must be a bulk
  #   private message). When sent async, the response will be an empty array
  #   (batch status can be queried via the {api:ConversationsController#batches batches API})
  #
  # @argument scope [Optional, String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [Optional, String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode [optional, "and"|"or", default "or"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  #
  # @argument context_code [Optional, String]
  #   The course or group that is the context for this conversation. Same format
  #   as courses or groups in the recipients argument.
  def create
    return render_error('recipients', 'blank') if params[:recipients].blank?
    return render_error('recipients', 'invalid') if @recipients.blank?
    return render_error('body', 'blank') if params[:body].blank?
    context_type = nil
    context_id = nil
    if params[:context_code].present?
      context = Context.find_by_asset_string(params[:context_code])
      return render_error('context_code', 'invalid') unless valid_context?(context)

      context_type = context.class.name
      context_id = context.id
    end

    group_conversation     = value_to_boolean(params[:group_conversation])
    batch_private_messages = !group_conversation && @recipients.size > 1
    batch_group_messages   = group_conversation && value_to_boolean(params[:bulk_message])
    message                = build_message

    if batch_private_messages || batch_group_messages
      mode = params[:mode] == 'async' ? :async : :sync
      batch = ConversationBatch.generate(message, @recipients, mode,
        subject: params[:subject], context_type: context_type,
        context_id: context_id, tags: @tags, group: batch_group_messages)

      if mode == :async
        headers['X-Conversation-Batch-Id'] = batch.id.to_s
        return render :json => [], :status => :accepted
      end

      # reload and preload stuff
      conversations = ConversationParticipant.where(:id => batch.conversations).includes(:conversation).order("visible_last_authored_at DESC, last_message_at DESC, id DESC")
      Conversation.preload_participants(conversations.map(&:conversation))
      ConversationParticipant.preload_latest_messages(conversations, @current_user)
      visibility_map = infer_visibility(conversations)
      render :json => conversations.map{ |c| conversation_json(c, @current_user, session, :include_participant_avatars => false, :include_participant_contexts => false, :visible => visibility_map[c.conversation_id]) }, :status => :created
    else
      @conversation = @current_user.initiate_conversation(@recipients, !value_to_boolean(params[:group_conversation]), :subject => params[:subject], :context_type => context_type, :context_id => context_id)
      @conversation.add_message(message, :tags => @tags, :update_for_sender => false)
      render :json => [conversation_json(@conversation.reload, @current_user, session, :include_indirect_participants => true, :messages => [message])], :status => :created
    end
  rescue ActiveRecord::RecordInvalid => err
    render :json => err.record.errors, :status => :bad_request
  end

  # @API Get running batches
  # Returns any currently running conversation batches for the current user.
  # Conversation batches are created when a bulk private message is sent
  # asynchronously (see the mode argument to the {api:ConversationsController#create create API action}).
  #
  # @example_response
  #   [
  #     {
  #       "id": 1,
  #       "subject": "conversations api example",
  #       "workflow_state": "created",
  #       "completion": 0.1234,
  #       "tags": [],
  #       "message":
  #       {
  #         "id": 1,
  #         "created_at": "2011-09-02T10:00:00Z",
  #         "body": "quick reminder, no class tomorrow",
  #         "author_id": 1,
  #         "generated": false,
  #         "media_comment": null,
  #         "forwarded_messages": [],
  #         "attachments": []
  #       }
  #     }
  #   ]
  def batches
    batches = Api.paginate(@current_user.conversation_batches.in_progress.order(:id),
                           self,
                           api_v1_conversations_batches_url)
    render :json => batches.map{ |m| conversation_batch_json(m, @current_user, session) }
  end

  # @API Get a single conversation
  # Returns information for a single conversation. Response includes all
  # fields that are present in the list/index action as well as messages
  # and extended participant information.
  #
  # @argument interleave_submissions [Boolean] (Obsolete) Submissions are no
  #   longer linked to conversations. This parameter is ignored.
  #
  # @argument scope [Optional, String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [Optional, String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode [optional, "and"|"or", default "or"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  #
  # @argument auto_mark_as_read [Boolean] Default true. If true, unread
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
  # @response_field submissions (Obsolete) Array of assignment submissions having
  #   comments relevant to this conversation. Submissions are no longer linked to conversations.
  #   This field will always be nil or empty.
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "subject": "conversations api example",
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
  #           "id": 3,
  #           "created_at": "2011-09-02T12:00:00Z",
  #           "body": "sure thing, here's the file",
  #           "author_id": 2,
  #           "generated": false,
  #           "media_comment": null,
  #           "forwarded_messages": [],
  #           "attachments": [{"id": 1, "display_name": "notes.doc", "uuid": "abcdefabcdefabcdefabcdefabcdef"}]
  #         },
  #         {
  #           "id": 2,
  #           "created_at": "2011-09-02T11:00:00Z",
  #           "body": "hey, bob didn't get the notes. do you have a copy i can give him?",
  #           "author_id": 2,
  #           "generated": false,
  #           "media_comment": null,
  #           "forwarded_messages":
  #             [
  #               {
  #                 "id": 1,
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
    messages = nil
    Shackles.activate(:slave) do
      messages = @conversation.messages
      ConversationMessage.send(:preload_associations, messages, :asset)
    end
    render :json => conversation_json(@conversation,
                                      @current_user,
                                      session,
                                      include_indirect_participants: true,
                                      messages: messages,
                                      submissions: [],
                                      include_beta: params[:include_beta],
                                      include_context_name: true)
  end

  # @API Edit a conversation
  # Updates attributes for a single conversation.
  #
  # @argument conversation[subject] [String]
  #   Change the subject of this conversation
  #
  # @argument conversation[workflow_state] [String, "read"|"unread"|"archived"]
  #   Change the state of this conversation
  #
  # @argument conversation[subscribed] [Boolean]
  #   Toggle the current user's subscription to the conversation (only valid for
  #   group conversations). If unsubscribed, the user will still have access to
  #   the latest messages, but the conversation won't be automatically flagged
  #   as unread, nor will it jump to the top of the inbox.
  #
  # @argument conversation[starred] [Boolean]
  #   Toggle the starred state of the current user's view of the conversation.
  #
  # @argument scope [Optional, String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [Optional, String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode [optional, "and"|"or", default "or"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "subject": "conversations api example",
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
    if @conversation.update_attributes(params[:conversation].slice(*API_ALLOWED_FIELDS))
      render :json => conversation_json(@conversation, @current_user, session)
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
  #     "subject": "conversations api example",
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
    render :json => conversation_json(@conversation, @current_user, session, :visible => false)
  end

  # internal api
  # @example_request
  #     curl https://<canvas>/api/v1/conversations/:id/delete_for_all \ 
  #       -X DELETE \ 
  #       -H 'Authorization: Bearer <token>'
  def delete_for_all
    return unless authorized_action(Account.site_admin, @current_user, :become_user)

    Conversation.find(params[:id]).delete_for_all

    render :json => {}
  end

  # @API Add recipients
  # Add recipients to an existing group conversation. Response is similar to
  # the GET/show action, except that only includes the
  # latest message (e.g. "joe was added to the conversation by bob")
  #
  # @argument recipients[] [String]
  #   An array of recipient ids. These may be user ids or course/group ids
  #   prefixed with "course_" or "group_" respectively, e.g.
  #   recipients[]=1&recipients[]=2&recipients[]=course_3
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "subject": "conversations api example",
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
  #           "id": 4,
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
      @conversation.add_participants(@recipients, :tags => @tags, :root_account_id => @domain_root_account.id)
      render :json => conversation_json(@conversation.reload, @current_user, session, :messages => [@conversation.messages.first])
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API Add a message
  # Add a message to an existing conversation. Response is similar to the
  # GET/show action, except that only includes the
  # latest message (i.e. what we just sent)
  #
  # @argument body [String]
  #   The message to be sent.
  #
  # @argument attachment_ids[] [String]
  #   An array of attachments ids. These must be files that have been previously
  #   uploaded to the sender's "conversation attachments" folder.
  #
  # @argument media_comment_id [String]
  #   Media comment id of an audio of video file to be associated with this
  #   message.
  #
  # @argument media_comment_type [String, "audio"|"video"]
  #   Type of the associated media file.
  #
  # @argument recipients[] [Optional, String]
  # An array of user ids. Defaults to all of the current conversation
  # recipients. To explicitly send a message to no other recipients,
  # this array should consist of the logged-in user id.
  #
  # @argument included_messages[] [Optional, String]
  # An array of message ids from this conversation to send to recipients
  # of the new message. Recipients who already had a copy of included
  # messages will not be affected.
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "subject": "conversations api example",
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
  #           "id": 3,
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

      # allow responses to be sent to anyone who is already a conversation participant.
      params[:from_conversation_id] = @conversation.conversation_id
      # not a before_filter because we need to set the above parameter.
      normalize_recipients

      message = build_message
      # find included_messages
      message_ids = params[:included_messages]
      message_ids = message_ids.split(/,/) if message_ids.is_a?(String)
      messages = ConversationMessage.where(:id => message_ids) if message_ids

      # these checks could be folded into the initial ConversationMessage lookup for better efficiency
      if messages
        # sanity check: can the user see the included messages?
        return render_error('included_messages', 'not a participant') unless messages.all? { |m| m.conversation_message_participants.where(:user_id => @current_user.id).exists? }
        # sanity check: are the messages part of this conversation?
        return render_error('included_messages', 'not for this conversation') unless messages.all? { |m| m.conversation_id == @conversation.conversation.id }
      end

      unless @conversation.private?
        @conversation.add_participants @recipients, no_messages: true if @recipients
      end
      @conversation.reload
      messages.each { |msg| @conversation.conversation.add_message_to_participants msg, new_message: false, only_users: @recipients } if messages
      @conversation.add_message message, :tags => @tags, :update_for_sender => false, only_users: @recipients

      render :json => conversation_json(@conversation.reload, @current_user, session, :messages => [message])
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API Delete a message
  # Delete messages from this conversation. Note that this only affects this
  # user's view of the conversation. If all messages are deleted, the
  # conversation will be as well (equivalent to DELETE)
  #
  # @argument remove[] [String]
  #   Array of message ids to be deleted
  #
  # @example_response
  #   {
  #     "id": 2,
  #     "subject": "conversations api example",
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
      @conversation.remove_messages(*@conversation.messages.find_all_by_id(*params[:remove]))
      if @conversation.conversation_message_participants.where('workflow_state <> ?', 'deleted').length == 0
        @conversation.update_attribute(:last_message_at, nil)
      end
      render :json => conversation_json(@conversation, @current_user, session)
    end
  end

  # @API Batch update conversations
  # Perform a change on a set of conversations. Operates asynchronously; use the {api:ProgressController#show progress endpoint}
  # to query the status of an operation.
  #
  # @argument conversation_ids[] [String]
  #   List of conversations to update. Limited to 500 conversations.
  #
  # @argument event [String, "mark_as_read"|"mark_as_unread"|"star"|"unstar"|"archive"|"destroy"]
  #   The action to take on each conversation.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/conversations \ 
  #       -X PUT \ 
  #       -H 'Authorization: Bearer <token>' \ 
  #       -d 'event=mark_as_read' \ 
  #       -d 'conversation_ids[]=1' \ 
  #       -d 'conversation_ids[]=2'
  #
  # @returns Progress
  def batch_update
    conversation_ids = params[:conversation_ids]
    update_params = params.slice(:event).with_indifferent_access

    allowed_events = %w(mark_as_read mark_as_unread star unstar archive destroy)
    return render(:json => {:message => 'conversation_ids not specified'}, :status => :bad_request) unless params[:conversation_ids].is_a?(Array)
    return render(:json => {:message => 'conversation batch size limit (500) exceeded'}, :status => :bad_request) unless params[:conversation_ids].size <= 500
    return render(:json => {:message => 'event not specified'}, :status => :bad_request) unless update_params[:event]
    return render(:json => {:message => 'invalid event'}, :status => :bad_request) unless allowed_events.include? update_params[:event]

    progress = ConversationParticipant.batch_update(@current_user, conversation_ids, update_params)
    render :json => progress_json(progress, @current_user, session)
  end


  # @API Find recipients
  #
  # Deprecated, see the {api:SearchController#recipients Find recipients endpoint} in the Search API
  def find_recipients; end

  # @API Unread count
  # Get the number of unread conversations for the current user
  #
  # @example_response
  #   {'unread_count': '7'}
  def unread_count
    # the reasons for this being a string instead of an integer are historical,
    # but for backwards API compatibility we need to leave it a string.
    render :json => {'unread_count' => @current_user.unread_conversations_count.to_s}
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
    Shackles.activate(:slave) do
      @entries = []
      @conversation_contexts = {}
      @current_user.conversations.each do |conversation|
        @entries.concat(conversation.messages.human)
        if @conversation_contexts[conversation.conversation.id].blank?
          @conversation_contexts[conversation.conversation.id] = feed_context_content(conversation)
        end
      end
      @entries = @entries.sort_by{|e| [e.created_at, e.id] }.reverse
      @entries.each do |entry|
        feed.entries << entry.to_atom(:additional_content => @conversation_contexts[entry.conversation.id])
      end
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def feed_context_content(conversation)
    content = ""
    audience = conversation.other_participants
    audience_names = audience.map(&:name)
    audience_contexts = contexts_for(audience, conversation.local_context_tags) # will be 0, 1, or 2 contexts
    audience_context_names = [:courses, :groups].inject([]) { |ary, context_key|
      ary + audience_contexts[context_key].keys.map { |k| @contexts[context_key][k] && @contexts[context_key][k][:name] }
    }.reject(&:blank?)

    content += "<hr />"
    content += "<div>#{ERB::Util.h(t('conversation_context', "From a conversation with"))} "
    participant_list_cutoff = 2
    if audience_names.length <= participant_list_cutoff
      content += "#{ERB::Util.h(audience_names.to_sentence)}"
    else
      others_string = t('other_recipients', {
        :one => "and 1 other",
        :other => "and %{count} others"
      },
        :count => audience_names.length - participant_list_cutoff)
      content += "#{ERB::Util.h(audience_names[0...participant_list_cutoff].join(", "))} #{ERB::Util.h(others_string)}"
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

  def render_error(attribute, message)
    render :json => [{
        :attribute => attribute,
        :message => message,
      }],
      :status => :bad_request
  end

  def infer_scope
    filter_mode = (params[:filter_mode].respond_to?(:to_sym) && params[:filter_mode].to_sym) || :or
    return render_error('filter_mode', 'invalid') if ![:or, :and].include?(filter_mode)

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

    filters = param_array(:filter)
    @conversations_scope = @conversations_scope.for_masquerading_user(@real_current_user) if @real_current_user
    @conversations_scope = @conversations_scope.tagged(*filters, :mode => filter_mode) if filters.present?
    @set_visibility = true
  end

  def infer_visibility(conversations)
    multiple = conversations.is_a?(Enumerable) || (!CANVAS_RAILS2 && conversations.is_a?(ActiveRecord::Relation))
    conversations = [conversations] unless multiple
    result = Hash.new(false)
    visible_conversations = @current_user.shard.activate do
        @conversations_scope.select(:conversation_id).where(:conversation_id => conversations.map(&:conversation_id)).all
      end
    visible_conversations.each { |c| result[c.conversation_id] = true }
    if !multiple
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
      @recipients = @current_user.load_messageable_users(MessageableUser.individual_recipients(recipient_ids), :conversation_id => params[:from_conversation_id])
      MessageableUser.context_recipients(recipient_ids).map do |context|
        @recipients.concat @current_user.messageable_users_in_context(context)
      end
      @recipients = @recipients.uniq(&:id)
    end
  end

  def infer_tags
    tags = param_array(:tags).concat(param_array(:recipients)).concat([params[:context_code]])
    tags = SimpleTags.normalize_tags(tags)
    tags += tags.grep(/\Agroup_(\d+)\z/){ g = Group.find_by_id($1.to_i) and g.context.asset_string }.compact
    @tags = tags.uniq
  end

  def get_conversation(allow_deleted = false)
    scope = @current_user.all_conversations
    scope = scope.where('message_count>0') unless allow_deleted
    @conversation = scope.find_by_conversation_id(params[:id] || params[:conversation_id] || 0)
    raise ActiveRecord::RecordNotFound unless @conversation
  end

  def build_message
    Conversation.build_message(
      @current_user,
      params[:body],
      :attachment_ids => params[:attachment_ids],
      :forwarded_message_ids => params[:forwarded_message_ids],
      :root_account_id => @domain_root_account.id,
      :media_comment => infer_media_comment,
      :generate_user_note => value_to_boolean(params[:user_note])
    )
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

  # Obsolete. Forced to false until we go through and clean it up thoroughly
  def interleave_submissions
    false
  end

  def include_private_conversation_enrollments
    value_to_boolean(params[:include_private_conversation_enrollments]) || api_request?
  end

  # TODO API v2: default to false, like we do in the UI
  def auto_mark_as_read?
    params[:auto_mark_as_read] ||= api_request?
    value_to_boolean(params[:auto_mark_as_read])
  end

  # look up the param and cast it to an array. treat empty string same as empty
  def param_array(key)
    Array(params[key].presence || []).compact
  end

  def valid_context?(context)
    case context
    when nil then false
    when Account then valid_account_context?(context)
    # might want to add some validation for Course and Group.
    else true
    end
  end

  def valid_account_context?(account)
    return false unless account.root_account?
    return true if account.grants_right?(@current_user, session, :read_roster)
    account.shard.activate do
      user_sub_accounts = @current_user.associated_accounts.where(root_account_id: account).to_a
      if user_sub_accounts.any? { |a| a.grants_right?(@current_user, session, :read_roster) }
        return true
      end
    end

    false
  end

end
