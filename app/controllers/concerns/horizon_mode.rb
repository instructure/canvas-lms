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

module HorizonMode
  def load_canvas_career
    return if force_academic? || api_request?
    return if params[:invitation].present?
    return unless @current_user

    case CanvasCareer::ExperienceResolver.new(@current_user, @context, @domain_root_account, session).resolve
    when CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER
      load_career_learning_provider
    when CanvasCareer::Constants::App::CAREER_LEARNER
      load_career_learner
    end
  end

  private

  def load_career_learning_provider
    redirect_to rewrite_path_for_career
  end

  def load_career_learner
    if @domain_root_account.feature_enabled?(:horizon_learner_app)
      redirect_to rewrite_path_for_career
    elsif @context.is_a?(Course) && @context.horizon_course?
      # Redirect to the separate career domain - this will be removed once transition to MF is completed
      redirect_url = CanvasCareer::Config.new(@domain_root_account).learner_app_redirect_url(request.path)
      redirect_to redirect_url if redirect_url.present?
    end
  end

  def force_academic?
    # The query param allows breaking out of career for a single request
    # The cookie allows it for an entire session (i.e., set in an iframe and forget); needed to support
    # form post in iframed Canvas academic
    Canvas::Plugin.value_to_boolean(params[:force_classic]) || Canvas::Plugin.value_to_boolean(cookies[:force_classic])
  end

  def rewrite_path_for_career
    "#{canvas_career_path}#{request.fullpath}"
  end
end
