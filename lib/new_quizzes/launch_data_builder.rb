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
    def initialize(context:, assignment:, tool:, current_user:, request:)
      @context = context
      @assignment = assignment
      @tool = tool
      @current_user = current_user
      @request = request
    end

    def build
      {
        # Canvas instance
        custom_canvas_api_domain: @request.host,

        # LTI Resource Link ID
        lti_resource_link_id: resource_link_id,

        # Assignment context
        custom_canvas_assignment_id: @assignment.id,
        custom_canvas_assignment_title: @assignment.title,
        custom_canvas_assignment_due_at: @assignment.due_at&.iso8601,
        custom_canvas_assignment_unlock_at: @assignment.unlock_at&.iso8601,
        custom_canvas_assignment_lock_at: @assignment.lock_at&.iso8601,
        custom_canvas_assignment_points_possible: @assignment.points_possible,
        custom_canvas_assignment_anonymous_grading: @assignment.anonymous_grading?,
        custom_canvas_assignment_omit_from_final_grade: @assignment.omit_from_final_grade,
        custom_canvas_assignment_hide_in_gradebook: @assignment.hide_in_gradebook?,
        custom_canvas_assignment_restrict_quantitative_data: restrict_quantitative_data?,
        custom_canvas_assignment_ldb_enabled: @assignment.settings&.dig("lockdown_browser", "require_lockdown_browser") || false,

        # Course context
        custom_canvas_course_id: @context.id,
        custom_canvas_course_uuid: @context.uuid,
        custom_canvas_course_workflow_state: @context.workflow_state,
        custom_canvas_course_grading_scheme: grading_scheme,
        custom_canvas_course_ai_quiz_generation: ai_quiz_generation_enabled?,
        context_title: @context.name,
        context_label: @context.course_code,

        # User context
        custom_canvas_user_id: @current_user.id,
        custom_canvas_user_uuid: @current_user.uuid,
        custom_canvas_user_login_id: @current_user.pseudonyms&.first&.unique_id,
        custom_canvas_user_current_uuid: @current_user.uuid,
        custom_canvas_user_student_view: @current_user.fake_student?,
        lis_person_name_full: @current_user.name,
        lis_person_name_given: @current_user.first_name,
        lis_person_name_family: @current_user.last_name,
        lis_person_contact_email_primary: @current_user.email,
        user_image: @current_user.avatar_url,

        # Context identifiers
        custom_canvas_context_uuid: @context.uuid,
        custom_canvas_global_context_id: @context.global_id,

        # Tool context
        custom_canvas_tool_id: @tool&.global_id,

        # Enrollment and permissions
        custom_canvas_enrollment_state: enrollment_state,
        custom_canvas_permissions: permissions,
        roles:,
        ext_roles:,

        # Rich Content Service
        custom_canvas_rcs_host: rcs_host,
        custom_canvas_rcs_service_jwt: rcs_jwt,

        # Locale and formatting
        custom_canvas_timezone_name: @current_user.time_zone&.name,
        custom_canvas_high_contrast_setting: @current_user.prefers_high_contrast?,
        custom_canvas_decimal_separator: decimal_separator,
        custom_canvas_thousand_separator: thousand_separator,
        custom_canvas_instui_nav: @context.root_account.feature_enabled?(:instui_nav),

        # Usage metrics
        custom_usage_metrics_enabled: usage_metrics_enabled?,

        # Module context (if launched from module)
        custom_canvas_module_id: module_id,
        custom_canvas_module_item_id: module_item_id,

        # Backend URL - extracted from the tool's launch URL
        # This allows the native app to connect to the correct tenant-specific backend
        backend_url:,
      }.compact # Remove nil values
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
      # Get the LTI resource link ID from the assignment's line items
      # This matches what Canvas sends in LTI 1.3 launches
      # Fallback to lti_context_id which is the assignment's unique LTI identifier
      if @assignment.submission_types == "external_tool" && @assignment.line_items.present?
        @assignment.line_items.first&.resource_link&.resource_link_uuid
      else
        @assignment.lti_context_id
      end
    end

    def restrict_quantitative_data?
      # Convert to string to match LTI variable expander behavior
      @assignment.restrict_quantitative_data?(@current_user)&.to_s
    end

    def grading_scheme
      # Use grading_standard_or_default to match LTI behavior
      # This always returns a scheme (default if no custom scheme is set)
      grading_standard = @context.grading_standard_or_default

      # The .data attribute contains the grading scheme as an array of [name, value] pairs
      grading_standard.data.map do |grading_standard_data_row|
        { name: grading_standard_data_row[0], value: grading_standard_data_row[1] }
      end.to_json
    end

    def ai_quiz_generation_enabled?
      @context.feature_enabled?(:new_quizzes_ai_quiz_generation)
    end

    def enrollment_state
      enrollment = @context.enrollments.where(user_id: @current_user).active.first
      enrollment&.workflow_state || "active"
    end

    def permissions
      # New Quizzes specific permissions
      permission_list = %w[
        manage_account_banks
        share_banks_with_subaccounts
        read_sis
        manage_sis
        new_quizzes_view_ip_address
        new_quizzes_multiple_session_detection
      ]

      granted = permission_list.select do |permission|
        @context.grants_right?(@current_user, permission.to_sym)
      end

      granted.join(",")
    end

    def roles
      # Generate LTI context roles (matches traditional LTI launch behavior)
      # Returns comma-separated role strings based on user's enrollments and account roles
      # This mirrors the logic in Lti::SubstitutionsHelper#current_lis_roles

      # Get course enrollments
      course_enrollments = @context.enrollments.where(user_id: @current_user).active
      course_roles = course_enrollments.filter_map do |enrollment|
        Lti::LtiUserCreator::ENROLLMENT_MAP[enrollment.class]
      end

      # Get account enrollments (for account admins)
      account_enrollments = if @context.respond_to?(:account_chain) && !@context.account_chain.empty?
                              @current_user.account_users.active
                                           .where(account_id: @context.account_chain)
                                           .distinct
                                           .to_a
                            else
                              []
                            end

      account_roles = account_enrollments.map do
        Lti::LtiUserCreator::ENROLLMENT_MAP[AccountUser]
      end

      # Combine course and account roles
      all_roles = course_roles + account_roles

      # Add site admin role if applicable (matches traditional LTI behavior)
      # Site admins get the System-level SysAdmin role, not Institution Administrator
      if Account.site_admin.account_users_for(@current_user).present?
        all_roles << LtiOutbound::LTIRoles::System::SYS_ADMIN
      end

      # Deduplicate roles and return comma-separated string or NONE if no roles found
      all_roles.uniq.join(",").presence || LtiOutbound::LTIRoles::System::NONE
    end

    def ext_roles
      # Generate LTI ext_roles (all user roles as URNs)
      # Use the LTI substitutions helper to generate role URNs
      helper = Lti::SubstitutionsHelper.new(@context, @context.root_account, @current_user, @tool)
      helper.all_roles # Returns LIS 1.0 format role URNs
    end

    def rcs_host
      # Rich Content Service host configuration
      # Use Services::RichContent to get the configured host, same as LTI
      rcs_env[:RICH_CONTENT_APP_HOST]
    end

    def rcs_jwt
      # Generate RCS service JWT using the same method as LTI launches
      # This ensures consistency with the LTI variable expander
      rcs_env[:JWT]
    end

    def rcs_env
      # Get RCS environment data (host and JWT) the same way as LTI launches
      @rcs_env ||= Services::RichContent.env_for(
        user: @current_user,
        domain: @request.host_with_port,
        real_user: nil, # Not available in native launch context
        context: @context
      )
    end

    def decimal_separator
      return nil unless Account.site_admin.feature_enabled?(:new_quizzes_separators)

      @context.account&.settings&.dig(:decimal_separator, :value) ||
        @context.root_account.settings&.dig(:decimal_separator, :value)
    end

    def thousand_separator
      return nil unless Account.site_admin.feature_enabled?(:new_quizzes_separators)

      @context.account&.settings&.dig(:thousand_separator, :value) ||
        @context.root_account.settings&.dig(:thousand_separator, :value)
    end

    def usage_metrics_enabled?
      @context.root_account.feature_enabled?(:send_usage_metrics)
    end

    def module_id
      return nil unless module_item_id

      ContentTag.find_by(id: module_item_id)&.context_module_id
    end

    def module_item_id
      # Extract from request params if launched from module
      @request.params[:module_item_id]
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
      signing_secret = tool_shared_secret

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
      URI.encode_www_form(params.sort.map do |k, v|
        value = (v.is_a?(Float) && v == v.to_i) ? v.to_i : v
        [k, value]
      end)
    end

    # Gets the tool's shared secret from the ContextExternalTool
    # This is the same secret used for LTI OAuth signature verification
    def tool_shared_secret
      @tool&.shared_secret
    end
  end
end
