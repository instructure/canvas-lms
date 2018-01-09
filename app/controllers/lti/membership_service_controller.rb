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
require 'oauth/request_proxy/action_controller_request'

module Lti
  class MembershipServiceController < ApplicationController
    before_action :require_context
    before_action :check_authorized_action

    def course_index
      render_page_presenter
    end

    def group_index
      render_page_presenter
    end

    private

    def check_authorized_action
      if @current_user
        require_user
        authorized_action(@context, @current_user, :read)
      elsif lti_tool_access_enabled?
        req = OAuth::RequestProxy.proxy(request)
        consumer_key, timestamp, nonce = req.oauth_consumer_key, req.oauth_timestamp, req.oauth_nonce
        return head :unauthorized unless Security::check_and_store_nonce("lti_nonce_#{consumer_key}_#{nonce}", timestamp, 10.minutes)
        tool = ContextExternalTool.find_active_external_tool_by_consumer_key(consumer_key, @context.is_a?(Course) ? @context : @context.context)
        head :unauthorized unless tool && tool.allow_membership_service_access && OAuth::Signature.verify(request, consumer_secret: tool.shared_secret)
      else
        head :unauthorized
      end
    end

    def render_page_presenter
      @page = MembershipService::PagePresenter.new(@context,
                                                   @current_user,
                                                   request.base_url,
                                                   membership_service_params)

      render json: @page
    end

    def membership_service_params
      keys = %w(role page per_page)
      params.select { |k,_| keys.include?(k) }
    end

    def lti_tool_access_enabled?
      @context.root_account.feature_enabled?(:membership_service_for_lti_tools)
    end
  end
end
