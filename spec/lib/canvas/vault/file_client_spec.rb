# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'spec_helper'

describe Canvas::Vault::FileClient do
  it "loads creds from static hash" do
    creds_hash = {
      "sts/testaccount/sts/canvas-shards-lookupper-test"=>{
        "access_key"=>"fake-access-key",
        "secret_key"=>"fake-secret-key",
        "security_token"=>"fake-security-token"
      }
    }
    allow(ConfigFile).to receive(:load).with("vault_contents").and_return(creds_hash)
    client = Canvas::Vault::FileClient.new
    output = client.read("sts/testaccount/sts/canvas-shards-lookupper-test")
    expect(output.data[:access_key]).to eq("fake-access-key")
  end
end