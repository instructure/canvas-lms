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

describe "AccountAuthorizationConfigs API", :type => :integration do
  before do
    @account = account_model(:name => 'root')
    user_with_pseudonym(:active_all => true, :account => @account)
    @account.add_user(@user)
  end

  it "should set the authorization config" do
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'update_all', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"auth_type" => "cas", "auth_base" => "127.0.0.1"}}})
    @account.reload
    @account.account_authorization_configs.size.should == 1
    config = @account.account_authorization_configs.first
    config.auth_type.should == 'cas'
    config.auth_base.should == '127.0.0.1'
  end

  it "should set multiple configs" do
    ldap1 = {'auth_type' => 'ldap', 'auth_host' => '127.0.0.1', 'auth_filter' => 'filter1', 'auth_username' => 'username1', 'auth_password' => 'password1'}
    ldap2 = {'auth_type' => 'ldap', 'auth_host' => '127.0.0.2', 'auth_filter' => 'filter2', 'auth_username' => 'username2', 'auth_password' => 'password2'}
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'update_all', :account_id => @account.id.to_s, :format => 'json' },
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
             { :controller => 'account_authorization_configs', :action => 'update_all', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"id" => config.id.to_s, "auth_type" => "cas", "auth_base" => "127.0.0.2"}}})
    @account.reload
    config.reload

    @account.account_authorization_configs.size.should == 1
    @account.account_authorization_configs.first.should == config
    config.auth_base.should == '127.0.0.2'
  end

  it "should delete configs not referenced" do
    config = @account.account_authorization_configs.create!("auth_type" => "cas", "auth_base" => "127.0.0.1")
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'update_all', :account_id => @account.id.to_s, :format => 'json' })
    @account.reload
    @account.account_authorization_configs.should be_empty
  end

  it "should discard config parameters not recognized for the given auth_type" do
    api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'update_all', :account_id => @account.id.to_s, :format => 'json' },
             { :account_authorization_config => {"0" => {"auth_type" => "cas", "auth_base" => "127.0.0.1", "auth_filter" => "discarded"}}})
    @account.reload
    @account.account_authorization_configs.size.should == 1
    config = @account.account_authorization_configs.first
    config.auth_type.should == 'cas'
    config.auth_filter.should be_nil
  end
end
