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

describe AuthenticationProvidersPresenter do
  describe "initialization" do
    it "wraps an account" do
      account = double
      presenter = described_class.new(account)
      expect(presenter.account).to eq(account)
    end
  end

  def stubbed_account(providers = [])
    double(authentication_providers: double(active: providers))
  end

  describe "#configs" do
    it "pulls configs from account" do
      config2 = double
      account = stubbed_account([double, config2])
      presenter = described_class.new(account)
      expect(presenter.configs[1]).to eq(config2)
    end

    it "wraps them in an array" do
      account = stubbed_account(Class.new(Array).new)
      presenter = described_class.new(account)
      expect(presenter.configs.class).to eq(Array)
    end

    it "only pulls from the db connection one time" do
      account = double
      expect(account).to receive(:authentication_providers).exactly(1).times.and_return(double(active: []))
      presenter = described_class.new(account)
      5.times { presenter.configs }
    end
  end

  describe "SAML view helpers" do
    let(:presenter) { described_class.new(double) }

    describe "#saml_identifiers" do
      it "is empty when saml disabled" do
        allow(AuthenticationProvider::SAML).to receive(:enabled?).and_return(false)
        expect(presenter.saml_identifiers).to be_empty
      end

      it "is the list from the SAML2 gem" do
        allow(AuthenticationProvider::SAML).to receive(:enabled?).and_return(true)
        expect(presenter.saml_identifiers).to eq(AuthenticationProvider::SAML.name_id_formats)
      end
    end

    describe "#saml_authn_contexts" do
      it "is empty when saml disabled" do
        allow(AuthenticationProvider::SAML).to receive(:enabled?).and_return(false)
        expect(presenter.saml_authn_contexts).to be_empty
      end

      context "when saml enabled" do
        before do
          allow(AuthenticationProvider::SAML).to receive(:enabled?).and_return(true)
        end

        it "sorts the gem values" do
          contexts = presenter.saml_authn_contexts(%w[abc xyz bcd])
          expect(contexts.index("bcd") < contexts.index("xyz")).to be(true)
        end

        it "adds in a nil value result" do
          contexts = presenter.saml_authn_contexts
          expect(contexts[0]).to eq(["No Value", nil])
        end
      end
    end
  end

  describe "#auth?" do
    it "is true for one aac" do
      account = stubbed_account([double])
      presenter = described_class.new(account)
      expect(presenter.auth?).to be(true)
    end

    it "is true for many aacs" do
      account = stubbed_account([double, double])
      presenter = described_class.new(account)
      expect(presenter.auth?).to be(true)
    end

    it "is false for no aacs" do
      account = stubbed_account
      presenter = described_class.new(account)
      expect(presenter.auth?).to be(false)
    end
  end

  describe "#ldap_config?" do
    it "is true if theres at least one ldap aac" do
      account = stubbed_account([AuthenticationProvider::LDAP.new])
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(true)
    end

    it "is false for no aacs" do
      account = stubbed_account
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(false)
    end

    it "is false for aacs which are not ldap" do
      account = stubbed_account([double(auth_type: "saml"), double(auth_type: "cas")])
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(false)
    end
  end

  describe "#sso_options" do
    it "always has cas and ldap" do
      AuthenticationProvider.valid_auth_types.each do |auth_type|
        klass = AuthenticationProvider.find_sti_class(auth_type)
        next if klass == AuthenticationProvider::SAML

        allow(klass).to receive(:enabled?).and_return(true)
      end

      allow(AuthenticationProvider::SAML).to receive(:enabled?).and_return(false)
      presenter = described_class.new(stubbed_account)
      options = presenter.sso_options
      expect(options).to include({ name: "CAS", value: "cas" })
      expect(options).to include({ name: "LinkedIn", value: "linkedin" })
    end

    it "includes saml if saml enabled" do
      AuthenticationProvider.valid_auth_types.each do |auth_type|
        klass = AuthenticationProvider.find_sti_class(auth_type)
        allow(klass).to receive(:enabled?).and_return(true)
      end

      presenter = described_class.new(stubbed_account)
      expect(presenter.sso_options).to include({ name: "SAML", value: "saml" })
    end
  end

  describe "#login_placeholder" do
    it "wraps AAC.default_delegated_login_handle_name" do
      expect(described_class.new(double).login_placeholder).to eq(
        AuthenticationProvider.default_delegated_login_handle_name
      )
    end
  end

  describe "#login_name" do
    let(:account) { Account.new }

    it "uses the one from the account if available" do
      account.login_handle_name = "LoginName"
      name = described_class.new(account).login_name
      expect(name).to eq("LoginName")
    end

    it "defaults to the provided default on AuthenticationProvider" do
      name = described_class.new(account).login_name
      expect(name).to eq(AuthenticationProvider.default_login_handle_name)
    end
  end

  describe "#ldap_configs" do
    it "selects out all ldap configs" do
      config = AuthenticationProvider::LDAP.new
      config2 = AuthenticationProvider::LDAP.new
      account = stubbed_account([double, config, double, config2])
      presenter = described_class.new(account)
      expect(presenter.ldap_configs).to eq([config, config2])
    end
  end

  describe "#saml_configs" do
    it "selects out all saml configs" do
      config = AuthenticationProvider::SAML.new
      config2 = AuthenticationProvider::SAML.new
      pre_configs = [double, config, double, config2]
      allow(pre_configs).to receive(:all).and_return(AuthenticationProvider)
      account = stubbed_account(pre_configs)
      configs = described_class.new(account).saml_configs
      expect(configs[0]).to eq(config)
      expect(configs[1]).to eq(config2)
      expect(configs.size).to eq(2)
    end
  end

  describe "#position_options" do
    let(:config) { AuthenticationProvider::SAML.new }
    let(:configs) { [config, config, config, config] }
    let(:account) { stubbed_account(configs) }

    before do
      allow(configs).to receive(:all).and_return(AuthenticationProvider)
    end

    it "generates a list from the saml config size" do
      allow(config).to receive(:new_record?).and_return(false)
      options = described_class.new(account).position_options(config)
      expect(options).to eq([[1, 1], [2, 2], [3, 3], [4, 4]])
    end

    it "tags on the 'Last' option if this config is new" do
      options = described_class.new(account).position_options(config)
      expect(options).to eq([["Last", nil], [1, 1], [2, 2], [3, 3], [4, 4]])
    end
  end

  describe "#login_url" do
    it "never includes id for LDAP" do
      config = Account.default.authentication_providers.create!(auth_type: "ldap")
      config2 = Account.default.authentication_providers.create!(auth_type: "ldap")
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: "login/ldap",
                                                        action: :new)
      expect(presenter.login_url_options(config2)).to eq(controller: "login/ldap",
                                                         action: :new)
    end

    it "doesn't include id if there is only one SAML config" do
      config = Account.default.authentication_providers.create!(auth_type: "saml")
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: "login/saml",
                                                        action: :new)
    end

    it "includes id if there are multiple SAML configs" do
      config = Account.default.authentication_providers.create!(auth_type: "saml")
      config2 = Account.default.authentication_providers.create!(auth_type: "saml")
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: "login/saml",
                                                        action: :new,
                                                        id: config)
      expect(presenter.login_url_options(config2)).to eq(controller: "login/saml",
                                                         action: :new,
                                                         id: config2)
    end
  end

  describe "#new_auth_types" do
    it "excludes singletons that have a config" do
      allow(AuthenticationProvider::Facebook).to receive(:enabled?).and_return(true)
      Account.default.authentication_providers.create!(auth_type: "facebook")
      presenter = described_class.new(Account.default)
      expect(presenter.new_auth_types).not_to include(AuthenticationProvider::Facebook)
    end
  end
end
