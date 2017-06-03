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
#

class GradebookSettingsController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :authorize

  def update
    @current_user.preferences.deep_merge!(
      {
        gradebook_settings: {
          @context.id => gradebook_settings_params.to_h
        }
      }
    )

    respond_to do |format|
      if @current_user.save
        format.json do
          updated_settings = {
            gradebook_settings: {
              @context.id => gradebook_settings[@context.id]
            }
          }

          render json: updated_settings, status: :ok
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
      :show_unpublished_assignments,
      :student_column_display_as,
      :student_column_secondary_info,
      :sort_rows_by_column_id,
      :sort_rows_by_setting_key,
      :sort_rows_by_direction,
    )
  end

  def authorize
    authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
  end

  def gradebook_settings
    @current_user.preferences.fetch(:gradebook_settings)
  end
end
