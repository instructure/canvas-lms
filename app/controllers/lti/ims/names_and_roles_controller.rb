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
    include Concerns::AdvantageServices

    skip_before_action :load_user

    MIME_TYPE = 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'.freeze

    def course_index
      render_memberships
    end

    def group_index
      render_memberships
    end

    def base_url
      polymorphic_url([context, :names_and_roles])
    end

    def tool_permissions_granted?
      access_token&.claim('scopes')&.split(' ')&.include?(TokenScopes::LTI_NRPS_V2_SCOPE)
    end

    def context
      get_context
      @context
    end

    private

    def render_memberships
      page = find_memberships_page
      render json: NamesAndRolesSerializer.new(page).as_json, content_type: MIME_TYPE
    rescue AdvantageErrors::AdvantageClientError => e # otherwise it's a system error, so we want normal error trapping and rendering to kick in
      handled_error(e)
      render_error e.api_message, e.status_code
    end

    def find_memberships_page
      {url: request.url}.reverse_merge(new_provider.find)
    end

    def new_provider
      Providers.const_get("#{context.class}MembershipsProvider").new(context, self, tool)
    end
  end
end
