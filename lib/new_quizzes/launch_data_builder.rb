# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# Builds the launch data for New Quizzes native launches
# This data structure matches what was previously sent via LTI custom_params
# Used to populate JS_ENV for the federated app
module NewQuizzes
  class LaunchDataBuilder
    def initialize(context:, assignment:, tool:, tag:, current_user:, controller:, request:, variable_expander:, placement: nil)
      @context = context
      @assignment = assignment
      @tool = tool
      @tag = tag
      @current_user = current_user
      @controller = controller
      @request = request
      @variable_expander = variable_expander
      @placement = placement # e.g., "course_navigation", "account_navigation" for Item Banks
    end

    def build
      base_params = build_base_params
      custom_params = build_custom_params

      base_params.merge(custom_params).compact
    end

    def build_base_params
      # Get standard LIS parameters from variable expander
      standard_params = @variable_expander.enabled_capability_params([
                                                                       "Context.id",
                                                                       "Context.title",
                                                                       "com.instructure.contextLabel",
                                                                       "Person.name.full",
                                                                       "Person.name.given",
                                                                       "Person.name.family",
                                                                       "Person.email.primary",
                                                                       "User.image",
                                                                       "Message.locale",
                                                                     ])

      params = {
        # Non-custom params that are always included
        backend_url:,
        roles:,
        ext_roles:,

        # Tool consumer information
        tool_consumer_info_product_family_code: "canvas",
        tool_consumer_info_version: "cloud",
        tool_consumer_instance_guid: @context.root_account.lti_guid,
        tool_consumer_instance_name: @context.root_account.name,

        # Parameters not included in VariableExpander
        resource_link_id:,
        resource_link_title:,
        launch_presentation_return_url: return_url
      }.merge(standard_params)

      # Assignment-specific outcome service parameters
      if @assignment
        # Only include result sourcedid for learners
        if learner?
          params[:lis_result_sourcedid] = encode_source_id(@assignment)
        end

        # Outcome service URLs
        params[:lis_outcome_service_url] = outcome_service_url
        params[:ext_ims_lis_basic_outcome_url] = legacy_outcome_service_url

        # Basic outcomes extensions
        lti_assignment = Lti::LtiAssignmentCreator.new(@assignment).convert
        return_types = lti_assignment.return_types
        params[:ext_outcome_data_values_accepted] = (return_types.is_a?(Proc) ? return_types.call : return_types).join(",")
        params[:ext_outcome_result_total_score_accepted] = true
        params[:ext_outcome_submission_submitted_at_accepted] = true
        params[:ext_outcome_submission_needs_additional_review_accepted] = true
        params[:ext_outcome_submission_prioritize_non_tool_grade_accepted] = true

        # Turnitin outcomes placement URL
        params[:ext_outcomes_tool_placement_url] = lti_turnitin_outcomes_placement_url if lti_turnitin_outcomes_placement_url
      end

      params
    end

    def build_custom_params
      return {} unless @tool

      # Get unexpanded custom fields from tool
      # Pass placement to include placement-specific custom fields (e.g., item_banks: course)
      unexpanded_fields = @tool.set_custom_fields(@placement)

      # Add Canvas-specific custom parameters that need variable expansion
      # Match LTI 1.1 behavior based on context type
      case @context
      when Course
        unexpanded_fields["custom_canvas_workflow_state"] = "$Canvas.course.workflowState"
      when Account
        unexpanded_fields["custom_canvas_account_id"] = "$Canvas.account.id"
        unexpanded_fields["custom_canvas_account_sis_id"] = "$Canvas.account.sisSourceId"
      end

      # Expand all variables
      @variable_expander.expand_variables!(unexpanded_fields)
    end

    # Builds launch data with HMAC signature for tamper protection
    # Returns: { params: {...}, signature: "base64-encoded-signature" }
    def build_with_signature
      params = build
      {
        params:,
        signature: sign_params(params)
      }
    end

    private

    def resource_link_id
      raise "Tool is required for resource_link_id" unless @tool

      # For item banks and other navigation launches, there's no tag
      # In that case, use the context as the resource link identifier
      @tool.opaque_identifier_for(@tag || @context)
    end

    def resource_link_title
      # Match LTI 1.1 behavior: use assignment title if available, otherwise tag title, otherwise tool name
      if @assignment
        @assignment.title
      elsif @tag
        @tag.title
      else
        @tool.name
      end
    end

    def return_url
      # Generate return URL - match LTI launch behavior by using set_return_url
      # This intelligently determines the best return URL based on the referer
      # (quizzes page, gradebook, modules, etc.)
      @controller&.set_return_url
    end

    def roles
      # Generate LTI context roles (matches traditional LTI launch behavior)
      # Returns comma-separated role strings based on user's enrollments and account roles
      # Delegates to Lti::SubstitutionsHelper#current_lis_roles for consistency
      substitutions_helper.current_lis_roles
    end

    def ext_roles
      # Generate LTI ext_roles (all user roles as URNs)
      # Use the LTI substitutions helper to generate role URNs
      substitutions_helper.all_roles # Returns LIS 1.0 format role URNs
    end

    def backend_url
      # Extract the backend URL from the tool's launch URL or domain
      # The launch_url typically contains the environment (region-env format)
      # Example: https://account.quiz-lti-region-env.instructure.com/lti/launch
      # We want to extract: https://account.quiz-lti-region-env.instructure.com
      return nil unless @tool

      tool_url = @tool.launch_url
      tool_domain = @tool.domain

      # If we have a URL, parse it to get the origin
      if tool_url.present?
        uri = URI.parse(tool_url)
        base_url = "#{uri.scheme}://#{uri.host}"
        base_url += ":#{uri.port}" if uri.port && uri.port != uri.default_port
        return base_url
      end

      # If we only have a domain (no scheme), assume HTTPS
      if tool_domain.present?
        return "https://#{tool_domain}"
      end

      nil
    rescue URI::InvalidURIError => e
      Rails.logger.error("Failed to parse tool URL for backend_url: #{e.message}")
      nil
    end

    # Signs the launch parameters with HMAC-SHA256 using the tool's shared secret
    # This prevents tampering with the launch data
    def sign_params(params)
      message = canonical_params_string(params)
      signing_secret = @tool&.shared_secret

      unless signing_secret
        Rails.logger.error("Cannot sign params: no shared secret available for tool #{@tool&.id}")
        raise "Missing shared secret for tool"
      end

      # Sign with HMAC-SHA256 and base64 encode
      signature = OpenSSL::HMAC.digest("sha256", signing_secret, message)
      Base64.strict_encode64(signature)
    end

    # Creates a canonical string representation of parameters for consistent signing
    # Uses query-string format with URL encoding to match OAuth standards
    def canonical_params_string(params)
      # Convert all values to strings for consistent sorting and encoding
      normalized_params = params.map do |k, v|
        value = normalize_value(v)
        [k.to_s, value]
      end

      # Sort by key for consistent ordering
      sorted_params = normalized_params.sort_by { |k, _v| k }

      URI.encode_www_form(sorted_params)
    end

    # Normalize parameter values to strings for signing
    def normalize_value(value)
      case value
      when Float
        # Convert floats to integers if they're whole numbers
        (value == value.to_i) ? value.to_i.to_s : value.to_s
      when Array, Hash
        # Convert complex types to JSON strings
        value.to_json
      else
        # Convert booleans, nil, and everything else to strings
        # (nil becomes empty string)
        value.to_s
      end
    end

    # Memoized substitutions helper for role and variable expansion
    def substitutions_helper
      @substitutions_helper ||= Lti::SubstitutionsHelper.new(@context, @context.root_account, @current_user, @tool)
    end

    # Check if current user is a learner (student) in the context
    def learner?
      return false unless @current_user && @context

      @context.enrollments.where(user_id: @current_user).active.any?(StudentEnrollment)
    end

    # Generate outcome service URL for grade passback
    def outcome_service_url
      @controller&.lti_grade_passback_api_url(@tool) if @assignment
    end

    # Generate legacy outcome service URL
    def legacy_outcome_service_url
      @controller&.blti_legacy_grade_passback_api_url(@tool) if @assignment
    end

    # Encode source ID for LTI assignment
    # Delegates to LtiOutboundAdapter for consistency with LTI 1.1 launches
    def encode_source_id(assignment)
      return nil unless assignment && @tool && @context && @current_user

      adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context)
      adapter.encode_source_id(assignment)
    end

    # Generate Turnitin outcomes placement URL
    def lti_turnitin_outcomes_placement_url
      return nil unless @assignment && @context

      # This is only used for Turnitin integrations
      # For New Quizzes, this is typically not needed, but include it for completeness
      @controller&.lti_turnitin_outcomes_placement_url(@tool)
    rescue
      # If the method doesn't exist on controller, return nil
      nil
    end
  end
end
