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
#

class Login::SamlIdpDiscoveryController < ApplicationController
  include Login::Shared

  before_action :forbid_on_files_domain
  before_action :fix_ms_office_redirects, only: :new

  def new
    uri = URI.parse(aac.discovery_service_url)
    params = URI.decode_www_form(uri.query || '')
    params << ['entityID', AuthenticationProvider::SAML.saml_default_entity_id_for_account(@domain_root_account)]
    params << ['return', saml_login_base_url]
    uri.query = URI.encode_www_form(params)
    redirect_to uri.to_s
  end

  private

  def aac
    @aac ||= begin
      scope = @domain_root_account.authentication_providers.active.where(auth_type: 'saml_idp_discovery')
      params[:id] ? scope.find(params[:id]) : scope.first!
    end
  end
end
