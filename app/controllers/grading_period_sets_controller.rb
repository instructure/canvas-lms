# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# @API Grading Period Sets
# Manage grading period sets
#
# @model GradingPeriodSets
#    {
#       "id": "GradingPeriodGroup",
#       "required": ["title"],
#       "properties": {
#         "title": {
#           "description": "The title of the grading period set.",
#           "example": "Hello World",
#           "type": "string"
#         },
#         "weighted": {
#           "description": "If true, the grading periods in the set are weighted.",
#           "example": true,
#           "type": "boolean"
#         },
#         "display_totals_for_all_grading_periods": {
#           "description": "If true, the totals for all grading periods in the set are displayed.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#    }
#
class GradingPeriodSetsController < ApplicationController
  before_action :require_user
  before_action :get_context
  before_action :check_manage_rights, except: [:index]
  before_action :check_read_rights, except: %i[update create destroy]

  # @API List grading period sets
  #
  # Returns the paginated list of grading period sets
  #
  # @example_response
  #   {
  #     "grading_period_set": [GradingPeriodGroup]
  #   }
  #
  def index
    paginated_sets = Api.paginate(
      GradingPeriodGroup.for(@context).order(:id),
      self,
      api_v1_account_grading_period_sets_url
    )
    meta = Api.jsonapi_meta(paginated_sets, self, api_v1_account_grading_period_sets_url)

    respond_to do |format|
      format.json { render json: serialize_json_api(paginated_sets, meta) }
    end
  end

  # @API Create a grading period set
  #
  # Create and return a new grading period set
  #
  # @argument enrollment_term_ids[] [Array]
  #   A list of associated term ids for the grading period set
  #
  # @argument grading_period_set[][title] [Required, String]
  #   The title of the grading period set
  #
  # @argument grading_period_set[][weighted] [Boolean]
  #   A boolean to determine whether the grading periods in the set are weighted
  #
  # @argument grading_period_set[][display_totals_for_all_grading_periods] [Boolean]
  #   A boolean to determine whether the totals for all grading periods in the set are displayed
  #
  # @example_response
  #   {
  #     "grading_period_set": [GradingPeriodGroup]
  #   }
  #
  def create
    grading_period_sets = GradingPeriodGroup.for(@context)
    grading_period_set = grading_period_sets.build(set_params)
    grading_period_set.enrollment_terms = enrollment_terms

    respond_to do |format|
      if grading_period_set.save
        serialized_set = GradingPeriodSetSerializer.new(
          grading_period_set,
          controller: self,
          scope: @current_user,
          root: true
        )

        format.json { render json: serialized_set, status: :created }
      else
        format.json { render json: grading_period_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # @API Update a grading period set
  #
  # Update an existing grading period set
  #
  # @argument enrollment_term_ids[] [Array]
  #   A list of associated term ids for the grading period set
  #
  # @argument grading_period_set[][title] [Required, String]
  #   The title of the grading period set
  #
  # @argument grading_period_set[][weighted] [Boolean]
  #   A boolean to determine whether the grading periods in the set are weighted
  #
  # @argument grading_period_set[][display_totals_for_all_grading_periods] [Boolean]
  #   A boolean to determine whether the totals for all grading periods in the set are displayed
  #
  # <b>204 No Content</b> response code is returned if the update was
  # successful.
  #
  def update
    old_term_ids = grading_period_set.enrollment_terms.pluck(:id)
    grading_period_set.enrollment_terms = enrollment_terms
    # we need to recompute scores for enrollment terms that were removed since the line above
    # will not run callbacks for the removed enrollment terms
    EnrollmentTerm.where(id: old_term_ids - enrollment_terms.map(&:id)).each do |term|
      term.recompute_course_scores_later(strand_identifier: "GradingPeriodGroup:#{grading_period_set.global_id}")
    end

    respond_to do |format|
      if grading_period_set.update(set_params)
        format.json { head :no_content }
      else
        format.json { render json: grading_period_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # @API Delete a grading period set
  #
  # <b>204 No Content</b> response code is returned if the deletion was
  # successful.
  #
  def destroy
    grading_period_set.destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def enrollment_terms
    return [] unless params[:enrollment_term_ids]

    @context.enrollment_terms.active.find(params[:enrollment_term_ids])
  end

  def grading_period_set
    @grading_period_set ||= GradingPeriodGroup
                            .for(@context)
                            .find(params[:id])
  end

  def set_params
    params.require(:grading_period_set).permit(:title, :weighted, :display_totals_for_all_grading_periods)
  end

  def check_read_rights
    render_json_unauthorized and return unless @context.grants_right?(@current_user, :read)
  end

  def check_manage_rights
    render_json_unauthorized and return unless @context.root_account?
    render_json_unauthorized and return unless @context.grants_right?(@current_user, :manage)
  end

  def serialize_json_api(grading_period_sets, meta = {})
    Canvas::APIArraySerializer.new(grading_period_sets, {
                                     each_serializer: GradingPeriodSetSerializer,
                                     controller: self,
                                     root: :grading_period_sets,
                                     meta:,
                                     scope: @current_user,
                                     include_root: false
                                   })
  end
end
