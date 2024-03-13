# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe AuthenticationProvider::Facebook do
  it "accesses client_id from plugin settings" do
    PluginSetting.create!(name: "facebook", settings: { app_id: "1234", app_secret: "secret" })
    ap = AuthenticationProvider::Facebook.new
    expect(ap.app_id).to eq "1234"
    expect(ap.client_id).to eq "1234"
    expect(ap.app_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
    ap.app_id = "5678"
    ap.app_secret = "bogus"
    expect(ap.app_id).to eq "1234"
    expect(ap.client_id).to eq "1234"
    expect(ap.app_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
  end

  it "accesses client_id from itself" do
    ap = AuthenticationProvider::Facebook.new
    expect(ap.app_id).to be_nil
    expect(ap.client_id).to be_nil
    expect(ap.app_secret).to be_nil
    expect(ap.client_secret).to be_nil
    ap.app_id = "5678"
    ap.app_secret = "secret"
    expect(ap.app_id).to eq "5678"
    expect(ap.client_id).to eq "5678"
    expect(ap.app_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
  end
end
