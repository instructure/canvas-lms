# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti::Oidc
  # In most instances, the OIDC Auth endpoint will share a domain with the Issuer Identifier/iss.
  # Instructure-hosted Canvas overrides this method in MRA, since it uses (for example):
  # `canvas.instructure.com` for the iss, and
  # `sso.canvaslms.com` for the OIDC Auth endpoint
  # format: canvas.docker, canvas.instructure.com (no protocol)
  def self.auth_domain(current_domain)
    return current_domain if Rails.env.development? || Rails.env.test?

    iss = CanvasSecurity.config["lti_iss"] || current_domain
    return iss unless /^https?:/.match?(iss)

    URI(iss)&.host
  end
end
