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
# A discussion topic object looks like:
#
#      !!!javascript
#      {
#        // The ID of this topic.
#        "id":1,
#
#        // The topic title.
#        "title":"Topic 1",
#
#        // The HTML content of the message body.
#        "message":"<p>content here</p>",
#
#        // The URL to the discussion topic in canvas.
#        "html_url": "https://<canvas>/courses/1/discussion_topics/2",
#
#        // The datetime the topic was posted. If it is null it hasn't been
#        // posted yet. (see delayed_post_at)
#        "posted_at":"2037-07-21T13:29:31Z",
#
#        // The datetime for when the last reply was in the topic.
#        "last_reply_at":"2037-07-28T19:38:31Z",
#
#        // If true then a user may not respond to other replies until that user
#        // has made an initial reply. Defaults to false.
#        "require_initial_post":false,
#
#        // The count of entries in the topic.
#        "discussion_subentry_count":0,
#
#        // The read_state of the topic for the current user, "read" or "unread".
#        "read_state":"read",
#
#        // The count of unread entries of this topic for the current user.
#        "unread_count":0,
#
#        // The unique identifier of the assignment if the topic is for grading, otherwise null.
#        "assignment_id":null,
#
#        // The datetime to publish the topic (if not right away).
#        "delayed_post_at":null,
#
#        // whether or not this is locked for students to see.
#        "locked":false,
#
#        // The username of the topic creator.
#        "user_name":"User Name",
#
#        // An array of topic_ids for the group discussions the user is a part of.
#        "topic_children":[5, 7, 10],
#
#        // If the topic is for grading and a group assignment this will
#        // point to the original topic in the course.
#        "root_topic_id":null,
#
#        // If the topic is a podcast topic this is the feed url for the current user.
#        "podcast_url":"/feeds/topics/1/enrollment_1XAcepje4u228rt4mi7Z1oFbRpn3RAkTzuXIGOPe.rss",
#
#        // The type of discussion. Values are 'side_comment', for discussions
#        // that only allow one level of nested comments, and 'threaded' for
#        // fully threaded discussions.
#        "discussion_type":"side_comment",
#
#        // Array of file attachments.
#        "attachments":[
#          {
#            "content-type":"unknown/unknown",
#            "url":"http://www.example.com/courses/1/files/1/download",
#            "filename":"content.txt",
#            "display_name":"content.txt"
#          }
#        ],
#
#        // The current user's permissions on this topic.
#        "permissions":
#        {
#          // If true, the calling user can attach files to this discussion's entries.
#          "attach": true
#        }
#      }
class DiscussionTopicsController < ApplicationController
  before_filter :require_context, :except => :public_feed

  include Api::V1::DiscussionTopics
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride

  # @API List discussion topics
  #
  # Returns the paginated list of discussion topics for this course or group.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics \ 
  #          -H 'Authorization: Bearer <token>'
  def index
    if authorized_action(@context.discussion_topics.new, @current_user, :read)
      return child_topic if params[:root_discussion_topic_id] && @context.respond_to?(:context) && @context.context && @context.context.discussion_topics.find(params[:root_discussion_topic_id])
      log_asset_access("topics:#{@context.asset_string}", "topics", 'other')
      respond_to do |format|
        format.html do
          @active_tab = "discussions"
          add_crumb t('#crumbs.discussions', "Discussions"), named_context_url(@context, :context_discussion_topics_url)
          js_env :permissions => {
            :create => @context.discussion_topics.new.grants_right?(@current_user, session, :create),
            :moderate => @context.grants_right?(@current_user, session, :moderate_forum),
            :change_settings => user_can_edit_course_settings?
          }
          if user_can_edit_course_settings?
            js_env :SETTINGS_URL => named_context_url(@context, :api_v1_context_settings_url) #named_context_url( "/api/v1/courses/#{@context.id}/settings"
          end
        end
        format.json do
          # you can pass ?only_announcements=true to get announcements instead of discussions TODO: document
          scope = (params[:only_announcements] ?
                   @context.active_announcements :
                   @context.active_discussion_topics.only_discussion_topics)
          scope = scope.by_position
          @topics = Api.paginate(scope, self, topic_pagination_url(:only_announcements => params[:only_announcements]))
          @topics.each { |t| t.current_user = @current_user }
          if api_request?
            render :json => discussion_topics_api_json(@topics, @context, @current_user, session)
          end
        end
      end
    end
  end

  def new
    @topic = @context.send(params[:is_announcement] ? :announcements : :discussion_topics).new
    add_discussion_or_announcement_crumb
    add_crumb t :create_new_crumb, "Create new"
    edit
  end

  def edit
    @topic ||= @context.all_discussion_topics.find(params[:id])
    if authorized_action(@topic, @current_user, (@topic.new_record? ? :create : :update))
      hash =  {
        :URL_ROOT => named_context_url(@context, :api_v1_context_discussion_topics_url),
        :PERMISSIONS => {
          :CAN_CREATE_ASSIGNMENT => @context.respond_to?(:assignments) && @context.assignments.new.grants_right?(@current_user, session, :create),
          :CAN_ATTACH => @topic.grants_right?(@current_user, session, :attach),
          :CAN_MODERATE => @context.grants_right?(@current_user, session, :moderate_forum)
        }
      }

      unless @topic.new_record?
        add_discussion_or_announcement_crumb
        add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
        add_crumb t :edit_crumb, "Edit"
        hash[:ATTRIBUTES] = discussion_topic_api_json(@topic, @context, @current_user, session)
      end
      (hash[:ATTRIBUTES] ||= {})[:is_announcement] = @topic.is_announcement
      handle_assignment_edit_params(hash[:ATTRIBUTES])

      if @topic.assignment.present?
        hash[:ATTRIBUTES][:assignment][:assignment_overrides] =
          (assignment_overrides_json(@topic.assignment.overrides_visible_to(@current_user)))
      end

      categories = @context.respond_to?(:group_categories) ? @context.group_categories : []
      sections = @context.respond_to?(:course_sections) ? @context.course_sections.active : []
      js_env :DISCUSSION_TOPIC => hash,
             :SECTION_LIST => sections.map { |section| { :id => section.id, :name => section.name } },
             :GROUP_CATEGORIES => categories.
                                  reject { |category| category.student_organized? }.
                                  map { |category| { :id => category.id, :name => category.name } },
             :CONTEXT_ID => @context.id
      render :action => "edit"
    end
  end

  def show
    parent_id = params[:parent_id]
    @topic = @context.all_discussion_topics.find(params[:id])
    @presenter = DiscussionTopicPresenter.new(@topic, @current_user)
    @assignment = if @topic.for_assignment?
      AssignmentOverrideApplicator.assignment_overridden_for(@topic.assignment, @current_user)
    else
      nil
    end
    @context.assert_assignment_group rescue nil
    add_discussion_or_announcement_crumb
    add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
    if @topic.deleted?
      flash[:notice] = t :deleted_topic_notice, "That topic has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
      return
    end

    if authorized_action(@topic, @current_user, :read)
      @headers = !params[:headless]
      @locked = @topic.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true) || @topic.locked?
      @topic.change_read_state('read', @current_user)
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

            @context_module_tag = ContextModuleItem.find_tag_with_preferred([@topic, @topic.root_topic, @topic.assignment], params[:module_item_id])
            @sequence_asset = @context_module_tag.try(:content)
            env_hash = {
              :APP_URL => named_context_url(@context, :context_discussion_topic_url, @topic),
              :TOPIC => {
                :ID => @topic.id,
              },
              :PERMISSIONS => {
                :CAN_REPLY      => @locked ? false : !(@topic.for_group_assignment? || @topic.locked?),     # Can reply
                :CAN_ATTACH     => @locked ? false : @topic.grants_right?(@current_user, session, :attach), # Can attach files on replies
                :CAN_MANAGE_OWN => @context.user_can_manage_own_discussion_posts?(@current_user),           # Can moderate their own topics
                :MODERATE       => @context.grants_right?(@current_user, session, :moderate_forum)          # Can moderate any topic
              },
              :ROOT_URL => named_context_url(@context, :api_v1_context_discussion_topic_view_url, @topic),
              :ENTRY_ROOT_URL => named_context_url(@context, :api_v1_context_discussion_topic_entry_list_url, @topic),
              :REPLY_URL => named_context_url(@context, :api_v1_context_discussion_add_reply_url, @topic, ':entry_id'),
              :ROOT_REPLY_URL => named_context_url(@context, :api_v1_context_discussion_add_entry_url, @topic),
              :DELETE_URL => named_context_url(@context, :api_v1_context_discussion_delete_reply_url, @topic, ':id'),
              :UPDATE_URL => named_context_url(@context, :api_v1_context_discussion_update_reply_url, @topic, ':id'),
              :MARK_READ_URL => named_context_url(@context, :api_v1_context_discussion_topic_discussion_entry_mark_read_url, @topic, ':id'),
              :CURRENT_USER => user_display_json(@current_user),
              :INITIAL_POST_REQUIRED => @initial_post_required,
              :THREADED => @topic.threaded?
            }
            if @topic.for_assignment? &&
               @topic.assignment.grants_right?(@current_user, session, :grade) && @presenter.allows_speed_grader?
              env_hash[:SPEEDGRADER_URL_TEMPLATE] = named_context_url(@topic.assignment.context,
                                                                      :speed_grader_context_gradebook_url,
                                                                      :assignment_id => @topic.assignment.id,
                                                                      :anchor => {:student_id => ":student_id"}.to_json)
            end
            js_env :DISCUSSION => env_hash

          end
        end
      end
    end
  end

  # @API Create a new discussion topic
  #
  # Create an new discussion topic for the course or group.
  #
  # @argument title
  # @argument message
  # @argument discussion_type
  #
  # @argument delayed_post_at If a timestamp is given, the topic will not be published until that time.
  #
  # @argument podcast_enabled If true, the topic will have an associated podcast feed.
  # @argument podcast_has_student_posts If true, the podcast will include posts from students as well. Implies podcast_enabled.
  #
  # @argument require_initial_post If true then a user may not respond to other replies until that user has made an initial reply. Defaults to false.
  #
  # @argument assignment To create an assignment discussion, pass the assignment parameters as a sub-object. See the {api:AssignmentsApiController#create Create an Assignment API} for the available parameters. The name parameter will be ignored, as it's taken from the discussion title. If you want to make a discussion that was an assignment NOT an assignment, pass set_assignment = false as part of the assignment object
  #
  # @argument is_announcement If true, this topic is an announcement. It will appear in the announcements section rather than the discussions section. This requires announcment-posting permissions.
  #
  # @argument position_after By default, discusions are sorted chronologically by creation date, you can pass the id of another topic to have this one show up after the other when they are listed.
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics \ 
  #         -F title='my topic' \ 
  #         -F message='initial message' \ 
  #         -F podcast_enabled=1 \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics \ 
  #         -F title='my assignment topic' \ 
  #         -F message='initial message' \ 
  #         -F assignment[points_possible]=15 \ 
  #         -H 'Authorization: Bearer <token>'
  #
  def create
    process_discussion_topic(!!:is_new)
  end

  # @API Update a topic
  #
  # Accepts the same parameters as create
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id> \ 
  #         -F title='This will be positioned after Topic #1234' \ 
  #         -F position_after=1234 \ 
  #         -H 'Authorization: Bearer <token>'
  #
  def update
    process_discussion_topic(!:is_new)
  end

  # @API Delete a topic
  #
  # Deletes the discussion topic. This will also delete the assignment, if it's
  # an assignment discussion.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/api/v1/courses/<course_id>/discussion_topics/<topic_id> \ 
  #          -H 'Authorization: Bearer <token>'
  def destroy
    @topic = @context.all_discussion_topics.find(params[:id] || params[:topic_id])
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

  protected

  def add_discussion_or_announcement_crumb
    if  @topic.is_a? Announcement
      @active_tab = "announcements"
      add_crumb t('#crumbs.announcements', "Announcements"), named_context_url(@context, :context_announcements_url)
    else
      @active_tab = "discussions"
      add_crumb t('#crumbs.discussions', "Discussions"), named_context_url(@context, :context_discussion_topics_url)
    end
  end

  API_ALLOWED_TOPIC_FIELDS = %w(title message discussion_type delayed_post_at podcast_enabled
                                podcast_has_student_posts require_initial_post is_announcement)
  def process_discussion_topic(is_new = false)
    discussion_topic_hash = params.slice(*API_ALLOWED_TOPIC_FIELDS)
    model_type = value_to_boolean(discussion_topic_hash.delete(:is_announcement)) && @context.announcements.new.grants_right?(@current_user, session, :create) ? :announcements : :discussion_topics
    if is_new
      @topic = @context.send(model_type).build
    else
      @topic = @context.send(model_type).active.find(params[:id] || params[:topic_id])
    end

    if authorized_action(@topic, @current_user, (is_new ? :create : :update))

      discussion_topic_hash[:podcast_enabled] = true if value_to_boolean(discussion_topic_hash[:podcast_has_student_posts])

      unless @context.grants_right?(@current_user, session, :moderate_forum)
        discussion_topic_hash.delete :podcast_enabled
        discussion_topic_hash.delete :podcast_has_student_posts
      end

      @topic.send(is_new ? :user= : :editor=, @current_user)
      @topic.current_user = @current_user
      @topic.content_being_saved_by(@current_user)

      # handle delayed posting
      if discussion_topic_hash.has_key? :delayed_post_at
        @topic.delayed_post_at = discussion_topic_hash[:delayed_post_at]
        @topic.delayed_post_at = "" if @topic.delayed_post_at && @topic.delayed_post_at < Time.now
        @topic.workflow_state = 'post_delayed' if @topic.delayed_post_at
        @topic.workflow_state = 'active' if @topic.post_delayed? && !@topic.delayed_post_at
      end

      if discussion_topic_hash.has_key?(:message)
        discussion_topic_hash[:message] = process_incoming_html_content(discussion_topic_hash[:message])
      end

       #handle locking/unlocking
       if (params.has_key?(:locked) && !params[:locked].is_a?(Hash))
         if value_to_boolean(params[:locked])
           @topic.lock
         else
           @topic.unlock
         end
       end

      if @topic.update_attributes(discussion_topic_hash)
        log_asset_access(@topic, 'topics', 'topics', 'participate')
        generate_new_page_view

        # handle sort positioning
        if params[:position_after] && @context.grants_right?(@current_user, session, :moderate_forum)
          other_topic = @context.discussion_topics.active.find(params[:position_after])
          @topic.insert_at(other_topic.position)
        end

        # handle creating/removing attachment
        if @topic.grants_right?(@current_user, session, :attach)
          attachment = params[:attachment] &&
                       params[:attachment].size > 0 &&
                       params[:attachment]

          return if attachment && attachment.size > 1.kilobytes &&
                    quota_exceeded(named_context_url(@context, :context_discussion_topics_url))

          if (params.has_key?(:remove_attachment) || attachment) && @topic.attachment
            @topic.attachment.destroy!
          end

          if attachment
            @attachment = @context.attachments.create!(:uploaded_data => attachment)
            @topic.attachment = @attachment
            @topic.save
          end
        end

        # handle creating/deleting assignment
        if params[:assignment] && !@topic.root_topic_id?
          if params[:assignment].has_key?(:set_assignment) && !value_to_boolean(params[:assignment][:set_assignment])
            if @topic.assignment && @topic.assignment.grants_right?(@current_user, session, :update)
              assignment = @topic.assignment
              @topic.assignment = nil
              @topic.save!
              assignment.destroy
            end

          elsif (@assignment = @topic.assignment || @topic.restore_old_assignment || (@topic.assignment = @context.assignments.build)) &&
                 @assignment.grants_right?(@current_user, session, :update)
            update_api_assignment(@assignment, params[:assignment].merge(@topic.attributes.slice('title')))
            @assignment.submission_types = 'discussion_topic'
            @assignment.saved_by = :discussion_topic
            @topic.assignment = @assignment
            @topic.save!
          end
        end

        render :json => discussion_topic_api_json(@topic, @context, @current_user, session)
      else
        render :json => @topic.errors.to_json, :status => :bad_request
      end
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

  def user_can_edit_course_settings?
    @context.is_a?(Course) && @context.grants_right?(@current_user, session, :update)
  end

  def handle_assignment_edit_params(hash)
    hash[:title] = params[:title] if params[:title]
    if params.slice(*[:due_at, :points_possible, :assignment_group_id]).present?
      if hash[:assignment].nil? && @context.respond_to?(:assignments) && @context.assignments.new.grants_right?(@current_user, session, :create)
        hash[:assignment] ||= {}
      end
      if !hash[:assignment].nil?
        hash[:assignment][:due_at] = params[:due_at].to_date if params[:due_at]
        hash[:assignment][:points_possible] = params[:points_possible] if params[:points_possible]
        hash[:assignment][:assignment_group_id] = params[:assignment_group_id] if params[:assignment_group_id]
      end
    end
  end

end
