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

# @API Discussion Topics
#
# API for accessing and participating in discussion topics in groups and courses.
class DiscussionTopicsController < ApplicationController
  before_filter :require_context, :except => :public_feed

  add_crumb(proc { t('#crumbs.discussions', "Discussions")}, :except => [:public_feed]) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_discussion_topics_url }
  before_filter { |c| c.active_tab = "discussions" }

  include Api::V1::DiscussionTopics

  # @API
  #
  # Returns the list of discussion topics for this course.
  #
  # @response_field assignment_id The unique identifier of the assignment if the topic is for grading, otherwise null
  # @response_field attachments Array of attachments
  # @response_field delayed_post_at The datetime to post the topic (if not right away)
  # @response_field discussion_subentry_count The count of entries in the topic
  # @response_field read_state The read_state of the topic, "read" or "unread"
  # @response_field unread_count The count of unread entries of this topic
  # @response_field id The unique identifier for the discussion topic.
  # @response_field last_reply_at The datetime for when the last reply was in the topic
  # @response_field message The HTML content of the topic
  # @response_field podcast_url If the topic is a podcast topic this is the feed url for the current user
  # @response_field posted_at The datetime the topic was posted. If it is null it hasn't been posted yet. (see delayed_post_at)
  # @response_field require_initial_post If true then a user may not respond to other replies until that user has made an initial reply
  # @response_field root_topic_id If the topic is for grading and a group assignment this will point to the original topic in the course
  # @response_field title The title of the topic
  # @response_field topic_children An array of topic_ids for the group discussions the user is a part of
  # @response_field user_name The username of the creator
  # @response_field url The URL to the discussion topic in canvas
  # @response_field discussion_type The type of discussion. Values are 'side_comment', for discussions that only allow one level of nested comments, and 'threaded' for fully threaded discussions.
  # @response_field permissions[attach] If true, the calling user can attach files to this discussion's entries.
  #
  # @example_response
  #     [
  #      {
  #        "id":1,
  #        "title":"Topic 1",
  #        "message":"<p>content here</p>",
  #        "posted_at":"2037-07-21T13:29:31Z",
  #        "last_reply_at":"2037-07-28T19:38:31Z",
  #        "require_initial_post":null,
  #        "discussion_subentry_count":0,
  #        "read_state":"read",
  #        "unread_count":0,
  #        "assignment_id":null,
  #        "delayed_post_at":null,
  #        "user_name":"User Name",
  #        "topic_children":[],
  #        "root_topic_id":null,
  #        "podcast_url":"/feeds/topics/1/enrollment_1XAcepje4u228rt4mi7Z1oFbRpn3RAkTzuXIGOPe.rss",
  #        "discussion_type":"side_comment",
  #        "attachments":[
  #          {
  #            "content-type":"unknown/unknown",
  #            "url":"http://www.example.com/courses/1/files/1/download",
  #            "filename":"content.txt",
  #            "display_name":"content.txt"
  #          }
  #        ],
  #        "permissions": { "attach": true }
  #      }
  #     ]
  def index
    @context.assert_assignment_group rescue nil
    @all_topics = @context.discussion_topics.active
    @all_topics = @all_topics.only_discussion_topics if params[:include_announcements] != "1"
    @topics = Api.paginate(@all_topics, self, topic_pagination_path).reject{|a| a.locked_for?(@current_user, :check_policies => true) }.
      each { |t| t.current_user = @current_user }
    if authorized_action(@context.discussion_topics.new, @current_user, :read)
      return child_topic if params[:root_discussion_topic_id] && @context.respond_to?(:context) && @context.context && @context.context.discussion_topics.find(params[:root_discussion_topic_id])
      log_asset_access("topics:#{@context.asset_string}", "topics", 'other')
      respond_to do |format|
        format.html
        format.json do
          if api_request?
            render :json => discussion_topics_api_json(@topics, @context, @current_user, session)
          else
            render :json => @topics.to_json(:methods => [:user_name, :discussion_subentry_count, :read_state, :unread_count], :permissions => {:user => @current_user, :session => session }, :include => [:assignment,:attachment])
          end
        end
      end
    end
  end

  def reorder
    if authorized_action(@context, @current_user, :moderate_forum)
      @topics = @context.discussion_topics
      @topics.first.update_order(params[:order].split(",").map{|id| id.to_i}.reverse) unless @topics.empty?
      flash[:notice] = t :reordered_topics_notice, "Topics successfully reordered"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
    end
  end

  def child_topic
    extra_params = {:headless => 1} if params[:headless]
    @root_topic = @context.context.discussion_topics.find(params[:root_discussion_topic_id])
    @topic = @context.discussion_topics.find_or_initialize_by_root_topic_id(params[:root_discussion_topic_id])
    @topic.message = @root_topic.message
    @topic.title = @root_topic.title
    @topic.assignment_id = @root_topic.assignment_id
    @topic.user_id = @root_topic.user_id
    @topic.save
    redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id, extra_params)
  end
  protected :child_topic

  def show
    parent_id = params[:parent_id]
    @topic = @context.all_discussion_topics.find(params[:id])
    @context.assert_assignment_group rescue nil
    add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
    if @topic.deleted?
      flash[:notice] = t :deleted_topic_notice, "That topic has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
      return
    end
    if authorized_action(@topic, @current_user, :read)
      @headers = !params[:headless]
      @locked = @topic.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
      @topic.context_module_action(@current_user, :read) if !@locked
      if @topic.for_group_assignment?
        @groups = @topic.assignment.group_category.groups.active.select{ |g| g.grants_right?(@current_user, session, :read) }
        topics = @topic.child_topics.to_a
        topics = topics.select{|t| @groups.include?(t.context) } unless @topic.grants_right?(@current_user, session, :update)
        @group_topics = @groups.map do |group|
          {:group => group, :topic => topics.find{|t| t.context == group} }
        end
      end

      @initial_post_required = @topic.initial_post_required?(@current_user, @context_enrollment, session)

      log_asset_access(@topic, 'topics', 'topics')
      respond_to do |format|
        if @topic.deleted?
          flash[:notice] = t :deleted_topic_notice, "That topic has been deleted"
          format.html { redirect_to named_context_url(@context, :discussion_topics_url) }
        elsif topics && topics.length == 1 && !@topic.grants_right?(@current_user, session, :update)
          format.html { redirect_to named_context_url(topics[0].context, :context_discussion_topics_url, :root_discussion_topic_id => @topic.id) }
        else
          format.html do

            env_hash = {
              :TOPIC => {
                :ID => @topic.id,
              },
              :PERMISSIONS => {
                :CAN_REPLY => !(@topic.for_group_assignment? || @topic.locked?),
                :CAN_ATTACH => @topic.grants_right?(@current_user, session, :attach),
                :MODERATE => @context.grants_right?(@current_user, session, :moderate_forum)
              },
              :ROOT_URL => named_context_url(@context, :api_v1_context_discussion_topic_view_url, @topic),
              :ENTRY_ROOT_URL => named_context_url(@context, :api_v1_context_discussion_topic_entry_list_url, @topic),
              :REPLY_URL => named_context_url(@context, :api_v1_context_discussion_add_reply_url, @topic, ':entry_id'),
              :ROOT_REPLY_URL => named_context_url(@context, :api_v1_context_discussion_add_entry_url, @topic),
              :DELETE_URL => named_context_url(@context, :api_v1_context_discussion_delete_reply_url, @topic, ':id'),
              :UPDATE_URL => named_context_url(@context, :api_v1_context_discussion_update_reply_url, @topic, ':id'),
              :MARK_READ_URL => named_context_url(@context, :api_v1_context_discussion_topic_discussion_entry_mark_read_url, @topic, ':id'),
              :CURRENT_USER => { :id => @current_user.id, :display_name => @current_user.short_name, :avatar_image_url => avatar_image_url(User.avatar_key(@current_user.id)) },
              :INITIAL_POST_REQUIRED => @initial_post_required,
              :THREADED => @topic.threaded?
            }
            if @topic.for_assignment? && @topic.assignment.grants_right?(@current_user, session, :grade)
              env_hash[:SPEEDGRADER_URL_TEMPLATE] = named_context_url(@topic.assignment.context, :speed_grader_context_gradebook_url, :assignment_id => @topic.assignment.id, :anchor => {:student_id => ":student_id"}.to_json)
            end
            js_env :DISCUSSION => env_hash

          end
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
        @topic.assignment.saved_by = :discussion_topic
        @topic.assignment.destroy
      end
      return
    end
    @assignment = @topic.assignment if @topic
    @assignment ||= @topic.restore_old_assignment if @topic
    @assignment ||= @context.assignments.build
    @assignment.submission_types = 'discussion_topic'
    @context.assert_assignment_group
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
    @topic.current_user = @current_user

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
          flash[:notice] = t :topic_created_notice, 'Topic was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic) }
          format.json  { render :json => @topic.to_json(:include => [:assignment,:attachment], :methods => [:user_name, :read_state, :unread_count], :permissions => {:user => @current_user, :session => session}), :status => :created }
          format.text  { render :json => @topic.to_json(:include => [:assignment,:attachment], :methods => [:user_name, :read_state, :unread_count], :permissions => {:user => @current_user, :session => session}), :status => :created }
        else
          format.html { render :action => "new" }
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
        params[:discussion_topic].delete :event
      end
      delay_posting = params[:discussion_topic].delete :delay_posting
      delayed_post_at = params[:discussion_topic].delete :delayed_post_at
      delayed_post_at = Time.zone.parse(delayed_post_at) if delayed_post_at
      @topic.workflow_state = (delay_posting == '1' && delayed_post_at > Time.now ? 'post_delayed' : @topic.workflow_state)
      @topic.workflow_state = 'active' if @topic.post_delayed? && (!delayed_post_at || delay_posting != '1')
      @topic.delayed_post_at = @topic.post_delayed? ? delayed_post_at : nil
      @topic.current_user = @current_user

      return if params[:attachment] && params[:attachment][:uploaded_data] &&
            params[:attachment][:uploaded_data].size > 1.kilobytes &&
            @topic.grants_right?(@current_user, session, :attach) &&
            quota_exceeded(named_context_url(@context, :context_discussion_topics_url))
        @topic.process_event(params[:discussion_topic].delete(:event)) if params[:discussion_topic][:event]
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
          flash[:notice] = t :topic_updated_notice, 'Topic was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @topic) }
          format.json  { render :json => @topic.to_json(:include => [:assignment, :attachment], :methods => [:user_name, :read_state, :unread_count], :permissions => {:user => @current_user, :session => session}), :status => :ok }
          format.text  { render :json => @topic.to_json(:include => [:assignment, :attachment], :methods => [:user_name, :read_state, :unread_count], :permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.html { render :action => "edit" }
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
        format.html {
          flash[:notice] = t :topic_deleted_notice, "%{topic_title} deleted successfully", :topic_title => @topic.title
          redirect_to named_context_url(@context, :context_discussion_topics_url)
        }
        format.json  { render :json => @topic.to_json(:include => {:user => {:only => :name} } ), :status => :ok }
      end
    end
  end

  def public_feed
    return unless get_feed_context
    feed = Atom::Feed.new do |f|
      f.title = t :discussion_feed_title, "%{title} Discussion Feed", :title => @context.name
      f.links << Atom::Link.new(:href => polymorphic_url([@context, :discussion_topics]), :rel => 'self')
      f.updated = Time.now
      f.id = polymorphic_url([@context, :discussion_topics])
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
