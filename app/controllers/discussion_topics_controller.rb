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

class DiscussionTopicsController < ApplicationController
  before_filter :require_context, :except => :public_feed
  
  add_crumb("Discussions", :except => [:public_feed]) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_discussion_topics_url }
  before_filter { |c| c.active_tab = "discussions" }  

  def index
    @context.assert_assignment_group rescue nil
    @all_topics = @context.discussion_topics.active
    @all_topics = @all_topics.only_discussion_topics if params[:include_announcements] != "1"
    @topics = @all_topics.paginate(:page => params[:page]).reject{|a| a.locked_for?(@current_user, :check_policies => true) }
    if authorized_action(@context.discussion_topics.new, @current_user, :read)
      return child_topic if params[:root_discussion_topic_id] && @context.respond_to?(:context) && @context.context && @context.context.discussion_topics.find(params[:root_discussion_topic_id])
      log_asset_access("topics:#{@context.asset_string}", "topics", 'other')
      respond_to do |format|
        format.html
        format.xml  { render :xml => @topics.to_xml }
        format.json  { render :json => @topics.to_json(:methods => [:user_name, :discussion_subentry_count], :permissions => {:user => @current_user, :session => session }) }
      end
    end
  end
  
  def reorder
    if authorized_action(@context, @current_user, :moderate_forum)
      @topics = @context.discussion_topics
      @topics.first.update_order(params[:order].split(",").map{|id| id.to_i}.reverse) unless @topics.empty?
      flash[:notice] = "Topics successfully reordered"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
    end
  end
  
  def child_topic
    @root_topic = @context.context.discussion_topics.find(params[:root_discussion_topic_id])
    @topic = @context.discussion_topics.find_or_initialize_by_root_topic_id(params[:root_discussion_topic_id])
    @topic.message = @root_topic.message
    @topic.title = @root_topic.title
    @topic.assignment_id = @root_topic.assignment_id
    @topic.user_id = @root_topic.user_id
    @topic.save
    redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id)
  end
  protected :child_topic

  def show
    parent_id = params[:parent_id] || 0
    @topic = @context.all_discussion_topics.find(params[:id])
    @assignment = @topic.assignment
    @context.assert_assignment_group rescue nil
    add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
    if @topic.deleted?
      flash[:notice] = "That topic has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
      return
    end
    if authorized_action(@topic, @current_user, :read)
      @headers = !params[:headless]
      @all_entries = @topic.discussion_entries.active
      @grouped_entries = @all_entries.group_by(&:parent_id)
      @entries = @all_entries.select{|e| e.parent_id == parent_id}
      @locked = @topic.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
      @topic.context_module_action(@current_user, :read) if !@locked
      if @topic.for_group_assignment?
        if params[:combined]
          @groups = @context.groups.active.find_all_by_category(@topic.assignment.group_category).select{|g| g.grants_right?(@current_user, session, :read) }
          @topic_agglomerated = true
          @topics = @topic.child_topics.select{|t| @groups.include?(t.context) }
          @entries = @topics.map{|t| t.discussion_entries.active.find(:all, :conditions => ['parent_id = ?', 0])}.flatten.sort_by{|e| e.created_at}
        else
          @groups = @context.groups.active.find_all_by_category(@topic.assignment.group_category).select{|g| g.grants_right?(@current_user, session, :read) }
          @topics = @topic.child_topics.to_a
          @topics = @topics.select{|t| @groups.include?(t.context) } unless @topic.grants_right?(@current_user, session, :update)
          @group_entry = @topic.discussion_entries.build(:message => render_to_string(:partial => 'group_assignment_discussion_entry'))
          @group_entry.new_record_header = "Group Discussion"
          @topic_uneditable = true
          @entries = [@group_entry]
        end
      end
      if @topic.require_initial_post || (@topic.root_topic && @topic.root_topic.require_initial_post)
        user_ids = []
        user_ids << @current_user.id if @current_user
        user_ids << @context_enrollment.associated_user_id if @context_enrollment && @context_enrollment.respond_to?(:associated_user_id) && @context_enrollment.associated_user_id
        unless @entries.detect{|e| user_ids.include?(e.user_id) } || @topic.grants_right?(@current_user, session, :update)
          @initial_post_required = true
        end
      end

      log_asset_access(@topic, 'topics', 'topics')
      respond_to do |format|
        if @topic.deleted?
          flash[:notice] = "That topic has been deleted"
          format.html { redirect_to named_context_url(@context, :discussion_topics_url) }
        elsif @topics && @topics.length == 1 && !@topic.grants_right?(@current_user, session, :update)
          format.html { redirect_to named_context_url(@topics[0].context, :context_discussion_topics_url, :root_discussion_topic_id => @topic.id) }
        else
          format.html { render :action => "show" }
          format.xml  { render :xml => @topic.to_xml }
          format.json  { render :json => @entries.to_json(:methods => :user_name, :permissions => {:user => @current_user, :session => session}) }
        end
      end
    end
  end
  
  def permissions
    if authorized_action(@context, @current_user, :read)
      @topic = @context.discussion_topics.find(params[:discussion_topic_id])
      @entries = @topic.discussion_entries.active
      @entries.each{|e| e.discussion_topic = @topic }
      render :json => @entries.to_json(:only => [:id], :permissions => {:user => @current_user, :session => session})
    end
  end
  
  def generate_assignment(assignment)
    if assignment[:set_assignment] && assignment[:set_assignment] != '1'
      params[:discussion_topic][:assignment] = nil
      if @topic && @topic.assignment
        @topic.update_attribute(:assignment_id, nil)
        @topic.assignment.destroy
      end
      return
    end
    @assignment = @topic.assignment if @topic
    @assignment ||= @topic.restore_old_assignment if @topic
    @assignment ||= @context.assignments.build
    @assignment.submission_types = 'discussion_topic'
    @assignment.assignment_group_id = assignment[:assignment_group_id] || @assignment.assignment_group_id || @context.assignment_groups.first.id
    @assignment.title = params[:discussion_topic][:title]
    @assignment.points_possible = assignment[:points_possible] || @assignment.points_possible
    @assignment.due_at = assignment[:due_at] || @assignment.due_at
    # if no due_at was given, set it to 11:59 pm in the creator's time zone
    @assignment.infer_due_at
    @assignment.saved_by = :discussion_topic
    @assignment.save
    params[:discussion_topic][:assignment] = @assignment
  end
  protected :generate_assignment
  
  def create
    params[:discussion_topic].delete(:remove_attachment)

    delay_posting = params[:discussion_topic].delete(:delay_posting)
    assignment = params[:discussion_topic].delete(:assignment)
    generate_assignment(assignment) if assignment && assignment[:set_assignment]

    unless @context.grants_right?(@current_user, session, :moderate_forum)
      params[:discussion_topic].delete :podcast_enabled
      params[:discussion_topic].delete :podcast_has_student_posts
    end
    if params[:discussion_topic].delete(:is_announcement) == "1" && @context.announcements.new.grants_right?(@current_user, session, :create)
      @topic = @context.announcements.build(params[:discussion_topic])
    else
      @topic = @context.discussion_topics.build(params[:discussion_topic])
    end
    @topic.workflow_state = 'post_delayed' if delay_posting == '1' && @topic.delayed_post_at && @topic.delayed_post_at > Time.now
    @topic.delayed_post_at = "" unless @topic.post_delayed?
    @topic.user = @current_user

    if authorized_action(@topic, @current_user, :create)
      return if params[:attachment] && params[:attachment][:uploaded_data] &&
        params[:attachment][:uploaded_data].size > 1.kilobytes && 
        @topic.grants_right?(@current_user, session, :attach) &&
        quota_exceeded(named_context_url(@context, :context_discussion_topics_url))
      respond_to do |format|
        @topic.content_being_saved_by(@current_user)
        if @topic.save
          @topic.insert_at_bottom
          log_asset_access(@topic, 'topics', 'topics', 'participate')
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @topic.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @topic.attachment = @attachment
            @topic.save
          end
          flash[:notice] = 'Topic was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic) }
          format.xml  { head :created, :location => named_context_url(@context, :context_discussion_topic_url, @topic) }
          format.json  { render :json => @topic.to_json(:include => [:assignment,:attachment], :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :created }
          format.text  { render :json => @topic.to_json(:include => [:assignment,:attachment], :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :created }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @topic.errors.to_xml }
          format.json { render :json => @topic.errors.to_json, :status => :bad_request }
          format.text { render :json => @topic.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def update
    params[:discussion_topic].delete(:is_announcement)

    remove_attachment = (params[:discussion_topic] || {}).delete :remove_attachment
    @topic = @context.all_discussion_topics.find(params[:id])
    @topic.attachment_id = nil if remove_attachment == '1'

    if authorized_action(@topic, @current_user, :update)
      assignment = params[:discussion_topic].delete(:assignment)
      generate_assignment(assignment) if assignment && assignment[:set_assignment]
      if params[:discussion_topic][:lock]
        @topic.workflow_state = (params[:discussion_topic][:lock] == '1') ? 'locked' : 'active'
        params[:discussion_topic].delete :lock
      end
      unless @context.grants_right?(@current_user, session, :moderate_forum)
        params[:discussion_topic].delete :podcast_enabled
        params[:discussion_topic].delete :podcast_has_student_posts
      end
      delay_posting = params[:discussion_topic].delete :delay_posting
      delayed_post_at = params[:discussion_topic].delete :delayed_post_at
      delayed_post_at = Time.parse(delayed_post_at) if delayed_post_at
      @topic.workflow_state = (delay_posting == '1' && delayed_post_at > Time.now ? 'post_delayed' : @topic.workflow_state)
      @topic.workflow_state = 'active' if @topic.post_delayed? && (!delayed_post_at || delay_posting != '1')
      @topic.delayed_post_at = @topic.post_delayed? ? delayed_post_at : nil

      return if params[:attachment] && params[:attachment][:uploaded_data] &&
            params[:attachment][:uploaded_data].size > 1.kilobytes && 
            @topic.grants_right?(@current_user, session, :attach) &&
            quota_exceeded(named_context_url(@context, :context_discussion_topics_url))
      respond_to do |format|
        @topic.content_being_saved_by(@current_user)
        @topic.editor = @current_user
        if @topic.update_attributes(params[:discussion_topic])
          @topic.context_module_action(@current_user, :contributed) if !@locked
          if params[:attachment] && params[:attachment][:uploaded_data] && params[:attachment][:uploaded_data].size > 0 && @topic.grants_right?(@current_user, session, :attach)
            @attachment = @context.attachments.create(params[:attachment])
            @topic.attachment = @attachment
            @topic.save
          end
          flash[:notice] = 'Topic was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic) }
          format.xml  { head :ok }
          format.json  { render :json => @topic.to_json(:include => [:assignment, :attachment], :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :ok }
          format.text  { render :json => @topic.to_json(:include => [:assignment, :attachment], :methods => :user_name, :permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @topic.errors.to_xml }
          format.json { render :json => @topic.errors.to_json, :status => :bad_request }
          format.text { render :json => @topic.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @topic = @context.all_discussion_topics.find(params[:id])
    if authorized_action(@topic, @current_user, :delete)
      @topic.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_discussion_topics_url) }
        format.xml  { head :ok }
        format.json  { render :json => @topic.to_json(:include => {:user => {:only => :name} } ), :status => :ok }
      end
    end
  end
  
  def public_feed
    return unless get_feed_context
    feed = Atom::Feed.new do |f|
      f.title = "#{@context.name} Discussion Feed"
      f.links << Atom::Link.new(:href => named_context_url(@context, :context_discussion_topics_url))
      f.updated = Time.now
      f.id = named_context_url(@context, :context_discussion_topics_url)
    end
    @entries = []
    @entries.concat @context.discussion_topics.reject{|a| a.locked_for?(@current_user, :check_policies => true) }
    @entries.concat @context.discussion_entries.active
    @entries = @entries.sort_by{|e| e.updated_at}
    @entries.each do |entry|
      feed.entries << entry.to_atom
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end    
  end
  
  def public_topic_feed
  end
end
