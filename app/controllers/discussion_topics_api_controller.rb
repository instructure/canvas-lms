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

# @API Discussion Topics
#
# API for accessing and participating in discussion topics in groups and courses.
class DiscussionTopicsApiController < ApplicationController
  include Api::V1::DiscussionTopics

  before_filter :require_context
  before_filter :require_topic
  before_filter :require_initial_post, :except => :add_entry

  # @API
  # Create a new entry in a discussion topic. Returns a json representation of
  # the created entry (see documentation for 'entries' method) on success.
  #
  # @argument message The body of the entry.
  #
  # @argument attachment [Optional] a multipart/form-data form-field-style
  #   attachment. Attachments larger than 1 kilobyte are subject to quota
  #   restrictions.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries.json' \ 
  #        -u '<username>:<password>' \ 
  #        -F 'api_key=<key>' \ 
  #        -F 'message=<message>' \ 
  #        -F 'attachment=@<filename>'
  def add_entry
    @entry = build_entry(@topic.discussion_entries)
    if authorized_action(@topic, @current_user, :read) && authorized_action(@entry, @current_user, :create)
      has_attachment = params[:attachment] && params[:attachment].size > 0 &&
        @entry.grants_right?(@current_user, session, :attach)
      return if has_attachment && params[:attachment].size > 1.kilobytes &&
        quota_exceeded(named_context_url(@context, :context_discussion_topic_url, @topic.id))
      if save_entry
        if has_attachment
          @attachment = @context.attachments.create(:uploaded_data => params[:attachment])
          @entry.attachment = @attachment
          @entry.save
        end
        render :json => discussion_entry_api_json([@entry], @context, @current_user, session).first, :status => :created
      end
    end
  end

  # @API
  # Retrieve the (paginated) top-level entries in a discussion topic.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # Will include the 10 most recent replies, if any, for each entry returned.
  #
  # If the topic is a root topic with children corresponding to groups of a
  # group assignment, entries from those subtopics for which the user belongs
  # to the corresponding group will be returned.
  #
  # Ordering of returned entries is newest-first by posting timestamp (reply
  # activity is ignored).
  #
  # @response_field id The unique identifier for the entry.
  #
  # @response_field user_id The unique identifier for the author of the entry.
  #
  # @response_field user_name The name of the author of the entry.
  #
  # @response_field message The content of the entry.
  #
  # @response_field created_at The creation time of the entry, in ISO8601
  #   format.
  #
  # @response_field updated_at The updated time of the entry, in ISO8601 format.
  #
  # @response_field attachment JSON representation of the attachment for the
  #   entry, if any. Present only if there is an attachment.
  #
  # @response_field attachments *Deprecated*. Same as attachment, but returned
  #   as a one-element array. Present only if there is an attachment.
  #
  # @response_field recent_replies The 10 most recent replies for the entry,
  #   newest first. Present only if there is at least one reply.
  #
  # @response_field has_more_replies True if there are more than 10 replies for
  #   the entry (i.e., not all were included in this response). Present only if
  #   there is at least one reply.
  #
  # @example_response
  #   [ {
  #       "id": 1019,
  #       "user_id": 7086,
  #       "user_name": "nobody@example.com",
  #       "message": "Newer entry",
  #       "created_at": "2011-11-03T21:33:29Z",
  #       "attachment": {
  #         "content-type": "unknown/unknown",
  #         "url": "http://www.example.com/files/681/download?verifier=JDG10Ruitv8o6LjGXWlxgOb5Sl3ElzVYm9cBKUT3",
  #         "filename": "content.txt",
  #         "display_name": "content.txt" } },
  #     {
  #       "id": 1016,
  #       "user_id": 7086,
  #       "user_name": "nobody@example.com",
  #       "message": "first top-level entry",
  #       "created_at": "2011-11-03T21:32:29Z",
  #       "recent_replies": [
  #         {
  #           "id": 1017,
  #           "user_id": 7086,
  #           "user_name": "nobody@example.com",
  #           "message": "Reply message",
  #           "created_at": "2011-11-03T21:32:29Z"
  #         } ],
  #       "has_more_replies": false } ]
  def entries
    if authorized_action(@topic, @current_user, :read)
      @entries = Api.paginate(root_entries(@topic).newest_first, self, entry_pagination_path(@topic))
      render :json => discussion_entry_api_json(@entries, @context, @current_user, session)
    end
  end

  # @API
  # Add a reply to a top-level entry in a discussion topic. Returns a json
  # representation of the created reply (see documentation for 'replies'
  # method) on success.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # @argument message The body of the entry.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>/replies.json' \ 
  #        -u '<username>:<password>' \ 
  #        -F 'api_key=<key>' \ 
  #        -F 'message=<message>'
  def add_reply
    @parent = root_entries(@topic).find(params[:entry_id])
    @entry = build_entry(@parent.discussion_subentries)
    if authorized_action(@topic, @current_user, :read) && authorized_action(@entry, @current_user, :create)
      if save_entry
        render :json => discussion_entry_api_json([@entry], @context, @current_user, session).first, :status => :created
      end
    end
  end

  # @API
  # Retrieve the (paginated) replies to a top-level entry in a discussion
  # topic.
  #
  # May require (depending on the topic) that the user has posted in the topic.
  # If it is required, and the user has not posted, will respond with a 403
  # Forbidden status and the body 'require_initial_post'.
  #
  # Ordering of returned entries is newest-first by creation timestamp.
  #
  # @response_field id The unique identifier for the reply.
  #
  # @response_field user_id The unique identifier for the author of the reply.
  #
  # @response_field user_name The name of the author of the reply.
  #
  # @response_field message The content of the reply.
  #
  # @response_field created_at The creation time of the reply, in ISO8601
  #   format.
  #
  # @example_response
  #   [ {
  #       "id": 1015,
  #       "user_id": 7084,
  #       "user_name": "nobody@example.com",
  #       "message": "Newer message",
  #       "created_at": "2011-11-03T21:27:44Z" },
  #     {
  #       "id": 1014,
  #       "user_id": 7084,
  #       "user_name": "nobody@example.com",
  #       "message": "Older message",
  #       "created_at": "2011-11-03T21:26:44Z" } ]
  def replies
    @parent = root_entries(@topic).find(params[:entry_id])
    if authorized_action(@topic, @current_user, :read)
      @replies = Api.paginate(reply_entries(@parent).newest_first, self, reply_pagination_path(@parent))
      render :json => discussion_entry_api_json(@replies, @context, @current_user, session)
    end
  end

  protected
  def require_topic
    @topic = @context.all_discussion_topics.active.find(params[:topic_id])
    return authorized_action(@topic, @current_user, :read)
  end

  def require_initial_post
    return true unless @topic.require_initial_post?

    users = []
    users << @current_user if @current_user
    users << @context_enrollment.associated_user if @context_enrollment && @context_enrollment.respond_to?(:associated_user_id) && @context_enrollment.associated_user_id
    return true if users.any?{ |user| @topic.user_can_see_posts?(user, session) }

    # neither the current user nor the enrollment user (if any) has posted yet,
    # so give them the forbidden status
    render :json => 'require_initial_post', :status => :forbidden
    return false
  end

  def build_entry(association)
    association.build(:message => params[:message], :user => @current_user, :discussion_topic => @topic)
  end

  def save_entry
    if !@entry.save
      render :json => @entry.errors.to_json, :status => :bad_request
      return false
    end
    @entry.update_topic
    log_asset_access(@topic, 'topics', 'topics', 'participate')
    @entry.context_module_action
    return true
  end

  def root_entries(topic)
    # conflate entries from all child topics for groups the user can access
    topics = [topic]
    if topic.for_group_assignment? && !topic.child_topics.empty?
      groups = topic.assignment.group_category.groups.active.select do |group|
        group.grants_right?(@current_user, session, :read)
      end
      topic.child_topics.each{ |t| topics << t if groups.include?(t.context) }
    end
    DiscussionEntry.top_level_for_topics(topics).active
  end

  def reply_entries(entry)
    entry.unordered_discussion_subentries.active
  end
end
