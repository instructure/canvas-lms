# Copyright (C) 2014-2016 Instructure, Inc.
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

# @API Grading Periods
# @beta
# Manage grading periods
#
# @model GradingPeriod
#    {
#       "id": "GradingPeriod",
#       "required": ["id", "start_date", "end_date"],
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the grading period.",
#           "example": 1023,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title for the grading period.",
#           "example": "First Block",
#           "type": "string"
#         },
#         "start_date": {
#           "description": "The start date of the grading period.",
#           "example": "2014-01-07T15:04:00Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "end_date": {
#           "description": "The end date of the grading period.",
#           "example": "2014-05-07T17:07:00Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "weight": {
#           "description": "The weighted percentage on how much this particular period should count toward the total grade.",
#           "type": "integer",
#           "example": "25"
#         }
#       }
#    }
#
class GradingPeriodsController < ApplicationController
  include ::Filters::GradingPeriods

  before_filter :require_user
  before_filter :get_context
  before_filter :check_feature_flag

  # @API List grading periods
  # @beta
  #
  # Returns the list of grading periods for the current course.
  #
  # @example_response
  #   {
  #     "grading_periods": [GradingPeriod]
  #   }
  #
  def index
    if authorized_action(@context, @current_user, :read)
      # FIXME: This action is no longer used with Accounts.
      #
      # Team question: What should we do if external clients are still
      # potentially going to expect grading periods on accounts by calling
      # to this endpoint?
      if @context.is_a? Account
        grading_periods = []
      else
        grading_periods = GradingPeriod.for(@context).sort_by(&:start_date)
      end
      read_only = grading_periods.present? && grading_periods.first.grading_period_group.account_id.present?
      paginated_grading_periods, meta = paginate_for(grading_periods)
      respond_to do |format|
        format.json do
          render json: serialize_json_api(paginated_grading_periods, meta)
            .merge(index_permissions)
            .merge(grading_periods_read_only: read_only)
        end
      end
    end
  end

  # @API Get a single grading period
  # @beta
  #
  # Returns the grading period with the given id
  #
  # @example_response
  #   {
  #     "grading_periods": [GradingPeriod]
  #   }
  #
  def show
    grading_period = GradingPeriod.context_find(@context, params[:id])
    fail ActionController::RoutingError.new('Not Found') if grading_period.blank?

    if authorized_action(grading_period, @current_user, :read)
      respond_to do |format|
        format.json { render json: serialize_json_api(grading_period) }
      end
    end
  end

  # @API Update a single grading period
  # @beta
  #
  # Update an existing grading period.
  #
  # @argument grading_periods[][start_date] [Required, Date]
  #   The date the grading period starts.
  #
  # @argument grading_periods[][end_date] [Required, Date]
  #
  # @argument grading_periods[][weight] [Number]
  #   The percentage weight of how much the period should count toward the course grade.
  #
  # @example_response
  #   {
  #     "grading_periods": [GradingPeriod]
  #   }
  #
  def update
    grading_period = GradingPeriod.active.find(params[:id])
    grading_period_params = params[:grading_periods].first

    if authorized_action(grading_period, @current_user, :update)
      respond_to do |format|
        if grading_period.update_attributes(grading_period_params)
          format.json { render json: serialize_json_api(grading_period) }
        else
          format.json do
            render json: grading_period.errors, status: :unprocessable_entity
          end
        end
      end
    end
  end

  # @API Delete a grading period
  # @beta
  #
  # <b>204 No Content</b> response code is returned if the deletion was
  # successful.
  def destroy
    grading_period = GradingPeriod.active.find(params[:id])
    unless can_destroy_in_context?(grading_period)
      return render_unauthorized_action
    end

    if authorized_action(grading_period, @current_user, :delete)
      grading_period.destroy
      respond_to do |format|
        format.json { head :no_content }
      end
    end
  end

  def batch_update
    if authorized_action(@context, @current_user, :manage_grades)
      case @context
      when Account
        account_batch_update
      when Course
        course_batch_update
      end
    end
  end

  private

  def account_batch_update
    periods = find_or_build_periods_for_account(params[:grading_periods])
    unless batch_update_rights?(periods)
      return render_unauthorized_action
    end

    grading_period_group.grading_periods.transaction do
      errors = no_overlapping_for_new_periods_validation_errors(periods)
        .concat(validation_errors(periods))

      respond_to do |format|
        if errors.present?
          format.json do
            render json: {errors: errors}, status: :unprocessable_entity
          end
        else
          periods.each(&:save!)
          format.json do
            render json: unpaginated_json_api(periods)
          end
        end
      end
    end
  end

  def course_batch_update
    periods = find_or_build_periods_for_course(params[:grading_periods])
    unless batch_update_rights?(periods)
      return render_unauthorized_action
    end
    unless can_batch_update_in_context?(periods)
      return render_unauthorized_action
    end

    @context.grading_periods.transaction do
      errors = no_overlapping_for_new_periods_validation_errors(periods)
        .concat(validation_errors(periods))

      respond_to do |format|
        if errors.present?
          format.json do
            render json: {errors: errors}, status: :unprocessable_entity
          end
        else
          periods.each(&:save!)
          paginated_periods, meta = paginate_for(periods)
          format.json do
            render json: serialize_json_api(paginated_periods, meta)
          end
        end
      end
    end
  end

  def get_context
    return super unless params[:set_id].present?

    term_subquery = EnrollmentTerm.select(:root_account_id).where(grading_period_group_id: params[:set_id])
    @context = Account.active.where(id: term_subquery).take
  end

  # model level validations
  def validation_errors(periods)
    periods.select(&:invalid?).map(&:errors)
  end

  # validate no overlapping check on newly built collection
  def no_overlapping_for_new_periods_validation_errors(periods)
    sorted_periods = periods.sort_by(&:start_date)
    sorted_periods.each_cons(2) do |first_period, second_period|
      # skip not_overlapping model validation in model level
      first_period.skip_not_overlapping_validator
      second_period.skip_not_overlapping_validator
      if second_period.start_date < first_period.end_date
        second_period.errors.add(:start_date, 'Start Date overlaps with another period')
      end
    end
    sorted_periods.select { |period| period.errors.present? }.map(&:errors)
  end

  def find_or_build_periods_for_account(periods_params)
    periods_params.map do |period_params|
      period = grading_period_group.grading_periods.find(period_params[:id]) if period_params[:id].present?
      period ||= grading_period_group.grading_periods.build
      period.assign_attributes(period_params.except(:id))
      period
    end
  end

  def find_or_build_periods_for_course(periods_params)
    periods_params.map do |period_params|
      period = GradingPeriod.context_find(@context, period_params[:id])
      period ||= context_grading_period_group.grading_periods.build
      period.assign_attributes(period_params.except(:id))
      period
    end
  end

  def batch_update_rights?(periods)
    new_periods, existing_periods = periods.partition(&:new_record?)
    current_user_can_create?(new_periods) &&
      current_user_can_update?(existing_periods)
  end

  def current_user_can_create?(periods)
    periods.all? { |p| p.grants_right?(@current_user, :create) }
  end

  def current_user_can_update?(periods)
    periods.all? { |p| p.grants_right?(@current_user, :update) }
  end

  def can_batch_update_in_context?(periods)
    periods.empty? || periods.first.grading_period_group.account_id.blank?
  end

  def can_destroy_in_context?(period)
    @context.is_a?(Account) || period.grading_period_group.account_id.blank?
  end

  def context_grading_period_group
    @context.grading_period_groups.active.first_or_create
  end

  def paginate_for(grading_periods)
    paginated_grading_periods, meta = Api.jsonapi_paginate(grading_periods, self, named_context_url(@context, :api_v1_context_grading_periods_url))
    meta[:primaryCollection] = 'grading_periods'
    [paginated_grading_periods, meta]
  end

  def unpaginated_json_api(grading_periods)
    grading_periods = Array.wrap(grading_periods)

    Canvas::APIArraySerializer.new(grading_periods, {
      each_serializer: GradingPeriodSerializer,
      controller: self,
      root: :grading_periods,
      scope: @current_user,
      include_root: false
    }).as_json
  end

  def serialize_json_api(grading_periods, meta = {})
    grading_periods = Array.wrap(grading_periods)

    Canvas::APIArraySerializer.new(grading_periods, {
      each_serializer: GradingPeriodSerializer,
      controller: self,
      root: :grading_periods,
      meta: meta,
      scope: @current_user,
      include_root: false
    }).as_json
  end

  def index_permissions
    can_create_grading_periods = @context.is_a?(Account) &&
      @context.root_account? && @context.grants_right?(@current_user, :manage)
    can_toggle_grading_periods = @domain_root_account.grants_right?(@current_user, :manage) ||
      @context.feature_allowed?(:multiple_grading_periods, exclude_enabled: true)
    {
      can_create_grading_periods: can_create_grading_periods,
      can_toggle_grading_periods: can_toggle_grading_periods
    }.as_json
  end

  def grading_period_group
    @grading_period_group ||= GradingPeriodGroup.active.find(params[:set_id]) if params[:set_id].present?
  end
end
