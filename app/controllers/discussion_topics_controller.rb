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

require 'atom'

# @API Discussion Topics
#
# API for accessing and participating in discussion topics in groups and courses.
#
# @model FileAttachment
#     {
#       "id": "FileAttachment",
#       "description": "A file attachment",
#       "properties": {
#         "content-type": {
#           "example": "unknown/unknown",
#           "type": "string"
#         },
#         "url": {
#           "example": "http://www.example.com/courses/1/files/1/download",
#           "type": "string"
#         },
#         "filename": {
#           "example": "content.txt",
#           "type": "string"
#         },
#         "display_name": {
#           "example": "content.txt",
#           "type": "string"
#         }
#       }
#     }
#
# @model DiscussionTopic
#     {
#       "id": "DiscussionTopic",
#       "description": "A discussion topic",
#       "properties": {
#         "id": {
#           "description": "The ID of this topic.",
#           "example": 1,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The topic title.",
#           "example": "Topic 1",
#           "type": "string"
#         },
#         "message": {
#           "description": "The HTML content of the message body.",
#           "example": "<p>content here</p>",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "The URL to the discussion topic in canvas.",
#           "example": "https://<canvas>/courses/1/discussion_topics/2",
#           "type": "string"
#         },
#         "posted_at": {
#           "description": "The datetime the topic was posted. If it is null it hasn't been posted yet. (see delayed_post_at)",
#           "example": "2037-07-21T13:29:31Z",
#           "type": "datetime"
#         },
#         "last_reply_at": {
#           "description": "The datetime for when the last reply was in the topic.",
#           "example": "2037-07-28T19:38:31Z",
#           "type": "datetime"
#         },
#         "require_initial_post": {
#           "description": "If true then a user may not respond to other replies until that user has made an initial reply. Defaults to false.",
#           "example": false,
#           "type": "boolean"
#         },
#         "user_can_see_posts": {
#           "description": "Whether or not posts in this topic are visible to the user.",
#           "example": true,
#           "type": "boolean"
#         },
#         "discussion_subentry_count": {
#           "description": "The count of entries in the topic.",
#           "example": 0,
#           "type": "integer"
#         },
#         "read_state": {
#           "description": "The read_state of the topic for the current user, 'read' or 'unread'.",
#           "example": "read",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "read",
#               "unread"
#             ]
#           }
#         },
#         "unread_count": {
#           "description": "The count of unread entries of this topic for the current user.",
#           "example": 0,
#           "type": "integer"
#         },
#         "subscribed": {
#           "description": "Whether or not the current user is subscribed to this topic.",
#           "example": true,
#           "type": "boolean"
#         },
#         "subscription_hold": {
#           "description": "(Optional) Why the user cannot subscribe to this topic. Only one reason will be returned even if multiple apply. Can be one of: 'initial_post_required': The user must post a reply first; 'not_in_group_set': The user is not in the group set for this graded group discussion; 'not_in_group': The user is not in this topic's group; 'topic_is_announcement': This topic is an announcement",
#           "example": "not_in_group_set",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "initial_post_required",
#               "not_in_group_set",
#               "not_in_group",
#               "topic_is_announcement"
#             ]
#           }
#         },
#         "assignment_id": {
#           "description": "The unique identifier of the assignment if the topic is for grading, otherwise null.",
#           "type": "integer"
#         },
#         "delayed_post_at": {
#           "description": "The datetime to publish the topic (if not right away).",
#           "type": "datetime"
#         },
#         "published": {
#           "description": "Whether this discussion topic is published (true) or draft state (false)",
#           "example": true,
#           "type": "boolean"
#         },
#         "lock_at": {
#           "description": "The datetime to lock the topic (if ever).",
#           "type": "datetime"
#         },
#         "locked": {
#           "description": "Whether or not the discussion is 'closed for comments'.",
#           "example": false,
#           "type": "boolean"
#         },
#         "pinned": {
#           "description": "Whether or not the discussion has been 'pinned' by an instructor",
#           "example": false,
#           "type": "boolean"
#         },
#         "locked_for_user": {
#           "description": "Whether or not this is locked for the user.",
#           "example": true,
#           "type": "boolean"
#         },
#         "lock_info": {
#           "description": "(Optional) Information for the user about the lock. Present when locked_for_user is true.",
#           "$ref": "LockInfo"
#         },
#         "lock_explanation": {
#           "description": "(Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.",
#           "example": "This discussion is locked until September 1 at 12:00am",
#           "type": "string"
#         },
#         "user_name": {
#           "description": "The username of the topic creator.",
#           "example": "User Name",
#           "type": "string"
#         },
#         "topic_children": {
#           "description": "An array of topic_ids for the group discussions the user is a part of.",
#           "example": [5, 7, 10],
#           "type": "array",
#           "items": { "type": "integer"}
#         },
#         "root_topic_id": {
#           "description": "If the topic is for grading and a group assignment this will point to the original topic in the course.",
#           "type": "integer"
#         },
#         "podcast_url": {
#           "description": "If the topic is a podcast topic this is the feed url for the current user.",
#           "example": "/feeds/topics/1/enrollment_1XAcepje4u228rt4mi7Z1oFbRpn3RAkTzuXIGOPe.rss",
#           "type": "string"
#         },
#         "discussion_type": {
#           "description": "The type of discussion. Values are 'side_comment', for discussions that only allow one level of nested comments, and 'threaded' for fully threaded discussions.",
#           "example": "side_comment",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "side_comment",
#               "threaded"
#             ]
#           }
#         },
#         "group_category_id": {
#           "description": "The unique identifier of the group category if the topic is a group discussion, otherwise null.",
#           "type": "integer"
#         },
#         "attachments": {
#           "description": "Array of file attachments.",
#           "type": "array",
#           "items": { "$ref": "FileAttachment" }
#         },
#         "permissions": {
#           "description": "The current user's permissions on this topic.",
#           "example": {"attach": true},
#           "type": "object",
#           "key": { "type": "string" },
#           "value": { "type": "boolean" }
#         },
#         "allow_rating": {
#           "description": "Whether or not users can rate entries in this topic.",
#           "example": true,
#           "type": "boolean"
#         },
#         "only_graders_can_rate": {
#           "description": "Whether or not grade permissions are required to rate entries.",
#           "example": true,
#           "type": "boolean"
#         },
#         "sort_by_rating": {
#           "description": "Whether or not entries should be sorted by rating.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
class DiscussionTopicsController < ApplicationController
  before_filter :require_context_and_read_access, :except => :public_feed
  before_filter :rich_content_service_config

  include Api::V1::DiscussionTopics
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride
  include KalturaHelper
  include SubmittableHelper

  # @API List discussion topics
  #
  # Returns the paginated list of discussion topics for this course or group.
  #
  # @argument include[] [String, "all_dates"]
  #   If "all_dates" is passed, all dates associated with graded discussions'
  #   assignments will be included.
  #
  # @argument order_by [String, "position"|"recent_activity"]
  #   Determines the order of the discussion topic list. Defaults to "position".
  #
  # @argument scope [String, "locked"|"unlocked"|"pinned"|"unpinned"]
  #   Only return discussion topics in the given state(s). Defaults to including
  #   all topics. Filtering is done after pagination, so pages
  #   may be smaller than requested if topics are filtered.
  #   Can pass multiple states as comma separated string.
  #
  # @argument only_announcements [Boolean]
  #   Return announcements instead of discussion topics. Defaults to false
  #
  # @argument search_term [String]
  #   The partial title of the discussion topics to match and return.
  #
  # @argument exclude_context_module_locked_topics [Boolean]
  #   For students, exclude topics that are locked by module progression.
  #   Defaults to false.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [DiscussionTopic]
  def index
    include_params = Array(params[:include])

    if params[:only_announcements]
      return unless authorized_action(@context.announcements.temp_record, @current_user, :read)
    else
      return unless authorized_action(@context.discussion_topics.temp_record, @current_user, :read)
    end

    return child_topic if is_child_topic?

    scope = if params[:only_announcements]
              @context.active_announcements
            else
              @context.active_discussion_topics.only_discussion_topics
            end

    # Specify the shard context, because downstream we use `union` which isn't
    # cross-shard compatible.
    @context.shard.activate do
      scope = DiscussionTopic::ScopedToUser.new(@context, @current_user, scope).scope
    end

    scope = if params[:order_by] == 'recent_activity'
              scope.by_last_reply_at
            elsif params[:only_announcements]
              scope.by_posted_at
            else
              scope.by_position_legacy
            end

    scope = DiscussionTopic.search_by_attribute(scope, :title, params[:search_term])

    states = params[:scope].split(',').map{|s| s.strip} if params[:scope]
    if states.present?
      if (states.include?('pinned') && states.include?('unpinned')) ||
          (states.include?('locked') && states.include?('unlocked'))
        render json: {errors: {scope: "scope is contradictory"}}, :status => :bad_request
        return
      end

      if states.include?('pinned')
        scope = scope.where(:pinned => true)
      elsif states.include?('unpinned')
        scope = scope.where("discussion_topics.pinned IS NOT TRUE")
      end
    end

    @topics = Api.paginate(scope, self, topic_pagination_url)

    if params[:exclude_context_module_locked_topics]
      @topics = DiscussionTopic.reject_context_module_locked_topics(@topics, @current_user)
    end

    if states.present?
      @topics.reject! { |t| t.locked_for?(@current_user) } if states.include?('unlocked')
      @topics.select! { |t| t.locked_for?(@current_user) } if states.include?('locked')
    end
    @topics.each { |topic| topic.current_user = @current_user }

    respond_to do |format|
      format.html do
        log_asset_access([ "topics", @context ], 'topics', 'other')

        @active_tab = 'discussions'
        add_crumb(t('#crumbs.discussions', 'Discussions'),
                  named_context_url(@context, :context_discussion_topics_url))

        locked_topics, open_topics = @topics.partition do |topic|
          locked = topic.locked? || topic.locked_for?(@current_user)
          locked.is_a?(Hash) ? locked[:can_view] : locked
        end

        hash = {USER_SETTINGS_URL: api_v1_user_settings_url(@current_user),
                openTopics: open_topics,
                lockedTopics: locked_topics,
                newTopicURL: named_context_url(@context, :new_context_discussion_topic_url),
                permissions: {
                    create: @context.discussion_topics.temp_record.grants_right?(@current_user, session, :create),
                    moderate: user_can_moderate,
                    change_settings: user_can_edit_course_settings?,
                    manage_content: @context.grants_right?(@current_user, session, :manage_content),
                    publish: user_can_moderate
                },
                :discussion_topic_menu_tools => external_tools_display_hashes(:discussion_topic_menu)
        }
        conditional_release_js_env(includes: :active_rules)
        append_sis_data(hash)
        js_env(hash)

        if user_can_edit_course_settings?
          js_env(SETTINGS_URL: named_context_url(@context, :api_v1_context_settings_url))
        end
      end
      format.json do
        render json: discussion_topics_api_json(@topics, @context, @current_user, session,
          user_can_moderate: user_can_moderate,
          plain_messages: value_to_boolean(params[:plain_messages]),
          exclude_assignment_description: value_to_boolean(params[:exclude_assignment_descriptions]),
          include_all_dates: include_params.include?('all_dates'))
      end
    end
  end

  def is_child_topic?
    root_topic_id = params[:root_discussion_topic_id]

    root_topic_id && @context.respond_to?(:context) &&
      @context.context && @context.context.discussion_topics.find(root_topic_id)
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
        URL_ROOT: named_context_url(@context, :api_v1_context_discussion_topics_url),
        PERMISSIONS: {
          CAN_CREATE_ASSIGNMENT: @context.respond_to?(:assignments) && @context.assignments.temp_record.grants_right?(@current_user, session, :create),
          CAN_ATTACH: @topic.grants_right?(@current_user, session, :attach),
          CAN_MODERATE: user_can_moderate
        }
      }

      unless @topic.new_record?
        add_discussion_or_announcement_crumb
        add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
        add_crumb t :edit_crumb, "Edit"
        hash[:ATTRIBUTES] = discussion_topic_api_json(@topic, @context, @current_user, session, override_dates: false)
      end
      (hash[:ATTRIBUTES] ||= {})[:is_announcement] = @topic.is_announcement
      hash[:ATTRIBUTES][:can_group] = @topic.can_group?
      handle_assignment_edit_params(hash[:ATTRIBUTES])

      categories = @context.respond_to?(:group_categories) ? @context.group_categories : []
      # if discussion has entries and is attached to a deleted group category,
      # add that category to the ENV list so it will be shown on the edit page.
      if @topic.group_category_deleted_with_entries?
        categories << @topic.group_category
      end

      if @topic.assignment.present?
        hash[:ATTRIBUTES][:assignment][:assignment_overrides] =
          (assignment_overrides_json(
            @topic.assignment.overrides_for(@current_user, ensure_set_not_empty: true)
            ))
        hash[:ATTRIBUTES][:assignment][:has_student_submissions] = @topic.assignment.has_student_submissions?
      end

      sections = @context.respond_to?(:course_sections) ? @context.course_sections.active : []

      js_hash = {
        CONTEXT_ACTION_SOURCE: :discussion_topic,
        CONTEXT_ID: @context.id,
        DISCUSSION_TOPIC: hash,
        GROUP_CATEGORIES: categories.
           reject(&:student_organized?).
           map { |category| { id: category.id, name: category.name } },
        MULTIPLE_GRADING_PERIODS_ENABLED: @context.feature_enabled?(:multiple_grading_periods),
        SECTION_LIST: sections.map { |section| { id: section.id, name: section.name } }
      }

      post_to_sis = Assignment.sis_grade_export_enabled?(@context)
      js_hash[:POST_TO_SIS] = post_to_sis
      js_hash[:POST_TO_SIS_DEFAULT] = @context.account.sis_default_grade_export[:value] if post_to_sis && @topic.new_record?

      if @context.is_a?(Course)
        js_hash['SECTION_LIST'] = sections.map { |section|
          {
            id: section.id,
            name: section.name,
            start_at: section.start_at,
            end_at: section.end_at,
            override_course_and_term_dates: section.restrict_enrollments_to_section_dates
          }
        }
        js_hash['VALID_DATE_RANGE'] = CourseDateRange.new(@context)
      end
      js_hash[:CANCEL_TO] = cancel_redirect_url
      append_sis_data(js_hash)

      if @context.feature_enabled?(:multiple_grading_periods)
        gp_context = @context.is_a?(Group) ? @context.context : @context
        js_hash[:active_grading_periods] = GradingPeriod.json_for(gp_context, @current_user)
      end
      if context.is_a?(Course)
        js_hash[:allow_self_signup] = true  # for group creation
        js_hash[:group_user_type] = 'student'
      end
      js_env(js_hash)

      conditional_release_js_env(@topic.assignment)

      render :edit
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
    @context.require_assignment_group rescue nil
    add_discussion_or_announcement_crumb
    add_crumb(@topic.title, named_context_url(@context, :context_discussion_topic_url, @topic.id))
    if @topic.deleted?
      flash[:notice] = t :deleted_topic_notice, "That topic has been deleted"
      redirect_to named_context_url(@context, :context_discussion_topics_url)
      return
    end

    unless @topic.grants_right?(@current_user, session, :read)
      return render_unauthorized_action unless @current_user
      respond_to do |format|
        flash[:error] = t 'You do not have access to the requested discussion.'
        format.html { redirect_to named_context_url(@context, :context_discussion_topics_url) }
      end
    else
      @headers = !params[:headless]
      # we still need the lock info even if the current user policies unlock the topic. check the policies manually later if you need to override the lockout.
      @locked = @topic.locked_for?(@current_user, :check_policies => false, :deep_check_if_needed => true)
      @unlock_at = @topic.available_from_for(@current_user)
      @topic.change_read_state('read', @current_user) unless @locked.is_a?(Hash) && !@locked[:can_view]
      if @topic.for_group_discussion?

        group_scope = @topic.group_category.groups.active
        if @topic.for_assignment? && @topic.assignment.only_visible_to_overrides?
          @groups = group_scope.where(:id => @topic.assignment.assignment_overrides.active.where(:set_type => "Group").pluck(:set_id)).to_a
          if @groups.empty?
            @groups = group_scope.to_a # revert to default if we're not using Group overrides
          end
        else
          @groups = group_scope.to_a
        end
        @groups.select!{ |g| g.grants_any_right?(@current_user, session, :post_to_forum, :read_as_admin) }
        @groups.sort_by!(&:id)

        topics = @topic.child_topics.to_a
        topics = topics.select{|t| @groups.include?(t.context) } unless @topic.grants_right?(@current_user, session, :update)
        @group_topics = @groups.map do |group|
          {:group => group, :topic => topics.find{|t| t.context == group} }
        end
      end

      @initial_post_required = @topic.initial_post_required?(@current_user, @context_enrollment, session)

      @padless = true

      log_asset_access(@topic, 'topics', 'topics')
      respond_to do |format|
        if topics && topics.length == 1 && !@topic.grants_right?(@current_user, session, :update)
          format.html { redirect_to named_context_url(topics[0].context, :context_discussion_topics_url, :root_discussion_topic_id => @topic.id) }
        else
          format.html do

            @discussion_topic_menu_tools = external_tools_display_hashes(:discussion_topic_menu)
            @context_module_tag = ContextModuleItem.find_tag_with_preferred([@topic, @topic.root_topic, @topic.assignment], params[:module_item_id])
            @sequence_asset = @context_module_tag.try(:content)

            api_url = lambda do |endpoint, *params|
              endpoint = "api_v1_context_discussion_#{endpoint}_url"
              named_context_url(@context, endpoint, @topic, *params)
            end

            env_hash = {
              :APP_URL => named_context_url(@context, :context_discussion_topic_url, @topic),
              :TOPIC => {
                :ID => @topic.id,
                :IS_SUBSCRIBED => @topic.subscribed?(@current_user),
                :IS_PUBLISHED  => @topic.published?,
                :CAN_UNPUBLISH => @topic.can_unpublish?,
              },
              :PERMISSIONS => {
                # Can reply
                :CAN_REPLY        => @topic.grants_right?(@current_user, session, :reply),
                # Can attach files on replies
                :CAN_ATTACH       => @topic.grants_right?(@current_user, session, :attach),
                :CAN_RATE         => @topic.grants_right?(@current_user, session, :rate),
                :CAN_READ_REPLIES => @topic.grants_right?(@current_user, :read_replies),
                # Can moderate their own topics
                :CAN_MANAGE_OWN   => @context.user_can_manage_own_discussion_posts?(@current_user) &&
                                     !@topic.locked_for?(@current_user, :check_policies => true),
                # Can moderate any topic
                :MODERATE         => user_can_moderate
              },
              :ROOT_URL => api_url.call('topic_view'),
              :ENTRY_ROOT_URL => api_url.call('topic_entry_list'),
              :REPLY_URL => api_url.call('add_reply', ':entry_id'),
              :ROOT_REPLY_URL => api_url.call('add_entry'),
              :DELETE_URL => api_url.call('delete_reply', ':id'),
              :UPDATE_URL => api_url.call('update_reply', ':id'),
              :MARK_READ_URL => api_url.call('topic_discussion_entry_mark_read', ':id'),
              :MARK_UNREAD_URL => api_url.call('topic_discussion_entry_mark_unread', ':id'),
              :RATE_URL => api_url.call('topic_discussion_entry_rate', ':id'),
              :MARK_ALL_READ_URL => api_url.call('topic_mark_all_read'),
              :MARK_ALL_UNREAD_URL => api_url.call('topic_mark_all_unread'),
              :MANUAL_MARK_AS_READ => @current_user.try(:manual_mark_as_read?),
              :CAN_SUBSCRIBE => !@topic.subscription_hold(@current_user, @context_enrollment, session),
              :CURRENT_USER => user_display_json(@current_user),
              :INITIAL_POST_REQUIRED => @initial_post_required,
              :THREADED => @topic.threaded?,
              :ALLOW_RATING => @topic.allow_rating,
              :SORT_BY_RATING => @topic.sort_by_rating
            }
            if params[:hide_student_names]
              env_hash[:HIDE_STUDENT_NAMES] = true
              env_hash[:STUDENT_ID] = params[:student_id]
            end
            if @sequence_asset
              env_hash[:SEQUENCE] = {
                :ASSET_TYPE => @sequence_asset.is_a?(Assignment) ? 'Assignment' : 'Discussion',
                :ASSET_ID => @sequence_asset.id,
                :COURSE_ID => @sequence_asset.context.id,
              }
            end
            if @topic.for_assignment? &&
               @topic.assignment.grants_right?(@current_user, session, :grade) && @presenter.allows_speed_grader?
              env_hash[:SPEEDGRADER_URL_TEMPLATE] = named_context_url(@topic.assignment.context,
                                                                      :speed_grader_context_gradebook_url,
                                                                      :assignment_id => @topic.assignment.id,
                                                                      :anchor => {:student_id => ":student_id"}.to_json)
            end

            js_hash = {:DISCUSSION => env_hash}
            js_hash[:CONTEXT_ACTION_SOURCE] = :discussion_topic
            js_hash[:STUDENT_CONTEXT_CARDS_ENABLED] = @context.is_a?(Course) &&
              @domain_root_account.feature_enabled?(:student_context_cards) &&
              @context.grants_right?(@current_user, session, :manage)

            append_sis_data(js_hash)
            js_env(js_hash)
            conditional_release_js_env(@topic.assignment, includes: [:rule])
          end
        end
      end
    end
  end

  # @API Create a new discussion topic
  #
  # Create an new discussion topic for the course or group.
  #
  # @argument title [String]
  #
  # @argument message [String]
  #
  # @argument discussion_type [String, "side_comment"|"threaded"]
  #   The type of discussion. Defaults to side_comment if not value is given. Accepted values are 'side_comment', for discussions that only allow one level of nested comments, and 'threaded' for fully threaded discussions.
  #
  # @argument published [Boolean]
  #   Whether this topic is published (true) or draft state (false). Only
  #   teachers and TAs have the ability to create draft state topics.
  #
  # @argument delayed_post_at [DateTime]
  #   If a timestamp is given, the topic will not be published until that time.
  #
  # @argument lock_at [DateTime]
  #   If a timestamp is given, the topic will be scheduled to lock at the
  #   provided timestamp. If the timestamp is in the past, the topic will be
  #   locked.
  #
  # @argument podcast_enabled [Boolean]
  #   If true, the topic will have an associated podcast feed.
  #
  # @argument podcast_has_student_posts [Boolean]
  #   If true, the podcast will include posts from students as well. Implies
  #   podcast_enabled.
  #
  # @argument require_initial_post [Boolean]
  #   If true then a user may not respond to other replies until that user has
  #   made an initial reply. Defaults to false.
  #
  # @argument assignment [Assignment]
  #   To create an assignment discussion, pass the assignment parameters as a
  #   sub-object. See the {api:AssignmentsApiController#create Create an Assignment API}
  #   for the available parameters. The name parameter will be ignored, as it's
  #   taken from the discussion title. If you want to make a discussion that was
  #   an assignment NOT an assignment, pass set_assignment = false as part of
  #   the assignment object
  #
  # @argument is_announcement [Boolean]
  #   If true, this topic is an announcement. It will appear in the
  #   announcement's section rather than the discussions section. This requires
  #   announcment-posting permissions.
  #
  # @argument pinned [Boolean]
  #   If true, this topic will be listed in the "Pinned Discussion" section
  #
  # @argument position_after [String]
  #   By default, discussions are sorted chronologically by creation date, you
  #   can pass the id of another topic to have this one show up after the other
  #   when they are listed.
  #
  # @argument group_category_id [Integer]
  #   If present, the topic will become a group discussion assigned
  #   to the group.
  #
  # @argument allow_rating [Boolean]
  #   If true, users will be allowed to rate entries.
  #
  # @argument only_graders_can_rate [Boolean]
  #   If true, only graders will be allowed to rate entries.
  #
  # @argument sort_by_rating [Boolean]
  #   If true, entries will be sorted by rating.
  #
  # @argument attachment [File]
  #   A multipart/form-data form-field-style attachment.
  #   Attachments larger than 1 kilobyte are subject to quota restrictions.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/discussion_topics \
  #         -F title='my topic' \
  #         -F message='initial message' \
  #         -F podcast_enabled=1 \
  #         -H 'Authorization: Bearer <token>'
  #         -F 'attachment=@<filename>' \
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
  # Update an existing discussion topic for the course or group.
  #
  # @argument title [String]
  #
  # @argument message [String]
  #
  # @argument discussion_type [String, "side_comment"|"threaded"]
  #   The type of discussion. Defaults to side_comment if not value is given. Accepted values are 'side_comment', for discussions that only allow one level of nested comments, and 'threaded' for fully threaded discussions.
  #
  # @argument published [Boolean]
  #   Whether this topic is published (true) or draft state (false). Only
  #   teachers and TAs have the ability to create draft state topics.
  #
  # @argument delayed_post_at [DateTime]
  #   If a timestamp is given, the topic will not be published until that time.
  #
  # @argument lock_at [DateTime]
  #   If a timestamp is given, the topic will be scheduled to lock at the
  #   provided timestamp. If the timestamp is in the past, the topic will be
  #   locked.
  #
  # @argument podcast_enabled [Boolean]
  #   If true, the topic will have an associated podcast feed.
  #
  # @argument podcast_has_student_posts [Boolean]
  #   If true, the podcast will include posts from students as well. Implies
  #   podcast_enabled.
  #
  # @argument require_initial_post [Boolean]
  #   If true then a user may not respond to other replies until that user has
  #   made an initial reply. Defaults to false.
  #
  # @argument assignment [Assignment]
  #   To create an assignment discussion, pass the assignment parameters as a
  #   sub-object. See the {api:AssignmentsApiController#create Create an Assignment API}
  #   for the available parameters. The name parameter will be ignored, as it's
  #   taken from the discussion title. If you want to make a discussion that was
  #   an assignment NOT an assignment, pass set_assignment = false as part of
  #   the assignment object
  #
  # @argument is_announcement [Boolean]
  #   If true, this topic is an announcement. It will appear in the
  #   announcement's section rather than the discussions section. This requires
  #   announcment-posting permissions.
  #
  # @argument pinned [Boolean]
  #   If true, this topic will be listed in the "Pinned Discussion" section
  #
  # @argument position_after [String]
  #   By default, discussions are sorted chronologically by creation date, you
  #   can pass the id of another topic to have this one show up after the other
  #   when they are listed.
  #
  # @argument group_category_id [Integer]
  #   If present, the topic will become a group discussion assigned
  #   to the group.
  #
  # @argument allow_rating [Boolean]
  #   If true, users will be allowed to rate entries.
  #
  # @argument only_graders_can_rate [Boolean]
  #   If true, only graders will be allowed to rate entries.
  #
  # @argument sort_by_rating [Boolean]
  #   If true, entries will be sorted by rating.
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
          redirect_to named_context_url(@context, @topic.is_announcement ? :context_announcements_url : :context_discussion_topics_url)
        }
        format.json  { render :json => @topic.as_json(:include => {:user => {:only => :name} } ), :status => :ok }
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
    @entries.concat @context.discussion_topics.
      select{|dt| dt.visible_for?(@current_user) }
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

  # @API Reorder pinned topics
  #
  # Puts the pinned discussion topics in the specified order.
  # All pinned topics should be included.
  #
  # @argument order[] [Required, Integer]
  #   The ids of the pinned discussion topics in the desired order.
  #   (For example, "order=104,102,103".)
  #
  def reorder
    if authorized_action(@context.discussion_topics.temp_record, @current_user, :update)
      order = Api.value_to_array(params[:order])
      reject! "order parameter required" unless order && order.length > 0
      topics = pinned_topics.where(id: order)
      reject! "topics not found" unless topics.length == order.length
      topics[0].update_order(order)
      new_order = pinned_topics.by_position.pluck(:id).map(&:to_s)
      render :json => {:reorder => true, :order => new_order}, :status => :ok
    end
  end

  protected

  def rich_content_service_config
    rce_js_env(:highrisk)
  end

  def cancel_redirect_url
    topic_type = @topic.is_announcement ? :announcements : :discussion_topics
    @topic.new_record? ? polymorphic_url([@context, topic_type]) : polymorphic_url([@context, @topic])
  end

  def pinned_topics
    @context.active_discussion_topics.only_discussion_topics.where(pinned: true)
  end

  def add_discussion_or_announcement_crumb
    if  @topic.is_a? Announcement
      @active_tab = "announcements"
      add_crumb t('#crumbs.announcements', "Announcements"), named_context_url(@context, :context_announcements_url)
    else
      @active_tab = "discussions"
      add_crumb t('#crumbs.discussions', "Discussions"), named_context_url(@context, :context_discussion_topics_url)
    end
  end

  def user_can_moderate
    @user_can_moderate = @context.grants_right?(@current_user, session, :moderate_forum) if @user_can_moderate.nil?
    @user_can_moderate
  end

  API_ALLOWED_TOPIC_FIELDS = %w(title message discussion_type delayed_post_at lock_at podcast_enabled
                                podcast_has_student_posts require_initial_post is_announcement pinned
                                group_category_id allow_rating only_graders_can_rate sort_by_rating).freeze

  def process_discussion_topic(is_new = false)
    @errors = {}
    discussion_topic_hash = params.slice(*API_ALLOWED_TOPIC_FIELDS)
    model_type = value_to_boolean(discussion_topic_hash.delete(:is_announcement)) && @context.announcements.temp_record.grants_right?(@current_user, session, :create) ? :announcements : :discussion_topics
    if is_new
      @topic = @context.send(model_type).build
    else
      @topic = @context.send(model_type).active.find(params[:id] || params[:topic_id])
    end

    return unless authorized_action(@topic, @current_user, (is_new ? :create : :update))

    prior_version = @topic.generate_prior_version
    process_podcast_parameters(discussion_topic_hash)

    if is_new
      @topic.user = @current_user
    elsif discussion_topic_hash.except(*%w{pinned}).present? # don't update editor if the only thing that changed was the pinned status
      @topic.editor = @current_user
    end
    @topic.current_user = @current_user
    @topic.content_being_saved_by(@current_user)

    if discussion_topic_hash.has_key?(:message)
      discussion_topic_hash[:message] = process_incoming_html_content(discussion_topic_hash[:message])
    end

    unless process_future_date_parameters(discussion_topic_hash)
      process_lock_parameters(discussion_topic_hash)
    end

    process_published_parameters(discussion_topic_hash)
    if is_new && @topic.published? && params[:assignment]
      @topic.unpublish
      @topic.root_topic.try(:unpublish)
      publish_later = true
    end

    process_group_parameters(discussion_topic_hash)
    process_pin_parameters(discussion_topic_hash)

    if @errors.present?
      render :json => {errors: @errors}, :status => :bad_request
    else
      @topic.skip_broadcasts = true
      DiscussionTopic.transaction do
        @topic.update_attributes(discussion_topic_hash)
        @topic.root_topic.try(:save)
      end
      if !@topic.errors.any? && !@topic.root_topic.try(:errors).try(:any?)
        log_asset_access(@topic, 'topics', 'topics', 'participate')

        apply_positioning_parameters
        apply_attachment_parameters
        unless @topic.root_topic_id?
          apply_assignment_parameters(strong_params[:assignment], @topic)
        end

        if publish_later
          @topic.publish!
          @topic.root_topic.try(:publish!)
        end

        @topic = DiscussionTopic.find(@topic.id)
        @topic.just_created = is_new
        @topic.prior_version = prior_version
        @topic.broadcast_notifications

        render :json => discussion_topic_api_json(@topic, @context, @current_user, session)
      else
        errors = @topic.errors.as_json[:errors]
        errors.merge!(@topic.root_topic.errors.as_json[:errors]) if @topic.root_topic
        errors['published'] = errors.delete(:workflow_state) if errors.has_key?(:workflow_state)
        render :json => {errors: errors}, :status => :bad_request
      end
    end
  end

  def process_podcast_parameters(discussion_topic_hash)
    discussion_topic_hash[:podcast_enabled] = true if value_to_boolean(discussion_topic_hash[:podcast_has_student_posts])

    unless user_can_moderate
      discussion_topic_hash.delete :podcast_enabled
      discussion_topic_hash.delete :podcast_has_student_posts
    end
  end

  # Internal: detetermines if the delayed_post_at or lock_at dates were changed
  # and applies changes to the topic if the were.
  #
  # Returns true if dates were changed and the topic was updated, false otherwise.
  def process_future_date_parameters(discussion_topic_hash)
    # Set the delayed_post_at and lock_at if provided. This will be used to determine if the values have changed
    # in order to know if we should rely on this data to update the workflow state
    @topic.delayed_post_at = discussion_topic_hash[:delayed_post_at] if params.has_key? :delayed_post_at
    @topic.lock_at = discussion_topic_hash[:lock_at] if params.has_key? :lock_at

    if @topic.delayed_post_at_changed? || @topic.lock_at_changed?
      @topic.workflow_state = @topic.should_not_post_yet ? 'post_delayed' : 'active'
      if @topic.should_lock_yet
        @topic.lock(without_save: true)
      else
        @topic.unlock(without_save: true)
      end
      true
    else
      false
    end
  end

  def process_lock_parameters(discussion_topic_hash)
    # Handle locking/unlocking (overrides workflow state if provided). It appears that the locked param as a hash
    # is from old code and is not being used. Verification requested.
    if params.has_key?(:locked) && !params[:locked].is_a?(Hash)
      should_lock = value_to_boolean(params[:locked])
      if should_lock != @topic.locked?
        if should_lock
          @topic.lock(without_save: true)
        else
          discussion_topic_hash[:lock_at] = nil
          @topic.unlock(without_save: true)
        end
      end
    end
  end

  def process_published_parameters(discussion_topic_hash)
    if params.has_key?(:published)
      should_publish = value_to_boolean(params[:published])
      if should_publish != @topic.published?
        if should_publish
          @topic.publish
          @topic.root_topic.try(:publish)
        elsif user_can_moderate
          @topic.unpublish
          @topic.root_topic.try(:unpublish)
        else
          @errors[:published] = t(:error_draft_state_unauthorized, "You do not have permission to set this topic to draft state.")
        end
      end
    elsif @topic.new_record? && !@topic.is_announcement &&  user_can_moderate
      @topic.unpublish
    end
  end

  def process_group_parameters(discussion_topic_hash)
    if params[:assignment] && params[:assignment].has_key?(:group_category_id)
      id = params[:assignment].delete(:group_category_id)
      discussion_topic_hash[:group_category_id] ||= id
    end
    return unless discussion_topic_hash.has_key?(:group_category_id)
    return if discussion_topic_hash[:group_category_id].nil? && @topic.group_category_id.nil?
    return if discussion_topic_hash[:group_category_id].to_i == @topic.group_category_id
    if @topic.is_announcement
      @errors[:group] = t(:error_group_announcement, "You cannot use grouped discussion on an announcement.")
      return
    end
    if !@topic.can_group?
      @errors[:group] = t(:error_group_change, "You cannot change grouping on a discussion with replies.")
    end
    if discussion_topic_hash[:group_category_id]
      discussion_topic_hash[:group_category] = @context.group_categories.find(discussion_topic_hash[:group_category_id])
    else
      discussion_topic_hash[:group_category] = nil
    end
  end

  # TODO: upgrade acts_as_list after rails3
  # check_scope will probably handle this
  def process_pin_parameters(discussion_topic_hash)
    return unless params.key?(:pinned)
    pinned = value_to_boolean(params[:pinned])
    return unless pinned != @topic.pinned?
    @topic.pinned = pinned
    @topic.position = nil
    @topic.add_to_list_bottom
  end

  def apply_positioning_parameters
    if params[:position_after] && user_can_moderate
      other_topic = @context.discussion_topics.active.find(params[:position_after])
      @topic.insert_at(other_topic.position)
    end

    if params[:position_at] && user_can_moderate
      @topic.insert_at(params[:position_at].to_i)
    end
  end

  def apply_attachment_parameters
    # handle creating/removing attachment
    if @topic.grants_right?(@current_user, session, :attach)
      attachment = params[:attachment] &&
                   params[:attachment].size > 0 &&
                   params[:attachment]

      return if attachment && attachment.size > 1.kilobytes &&
        quota_exceeded(@context, named_context_url(@context, :context_discussion_topics_url))

      if (params.has_key?(:remove_attachment) || attachment) && @topic.attachment
        @topic.transaction do
          att = @topic.attachment
          @topic.attachment = nil
          @topic.save! if !@topic.new_record?
          att.destroy
        end
      end

      if attachment
        @attachment = @context.attachments.create!(:uploaded_data => attachment)
        @topic.attachment = @attachment
        @topic.save
      end
    end
  end

  def child_topic
    if params[:headless]
      extra_params = {
        :headless => 1,
        :hide_student_names => params[:hide_student_names],
        :student_id => params[:student_id]
      }
    end

    @root_topic = @context.context.discussion_topics.find(params[:root_discussion_topic_id])
    @topic = @root_topic.ensure_child_topic_for(@context)
    redirect_to named_context_url(@context, :context_discussion_topic_url, @topic.id, extra_params)
  end

  def user_can_edit_course_settings?
    @context.is_a?(Course) && @context.grants_right?(@current_user, session, :update)
  end

  def handle_assignment_edit_params(hash)
    hash[:title] = params[:title] if params[:title]
    if params.slice(*[:due_at, :points_possible, :assignment_group_id]).present?
      if hash[:assignment].nil? && @context.respond_to?(:assignments) && @context.assignments.temp_record.grants_right?(@current_user, session, :create)
        hash[:assignment] ||= {}
      end

      if !hash[:assignment].nil?
        if params[:due_at]
          hash[:assignment][:due_at] = params[:due_at].empty? || params[:due_at] == "null"  ? nil : params[:due_at]
        end
        hash[:assignment][:points_possible] = params[:points_possible] if params[:points_possible]
        hash[:assignment][:assignment_group_id] = params[:assignment_group_id] if params[:assignment_group_id]
      end
    end
  end
end
