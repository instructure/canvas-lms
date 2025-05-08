# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class CareerController < ApplicationController
  include HorizonMode

  before_action :require_user
  before_action :require_enabled_feature_flag
  before_action :set_context_from_params
  before_action :load_canvas_career_learning_provider_app

  # This action will handle all routes under /career*
  def catch_all
    respond_to do |format|
      format.html { render html: "", layout: "bare" }
    end
  end

  private

  # Set the context from the course_id parameter if available
  # This ensures that @context is properly set for HorizonMode methods
  def set_context_from_params
    course_id = params[:course_id].presence || session[:career_course_id]
    if course_id.present?
      @context = Course.find(course_id)
    else
      redirect_to root_path and return
    end
  end

  def require_enabled_feature_flag
    unless Account.site_admin.feature_enabled?(:horizon_learning_provider_app)
      redirect_to root_path and return
    end
  end
end
