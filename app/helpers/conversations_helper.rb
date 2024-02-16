# frozen_string_literal: true

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

module ConversationsHelper
  def process_response(
    conversation:,
    context:,
    current_user:,
    session:,
    recipients:,
    context_code:,
    message_ids:,
    body:,
    attachment_ids:,
    domain_root_account_id:,
    media_comment_id:,
    media_comment_type:,
    user_note:
  )
    if conversation.conversation.replies_locked_for?(current_user, recipients)
      raise ConversationsHelper::RepliesLockedForUser.new(message: I18n.t("Unauthorized, unable to add messages to conversation"), status: :unauthorized, attribute: "workflow_state")
    end

    if context.is_a?(Course) && context.workflow_state == "completed" && !context.grants_right?(current_user, session, :read_as_admin)
      raise ConversationsHelper::Error.new(message: I18n.t("Course concluded, unable to send messages"), status: :unauthorized, attribute: "workflow_state")
    end

    if body.blank?
      raise ConversationsHelper::Error.new(message: I18n.t("Unable to create message without a body"), status: :bad_request, attribute: "empty_message")
    end

    recipients = normalize_recipients(
      recipients:,
      context_code:,
      conversation_id: conversation.conversation_id,
      current_user:
    )

    if recipients && !conversation.conversation.can_add_participants?(recipients)
      raise ConversationsHelper::Error.new(message: I18n.t("Too many participants for group conversation"), status: :bad_request, attribute: "recipients")
    end

    invalid_recipients = get_invalid_recipients(context, recipients, current_user)
    unless invalid_recipients.to_a.empty?
      invalid_recipients = invalid_recipients.pluck(1)
      raise ConversationsHelper::Error.new(message: I18n.t("The following recipients have no active enrollment in the course, %{invalid_recipients}, unable to send messages", invalid_recipients:), status: :unauthorized, attribute: "recipients")
    end

    tags = infer_tags(
      recipients: conversation.conversation.participants.pluck(:id),
      context_code:
    )

    validate_message_ids(message_ids, conversation, current_user:)
    message_args = build_message_args(
      body:,
      attachment_ids:,
      domain_root_account_id:,
      media_comment_id:,
      media_comment_type:,
      user_note:,
      current_user:
    )

    if conversation.should_process_immediately?
      message = conversation.process_new_message(message_args, recipients, message_ids, tags)
      { message:, recipients_count: recipients ? recipients.count : 0, status: :ok }
    else
      conversation.delay(strand: "add_message_#{conversation.global_conversation_id}").process_new_message(message_args, recipients, message_ids, tags)
      # The message is delayed and will be processed later so there is nothing to return
      # right now. If there is no error, success can be assumed.
      { message: nil, recipients_count: recipients ? recipients.count : 0, status: :accepted }
    end
  rescue ConversationsHelper::InvalidMessageForConversationError
    raise ConversationsHelper::Error.new(message: I18n.t("not for this conversation"), status: :bad_request, attribute: "included_messages")
  rescue ConversationsHelper::InvalidMessageParticipantError
    raise ConversationsHelper::Error.new(message: I18n.t("not a participant"), status: :bad_request, attribute: "included_messages")
  end

  def contexts_for(audience, context_tags)
    result = { courses: {}, groups: {} }
    return result if audience.empty?

    context_tags.each do |tag|
      next unless tag =~ /\A(course|group)_(\d+)\z/

      result[:"#{$1}s"][$2.to_i] = []
    end

    if audience.size == 1 && include_private_conversation_enrollments
      enrollments = Shard.partition_by_shard(result[:courses].keys) do |course_ids|
        next unless audience.first.associated_shards.include?(Shard.current)

        Enrollment.where(course_id: course_ids, user_id: audience.first.id, workflow_state: "active").select([:course_id, :type]).to_a
      end
      enrollments.each do |enrollment|
        result[:courses][enrollment.course_id] << enrollment.type
      end

      memberships = Shard.partition_by_shard(result[:groups].keys) do |group_ids|
        next unless audience.first.associated_shards.include?(Shard.current)

        GroupMembership.where(group_id: group_ids, user_id: audience.first.id, workflow_state: "accepted").select(:group_id).to_a
      end
      memberships.each do |membership|
        result[:groups][membership.group_id] = ["Member"]
      end
    end
    result
  end

  def normalize_recipients(recipients: nil, context_code: nil, conversation_id: nil, current_user: @current_user)
    if defined?(params)
      recipients ||= params[:recipients]
      context_code ||= params[:context_code]
      conversation_id ||= params[:from_conversation_id]
    end

    return unless recipients

    unless recipients.is_a? Array
      recipients = recipients.split ","
      params[:recipients] = recipients if defined?(params)
    end

    # unrecognized context codes are ignored
    if AddressBook.valid_context?(context_code)
      context = AddressBook.load_context(context_code)
      raise InvalidContextError if context.nil?
    end

    users, contexts = AddressBook.partition_recipients(recipients)
    known = current_user.address_book.known_users(
      users,
      context:,
      conversation_id:,
      strict_checks: !Account.site_admin.grants_right?(current_user, session, :send_messages)
    )

    # include users that were already part of the given conversation
    if conversation_id && conversation_id != ""
      unknown_users = users - known.pluck(:id)
      conversation_participant_ids = Conversation.find(conversation_id).participants.pluck(:id)
      unknown_users = unknown_users.select do |unknown_user|
        conversation_participant_ids.include?(unknown_user)
      end
      known.concat(unknown_users.map { |id| MessageableUser.find(id) })
    end

    contexts.each { |c| known.concat(current_user.address_book.known_in_context(c)) }
    @recipients = known.uniq(&:id)
    @recipients.reject! { |u| u.id == current_user.id } unless @recipients == [current_user] && recipients.count == 1
    @recipients
  end

  def get_invalid_recipients(context, recipients, current_user)
    if context.is_a?(Course) && context.available? && !recipients.nil? && (context.user_is_student?(current_user) && !context.user_is_instructor?(current_user) && !context.user_is_admin?(current_user))
      valid_student_recipients = context.current_users.pluck(:id, :name)
      recipients.map { |recipient| [recipient.id, recipient.name] } - valid_student_recipients
    end
  end

  def all_recipients_are_instructors?(context, recipients)
    if context.is_a?(Course)
      return recipients.inject(true) do |all_recipients_are_instructors, recipient|
        all_recipients_are_instructors && context.user_is_instructor?(recipient)
      end
    end
    false
  end

  def observer_to_linked_students(recipients)
    observee_ids = @current_user.enrollments.where(type: "ObserverEnrollment").distinct.pluck(:associated_user_id)
    return false if observee_ids.empty?

    recipients.each do |recipient|
      return false if observee_ids.exclude?(recipient.id)
    end

    true
  end

  def valid_context?(context)
    case context
    when Account then valid_account_context?(context)
    when Course, Group then context.membership_for_user(@current_user) || context.grants_right?(@current_user, session, :send_messages)
    else false
    end
  end

  def valid_account_context?(account)
    return false unless account.root_account?
    return true if account.grants_right?(@current_user, session, :read_roster)

    user_sub_accounts = @current_user.associated_accounts.shard(@current_user).where(root_account_id: account).to_a
    user_sub_accounts.any? { |a| a.grants_right?(@current_user, session, :read_roster) }
  end

  def build_message
    Conversation.build_message(*build_message_args)
  end

  def build_message_args(
    body: nil,
    attachment_ids: nil,
    forwarded_message_ids: nil,
    domain_root_account_id: nil,
    media_comment_id: nil,
    media_comment_type: nil,
    user_note: nil,
    current_user: @current_user
  )
    if defined?(params)
      body ||= params[:body]
      attachment_ids ||= params[:attachment_ids]
      forwarded_message_ids ||= params[:forwarded_message_ids]
      domain_root_account_id ||= @domain_root_account.id
      media_comment_id ||= params[:media_comment_id]
      media_comment_type ||= params[:media_comment_type]
      user_note = value_to_boolean(params[:user_note]) if user_note.nil?
    end
    [
      current_user,
      body,
      {
        attachment_ids:,
        forwarded_message_ids:,
        root_account_id: domain_root_account_id,
        media_comment: infer_media_comment(media_comment_id, media_comment_type, domain_root_account_id, current_user),
        generate_user_note: user_note
      }
    ]
  end

  def infer_media_comment(media_id, media_type, root_account_id, user)
    if media_id.present? && media_type.present?
      media_comment = MediaObject.by_media_id(media_id).first
      unless media_comment
        media_comment ||= MediaObject.new
        media_comment.media_type = media_type
        media_comment.media_id = media_id
        media_comment.root_account_id = root_account_id
        media_comment.user = user
      end
      media_comment.context = user
      media_comment.save
      media_comment
    end
  end

  def infer_tags(tags: nil, recipients: nil, context_code: nil)
    tags = defined?(params) ? param_array(:tags) : Array(tags || []).compact
    recipients = defined?(params) ? param_array(:recipients) : Array(recipients || []).compact
    context_code = defined?(params) ? param_array(:context_code) : Array(context_code || []).compact

    tags = tags.concat(recipients).concat(context_code)
    tags = SimpleTags.normalize_tags(tags)
    tags += tags.grep(/\Agroup_(\d+)\z/) { g = Group.where(id: $1.to_i).first and g.context.asset_string }.compact
    @tags = tags.uniq
  end

  # look up the param and cast it to an array. treat empty string same as empty
  def param_array(key)
    Array(params[key].presence || []).compact
  end

  def soft_concluded_course_for_user?(course, user)
    # Fetch active enrollments for the user in the course and map to their types
    user_enrollment_types = course.enrollments.active.where(user_id: user.id).map(&:type)
    return course.soft_concluded? if user_enrollment_types.empty?

    # If the user has an active enrollment type or active section, the course is not soft concluded for that user
    !(has_active_enrollment_type?(course, user_enrollment_types) || user_has_active_section?(course, user))
  end

  def user_has_active_section?(course, user)
    visible_sections = course.sections_visible_to(user)
    visible_sections.any? { |section| !section.concluded? }
  end

  def has_active_enrollment_type?(course, enrollment_types)
    return false if enrollment_types.empty?

    !enrollment_types.all? { |enrollment_name| course.soft_concluded?(enrollment_name) }
  end

  def validate_context(context, recipients)
    recipients_are_instructors = all_recipients_are_instructors?(context, recipients)

    if context.is_a?(Course) &&
       !recipients_are_instructors &&
       !observer_to_linked_students(recipients) &&
       !context.grants_right?(@current_user, session, :send_messages)

      raise InvalidContextPermissionsError
    elsif !valid_context?(context)
      raise InvalidContextError
    end

    if context.is_a?(Course) && (context.workflow_state == "completed" || soft_concluded_course_for_user?(context, @current_user))
      raise CourseConcludedError
    end
  end

  def validate_message_ids(message_ids, conversation, current_user: @current_user)
    if message_ids
      # sanity check: are the messages part of this conversation?
      db_ids = ConversationMessage.where(id: message_ids, conversation_id: conversation.conversation_id).pluck(:id)
      raise InvalidMessageForConversationError unless db_ids.count == message_ids.count

      message_ids = db_ids

      # sanity check: can the user see the included messages?
      found_count = 0
      Shard.partition_by_shard(message_ids) do |shard_message_ids|
        found_count += ConversationMessageParticipant.where(conversation_message_id: shard_message_ids, user_id: current_user).count
      end
      raise InvalidMessageParticipantError unless found_count == message_ids.count
    end
  end

  class Error < StandardError
    attr_accessor :message, :status, :attribute

    def initialize(message:, status:, attribute:)
      super
      @message = message
      @status = status
      @attribute = attribute
    end
  end

  class RepliesLockedForUser < Error; end

  class InvalidContextError < StandardError; end

  class InvalidContextPermissionsError < StandardError; end

  class CourseConcludedError < StandardError; end

  class InvalidRecipientsError < StandardError; end

  class InvalidMessageForConversationError < StandardError; end

  class InvalidMessageParticipantError < StandardError; end
end
