#
# Copyright (C) 2011-2014 Instructure, Inc.
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

describe GoogleDrive::Client do

  let(:client_secrets) {
    {
      'client_id' => "6",
      'client_secret' => "secret",
      'redirect_uri' => "http://example.com/custom"
    }
  }

  it 'creates a new Google API client' do

    client = described_class.create(client_secrets)
    expect(client.authorization.client_secret).to eq 'secret'
    expect(client.authorization.refresh_token).to be_nil
  end

  it 'creates a new Google API client with a refresh token' do
    client = described_class.create(client_secrets, 'refresh_token')
    expect(client.authorization.client_secret).to eq 'secret'
    expect(client.authorization.refresh_token).to eq 'refresh_token'
  end

  it 'creates a new Google API client with a access token' do
    client = described_class.create(client_secrets, nil, 'access_token')
    expect(client.authorization.client_secret).to eq 'secret'
    expect(client.authorization.access_token).to eq 'access_token'
  end

  it 'auth_uri handles all params being passed in' do
    client = described_class.create(client_secrets, nil, 'access_token')

    auth_uri = described_class.auth_uri(client, 'awesome_scope', 'my_crazy_username')
    expect(auth_uri).to include 'state=awesome_scope'
    expect(auth_uri).to include 'login_hint=my_crazy_username'
  end


  it 'auth_uri handles scope and no username' do
    client = described_class.create(client_secrets, nil, 'access_token')

    auth_uri = described_class.auth_uri(client, 'scope')
    expect(auth_uri).to include 'state=scope'
    expect(auth_uri).to_not include 'login_hint'
  end
end