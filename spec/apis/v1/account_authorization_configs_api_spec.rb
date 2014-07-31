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
    @cas_hash = {"auth_type" => "cas", "auth_base" => "127.0.0.1"}
    @saml_hash = {'auth_type' => 'saml', 'idp_entity_id' => 'http://example.com/saml1', 'log_in_url' => 'http://example.com/saml1/sli', 'log_out_url' => 'http://example.com/saml1/slo', 'certificate_fingerprint' => '111222', 'identifier_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'}
    @ldap_hash = {'auth_type' => 'ldap', 'auth_host' => '127.0.0.1', 'auth_filter' => 'filter1', 'auth_username' => 'username1', 'auth_password' => 'password1'}
  end

  context "/index" do
    def call_index(status=200)
      api_call(:get, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'index', :account_id => @account.id.to_s, :format => 'json' },
             {}, {}, :expected_status => status)
    end

    it "should return all aacs in position order" do
      config1 = @account.account_authorization_configs.create!(@saml_hash.merge(:idp_entity_id => "a"))
      config2 = @account.account_authorization_configs.create!(@saml_hash.merge(:idp_entity_id => "d"))
      config3 = @account.account_authorization_configs.create!(@saml_hash.merge(:idp_entity_id => "r"))
      config3.move_to_top
      config3.save!

      res = call_index

      res.map{|c|c['idp_entity_id']}.join.should == 'rad'
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_index(401)
    end
  end

  context "/create" do
    # the deprecated mass-update/create is tested in account_authorization_configs_deprecated_api_spec.rb

    def call_create(params, status = 200)
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/account_authorization_configs",
             { :controller => 'account_authorization_configs', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             params, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should create a saml aac" do
      call_create(@saml_hash)
      aac = @account.account_authorization_config
      aac.auth_type.should == 'saml'
      aac.idp_entity_id.should == 'http://example.com/saml1'
      aac.log_in_url.should == 'http://example.com/saml1/sli'
      aac.log_out_url.should == 'http://example.com/saml1/slo'
      aac.certificate_fingerprint.should == '111222'
      aac.identifier_format.should == 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
      aac.position.should == 1
    end

    it "should work with rails form style params" do
      call_create({:account_authorization_config => @saml_hash})
      aac = @account.account_authorization_config
      aac.auth_type.should == 'saml'
      aac.idp_entity_id.should == 'http://example.com/saml1'
    end

    it "should create multiple saml aacs" do
      call_create(@saml_hash)
      call_create(@saml_hash.merge('idp_entity_id' => "secondeh"))

      aac1 = @account.account_authorization_configs.first
      aac1.idp_entity_id.should == 'http://example.com/saml1'
      aac1.position.should == 1

      aac2 = @account.account_authorization_configs.last
      aac2.idp_entity_id.should == 'secondeh'
      aac2.position.should == 2
    end

    it "should create an ldap aac" do
      call_create(@ldap_hash)
      aac = @account.account_authorization_config
      aac.auth_type.should == 'ldap'
      aac.auth_host.should == '127.0.0.1'
      aac.auth_filter.should == 'filter1'
      aac.auth_username.should == 'username1'
      aac.auth_decrypted_password.should == 'password1'
      aac.position.should == 1
    end
    it "should create multiple ldap aacs" do
      call_create(@ldap_hash)
      call_create(@ldap_hash.merge('auth_host' => '127.0.0.2'))
      aac = @account.account_authorization_configs.first
      aac.auth_host.should == '127.0.0.1'
      aac.position.should == 1
      aac2 = @account.account_authorization_configs.last
      aac2.auth_host.should == '127.0.0.2'
      aac2.position.should == 2
    end
    it "should default ldap auth_over_tls to 'start_tls'" do
      call_create(@ldap_hash)
      @account.account_authorization_config.auth_over_tls.should == 'start_tls'
    end

    it "should create a cas aac" do
      call_create(@cas_hash)

      aac = @account.account_authorization_config
      aac.auth_type.should == 'cas'
      aac.auth_base.should == '127.0.0.1'
      aac.position.should == 1
    end

    it "should not allow multiple cas aacs (for now)" do
      call_create(@cas_hash)
      json = call_create(@cas_hash, 422)
      json.keys.sort.should == ['error_report_id', 'errors']
      json['errors'].should == [
        { "field" => "auth_type", "error_code" => "multiple_cas_configs", "message" => "Only one CAS config is supported" },
      ]
    end

    it "should error when mixing auth_types (for now)" do
      call_create(@ldap_hash)
      json = call_create(@saml_hash, 422)
      json['errors'].first['error_code'].should == 'mixing_authentication_types'
    end

    it "should update positions" do
      call_create(@ldap_hash)
      call_create(@ldap_hash.merge('auth_host' => '127.0.0.2', 'position' => 1))

      @account.account_authorization_config.auth_host.should == '127.0.0.2'

      call_create(@ldap_hash.merge('auth_host' => '127.0.0.3', 'position' => 2))

      @account.account_authorization_configs[0].auth_host.should == '127.0.0.2'
      @account.account_authorization_configs[1].auth_host.should == '127.0.0.3'
      @account.account_authorization_configs[2].auth_host.should == '127.0.0.1'
    end

    it "should error if deprecated and new style are used" do
      json = call_create({:account_authorization_config => {"0" => @ldap_hash}}.merge(@ldap_hash), 400)
      json.keys.sort.should == ['error_report_id', 'errors']
      json['errors'].should == [
        "error_code" => "deprecated_request_syntax",
        "message" => "This request syntax has been deprecated",
        "field" => nil,
      ]
    end

    it "should error if empty post params sent" do
      json = call_create({}, 422)
      json['errors'].first.should == { 'field' => 'auth_type', 'message' => "invalid auth_type, must be one of #{AccountAuthorizationConfig::VALID_AUTH_TYPES.join(',')}", 'error_code' => 'inclusion' }
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_create({}, 401)
    end

    it "should disable open registration when setting delegated auth" do
      @account.settings = { :open_registration => true }
      @account.save!
      call_create(@cas_hash)
      @account.open_registration?.should be_false
    end
  end

  context "/show" do
    def call_show(id, status = 200)
      api_call(:get, "/api/v1/accounts/#{@account.id}/account_authorization_configs/#{id}",
             { :controller => 'account_authorization_configs', :action => 'show', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             {}, {}, :expected_status => status)
    end

    it "should return saml aac" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      json = call_show(aac.id)

      @saml_hash['id'] = aac.id
      @saml_hash['position'] = 1
      @saml_hash['login_handle_name'] = nil
      @saml_hash['change_password_url'] = nil
      @saml_hash['requested_authn_context'] = nil
      @saml_hash['login_attribute'] = 'nameid'
      json.should == @saml_hash
    end

    it "should return ldap aac" do
      aac = @account.account_authorization_configs.create!(@ldap_hash)
      json = call_show(aac.id)

      @ldap_hash.delete 'auth_password'
      @ldap_hash['id'] = aac.id
      @ldap_hash['auth_port'] = nil
      @ldap_hash['auth_base'] = nil
      @ldap_hash['auth_over_tls'] = nil
      @ldap_hash['login_handle_name'] = nil
      @ldap_hash['identifier_format'] = nil
      @ldap_hash['change_password_url'] = nil
      @ldap_hash['position'] = 1
      json.should == @ldap_hash
    end

    it "should return cas aac" do
      aac = @account.account_authorization_configs.create!(@cas_hash)
      json = call_show(aac.id)

      @cas_hash['login_handle_name'] = nil
      @cas_hash['log_in_url'] = nil
      @cas_hash['id'] = aac.id
      @cas_hash['position'] = 1
      json.should == @cas_hash
    end

    it "should 404" do
      call_show(0, 404)
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_show(0, 401)
    end
  end

  context "/update" do
    def call_update(id, params, status = 200)
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/#{id}",
             { :controller => 'account_authorization_configs', :action => 'update', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             params, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should update a saml aac" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      @saml_hash['idp_entity_id'] = 'hahahaha'
      call_update(aac.id, @saml_hash)

      aac.reload
      aac.idp_entity_id.should == 'hahahaha'
    end

    it "should work with rails form style params" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      @saml_hash['idp_entity_id'] = 'hahahaha'
      call_update(aac.id, {:account_authorization_config => @saml_hash})

      aac.reload
      aac.idp_entity_id.should == 'hahahaha'
    end

    it "should update an ldap aac" do
      aac = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      call_update(aac.id, @ldap_hash)

      aac.reload
      aac.auth_host.should == '192.168.0.1'
    end

    it "should update a cas aac" do
      aac = @account.account_authorization_configs.create!(@cas_hash)
      @cas_hash['auth_base'] = '192.168.0.1'
      call_update(aac.id, @cas_hash)

      aac.reload
      aac.auth_base.should == '192.168.0.1'
    end

    it "should error when mixing auth_types" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      json = call_update(aac.id, @cas_hash, 400)
      json['message'].should == 'Can not change type of authorization config, please delete and create new config.'
    end

    it "should update positions" do
      aac = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      aac2 = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['position'] = 1
      call_update(aac2.id, @ldap_hash)

      @account.account_authorization_config.id.should == aac2.id
    end

    it "should 404" do
      call_update(0, {}, 404)
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_update(0, {}, 401)
    end
  end

  context "/destroy" do
    def call_destroy(id, status = 200)
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/account_authorization_configs/#{id}",
             { :controller => 'account_authorization_configs', :action => 'destroy', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             {}, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should delete" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      call_destroy(aac.id)

      @account.account_authorization_config.should be_nil
    end

    it "should reposition correctly" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      aac2 = @account.account_authorization_configs.create!(@saml_hash)
      aac3 = @account.account_authorization_configs.create!(@saml_hash)
      aac4 = @account.account_authorization_configs.create!(@saml_hash)

      call_destroy(aac.id)
      aac2.reload
      aac3.reload
      aac4.reload
      @account.account_authorization_configs.count.should == 3
      @account.account_authorization_config.id.should == aac2.id
      aac2.position.should == 1
      aac3.position.should == 2
      aac4.position.should == 3

      call_destroy(aac3.id)
      aac2.reload
      aac4.reload
      @account.account_authorization_configs.count.should == 2
      @account.account_authorization_config.id.should == aac2.id
      aac2.position.should == 1
      aac4.position.should == 2
    end

    it "should 404" do
      call_destroy(0, 404)
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_destroy(0, 401)
    end
  end

  context "discovery url" do
    append_before do
      @account.auth_discovery_url = "http://example.com/auth"
      @account.save!
    end

    it "should get the url" do
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'show_discovery_url', :account_id => @account.id.to_s, :format => 'json' })
      json.should == {'discovery_url' => @account.auth_discovery_url}
    end

    it "should set the url" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'update_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
             {'discovery_url' => 'http://example.com/different_url'})
      json.should == {'discovery_url' => 'http://example.com/different_url'}
      @account.reload
      @account.auth_discovery_url.should == 'http://example.com/different_url'
    end

    it "should clear if set to empty string" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'update_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
             {'discovery_url' => ''})
      json.should == {'discovery_url' => nil}
      @account.reload
      @account.auth_discovery_url.should == nil
    end

    it "should delete the url" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'destroy_discovery_url', :account_id => @account.id.to_s, :format => 'json' })
      json.should == {'discovery_url' => nil}
      @account.reload
      @account.auth_discovery_url.should == nil
    end

    it "should return unauthorized" do
      course_with_student(:course => @course)
      api_call(:get, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'show_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
      {},{}, :expected_status => 401)
      api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'update_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
      {'discovery_url' => ''},{}, :expected_status => 401)
      @account.reload; @account.auth_discovery_url = "http://example.com/auth"
      api_call(:delete, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'destroy_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
      {},{}, :expected_status => 401)
      @account.reload; @account.auth_discovery_url = "http://example.com/auth"
    end

  end

end
