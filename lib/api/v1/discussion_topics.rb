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
#

module Api::V1::DiscussionTopics
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::Attachment
  include Api::V1::Locked
  include Api::V1::Assignment
  include Api::V1::Section

  include HtmlTextHelper

  # Public: DiscussionTopic fields to serialize.
  ALLOWED_TOPIC_FIELDS = %w[
    id
    title
    assignment_id
    delayed_post_at
    lock_at
    created_at
    last_reply_at
    posted_at
    root_topic_id
    podcast_has_student_posts
    discussion_type
    position
    allow_rating
    only_graders_can_rate
    sort_by_rating
    is_section_specific
    anonymous_state
  ].freeze

  # Public: DiscussionTopic methods to serialize.
  ALLOWED_TOPIC_METHODS = [:user_name, :discussion_subentry_count].freeze

  # For the given discussion topics, get the root topics for these topics,
  # only grabbing the given fields.  Returns a hash keyed by the id of the
  # root topic.
  #
  # The ids of the root topics are always included.
  def get_root_topic_data(topics, fields)
    root_topic_ids = topics.pluck(:root_topic_id).compact_blank.uniq
    return {} unless root_topic_ids.present?

    fields_with_id = fields.unshift(:id)
    root_topics_array = DiscussionTopic.select(fields_with_id).find(root_topic_ids)
    root_topics_array.index_by(&:id)
  end

  # Public: Serialize an array of DiscussionTopic objects for returning as JSON.
  #
  # topics - An array of DiscussionTopic objects.
  # context - The current context.
  # user - The current user.
  # session - The current session.
  # opts - see discussion_topic_api_json in this file for what the options are
  # Returns an array of hashes
  def discussion_topics_api_json(topics, context, user, session, opts = {})
    DiscussionTopic.preload_can_unpublish(context, topics) if context
    root_topics = {}
    if opts[:root_topic_fields]&.length
      root_topics = get_root_topic_data(topics, opts[:root_topic_fields])
    end
    # ignore :include_sections_user_count for non-course contexts like groups
    if opts[:include_sections_user_count] && context && context.is_a?(Course)
      opts[:context_user_count] = GuardRail.activate(:secondary) { context.enrollments.not_fake.active_or_pending_by_date_ignoring_access.distinct.count(:user_id) }
    end

    ActiveRecord::Associations.preload(
      topics,
      [
        { assignment: %i[external_tool_tag post_policy rubric_association] },
        :attachment,
        :discussion_topic_participants,
        :context,
        :root_topic,
        :user
      ]
    )

    DiscussionTopic.preload_subentry_counts(topics)
    opts[:use_preload] = true
    topics.each_with_object([]) do |topic, result|
      if topic.visible_for?(user)
        result << discussion_topic_api_json(topic, context || topic.context, user, session, opts, root_topics)
      end
    end
  end

  # Public: Serialize a discussion topic for returning as JSON.
  #
  # topic - The discussion topic to serialize.
  # context - The current context.
  # user - The requesting user.
  # session - The current session.
  # opts - Supported options are:
  #   include_assignment: Optionally include the topic's assignment, if any (default: true).
  #   include_all_dates: include all dates associated with the discussion topic (default: false)
  #   override_dates: if the topic is graded, use the overridden dates for the given user (default: true)
  #   root_topic_fields: fields to fill in from root topic (if any) if not already present.
  #   include_usage_rights: Optionally include usage rights of the topic's file attachment, if any (default: false)
  # root_topics- if you alraedy have the root topics to get the root_topic_data from, pass
  #   them in.  Useful if this is to be called repeatedly and you don't want to make a
  #   db call each time.
  # Returns a hash.
  def discussion_topic_api_json(topic, context, user, session, opts = {}, root_topics = nil)
    opts.reverse_merge!(
      include_assignment: true,
      include_all_dates: false,
      override_dates: true,
      include_root_topic_data: false,
      root_topic_fields: [],
      include_overrides: false,
      assignment_opts: {}
    )

    opts[:user_can_moderate] = context.grants_right?(user, session, :moderate_forum) if opts[:user_can_moderate].nil?
    permissions = opts[:skip_permissions] ? [] : %i[attach update reply delete]
    json = api_json(topic, user, session, { only: ALLOWED_TOPIC_FIELDS, methods: ALLOWED_TOPIC_METHODS }, permissions)

    json.merge!(serialize_additional_topic_fields(topic, context, user, opts))

    if (hold = topic.subscription_hold(user, session))
      json[:subscription_hold] = hold
    end

    if opts[:include_assignment] && topic.assignment
      excludes = opts[:exclude_assignment_description] ? ["description"] : []
      json[:assignment] = assignment_json(topic.assignment,
                                          user,
                                          session,
                                          { include_discussion_topic: false,
                                            override_dates: opts[:override_dates],
                                            include_all_dates: opts[:include_all_dates],
                                            exclude_response_fields: excludes,
                                            include_overrides: opts[:include_overrides] }.merge(opts[:assignment_opts]))
    end

    # ignore :include_sections_user_count for non-course contexts like groups
    if opts[:include_sections_user_count] && !topic.is_section_specific && context.is_a?(Course)
      json[:user_count] = opts[:context_user_count] || GuardRail.activate(:secondary) { context.enrollments.not_fake.active_or_pending_by_date_ignoring_access.count }
    end

    if opts[:include_sections] && topic.is_section_specific
      section_includes = []
      section_includes.push("user_count") if opts[:include_sections_user_count]
      json[:sections] = sections_json(topic.course_sections, user, session, section_includes)
    end

    json[:todo_date] = topic.todo_date

    if opts[:root_topic_fields].present?
      # If this is called from discussion_topics_api_json then we already
      # have the topics, so don't get them again.
      root_topics ||= get_root_topic_data([topic], opts[:root_topic_fields])
      opts[:root_topic_fields].each do |field_name|
        # Only overwrite fields that are not present already.
        json[field_name] ||= root_topics[topic.root_topic_id][field_name] if root_topics[topic.root_topic_id]
      end
    end

    if user&.pronouns
      json[:user_pronouns] = user.pronouns
    end

    # topic can be announcement
    json[:is_announcement] = topic.is_announcement

    json
  end

  # Internal: Return a hash of hard-to-generate fields for topic object.
  #
  # topic - The DiscussionTopic subject.
  # context - Current context.
  # user - Requesting user.
  #
  # Returns a hash.
  def serialize_additional_topic_fields(topic, context, user, opts = {})
    attachment_opts = {}
    attachment_opts[:include] = ["usage_rights"] if opts[:include_usage_rights]
    attachments = topic.attachment ? [attachment_json(topic.attachment, user, {}, attachment_opts)] : []
    html_url    = named_context_url(context,
                                    :context_discussion_topic_url,
                                    topic,
                                    include_host: true)
    url = if topic.podcast_enabled?
            code = (@context_enrollment || @context || context).feed_code
            feeds_topic_format_path(topic.id, code, :rss)
          else
            nil
          end

    fields = { require_initial_post: topic.require_initial_post?,
               user_can_see_posts: topic.user_can_see_posts?(user),
               podcast_url: url,
               read_state: topic.read_state(user),
               unread_count: topic.unread_count(user, opts:),
               subscribed: topic.subscribed?(user, opts:),
               attachments:,
               published: topic.published?,
               can_unpublish: opts[:user_can_moderate] ? topic.can_unpublish?(opts) : false,
               locked: topic.locked?,
               can_lock: topic.can_lock?,
               comments_disabled: topic.comments_disabled?,
               author: topic.anonymous? ? nil : user_display_json(topic.user, topic.context),
               html_url:,
               url: html_url,
               pinned: !!topic.pinned,
               group_category_id: topic.group_category_id,
               can_group: topic.can_group?(opts) }

    child_topic_data = topic.root_topic? ? topic.child_topics.active.pluck(:id, :context_id) : []
    fields[:topic_children] = child_topic_data.map(&:first)
    fields[:group_topic_children] = child_topic_data.map { |id, group_id| { id:, group_id: } }

    fields[:context_code] = Context.context_code_for(topic) if opts[:include_context_code]

    topic_course = nil
    if context.is_a?(Course)
      topic_course = context
    elsif context.context_type == "Course"
      topic_course = Course.find_by(id: context.context_id)
    end

    paced_course = topic_course ? topic_course.account.feature_enabled?(:course_paces) && topic_course.enable_course_paces? : nil
    fields[:in_paced_course] = paced_course if paced_course

    locked_json(fields, topic, user, "topic", check_policies: true, deep_check_if_needed: true)
    can_view = !fields[:lock_info].is_a?(Hash) || fields[:lock_info][:can_view]
    unless opts[:exclude_messages]
      fields[:message] =
        if !can_view
          lock_explanation(fields[:lock_info], "topic", context)
        elsif opts[:plain_messages]
          topic.message # used for searching by body on index
        elsif opts[:text_only]
          html_to_text(topic.message, preserve_links: true)
        else
          api_user_content(topic.message, context)
        end
    end

    if opts[:master_course_status]
      fields.merge!(topic.master_course_api_restriction_data(opts[:master_course_status]))
    end

    fields
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
  def discussion_entry_api_json(entries, context, user, session, includes = %i[user_name subentries display_user])
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
    allowed_fields  = %w[id created_at updated_at parent_id rating_count rating_sum]
    allowed_methods = []
    allowed_fields << "editor_id" if entry.deleted? || entry.editor_id
    allowed_fields << "user_id"   unless entry.deleted?
    allowed_methods << "user_name" if !entry.deleted? && includes.include?(:user_name)

    json = api_json(entry, user, session, only: allowed_fields, methods: allowed_methods)

    if entry.deleted?
      json[:deleted] = true
    else
      json[:message] = api_user_content(entry.message, context, user)
    end

    json[:user] = user_display_json(entry.user, context) if includes.include?(:display_user)

    json.merge!(discussion_entry_attachment(entry, user))
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
  def discussion_entry_attachment(entry, user)
    return {} unless entry.attachment

    url_options = {}
    if !respond_to?(:request) && respond_to?(:use_placeholder_host?) && use_placeholder_host?
      url_options[:host] = Api::PLACEHOLDER_HOST
      url_options[:protocol] = Api::PLACEHOLDER_PROTOCOL
    end
    json = { attachment: attachment_json(entry.attachment, user, url_options) }
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

    replies = entry.flattened_discussion_subentries.active.newest_first.limit(11).to_a

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
      api_v1_course_discussion_entries_url(@context, topic)
    else
      api_v1_group_discussion_entries_url(@context, topic)
    end
  end

  def reply_pagination_url(topic, entry)
    if @context.is_a? Course
      api_v1_course_discussion_replies_url(@context, topic, entry)
    else
      api_v1_group_discussion_replies_url(@context, topic, entry)
    end
  end
end
