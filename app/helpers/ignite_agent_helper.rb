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
  def add_ignite_agent_bundle
    return unless @domain_root_account&.feature_enabled?(:ignite_agent_enabled)
    return unless @current_user

    return unless @domain_root_account&.grants_right?(@current_user, session, :access_ignite_agent)

    js_bundle :ignite_agent
    remote_env(ignite_agent: {
                 launch_url: Services::IgniteAgent.launch_url,
                 backend_url: Services::IgniteAgent.backend_url
               })
  end
end
