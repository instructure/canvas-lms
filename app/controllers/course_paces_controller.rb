# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API Course Pace
# API for accessing and building Course Paces.
#
# @model CoursePace
#     {
#       "id": "CoursePace",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the course pace",
#           "example": 5,
#           "type": "integer"
#         },
#         "course_id": {
#           "description": "the ID of the course",
#           "example": 5,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "the ID of the user for this course pace",
#           "example": 10,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "the state of the course pace",
#           "example": "active",
#           "type": "string"
#         },
#         "exclude_weekends": {
#           "description": "boolean value depending on exclude weekends setting",
#           "example": true,
#           "type": "boolean"
#         },
#         "hard_end_dates": {
#           "description": "set if the end date is set from course",
#           "example": true,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "date when course pace is created",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "end_date": {
#           "description": "course end date",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "date when course pace is updated",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "published_at": {
#           "description": "date when course pace is published",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "root_account_id": {
#           "description": "the root account ID for this course pace",
#           "example": 10,
#           "type": "integer"
#         },
#         "start_date": {
#           "description": "course start date",
#           "example": "2013-01-23T23:59:00-07:00",
#           "type": "datetime"
#         },
#         "modules": {
#           "description": "list of modules and items for this course pace",
#           "type": "array",
#           "modules": { "$ref": "Module" }
#         },
#         "progress": {
#           "description": "progress of pace publishing",
#           "$ref": "Progress"
#         }
#       }
#     }
# @model Module
#     {
#       "id": "Module",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the module",
#           "example": 5,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the module",
#           "example": "Module 1",
#           "type": "string"
#         },
#         "position": {
#           "description": "the position of the module",
#           "example": 5,
#           "type": "integer"
#         },
#         "items" : {
#           "description": "list of module items",
#           "type": "array",
#           "items": { "$ref": "ModuleItem" }
#         },
#         "context_id": {
#           "description": "the ID of the context for this course pace",
#           "example": 10,
#           "type": "integer"
#         },
#         "context_type": {
#           "description": "The given context for the course pace",
#           "enum":
#           [
#             "Course",
#             "Section",
#             "User"
#           ],
#           "example": "Course",
#           "type": "string"
#         }
#       }
#     }
# @model ModuleItem
#     {
#       "id": "ModuleItem",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "duration": {
#           "description": "the duration of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "course_pace_id": {
#           "description": "the course pace id of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "root_account_id": {
#           "description": "the root account id of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "module_item_id": {
#           "description": "the module item id of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "assignment_title": {
#           "description": "The title of the item assignment",
#           "example": "Assignment 9",
#           "type": "string"
#         },
#         "points_possible": {
#           "description": "The points of the item",
#           "example": 10.0,
#           "type": "number"
#         },
#         "assignment_link": {
#           "description": "The link of the item assignment",
#           "example": "/courses/105/modules/items/264",
#           "type": "string"
#         },
#         "position": {
#           "description": "the current position of the module item",
#           "example": 5,
#           "type": "integer"
#         },
#         "module_item_type": {
#           "description": "The module item type of the item assignment",
#           "example": "Assignment",
#           "type": "string"
#         },
#         "published": {
#           "description": "published boolean value for course pace",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model Progress
#     {
#       "id": "Progress",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the Progress object",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_id": {
#           "description": "the context owning the job.",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Account",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "the id of the user who started the job",
#           "example": 123,
#           "type": "integer"
#         },
#         "tag": {
#           "description": "the type of operation",
#           "example": "course_batch_update",
#           "type": "string"
#         },
#         "completion": {
#           "description": "percent completed",
#           "example": 100,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "the state of the job one of 'queued', 'running', 'completed', 'failed'",
#           "example": "completed",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "queued",
#               "running",
#               "completed",
#               "failed"
#             ]
#           }
#         },
#         "created_at": {
#           "description": "the time the job was created",
#           "example": "2013-01-15T15:00:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "the time the job was last updated",
#           "example": "2013-01-15T15:04:00Z",
#           "type": "datetime"
#         },
#         "message": {
#           "description": "optional details about the job",
#           "example": "17 courses processed",
#           "type": "string"
#         },
#         "results": {
#           "description": "optional results of the job. omitted when job is still pending",
#           "example": { "id": "123" },
#           "type": "object"
#         },
#         "url": {
#           "description": "url where a progress update can be retrieved",
#           "example": "https://canvas.example.edu/api/v1/progress/1",
#           "type": "string"
#         }
#       }
#     }

