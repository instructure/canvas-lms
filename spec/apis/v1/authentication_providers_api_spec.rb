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

describe "AuthenticationProviders API", type: :request do
  before :once do
    @account = account_model(:name => 'root')
    user_with_pseudonym(:active_all => true, :account => @account)
    @account.authentication_providers.scope.delete_all
    @account.account_users.create!(user: @user)
    @cas_hash = {"auth_type" => "cas",
                 "auth_base" => "127.0.0.1",
                 "jit_provisioning" => false}
    @saml_hash = {'auth_type' => 'saml',
                  'idp_entity_id' => 'http://example.com/saml1',
                  'log_in_url' => 'http://example.com/saml1/sli',
                  'log_out_url' => 'http://example.com/saml1/slo',
                  'certificate_fingerprint' => '111222',
                  'identifier_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
                  'federated_attributes' => {},
                  'jit_provisioning' => false}
    @ldap_hash = {'auth_type' => 'ldap',
                  'auth_host' => '127.0.0.1',
                  'auth_filter' => 'filter1',
                  'auth_username' => 'username1',
                  'auth_password' => 'password1',
                  'jit_provisioning' => false}
  end

  context "/index" do
    def call_index(status=200)
      api_call(:get, "/api/v1/accounts/#{@account.id}/authentication_providers",
             { :controller => 'authentication_providers', :action => 'index', :account_id => @account.id.to_s, :format => 'json' },
             {}, {}, :expected_status => status)
    end

    it "should return all aacs in position order" do
      @account.authentication_providers.create!(@saml_hash.merge(:idp_entity_id => "a"))
      @account.authentication_providers.create!(@saml_hash.merge(:idp_entity_id => "d"))
      config3 = @account.authentication_providers.create!(@saml_hash.merge(:idp_entity_id => "r"))
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
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/authentication_providers",
             { :controller => 'authentication_providers', :action => 'create', :account_id => @account.id.to_s, :format => 'json' },
             params, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should create a saml aac" do
      json = call_create(@saml_hash)
      aac = @account.authentication_providers.first
      expect(aac.auth_type).to eq 'saml'
      expect(aac.idp_entity_id).to eq 'http://example.com/saml1'
      expect(aac.log_in_url).to eq 'http://example.com/saml1/sli'
      expect(aac.log_out_url).to eq 'http://example.com/saml1/slo'
      expect(aac.certificate_fingerprint).to eq '111222'
      expect(aac.identifier_format).to eq 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
      expect(aac.position).to eq 1
    end

    it "should work with rails form style params" do
      call_create({:authentication_provider => @saml_hash})
      aac = @account.authentication_providers.first
      expect(aac.auth_type).to eq 'saml'
      expect(aac.idp_entity_id).to eq 'http://example.com/saml1'
    end

    it "should create multiple saml aacs" do
      call_create(@saml_hash)
      call_create(@saml_hash.merge('idp_entity_id' => "secondeh"))

      aac1 = @account.authentication_providers.first
      expect(aac1.idp_entity_id).to eq 'http://example.com/saml1'
      expect(aac1.position).to eq 1

      aac2 = @account.authentication_providers.last
      expect(aac2.idp_entity_id).to eq 'secondeh'
      expect(aac2.position).to eq 2
    end

    it "should create an ldap aac" do
      call_create(@ldap_hash)
      aac = @account.authentication_providers.first
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
      aac = @account.authentication_providers.first
      expect(aac.auth_host).to eq '127.0.0.1'
      expect(aac.position).to eq 1
      aac2 = @account.authentication_providers.last
      expect(aac2.auth_host).to eq '127.0.0.2'
      expect(aac2.position).to eq 2
    end
    it "should default ldap auth_over_tls to 'start_tls'" do
      call_create(@ldap_hash)
      expect(@account.authentication_providers.first.auth_over_tls).to eq 'start_tls'
    end

    it "should create a cas aac" do
      call_create(@cas_hash)

      aac = @account.authentication_providers.first
      expect(aac.auth_type).to eq 'cas'
      expect(aac.auth_base).to eq '127.0.0.1'
      expect(aac.position).to eq 1
    end

    it "does not error when mixing auth_types (for now)" do
      call_create(@ldap_hash)
      call_create(@saml_hash, 200)
    end

    it "should update positions" do
      call_create(@ldap_hash)
      call_create(@ldap_hash.merge('auth_host' => '127.0.0.2', 'position' => 1))

      expect(@account.authentication_providers.first.auth_host).to eq '127.0.0.2'

      call_create(@ldap_hash.merge('auth_host' => '127.0.0.3', 'position' => 2))

      expect(@account.authentication_providers[0].auth_host).to eq '127.0.0.2'
      expect(@account.authentication_providers[1].auth_host).to eq '127.0.0.3'
      expect(@account.authentication_providers[2].auth_host).to eq '127.0.0.1'
    end

    it "should error if empty post params sent" do
      json = call_create({}, 422)
      expect(json['errors'].first).to eq({
        'field' => 'auth_type',
        'message' => "invalid auth_type, must be one of #{AuthenticationProvider.valid_auth_types.join(',')}",
        'error_code' => 'inclusion'
      })
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      call_create({}, 401)
    end

    it "should disable open registration when setting delegated auth" do
      @account.settings = { open_registration: true }
      @account.save!
      call_create(@cas_hash)
      expect(@account.open_registration?).to be_falsey
    end

    it "should not allow creation of duplicate singleton providers" do
      call_create({ auth_type: 'facebook' })
      call_create({ auth_type: 'facebook' }, 422)
    end
  end

  context "/show" do
    def call_show(id, status = 200)
      api_call(:get, "/api/v1/accounts/#{@account.id}/authentication_providers/#{id}",
             { :controller => 'authentication_providers', :action => 'show', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             {}, {}, :expected_status => status)
    end

    it "should return saml aac" do
      aac = @account.authentication_providers.create!(@saml_hash)
      json = call_show(aac.id)

      @saml_hash['id'] = aac.id
      @saml_hash['position'] = 1
      @saml_hash['login_handle_name'] = nil
      @saml_hash['change_password_url'] = nil
      @saml_hash['requested_authn_context'] = nil
      @saml_hash['login_attribute'] = 'NameID'
      @saml_hash['unknown_user_url'] = nil
      @saml_hash['parent_registration'] = false
      @saml_hash['metadata_uri'] = nil
      @saml_hash['sig_alg'] = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      @saml_hash['strip_domain_from_login_attribute'] = false
      expect(json).to eq @saml_hash
    end

    it "should return ldap aac" do
      aac = @account.authentication_providers.create!(@ldap_hash)
      json = call_show(aac.id)

      @ldap_hash.delete 'auth_password'
      @ldap_hash['id'] = aac.id
      @ldap_hash['auth_port'] = nil
      @ldap_hash['auth_base'] = nil
      @ldap_hash['auth_over_tls'] = 'start_tls'
      @ldap_hash['identifier_format'] = nil
      @ldap_hash['position'] = 1
      expect(json).to eq @ldap_hash
    end

    it "should return cas aac" do
      aac = @account.authentication_providers.create!(@cas_hash)
      json = call_show(aac.id)

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
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/authentication_providers/#{id}",
             { :controller => 'authentication_providers', :action => 'update', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             params, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should update a saml aac" do
      aac = @account.authentication_providers.create!(@saml_hash)
      @saml_hash['idp_entity_id'] = 'hahahaha'
      call_update(aac.id, @saml_hash)

      aac.reload
      expect(aac.idp_entity_id).to eq 'hahahaha'
    end


    it "should return error when it fails to update" do
      aac = @account.authentication_providers.create!(@saml_hash)
      @saml_hash['metadata_uri'] = 'hahahaha_super_invalid'
      json = call_update(aac.id, @saml_hash, 422)
      expect(json['errors'].first['field']).to eq 'metadata_uri'
    end

    it "updates federated attributes" do
      aac = @account.authentication_providers.create!(@saml_hash)
      json = call_update(aac.id, 'auth_type' => 'saml',
                         'federated_attributes' => { 'integration_id' => 'internal_id' })
      # jit provisioning off; short form output
      expect(json['federated_attributes']).to eq('integration_id' => 'internal_id')
      aac.reload
      expect(aac.federated_attributes).to eq('integration_id' => { 'attribute' => 'internal_id',
                                                                   'provisioning_only' => false })
    end

    it "should work with rails form style params" do
      aac = @account.authentication_providers.create!(@saml_hash)
      @saml_hash['idp_entity_id'] = 'hahahaha'
      call_update(aac.id, {:authentication_provider => @saml_hash})

      aac.reload
      expect(aac.idp_entity_id).to eq 'hahahaha'
    end

    it "should update an ldap aac" do
      aac = @account.authentication_providers.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      call_update(aac.id, @ldap_hash)

      aac.reload
      expect(aac.auth_host).to eq '192.168.0.1'
    end

    it "should update a cas aac" do
      aac = @account.authentication_providers.create!(@cas_hash)
      @cas_hash['auth_base'] = '192.168.0.1'
      call_update(aac.id, @cas_hash)

      aac.reload
      expect(aac.auth_base).to eq '192.168.0.1'
    end

    it "should error when mixing auth_types" do
      aac = @account.authentication_providers.create!(@saml_hash)
      json = call_update(aac.id, @cas_hash, 400)
      expect(json['message']).to eq 'Can not change type of authorization config, please delete and create new config.'
    end

    it "should update positions" do
      @account.authentication_providers.create!(@ldap_hash)
      @ldap_hash['auth_host'] = '192.168.0.1'
      aac2 = @account.authentication_providers.create!(@ldap_hash)
      @ldap_hash['position'] = 1
      call_update(aac2.id, @ldap_hash)

      expect(@account.authentication_providers.first.id).to eq aac2.id
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
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/authentication_providers/#{id}",
             { :controller => 'authentication_providers', :action => 'destroy', :account_id => @account.id.to_s, :id => id.to_param, :format => 'json' },
             {}, {}, :expected_status => status)
      @account.reload
      json
    end

    it "should delete" do
      aac = @account.authentication_providers.create!(@saml_hash)
      call_destroy(aac.id)

      expect(@account.non_canvas_auth_configured?).to be_falsey
    end

    it "should reposition correctly" do
      aac = @account.authentication_providers.create!(@saml_hash)
      aac2 = @account.authentication_providers.create!(@saml_hash)
      aac3 = @account.authentication_providers.create!(@saml_hash)
      aac4 = @account.authentication_providers.create!(@saml_hash)

      call_destroy(aac.id)
      aac2.reload
      aac3.reload
      aac4.reload
      expect(@account.authentication_providers.active.count).to eq 3
      expect(@account.authentication_providers.active.first.id).to eq aac2.id
      expect(aac2.position).to eq 1
      expect(aac3.position).to eq 2
      expect(aac4.position).to eq 3

      call_destroy(aac3.id)
      aac2.reload
      aac4.reload
      expect(@account.authentication_providers.active.count).to eq 2
      expect(@account.authentication_providers.active.first.id).to eq aac2.id
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

  describe "sso settings" do
    let(:sso_path) do
      "/api/v1/accounts/#{@account.id}/sso_settings"
    end

    def update_settings(settings, expected_status)
      api_call(:put,
               sso_path,
               {
                 controller: 'authentication_providers',
                 action: 'update_sso_settings',
                 account_id: @account.id.to_s,
                 format: 'json'
               },
               settings,
               {},
               expected_status: expected_status)
    end

    it "requires authorization" do
      course_with_student(course: @course)
      update_settings({}, 401)
    end

    it "sets auth settings" do
      payload = {
        'sso_settings' => {
          'auth_discovery_url' => 'https://www.discover.com'
        }
      }
      update_settings(payload, 200)
      expect(@account.reload.auth_discovery_url).to eq('https://www.discover.com')
    end

    it "ignores settings that don't exist" do
      payload = {
        'sso_settings' => {
          'abcdefg' => 'balongna'
        }
      }
      update_settings(payload, 200)
    end

    context "with login handle pre-existing on account" do
      before do
        @account.login_handle_name = "LoginHandleSet"
        @account.save!
      end

      it "clears settings with a key but no value" do
        payload = {
          'sso_settings' => {
            'login_handle_name' => ''
          }
        }
        update_settings(payload, 200)
        expect(@account.reload.login_handle_name).to be_nil
      end

      it "leaves unspecified settings alone" do
        payload = {
          'sso_settings' => {
            'auth_discovery_url' => 'someurl'
          }
        }
        update_settings(payload, 200)
        expect(@account.reload.login_handle_name).to eq("LoginHandleSet")
      end

      it "can get the current state of settings" do
        response = api_call(:get,
                            sso_path,
                            {
                              controller: "authentication_providers",
                              action: "show_sso_settings",
                              account_id: @account.id.to_s,
                              format: 'json'
                            },{},{},
                            expected_status: 200)

        expect(response['sso_settings']['login_handle_name']).
          to eq("LoginHandleSet")
      end
    end
  end

  describe "API JSON" do
    describe 'federated_attributes' do
      it 'excludes provisioning only attributes when jit_provisioning is off' do
        aac = AuthenticationProvider::SAML.new(
          federated_attributes: { 'integration_id' => { 'attribute' => 'internal_id' },
                                  'sis_user_id' => { 'attribute' => 'external_id',
                                                     'provisioning_only' => true }}
        )
        expect(aac.federated_attributes_for_api).to eq('integration_id' => 'internal_id')
      end

      it 'uses full form when jit_provisioning is on' do
        federated_attributes = { 'integration_id' => { 'attribute' => 'internal_id',
                                                       'provisioning_only' => false },
                                 'sis_user_id' => { 'attribute' => 'external_id',
                                                    'provisioning_only' => true }}
        aac = AuthenticationProvider::SAML.new(federated_attributes: federated_attributes,
                                                   jit_provisioning: true)
        expect(aac.federated_attributes_for_api).to eq(federated_attributes)
      end
    end
  end
end
