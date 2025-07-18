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

# @API Discussion Topics
class DiscussionEntriesController < ApplicationController
  before_action :require_context_and_read_access, except: :public_feed

  def show
    @entry = @context.discussion_entries.find(params[:id]).tap { |e| e.current_user = @current_user }
    page_has_instui_topnav
    if @entry.deleted?
      flash[:notice] = t :deleted_entry_notice, "That entry has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)
    end
    if authorized_action(@entry, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id) }
        format.json { render json: @entry.as_json(methods: :read_state) }
      end
    end
  end

  def create
    @topic = @context.discussion_topics.active.find(params[:discussion_entry].delete(:discussion_topic_id))
    params[:discussion_entry].delete(:remove_attachment)
    parent_id = params[:discussion_entry].delete(:parent_id)

    entry_params = params.require(:discussion_entry).permit(:message, :plaintext_message)
    entry_params[:message] = process_incoming_html_content(entry_params[:message]) if entry_params[:message]

    @entry = @topic.discussion_entries.temp_record(entry_params)
    @entry.current_user = @current_user
    @entry.user_id = @current_user&.id
    @entry.parent_id = parent_id
    if authorized_action(@entry, @current_user, :create)

      return if context_file_quota_exceeded?

      respond_to do |format|
        if @entry.save
          @entry.update_topic
          log_asset_access(@topic, "topics", "topics", "participate")
          @entry.context_module_action
          save_attachment
          flash[:notice] = t :created_entry_notice, "Entry was successfully created."
          format.html do
            redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id)
          end
          format.json do
            json = @entry.as_json(include: :attachment,
                                  methods: [:user_name, :read_state],
                                  permissions: {
                                    user: @current_user,
                                    session:
                                  })
            render(json:, status: :created)
          end
        else
          respond_to_bad_request(format, "new")
        end
      end
    end
  end

  include Api::V1::DiscussionTopics

  # @API Update an entry
  # Update an existing discussion entry.
  #
  # The entry must have been created by the current user, or the current user
  # must have admin rights to the discussion. If the edit is not allowed, a 401 will be returned.
  #
  # @argument message [String] The updated body of the entry.
  #
  # @example_request
  #   curl -X PUT 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>' \
  #        -F 'message=<message>' \
  #        -H "Authorization: Bearer <token>"
  def update
    @topic = @context.all_discussion_topics.active.find(params[:topic_id]) if params[:topic_id].present?

    entry_params = (params[:discussion_entry] || params).permit(:message, :plaintext_message, :remove_attachment)
    entry_params[:message] = process_incoming_html_content(entry_params[:message]) if entry_params[:message]

    @remove_attachment = entry_params.delete :remove_attachment

    @entry = (@topic || @context).discussion_entries.find(params[:id])
    raise(ActiveRecord::RecordNotFound) if @entry.deleted?

    @topic ||= @entry.discussion_topic
    @entry.current_user = @current_user
    @entry.attachment_id = nil if @remove_attachment == "1" || params[:attachment].nil?

    if authorized_action(@entry, @current_user, :update)
      return if context_file_quota_exceeded?

      @entry.editor = @current_user
      respond_to do |format|
        if @entry.update(entry_params)
          save_attachment
          format.html do
            flash[:notice] = t :updated_entry_notice, "Entry was successfully updated."
            redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)
          end
          format.json { render json: discussion_entry_api_json([@entry], @context, @current_user, session, [:user_name]).first }
        else
          respond_to_bad_request(format, "edit")
        end
      end
    end
  end

  # @API Delete an entry
  # Delete a discussion entry.
  #
  # The entry must have been created by the current user, or the current user
  # must have admin rights to the discussion. If the delete is not allowed, a 401 will be returned.
  #
  # The discussion will be marked deleted, and the user_id and message will be cleared out.
  #
  # @example_request
  #
  #   curl -X DELETE 'https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    @topic = @context.all_discussion_topics.active.find(params[:topic_id]) if params[:topic_id].present?
    @entry = (@topic || @context).discussion_entries.find(params[:id])
    if authorized_action(@entry, @current_user, :delete)
      @entry.editor = @current_user
      @entry.destroy

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id) }
        format.json { head :no_content }
      end
    end
  end

  def public_feed
    return unless get_feed_context

    @topic = @context.discussion_topics.active.find(params[:discussion_topic_id])
    if !@topic.podcast_enabled && request.format == :rss
      @problem = t :disabled_podcasts_notice, "Podcasts have not been enabled for this topic."
      render "shared/unauthorized_feed", status: :bad_request, formats: [:html]
      return
    end
    if authorized_action(@context, @current_user, :read) && authorized_action(@topic, @current_user, :read)
      @discussion_entries = @topic.entries_for_feed(@current_user, request.format == :rss)
      respond_to do |format|
        format.atom do
          title = t :posts_feed_title, "%{title} Posts Feed", title: @topic.title
          link = polymorphic_url([@context, @topic])

          render plain: AtomFeedHelper.render_xml(title:, link:, entries: [@topic, *@discussion_entries.sort_by(&:updated_at)])
        end
        format.rss do
          @entries = [@topic] + @discussion_entries
          require "rss/2.0"
          rss = RSS::Rss.new("2.0")
          channel = RSS::Rss::Channel.new
          channel.title = t :podcast_feed_title, "%{title} Posts Podcast Feed", title: @topic.title
          channel.description = t :podcast_description, "Any media files linked from or embedded within entries in the topic \"%{title}\" will appear in this feed.", title: @topic.title
          channel.link = polymorphic_url([@context, @topic])
          channel.pubDate = Time.zone.now.strftime("%a, %d %b %Y %H:%M:%S %z")
          elements = Announcement.podcast_elements(@entries, @context)
          elements.each do |item|
            channel.items << item
          end
          rss.channel = channel
          render plain: rss.to_s
        end
      end
    end
  end

  private

  # Internal: Determine if the current user can attach a file to the entry.
  #
  # min_filesize - The minimum size the file can be (default: 0).
  #
  # Returns a boolean.
  def can_attach?(min_filesize = 0)
    return false unless (attachment = params[:attachment])

    attachment[:uploaded_data].try(:size).to_i > min_filesize &&
      @entry.grants_right?(@current_user, session, :attach)
  end

  # Internal: Save an attachment on the context and entry.
  #
  # Returns nothing.
  def save_attachment
    return unless can_attach?

    attachment_params = params.require(:attachment)
                              .permit(Attachment.permitted_attributes)
    @attachment = @context.attachments.create(attachment_params)
    @entry.attachment = @attachment
    @entry.save
  end

  # Internal: Determine if the current context's file quota has been exceeded.
  #
  # Returns a boolean.
  def context_file_quota_exceeded?
    can_attach?(1.kilobyte) && quota_exceeded(@current_user, named_context_url(@context, :context_discussion_topic_url, @topic.id))
  end

  # Internal: Respond to a bad request by redirecting or returning error JSON.
  #
  # format - The format object from a respond_to block.
  # action - The action to redirect to for HTML requests.
  #
  # Returns nothing.
  def respond_to_bad_request(format, action)
    format.html { render(action:) }
    format.json { render(json: @entry.errors, status: :bad_request) }
  end
end
