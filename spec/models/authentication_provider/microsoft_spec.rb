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
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "microsoft")
      expect(ap.send(:tenant_value)).to eql AuthenticationProvider::Microsoft::MICROSOFT_TENANT
      expect(ap.tenant).to eql "microsoft"
      expect(ap.tenants).to eql ["microsoft"]
      claims = { "tid" => AuthenticationProvider::Microsoft::MICROSOFT_TENANT, "sub" => "abc" }
      allow(ap).to receive(:claims).and_return(claims)
      expect(ap.unique_id("token")).to eql claims.merge("tid+oid" => "#{claims["tid"]}#")
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows specifying additional allowed tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "microsoft,1234")
      expect(ap.send(:tenant_value)).to eql "common"
      expect(ap.tenant).to eql "microsoft"
      expect(ap.tenants).to eql ["microsoft", "1234"]
      claims = { "tid" => "1234", "sub" => "abc" }
      allow(ap).to receive(:claims).and_return(claims)
      expect(ap.unique_id("token")).to eql claims.merge("tid+oid" => "1234#")
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows guest accounts" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "abc,guests")
      expect(ap.send(:tenant_value)).to eql "abc"
      expect(ap.tenant).to eql "abc"
      expect(ap.tenants).to eql ["abc", "guests"]
      allow(ap).to receive(:claims).and_return({ "tid" => "1234",
                                                 "sub" => "def",
                                                 "iss" => "https://login.microsoftonline.com/abc/v2.0" })
      expect(ap.unique_id("token")).to eql({ "tid" => "1234", "sub" => "def", "tid+oid" => "1234#" })
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows guest accounts from multiple tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "abc,def,guests")
      expect(ap.send(:tenant_value)).to eql "common"
      expect(ap.tenant).to eql "abc"
      expect(ap.tenants).to eql %w[abc def guests]
      allow(ap).to receive(:claims).and_return({ "tid" => "1234",
                                                 "sub" => "def",
                                                 "iss" => "https://login.microsoftonline.com/abc/v2.0" })
      expect(ap.unique_id("token")).to eql({ "tid" => "1234", "sub" => "def", "tid+oid" => "1234#" })
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end
  end
end
