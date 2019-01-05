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
    deep_merge_gradebook_settings

    respond_to do |format|
      if @current_user.save
        format.json { render json: updated_settings, status: :ok }
      else
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def gradebook_settings_params
    gradebook_settings_params = params.require(:gradebook_settings).permit(
      {
        filter_columns_by: [
          :context_module_id,
          :grading_period_id,
          :assignment_group_id
        ],
        filter_rows_by: [
          :section_id
        ],
        selected_view_options_filters: []
      },
      :enter_grades_as,
      :show_concluded_enrollments,
      :show_inactive_enrollments,
      :show_final_grade_overrides,
      :show_unpublished_assignments,
      :student_column_display_as,
      :student_column_secondary_info,
      :sort_rows_by_column_id,
      :sort_rows_by_setting_key,
      :sort_rows_by_direction,
      { colors: [ :late, :missing, :resubmitted, :dropped, :excused ] }
    )
    gradebook_settings_params[:enter_grades_as] = params[:gradebook_settings][:enter_grades_as]
    gradebook_settings_params.permit!
  end

  def valid_colors(color_params)
    color_params.select { |_key, value| value =~ /^#([0-9A-F]{3}){1,2}$/i }
  end

  def nilify_strings(hash)
    massaged_hash = {}
    hash.each do |key, value|
      massaged_hash[key] = if value == 'null'
        nil
      elsif value.is_a? Hash
        nilify_strings(value)
      else
        value
      end
    end
    massaged_hash
  end

  def authorize
    authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
  end

  def gradebook_settings
    @current_user.preferences.fetch(:gradebook_settings)
  end

  def updated_settings
    {
      gradebook_settings: {
        @context.id => gradebook_settings.fetch(@context.id),
        # when new_gradebook is the only gradebook this can change to .fetch(:colors)
        colors: gradebook_settings.fetch(:colors, {})
      }
    }
  end

  def deep_merge_gradebook_settings
    @current_user.preferences.deep_merge!({
      gradebook_settings: {
       @context.id => nilify_strings(gradebook_settings_params.except(:colors).to_h),
       # when new_gradebook is the only gradebook this can change to .fetch('colors')
       colors: valid_colors(gradebook_settings_params.fetch('colors', {})).to_unsafe_h
      }
    })
  end
end
