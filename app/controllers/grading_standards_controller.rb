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
  before_filter :require_context
  add_crumb(proc { t '#crumbs.grading_standards', "Grading" }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grading_standards_url }
  before_filter { |c| c.active_tab = "grading_standards" }

  def default_data
    GradingStandard.default_grading_standard
  end

  def index
    if authorized_action(@context, @current_user, :manage_grades)
      js_env({
        :GRADING_STANDARDS_URL => context_url(@context, :context_grading_standards_url),
        :GRADING_PERIODS_URL => context_url(@context, :api_v1_context_grading_periods_url),
        :MULTIPLE_GRADING_PERIODS => multiple_grading_periods?
      })
      @standards = GradingStandard.standards_for(@context).sorted.limit(100)
      respond_to do |format|
        format.html { }
        format.json {
          standards_json = @standards.map do |s|
            s.as_json(methods: [:display_name, :context_code, :assessed_assignment?, :context_name], permissions: {user: @current_user})
          end
          render :json => standards_json
        }
      end
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      @standard = @context.grading_standards.build(params[:grading_standard])
      @standard.data = default_data unless params[:grading_standard][:data]
      @standard.user = @current_user
      respond_to do |format|
        if @standard.save
          format.json{ render :json => @standard.as_json(permissions: {user: @current_user}) }
        else
          format.json{ render :json => @standard.errors, :status => :bad_request }
        end
      end
    end
  end

  def update
    @standard = @context.grading_standards.find(params[:id])
    if authorized_action(@context, @current_user, :manage_grades)
      @standard.user = @current_user
      respond_to do |format|
        if @standard.update_attributes(params[:grading_standard])
          format.json{ render :json => @standard.as_json(permissions: {user: @current_user}) }
        else
          format.json{ render :json => @standard.errors, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @standard = @context.grading_standards.find(params[:id])
    if authorized_action(@context, @current_user, :manage_grades)
      respond_to do |format|
        if @standard.destroy
          format.json{ render :json => @standard.as_json(permissions: {user: @current_user}) }
        else
          format.json{ render :json => @standard.errors, :status => :bad_request }
        end
      end
    end
  end
end
