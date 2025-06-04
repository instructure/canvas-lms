# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  before_action :require_user
  before_action :require_context
  before_action :require_enabled_learning_provider_app

  def catch_all
    env = {
      FEATURES: features_env
    }
    js_env(CANVAS_CAREER: env)
    remote_env(canvascareer: canvas_career_learning_provider_app_launch_url)
    deferred_js_bundle :canvas_career

    respond_to do |format|
      format.html { render html: "", layout: "bare" }
    end
  end

  private

  def require_enabled_learning_provider_app
    unless canvas_career_learning_provider_app_enabled?
      redirect_to root_path and return
    end
  end

  def features_env
    account = @context.is_a?(Account) ? @context : @context.account
    %i[
      horizon_crm_integration
      horizon_leader_dashboards
      horizon_admin_dashboards
      horizon_roles_and_permissions
      horizon_agent
      horizon_content_library
      horizon_program_management
      horizon_skill_management
    ].index_with { |feature| account.feature_enabled?(feature) }
  end
end
