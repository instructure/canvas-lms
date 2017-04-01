#
# Copyright (C) 2011 Instructure, Inc.
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

class GradingStandardsController < ApplicationController
  JSON_METHODS =
    [:display_name, :context_code, :assessed_assignment?, :context_name].freeze

  before_action :require_context
  add_crumb(proc { t '#crumbs.grading_standards', "Grading" }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grading_standards_url }
  before_action { |c| c.active_tab = "grading_standards" }

  def index
    if authorized_action(@context, @current_user, :manage_grades)
      client_env = {
        GRADING_STANDARDS_URL: context_url(@context, :context_grading_standards_url),
        GRADING_PERIOD_SETS_URL: api_v1_account_grading_period_sets_url(@context),
        ENROLLMENT_TERMS_URL: api_v1_enrollment_terms_url(@context),
        HAS_GRADING_PERIODS: grading_periods?,
        DEFAULT_GRADING_STANDARD_DATA: GradingStandard.default_grading_standard,
        CONTEXT_SETTINGS_URL: context_url(@context, :context_settings_url)
      }

      if @context.is_a?(Account)
        client_env[:GRADING_PERIODS_UPDATE_URL] = api_v1_grading_period_set_periods_update_url("{{ set_id }}")
        client_env[:GRADING_PERIODS_READ_ONLY] = !@context.root_account?
        client_env[:GRADING_PERIOD_SET_UPDATE_URL] = api_v1_account_grading_period_set_url(@context, "{{ id }}")
        client_env[:ENROLLMENT_TERMS_URL] = api_v1_enrollment_terms_url(@context.root_account)
        client_env[:DELETE_GRADING_PERIOD_URL] = api_v1_account_grading_period_destroy_url(@context, "{{ id }}")
        view_path = 'account_index'
      else
        client_env[:GRADING_PERIODS_URL] = api_v1_course_grading_periods_url(@context)
        client_env[:GRADING_PERIODS_WEIGHTED] = @context.weighted_grading_periods?
        view_path = 'course_index'
      end

      js_env(client_env)

      @standards = GradingStandard.for(@context).sorted.limit(100)
      respond_to do |format|
        format.html { render view_path }
        format.json { render json: @standards.map { |s| standard_as_json(s) } }
      end
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      @standard = @context.grading_standards.build(grading_standard_params)
      if @standard.read_attribute(:data).blank?
        @standard.data = GradingStandard.default_grading_standard
      end
      @standard.user = @current_user
      respond_to do |format|
        if @standard.save
          format.json { render json: standard_as_json(@standard) }
        else
          format.json { render json: @standard.errors, status: :bad_request }
        end
      end
    end
  end

  def update
    @standard = GradingStandard.for(@context).find(params[:id])
    if authorized_action(@standard, @current_user, :manage)
      @standard.user = @current_user
      respond_to do |format|
        if @standard.update_attributes(grading_standard_params)
          format.json { render json: standard_as_json(@standard) }
        else
          format.json { render json: @standard.errors, status: :bad_request }
        end
      end
    end
  end

  def destroy
    @standard = GradingStandard.for(@context).find(params[:id])
    if authorized_action(@standard, @current_user, :manage)
      respond_to do |format|
        if @standard.destroy
          format.json { render json: standard_as_json(@standard) }
        else
          format.json { render json: @standard.errors, status: :bad_request }
        end
      end
    end
  end

  private

  def default_data
    GradingStandard.default_grading_standard
  end

  def standard_as_json(standard)
    standard.as_json(methods: JSON_METHODS, permissions: { user: @current_user })
  end

  def grading_standard_params
    return {} unless params[:grading_standard]
    params[:grading_standard].permit(:title, :standard_data => strong_anything, :data => strong_anything)
  end
end
