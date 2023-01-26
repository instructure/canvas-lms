# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module Lti
  # Provides a page to be loaded in an invisible iframe alongside LTI launches
  # for tools to send postMessages to the OIDC Auth domain instead of the
  # current Canvas domain. This is part of the LTI Platform Storage spec,
  # which allows tools to securely launch in browsers like Safari, and store
  # key/value data in Canvas' localstorage.
  #
  # For ease of rendering this sibling iframe alongside the LTI launch iframe,
  # this iframe initially has a src of `current_domain\post_message_forwarding`
  # which this controller will HTTP redirect to the needed src of
  # `OIDC_domain\post_message_forwarding?token=<JWT>`. The JWT contains the
  # original current_domain so that postMessages can be proxied from
  # Canvas to tool.
  #
  # Other references:
  # * standard postMessage listener: ui/shared/lti/jquery/messages.js
  # * forwarding listener: ui/features/post_message_forwarding/index.ts
  # * postMessage docs: doc/api/lti_window_post_message.md
  class PlatformStorageController < ApplicationController
    after_action :set_extra_csp_frame_ancestor!

    def post_message_forwarding
      unless Lti::PlatformStorage.flag_enabled?
        render status: :not_found
        return
      end

      unless current_domain == forwarding_domain
        redirect_to "#{forwarding_domain}/post_message_forwarding?token=#{create_jwt}"
        return
      end

      js_env({ PARENT_DOMAIN: parent_domain })

      render layout: "bare"
    end

    # Allow iframe loading for a domain that is different than the already listed
    # frame-ancestors from application_controller#set_response_headers.
    #
    # Example for production:
    #   normal request to `school.instructure.com`
    #     Content-Security-Policy: frame-ancestors 'self' school.instructure.com vanity.school.edu ... ;
    #   after redirect to `canvas.instructure.com`
    #     Content-Security-Policy: frame-ancestors 'self' canvas.instructure.com ... school.instructure.com;
    #
    # Adding `school.instructure.com` allows the main Canvas window (showing `school.instructure.com`) to
    # load an iframe that points to `canvas.instructure.com`
    #
    # TODO: this doesn't account for accounts that have the CSP enabled, since that adds `frame-src ...;`,
    # which means this will add the parent domain to both -ancestors and -src.
    # TODO: is there a way to achieve this same result using frame-src <forwarding domain>? Since that
    # is already added when an account turns on the CSP, it may be easier. but what to do for accounts
    # that have it off (which is the majority)
    # TODO: resolve these above TODOs before enabling the lti_platform_storage flag (see INTEROP-7714)

    def set_extra_csp_frame_ancestor!
      csp_frame_ancestors << URI.parse(parent_domain)&.host
    end

    # Per the LTI Platform Storage spec, postMessages from tools to get and put data
    # must be sent to the OIDC Auth domain.
    #   For most environments, that is the same as the `iss` value sent in the LTI 1.3 launch.
    #   For local development, that will normally be the main domain unless an override is set.
    def forwarding_domain
      if Rails.env.development?
        return forwarding_domain_override if forwarding_domain_override

        return request.base_url
      end

      # TODO: this will eventually need to change to match the LTI OIDC Auth redirect endpoint.
      # That is currently the same as the iss (`canvas.instructure.com`), but at some point will
      # need to be changed to `sso.canvaslms.com`, while leaving the iss with its original value.
      # see INTEROP-7715
      CanvasSecurity.config["lti_iss"]
    end

    # For local development
    # Set this value in `config/dynamic_settings.yml` under
    # development.config.canvas.canvas.lti_post_message_forwarding_domain
    # An example:
    #   Set this value to `canvas.docker`
    #   Render this route at `shard2.canvas.docker` or another local domain
    #   This route should redirect to `canvas.docker`
    def forwarding_domain_override
      DynamicSettings.find("canvas")["lti_post_message_forwarding_domain"]
    end

    def parent_domain
      decoded_jwt["parent_domain"] || request.base_url
    end

    def current_domain
      request.base_url
    end

    def decoded_jwt
      return {} unless params[:token]

      CanvasSecurity.decode_jwt(params[:token], [signing_secret])
    end

    def create_jwt
      CanvasSecurity.create_jwt({ parent_domain: current_domain }, nil, signing_secret, :HS512)
    end

    def signing_secret
      CanvasSecurity.services_signing_secret
    end
  end
end
