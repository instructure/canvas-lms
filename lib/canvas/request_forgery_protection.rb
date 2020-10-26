# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# a series of overrides against ActionController::RequestForgeryProtection to:
#
#  (1) deal with masked authenticity tokens (see CanvasBreachMitigation)
#  (2) skip CSRF protection on token/policy-authenticated API requests
#
module Canvas
  module RequestForgeryProtection
    def form_authenticity_token(form_options: {})
      # to implement per-form CSRF, see https://github.com/rails/rails/commit/3e98819e20bc113343d4d4c0df614865ad5a9d3a
      masked_authenticity_token
    end

    def verified_request?
      !protect_against_forgery? || request.get? || request.head? ||
        (api_request? && !in_app?) ||
        CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(cookies, form_authenticity_param) ||
        CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(cookies, request.headers['X-CSRF-Token'])
    end

    private
    def authenticity_token_options
      session_options = CanvasRails::Application.config.session_options
      options = session_options.slice(:domain, :secure)
      options[:httponly] = HostUrl.is_file_host?(request.host_with_port)
      options
    end

    def reset_authenticity_token!
      CanvasBreachMitigation::MaskingSecrets.reset_authenticity_token!(cookies, authenticity_token_options)
    end

    def masked_authenticity_token
      CanvasBreachMitigation::MaskingSecrets.masked_authenticity_token(cookies, authenticity_token_options)
    end
  end
end
