#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Ims
  class NamesAndRolesController < ApplicationController
    include Lti::Ims::AccessTokenHelper
    include Lti::Ims::Concerns::AdvantageServices

    skip_before_action :load_user

    # TODO: When Group authZ support added (LTIA-27), take out all the `only:` conditions
    before_action(
      :verify_environment,
      :verify_access_token,
      :verify_permissions,
      :verify_developer_key,
      :verify_context,
      :verify_tool,
      :verify_lti_advantage_enabled
    )

    MIME_TYPE = 'application/vnd.ims.lis.v2.membershipcontainer+json'.freeze

    def course_index
      render_memberships
    end

    def group_index
      render_memberships
    end

    def base_url
      polymorphic_url([context, :names_and_roles])
    end

    private

    def render_memberships
      page = find_memberships_page
      render json: Lti::Ims::NamesAndRolesSerializer.new(page).as_json, content_type: MIME_TYPE
    end

    def find_memberships_page
      {url: request.url}.reverse_merge(new_provider.find)
    end

    def new_provider
      Providers.const_get("#{context.class}MembershipsProvider").new(context, self, tool)
    end

    def verify_environment
      # TODO: Take out when 1.3/Advantage fully baked. See same hack in Lti::Ims::Concerns::GradebookServices.
      render_unauthorized_action if Rails.env.production?
    end

    def verify_access_token
      # TODO: this needs to change to use either Lti::Oauth2::AuthorizationValidator#validate! or
      # Lti::Ims::AccessTokenHelper#validate_access_token!. Currently can't use former b/c it expects JWTs to be signed
      # by DeveloperKey#api_key, whereas current Client Credentials Grant support uses the system-wide encryption key.
      # Currently can't use latter (#validate_access_token!) b/c of a variety of mismatched expectations around `aud`
      # and `iss` claims
      render_error("Missing Access Token", :unauthorized) if access_token.blank?
    end

    def verify_permissions
      render_error("NRPS v2 scope not granted", :unauthorized) unless nrps_scope_granted
    end

    def nrps_scope_granted
      access_token&.claim('scopes')&.split(' ')&.include?(TokenScopes::LTI_NRPS_V2_SCOPE)
    end

    def verify_developer_key
      render_error("Unknown or inactive Developer Key", :unauthorized) unless developer_key&.active?
    end

    def verify_context
      require_context
    end

    def verify_tool
      render_error("Access Token not linked to a Tool associated with this Context", :unauthorized) if tool.blank?
    end

    def verify_lti_advantage_enabled
      render_error("LTI 1.3/Advantage features not enabled", :unauthorized) unless tool&.names_and_roles_service_enabled?
    end

    def tool
      @_tool ||= begin
        return nil unless context
        return nil if (tools = developer_key&.active_context_external_tools).blank?
        # DeveloperKeys have n-many ContextExternalTools. Limit that list to just the
        # active ones, then try to find the first CET with a direct association w the requested
        # Context. Failing that, walk the Context's Account chain and find the first CET
        # directly associated with such an Account.
        tools.find(-> {find_account_tool(tools)}, &method(:context_tool?))
      end
    end

    def find_account_tool(tools)
      context.account_chain.each do |acct|
        tool = tools.find { |t| t.context.is_a?(Account) && t.context == acct}
        return tool if tool
      end
      nil
    end

    def context_tool?(tool)
      tool_bindable_context = context.is_a?(Group) ? context.course : context
      tool.context == tool_bindable_context ? tool : nil
    end
  end
end
