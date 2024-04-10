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

module Lti
  # Responsible for generating parameters for both Login requests
  # and Authentication Responses (ID token).
  #
  # This class serves a similar purpose to LtiOutboundAdapter
  # (and exposes the same interface), but is only
  # used for LTI 1.3. LtiOutboundAdapter is used only for LTI 1.x.
  #
  # Please refer to the following IMS specification sections:
  # - https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login
  # - http://www.imsglobal.org/spec/lti/v1p3/#additional-login-parameters
  #
  # LtiAdvantageAdapter offers various methods that provide
  # context-tailored parameters for login requests and authentication
  # responses:
  #   - generate_post_payload_for_assignment
  #   - generate_post_payload_for_homework_submission
  #   - generate_post_payload
  #
  # These are the primary methods used to interface with
  # LtiAdvantageAdapter from external classes. A brief
  # overview of each can be found in method-specific
  # documentation.
  #
  # In general, the formation of the login request (and later
  # authentication response) is handled in the following way:
  #
  # 1. Generate the complete, signed id_token that will be sent
  #    in the authentication response from Canvas to the tool.
  # 2. Create a random cache key, and store the id_token in
  #    cache for later retrieval if authentication with the
  #    the tool succeeds.
  # 3. Include the cache key as the "lti_message_hint" parameter
  #    in the login request. This value is passed back to Canvas
  #    By the tool in the authentication request (handled by
  #    app/controllers/lti/ims/authentication_controller.rb#authorize).
  #
  # For information on how the cached ID token is eventually retrieved
  # and sent to a tool, please refer to the inline documentation of
  # app/controllers/lti/ims/authentication_controller.rb
  class LtiAdvantageAdapter
    MESSAGE_HINT_LIFESPAN = 5.minutes

    include Lti::RedisMessageClient

    def initialize(tool:, user:, context:, return_url:, expander:, opts:, include_storage_target: true)
      @tool = tool
      @user = user
      @context = context
      @return_url = return_url
      @expander = expander
      @opts = opts
      @target_link_uri = opts[:launch_url]
      @include_storage_target = include_storage_target
    end

    # Generates a login request pointing to a cached launch (ID token)
    # suitable for assignment LTI launches.
    #
    # This ensures, for example, that Assignment and Grade services
    # parameters are included in the cached launch.
    #
    # See method-level documentation of "generate_post_payload" for
    # more details.
    #
    # For information on how the cached ID token is eventually retrieved
    # and sent to a tool, please refer to the inline documentation of
    # app/controllers/lti/ims/authentication_controller.rb
    def generate_post_payload_for_assignment(*args)
      login_request(resource_link_request.generate_post_payload_for_assignment(*args))
    end

    # Generates a login request pointing to a cached launch (ID token)
    # suitable for submission LTI launches.
    #
    # These launches occur when a student launches a tool with
    # the intent of selecting some document or link that will
    # be used as their submission for an assignment.
    #
    # See method-level documentation of "generate_post_payload" for
    # more details.
    #
    # For information on how the cached ID token is eventually retrieved
    # and sent to a tool, please refer to the inline documentation of
    # app/controllers/lti/ims/authentication_controller.rb
    def generate_post_payload_for_homework_submission(*args)
      login_request(resource_link_request.generate_post_payload_for_homework_submission(*args))
    end

    # Generates a login request pointing to a cached launch (ID token)
    # suitable for student context card LTI launches.
    #
    # These launches occur when a teacher launches a tool from the
    # student context card, which shows when clicking on the name
    # from the gradebook or course user list.
    #
    # See method-level documentation of "generate_post_payload" for
    # more details.
    #
    # For information on how the cached ID token is eventually retrieved
    # and sent to a tool, please refer to the inline documentation of
    # app/controllers/lti/ims/authentication_controller.rb
    def generate_post_payload_for_student_context_card(student_id:)
      @opts[:student_id] = student_id
      login_request(resource_link_request.generate_post_payload)
    end

    # Generates a login request pointing to a general-use
    # cached launch (ID token).
    #
    # This method, along with all other "generate_post_payload_for_*"
    # methods, generates a login request in the following way:
    #
    # 1. Determine what the message type should be. For now this
    #    is always either "LtiResourceLinkRequest" or "DeepLinkingRequest".
    #    Default to "LtiResourceLink" if the requested message type is
    #    not recognized.
    # 2. Invoke the constructor for the "factory" class that builds
    #    the requested message type. At the time of writing, these
    #    classes live in "lib/lti/messages".
    # 3. Cache the ID token returned from the factory class (this is a
    #    signed JWT, so always a string)
    # 4. Construct the login request parameters with a lti_message_hint
    #    that points to the cached ID token.
    #
    # Please refer to the following IMS specification sections:
    # - https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login
    # - http://www.imsglobal.org/spec/lti/v1p3/#additional-login-parameters
    #
    # For information on how the cached ID token is eventually retrieved
    # and sent to a tool, please refer to the inline documentation of
    # app/controllers/lti/ims/authentication_controller.rb
    def generate_post_payload
      login_request(generate_lti_params)
    end

    def launch_url
      @tool.login_or_launch_url(extension_type: resource_type)
    end

    private

    def target_link_uri
      return @target_link_uri if @target_link_uri.present?

      resource_type ? @tool.extension_setting(resource_type, :target_link_uri) : @tool.url
    end

    def generate_lti_params
      if resource_type&.to_sym == :course_assignments_menu &&
         !@context.root_account.feature_enabled?(:lti_multiple_assignment_deep_linking)
        return resource_link_request.generate_post_payload
      end

      if resource_type&.to_sym == :module_index_menu_modal &&
         !@context.root_account.feature_enabled?(:lti_deep_linking_module_index_menu_modal)
        return resource_link_request.generate_post_payload
      end

      message_type = @tool.extension_setting(resource_type, :message_type)
      if message_type == LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE
        deep_linking_request.generate_post_payload
      else
        resource_link_request.generate_post_payload
      end
    end

    def login_request(lti_params)
      message_hint = cache_payload(lti_params)
      login_hint = Lti::Asset.opaque_identifier_for(@user, context: @context) || User.public_lti_id

      req = LtiAdvantage::Messages::LoginRequest.new(
        iss: Canvas::Security.config["lti_iss"],
        login_hint:,
        client_id: @tool.global_developer_key_id,
        deployment_id: @tool.deployment_id,
        target_link_uri:,
        lti_message_hint: message_hint,
        canvas_environment: ApplicationController.test_cluster_name || "prod",
        canvas_region: @context.shard.database_server.config[:region] || "not_configured"
      )
      req.lti_storage_target = Lti::PlatformStorage::FORWARDING_TARGET if @include_storage_target
      req.as_json
    end

    def cache_payload(lti_params)
      verifier = cache_launch(lti_params, @context)
      Canvas::Security.create_jwt(
        {
          verifier:,
          canvas_domain: @opts[:domain],
          context_type: @context.class,
          context_id: @context.global_id,
          canvas_locale: I18n.locale || I18n.default_locale.to_s,
          parent_frame_context: @opts[:parent_frame_context],
          include_storage_target: @include_storage_target
        }.compact,
        (Time.zone.now + MESSAGE_HINT_LIFESPAN)
      )
    end

    def deep_linking_request
      Lti::Messages::DeepLinkingRequest.new(
        tool: @tool,
        context: @context,
        user: @user,
        expander: @expander,
        return_url: @return_url,
        opts: @opts.merge(option_overrides)
      )
    end

    def resource_link_request
      @_resource_link_request ||= Lti::Messages::ResourceLinkRequest.new(
        tool: @tool,
        context: @context,
        user: @user,
        expander: @expander,
        return_url: @return_url,
        opts: @opts.merge(option_overrides)
      )
    end

    def option_overrides
      {
        target_link_uri:
      }
    end

    def resource_type
      @opts[:resource_type]
    end
  end
end
