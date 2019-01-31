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

require 'lti_advantage'

module Lti::Messages
  class JwtMessage
    EXTENSION_PREFIX = 'https://www.instructure.com/'.freeze

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

    def generate_post_payload_message
      raise 'Class can only be used once.' if @used
      @used = true

      add_security_claims! if include_claims?(:security)
      add_public_claims! if @tool.public? && include_claims?(:public)
      add_mentorship_claims! if @tool.public? && include_claims?(:mentorship)
      add_include_email_claims! if @tool.include_email? && include_claims?(:email)
      add_include_name_claims! if @tool.include_name? && include_claims?(:name)
      add_resource_claims! if include_claims?(:resource)
      add_context_claims! if include_claims?(:context)
      add_tool_platform_claims! if include_claims?(:tool_platform)
      add_launch_presentation_claims! if include_claims?(:launch_presentation)
      add_i18n_claims! if include_claims?(:i18n)
      add_roles_claims! if include_claims?(:roles)
      add_custom_params_claims! if include_claims?(:custom_params)
      add_names_and_roles_service_claims! if include_names_and_roles_service_claims?

      @expander.expand_variables!(@message.extensions)
      @message
    end

    def generate_post_payload
      generate_post_payload_message.to_h
    end

    private

    def add_security_claims!
      @message.aud = @tool.developer_key.global_id.to_s
      @message.deployment_id = @tool.deployment_id
      @message.exp = Setting.get('lti.oauth2.access_token.exp', 1.hour).to_i.seconds.from_now.to_i
      @message.iat = Time.zone.now.to_i
      @message.iss = Canvas::Security.config['lti_iss']
      @message.nonce = SecureRandom.uuid
      @message.sub = @user.lti_id
      @message.lti11_legacy_user_id = Lti::Asset.opaque_identifier_for(@user)
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
      @message.tool_platform.version = 'cloud'
      @message.tool_platform.product_family_code = 'canvas'
    end

    def add_launch_presentation_claims!
      @message.launch_presentation.document_target = 'iframe'
      @message.launch_presentation.height = @tool.extension_setting(@opts[:resource_type], :selection_height)
      @message.launch_presentation.width = @tool.extension_setting(@opts[:resource_type], :selection_width)
      @message.launch_presentation.return_url = @return_url
      @message.launch_presentation.locale = I18n.locale || I18n.default_locale.to_s
    end

    def add_i18n_claims!
      # Repeated as @message.launch_presentation.locale above. Separated b/c often want one or the other but not both,
      # e.g. NRPS v2 only wants this one and none of the launch_presention fields.
      @message.locale = I18n.locale || I18n.default_locale.to_s
    end

    def add_roles_claims!
      @message.roles = expand_variable('$com.Instructure.membership.roles').split ','
      add_extension('roles', '$Canvas.xuser.allRoles')
      add_extension('canvas_enrollment_state', '$Canvas.enrollment.enrollmentState')
    end

    def add_custom_params_claims!
      @message.custom = custom_parameters
    end

    def add_include_name_claims!
      @message.name = @user.name
      @message.given_name = @user.first_name
      @message.family_name = @user.last_name
      @message.lis.person_sourcedid = expand_variable('$Person.sourcedId')
      @message.lis.course_offering_sourcedid = expand_variable('$CourseSection.sourcedId')
    end

    def add_include_email_claims!
      @message.email = @user.email
    end

    def add_public_claims!
      @message.picture = @user.avatar_url
      add_extension('canvas_user_id', '$Canvas.user.id')
      add_extension('canvas_user_login_id', '$Canvas.user.loginId')
      add_extension('canvas_api_domain', '$Canvas.api.domain')

      if @context.is_a?(Course)
        add_extension('canvas_course_id', '$Canvas.course.id')
        add_extension('canvas_workflow_state', '$Canvas.course.workflowState')
        add_extension('lis_course_offering_sourcedid', '$CourseSection.sourcedId')
      elsif @context.is_a?(Account)
        add_extension('canvas_account_id', '$Canvas.account.id')
        add_extension('canvas_account_sis_id', '$Canvas.account.sisSourceId')
      end
    end

    def add_mentorship_claims!
      @message.role_scope_mentor = current_observee_list if current_observee_list.present?
    end

    def add_resource_claims!
      resource_type = @opts[:resource_type].to_s
      case resource_type
      when 'editor_button'
        add_extension('selection_directive', 'embed_content')
        add_extension('content_intended_use', 'embed')
        add_extension('content_return_types', 'oembed,lti_launch_url,url,image_url,iframe')
        add_extension('content_return_url', @return_url)
      when 'resource_selection'
        add_extension('selection_directive', 'select_link')
        add_extension('content_intended_use', 'navigation')
        add_extension('content_return_types', 'lti_launch_url')
        add_extension('content_return_url', @return_url)
      when 'homework_submission'
        add_extension('content_intended_use', 'homework')
        add_extension('content_return_url', @return_url)
      when 'migration_selection'
        add_extension('content_intended_use', 'content_package')
        add_extension('content_return_types', 'file')
        add_extension('content_file_extensions', 'zip,imscc')
        add_extension('content_return_url', @return_url)
      end
    end

    def include_names_and_roles_service_claims?
      include_claims?(:names_and_roles_service) &&
        (@context.is_a?(Course) || @context.is_a?(Group)) &&
        @tool.lti_1_3_enabled? &&
        @tool.developer_key&.scopes&.include?(TokenScopes::LTI_NRPS_V2_SCOPE)
    end

    def add_names_and_roles_service_claims!
      @message.names_and_roles_service.context_memberships_url =
        @expander.controller.polymorphic_url([@context, :names_and_roles])
      @message.names_and_roles_service.service_versions = ['2.0']
    end

    def expand_variable(variable)
      @expander.expand_variables!({value: variable})[:value]
    end

    def current_observee_list
      return nil unless @context.is_a?(Course)
      @_current_observee_list ||= begin
        @user.observer_enrollments.current.
          where(course_id: @context.id).
          preload(:associated_user).
          map { |e| e.try(:associated_user).try(:lti_context_id) }.compact
      end
    end

    def custom_parameters
      custom_params_hash = @tool.set_custom_fields(@opts[:resource_type]).transform_keys do |k|
        key = k.dup
        key.slice! 'custom_'
        key
      end
      @expander.expand_variables!(custom_params_hash)
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
