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

describe AuthenticationProvider::Microsoft do
  it "accesses client_id from plugin settings" do
    PluginSetting.create!(name: "microsoft", settings: { application_id: "1234", application_secret: "secret" })
    ap = AuthenticationProvider::Microsoft.new
    expect(ap.application_id).to eq "1234"
    expect(ap.client_id).to eq "1234"
    expect(ap.application_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
    ap.application_id = "5678"
    ap.application_secret = "bogus"
    expect(ap.application_id).to eq "1234"
    expect(ap.client_id).to eq "1234"
    expect(ap.application_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
  end

  it "accesses client_id from itself" do
    ap = AuthenticationProvider::Microsoft.new
    expect(ap.application_id).to be_nil
    expect(ap.client_id).to be_nil
    expect(ap.application_secret).to be_nil
    expect(ap.client_secret).to be_nil
    ap.application_id = "5678"
    ap.application_secret = "secret"
    expect(ap.application_id).to eq "5678"
    expect(ap.client_id).to eq "5678"
    expect(ap.application_secret).to eq "secret"
    expect(ap.client_secret).to eq "secret"
  end

  it "allows `microsoft` as an alias for the Microsoft tenant" do
    ap = AuthenticationProvider::Microsoft.new
    ap.tenant = "microsoft"
    expect(ap.send(:authorize_url)).to include(AuthenticationProvider::Microsoft::MICROSOFT_TENANT)
  end

  context "fetch unique_id" do
    it "records used tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default)
      allow(ap).to receive(:claims).and_return("tid" => "1234")
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq ["1234"]
      expect(ap).not_to receive(:save!)
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq ["1234"]
    end

    it "records used missing tenant" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default)
      allow(ap).to receive(:claims).and_return({})
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq [nil]
    end

    it "enforces the tenant" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "microsoft")
      allow(ap).to receive(:claims).and_return({ "tid" => AuthenticationProvider::Microsoft::MICROSOFT_TENANT, "sub" => "abc" })
      expect(ap.unique_id("token")).to eql "abc"
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows specifying additional allowed tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "microsoft", allowed_tenants: "1234")
      allow(ap).to receive(:claims).and_return({ "tid" => "1234", "sub" => "abc" })
      expect(ap.unique_id("token")).to eql "abc"
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows specifying all guest accounts" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "microsoft", allowed_tenants: "guests")
      allow(ap).to receive(:claims).and_return({ "tid" => "1234",
                                                 "sub" => "abc",
                                                 "iss" => "https://login.microsoftonline.com/#{AuthenticationProvider::Microsoft::MICROSOFT_TENANT}/v2.0" })
      expect(ap.unique_id("token")).to eql "abc"
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end
  end
end
