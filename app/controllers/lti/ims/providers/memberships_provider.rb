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

    def self.unwrap(wrapped)
      wrapped&.respond_to?(:unwrap) ? wrapped.unwrap : wrapped
    end

    def initialize(context, controller, tool)
      @context = context
      @controller = controller
      @tool = tool
    end

    def find
      validate!
      memberships, api_metadata = find_memberships
      # NB Api#jsonapi_paginate has already written the Link header into the response.
      # That makes the `api_metadata` field here redundant, but we include it anyway
      # in case response serialization should ever need it. E.g. in NRPS v1, pagination
      # links went in the response body.
      {
          memberships: memberships,
          context: context,
          assignment: assignment,
          api_metadata: api_metadata,
          controller: controller,
          tool: tool,
          opts: {
            rlid: rlid,
            role: role,
            limit: limit
          }.compact
      }
    end

    protected

    def users_scope
      rlid? ? rlid_users_scope : apply_role_filter(base_users_scope)
    end

    def base_users_scope
      raise 'Abstract Method'
    end

    def rlid_users_scope
      raise 'Abstract Method'
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def apply_role_filter(scope)
      raise 'Abstract Method'
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def correlated_assignment_submissions(outer_user_id_column)
      Submission.active.for_assignment(assignment).where("#{outer_user_id_column} = submissions.user_id").select(:user_id)
    end

    def validate!
      return if !rlid? || (rlid == course_rlid)
      validate_tool_for_assignment!
    end

    def rlid
      controller.params[:rlid]
    end

    def rlid?
      rlid.present?
    end

    def role
      controller.params[:role]
    end

    def role?
      role.present?
    end

    def queryable_roles(lti_role)
      # Roles represented as Strings are for system and institution roles, which we do not care about for
      # purposes of NRPS filtering by role
      Lti::SubstitutionsHelper::INVERTED_LIS_V2_LTI_ADVANTAGE_ROLE_MAP[lti_role]&.reject { |r| r.is_a?(String) }
    end

    def nonsense_role_filter?
      role? && queryable_roles(role).blank?
    end

    def assignment
      @_assignment ||= begin
        return nil unless rlid?
        Assignment.active.for_course(course.id).
          joins(line_items: :resource_link).
          where(lti_resource_links: { resource_link_id: rlid, context_external_tool_id: tool.id }).
          distinct.
          take
      end
    end

    def assignment?
      assignment.present?
    end

    def validate_tool_for_assignment!
      raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter unless assignment?

      unless assignment.external_tool?
        raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter.new(
          "Assignment (id: #{assignment.id}, rlid: #{rlid}) is not configured for submissions via external tool",
          api_message: 'Requested assignment not configured for external tool launches'
        )
      end

      tool_tag = assignment.external_tool_tag
      if tool_tag.blank?
        raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter.new(
          "Assignment (id: #{assignment.id}, rlid: #{rlid}) is not bound to an external tool",
          api_message: 'Requested assignment not bound to an external tool'
        )
      end
      if tool_tag.content_type != "ContextExternalTool"
        raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter.new(
          "Assignment (id: #{assignment.id}, rlid: #{rlid}) needs content tag type 'ContextExternalTool' but found #{tool_tag.content_type}",
          api_message: 'Requested assignment has unexpected content type'
        )
      end
      if tool_tag.content_id != tool.id
        raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter.new(
          "Assignment (id: #{assignment.id}, rlid: #{rlid}) needs binding to external tool #{tool.id} but found #{tool_tag.content_id}",
          api_message: 'Requested assignment bound to unexpected external tool'
        )
      end
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

    def limit
      controller.params[:limit].to_i
    end

    def paginate(scope)
      Api.jsonapi_paginate(scope, controller, base_url, pagination_args)
    end

    def pagination_args
      # Treat LTI's `limit` param as override of std `per_page` API pagination param. Is no LTI override for `page`.
      pagination_args = {}
      if limit > 0
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
