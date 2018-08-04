#
# Copyright (C) 2011 - present Instructure, Inc.
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
#           "type": "array",
#           "items": {
#             "type": "string"
#           }
#         },
#         "audience": {
#           "description": "Array of user ids who are involved in the conversation, ordered by participation level, then alphabetical. Excludes current user, unless this is a monologue.",
#           "type": "array",
#           "items": {
#             "type": "integer"
#           }
#         },
#         "audience_contexts": {
#           "description": "Most relevant shared contexts (courses and groups) between current user and other participants. If there is only one participant, it will also include that user's enrollment(s)/ membership type(s) in each course/group.",
#           "type": "array",
#           "items": {
#             "type": "string"
#           }
#         },
#         "avatar_url": {
#           "description": "URL to appropriate icon for this conversation (custom, individual or group avatar, depending on audience).",
#           "example": "https://canvas.instructure.com/images/messages/avatar-group-50.png",
#           "type": "string"
#         },
#         "participants": {
#           "description": "Array of users participating in the conversation. Includes current user.",
#           "type": "array",
#           "items": { "$ref": "ConversationParticipant" }
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
#
# @model ConversationParticipant
#     {
#       "id": "ConversationParticipant",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The user ID for the participant.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "name": {
#           "description": "A short name the user has selected, for use in conversations or other less formal places through the site.",
#           "example": "Shelly",
#           "type": "string"
#         },
#         "full_name": {
#           "description": "The full name of the user.",
#           "example": "Sheldon Cooper",
#           "type": "string"
#         },
#         "avatar_url": {
#           "description": "If requested, this field will be included and contain a url to retrieve the user's avatar.",
#           "example": "https://canvas.instructure.com/images/messages/avatar-50.png",
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

  before_action :require_user, :except => [:public_feed]
  before_action :reject_student_view_student
  before_action :get_conversation, :only => [:show, :update, :destroy, :add_recipients, :remove_messages]
  before_action :infer_scope, :only => [:index, :show, :create, :update, :add_recipients, :add_message, :remove_messages]
  before_action :normalize_recipients, :only => [:create, :add_recipients]
  before_action :infer_tags, :only => [:create, :add_message, :add_recipients]

  # whether it's a bulk private message, or a big group conversation,
  # batch up all delayed jobs to make this more responsive to the user
  batch_jobs_in_actions :only => :create

  API_ALLOWED_FIELDS = %w{workflow_state subscribed starred}.freeze

  # @API List conversations
  # Returns the paginated list of conversations for the current user, most
  # recent ones first.
  #
  # @argument scope [String, "unread"|"starred"|"archived"]
  #   When set, only return conversations of the specified type. For example,
  #   set to "unread" to return only conversations that haven't been read.
  #   The default behavior is to return all non-archived conversations (i.e.
  #   read and unread).
  #
  # @argument filter[] [String, course_id|group_id|user_id]
  #   When set, only return conversations for the specified courses, groups
  #   or users. The id should be prefixed with its type, e.g. "user_123" or
  #   "course_456". Can be an array (by setting "filter[]") or single value
  #   (by setting "filter")
  #
  # @argument filter_mode ["and"|"or", default "or"]
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
  # @argument include[] [Optional, String, "participant_avatars"]
  #   "participant_avatars":: Optionally include an "avatar_url" key for each user participanting in the conversation
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
  # @response_field participants Array of users (id, name, full_name) participating in
  #   the conversation. Includes current user. If `include[]=participant_avatars`
  #   was passed as an argument, each user in the array will also have an
  #   "avatar_url" field
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
  #       "participants": [
  #         {"id": 1, "name": "Joe", "full_name": "Joe TA"},
  #         {"id": 2, "name": "Jane", "full_name": "Jane Teacher"}
  #       ],
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
        session, include_participant_avatars: (Array(params[:include]).include? "participant_avatars"),
        include_participant_contexts: false, visible: true,
        include_context_name: true, include_beta: params[:include_beta])

      if params[:include_all_conversation_ids]
        @conversations_json = {:conversations => @conversations_json, :conversation_ids => @conversations_scope.conversation_ids}
      end
      render :json => @conversations_json
    else
      return redirect_to conversations_path(:scope => params[:redirect_scope]) if params[:redirect_scope]
      @current_user.reset_unread_conversations_counter
      @current_user.reload

      hash = {
        :ATTACHMENTS_FOLDER_ID => @current_user.conversation_attachments_folder.id.to_s,
        :ACCOUNT_CONTEXT_CODE => "account_#{@domain_root_account.id}",
        :CAN_MESSAGE_ACCOUNT_CONTEXT => valid_account_context?(@domain_root_account),
        :MAX_GROUP_CONVERSATION_SIZE => Conversation.max_group_conversation_size
      }

      notes_enabled_accounts = @current_user.associated_accounts.where(enable_user_notes: true)

      hash[:NOTES_ENABLED] = notes_enabled_accounts.any?
      hash[:CAN_ADD_NOTES_FOR_ACCOUNT] = notes_enabled_accounts.any? {|a| a.grants_right?(@current_user, :manage_students) }

      if hash[:NOTES_ENABLED] && !hash[:CAN_ADD_NOTES_FOR_ACCOUNT]
        course_note_permissions = {}
        @current_user.enrollments.active.of_instructor_type.preload(:course).each do |enrollment|
          course_note_permissions[enrollment.course_id] = true if enrollment.has_permission_to?(:manage_user_notes)
        end
        hash[:CAN_ADD_NOTES_FOR_COURSES] = course_note_permissions
      end
      js_env(CONVERSATIONS: hash)
      return render :index_new
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
  # @argument recipients[] [Required, String]
  #   An array of recipient ids. These may be user ids or course/group ids
  #   prefixed with "course_" or "group_" respectively, e.g.
  #   recipients[]=1&recipients[]=2&recipients[]=course_3
  #
  # @argument subject [String]
  #   The subject of the conversation. This is ignored when reusing a
  #   conversation. Maximum length is 255 characters.
  #
  # @argument body [Required, String]
  #   The message to be sent
  #
  # @argument group_conversation [Boolean]
  #   Defaults to false. If true, this will be a group conversation (i.e. all
  #   recipients may see all messages and replies). If false, individual private
  #   conversations will be started with each recipient. Must be set false if the
  #   number of recipients is over the set maximum (default is 100).
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
  # @argument user_note [Boolean]
  #   Will add a faculty journal entry for each recipient as long as the user
  #   making the api call has permission, the recipient is a student and
  #   faculty journals are enabled in the account.
  #
  # @argument mode [String, "sync"|"async"]
  #   Determines whether the messages will be created/sent synchronously or
  #   asynchronously. Defaults to sync, and this option is ignored if this is a
  #   group conversation or there is just one recipient (i.e. it must be a bulk
  #   private message). When sent async, the response will be an empty array
  #   (batch status can be queried via the {api:ConversationsController#batches batches API})
  #
  # @argument scope [String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode ["and"|"or", default "or"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  #
  # @argument context_code [String]
  #   The course or group that is the context for this conversation. Same format
  #   as courses or groups in the recipients argument.
  def create
    return render_error('recipients', 'blank') if params[:recipients].blank?
    return render_error('recipients', 'invalid') if @recipients.blank?
    return render_error('body', 'blank') if params[:body].blank?
    context_type = nil
    context_id = nil
    shard = Shard.current
    if params[:context_code].present?
      context = Context.find_by_asset_string(params[:context_code])
      return render_error('context_code', 'invalid') unless valid_context?(context)

      shard = context.shard
      context_type = context.class.name
      context_id = context.id
    end

    params[:recipients].each do |recipient|
      if recipient =~ /\A(course_\d+)(?:_([a-z]+))?$/ && [nil, 'students', 'observers'].include?($2) &&
         !Context.find_by_asset_string($1).try(:grants_right?, @current_user, session, :send_messages_all)
        return render_error('recipients', 'restricted by role')
      end
    end

    group_conversation     = value_to_boolean(params[:group_conversation])
    batch_private_messages = !group_conversation && @recipients.size > 1
    batch_group_messages   = group_conversation && value_to_boolean(params[:bulk_message])
    message                = build_message

    if !batch_group_messages && @recipients.size > Conversation.max_group_conversation_size
      return render_error('recipients', 'too many for group conversation')
    end

    shard.activate do
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
        conversations = ConversationParticipant.where(:id => batch.conversations).preload(:conversation).order("visible_last_authored_at DESC, last_message_at DESC, id DESC")
        Conversation.preload_participants(conversations.map(&:conversation))
        ConversationParticipant.preload_latest_messages(conversations, @current_user)
        visibility_map = infer_visibility(conversations)
        render :json => conversations.map{ |c| conversation_json(c, @current_user, session, :include_participant_avatars => false, :include_participant_contexts => false, :visible => visibility_map[c.conversation_id]) }, :status => :created
      else
        @conversation = @current_user.initiate_conversation(@recipients, !group_conversation, :subject => params[:subject], :context_type => context_type, :context_id => context_id)
        @conversation.add_message(message, :tags => @tags, :update_for_sender => false, :cc_author => true)
        render :json => [conversation_json(@conversation.reload, @current_user, session, :include_indirect_participants => true, :messages => [message])], :status => :created
      end
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
  # Returns information for a single conversation for the current user. Response includes all
  # fields that are present in the list/index action as well as messages
  # and extended participant information.
  #
  # @argument interleave_submissions [Boolean] (Obsolete) Submissions are no
  #   longer linked to conversations. This parameter is ignored.
  #
  # @argument scope [String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode ["and"|"or", default "or"]
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
  #     "participants": [
  #       {"id": 1, "name": "Joe", "full_name": "Joe TA"},
  #       {"id": 2, "name": "Jane", "full_name": "Jane Teacher"},
  #       {"id": 3, "name": "Bob", "full_name": "Bob Student"}
  #     ],
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
      ActiveRecord::Associations::Preloader.new.preload(messages, :asset)
    end

    render :json => conversation_json(@conversation,
                                      @current_user,
                                      session,
                                      include_participant_contexts: value_to_boolean(params.fetch(:include_participant_contexts, true)),
                                      include_indirect_participants: true,
                                      messages: messages,
                                      submissions: [],
                                      include_beta: params[:include_beta],
                                      include_context_name: true,
                                      include_reply_permission_check: true
    )
  end

  # @API Edit a conversation
  # Updates attributes for a single conversation.
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
  # @argument scope [String, "unread"|"starred"|"archived"]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter[] [String, course_id|group_id|user_id]
  #   Used when generating "visible" in the API response. See the explanation
  #   under the {api:ConversationsController#index index API action}
  # @argument filter_mode ["and"|"or", default "or"]
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
  #     "participants": [{"id": 1, "name": "Joe", "full_name": "Joe TA"}]
  #   }
  def update
    if @conversation.update_attributes(params.require(:conversation).permit(*API_ALLOWED_FIELDS))
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
    return unless authorized_action(Account.site_admin, @current_user, :manage_students)

    Conversation.find(params[:id]).delete_for_all

    render :json => {}
  end

  # internal api
  def deleted_index
    return render_unauthorized_action unless @current_user.roles(Account.site_admin).include? 'admin'

    query = lambda {
      participants = ConversationMessageParticipant.query_deleted(params['user_id'], params)

      Api.paginate(
        participants,
        self,
        api_v1_deleted_conversations_url
      )

      participants.map { |p| deleted_conversation_json(p, @current_user, session) }
    }

    if (params['conversation_id'])
      conversation_messages = Conversation.find(params['conversation_id']).shard.activate { query.call }
    else
      conversation_messages = query.call
    end

    render :json => conversation_messages
  end

  #internal api
  def restore_message
    return render_unauthorized_action unless @current_user.roles(Account.site_admin).include? 'admin'
    return render_error('message_id', 'required') unless params['message_id']
    return render_error('user_id', 'required') unless params['user_id']
    return render_error('conversation_id', 'required') unless params['conversation_id']

    Conversation.find(params['conversation_id']).shard.activate do
      cmp = ConversationMessageParticipant.
        where(:user_id => params['user_id']).
        where(:conversation_message_id => params['message_id'])

      cmp.update_all(:workflow_state => 'active', :deleted_at => nil)

      participant = ConversationParticipant.
        where(:conversation_id => params['conversation_id']).
        where(:user_id => params['user_id']).first
      messages = participant.messages

      participant.message_count = messages.count(:id)
      participant.last_message_at = messages.first().created_at
      participant.save!

      render :json => cmp.map { |c| conversation_message_json(c.conversation_message, @current_user, session) }
    end
  end


  # @API Add recipients
  # Add recipients to an existing group conversation. Response is similar to
  # the GET/show action, except that only includes the
  # latest message (e.g. "joe was added to the conversation by bob")
  #
  # @argument recipients[] [Required, String]
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
  #     "participants": [
  #       {"id": 1, "name": "Joe", "full_name": "Joe TA"},
  #       {"id": 2, "name": "Jane", "full_name": "Jane Teacher"},
  #       {"id": 3, "name": "Bob", "full_name": "Bob Student"},
  #       {"id": 4, "name": "Jim", "full_name": "Jim Admin"}
  #     ],
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
      if @conversation.conversation.can_add_participants?(@recipients)
        @conversation.add_participants(@recipients, :tags => @tags, :root_account_id => @domain_root_account.id)
        render :json => conversation_json(@conversation.reload, @current_user, session, :messages => [@conversation.messages.first])
      else
        render_error('recipients', 'too many participants for group conversation')
      end
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API Add a message
  # Add a message to an existing conversation. Response is similar to the
  # GET/show action, except that only includes the
  # latest message (i.e. what we just sent)
  #
  # @argument body [Required, String]
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
  # @argument recipients[] [String]
  # An array of user ids. Defaults to all of the current conversation
  # recipients. To explicitly send a message to no other recipients,
  # this array should consist of the logged-in user id.
  #
  # @argument included_messages[] [String]
  # An array of message ids from this conversation to send to recipients
  # of the new message. Recipients who already had a copy of included
  # messages will not be affected.
  #
  # @argument user_note [Boolean]
  #   Will add a faculty journal entry for each recipient as long as the user
  #   making the api call has permission, the recipient is a student and
  #   faculty journals are enabled in the account.
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
  #     "participants": [
  #       {"id": 1, "name": "Joe", "full_name": "Joe TA"},
  #       {"id": 2, "name": "Jane", "full_name": "Jane Teacher"},
  #       {"id": 3, "name": "Bob", "full_name": "Bob Student"}
  #     ],
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
    if @conversation.conversation.replies_locked_for?(@current_user)
      return render_unauthorized_action
    end
    if params[:body].present?
      # allow responses to be sent to anyone who is already a conversation participant.
      params[:from_conversation_id] = @conversation.conversation_id
      # not a before_action because we need to set the above parameter.
      normalize_recipients
      if @recipients && !@conversation.conversation.can_add_participants?(@recipients)
        return render_error('recipients', 'too many participants for group conversation')
      end
      # find included_messages
      message_ids = params[:included_messages]
      message_ids = message_ids.split(/,/) if message_ids.is_a?(String)

      # these checks could be folded into the initial ConversationMessage lookup for better efficiency
      if message_ids

        # sanity check: are the messages part of this conversation?
        db_ids = ConversationMessage.where(:id => message_ids, :conversation_id => @conversation.conversation_id).pluck(:id)
        unless db_ids.count == message_ids.count
          return render_error('included_messages', 'not for this conversation')
        end
        message_ids = db_ids

        # sanity check: can the user see the included messages?
        found_count = 0
        Shard.partition_by_shard(message_ids) do |shard_message_ids|
          found_count += ConversationMessageParticipant.where(:conversation_message_id => shard_message_ids, :user_id => @current_user).count
        end
        unless found_count == message_ids.count
          return render_error('included_messages', 'not a participant')
        end
      end

      message_args = build_message_args
      if @conversation.should_process_immediately?
        message = @conversation.process_new_message(message_args, @recipients, message_ids, @tags)
        render :json => conversation_json(@conversation.reload, @current_user, session, :messages => [message])
      else
        @conversation.send_later_enqueue_args(:process_new_message,
          {:strand => "add_message_#{@conversation.global_conversation_id}", :max_attempts => 1},
          message_args, @recipients, message_ids, @tags)
        return render :json => [], :status => :accepted
      end
    else
      render :json => {}, :status => :bad_request
    end
  end

  # @API Delete a message
  # Delete messages from this conversation. Note that this only affects this
  # user's view of the conversation. If all messages are deleted, the
  # conversation will be as well (equivalent to DELETE)
  #
  # @argument remove[] [Required, String]
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
      @conversation.remove_messages(*@conversation.messages.where(id: params[:remove]).to_a)
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
  # @argument conversation_ids[] [required, String]
  #   List of conversations to update. Limited to 500 conversations.
  #
  # @argument event [Required, String, "mark_as_read"|"mark_as_unread"|"star"|"unstar"|"archive"|"destroy"]
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
    update_params = params.permit(:event).to_unsafe_h

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
      format.atom { render :plain => feed.to_xml }
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
    multiple = conversations.is_a?(Enumerable) || conversations.is_a?(ActiveRecord::Relation)
    conversations = [conversations] unless multiple
    result = Hash.new(false)
    visible_conversation_ids = @current_user.shard.activate do
      @conversations_scope.where(:conversation_id => conversations.map(&:conversation_id)).pluck(:conversation_id)
    end
    visible_conversation_ids.each { |c_id| result[Shard.relative_id_for(c_id, @current_user.shard, Shard.current)] = true }
    if !multiple
      result[conversations.first.conversation_id]
    else
      result
    end
  end

  def normalize_recipients
    return unless params[:recipients]

    unless params[:recipients].is_a? Array
      params[:recipients] = params[:recipients].split ","
    end

    # unrecognized context codes are ignored
    if AddressBook.valid_context?(params[:context_code])
      context = AddressBook.load_context(params[:context_code])
      if context.nil?
        # recognized context code must refer to a valid course or group
        return render json: { message: 'invalid context_code' }, status: :bad_request
      end
    end

    users, contexts = AddressBook.partition_recipients(params[:recipients])
    known = @current_user.address_book.known_users(users, context: context, conversation_id: params[:from_conversation_id])
    contexts.each{ |context| known.concat(@current_user.address_book.known_in_context(context)) }
    @recipients = known.uniq(&:id)
    @recipients.reject!{|u| u.id == @current_user.id} unless @recipients == [@current_user]
  end

  def infer_tags
    tags = param_array(:tags).concat(param_array(:recipients)).concat([params[:context_code]])
    tags = SimpleTags.normalize_tags(tags)
    tags += tags.grep(/\Agroup_(\d+)\z/){ g = Group.where(id: $1.to_i).first and g.context.asset_string }.compact
    @tags = tags.uniq
  end

  def get_conversation(allow_deleted = false)
    scope = @current_user.all_conversations
    scope = scope.where('message_count>0') unless allow_deleted
    @conversation = scope.where(conversation_id: params[:id] || params[:conversation_id] || 0).first
    raise ActiveRecord::RecordNotFound unless @conversation
  end

  def build_message
    Conversation.build_message(*build_message_args)
  end

  def build_message_args
    [
      @current_user,
      params[:body],
      {
        :attachment_ids => params[:attachment_ids],
        :forwarded_message_ids => params[:forwarded_message_ids],
        :root_account_id => @domain_root_account.id,
        :media_comment => infer_media_comment,
        :generate_user_note => value_to_boolean(params[:user_note])
      }
    ]
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

  def include_private_conversation_enrollments
    if params.has_key? :include_private_conversation_enrollments
      value_to_boolean(params[:include_private_conversation_enrollments])
    else
      api_request?
    end
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
    when Course, Group then context.membership_for_user(@current_user) || context.grants_right?(@current_user, session, :send_messages)
    else false
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
