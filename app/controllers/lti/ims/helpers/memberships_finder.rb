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

module Lti::Ims::Helpers
  class MembershipsFinder
    include Api::V1::User

    attr_reader :context, :controller

    def initialize(context, controller)
      @context = context
      @controller = controller
    end

    def find
      memberships, api_metadata = find_memberships
      # NB Api#jsonapi_paginate has already written the Link header into the response.
      # That makes the `api_metadata` field here redundant, but we include it anyway
      # in case response serialization should ever need it. E.g. in NRPS v1, pagination
      # links went in the response body.
      {
          memberships: memberships,
          context: context,
          api_metadata: api_metadata
      }
    end

    protected

    def find_memberships
      throw 'Abstract Method'
    end

    def base_url
      controller.base_url
    end

    def pagination_args
      # Treat LTI's `limit` param as override of std `per_page` API pagination param. Is no LTI override for `page`.
      pagination_args = {}
      if (limit = controller.params[:limit].to_i) > 0
        pagination_args[:per_page] = [limit, Api.max_per_page].min
        # Ensure page size reset isn't accidentally clobbered by other pagination API params
        clear_request_param :per_page
      end
      # Avoid
      #   a) perpetual page size reset
      #   b) repetition of nonsense `limit` values in pagination Links
      clear_request_param :limit
      pagination_args
    end

    def clear_request_param(param)
      controller.params.delete param
      controller.request.query_parameters.delete param
    end

  end
end
