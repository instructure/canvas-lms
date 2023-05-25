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
#

describe OAuthProxyController do
  it "redirects to the url in the state" do
    get :redirect_proxy, params: { state: Canvas::Security.create_jwt({ redirect_uri: "http://example.com" }) }
    expect(response.location).to match("example.com")
  end

  it "throws an error if state is missing" do
    get :redirect_proxy
    expect(response).to have_http_status :bad_request
  end

  it "throws an error if the state is invalid" do
    get :redirect_proxy, params: { state: "123" }
    expect(response).to have_http_status :bad_request
  end

  it "filters out rails added params" do
    get :redirect_proxy, params: { state: Canvas::Security.create_jwt({ redirect_uri: "http://example.com" }) }
    jwt = URI.decode_www_form(URI.parse(response.location).query).first.last
    params = Canvas::Security.decode_jwt(jwt)
    expect(params.keys & %w[controller action]).to be_empty
  end

  it "handles redirect urls with an existing query" do
    get :redirect_proxy, params: { state: Canvas::Security.create_jwt({ redirect_uri: "http://example.com/test?foo=bar" }) }
    keys = URI.decode_www_form(URI.parse(response.location).query).pluck(0)
    expect(keys).to eq %w[foo state]
  end
end
