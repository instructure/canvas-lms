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
  before_action :require_view_analytics_hub_permission
  before_action { |c| c.active_tab = "analytics_hub" }

  def require_view_analytics_hub_permission
    !!authorized_action(@context, @current_user, :view_analytics_hub)
  end

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
      ANALYTICS_HUB: {
        ACCOUNT_ID: @account.id.to_s,
        PERMISSIONS: @context.granted_rights(@current_user, :view_ask_questions_analytics, :view_students_in_need, :view_course_readiness, :view_lti_usage),
        FEATURE_FLAGS: {
          ADVANCED_ANALYTICS_ASK_QUESTIONS_ENABLED: @account.feature_enabled?(:advanced_analytics_ask_questions),
          K20_STUDENTS_IN_NEED_OF_ATTENTION_ENABLED: @account.feature_enabled?(:k20_students_in_need_of_attention),
          K20_COURSE_READINESS_ENABLED: @account.feature_enabled?(:k20_course_readiness),
          K20_LTI_USAGE_ENABLED: @account.feature_enabled?(:k20_lti_usage),
          MONITOR_LTI_USAGE_ENABLED: @account.feature_enabled?(:lti_registrations_usage_data)
        }
      }
    }

    js_env(env)
    render html: "", layout: true
  end
end
