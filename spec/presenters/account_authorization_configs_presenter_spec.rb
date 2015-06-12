 require 'spec_helper'

describe AccountAuthorizationConfigsPresenter do
  describe "initialization" do
    it "wraps an account" do
      account = stub()
      presenter = described_class.new(account)
      expect(presenter.account).to eq(account)
    end
  end

  def stubbed_account(providers=[])
    stub(authentication_providers: stub(active: providers))
  end

  describe "#configs" do

    it "pulls configs from account" do
      config2 = stub
      account = stubbed_account([stub, config2])
      presenter = described_class.new(account)
      expect(presenter.configs[1]).to eq(config2)
    end

    it "wraps them in an array" do
      class NotArray < Array
      end
      account = stubbed_account(NotArray.new([]))
      presenter = described_class.new(account)
      expect(presenter.configs.class).to eq(Array)
    end

    it "only pulls from the db connection one time" do
      account = stub()
      account.expects(:authentication_providers).times(1).returns(stub(active: []))
      presenter = described_class.new(account)
      5.times{ presenter.configs }
    end
  end

  describe "SAML view helpers" do
    let(:presenter){ described_class.new(stub) }

    describe "#saml_identifiers" do
      it "is empty when saml disabled" do
        AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(false)
        expect(presenter.saml_identifiers).to be_empty
      end

      it "is the list from Onelogin::Saml::NameIdentifiers" do
        AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(true)
        expected = Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS
        expect(presenter.saml_identifiers).to eq(expected)
      end
    end

    describe "#saml_authn_contexts" do
      it "is empty when saml disabled" do
        AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(false)
        expect(presenter.saml_authn_contexts).to be_empty
      end

      context "when saml enabled" do

        before do
          AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(true)
        end

        it "has each value from Onelogin" do
          contexts = presenter.saml_authn_contexts
          Onelogin::Saml::AuthnContexts::ALL_CONTEXTS.each do |context|
            expect(contexts).to include(context)
          end
        end

        it "sorts OneLogin values" do
          contexts = presenter.saml_authn_contexts(['abc', 'xyz', 'bcd'])
          expect(contexts.index('bcd') < contexts.index('xyz')).to be(true)
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
      account = stubbed_account([stub])
      presenter = described_class.new(account)
      expect(presenter.auth?).to be(true)
    end

    it "is true for many aacs" do
      account = stubbed_account([stub, stub])
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
      account = stubbed_account([AccountAuthorizationConfig::LDAP.new])
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(true)
    end

    it "is false for no aacs" do
      account = stubbed_account
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(false)
    end

    it "is false for aacs which are not ldap" do
      account = stubbed_account( [ stub(auth_type: 'saml'), stub(auth_type: 'cas') ] )
      presenter = described_class.new(account)
      expect(presenter.ldap_config?).to be(false)
    end
  end

  describe "#sso_options" do
    it "always has cas and ldap" do
      AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(false)
      presenter = described_class.new(stubbed_account)
      options = presenter.sso_options
      expect(options).to include({name: 'CAS', value: 'cas'})
      expect(options).to include({name: 'LinkedIn', value: 'linkedin'})
    end

    it "includes saml if saml enabled" do
      AccountAuthorizationConfig::SAML.stubs(:enabled?).returns(true)
      presenter = described_class.new(stubbed_account)
      expect(presenter.sso_options).to include({name: 'SAML', value: 'saml'})
    end
  end

  describe "ip_configuration" do
    def stub_setting(val)
      Setting.stubs(:get)
        .with('account_authorization_config_ip_addresses', nil)
        .returns(val)
    end

    describe "#ips_configured?" do
      it "is true if there is anything in the ip addresses setting" do
        stub_setting('127.0.0.1')
        presenter = described_class.new(stub)
        expect(presenter.ips_configured?).to be(true)
      end

      it "is false without ip addresses" do
        stub_setting(nil)
        presenter = described_class.new(stub)
        expect(presenter.ips_configured?).to be(false)
      end
    end

    describe "#ip_list" do
      it "just returns the one for one ip address" do
        stub_setting("127.0.0.1")
        presenter = described_class.new(stub)
        expect(presenter.ip_list).to eq("127.0.0.1")
      end

      it "combines many ips into a newline delimited block" do
        stub_setting("127.0.0.1,2.2.2.2, 4.4.4.4,  6.6.6.6")
        presenter = described_class.new(stub)
        list_output = "127.0.0.1\n2.2.2.2\n4.4.4.4\n6.6.6.6"
        expect(presenter.ip_list).to eq(list_output)
      end

      it "is an empty string for no ips" do
        stub_setting(nil)
        presenter = described_class.new(stub)
        expect(presenter.ip_list).to eq("")
      end
    end
  end

  describe "#canvas_auth_only?" do
    it "is true if no auth provider exists" do
      account = stub(non_canvas_auth_configured?: false)
      presenter = described_class.new(account)
      expect(presenter.canvas_auth_only?).to eq(true)
    end

    it "is false if an auth provider exists" do
      account = stub(non_canvas_auth_configured?: true)
      presenter = described_class.new(account)
      expect(presenter.canvas_auth_only?).to eq(false)
    end
  end

  describe "#login_placeholder" do
    it "wraps AAC.default_delegated_login_handle_name" do
      expect(described_class.new(stub).login_placeholder).to eq(
        AccountAuthorizationConfig.default_delegated_login_handle_name
      )
    end
  end

  describe "#login_name" do
    let(:account){ Account.new }

    it "uses the one from the account if available" do
      account.login_handle_name = "LoginName"
      name = described_class.new(account).login_name
      expect(name).to eq("LoginName")
    end

    it "defaults to the provided default on AccountAuthorizationConfig" do
      name = described_class.new(account).login_name
      expect(name).to eq(AccountAuthorizationConfig.default_login_handle_name)
    end
  end

  describe "#ldap_configs" do
    it "selects out all ldap configs" do
      config = AccountAuthorizationConfig::LDAP.new
      config2 = AccountAuthorizationConfig::LDAP.new
      account = stubbed_account([stub, config, stub, config2])
      presenter = described_class.new(account)
      expect(presenter.ldap_configs).to eq([config, config2])
    end
  end

  describe "#saml_configs" do
    it "selects out all saml configs" do
      config = AccountAuthorizationConfig::SAML.new
      config2 = AccountAuthorizationConfig::SAML.new
      pre_configs = [stub, config, stub, config2]
      pre_configs.stubs(:scoped).returns(AccountAuthorizationConfig)
      account = stubbed_account(pre_configs)
      configs = described_class.new(account).saml_configs
      expect(configs[0]).to eq(config)
      expect(configs[1]).to eq(config2)
      expect(configs.size).to eq(2)
    end
  end

  describe "#position_options" do
    let(:config){ AccountAuthorizationConfig::SAML.new }
    let(:configs){ [config, config, config, config] }
    let(:account){ stubbed_account(configs) }

    before do
      configs.stubs(:scoped).returns(AccountAuthorizationConfig)
    end

    it "generates a list from the saml config size" do
      config.stubs(:new_record?).returns(false)
      options = described_class.new(account).position_options(config)
      expect(options).to eq([[1,1],[2,2],[3,3],[4,4]])
    end

    it "tags on the 'Last' option if this config is new" do
      options = described_class.new(account).position_options(config)
      expect(options).to eq([["Last",nil],[1,1],[2,2],[3,3],[4,4]])
    end
  end

  describe "#login_url" do
    it "never includes id for LDAP" do
      config = Account.default.authentication_providers.create!(auth_type: 'ldap')
      config2 = Account.default.authentication_providers.create!(auth_type: 'ldap')
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: 'login/ldap',
                                                        action: :new)
      expect(presenter.login_url_options(config2)).to eq(controller: 'login/ldap',
                                                         action: :new)
    end

    it "doesn't include id if there is only one SAML config" do
      config = Account.default.authentication_providers.create!(auth_type: 'saml')
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: 'login/saml',
                                                        action: :new)
    end

    it "includes id if there are multiple SAML configs" do
      config = Account.default.authentication_providers.create!(auth_type: 'saml')
      config2 = Account.default.authentication_providers.create!(auth_type: 'saml')
      presenter = described_class.new(Account.default)
      expect(presenter.login_url_options(config)).to eq(controller: 'login/saml',
                                                        action: :new,
                                                        id: config)
      expect(presenter.login_url_options(config2)).to eq(controller: 'login/saml',
                                                         action: :new,
                                                         id: config2)
    end
  end

  describe "#new_auth_types" do
    it "excludes singletons that have a config" do
      AccountAuthorizationConfig::Facebook.stubs(:enabled?).returns(true)
      Account.default.authentication_providers.create!(auth_type: 'facebook')
      presenter = described_class.new(Account.default)
      expect(presenter.new_auth_types).to_not be_include(AccountAuthorizationConfig::Facebook)
    end
  end
end
