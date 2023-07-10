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
  # * standard postMessage listener: ui/shared/lti/jquery/messages.ts
  # * forwarding listener: ui/features/post_message_forwarding/index.ts
  # * postMessage docs: doc/api/lti_window_post_message.md
  # * LTI Platform Storage spec:
  #   * Client Side postMessages: https://www.imsglobal.org/spec/lti-cs-pm/v0p1
  #   * postMessage Storage: https://www.imsglobal.org/spec/lti-pm-s/v0p1
  #   * Implementation Guide: https://www.imsglobal.org/spec/lti-cs-oidc/v0p1
  class PlatformStorageController < ApplicationController
    def post_message_forwarding
      unless Lti::PlatformStorage.flag_enabled?
        render status: :not_found
        return
      end

      unless current_domain == oidc_auth_domain
        redirect_to "#{HostUrl.protocol}://#{oidc_auth_domain}/post_message_forwarding?token=#{create_jwt}"
        return
      end

      js_env({
               # postMessage origins require a protocol
               PARENT_ORIGIN: "#{HostUrl.protocol}://#{parent_domain}",
               IGNORE_LTI_POST_MESSAGES: true,
             })
      set_extra_csp_frame_ancestor!

      # this page has no UI and so doesn't need all the preloaded JS.
      # also, the preloaded JS ends up loading the canvas postMessage handler
      # (through the RCE), which results in duplicate responses to postMessages,
      # so we extra do not need this here.
      # @headers = false
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
    def set_extra_csp_frame_ancestor!
      csp_frame_ancestors << parent_domain
    end

    # In most instances, the OIDC Auth endpoint will share a domain with the Issuer Identifier/iss.
    # Instructure-hosted Canvas overrides this method in MRA, since it uses (for example):
    # `canvas.instructure.com` for the iss, and
    # `sso.canvaslms.com` for the OIDC Auth endpoint
    # format: canvas.docker, canvas.instructure.com (no protocol)
    def oidc_auth_domain
      return current_domain if Rails.env.development?

      iss = CanvasSecurity.config["lti_iss"] || current_domain
      return iss unless /^https?:/.match?(iss)

      URI(iss)&.host
    end

    def parent_domain
      decoded_jwt["parent_domain"] || current_domain
    end

    # format: canvas.docker, school.instructure.com, etc.
    def current_domain
      HostUrl.context_host(@domain_root_account, request.host)
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
