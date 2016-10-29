#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::Conversation
  include Api::V1::Json
  include Api::V1::Submission
  include Api::V1::Attachment

  def conversations_json(conversations, current_user, session, options = {})
    include_context_name = options.delete(:include_context_name)
    if include_context_name
      context_names_by_type_and_id = Context.names_by_context_types_and_ids(conversations.map(&:conversation).map(&:context_components))
    end
    conversations.map do |c|
      result = conversation_json(c, current_user, session, options)
      result[:context_name] = context_names_by_type_and_id[c.context_components] if include_context_name
      result
    end
  end

  def conversation_json(conversation, current_user, session, options = {})
    options = {
      :include_participant_contexts => true
    }.merge(options)
    result = conversation.as_json(options)
    participants = conversation.participants(options.slice(:include_participant_contexts, :include_indirect_participants))
    explicit_participants = conversation.participants
    audience = conversation.other_participants(explicit_participants)
    result[:messages] = options[:messages].map{ |m| conversation_message_json(m, current_user, session) } if options[:messages]
    result[:submissions] = options[:submissions].map { |s| submission_json(s, s.assignment, current_user, session, nil, ['assignment', 'submission_comments']) } if options[:submissions]
    result[:audience] = audience.map(&:id)
    result[:audience].map!(&:to_s) if stringify_json_ids?
    result[:audience_contexts] = contexts_for(audience, conversation.local_context_tags)
    result[:avatar_url] = avatar_url_for(conversation, explicit_participants)
    result[:participants] = conversation_users_json(participants, current_user, session, options)
    result[:visible] = options.key?(:visible) ? options[:visible] : @set_visibility && infer_visibility(conversation)
    result[:context_name] = conversation.context_name if options[:include_context_name]
    result[:context_code] = conversation.conversation.context_code
    if options[:include_beta]
      result[:beta] = !!conversation.conversation.context_id
    end
    result
  end

  def conversation_message_json(message, current_user, session)
    result = message.as_json
    result['participating_user_ids'] = message.conversation_message_participants.pluck(:user_id)
    result['media_comment'] = media_comment_json(result['media_comment']) if result['media_comment']
    result['attachments'] = result['attachments'].map{ |attachment| attachment_json(attachment, current_user) }
    result['forwarded_messages'] = result['forwarded_messages'].map{ |m| conversation_message_json(m, current_user, session) }
    result['submission'] = submission_json(message.submission, message.submission.assignment, current_user, session, nil, ['assignment', 'submission_comments']) if message.submission
    result
  end

  # ensure the common contexts for those users are fetched and cached in
  # bulk, if not already done
  def preload_common_contexts(current_user, recipients)
    users = recipients.select{ |recipient| recipient.is_a?(User) }
    current_user.address_book.preload_users(users)
  end

  def conversation_recipients_json(recipients, current_user, session)
    ActiveRecord::Associations::Preloader.new.preload(recipients.select{|r| r.is_a?(User)},
      {:pseudonym => :account}) # for avatar_url

    preload_common_contexts(current_user, recipients)
    recipients.map do |recipient|
      if recipient.is_a?(User)
        conversation_user_json(recipient, current_user, session,
          :include_participant_avatars => true,
          :include_participant_contexts => true)
      else
        # contexts are already json
        recipient
      end
    end
  end

  def conversation_users_json(users, current_user, session, options = {})
    options = {
      :include_participant_avatars => true,
      :include_participant_contexts => true
    }.merge(options)
    if options[:include_participant_avatars]
      ActiveRecord::Associations::Preloader.new.preload(users, {:pseudonym => :account}) # for avatar_url
    end

    preload_common_contexts(current_user, users) if options[:include_participant_contexts]
    users.map { |user| conversation_user_json(user, current_user, session, options) }
  end

  def conversation_user_json(user, current_user, session, options = {})
    result = {
      :id => user.id,
      :name => user.short_name
    }
    if options[:include_participant_contexts]
      result[:common_courses] = current_user.address_book.common_courses(user)
      result[:common_groups] = current_user.address_book.common_groups(user)
    end
    result[:avatar_url] = avatar_url_for_user(user, blank_fallback) if options[:include_participant_avatars]
    result
  end

  def conversation_batch_json(batch, current_user, session)
    result = api_json batch,
                      current_user,
                      session,
                      :only => %w{id workflow_state},
                      :methods => %w{completion recipient_count}
    result[:message] = conversation_message_json(batch.root_conversation_message, current_user, session)
    result[:tags] = batch.local_tags
    result
  end

  def deleted_conversation_json(conversation_message_participant, current_user, session)
    hash = conversation_message_json(conversation_message_participant.conversation_message, current_user, session)
    hash['deleted_at'] = conversation_message_participant.deleted_at
    hash['user_id'] = conversation_message_participant.user_id
    hash['conversation_id'] = conversation_message_participant.conversation_message.conversation_id
    hash
  end
end
