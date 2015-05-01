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

module Api::V1::DiscussionTopics
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::Attachment
  include Api::V1::Locked
  include Api::V1::Assignment

  # Public: DiscussionTopic fields to serialize.
  ALLOWED_TOPIC_FIELDS  = %w{id title assignment_id delayed_post_at lock_at
    last_reply_at posted_at root_topic_id podcast_has_student_posts
    discussion_type position}

  # Public: DiscussionTopic methods to serialize.
  ALLOWED_TOPIC_METHODS = [:user_name, :discussion_subentry_count]

  # Public: Serialize an array of DiscussionTopic objects for returning as JSON.
  #
  # topics - An array of DiscussionTopic objects.
  # context - The current context.
  # user - The current user.
  # session - The current session.
  #
  # Returns an array of hashes.
  def discussion_topics_api_json(topics, context, user, session, opts={})
    topics.inject([]) do |result, topic|
      if topic.visible_for?(user, check_policies: true)
        result << discussion_topic_api_json(topic, context, user, session, opts)
      end

      result
    end
  end

  # Public: Serialize a discussion topic for returning as JSON.
  #
  # topic - The discussion topic to serialize.
  # context - The current context.
  # user - The requesting user.
  # session - The current session.
  # include_assignment - Optionally include the topic's assignment, if any (default: true).
  #
  # Returns a hash.
  def discussion_topic_api_json(topic, context, user, session, opts = {})
    opts.reverse_merge!(
      include_assignment: true,
      override_dates: true
    )

    opts[:user_can_moderate] = context.grants_right?(user, session, :moderate_forum) if opts[:user_can_moderate].nil?
    json = api_json(topic, user, session, { only: ALLOWED_TOPIC_FIELDS, methods: ALLOWED_TOPIC_METHODS }, [:attach, :update, :delete])
    json.merge!(serialize_additional_topic_fields(topic, context, user, opts))

    if hold = topic.subscription_hold(user, @context_enrollment, session)
      json[:subscription_hold] = hold
    end

    locked_json(json, topic, user, session)
    if opts[:include_assignment] && topic.assignment
      json[:assignment] = assignment_json(topic.assignment, user, session,
        include_discussion_topic: false, override_dates: opts[:override_dates])
    end

    json
  end

  # Internal: Return a hash of hard-to-generate fields for topic object.
  #
  # topic - The DiscussionTopic subject.
  # context - Current context.
  # user - Requesting user.
  #
  # Returns a hash.
  def serialize_additional_topic_fields(topic, context, user, opts={})
    attachments = topic.attachment ? [attachment_json(topic.attachment, user)] : []
    html_url    = named_context_url(context, :context_discussion_topic_url,
                                    topic, include_host: true)
    url         = if topic.podcast_enabled?
                    code = (@context_enrollment || @context || context).feed_code
                    feeds_topic_format_path(topic.id, code, :rss)
                  else
                    nil
                  end

    { message: api_user_content(topic.message, context),
      require_initial_post: topic.require_initial_post?,
      user_can_see_posts: topic.user_can_see_posts?(user), podcast_url: url,
      read_state: topic.read_state(user), unread_count: topic.unread_count(user),
      subscribed: topic.subscribed?(user), topic_children: topic.child_topics.pluck(:id),
      attachments: attachments, published: topic.published?,
      can_unpublish: opts[:user_can_moderate] ? topic.can_unpublish?(opts) : false,
      locked: topic.locked?, can_lock: topic.can_lock?,
      author: user_display_json(topic.user, topic.context),
      html_url: html_url, url: html_url, pinned: !!topic.pinned,
      group_category_id: topic.group_category_id, can_group: topic.can_group? }
  end

  # Public: Serialize discussion entries for returning a JSON response. This method,
  #   though normally called from controllers can also be called while generating a
  #   materialized view. It returns the same JSON for every user who can access the
  #   discussion, so differs a little from normal api_json helpers.
  #
  # entries - An array of DiscussionEntry objects.
  # context - The current context.
  # user - The current user.
  # session - The current session.
  # includes - An array of optional fields to include in the response (default: [:user_name, :subentries]).
  #   Recognized fields: user_name, subentries.
  #
  # Returns an array of hashes ready to be serialized.
  def discussion_entry_api_json(entries, context, user, session, includes = [:user_name, :subentries])
    entries.map do |entry|
      serialize_entry(entry, user, context, session, includes)
    end
  end

  # Internal: Serialize a DiscussionEntry for returning a JSON response.
  #
  # entry - The DiscussionEntry subject.
  # user - The current user.
  # context - The current context.
  # session - The current session.
  # includes - An array of optional fields to include in the response.
  #
  # Returns a hash.
  def serialize_entry(entry, user, context, session, includes)
    allowed_fields  = %w{id created_at updated_at parent_id}
    allowed_methods = []
    allowed_fields << 'editor_id' if entry.deleted? || entry.editor_id
    allowed_fields << 'user_id'   if !entry.deleted?
    allowed_methods << 'user_name' if !entry.deleted? && includes.include?(:user_name)

    json = api_json(entry, user, session, only: allowed_fields, methods: allowed_methods)

    if entry.deleted?
      json[:deleted] = true
    else
      json[:message] = api_user_content(entry.message, context, user)
    end

    json.merge!(discussion_entry_attachment(entry, user, context))
    json.merge!(discussion_entry_read_state(entry, user))
    json.merge!(discussion_entry_subentries(entry, user, context, session, includes))

    json
  end

  # Internal: Serialize a DiscussionEntry's attachment object.
  #
  # entry - The DiscussionEntry subject.
  # user - The current user.
  # context - The current context.
  #
  # Returns a hash.
  def discussion_entry_attachment(entry, user, context)
    return {} unless entry.attachment
    url_options = {}
    url_options.merge!(host: Api::PLACEHOLDER_HOST, protocol: Api::PLACEHOLDER_PROTOCOL) if respond_to?(:use_placeholder_host?) && use_placeholder_host? unless respond_to?(:request)
    json = {attachment: attachment_json(entry.attachment, user, url_options)}
    json[:attachments] = [json[:attachment]]

    json
  end

  # Internal: Serialize a DiscussionEntry's read state.
  #
  # entry - The DiscussionEntry  subject.
  # user - The current user.
  #
  # Returns a hash.
  def discussion_entry_read_state(entry, user)
    return {} unless user
    participant = entry.find_existing_participant(user)

    { read_state: participant.workflow_state,
      forced_read_state: participant.forced_read_state? }
  end

  # Internal: Serialize a DiscussionEntry's subentries.
  #
  # entry - The DiscussionEntry subject.
  # user - The current user.
  # context - The current context.
  # session - The current session.
  # includes - An array of optional fields to include in the response.
  #
  # Returns a hash.
  def discussion_entry_subentries(entry, user, context, session, includes)
    return {} unless includes.include?(:subentries) && entry.root_entry_id.nil?
    replies = entry.flattened_discussion_subentries.active.newest_first.limit(11).all

    if replies.empty?
      {}
    else
      { recent_replies: discussion_entry_api_json(replies.first(10), context, user, session, includes),
        has_more_replies: replies.size > 10 }
    end
  end

  def topic_pagination_url(options = {})
    if @context.is_a? Course
      api_v1_course_discussion_topics_url(@context, options)
    else
      api_v1_group_discussion_topics_url(@context, options)
    end
  end

  def entry_pagination_url(topic)
    if @context.is_a? Course
      api_v1_course_discussion_entries_url(@context)
    else
      api_v1_group_discussion_entries_url(@context)
    end
  end

  def reply_pagination_url(entry)
    if @context.is_a? Course
      api_v1_course_discussion_replies_url(@context)
    else
      api_v1_group_discussion_replies_url(@context)
    end
  end
end
