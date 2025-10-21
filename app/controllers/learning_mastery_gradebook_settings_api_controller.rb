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

    respond_to do |format|
      if update_learning_mastery_gradebook_settings
        settings = learning_mastery_gradebook_settings
        format.json { render json: { learning_mastery_gradebook_settings: settings }, status: :ok }
      else
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def learning_mastery_gradebook_settings_params
    params.require(:learning_mastery_gradebook_settings).permit(
      :secondary_info_display,
      :show_students_with_no_results,
      :show_student_avatars,
      :name_display_format
    )
  end

  def learning_mastery_gradebook_settings
    @current_user.get_preference(:learning_mastery_gradebook_settings, @context.global_id) || {}
  end

  def update_learning_mastery_gradebook_settings
    current_settings = learning_mastery_gradebook_settings
    updated_settings = current_settings.deep_merge(learning_mastery_gradebook_settings_params.to_h)
    @current_user.set_preference(:learning_mastery_gradebook_settings, @context.global_id, updated_settings)
  end

  def authorize
    authorized_action(@context, @current_user, %i[manage_grades view_all_grades])
  end

  def outcome_gradebook_enabled?
    @context.feature_enabled?(:outcome_gradebook)
  end
end
