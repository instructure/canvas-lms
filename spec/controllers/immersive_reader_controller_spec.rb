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
#

require 'spec_helper'
require 'webmock/rspec'

describe ImmersiveReaderController do
  around(:example) do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  it 'should require a user be logged in' do
    get 'authenticate'
    assert_unauthorized
  end

  it 'should require the plugin be configured' do
    user_model
    user_session(@user)
    get 'authenticate'
    assert_status(404)
  end

  it 'should authenticate with cognitive services' do
    user_model
    user_session(@user)
    stub_request(:post, 'https://login.windows.net')
    allow(controller).to receive(:ir_config).and_return(
      {
        ir_tenant_id: 'faketenantid',
        ir_client_id: 'fakeclientid',
        ir_client_secret: 'fakesecret',
        ir_subdomain: 'fakesub'
      }
    )
    get 'authenticate'
    expect(WebMock).to have_requested(:post, 'https://login.windows.net/faketenantid/oauth2/token')
      .with(
      body:
        'grant_type=client_credentials&client_id=fakeclientid&client_secret=fakesecret&resource=https%3A%2F%2Fcognitiveservices.azure.com%2F',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )
      .once
  end
end
