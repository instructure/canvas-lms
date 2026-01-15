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

module IgniteAgentHelper
  ALLOWED_PAGES = begin
    config_path = Rails.root.join("config/ignite_agent_pages.yml")
    config = YAML.load_file(config_path)
    config["allowed_pages"] || []
  end.freeze

  def add_ignite_agent_bundle?
    return false if params[:preview] == "true"
    return false if controller_name == "oauth2_provider"
    return false unless @domain_root_account

    if @domain_root_account.feature_enabled?(:ignite_agent_enabled) # legacy, scheduled for removal
      return true if @domain_root_account.grants_right?(@current_user, session, :manage_account_settings)
      return true if @current_user&.feature_enabled?(:ignite_agent_enabled_for_user)
    end

    return true if @domain_root_account.feature_enabled?(:oak_for_admins) && @domain_root_account.grants_right?(@current_user, session, :access_oak)

    false
  end

  def show_ignite_agent_button?
    ALLOWED_PAGES.include?("#{controller_path}##{action_name}")
  end
end
