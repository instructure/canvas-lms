# frozen_string_literal: true

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

module Lti::Messages
  # A "factory" class that builds an ID Token (JWT) to be used in LTI Advantage
  # LTI Resource Link Requests (a.k.a standard LTI 1.3 tool launches).
  #
  # This class relies on a another class (LtiAdvantage::Messages::ResourceLinkRequest)
  # to model the data in the JWT body and produce a signature.
  #
  # For details on the data included in the ID token please refer
  # to http://www.imsglobal.org/spec/lti/v1p3/.
  #
  # For implementation details on LTI Advantage launches in
  # Canvas, please see the inline documentation of
  # app/models/lti/lti_advantage_adapter.rb.
  class ResourceLinkRequest < JwtMessage
    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      super
      @message = LtiAdvantage::Messages::ResourceLinkRequest.new
    end

    def generate_post_payload_message(validate_launch: true)
      add_resource_link_request_claims! if include_claims?(:rlid)
      add_assignment_and_grade_service_claims if include_assignment_and_grade_service_claims?
      super(validate_launch: validate_launch)
    end

    def generate_post_payload_for_assignment(assignment, _outcome_service_url, _legacy_outcome_service_url, _lti_turnitin_outcomes_placement_url)
      @assignment = assignment
      generate_post_payload
    end

    def generate_post_payload_for_homework_submission(assignment)
      @assignment = assignment
      generate_post_payload
    end

    private

    def tool_from_tag(tag, context)
      ContextExternalTool.find_external_tool(
        tag.url,
        context,
        tag.content_id
      )
    end

    def add_resource_link_request_claims!
      resource_link = assignment_resource_link
      assignment = line_item_for_assignment&.assignment
      @message.resource_link.id = resource_link&.resource_link_id || context_resource_link_id
      @message.resource_link.description = resource_link && assignment&.description
      @message.resource_link.title = resource_link && assignment&.title
    end

    def unexpanded_custom_parameters
      # Add in link-specific custom params (e.g. created by deep linking)
      super.merge!(resource_link_for_custom_parameters&.custom || {})
    end

    def resource_link_for_custom_parameters
      assignment_resource_link || @opts[:resource_link_for_custom_params]
    end

    def context_resource_link_id
      Lti::Asset.opaque_identifier_for(@context)
    end

    def assignment_resource_link
      return if @assignment.nil?

      unless defined?(@assignment_resource_link)
        launch_error = Lti::Ims::AdvantageErrors::InvalidLaunchError
        unless @assignment.external_tool?
          raise launch_error.new(nil, api_message: 'Assignment not configured for external tool launches')
        end
        unless tool_from_tag(@assignment.external_tool_tag, @context) == @tool
          raise launch_error.new(nil, api_message: 'Assignment not configured for launches with specified tool')
        end

        @assignment_resource_link = line_item_for_assignment&.resource_link
      end

      @assignment_resource_link
    end

    def assignment_line_item_url
      @assignment_line_item_url ||= begin
        line_item = line_item_for_assignment
        return if line_item.blank?
        # assume @context is either Group or Course, per #include_assignment_and_grade_service_claims?
        @expander.controller.lti_line_item_show_url(
          course_id: @context.is_a?(Group) ? context.context_id : @context.id,
          id: line_item.id
        )
      end
    end

    def line_item_for_assignment
      @_line_item ||= @assignment&.line_items&.find(&:assignment_line_item?)
    end

    def include_assignment_and_grade_service_claims?
      include_claims?(:assignment_and_grade_service) &&
        (@context.is_a?(Course) || @context.is_a?(Group)) &&
        (@tool.developer_key.scopes & TokenScopes::LTI_AGS_SCOPES).present?
    end

    def add_assignment_and_grade_service_claims
      @message.assignment_and_grade_service.scope = @tool.developer_key.scopes & TokenScopes::LTI_AGS_SCOPES
      @message.assignment_and_grade_service.lineitems = line_items_url
      # line_item_url won't exist except when launching an assignment, but nested claims dont get compacted on
      # serialization, so explicit logic here to skip attr set
      ali_url = assignment_line_item_url
      @message.assignment_and_grade_service.lineitem = ali_url if ali_url.present?
    end

    def line_items_url
      # assume @context is either Group or Course, per #include_assignment_and_grade_service_claims?
      @expander.controller.lti_line_item_index_url(course_id: @context.is_a?(Group) ? @context.context_id : @context.id)
    end
  end
end
