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

    if @context.is_a?(Account)
      # We'd only ever load the provider app for an account
      load_canvas_career_for_provider
    else
      # Otherwise, try the learner app and then the provider app
      load_canvas_career_for_student
      load_canvas_career_for_provider unless performed?
    end
  end

  def canvas_career_learning_provider_app_launch_url
    uri = @context.root_account.horizon_url("learning-provider/remoteEntry.js")
    uri.to_s
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
    !(@context.user_is_admin?(@current_user) || @context.cached_account_users_for(@current_user).any?)
  end

  def horizon_admin?
    @context.grants_right?(@current_user, :read_as_admin)
  end

  # Use this function after @context is set
  def load_canvas_career_for_student
    return if params[:invitation].present?
    return unless horizon_course?
    return unless horizon_student?

    redirect_url = @context.root_account.horizon_redirect_url(request.path)
    return if redirect_url.nil?

    redirect_to redirect_url
  end

  # Use this function after @context is set
  def load_canvas_career_for_provider
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
    return false unless horizon_course?
    return false unless horizon_admin?
    return false if canvas_career_learning_provider_app_launch_url.blank?
    return false unless @context.account.feature_enabled?(:horizon_learning_provider_app_for_courses)

    true
  end

  def canvas_career_learning_provider_app_enabled_for_accounts?
    return false unless horizon_account?
    return false unless horizon_admin?
    return false if canvas_career_learning_provider_app_launch_url.blank?
    return false unless @context.feature_enabled?(:horizon_learning_provider_app_for_accounts)

    true
  end
end
