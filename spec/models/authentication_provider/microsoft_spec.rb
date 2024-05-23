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

  describe "#tenants=" do
    it "translates explicit microsoft to 'microsoft'" do
      expect(AuthenticationProvider::Microsoft.new(tenants: described_class::MICROSOFT_TENANT).tenants).to eq ["microsoft"]
    end

    it "removes all other tenants if common is specified" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "common,microsoft,abc").tenants).to eq ["common"]
      expect(AuthenticationProvider::Microsoft.new(tenants: "def,common,microsoft,abc").tenants).to eq ["common"]
    end
  end

  context "tenants validation" do
    it "allows the microsoft tenant" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft", account: Account.default)).to be_valid
    end

    it "allows a GUID tenant" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "9188040d-6c67-4c5b-b112-36a304b66dad", account: Account.default)).to be_valid
    end

    it "allows guests" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0,guests", account: Account.default)).to be_valid
    end

    it "allows multiple tenants" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "9188040d-6c67-4c5b-b112-36a304b66dad,microsoft,31da9f75-0173-4eb4-abec-f5ed0f0652d0", account: Account.default)).to be_valid
    end

    it "disallows no tenants" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "", account: Account.default)).not_to be_valid
    end

    it "disallows garbage tenants" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "invalid", account: Account.default)).not_to be_valid
    end

    it "disallows only guests" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "guests", account: Account.default)).not_to be_valid
    end

    it "disallows guests with only Microsoft" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft,guests", account: Account.default)).not_to be_valid
    end

    it "disallows guests with only Microsoft (manually specified)" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "#{described_class::MICROSOFT_TENANT},guests", account: Account.default)).not_to be_valid
    end

    it "disallows email login attribute with Microsoft" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft",
                                                   login_attribute: "email",
                                                   account: Account.default,
                                                   jit_provisioning: true)).not_to be_valid
    end

    it "allows email login attribute with Microsoft when jit provisioning is disabled" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft",
                                                   login_attribute: "email",
                                                   account: Account.default)).to be_valid
    end

    it "allows sub login attribute with Microsoft" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft", login_attribute: "sub", account: Account.default)).to be_valid
    end

    it "allows oid login attribute with Microsoft" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "microsoft", login_attribute: "oid", account: Account.default)).to be_valid
    end

    it "disallows oid login attribute with Microsoft _and_ another tenant" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0,microsoft",
                                                   login_attribute: "oid",
                                                   account: Account.default)).not_to be_valid
    end

    it "allows oid login attribute with a single tenant" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0",
                                                   login_attribute: "oid",
                                                   account: Account.default)).to be_valid
    end

    it "disallows oid login attribute with multiple tenants" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0,752dcc86-6caf-4534-b50b-282d35a39153",
                                                   login_attribute: "oid",
                                                   account: Account.default)).not_to be_valid
    end

    it "only allows tid+tid with common" do
      expect(AuthenticationProvider::Microsoft.new(tenants: "common", login_attribute: "tid+oid", account: Account.default)).to be_valid
      expect(AuthenticationProvider::Microsoft.new(tenants: "common", login_attribute: "oid", account: Account.default)).not_to be_valid
      expect(AuthenticationProvider::Microsoft.new(tenants: "common", login_attribute: "sub", account: Account.default)).not_to be_valid
    end
  end

  context "fetch unique_id" do
    it "records used tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "common")
      allow(ap).to receive(:claims).and_return("tid" => "1234")
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq ["1234"]
      expect(ap).not_to receive(:save!)
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq ["1234"]
    end

    it "records used missing tenant" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "common")
      allow(ap).to receive(:claims).and_return({})
      ap.unique_id("token")
      expect(ap.settings["known_tenants"]).to eq [nil]
    end

    it "calculates tid+oid when both are present" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenant: "common", login_attribute: "tid+oid")
      claims = { "tid" => "1234", "oid" => "5678" }
      allow(ap).to receive(:claims).and_return(claims)
      expect(ap.unique_id("token")).to eql claims.merge("tid+oid" => "1234#5678")
    end

    it "enforces the tenant" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "microsoft")
      expect(ap.send(:tenant_value)).to eql AuthenticationProvider::Microsoft::MICROSOFT_TENANT
      expect(ap.tenant).to eql "microsoft"
      expect(ap.tenants).to eql ["microsoft"]
      claims = { "tid" => AuthenticationProvider::Microsoft::MICROSOFT_TENANT, "sub" => "abc" }
      allow(ap).to receive(:claims).and_return(claims)
      expect(ap.unique_id("token")).to eql claims
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows specifying additional allowed tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "microsoft,31da9f75-0173-4eb4-abec-f5ed0f0652d0")
      expect(ap.send(:tenant_value)).to eql "common"
      expect(ap.tenant).to eql "microsoft"
      expect(ap.tenants).to eql ["microsoft", "31da9f75-0173-4eb4-abec-f5ed0f0652d0"]
      claims = { "tid" => "31da9f75-0173-4eb4-abec-f5ed0f0652d0", "sub" => "abc" }
      allow(ap).to receive(:claims).and_return(claims)
      expect(ap.unique_id("token")).to eql claims
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows guest accounts" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0,guests")
      expect(ap.send(:tenant_value)).to eql "31da9f75-0173-4eb4-abec-f5ed0f0652d0"
      expect(ap.tenant).to eql "31da9f75-0173-4eb4-abec-f5ed0f0652d0"
      expect(ap.tenants).to eql ["31da9f75-0173-4eb4-abec-f5ed0f0652d0", "guests"]
      allow(ap).to receive(:claims).and_return({ "tid" => "1234",
                                                 "sub" => "def",
                                                 "iss" => "https://login.microsoftonline.com/31da9f75-0173-4eb4-abec-f5ed0f0652d0/v2.0" })
      expect(ap.unique_id("token")).to eql({ "tid" => "1234", "sub" => "def" })
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end

    it "allows guest accounts from multiple tenants" do
      ap = AuthenticationProvider::Microsoft.new(account: Account.default, tenants: "31da9f75-0173-4eb4-abec-f5ed0f0652d0,752dcc86-6caf-4534-b50b-282d35a39153,guests")
      expect(ap.send(:tenant_value)).to eql "common"
      expect(ap.tenant).to eql "31da9f75-0173-4eb4-abec-f5ed0f0652d0"
      expect(ap.tenants).to eql %w[31da9f75-0173-4eb4-abec-f5ed0f0652d0 752dcc86-6caf-4534-b50b-282d35a39153 guests]
      allow(ap).to receive(:claims).and_return({ "tid" => "1234",
                                                 "sub" => "def",
                                                 "iss" => "https://login.microsoftonline.com/31da9f75-0173-4eb4-abec-f5ed0f0652d0/v2.0" })
      expect(ap.unique_id("token")).to eql({ "tid" => "1234", "sub" => "def" })
      allow(ap).to receive(:claims).and_return({ "tid" => "elsewhise", "sub" => "abc" })
      expect { ap.unique_id("token") }.to raise_error(OAuthValidationError)
    end
  end
end
