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
  
  def create
    if authorized_action(@context, @current_user, :manage_grades)
      @standard = @context.grading_standards.build(params[:grading_standard])
      @standard.user = @current_user
      respond_to do |format|
        if @standard.save
          format.json{ render :json => @standard.to_json } 
        else
          format.json{ render :json => @standard.errors.to_json, :status => :bad_request }
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
          format.json{ render :json => @standard.to_json }
        else
          format.json{ render :json => @standard.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
end
