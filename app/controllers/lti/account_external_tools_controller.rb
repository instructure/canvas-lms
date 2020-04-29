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
    include Ims::Concerns::AdvantageServices
    include Api::V1::ExternalTools

    MIME_TYPE = 'application/vnd.canvas.contextexternaltools+json'.freeze

    ACTION_SCOPE_MATCHERS = {
      create: all_of(TokenScopes::LTI_CREATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      show: all_of(TokenScopes::LTI_SHOW_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      update: all_of(TokenScopes::LTI_UPDATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      index: all_of(TokenScopes::LTI_LIST_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
      destroy: all_of(TokenScopes::LTI_DESTROY_ACCOUNT_EXTERNAL_TOOLS_SCOPE),
    }.freeze.with_indifferent_access

    def create
      # Will add in seperate PS
    end

    def update
      # Will add in seperate PS
    end

    def show
      # Will add in seperate PS
    end

    def index
      @tools = Api.paginate(ContextExternalTool.all_tools_for(context), self, account_external_tools_index_path(params[:account_id]))
      render json: external_tools_json(@tools, context, @current_user, session), content_type: MIME_TYPE
    end

    def destroy
      # Will add in seperate PS
    end

    private

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end

    def context
      @context ||= Account.active.find_by(lti_context_id: params[:account_id])
    end

    def message_type
      params[:message_type] || 'live-event'
    end
  end
end
