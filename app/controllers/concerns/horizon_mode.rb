# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module HorizonMode
  # Use this function after @context is set
  # Combines both student and provider career loading in one method
  def load_canvas_career
    return if Canvas::Plugin.value_to_boolean(params[:force_classic])
    return if api_request?

    # Check appropriate feature flag before redirecting
    if should_load_provider_app?
      return unless canvas_career_learning_provider_app_enabled?

      load_canvas_career_for_provider
    else
      load_canvas_career_for_student
    end
  end

  # Helper method to determine if provider app should be loaded
  def should_load_provider_app?
    @context.is_a?(Account) || horizon_admin?
  end

  # Helper methods to centralize feature flag checking
  def learner_app_feature_enabled?
    @context.account.feature_enabled?(:horizon_learner_app_for_students)
  end

  def provider_app_feature_enabled_for_courses?
    @context.account.feature_enabled?(:horizon_learning_provider_app_for_courses)
  end

  def provider_app_feature_enabled_for_accounts?
    @context.feature_enabled?(:horizon_learning_provider_app_for_accounts)
  end

  def canvas_career_learning_provider_app_launch_url
    @context.root_account.horizon_url("learning-provider/remoteEntry.js").to_s
  end

  def canvas_career_learner_app_launch_url
    @context.root_account.horizon_url("remoteEntry.js").to_s
  end

  def canvas_career_learner_app_enabled?
    if @context.is_a?(Course)
      canvas_career_learner_app_enabled_for_students?
    else
      false
    end
  end

  def canvas_career_learning_provider_app_enabled?
    if @context.is_a?(Course)
      canvas_career_learning_provider_app_enabled_for_courses?
    elsif @context.is_a?(Account)
      canvas_career_learning_provider_app_enabled_for_accounts?
    else
      false
    end
  end

  private

  def horizon_course?
    return @_horizon_course unless @_horizon_course.nil?

    @_horizon_course = @context.is_a?(Course) && @context.horizon_course?
  end

  def horizon_account?
    return @_horizon_account unless @_horizon_account.nil?

    @_horizon_account = @context.is_a?(Account) && @context.horizon_account?
  end

  def horizon_student?
    return false if @context.nil?

    !(@context.user_is_admin?(@current_user) || @context.cached_account_users_for(@current_user).any?)
  end

  def horizon_admin?
    return false if @context.nil?

    @context.grants_right?(@current_user, :read_as_admin)
  end

  # Use this function after @context is set
  def load_canvas_career_for_student
    return unless @context # Safety check: ensure @context exists
    return if request.path.include?("/career")

    return if params[:invitation].present?

    if canvas_career_learner_app_enabled_for_students?
      redirect_to career_learn_path(course_id: @context.id)
      return
    end

    redirect_url = @context.root_account.horizon_redirect_url(request.path)

    return if redirect_url.nil?

    redirect_to redirect_url
  end

  # Use this function after @context is set
  def load_canvas_career_for_provider
    return unless @context # Safety check: ensure @context exists
    return unless canvas_career_learning_provider_app_enabled?
    return if request.path.include?("/career")

    if @context.is_a?(Course)
      path = request.path.sub("/courses/#{@context.id}", "")
      redirect_to "#{course_career_path(course_id: @context.id)}#{path}"
    elsif @context.is_a?(Account)
      path = request.path.sub("/accounts/#{@context.id}", "")
      redirect_to "#{account_career_path(account_id: @context.id)}#{path}"
    else
      redirect_to root_path
    end
  end

  def canvas_career_learning_provider_app_enabled_for_courses?
    horizon_course? &&
      provider_app_feature_enabled_for_courses? &&
      horizon_admin? &&
      canvas_career_learning_provider_app_launch_url.present?
  end

  def canvas_career_learning_provider_app_enabled_for_accounts?
    horizon_account? &&
      provider_app_feature_enabled_for_accounts? &&
      horizon_admin? &&
      canvas_career_learning_provider_app_launch_url.present?
  end

  def canvas_career_learner_app_enabled_for_students?
    horizon_course? &&
      learner_app_feature_enabled? &&
      horizon_student? &&
      canvas_career_learner_app_launch_url.present?
  end
end
