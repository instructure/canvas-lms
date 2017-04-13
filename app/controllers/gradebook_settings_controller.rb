#
# Copyright (C) 2016 - 2017 Instructure, Inc.
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

class GradebookSettingsController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :authorize

  def update
    @current_user.preferences[:gradebook_settings] = {
      @context.id => gradebook_settings_params.to_h
    }
    respond_to do |format|
      if @current_user.save
        format.json do
          render json: { gradebook_settings: gradebook_settings }, status: :ok
        end
      else
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def gradebook_settings_params
    params.require(:gradebook_settings).permit(
      :show_concluded_enrollments,
      :show_inactive_enrollments,
      :show_unpublished_assignments
    )
  end

  def authorize
    authorized_action(@context, @current_user, :view_all_grades)
  end

  def gradebook_settings
    @current_user.preferences.fetch(:gradebook_settings)
  end
end
