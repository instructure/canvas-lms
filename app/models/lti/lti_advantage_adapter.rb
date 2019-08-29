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

module Lti
  class LtiAdvantageAdapter
    MESSAGE_HINT_LIFESPAN = 5.minutes

    include Lti::RedisMessageClient

    def initialize(tool:, user:, context:, return_url:, expander:, opts:)
      @tool = tool
      @user = user
      @context = context
      @return_url = return_url
      @expander = expander
      @opts = opts
      @target_link_uri = opts[:launch_url]
    end

    def generate_post_payload_for_assignment(*args)
      login_request(resource_link_request.generate_post_payload_for_assignment(*args))
    end

    def generate_post_payload_for_homework_submission(*args)
      login_request(resource_link_request.generate_post_payload_for_homework_submission(*args))
    end

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
      message_type = @tool.extension_setting(resource_type, :message_type)
      if message_type == LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE
        deep_linking_request.generate_post_payload
      else
        resource_link_request.generate_post_payload
      end
    end

    def login_request(lti_params)
      message_hint = cache_payload(lti_params)
      LtiAdvantage::Messages::LoginRequest.new(
        iss: Canvas::Security.config['lti_iss'],
        login_hint: Lti::Asset.opaque_identifier_for(@user, context: @context),
        client_id: @tool.global_developer_key_id,
        target_link_uri: target_link_uri,
        lti_message_hint: message_hint,
        canvas_region: @context.shard.database_server.config[:region] || 'not_configured'
      ).as_json
    end

    def cache_payload(lti_params)
      verifier = cache_launch(lti_params, @context)
      Canvas::Security.create_jwt(
        {
          verifier: verifier,
          canvas_domain: @opts[:domain],
          context_type: @context.class,
          context_id: @context.global_id
        },
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
      @_resource_link_request ||= begin
        Lti::Messages::ResourceLinkRequest.new(
          tool: @tool,
          context: @context,
          user: @user,
          expander: @expander,
          return_url: @return_url,
          opts: @opts.merge(option_overrides)
        )
      end
    end

    def option_overrides
      {
        target_link_uri: target_link_uri
      }
    end

    def resource_type
      @opts[:resource_type]
    end
  end
end
