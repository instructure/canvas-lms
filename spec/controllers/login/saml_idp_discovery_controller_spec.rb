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

require_relative '../../spec_helper'

describe Login::SamlIdpDiscoveryController do
  it "works" do
    a = Account.default
    a.settings[:saml_entity_id] = 'http://school.instructure.com/saml2'
    a.save!
    a.authentication_providers.create!(auth_type: "saml_idp_discovery", discovery_service_url: "http://idp.school.edu/WAYF")

    get :new
    expect(response).to redirect_to("http://idp.school.edu/WAYF?entityID=http%3A%2F%2Fschool.instructure.com%2Fsaml2&return=http%3A%2F%2Ftest.host%2Flogin%2Fsaml")
  end
end
