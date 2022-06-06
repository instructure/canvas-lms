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

class CoursePacesController < ApplicationController
  before_action :load_context
  before_action :load_course
  before_action :load_blackout_dates, only: %i[index]
  before_action :require_feature_flag
  before_action :authorize_action
  before_action :load_course_pace, only: %i[api_show publish update]

  include Api::V1::Course
  include Api::V1::Progress
  include K5Mode
  include GranularPermissionEnforcement

  def index
    add_crumb(t("Course Pacing"))
    @course_pace = @context.course_paces.primary.first

    if @course_pace.nil?
      @course_pace = @context.course_paces.new
      @context.context_module_tags.not_deleted.each do |module_item|
        next unless module_item.assignment

        @course_pace.course_pace_module_items.new module_item: module_item, duration: 0
      end
    end

    progress = latest_progress
    if progress
      # start delayed job if it's not already started
      if progress.queued?
        if progress.delayed_job.present?
          progress.delayed_job.update(run_at: Time.now)
        else
          progress = publish_course_pace
        end
      end
      progress_json = progress_json(progress, @current_user, session)
    end

    status = setup_master_course_restrictions([@course_pace], @context)

    if status
      master_course_data = @course_pace.master_course_api_restriction_data(status)
      master_course_data[:default_restrictions] = MasterCourses::MasterTemplate.full_template_for(@context).default_restrictions_for(@course_pace) if status == :master
    end

    js_env({
             BLACKOUT_DATES: @blackout_dates.as_json(include_root: false),
             COURSE: course_json(@context, @current_user, session, [], nil),
             ENROLLMENTS: enrollments_json(@context),
             SECTIONS: sections_json(@context),
             COURSE_ID: @context.id,
             COURSE_PACE_ID: @course_pace.id,
             COURSE_PACE: CoursePacePresenter.new(@course_pace).as_json,
             COURSE_PACE_PROGRESS: progress_json,
             VALID_DATE_RANGE: CourseDateRange.new(@context),
             MASTER_COURSE_DATA: master_course_data
           })

    js_bundle :course_paces
    css_bundle :course_paces
  end

  def api_show
    progress = latest_progress
    progress_json = progress_json(progress, @current_user, session) if progress
    render json: {
      course_pace: CoursePacePresenter.new(@course_pace).as_json,
      progress: progress_json
    }
  end

  def new
    @course_pace = case @context
                   when Course
                     @context.course_paces.primary.not_deleted.take
                   when CourseSection
                     @course.course_paces.for_section(@context).not_deleted.take
                   when Enrollment
                     @course.course_paces.for_user(@context.user).not_deleted.take
                   end
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
          @course_pace.course_pace_module_items.new module_item: module_item, duration: 0
        end
      end
    end
    render json: { course_pace: CoursePacePresenter.new(@course_pace).as_json }
  end

  def publish
    publish_course_pace
    render json: progress_json(@progress, @current_user, session)
  end

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

    compressed_module_items = @course_pace.compress_dates(save: false, start_date: start_date)
                                          .sort_by { |ppmi| ppmi.module_item.position }
                                          .group_by { |ppmi| ppmi.module_item.context_module }
                                          .sort_by { |context_module, _items| context_module.position }
                                          .to_h.values.flatten
    compressed_dates = CoursePaceDueDatesCalculator.new(@course_pace).get_due_dates(compressed_module_items, start_date: start_date)

    render json: compressed_dates.to_json
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
      }
    )
  end

  def latest_progress
    progress = Progress.order(created_at: :desc).find_by(context: @course_pace, tag: "course_pace_publish")
    progress&.workflow_state == "completed" ? nil : progress
  end

  def enrollments_json(course)
    json = course.all_real_student_enrollments.map do |enrollment|
      {
        id: enrollment.id,
        user_id: enrollment.user_id,
        course_id: enrollment.course_id,
        section_id: enrollment.course_section_id,
        full_name: enrollment.user.name,
        sortable_name: enrollment.user.sortable_name,
        start_at: enrollment.start_at,
        avatar_url: User.find_by(id: enrollment.user_id).avatar_image_url
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
    elsif @permitted_params[:context_type] == "User"
      @permitted_params[:user_id] = @permitted_params[:context_id]
    end
    @permitted_params = @permitted_params.except(:context_id, :context_type)
  end

  def publish_course_pace
    @progress = @course_pace.create_publish_progress(run_at: Time.now)
  end
end
