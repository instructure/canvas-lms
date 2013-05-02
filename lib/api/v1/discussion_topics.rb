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

  def discussion_topics_api_json(topics, context, user, session)
    # remove the topics which are not visible for the current user from the returned list of topics
    topics.reject! { |t| !t.visible_for?(user, :check_policies => true) }

    topics.map do |topic|
      discussion_topic_api_json(topic, context, user, session)
    end
  end

  def discussion_topic_api_json(topic, context, user, session, include_assignment = true)
    attachments = []
    if topic.attachment
      attachments << attachment_json(topic.attachment, user)
    end

    url = nil
    if topic.podcast_enabled
      code = (@context_enrollment || @context || context).feed_code
      url = feeds_topic_format_path(topic.id, code, :rss)
    end

    children = topic.child_topics.pluck(:id)

    api_json(topic, user, session, {
                  :only => %w(id title assignment_id delayed_post_at lock_at last_reply_at posted_at root_topic_id podcast_has_student_posts),
                  :methods => [:user_name, :discussion_subentry_count], }, [:attach, :update, :delete]
    ).tap do |json|
      json.merge! :message => api_user_content(topic.message, context),
                  :discussion_type => topic.discussion_type,
                  :require_initial_post => topic.require_initial_post?,
                  :podcast_url => url,
                  :read_state => topic.read_state(user),
                  :unread_count => topic.unread_count(user),
                  :topic_children => children,
                  :attachments => attachments,
                  :locked => (topic.locked_for?(user) || topic.locked?),
                  :author => user_display_json(topic.user, topic.context),
                  :html_url => context.is_a?(CollectionItem) ? nil :
                          named_context_url(context,
                                            :context_discussion_topic_url,
                                            topic,
                                            :include_host => true)
      json[:url] = json[:html_url] # deprecated
      if include_assignment && topic.assignment
        extend Api::V1::Assignment
        json[:assignment] = assignment_json(topic.assignment, user, session, !:include_discussion_topic)
      end
      json
    end
  end

  # this is called normally from controllers, but also in non-controller
  # context by the code to build the optimized materialized view of the
  # discussion
  #
  # there is no specific user attached to this view of the discussion, the same
  # json is returned to all users who can access the discussion, so it's a bit
  # different than our normal api_json helpers
  def discussion_entry_api_json(entries, context, user, session, includes = [:user_name, :subentries])
    entries.map do |entry|
      if entry.deleted?
        json = api_json(entry, user, session, :only => %w(id created_at updated_at parent_id editor_id))
        json[:deleted] = true
      else
        json = api_json(entry, user, session,
                        :only => %w(id user_id created_at updated_at parent_id))
        json[:user_name] = entry.user_name if includes.include?(:user_name)
        json[:editor_id] = entry.editor_id if entry.editor_id
        json[:message] = api_user_content(entry.message, context, user)
        if entry.attachment
          json[:attachment] = attachment_json(entry.attachment, user, :host => HostUrl.context_host(context))
          # this is for backwards compatibility, and can go away if we make an api v2
          json[:attachments] = [json[:attachment]]
        end
      end
      json[:read_state] = entry.read_state(user) if user

      if includes.include?(:subentries) && entry.root_entry_id.nil?
        replies = entry.flattened_discussion_subentries.active.newest_first.limit(11).all
        unless replies.empty?
          json[:recent_replies] = discussion_entry_api_json(replies.first(10), context, user, session, includes)
          json[:has_more_replies] = replies.size > 10
        end
      end
      json
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
