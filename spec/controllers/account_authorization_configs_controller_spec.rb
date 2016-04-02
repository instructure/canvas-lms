#
# Copyright (C) 2015 - 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountAuthorizationConfigsController do

  let!(:account) { Account.create! }

  before do
    admin = account_admin_user(account: account)
    user_session(admin)
  end

  describe "GET #index" do

    let(:saml_hash) do
      {
        'auth_type' => 'saml',
        'idp_entity_id' => 'http://example.com/saml1',
        'log_in_url' => 'http://example.com/saml1/sli',
        'log_out_url' => 'http://example.com/saml1/slo',
        'certificate_fingerprint' => '111222',
        'identifier_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
      }
    end

    let(:cas_hash) { { "auth_type" => "cas", "auth_base" => "127.0.0.1" } }

    let(:ldap_hash) do
      {
        'auth_type' => 'ldap',
        'auth_host' => '127.0.0.1',
        'auth_filter' => 'filter1',
        'auth_username' => 'username1',
        'auth_password' => 'password1'
      }
    end

    context "with no aacs" do
      it "renders ok" do
        get 'index', account_id: account.id
        expect(response).to be_success
      end
    end

    context "with an AAC" do
      it "renders ok" do
        account.authentication_providers.create!(saml_hash)
        get 'index', account_id: account.id
        expect(response).to be_success
      end
    end

  end

  describe "saml_testing" do
    it "requires saml configuration to test" do
      get "saml_testing", account_id: account.id, format: :json
      expect(response).to be_success
      expect(response.body).to match("A SAML configuration is required to test SAML")
    end
  end

  describe "POST #create" do

    it "adds a new auth config successfully" do
      cas = {
        auth_type: 'cas',
        auth_base: 'http://example.com',
      }
      post "create", { account_id: account.id }.merge(cas)

      account.reload
      aac = account.authentication_providers.active.where(auth_type: 'cas').first
      expect(aac).to be_present
    end

    it "adds a singleton type successfully" do
      linkedin = {
        auth_type: 'linkedin',
        client_id: '1',
        client_secret: '2'
      }
      post "create", { account_id: account.id }.merge(linkedin)

      account.reload
      aac = account.authentication_providers.active.where(auth_type: 'linkedin').first
      expect(aac).to be_present
    end

    it "rejects a singleton type if it already exists" do
      linkedin = {
        auth_type: 'linkedin',
        client_id: '1',
        client_secret: '2'
      }
      account.authentication_providers.create!(linkedin)

      post "create", { format: :json, account_id: account.id }.merge(linkedin)
      expect(response.code).to eq "422"
    end

    it "allows multiple non-singleton types" do
      cas = {
        auth_type: 'cas',
        auth_base: 'http://example.com/cas2',
      }
      account.authentication_providers.create!({
        auth_type: 'cas',
        auth_base: 'http://example.com/cas'
      })
      post "create", { account_id: account.id }.merge(cas)

      account.reload
      aac_count = account.authentication_providers.active.where(auth_type: 'cas').count
      expect(aac_count).to eq 2
    end

    it "allows re-adding a singleton type that was previously deleted" do
      linkedin = {
        auth_type: 'linkedin',
        client_id: '1',
        client_secret: '2'
      }
      aac = account.authentication_providers.create!(linkedin)
      aac.destroy

      post "create", { account_id: account.id }.merge(linkedin)
      account.reload
      aac = account.authentication_providers.active.where(auth_type: 'linkedin').first
      expect(aac).to be_present
    end

  end
end
