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

    def user(user)
      UserDecorator.new(
        user,
        tool,
        user_variable_expander(user)
      )
    end

    def user_variable_expander(user)
      Lti::VariableExpander.new(
        course.root_account,
        course,
        controller,
        {
          current_user: user,
          tool: tool,
          variable_whitelist: %w(
            Person.name.full
            Person.name.display
            Person.name.family
            Person.name.given
            User.image
            User.id
            Canvas.user.id
            vnd.instructure.User.uuid
            Canvas.user.globalId
            Canvas.user.sisSourceId
            Person.sourcedId
            Message.locale
            vnd.Canvas.Person.email.sis
            Person.email.primary
          )
        }
      )
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
      validate_rlid!
    end

    def validate_rlid!
      return unless rlid?
      validate_tool_for_assignment!
      validate_course_for_rlid!
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

    def lti_roles
      Lti::SubstitutionsHelper::INVERTED_LIS_ADVANTAGE_ROLE_MAP[role]
    end

    def nonsense_role_filter?
      role? && lti_roles.blank?
    end

    def assignment
      @_assignment ||= begin
        return nil unless rlid?
        assignment = Assignment.active.for_course(course.id).where(lti_context_id: rlid).take
        return nil if assignment.blank?
        assignment
      end
    end

    def assignment?
      assignment.present?
    end

    def validate_tool_for_assignment!
      return unless assignment?
      # TODO: all of this might need to change once the LTI 1.3 tool<->resourcelink<->assignment binding mechanism is finalized
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

    def validate_course_for_rlid!
      raise Lti::Ims::AdvantageErrors::InvalidResourceLinkIdFilter if rlid? && !assignment? && course_rlid != rlid
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

    # Purposefully conservative and limiting in what we allow to be output into NRPS v2 responses. Obviously
    # has to change if more custom param support is added in the future. But that day may never come, so err on the
    # side of making it very hard to leak user attributes.
    class UserDecorator
      attr_reader :user, :expander, :tool

      def initialize(user, tool, expander)
        @user = user
        @tool = tool
        @expander = expander
      end

      def unwrap
        user
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

      def locale
        user.locale
      end
    end
  end
end
