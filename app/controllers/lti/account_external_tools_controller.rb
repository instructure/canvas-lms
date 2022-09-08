# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti
  # @API Accounts (LTI)
  # @internal
  #
  # API for accessing account data using an LTI dev key. Allows a tool to get
  # external tool information via LTI Advantage authorization scheme, which
  # does not require a user session like normal developer keys do. Requires
  # the account external tools scope on the LTI key.

  class AccountExternalToolsController < ApplicationController
    include ::Lti::IMS::Concerns::AdvantageServices
    include Api::V1::ExternalTools

    before_action :verify_target_developer_key, only: [:create, :update]

    MIME_TYPE = "application/vnd.canvas.contextexternaltools+json"

    ACTION_SCOPE_MATCHERS = {
      create: all_of(TokenScopes::LTI_CREATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      show: all_of(TokenScopes::LTI_SHOW_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      update: all_of(TokenScopes::LTI_UPDATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      index: all_of(TokenScopes::LTI_LIST_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      destroy: all_of(TokenScopes::LTI_DESTROY_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
    }.freeze.with_indifferent_access

    def create
      tool = target_developer_key.tool_configuration.new_external_tool(context)
      tool.check_for_duplication(params[:verify_uniqueness].present?)

      if tool.errors.blank? && tool.save
        invalidate_nav_tabs_cache(tool)
        render json: external_tool_json(tool, context, @current_user, session), content_type: MIME_TYPE
      else
        tool.destroy if tool.persisted?
        render json: tool.errors, status: :bad_request, content_type: MIME_TYPE
      end
    end

    def show
      tool = tools.active.find(params["external_tool_id"])
      render json: external_tool_json(tool, context, @current_user, session), content_type: MIME_TYPE
    end

    def index
      api = Api.paginate(tools, self, account_external_tools_index_path(params[:account_id]))
      render json: external_tools_json(api, context, @current_user, session), content_type: MIME_TYPE
    end

    def destroy
      tool = tools.active.find(params["external_tool_id"])
      if tool.destroy
        render json: external_tool_json(tool, context, @current_user, session), content_type: MIME_TYPE
      else
        render json: tool.errors, status: :bad_request, content_type: MIME_TYPE
      end
    end

    private

    def verify_target_developer_key
      head :unauthorized unless target_developer_key.usable_in_context?(context)
    end

    def target_developer_key
      DeveloperKey.nondeleted.find_cached(params[:client_id])
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end

    def tools
      @tools ||= Lti::ContextToolFinder.all_tools_for(context)
    end

    def context
      @context ||= Account.active.find_by(lti_context_id: params[:account_id])
    end

    def message_type
      params[:message_type] || "live-event"
    end

    def invalidate_nav_tabs_cache(tool)
      if tool.has_placement?(:user_navigation) || tool.has_placement?(:course_navigation) || tool.has_placement?(:account_navigation)
        Lti::NavigationCache.new(@domain_root_account).invalidate_cache_key
      end
    end
  end
end