class CoursePacesController < ApplicationController
  before_action :load_context
  before_action :load_course
  before_action :load_blackout_dates, only: %i[index]
  before_action :load_calendar_event_blackout_dates, only: %i[index]
  before_action :require_feature_flag
  before_action :authorize_action
  before_action :load_course_pace, only: %i[api_show publish update destroy]

  include Api::V1::Course
  include Api::V1::Progress
  include K5Mode
  include GranularPermissionEnforcement

  COURSE_PACES_PUBLISHING_LIMIT = 50

  def index
    add_crumb(t("Course Pacing"))
    @course_pace = @context.course_paces.primary.first

    if @course_pace.nil?
      @course_pace = @context.course_paces.new
      @context.context_module_tags.not_deleted.each do |module_item|
        next unless module_item.assignment

        @course_pace.course_pace_module_items.new module_item:, duration: 0
      end
    end

    load_and_run_progress

    status = setup_master_course_restrictions([@course_pace], @context)

    if status
      master_course_data = @course_pace.master_course_api_restriction_data(status)
      master_course_data[:default_restrictions] = MasterCourses::MasterTemplate.full_template_for(@context).default_restrictions_for(@course_pace) if status == :master
    end

    js_env({
             BLACKOUT_DATES: @blackout_dates.as_json(include_root: false),
             CALENDAR_EVENT_BLACKOUT_DATES: @calendar_event_blackout_dates.as_json(include_root: false),
             COURSE: course_json(@context, @current_user, session, [], nil),
             ENROLLMENTS: enrollments_json(@context),
             SECTIONS: sections_json(@context),
             COURSE_ID: @context.id,
             COURSE_PACE_ID: @course_pace.id,
             COURSE_PACE: CoursePacePresenter.new(@course_pace).as_json,
             COURSE_PACE_PROGRESS: @progress_json,
             VALID_DATE_RANGE: CourseDateRange.new(@context),
             MASTER_COURSE_DATA: master_course_data,
             IS_MASQUERADING: @current_user && @real_current_user && @real_current_user != @current_user,
             PACES_PUBLISHING: paces_publishing
           })

    js_bundle :course_paces
    css_bundle :course_paces
  end

  def paces_publishing
    jobs_progress = Progress
                    .where(tag: "course_pace_publish", context: @context.course_paces)
                    .is_pending
                    .select('DISTINCT ON ("context_id") *')
                    .map do |progress|
      pace = progress.context
      if pace&.workflow_state == "active"
        pace_context = context_for(pace)
        # If the pace context is nil, then the context was deleted and we should destroy the progress
        if pace_context.nil?
          progress.destroy
          next
        end

        {
          pace_context: CoursePacing::PaceContextsPresenter.as_json(pace_context),
          progress_context_id: progress.context_id
        }
      else
        nil
      end
    end
    jobs_progress.compact
  end

  def context_for(pace)
    return pace.course_section if pace.course_section_id
    # search the pace's shard for the student enrollment since the enrollment associated with the pace's course
    # will always be on the pace's shard (not necessarily the user's shard though)
    return pace.user.student_enrollments.shard(pace.shard).where(course: @course).active.take if pace.user_id

    pace.course
  end

  # @API Show a Course pace
  # Returns a course pace for the course and pace id provided
  #
  # @argument course_id [Required, Integer]
  #   The id of the course
  #
  # @argument course_pace_id [Required, Integer]
  #   The id of the course_pace
  #
  # @returns CoursePace
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/course_pacing/1 \
  #     -H 'Authorization: Bearer <token>'

  def api_show
    load_and_run_progress
    render json: {
      course_pace: CoursePacePresenter.new(@course_pace).as_json,
      progress: @progress_json
    }
  end

  def new
    @course_pace = case @context
                   when Course
                     @context.course_paces.primary.published.take ||
                     @context.course_paces.primary.not_deleted.take
                   when CourseSection
                     @course.course_paces.for_section(@context).published.take ||
                     @course.course_paces.for_section(@context).not_deleted.take
                   when Enrollment
                     @course.course_paces.for_user(@context.user).published.take ||
                     @course.course_paces.for_user(@context.user).not_deleted.take
                   end
    load_and_run_progress
    if @course_pace.nil?
      pace_params = case @context
                    when Course
                      { course_section_id: nil, user_id: nil }
                    when CourseSection
                      { course_section_id: @context }
                    when Enrollment
                      { user_id: @context.user }
                    end
      # Duplicate a published plan if one exists for the plan or for the course
      published_course_pace = @course.course_paces.published.where(pace_params).take
      published_course_pace ||= @course.course_paces.published.where(course_section_id: @context.course_section_id).take if @context.is_a?(Enrollment)
      published_course_pace ||= @course.course_paces.primary.published.take
      if published_course_pace
        @course_pace = published_course_pace.duplicate(pace_params)
      else
        @course_pace = @course.course_paces.new(pace_params)
        @course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
          next unless module_item.assignment

          @course_pace.course_pace_module_items.new module_item:, duration: 0
        end
      end
    end
    render json: {
      course_pace: CoursePacePresenter.new(@course_pace).as_json,
      progress: @progress_json
    }
  end

  def publish
    publish_course_pace
    log_course_paces_publishing
    render json: progress_json(@progress, @current_user, session)
  end

  # @API Create a Course pace
  #
  # @argument course_id [Required, Integer]
  #   The id of the course
  #
  # @argument end_date [Datetime]
  #   End date of the course pace
  #
  # @argument end_date_context [String]
  #   End date context (course, section, hupothetical)
  #
  # @argument start_date [Datetime]
  #   Start date of the course pace
  #
  # @argument start_date_context [String]
  #   Start date context (course, section, hupothetical)
  #
  # @argument exclude_weekends [Boolean]
  #   Course pace dates excludes weekends if true
  #
  # @argument hard_end_dates [Boolean]
  #   Course pace uess hard end dates if true
  #
  # @argument workflow_state [String]
  #   The state of the course pace
  #
  # @argument course_pace_module_item_attributes[] [String]
  #   Module Items attributes
  #
  # @argument context_id [Integer]
  #   Pace Context ID
  #
  # @argument context_type [String]
  #   Pace Context Type (Course, Section, User)
  #
  # @returns CoursePace
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/course_pacing \
  #     -X POST \
  #     -H 'Authorization: Bearer <token>'

  def create
    @course_pace = @context.course_paces.new(create_params)

    if @course_pace.save
      publish_course_pace
      render json: {
        course_pace: CoursePacePresenter.new(@course_pace).as_json,
        progress: progress_json(@progress, @current_user, session)
      }
    else
      render json: { success: false, errors: @course_pace.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @API Update a Course pace
  # Returns the updated course pace
  #
  # @argument course_id [Required, Integer]
  #   The id of the course
  #
  # @argument course_pace_id [Required, Integer]
  #   The id of the course pace
  #
  # @argument end_date [Datetime]
  #   End date of the course pace
  #
  # @argument exclude_weekends [Boolean]
  #   Course pace dates excludes weekends if true
  #
  # @argument hard_end_dates [Boolean]
  #   Course pace uess hard end dates if true
  #
  # @argument workflow_state [String]
  #   The state of the course pace
  #
  # @argument course_pace_module_item_attributes[] [String]
  #   Module Items attributes
  #
  # @returns CoursePace
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/course_pacing/1 \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>'

  def update
    if @course_pace.update(update_params)
      # Force the updated_at to be updated, because if the update just changed the items the course pace's
      # updated_at doesn't get modified
      @course_pace.touch

      publish_course_pace
      render json: {
        course_pace: CoursePacePresenter.new(@course_pace).as_json,
        progress: progress_json(@progress, @current_user, session)
      }
    else
      render json: { success: false, errors: @course_pace.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def compress_dates
    @course_pace = @course.course_paces.new(create_params)
    if params[:blackout_dates]
      # keep the param.permit values in sync with BlackoutDatesController#blackout_date_params
      # Note: we can replace blackout_dates on the course because the course never gets saved
      # while doing the compressing
      blackout_dates_params = params[:blackout_dates].map { |param| param.permit(:start_date, :end_date, :event_title) }
      @course.blackout_dates.build(blackout_dates_params)
    end

    unless @course_pace.valid?
      return render json: { success: false, errors: @course_pace.errors.full_messages }, status: :unprocessable_entity
    end

    @course_pace.course = @course
    start_date = params.dig(:course_pace, :start_date).present? ? Date.parse(params.dig(:course_pace, :start_date)) : @course_pace.start_date

    if @course_pace.end_date && start_date && @course_pace.end_date < start_date
      return render json: { success: false, errors: "End date cannot be before start date" }, status: :unprocessable_entity
    end

    compressed_module_items = @course_pace.compress_dates(save: false, start_date:)
                                          .sort_by { |ppmi| ppmi.module_item.position }
                                          .group_by { |ppmi| ppmi.module_item.context_module }
                                          .sort_by { |context_module, _items| context_module.position }
                                          .to_h.values.flatten
    compressed_dates = CoursePaceDueDatesCalculator.new(@course_pace).get_due_dates(compressed_module_items, start_date:)

    render json: compressed_dates.to_json
  end

  # @API Delete a Course pace
  # Returns the updated course pace
  #
  # @argument course_id [Required, Integer]
  #   The id of the course
  #
  # @argument course_pace_id [Required, Integer]
  #   The id of the course_pace
  #
  # @returns CoursePace
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/1/course_pacing/1 \
  #     -X DELETE \
  #     -H 'Authorization: Bearer <token>'

  def destroy
    return not_found unless Account.site_admin.feature_enabled?(:course_paces_redesign)

    if @course_pace.primary? && @course_pace.published?
      return render json: { success: false, errors: t("You cannot delete the default course pace.") }, status: :unprocessable_entity
    end

    was_published = @course_pace.published?
    @course_pace.destroy
    @course_pace.republish_paces_for_affected_enrollments if was_published
    render json: { course_pace: CoursePacePresenter.new(@course_pace).as_json }
  end

  private

  def authorize_action
    enforce_granular_permissions(
      @course,
      overrides: [:manage_content],
      actions: {
        index: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        api_show: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        new: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        publish: [:manage_course_content_edit],
        create: [:manage_course_content_add],
        update: [:manage_course_content_edit],
        compress_dates: [:manage_course_content_edit],
        master_course_info: [:manage_course_content_edit],
        destroy: [:manage_course_content_delete]
      }
    )
  end

  def latest_progress
    progress = Progress.order(created_at: :desc).find_by(context: @course_pace, tag: "course_pace_publish")
    (progress&.workflow_state == "completed") ? nil : progress
  end

  def load_and_run_progress
    @progress = latest_progress
    if @progress
      if @progress.queued?
        case [@progress.delayed_job_id.present?, @progress.delayed_job.present?]
        in [false, _]
          @course_pace.run_publish_progress(@progress)
        in [true, false]
          @progress.fail!
          @progress = publish_course_pace
        in [true, true]
          @progress.delayed_job.update(run_at: Time.now)
        end
      end
      @progress_json = progress_json(@progress, @current_user, session)
    end
  end

  def enrollments_json(course)
    # Only the most recent enrollment of each student is considered
    json = course.all_real_student_enrollments.order(:user_id, created_at: :desc).select("DISTINCT ON(enrollments.user_id) enrollments.*").map do |enrollment|
      {
        id: enrollment.id,
        user_id: enrollment.user_id,
        course_id: enrollment.course_id,
        section_id: enrollment.course_section_id,
        full_name: enrollment.user.name,
        sortable_name: enrollment.user.sortable_name,
        start_at: enrollment.start_at,
        avatar_url: enrollment.user.avatar_image_url
      }
    end
    json.index_by { |h| h[:id] }
  end

  def sections_json(course)
    json = course.active_course_sections.map do |section|
      {
        id: section.id,
        course_id: section.course_id,
        name: section.name,
        start_at: section.start_at,
        end_at: section.end_at
      }
    end
    json.index_by { |h| h[:id] }
  end

  def require_feature_flag
    not_found unless @course.account.feature_enabled?(:course_paces) && @course.enable_course_paces
  end

  def load_course_pace
    @course_pace = @context.course_paces.find(params[:id])
  end

  def load_context
    if params[:enrollment_id]
      @context = Enrollment.find(params[:enrollment_id])
    elsif params[:course_section_id]
      @context = CourseSection.find(params[:course_section_id])
    else
      require_context
    end
  end

  def load_course
    @course = @context.respond_to?(:course) ? @context.course : @context
  end

  def load_blackout_dates
    @blackout_dates = @context.respond_to?(:blackout_dates) ? @context.blackout_dates : []
  end

  def load_calendar_event_blackout_dates
    account_codes = Account.multi_account_chain_ids([@context.account.id]).map { |id| "account_#{id}" }
    context_codes = account_codes.append("course_#{@context.id}")
    @calendar_event_blackout_dates = CalendarEvent.with_blackout_date.active.for_context_codes(context_codes)
  end

  def update_params
    @permitted_params = params.require(:course_pace).permit(
      :context_id,
      :context_type,
      :course_section_id,
      :user_id,
      :end_date,
      :exclude_weekends,
      :hard_end_dates,
      :workflow_state,
      course_pace_module_items_attributes: %i[id duration module_item_id root_account_id]
    )
    set_context_ids
    @permitted_params
  end

  def create_params
    @permitted_params = params.require(:course_pace).permit(
      :context_id,
      :context_type,
      :course_id,
      :course_section_id,
      :user_id,
      :end_date,
      :exclude_weekends,
      :hard_end_dates,
      :workflow_state,
      course_pace_module_items_attributes: %i[duration module_item_id root_account_id]
    )
    set_context_ids
    @permitted_params
  end

  # Converts the context_id and context_type params to the database column required for that context
  def set_context_ids
    return unless @permitted_params[:context_id].present? && @permitted_params[:context_type].present?

    if @permitted_params[:context_type] == "Section"
      @permitted_params[:course_section_id] = @permitted_params[:context_id]
    elsif @permitted_params[:context_type] == "Enrollment"
      @permitted_params[:user_id] = @permitted_params[:context_id]
    end
    @permitted_params = @permitted_params.except(:context_id, :context_type)
  end

  def publish_course_pace
    @progress = @course_pace.create_publish_progress(run_at: Time.now)
  end

  def log_course_paces_publishing
    count = paces_publishing.length
    InstStatsd::Statsd.count("course_pacing.publishing.count_exceeding_limit", count) if count > COURSE_PACES_PUBLISHING_LIMIT
  end
end
