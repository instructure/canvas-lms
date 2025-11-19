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

class CareerController < ApplicationController
  include HorizonMode

  before_action :require_user, :get_context

  def show
    app = CanvasCareer::ExperienceResolver.new(@current_user, @context, @domain_root_account, session).resolve
    return redirect_to(root_path) if app == CanvasCareer::Constants::App::ACADEMIC

    env = {
      FEATURES: features_env,
    }
    js_env(CANVAS_CAREER: env)
    js_env(MAX_GROUP_CONVERSATION_SIZE: Conversation.max_group_conversation_size)

    config = CanvasCareer::Config.new(@domain_root_account, session)
    if app == CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER
      remote_env(canvas_career_learning_provider: config.learning_provider_app_launch_url)
    elsif app == CanvasCareer::Constants::App::CAREER_LEARNER
      remote_env(canvas_career_learner: config.learner_app_launch_url)
    end

    remote_env(canvas_career_config: config.public_app_config(request))
    deferred_js_bundle(:canvas_career)

    @include_masquerade_layout = true

    respond_to do |format|
      format.html { render html: "", layout: "bare" }
    end
  end

  private

  def features_env
    %i[
      horizon_root_experience
      horizon_dashboard_ai_widgets
      horizon_hris_integrations
      horizon_user_profile_page
      horizon_bulk_metadata_import
      horizon_manual_dashboard_builder
      horizon_dark_career_theme_in_learning_provider
      horizon_learning_library
      horizon_course_navigation
      horizon_course_redesign
      horizon_course_index_page
      horizon_chart_view
    ].index_with { |feature| @domain_root_account.feature_enabled?(feature) }
  end
end
