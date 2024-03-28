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

require "lti_advantage"

module Lti::Messages
  # Base class for all LTI Message "factory" classes.
  #
  # This class, and it's child classes, are responsible
  # for constructing and ID token suitable for LTI 1.3
  # authentication responses (LTI launches).
  #
  # These class have counterparts for simply modeling the
  # data  at "gems/lti-advantage/lib/lti_advantage/messages".
  #
  # For details on the data included in the ID token please refer
  # to http://www.imsglobal.org/spec/lti/v1p3/.
  #
  # For implementation details on LTI Advantage launches in
  # Canvas, please see the inline documentation of
  # app/models/lti/lti_advantage_adapter.rb.
  class JwtMessage
    EXTENSION_PREFIX = "https://www.instructure.com/"

    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      @tool = tool
      @context = context
      @user = user
      @opts = opts
      @expander = expander
      @return_url = return_url
      @message = LtiAdvantage::Messages::JwtMessage.new
      @used = false
    end

    def self.generate_id_token(body)
      { id_token: LtiAdvantage::Messages::JwtMessage.create_jws(body, Lti::KeyStorage.present_key) }
    end

    def generate_post_payload_message(validate_launch: true)
      raise "Class can only be used once." if @used

      @used = true

      add_security_claims! if include_claims?(:security)
      add_public_claims! if @tool.public? && include_claims?(:public)
      add_mentorship_claims! if @tool.public? && include_claims?(:mentorship)
      add_include_email_claims! if @tool.include_email? && include_claims?(:email)
      add_include_name_claims! if @tool.include_name? && include_claims?(:name)
      add_context_claims! if include_claims?(:context)
      add_tool_platform_claims! if include_claims?(:tool_platform)
      add_launch_presentation_claims! if include_claims?(:launch_presentation)
      add_i18n_claims! if include_claims?(:i18n)
      add_roles_claims! if include_claims?(:roles)
      add_custom_params_claims! if include_claims?(:custom_params)
      add_assignment_and_grade_service_claims! if include_assignment_and_grade_service_claims?
      add_names_and_roles_service_claims! if include_names_and_roles_service_claims?
      add_lti11_legacy_user_id!
      add_lti1p1_claims! if include_lti1p1_claims?
      add_extension("placement", @opts[:resource_type])
      add_extension("lti_student_id", @opts[:student_id].to_s) if @opts[:student_id].present?

      @expander.expand_variables!(@message.extensions)
      @message.validate! if validate_launch
      @message
    end

    def generate_post_payload
      generate_post_payload_message.to_h
    end

    private

    def add_security_claims!
      @message.aud = @tool.developer_key.global_id.to_s
      @message.azp = @tool.developer_key.global_id.to_s
      @message.deployment_id = @tool.deployment_id
      @message.exp = 1.hour.from_now.to_i
      @message.iat = Time.zone.now.to_i
      @message.iss = Canvas::Security.config["lti_iss"]
      @message.nonce = SecureRandom.uuid
      @message.sub = @user&.lookup_lti_id(@context) if include_sub_claim?
      @message.target_link_uri = target_link_uri
    end

    def include_sub_claim?
      @user.present?
    end

    def target_link_uri
      @opts[:target_link_uri].presence ||
        @tool.extension_setting(@opts[:resource_type], :target_link_uri).presence ||
        @tool.url
    end

    def add_context_claims!
      @message.context.id = Lti::Asset.opaque_identifier_for(@context)
      @message.context.label = @context.course_code if @context.respond_to?(:course_code)
      @message.context.title = @context.name
      @message.context.type = [Lti::SubstitutionsHelper::LIS_V2_ROLE_MAP[@context.class] || @context.class.to_s]
    end

    def add_tool_platform_claims!
      @message.tool_platform.guid = @context.root_account.lti_guid
      @message.tool_platform.name = @context.root_account.name
      @message.tool_platform.version = "cloud"
      @message.tool_platform.product_family_code = "canvas"
    end

    def add_launch_presentation_claims!
      @message.launch_presentation.document_target = "iframe"
      @message.launch_presentation.return_url = @return_url
      @message.launch_presentation.locale = I18n.locale || I18n.default_locale.to_s

      content_tag_link_settings = @expander.content_tag&.link_settings
      height = content_tag_link_settings&.dig("selection_height")&.to_s&.gsub(/px$/, "").presence || @tool.extension_setting(@opts[:resource_type], :selection_height) || @tool.settings[:selection_height]
      width = content_tag_link_settings&.dig("selection_width")&.to_s&.gsub(/px$/, "").presence || @tool.extension_setting(@opts[:resource_type], :selection_width) || @tool.settings[:selection_width]
      @message.launch_presentation.height = height.to_i if height.present?
      @message.launch_presentation.width = width.to_i if width.present?
    end

    def add_i18n_claims!
      # Repeated as @message.launch_presentation.locale above. Separated b/c often want one or the other but not both,
      # e.g. NRPS v2 only wants this one and none of the launch_presention fields.
      @message.locale = I18n.locale || I18n.default_locale.to_s
    end

    def add_roles_claims!
      @message.roles = expand_variable("$com.instructure.User.allRoles").split ","
    end

    def add_custom_params_claims!
      @message.custom = custom_parameters
    end

    def add_include_name_claims!
      @message.name = @user&.name
      @message.given_name = @user&.first_name
      @message.family_name = @user&.last_name
      @message.lis.person_sourcedid = expand_variable("$Person.sourcedId")
      @message.lis.course_offering_sourcedid = expand_variable("$CourseSection.sourcedId")
    end

    def add_include_email_claims!
      @message.email = @user&.email
    end

    def add_public_claims!
      @message.picture = @user&.avatar_url
    end

    def add_mentorship_claims!
      @message.role_scope_mentor = current_observee_list if current_observee_list.present?
    end

    def add_lti11_legacy_user_id!
      @message.lti11_legacy_user_id = @tool.opaque_identifier_for(@user) || ""
    end

    def add_lti1p1_claims!
      @message.lti1p1.user_id = @user&.lti_context_id
      if associated_1_1_tool.present?
        @message.lti1p1.oauth_consumer_key = associated_1_1_tool.consumer_key
        @message.lti1p1.oauth_consumer_key_sign = Lti::Helpers::JwtMessageHelper.generate_oauth_consumer_key_sign(associated_1_1_tool, @message)
      end
    end

    # Following the spec https://www.imsglobal.org/spec/lti/v1p3/migr#remapping-parameters
    # If the parameter's value is not the same as its LTI 1.3 equivalent, the
    # platform MUST include the parameter and its LTI 1.1 value. Otherwise the
    # platform MAY omit that attribute.
    def include_lti1p1_claims?
      user_ids_differ = @user&.lti_context_id && @user.lti_context_id != @user.lti_id

      user_ids_differ || associated_1_1_tool.present?
    end

    # Follows the spec at https://www.imsglobal.org/spec/lti-ags/v2p0/#assignment-and-grade-service-claim
    # and only adds this claim if the tool has the right scopes, and not for account-level launches.
    def include_assignment_and_grade_service_claims?
      include_claims?(:assignment_and_grade_service) &&
        (@context.is_a?(Course) || @context.is_a?(Group)) &&
        @tool.developer_key.scopes.intersect?(TokenScopes::LTI_AGS_SCOPES)
    end

    # Follows the spec at https://www.imsglobal.org/spec/lti-ags/v2p0/#assignment-and-grade-service-claim
    # see ResourceLinkRequest#add_line_item_url_to_ags_claim! for adding the 'lineitem' properties
    def add_assignment_and_grade_service_claims!
      @message.assignment_and_grade_service.scope = @tool.developer_key.scopes & TokenScopes::LTI_AGS_SCOPES

      @message.assignment_and_grade_service.lineitems =
        @expander.controller.lti_line_item_index_url(
          host: @context.root_account.environment_specific_domain, course_id: course_id_for_ags_url
        )
    end

    def associated_1_1_tool
      return nil unless Account.site_admin.feature_enabled?(:include_oauth_consumer_key_in_lti_launch)

      @associated_1_1_tool ||= @tool&.associated_1_1_tool(@context, target_link_uri)
    end

    # Used to construct URLs for AGS endpoints like line item index, or line item show
    # assumes @context is either Group or Course, per #include_assignment_and_grade_service_claims?
    def course_id_for_ags_url
      @context.is_a?(Group) ? @context.context_id : @context.id
    end

    def include_names_and_roles_service_claims?
      include_claims?(:names_and_roles_service) &&
        (@context.is_a?(Course) || @context.is_a?(Group)) &&
        @tool.developer_key&.scopes&.include?(TokenScopes::LTI_NRPS_V2_SCOPE)
    end

    def add_names_and_roles_service_claims!
      @message.names_and_roles_service.context_memberships_url =
        @expander.controller.polymorphic_url(
          [@context, :names_and_roles],
          host: @context.root_account.environment_specific_domain
        )
      @message.names_and_roles_service.service_versions = ["2.0"]
    end

    def expand_variable(variable)
      @expander.expand_variables!({ value: variable })[:value]
    end

    def current_observee_list
      return nil unless @context.is_a?(Course)
      return nil if @user.blank?

      @_current_observee_list ||= @user.observer_enrollments.current
                                       .where(course_id: @context.id)
                                       .preload(:associated_user)
                                       .filter_map { |e| e.try(:associated_user).try(:lti_id) }
    end

    def custom_parameters
      @expander.expand_variables!(unexpanded_custom_parameters)
    end

    def unexpanded_custom_parameters
      @tool.set_custom_fields(@opts[:resource_type]).transform_keys do |k|
        key = k.dup
        key.slice! "custom_"
        key
      end
    end

    def include_claims?(claim_group)
      Lti::AppUtil.allowed?(claim_group, @opts[:claim_group_whitelist], @opts[:claim_group_blacklist])
    end

    def include_extension?(extension_name)
      Lti::AppUtil.allowed?(extension_name, @opts[:extension_whitelist], @opts[:extension_blacklist])
    end

    protected

    def add_extension(key, value)
      return unless include_extension?(key.to_sym)

      @message.extensions["#{JwtMessage::EXTENSION_PREFIX}#{key}"] = value
    end
  end
end
