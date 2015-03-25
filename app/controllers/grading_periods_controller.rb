# Copyright (C) 2014 Instructure, Inc.
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
  include Filters::GradingPeriods

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
      # inheritance check instead of #get_context?
      @grading_periods = @context.grading_periods.active.order('start_date')
      json, meta = paginate_for(@grading_periods)
      render json: serialize_jsonapi(json, meta)
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
    @grading_period = @context.grading_periods.active.find(params[:id])
    if @grading_period && authorized_action(@grading_period, @current_user, :read)
      render json: serialize_jsonapi(@grading_period)
    end
  end

  # @API Create a single grading period
  # @beta
  #
  # Create a new grading period for the current user
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
  def create
    grading_period_params = params[:grading_periods][0]
    # grabbing the first grading_period_group for now, until
    # we decide to allow for multiple grading_period_groups later
    grading_period_group = @context.grading_period_groups.first_or_create
    # another inheritance check here?
    @grading_period = grading_period_group.grading_periods.new(grading_period_params)
    if @grading_period && authorized_action(@grading_period, @current_user, :manage)
      if @grading_period.save
        render json: serialize_jsonapi(@grading_period)
      else
        render json: @grading_period.errors, status: :bad_request
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
    @grading_period = GradingPeriod.active.find(params[:id])
    grading_period_params = params[:grading_periods][0]

    if @grading_period && authorized_action(@grading_period, @current_user, :manage)
      if @grading_period.update_attributes(grading_period_params)
        render json: serialize_jsonapi(@grading_period)
      else
        render json: @grading_period.errors, status: :bad_request
      end
    end
  end

  # @API Delete a grading period
  # @beta
  #
  # <b>204 No Content</b> response code is returned if the deletion was successful.
  def destroy
    @grading_period = GradingPeriod.active.find(params[:id])

    if @grading_period && authorized_action(@grading_period, @current_user, :manage)
      @grading_period.destroy
      head :no_content
    end
  end

  protected
  def paginate_for(grading_periods)
    meta = {}
    grading_periods, meta = Api.jsonapi_paginate(grading_periods, self, named_context_url(@context, :api_v1_context_grading_periods_url))
    meta[:primaryCollection] = 'grading_periods'
    return grading_periods, meta
  end

  def serialize_jsonapi(grading_periods, meta = {})
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
end
