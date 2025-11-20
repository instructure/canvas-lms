# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class LearningMasteryGradebookSettingsApiController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :authorize

  VALID_SECONDARY_INFO_DISPLAY_VALUES = %w[none sis_id integration_id login_id].freeze
  VALID_NAME_DISPLAY_FORMAT_VALUES = %w[first_last last_first].freeze
  VALID_STUDENTS_PER_PAGE_VALUES = [15, 30, 50, 100].freeze
  VALID_SCORE_DISPLAY_FORMAT_VALUES = %w[icon_only icon_and_points icon_and_label].freeze

  # @API Get Learning Mastery Gradebook Settings
  #
  # Get the current user's Learning Mastery Gradebook settings for the current context.
  #
  # @returns [Hash] The Learning Mastery Gradebook settings.
  def show
    return unless outcome_gradebook_enabled?

    settings = learning_mastery_gradebook_settings
    render json: { learning_mastery_gradebook_settings: settings }, status: :ok
  end

  # @API Update Learning Mastery Gradebook Settings
  #
  # Update the current user's Learning Mastery Gradebook settings for the current context.
  #
  # @param [Hash] learning_mastery_gradebook_settings The Learning Mastery Gradebook settings to update.
  #
  # @returns [Hash] The updated Learning Mastery Gradebook settings.
  def update
    return unless outcome_gradebook_enabled?

    errors = update_learning_mastery_gradebook_settings

    respond_to do |format|
      if errors.empty?
        settings = learning_mastery_gradebook_settings
        format.json { render json: { learning_mastery_gradebook_settings: settings }, status: :ok }
      else
        format.json { render json: { errors: }, status: :unprocessable_content }
      end
    end
  end

  private

  def learning_mastery_gradebook_settings_params
    params.require(:learning_mastery_gradebook_settings).permit(
      :secondary_info_display,
      :show_students_with_no_results,
      :show_student_avatars,
      :name_display_format,
      :students_per_page,
      :score_display_format
    )
  end

  def learning_mastery_gradebook_settings
    @current_user.get_preference(:learning_mastery_gradebook_settings, @context.global_id) || {}
  end

  def update_learning_mastery_gradebook_settings
    settings = learning_mastery_gradebook_settings_params
    errors = validate_settings(settings)

    if errors.empty?
      current_settings = learning_mastery_gradebook_settings
      updated_settings = current_settings.deep_merge(settings.to_h)
      @current_user.set_preference(:learning_mastery_gradebook_settings, @context.global_id, updated_settings)
    end

    errors
  end

  def validate_settings(settings)
    errors = []

    if settings.key?(:secondary_info_display)
      value = settings[:secondary_info_display]
      unless VALID_SECONDARY_INFO_DISPLAY_VALUES.include?(value)
        errors << "Invalid secondary_info_display. Valid values are: #{VALID_SECONDARY_INFO_DISPLAY_VALUES.join(", ")}"
      end
    end

    if settings.key?(:show_students_with_no_results)
      value = settings[:show_students_with_no_results]
      unless [true, false, "true", "false"].include?(value)
        errors << "Invalid show_students_with_no_results ('#{value}'). Valid values are: [true, false]"
      end
    end

    if settings.key?(:show_student_avatars)
      value = settings[:show_student_avatars]
      unless [true, false, "true", "false"].include?(value)
        errors << "Invalid show_student_avatars ('#{value}'). Valid values are: [true, false]"
      end
    end

    if settings.key?(:name_display_format)
      value = settings[:name_display_format]
      unless VALID_NAME_DISPLAY_FORMAT_VALUES.include?(value)
        errors << "Invalid name_display_format ('#{value}'). Valid values are: #{VALID_NAME_DISPLAY_FORMAT_VALUES.join(", ")}"
      end
    end

    if settings.key?(:students_per_page)
      value = settings[:students_per_page]
      unless VALID_STUDENTS_PER_PAGE_VALUES.include?(value.to_i)
        errors << "Invalid students_per_page ('#{value}'). Valid values are: #{VALID_STUDENTS_PER_PAGE_VALUES.join(", ")}"
      end
    end

    if settings.key?(:score_display_format)
      value = settings[:score_display_format]
      unless VALID_SCORE_DISPLAY_FORMAT_VALUES.include?(value)
        errors << "Invalid score_display_format ('#{value}'). Valid values are: #{VALID_SCORE_DISPLAY_FORMAT_VALUES.join(", ")}"
      end
    end

    errors
  end

  def authorize
    authorized_action(@context, @current_user, %i[manage_grades view_all_grades])
  end

  def outcome_gradebook_enabled?
    @context.feature_enabled?(:outcome_gradebook)
  end
end
