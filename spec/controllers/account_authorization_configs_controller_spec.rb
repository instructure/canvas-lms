require 'spec_helper'

RSpec.describe AccountAuthorizationConfigsController, type: :controller do

  describe "GET #index" do
    let!(:account) { Account.create! }

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

    before do
      admin = account_admin_user(account: account)
      user_session(admin)
    end

    context "with no aacs" do
      it "renders ok" do
        get 'index', account_id: account.id
        expect(response).to be_success
      end
    end

    context "with an AAC" do
      it "renders ok" do
        account.account_authorization_configs.create!(saml_hash)
        get 'index', account_id: account.id
        expect(response).to be_success
      end
    end

  end

end
