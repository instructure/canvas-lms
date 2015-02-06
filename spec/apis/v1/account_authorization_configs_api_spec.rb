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
  before :once do
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

      expect(res.map{|c|c['idp_entity_id']}.join).to eq 'rad'
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
      expect(aac.auth_type).to eq 'saml'
      expect(aac.idp_entity_id).to eq 'http://example.com/saml1'
      expect(aac.log_in_url).to eq 'http://example.com/saml1/sli'
      expect(aac.log_out_url).to eq 'http://example.com/saml1/slo'
      expect(aac.certificate_fingerprint).to eq '111222'
      expect(aac.identifier_format).to eq 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
      expect(aac.position).to eq 1
    end

    it "should work with rails form style params" do
      call_create({:account_authorization_config => @saml_hash})
      aac = @account.account_authorization_config
      expect(aac.auth_type).to eq 'saml'
      expect(aac.idp_entity_id).to eq 'http://example.com/saml1'
    end

    it "should create multiple saml aacs" do
      call_create(@saml_hash)
      call_create(@saml_hash.merge('idp_entity_id' => "secondeh"))

      aac1 = @account.account_authorization_configs.first
      expect(aac1.idp_entity_id).to eq 'http://example.com/saml1'
      expect(aac1.position).to eq 1

      aac2 = @account.account_authorization_configs.last
      expect(aac2.idp_entity_id).to eq 'secondeh'
      expect(aac2.position).to eq 2
    end

    it "should create an ldap aac" do
      call_create(@ldap_hash)
      aac = @account.account_authorization_config
      expect(aac.auth_type).to eq 'ldap'
      expect(aac.auth_host).to eq '127.0.0.1'
      expect(aac.auth_filter).to eq 'filter1'
      expect(aac.auth_username).to eq 'username1'
      expect(aac.auth_decrypted_password).to eq 'password1'
      expect(aac.position).to eq 1
    end
    it "should create multiple ldap aacs" do
      call_create(@ldap_hash)
      call_create(@ldap_hash.merge('auth_host' => '127.0.0.2'))
      aac = @account.account_authorization_configs.first
      expect(aac.auth_host).to eq '127.0.0.1'
      expect(aac.position).to eq 1
      aac2 = @account.account_authorization_configs.last
      expect(aac2.auth_host).to eq '127.0.0.2'
      expect(aac2.position).to eq 2
    end
    it "should default ldap auth_over_tls to 'start_tls'" do
      call_create(@ldap_hash)
      expect(@account.account_authorization_config.auth_over_tls).to eq 'start_tls'
    end

    it "should create a cas aac" do
      call_create(@cas_hash)

      aac = @account.account_authorization_config
      expect(aac.auth_type).to eq 'cas'
      expect(aac.auth_base).to eq '127.0.0.1'
      expect(aac.position).to eq 1
    end

    it "should not allow multiple cas aacs (for now)" do
      call_create(@cas_hash)
      json = call_create(@cas_hash, 422)
      expect(json.keys.sort).to eq ['error_report_id', 'errors']
      expect(json['errors']).to eq [
        { "field" => "auth_type", "error_code" => "multiple_cas_configs", "message" => "Only one CAS config is supported" },
      ]
    end

    it "should error when mixing auth_types (for now)" do
      call_create(@ldap_hash)
      json = call_create(@saml_hash, 422)
      expect(json['errors'].first['error_code']).to eq 'mixing_authentication_types'
    end

    it "should update positions" do
      call_create(@ldap_hash)
      call_create(@ldap_hash.merge('auth_host' => '127.0.0.2', 'position' => 1))

      expect(@account.account_authorization_config.auth_host).to eq '127.0.0.2'

      call_create(@ldap_hash.merge('auth_host' => '127.0.0.3', 'position' => 2))

      expect(@account.account_authorization_configs[0].auth_host).to eq '127.0.0.2'
      expect(@account.account_authorization_configs[1].auth_host).to eq '127.0.0.3'
      expect(@account.account_authorization_configs[2].auth_host).to eq '127.0.0.1'
    end

    it "should error if deprecated and new style are used" do
      json = call_create({:account_authorization_config => {"0" => @ldap_hash}}.merge(@ldap_hash), 400)
      expect(json.keys.sort).to eq ['error_report_id', 'errors']
      expect(json['errors']).to eq [
        "error_code" => "deprecated_request_syntax",
        "message" => "This request syntax has been deprecated",
        "field" => nil,
      ]
    end

    it "should error if empty post params sent" do
      json = call_create({}, 422)
      expect(json['errors'].first).to eq({ 'field' => 'auth_type', 'message' => "invalid auth_type, must be one of #{AccountAuthorizationConfig::VALID_AUTH_TYPES.join(',')}", 'error_code' => 'inclusion' })
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_create({}, 401)
    end

    it "should disable open registration when setting delegated auth" do
      @account.settings = { :open_registration => true }
      @account.save!
      call_create(@cas_hash)
      expect(@account.open_registration?).to be_falsey
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
      @saml_hash['unknown_user_url'] = nil
      expect(json).to eq @saml_hash
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
      expect(json).to eq @ldap_hash
    end

    it "should return cas aac" do
      aac = @account.account_authorization_configs.create!(@cas_hash)
      json = call_show(aac.id)

      @cas_hash['login_handle_name'] = nil
      @cas_hash['log_in_url'] = nil
      @cas_hash['id'] = aac.id
      @cas_hash['position'] = 1
      @cas_hash['unknown_user_url'] = nil
      expect(json).to eq @cas_hash
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
      expect(aac.idp_entity_id).to eq 'hahahaha'
    end

    it "should work with rails form style params" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      @saml_hash['idp_entity_id'] = 'hahahaha'
      call_update(aac.id, {:account_authorization_config => @saml_hash})

      aac.reload
      expect(aac.idp_entity_id).to eq 'hahahaha'
    end

    it "should update an ldap aac" do
      aac = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      call_update(aac.id, @ldap_hash)

      aac.reload
      expect(aac.auth_host).to eq '192.168.0.1'
    end

    it "should update a cas aac" do
      aac = @account.account_authorization_configs.create!(@cas_hash)
      @cas_hash['auth_base'] = '192.168.0.1'
      call_update(aac.id, @cas_hash)

      aac.reload
      expect(aac.auth_base).to eq '192.168.0.1'
    end

    it "should error when mixing auth_types" do
      aac = @account.account_authorization_configs.create!(@saml_hash)
      json = call_update(aac.id, @cas_hash, 400)
      expect(json['message']).to eq 'Can not change type of authorization config, please delete and create new config.'
    end

    it "should update positions" do
      aac = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      aac2 = @account.account_authorization_configs.create!(@ldap_hash)
      @ldap_hash['position'] = 1
      call_update(aac2.id, @ldap_hash)

      expect(@account.account_authorization_config.id).to eq aac2.id
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

      expect(@account.account_authorization_config).to be_nil
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
      expect(@account.account_authorization_configs.count).to eq 3
      expect(@account.account_authorization_config.id).to eq aac2.id
      expect(aac2.position).to eq 1
      expect(aac3.position).to eq 2
      expect(aac4.position).to eq 3

      call_destroy(aac3.id)
      aac2.reload
      aac4.reload
      expect(@account.account_authorization_configs.count).to eq 2
      expect(@account.account_authorization_config.id).to eq aac2.id
      expect(aac2.position).to eq 1
      expect(aac4.position).to eq 2
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
    before do
      @account.auth_discovery_url = "http://example.com/auth"
      @account.save!
    end

    it "should get the url" do
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'show_discovery_url', :account_id => @account.id.to_s, :format => 'json' })
      expect(json).to eq({'discovery_url' => @account.auth_discovery_url})
    end

    it "should set the url" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'update_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
             {'discovery_url' => 'http://example.com/different_url'})
      expect(json).to eq({'discovery_url' => 'http://example.com/different_url'})
      @account.reload
      expect(@account.auth_discovery_url).to eq 'http://example.com/different_url'
    end

    it "should clear if set to empty string" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'update_discovery_url', :account_id => @account.id.to_s, :format => 'json' },
             {'discovery_url' => ''})
      expect(json).to eq({'discovery_url' => nil})
      @account.reload
      expect(@account.auth_discovery_url).to eq nil
    end

    it "should delete the url" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/account_authorization_configs/discovery_url",
             { :controller => 'account_authorization_configs', :action => 'destroy_discovery_url', :account_id => @account.id.to_s, :format => 'json' })
      expect(json).to eq({'discovery_url' => nil})
      @account.reload
      expect(@account.auth_discovery_url).to eq nil
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
