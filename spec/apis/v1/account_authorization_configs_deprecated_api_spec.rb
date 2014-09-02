
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "AccountAuthorizationConfigs API", type: :request do
  before do
    @account = account_model(:name => 'root')
    user_with_pseudonym(:active_all => true, :account => @account)
    @account.account_users.create!(user: @user)
  end

  it "should set the authorization config" do
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"auth_type" => "cas", "auth_base" => "127.0.0.1"}}})
    @account.reload
    @account.account_authorization_configs.size.should == 1
    config = @account.account_authorization_configs.first
    config.auth_type.should == 'cas'
    config.auth_base.should == '127.0.0.1'
  end

  it "should set multiple ldap configs" do
    ldap1 = {'auth_type' => 'ldap', 'auth_host' => '127.0.0.1', 'auth_filter' => 'filter1', 'auth_username' => 'username1', 'auth_password' => 'password1'}
    ldap2 = {'auth_type' => 'ldap', 'auth_host' => '127.0.0.2', 'auth_filter' => 'filter2', 'auth_username' => 'username2', 'auth_password' => 'password2'}
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => ldap1, "1" => ldap2}})

    @account.reload
    @account.account_authorization_configs.size.should == 2
    config1 = @account.account_authorization_configs.first
    config2 = @account.account_authorization_configs.second

    config1.auth_type.should == 'ldap'
    config1.auth_host.should == '127.0.0.1'
    config1.auth_filter.should == 'filter1'
    config1.auth_username.should == 'username1'
    config1.auth_decrypted_password.should == 'password1'

    config2.auth_type.should == 'ldap'
    config2.auth_host.should == '127.0.0.2'
    config2.auth_filter.should == 'filter2'
    config2.auth_username.should == 'username2'
    config2.auth_decrypted_password.should == 'password2'
  end

  it "should update existing configs" do
    config = @account.account_authorization_configs.create!("auth_type" => "cas", "auth_base" => "127.0.0.1")
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"id" => config.id.to_s, "auth_type" => "cas", "auth_base" => "127.0.0.2"}}})
    @account.reload
    config.reload

    @account.account_authorization_configs.size.should == 1
    @account.account_authorization_configs.first.should == config
    config.auth_base.should == '127.0.0.2'
  end

  it "should delete configs not referenced" do
    config = @account.account_authorization_configs.create!("auth_type" => "ldap")
    config = @account.account_authorization_configs.create!("auth_type" => "ldap")
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"id" => config.id.to_s, "auth_type" => "ldap"}}})
    @account.reload
    @account.account_authorization_configs.count.should == 1
  end

  it "should discard config parameters not recognized for the given auth_type" do
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"auth_type" => "cas", "auth_base" => "127.0.0.1", "auth_filter" => "discarded"}}})
    @account.reload
    @account.account_authorization_configs.size.should == 1
    config = @account.account_authorization_configs.first
    config.auth_type.should == 'cas'
    config.auth_filter.should be_nil
  end

  context "saml" do
    append_before do
      @saml1 = {'auth_type' => 'saml', 'idp_entity_id' => 'http://example.com/saml1', 'log_in_url' => 'http://example.com/saml1/sli', 'log_out_url' => 'http://example.com/saml1/slo', 'certificate_fingerprint' => '111222', 'identifier_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'}
      @saml2 = {'auth_type' => 'saml', 'idp_entity_id' => 'http://example.com/saml2', 'log_in_url' => 'http://example.com/saml1/sli2', 'log_out_url' => 'http://example.com/saml1/slo2', 'certificate_fingerprint' => '222111', 'identifier_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'}
    end

    def update_saml(data=nil)
      data ||= {:account_authorization_config => {"0" => @saml1, "1" => @saml2}}
      api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
               {:controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json'},
               data)
    end

    it "should set multiple saml configs" do
      update_saml
      @account.reload
      @account.account_authorization_configs.size.should == 2
      config1 = @account.account_authorization_configs.first
      config2 = @account.account_authorization_configs.second

      config1.auth_type.should == 'saml'
      config1.idp_entity_id.should == 'http://example.com/saml1'
      config1.log_in_url.should == 'http://example.com/saml1/sli'
      config1.log_out_url.should == 'http://example.com/saml1/slo'
      config1.certificate_fingerprint.should == '111222'
      config1.identifier_format.should == 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'

      config2.auth_type.should == 'saml'
      config2.idp_entity_id.should == 'http://example.com/saml2'
      config2.log_in_url.should == 'http://example.com/saml1/sli2'
      config2.log_out_url.should == 'http://example.com/saml1/slo2'
      config2.certificate_fingerprint.should == '222111'
      config2.identifier_format.should == 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
    end

    it "should update the existing AACs" do
      update_saml

      @account.reload
      config1 = @account.account_authorization_configs.first
      config2 = @account.account_authorization_configs.second

      @saml1['idp_entity_id'] = 'different'
      @saml1['id'] = config1.id
      @saml2['idp_entity_id'] = 'different2'
      @saml2['id'] = config2.id

      update_saml

      @account.reload
      @account.account_authorization_configs.size.should == 2

      config1.reload
      config1.idp_entity_id.should == 'different'
      config2.reload
      config2.idp_entity_id.should == 'different2'
    end

    it "should use the first config as the default" do
      update_saml
      @account.account_authorization_config.idp_entity_id.should == 'http://example.com/saml1'
    end

    it "should create new configs if they are reordered" do
      update_saml
      config1 = @account.account_authorization_configs.first
      config2 = @account.account_authorization_configs.second

      update_saml(:account_authorization_config => {"0" => @saml2, "1" => @saml1})
      @account.reload
      @account.account_authorization_configs.count.should == 2

      config3 = @account.account_authorization_configs.first
      config4 = @account.account_authorization_configs.second
      config3.idp_entity_id.should == 'http://example.com/saml2'
      config3.id.should_not == config2.id
      config4.idp_entity_id.should == 'http://example.com/saml1'
      config4.id.should_not == config1.id
    end

    it "should set the discovery url" do
      update_saml({:account_authorization_config => {"0" => @saml1, "1" => @saml2}, :discovery_url => 'http://example.com/auth_discovery'})
      @account.reload
      @account.auth_discovery_url.should == 'http://example.com/auth_discovery'
    end

    it "should clear the discovery url" do
      @account.auth_discovery_url = 'http://example.com/auth_discovery'
      @account.save!
      update_saml({:account_authorization_config => {"0" => @saml1, "1" => @saml2}, :discovery_url => ''})
      @account.reload
      @account.auth_discovery_url.should == nil

      @account.auth_discovery_url = 'http://example.com/auth_discovery'
      @account.save!
      update_saml({:account_authorization_config => {"0" => @saml1}, :discovery_url => 'http://example.com/wutwut'})
      @account.reload
      @account.auth_discovery_url.should == nil
    end

  end
end
