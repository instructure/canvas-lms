# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class AnalyticsHubController < ApplicationController
  before_action :require_account_context
  before_action :require_user
  before_action :require_account_management
  before_action { |c| c.active_tab = "analytics_hub" }

  def show
    add_crumb "Analytics Hub"
    @page_title = "Analytics Hub"
    @body_classes << "full-width padless-content"

    remote_env(analytics_hub: {
                 launch_url: Services::AnalyticsHub.launch_url,
                 backend_url: Services::AnalyticsHub.backend_url
               })

    deferred_js_bundle :analytics_hub

    env = {
      accountID: @account.id.to_s,
      # course_readiness_read: @account.grants_right?(@current_user, session, :course_readiness_read)
    }

    js_env(env)
    render html: "", layout: true
  end
end
