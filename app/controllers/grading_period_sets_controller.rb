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

class GradingPeriodSetsController < ApplicationController
  before_action :require_user
  before_action :get_context
  before_action :check_manage_rights, except: [:index]
  before_action :check_read_rights, except: [:update, :create, :destroy]

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
      meta: meta,
      scope: @current_user,
      include_root: false
    })
  end
end
