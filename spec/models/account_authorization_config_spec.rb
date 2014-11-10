#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AccountAuthorizationConfig do

  context "LDAP settings" do
    it "should not escape auth_filter" do
      @account = Account.new
      @account_config = @account.account_authorization_configs.build(:ldap_filter => '(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))')
      @account_config.save
      expect(@account_config.auth_filter).to eql("(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))")
    end

    describe "test_ldap_search" do
      it "should validate filter syntax" do
        aac = AccountAuthorizationConfig.new
        aac.auth_type = 'ldap'
        aac.ldap_filter = 'bob'
        expect(aac.test_ldap_search).to be_falsey
        expect(aac.errors.full_messages.join).to match /Invalid filter syntax/

        aac.errors.clear
        aac.ldap_filter = '(sAMAccountName={{login}})'
        expect(aac.test_ldap_search).to be_falsey
        expect(aac.errors.full_messages.join).not_to match /Invalid filter syntax/
      end
    end
  end

  context "#ldap_bind_result" do
    it "should not attempt to bind with a blank password" do
      aac = AccountAuthorizationConfig.new
      aac.auth_type = 'ldap'
      aac.ldap_filter = 'bob'
      aac.expects(:ldap_connection).never
      aac.ldap_bind_result('test', '')
    end
  end

  it "should replace empty string with nil" do
    @account = Account.new
    config = @account.account_authorization_configs.build
    config.change_password_url = ""
    expect(config.change_password_url).to be_nil
  end

  context "SAML settings" do
    before(:each) do
      skip("requires SAML extension") unless AccountAuthorizationConfig.saml_enabled
      @account = Account.create!(:name => "account")
      @file_that_exists = File.expand_path(__FILE__)
    end

    it "should load encryption settings" do
      ConfigFile.stub('saml', {
        :entity_id => 'http://www.example.com/saml2',
        :encryption => {
          :private_key => @file_that_exists,
          :certificate => @file_that_exists
        }
      })

      s = @account.account_authorization_configs.build(:auth_type => 'saml').saml_settings

      expect(s.encryption_configured?).to be_truthy
    end

    it "should load the tech contact settings" do
      ConfigFile.stub('saml', {
        :tech_contact_name => 'Admin Dude',
        :tech_contact_email => 'admindude@example.com',
      })

      s = @account.account_authorization_configs.build(:auth_type => 'saml').saml_settings

      expect(s.tech_contact_name).to eq 'Admin Dude'
      expect(s.tech_contact_email).to eq 'admindude@example.com'
    end

    it "should allow additional private keys to be set" do
      ConfigFile.stub('saml', {
        :entity_id => 'http://www.example.com/saml2',
        :encryption => {
          :private_key => @file_that_exists,
          :certificate => @file_that_exists,
          :additional_private_keys => [
            @file_that_exists
          ]
        }
      })

      s = @account.account_authorization_configs.build(:auth_type => 'saml').saml_settings

      expect(s.xmlsec_additional_privatekeys).to eq [@file_that_exists]
    end

    it "should allow some additional private keys to be set when not all exist" do
      file_that_does_not_exist = '/tmp/i_am_not_a_private_key'
      ConfigFile.stub('saml', {
        :entity_id => 'http://www.example.com/saml2',
        :encryption => {
          :private_key => @file_that_exists,
          :certificate => @file_that_exists,
          :additional_private_keys => [
            @file_that_exists,
            file_that_does_not_exist
          ]
        }
      })

      s = @account.account_authorization_configs.build(:auth_type => 'saml').saml_settings

      expect(s.xmlsec_additional_privatekeys).to eq [@file_that_exists]
    end

    it "should set the entity_id with the current domain" do
      HostUrl.stubs(:default_host).returns('bob.cody.instructure.com')
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml")
      expect(@aac.entity_id).to eq "http://bob.cody.instructure.com/saml2"
    end

    it "should not overwrite a specific entity_id" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :entity_id => "http://wtb.instructure.com/saml2")
      expect(@aac.entity_id).to eq "http://wtb.instructure.com/saml2"
    end

    it "should set requested_authn_context to nil if empty string" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :requested_authn_context => "")
      expect(@aac.requested_authn_context).to eq nil
    end

    it "should allow requested_authn_context to be set to anything" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :requested_authn_context => "anything")
      expect(@aac.requested_authn_context).to eq "anything"
    end
  end

  describe '.resolve_saml_key_path' do
    it "returns nil for nil" do
      expect(AccountAuthorizationConfig.resolve_saml_key_path(nil)).to be_nil
    end

    it "returns nil for nonexistent paths" do
      expect(AccountAuthorizationConfig.resolve_saml_key_path('/tmp/does_not_exist')).to be_nil
    end

    it "returns abolute paths unmodified when the file exists" do
      Tempfile.open('samlkey') do |samlkey|
        expect(AccountAuthorizationConfig.resolve_saml_key_path(samlkey.path)).to eq samlkey.path
      end
    end

    it "interprets relative paths from the config dir" do
      expect(AccountAuthorizationConfig.resolve_saml_key_path('initializers')).to eq Rails.root.join('config', 'initializers').to_s
    end
  end

  context "password" do
    it "should decrypt the password to the original value" do
      c = AccountAuthorizationConfig.new
      c.auth_password = "asdf"
      expect(c.auth_decrypted_password).to eql("asdf")
      c.auth_password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(c.auth_decrypted_password).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  it "should enable canvas auth when destroyed" do
    Account.default.settings[:canvas_authentication] = false
    Account.default.save!
    expect(Account.default.canvas_authentication?).to be_truthy
    aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    expect(Account.default.canvas_authentication?).to be_falsey
    aac.destroy
    expect(Account.default.reload.canvas_authentication?).to be_truthy
    expect(Account.default.settings[:canvas_authentication]).not_to be_falsey
    Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    # still true
    expect(Account.default.reload.canvas_authentication?).to be_truthy
  end

  it "should disable open registration when created" do
    Account.default.settings[:open_registration] = true
    Account.default.save!
    Account.default.account_authorization_configs.create!(:auth_type => 'cas')
    expect(Account.default.reload.open_registration?).to be_falsey
  end
end
