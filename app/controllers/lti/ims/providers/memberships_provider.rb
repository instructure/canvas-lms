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

module Lti::Ims::Providers
  class MembershipsProvider
    include Api::V1::User

    attr_reader :context, :controller, :tool

    def initialize(context, controller, tool)
      @context = context
      @controller = controller
      @tool = tool
    end

    def find
      validate_rlid! if controller.params.key?(:rlid)
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

    def user(user)
      UserDecorator.new(
        user,
        tool,
        Lti::VariableExpander.new(
          course.root_account,
          course,
          controller,
          {
            current_user: user,
            tool: tool
          }
        )
      )
    end

    protected

    def validate_rlid!
      # TODO: check if rlid matches an Assignment ResourceLink
      rlid = controller.params[:rlid]
      raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter if rlid.present? && course_rlid != rlid
    end

    def course
      raise 'Abstract Method'
    end

    def course_rlid
      Lti::Asset.opaque_identifier_for(course)
    end

    def find_memberships
      throw 'Abstract Method'
    end

    def base_url
      controller.base_url
    end

    def preload_enrollments(enrollments)
      user_json_preloads(enrollments.map(&:user),
                         true,
                         { accounts: tool.include_name?, pseudonyms: tool.include_name? })
      enrollments
    end

    def paginate(scope)
      Api.jsonapi_paginate(scope, controller, base_url, pagination_args)
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

    # Purposefully conservative and limiting in what we allow to be output into NRPS v2 responses. Obviously
    # has to change if more custom param support is added in the future. But that day may never come, so err on the
    # side of making it very hard to leak user attributes.
    class UserDecorator
      attr_reader :user # Intentional backdoor. See Lti::Ims::NamesAndRolesSerializer for use case/s.

      def initialize(user, tool, expander)
        @user = user
        @tool = tool
        @expander = expander
      end

      def id
        user.id
      end

      def name
        user.name if @tool.include_name?
      end

      def first_name
        user.first_name if @tool.include_name?
      end

      def last_name
        user.last_name if @tool.include_name?
      end

      def email
        user.email if @tool.include_email?
      end

      def avatar_image_url
        user.avatar_image_url if @tool.public?
      end

      def sourced_id
        return nil unless @tool.include_name?
        @_sourced_id ||= begin
          expanded = @expander.expand_variables!({value: '$Person.sourcedId'})[:value]
          expanded == '$Person.sourcedId' ? nil : expanded
        end
      end
    end
  end
end
