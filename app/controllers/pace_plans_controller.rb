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

class PacePlansController < ApplicationController
  before_action :load_context
  before_action :load_course
  before_action :require_feature_flag
  before_action :authorize_action
  before_action :load_pace_plan, only: [:api_show, :update, :publish]

  include Api::V1::Course
  include Api::V1::Progress
  include K5Mode

  def index
    @pace_plan = @context.pace_plans.primary.first

    if @pace_plan.nil?
      @pace_plan = @context.pace_plans.new
      @context.context_module_tags.not_deleted.each do |module_item|
        next unless module_item.assignment

        @pace_plan.pace_plan_module_items.new module_item: module_item, duration: 0
      end
    end

    progress = Progress.find_by(context: @pace_plan, workflow_state: ['queued', 'running'], tag: 'pace_plan_publish')
    progress_json = progress_json(progress, @current_user, session) if progress

    js_env({
             BLACKOUT_DATES: [],
             COURSE: course_json(@context, @current_user, session, [], nil),
             ENROLLMENTS: enrollments_json(@context),
             SECTIONS: sections_json(@context),
             PACE_PLAN: PacePlanPresenter.new(@pace_plan).as_json,
             PACE_PLAN_PROGRESS: progress_json
           })
    js_bundle :pace_plans
    css_bundle :pace_plans
  end

  def api_show
    progress = Progress.find_by(context: @pace_plan, workflow_state: ['queued', 'running'], tag: 'pace_plan_publish')
    progress_json = progress_json(progress, @current_user, session) if progress
    render json: {
      pace_plan: PacePlanPresenter.new(@pace_plan).as_json,
      progress: progress_json
    }
  end

  def new
    @pace_plan = case @context
                 when Course
                   @context.pace_plans.primary.not_deleted.take
                 when CourseSection
                   @course.pace_plans.for_section(@context).not_deleted.take
                 when Enrollment
                   @course.pace_plans.for_user(@context.user).not_deleted.take
                 end
    if @pace_plan.nil?
      params = case @context
               when Course
                 { course_section_id: nil, user_id: nil }
               when CourseSection
                 { course_section_id: @context }
               when Enrollment
                 { user_id: @context.user }
               end
      # Duplicate a published plan if one exists for the plan or for the course
      published_pace_plan = @course.pace_plans.published.where(params).take || @course.pace_plans.primary.published.take
      if published_pace_plan
        @pace_plan = published_pace_plan.duplicate(params)
      else
        @pace_plan = @course.pace_plans.new(params)
        @course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
          @pace_plan.pace_plan_module_items.new module_item: module_item, duration: 0
        end
      end
    end
    render json: { pace_plan: PacePlanPresenter.new(@pace_plan).as_json }
  end

  def publish
    publish_pace_plan
    render json: progress_json(@progress, @current_user, session)
  end

  def create
    @pace_plan = @context.pace_plans.new(create_params)

    if @pace_plan.save
      publish_pace_plan
      render json: {
        pace_plan: PacePlanPresenter.new(@pace_plan).as_json,
        progress: progress_json(@progress, @current_user, session)
      }
    else
      render json: { success: false, errors: @pace_plan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pace_plan.update(update_params)
      # Force the updated_at to be updated, because if the update just changed the items the pace plan's
      # updated_at doesn't get modified
      @pace_plan.touch

      publish_pace_plan
      render json: {
        pace_plan: PacePlanPresenter.new(@pace_plan).as_json,
        progress: progress_json(@progress, @current_user, session)
      }
    else
      render json: { success: false, errors: @pace_plan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def enrollments_json(course)
    json = course.all_real_student_enrollments.map do |enrollment|
      {
        id: enrollment.id,
        user_id: enrollment.user_id,
        course_id: enrollment.course_id,
        section_id: enrollment.course_section_id,
        full_name: enrollment.user.name,
        sortable_name: enrollment.user.sortable_name,
        start_at: enrollment.start_at
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

  def authorize_action
    authorized_action(@course, @current_user, :manage_content)
  end

  def require_feature_flag
    not_found unless @course.account.feature_enabled?(:pace_plans) && @course.enable_pace_plans
  end

  def load_pace_plan
    @pace_plan = @context.pace_plans.find(params[:id])
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

  def update_params
    params.require(:pace_plan).permit(
      :course_section_id,
      :user_id,
      :end_date,
      :exclude_weekends,
      :hard_end_dates,
      :workflow_state,
      pace_plan_module_items_attributes: [:id, :duration, :module_item_id, :root_account_id]
    )
  end

  def create_params
    params.require(:pace_plan).permit(
      :course_id,
      :course_section_id,
      :user_id,
      :end_date,
      :exclude_weekends,
      :hard_end_dates,
      :workflow_state,
      pace_plan_module_items_attributes: [:duration, :module_item_id, :root_account_id]
    )
  end

  def publish_pace_plan
    @progress = Progress.create!(context: @pace_plan, tag: 'pace_plan_publish')
    @progress.process_job(@pace_plan, :publish, {})
  end
end
