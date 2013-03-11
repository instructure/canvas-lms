#
# Copyright (C) 2011 Instructure, Inc.
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
      @account_config.auth_filter.should eql("(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))")
    end

    describe "test_ldap_search" do
      it "should validate filter syntax" do
        aac = AccountAuthorizationConfig.new
        aac.auth_type = 'ldap'
        aac.ldap_filter = 'bob'
        aac.test_ldap_search.should be_false
        aac.errors.first.last.should match /Invalid filter syntax/

        aac.errors.clear
        aac.ldap_filter = '(sAMAccountName={{login}})'
        aac.test_ldap_search.should be_false
        aac.errors.first.last.should_not match /Invalid filter syntax/
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
    config.change_password_url.should be_nil
  end

  context "SAML settings" do
    before(:each) do
      @account = Account.create!(:name => "account")
    end
    
    it "should load encryption settings" do
      file_that_exists = File.expand_path(__FILE__)
      Setting.set_config('saml', {
        :entity_id => 'http://www.example.com/saml2',
        :tech_contact_name => 'Admin Dude',
        :tech_contact_email => 'admindude@example.com',
        :encryption => {
          :private_key => file_that_exists,
          :certificate => file_that_exists
        }
      })
      
      config = @account.account_authorization_configs.build(:auth_type => 'saml')
      
      s = config.saml_settings
      s.encryption_configured?.should be_true
    end
    
    it "should set the entity_id with the current domain" do
      HostUrl.stubs(:default_host).returns('bob.cody.instructure.com')
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml")
      @aac.entity_id.should == "http://bob.cody.instructure.com/saml2"
    end
    
    it "should not overwrite a specific entity_id" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :entity_id => "http://wtb.instructure.com/saml2")
      @aac.entity_id.should == "http://wtb.instructure.com/saml2"
    end
    
    it "should set requested_authn_context to nil if empty string" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :requested_authn_context => "")
      @aac.requested_authn_context.should == nil
    end
    
    it "should allow requested_authn_context to be set to anything" do
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml", :requested_authn_context => "anything")
      @aac.requested_authn_context.should == "anything"
    end
  end
  
  context "password" do
    it "should decrypt the password to the original value" do
      c = AccountAuthorizationConfig.new
      c.auth_password = "asdf"
      c.auth_decrypted_password.should eql("asdf")
      c.auth_password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      c.auth_decrypted_password.should eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end

  it "should enable canvas auth when destroyed" do
    Account.default.settings[:canvas_authentication] = false
    Account.default.save!
    Account.default.canvas_authentication?.should be_true
    aac = Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    Account.default.canvas_authentication?.should be_false
    aac.destroy
    Account.default.reload.canvas_authentication?.should be_true
    Account.default.settings[:canvas_authentication].should_not be_false
    Account.default.account_authorization_configs.create!(:auth_type => 'ldap')
    # still true
    Account.default.reload.canvas_authentication?.should be_true
  end

  it "should disable open registration when created" do
    Account.default.settings[:open_registration] = true
    Account.default.save!
    Account.default.account_authorization_configs.create!(:auth_type => 'cas')
    Account.default.reload.open_registration?.should be_false
  end
end
