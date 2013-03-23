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

  def conversation_json(conversation, current_user, session, options = {})
    options = {
      :include_participant_contexts => true
    }.merge(options)
    result = conversation.as_json(options)
    participants = conversation.participants(options.slice(:include_participant_contexts, :include_indirect_participants))
    explicit_participants = conversation.participants({:include_participant_contexts => include_private_conversation_enrollments})
    audience = conversation.other_participants(explicit_participants)
    result[:messages] = options[:messages].map{ |m| conversation_message_json(m, current_user, session) } if options[:messages]
    result[:submissions] = options[:submissions].map { |s| submission_json(s, s.assignment, current_user, session, nil, ['assignment', 'submission_comments']) } if options[:submissions]
    unless interleave_submissions
      result['message_count'] = result[:submissions] ?
        result['message_count'] - result[:submissions].size :
        conversation.messages.human.scoped(:conditions => "asset_id IS NULL").size
    end
    result[:audience] = audience.map(&:id)
    result[:audience_contexts] = contexts_for(audience, conversation.local_context_tags)
    result[:avatar_url] = avatar_url_for(conversation, explicit_participants)
    result[:participants] = conversation_users_json(participants, current_user, session, options)
    result[:visible] = options.key?(:visible) ? options[:visible] : @set_visibility && infer_visibility(conversation)
    result
  end

  def conversation_message_json(message, current_user, session)
    result = message.as_json
    result['media_comment'] = media_comment_json(result['media_comment']) if result['media_comment']
    result['attachments'] = result['attachments'].map{ |attachment| attachment_json(attachment, current_user) }
    result['forwarded_messages'] = result['forwarded_messages'].map{ |m| conversation_message_json(m, current_user, session) }
    result['submission'] = submission_json(message.submission, message.submission.assignment, current_user, session, nil, ['assignment', 'submission_comments']) if message.submission
    result
  end

  def conversation_users_json(users, current_user, session, options = {})
    options = {
      :include_participant_avatars => true,
      :include_participant_contexts => true
    }.merge(options)
    users.map { |user| conversation_user_json(user, current_user, session, options) }
  end

  def conversation_user_json(user, current_user, session, options = {})
    result = {
      :id => user.id,
      :name => user.short_name
    }
    if options[:include_participant_contexts]
      result[:common_courses] = user.common_courses
      result[:common_groups] = user.common_groups
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
end