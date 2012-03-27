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
class DiscussionEntriesController < ApplicationController
  before_filter :require_context, :except => :public_feed

  def show
    @entry = @context.discussion_entries.find(params[:id]).tap{|e| e.current_user = @current_user}
    if @entry.deleted?
      flash[:notice] = t :deleted_entry_notice, "That entry has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)
    end
    if authorized_action(@entry, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)}
        format.json  { render :json => @entry.to_json(:methods => :read_state) }
      end
    end
  end

  def create
    @topic = @context.discussion_topics.active.find(params[:discussion_entry].delete(:discussion_topic_id))
    params[:discussion_entry].delete :remove_attachment rescue nil
    parent_id = params[:discussion_entry].delete(:parent_id)
    @entry = @topic.discussion_entries.new(params[:discussion_entry])
    @entry.current_user = @current_user
    @entry.user_id = @current_user ? @current_user.id : nil
    @entry.parent_id = parent_id
    if authorized_action(@entry, @current_user, :create)
      return if params[:attachment] && params[:attachment][:uploaded_data] &&
        params[:attachment][:uploaded_data].size > 1.kilobytes &&
        @entry.grants_right?(@current_user, session, :attach) &&
        quota_exceeded(named_context_url(@context, :context_discussion_topic_url, @topic.id))
      respond_to do |format|
        if @entry.save
          @entry.update_topic
          log_asset_access(@topic, 'topics', 'topics', 'participate')
          @entry.context_module_action
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @entry.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @entry.attachment = @attachment
            @entry.save
          end
          flash[:notice] = t :created_entry_notice, 'Entry was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id) }
          format.json { render :json => @entry.to_json(:include => :attachment, :methods => [:user_name, :read_state], :permissions => {:user => @current_user, :session => session}), :status => :created }
          format.text { render :json => @entry.to_json(:include => :attachment, :methods => [:user_name, :read_state], :permissions => {:user => @current_user, :session => session}), :status => :created }
        else
          format.html { render :action => "new" }
          format.json { render :json => @entry.errors.to_json, :status => :bad_request }
          format.text { render :json => @entry.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  include Api::V1::DiscussionTopics

  # @API
  # Update an existing discussion entry.
  #
  # The entry must have been created by the current user, or the current user
  # must have admin rights to the discussion. If the edit is not allowed, a 401 will be returned.
  #
  # @argument message The updated body of the entry.
  #
  # @example_request
  #   curl -X PUT 'http://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>' \ 
  #        -F 'message=<message>' \ 
  #        -H "Authorization: Bearer <token>"
  def update
    @topic = @context.all_discussion_topics.active.find(params[:topic_id]) if params[:topic_id].present?
    params[:discussion_entry] ||= params
    @remove_attachment = params[:discussion_entry].delete :remove_attachment
    # unused attributes during update
    params[:discussion_entry].delete(:discussion_topic_id)
    params[:discussion_entry].delete(:parent_id)

    @entry = (@topic || @context).discussion_entries.find(params[:id])
    raise(ActiveRecord::RecordNotFound) if @entry.deleted?

    @topic ||= @entry.discussion_topic
    @entry.current_user = @current_user
    @entry.attachment_id = nil if @remove_attachment == '1'
    if authorized_action(@entry, @current_user, :update)
      return if params[:attachment] && params[:attachment][:uploaded_data] &&
        params[:attachment][:uploaded_data].size > 1.kilobytes &&
        @entry.grants_right?(@current_user, session, :attach) &&
        quota_exceeded(named_context_url(@context, :context_discussion_topic_url, @topic.id))
      @entry.editor = @current_user
      respond_to do |format|
        if @entry.update_attributes(params[:discussion_entry].slice(:message, :plaintext_message))
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @entry.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @entry.attachment = @attachment
            @entry.save
          end
          format.html {
            flash[:notice] = t :updated_entry_notice, 'Entry was successfully updated.'
            redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)
          }
          format.json { render :json => discussion_entry_api_json([@entry], @context, @current_user, session, false).first }
          format.text {  render :json => discussion_entry_api_json([@entry], @context, @current_user, session, false).first }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @entry.errors.to_json, :status => :bad_request }
          format.text { render :json => @entry.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # @API
  # Delete a discussion entry.
  #
  # The entry must have been created by the current user, or the current user
  # must have admin rights to the discussion. If the delete is not allowed, a 401 will be returned.
  #
  # The discussion will be marked deleted, and the user_id and message will be cleared out.
  #
  # @example_request
  #
  #   curl -X DELETE 'http://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id>/entries/<entry_id>' \ 
  #        -H "Authorization: Bearer <token>"
  def destroy
    @topic = @context.all_discussion_topics.active.find(params[:topic_id]) if params[:topic_id].present?
    @entry = (@topic || @context).discussion_entries.find(params[:id])
    if authorized_action(@entry, @current_user, :delete)
      @entry.editor = @current_user
      @entry.destroy

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id) }
        format.json { render :nothing => true, :status => :no_content }
      end
    end
  end

  def public_feed
    return unless get_feed_context
    @topic = @context.discussion_topics.active.find(params[:discussion_topic_id])
    if !@topic.podcast_enabled && request.format == :rss
      @problem = t :disabled_podcasts_notice, "Podcasts have not been enabled for this topic."
      @template_format = 'html'
      @template.template_format = 'html'
      render :text => @template.render(:file => "shared/unauthorized_feed", :layout => "layouts/application"), :status => :bad_request # :template => "shared/unauthorized_feed", :status => :bad_request
      return
    end
    if authorized_action(@topic, @current_user, :read)
      @all_discussion_entries = @topic.discussion_entries.active
      @discussion_entries = @all_discussion_entries
      if request.format == :rss && !@topic.podcast_has_student_posts
        @admins = @context.admins
        @discussion_entries = @discussion_entries.find_all_by_user_id(@admins.map(&:id))
      end
      if !@topic.user_can_see_posts?(@current_user)
        @discussion_entries = []
      end
      if @topic.locked_for?(@current_user) && !@topic.grants_right?(@current_user, nil, :update)
        @discussion_entries = []
      end
      respond_to do |format|
        format.atom {
          feed = Atom::Feed.new do |f|
            f.title = t :posts_feed_title, "%{title} Posts Feed", :title => @topic.title
            f.links << Atom::Link.new(:href => named_context_url(@context, :context_discussion_topic_url, @topic.id))
            f.updated = Time.now
            f.id = named_context_url(@context, :context_discussion_topic_url, @topic.id)
          end
          feed.entries << @topic.to_atom
          @discussion_entries.sort_by{|e| e.updated_at}.each do |e|
            feed.entries << e.to_atom
          end
          render :text => feed.to_xml
        }
        format.rss {
          @entries = [@topic] + @discussion_entries
          require 'rss/2.0'
          rss = RSS::Rss.new("2.0")
          channel = RSS::Rss::Channel.new
          channel.title = t :podcast_feed_title, "%{title} Posts Podcast Feed", :title => @topic.title
          channel.description = t :podcast_description, "Any media files linked from or embedded within entries in the topic \"%{title}\" will appear in this feed.", :title => @topic.title
          channel.link = named_context_url(@context, :context_discussion_topic_url, @topic.id)
          channel.pubDate = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
          elements = Announcement.podcast_elements(@entries, @context)
          elements.each do |item|
            channel.items << item
          end
          rss.channel = channel
          render :text => rss.to_s
        }
      end
    end
  end

end
