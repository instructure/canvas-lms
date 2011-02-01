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

class DiscussionEntriesController < ApplicationController
  before_filter :require_context, :except => :public_feed

  def show
    @entry = @context.discussion_entries.find(params[:id])
    if @entry.deleted?
      flash[:notice] = "That entry has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)
    end
    if authorized_action(@entry, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id)}
        format.json  { render :json => @entry.to_json }
      end
    end
  end

  def create
    @topic = @context.discussion_topics.active.find(params[:discussion_entry].delete(:discussion_topic_id))
    params[:discussion_entry].delete :remove_attachment rescue nil
    parent_id = params[:discussion_entry].delete(:parent_id)
    @entry = @topic.discussion_entries.new(params[:discussion_entry])
    
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
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @entry.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @entry.attachment = @attachment
            @entry.save
          end
          flash[:notice] = 'Entry was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id) }
          format.xml  { head :created, :location => named_context_url(@context, :context_discussion_topic_url, @topic.id) }
          format.json { render :json => @entry.to_json(:include => :attachment, :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :created }
          format.text { render :json => @entry.to_json(:include => :attachment, :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :created }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @entry.errors.to_xml }
          format.json { render :json => @entry.errors.to_json, :status => :bad_request }
          format.text { render :json => @entry.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def update
    @remove_attachment = (params[:discussion_entry] || {}).delete :remove_attachment
    # unused attributes during update
    params[:discussion_entry].delete(:discussion_topic_id)
    params[:discussion_entry].delete(:parent_id)

    @entry = @context.discussion_entries.find(params[:id])
    @topic = @entry.discussion_topic
    @entry.attachment_id = nil if @remove_attachment == '1'
    if authorized_action(@entry, @current_user, :update)
      return if params[:attachment] && params[:attachment][:uploaded_data] &&
        params[:attachment][:uploaded_data].size > 1.kilobytes && 
        @entry.grants_right?(@current_user, session, :attach) &&
        quota_exceeded(named_context_url(@context, :context_discussion_topic_url, @topic.id))
      @entry.editor = @current_user
      respond_to do |format|
        if @entry.update_attributes(params[:discussion_entry])
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @entry.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @entry.attachment = @attachment
            @entry.save
          end
          flash[:notice] = 'Entry was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id) }
          format.xml  { head :ok }
          format.json { render :json => @entry.to_json(:include => :attachment, :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :ok }
          format.text { render :json => @entry.to_json(:include => :attachment, :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @entry.errors.to_xml }
          format.json { render :json => @entry.errors.to_json, :status => :bad_request }
          format.text { render :json => @entry.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @entry = @context.discussion_entries.find(params[:id])
    if authorized_action(@entry, @current_user, :delete)
      @entry.destroy

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @entry.discussion_topic_id) }
        format.xml  { head :ok }
        format.json { render :json => @entry.to_json, :status => :ok }
      end
    end
  end
  
  def public_feed
    return unless get_feed_context
    topic = @context.discussion_topics.active.find(params[:discussion_topic_id])
    feed = Atom::Feed.new do |f|
      f.title = "#{topic.title}: #{@context.name} Discussion Feed"
      f.links << Atom::Link.new(:href => named_context_url(@context, :context_discussion_topic_url, topic.id))
      f.updated = Time.now
      f.id = named_context_url(@context, :context_discussion_topic_url, topic.id)
    end
    @entries = []
    @entries.concat topic.discussion_entries
    @entries = @entries.sort_by{|e| e.updated_at}
    @entries.each do |entry|
      feed.entries << entry.to_atom
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end
end
