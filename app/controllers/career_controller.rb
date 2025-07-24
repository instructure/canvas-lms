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

    config = CanvasCareer::Config.new(@domain_root_account)
    if app == CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER
      remote_env(canvas_career_learning_provider: config.learning_provider_app_launch_url)
    elsif app == CanvasCareer::Constants::App::CAREER_LEARNER
      remote_env(canvas_career_learner: config.learner_app_launch_url)
    end

    remote_env(canvas_career_config: config.public_app_config(request)) if @domain_root_account.feature_enabled?(:horizon_injected_config)
    deferred_js_bundle(:canvas_career)

    respond_to do |format|
      format.html { render html: "", layout: "bare" }
    end
  end

  private

  def features_env
    %i[
      horizon_crm_integration
      horizon_leader_dashboards
      horizon_admin_dashboards
      horizon_roles_and_permissions
      horizon_agent
      horizon_content_library
      horizon_program_management
      horizon_skill_management
    ].index_with { |feature| @domain_root_account.feature_enabled?(feature) }
  end
end
