# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AuthenticationProvidersController do
  let!(:account) { Account.create! }

  let_once(:saml_hash) do
    {
      "auth_type" => "saml",
      "idp_entity_id" => "http://example.com/saml1",
      "log_in_url" => "http://example.com/saml1/sli",
      "log_out_url" => "http://example.com/saml1/slo",
      "certificate_fingerprint" => "111222",
      "identifier_format" => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    }
  end
  let_once(:cas_hash) { { "auth_type" => "cas", "auth_base" => "127.0.0.1" } }
  let_once(:ldap_hash) do
    {
      "auth_type" => "ldap",
      "auth_host" => "127.0.0.1",
      "auth_filter" => "filter1",
      "auth_username" => "username1",
      "auth_password" => "password1"
    }
  end
  let_once(:microsoft_hash) { { "auth_type" => "microsoft" } }

  before do
    admin = account_admin_user(account:)
    user_session(admin)
  end

  describe "GET #index" do
    context "with no aacs" do
      it "renders ok" do
        get "index", params: { account_id: account.id }
        expect(response).to be_successful
      end
    end

    context "with an AAC" do
      it "renders ok" do
        account.authentication_providers.create!(saml_hash)
        get "index", params: { account_id: account.id }
        expect(response).to be_successful
      end
    end

    context "with a Microsoft AAC" do
      it "renders ok" do
        account.authentication_providers.create!(microsoft_hash)
        get "index", params: { account_id: account.id }
        expect(response).to be_successful
      end
    end
  end

  describe "refresh_saml_metadata" do
    it "requires root manage account settings permission" do
      user_session(user_with_pseudonym(account:))
      provider = account.authentication_providers.create!(saml_hash)
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }
      expect(response).to have_http_status :unauthorized
    end

    it "renders not_found if provider doesn't exist" do
      provider = account.authentication_providers.create!(saml_hash)
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id + 1 }
      expect(response).to have_http_status :not_found
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id + 1 }, format: :json
      expect(response).to have_http_status :not_found
    end

    it "errors on unsupported auth type" do
      provider = account.authentication_providers.create!(microsoft_hash)
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }
      expect(flash[:error]).to match("Unsupported authentication type")
      expect(response).to be_redirect
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }, format: :json
      expect(response).to have_http_status :bad_request
      expect(response.body).to match("Unsupported authentication type")
    end

    it "errors on empty metadata_uri field" do
      provider = account.authentication_providers.create!(saml_hash)
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }
      expect(flash[:error]).to match("IdP metadata URI cannot be blank")
      expect(response).to be_redirect
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }, format: :json
      expect(response).to have_http_status :bad_request
      expect(response.body).to match("A valid metadata URI is required")
    end

    it "calls the metadata refresher" do
      allow_any_instance_of(AuthenticationProvider::SAML).to receive(:download_metadata).and_return("metadata")
      provider = account.authentication_providers.create!(saml_hash.merge(metadata_uri: "http://example.com/metadata"))
      expect(AuthenticationProvider::SAML::MetadataRefresher).to receive(:refresh_providers).twice.with(providers: [provider])
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }
      expect(flash[:notice]).to match("Metadata refresh has been initiated. Please check back")
      expect(response).to be_redirect
      get "refresh_saml_metadata", params: { account_id: account.id, authentication_provider_id: provider.id }, format: :json
      expect(response).to have_http_status :ok
    end
  end

  describe "start_debugging" do
    it "complains about unsupported auth type" do
      enable_cache do
        put "start_debugging", params: { account_id: account.id, authentication_provider_id: account.canvas_authentication_provider.id }, format: :json
        expect(response).to have_http_status :bad_request
        expect(response.body).to match("Unsupported authentication type")
        expect(account.canvas_authentication_provider).to_not be_debugging
      end
    end

    it "works for supported auth type" do
      enable_cache do
        provider = account.authentication_providers.create!(auth_type: "saml")
        put "start_debugging", params: { account_id: account.id, authentication_provider_id: provider.id }, format: :json
        expect(response).to be_successful
        expect(provider).to be_debugging
      end
    end
  end

  describe "POST #create" do
    let(:idp_xml) do
      <<~XML
        <?xml version="1.0"?>
        <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://sso.school.edu/idp/shibboleth">
          <IDPSSODescriptor protocolSupportEnumeration="urn:mace:shibboleth:1.0 urn:oasis:names:tc:SAML:1.1:protocol urn:oasis:names:tc:SAML:2.0:protocol">
            <KeyDescriptor use="signing">
              <ds:KeyInfo>
                <ds:X509Data>
                  <ds:X509Certificate>
                    MIIE8TCCA9mgAwIBAgIJAITusxON60cKMA0GCSqGSIb3DQEBBQUAMIGrMQswCQYD
                    VQQGEwJVUzENMAsGA1UECBMEVXRhaDEXMBUGA1UEBxMOU2FsdCBMYWtlIENpdHkx
                    GTAXBgNVBAoTEEluc3RydWN0dXJlLCBJbmMxEzARBgNVBAsTCk9wZXJhdGlvbnMx
                    IDAeBgNVBAMTF0NhbnZhcyBTQU1MIENlcnRpZmljYXRlMSIwIAYJKoZIhvcNAQkB
                    FhNvcHNAaW5zdHJ1Y3R1cmUuY29tMB4XDTEzMDQyMjE3NDQ0M1oXDTE1MDQyMjE3
                    NDQ0M1owgasxCzAJBgNVBAYTAlVTMQ0wCwYDVQQIEwRVdGFoMRcwFQYDVQQHEw5T
                    YWx0IExha2UgQ2l0eTEZMBcGA1UEChMQSW5zdHJ1Y3R1cmUsIEluYzETMBEGA1UE
                    CxMKT3BlcmF0aW9uczEgMB4GA1UEAxMXQ2FudmFzIFNBTUwgQ2VydGlmaWNhdGUx
                    IjAgBgkqhkiG9w0BCQEWE29wc0BpbnN0cnVjdHVyZS5jb20wggEiMA0GCSqGSIb3
                    DQEBAQUAA4IBDwAwggEKAoIBAQDHRYRp/slsoqD7iPFo+8UFjqd+LgSQ062x09CG
                    m5uW9smY/x2ig8hxfd05Dtk42wrA9frRh6QiEhtoy8qL/4g/LOmYq5USDdzLXsPF
                    /nqTVPkTOhGcuSpfJbxucRsMfGL6IvrGqLNxpyfroyV1dv9/fim+d6bs7js5k1i5
                    EkKksgVlnnpUpOx5pswWVcZICeIJwTMe1C0KHcpUMycZxMHueJ+Y7tWHtWW+R75T
                    QWdWjL+TevEL57B3cW19+9Sud2Y63DcwP6V0aDrwArxQwmp73uUb5ol6gSSvD+Ol
                    CIsf6S/5gqMdgqxJJsWqzBOTeDsVr8m2Dx3VX7Plho7pk06FAgMBAAGjggEUMIIB
                    EDAdBgNVHQ4EFgQUQy1zIfZP/NZKPYLGugNSjjBnTYgwgeAGA1UdIwSB2DCB1YAU
                    Qy1zIfZP/NZKPYLGugNSjjBnTYihgbGkga4wgasxCzAJBgNVBAYTAlVTMQ0wCwYD
                    VQQIEwRVdGFoMRcwFQYDVQQHEw5TYWx0IExha2UgQ2l0eTEZMBcGA1UEChMQSW5z
                    dHJ1Y3R1cmUsIEluYzETMBEGA1UECxMKT3BlcmF0aW9uczEgMB4GA1UEAxMXQ2Fu
                    dmFzIFNBTUwgQ2VydGlmaWNhdGUxIjAgBgkqhkiG9w0BCQEWE29wc0BpbnN0cnVj
                    dHVyZS5jb22CCQCE7rMTjetHCjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUA
                    A4IBAQC1dgkv3cT4KRMR42mIKgJRp4Jf7swUrtoAFOdOr1R6fjI/9bFNSVNgauiQ
                    flN6q8QA5B2sbDihiSqAylm9F34hpI3C3PvzSWzuIk+Z2FPHcA05CZtwrUWj1M0c
                    eBXxXragtR7ZYtIbEb0srzBfwoFYvWnLU7tM8t6wM6+1rxvOuQFVCCSXyptsGoBl
                    D9qyzAbyYDgJZYpbTjaA9bqhpkn/9CLN3JhNHLyBVr03fp3hQqNwZ2do9bFZBnW0
                    c5Dx9pbKTvC3TAUb2cwUD69yTYS1oq7//yIC2ha2ouzkV/VpB1fcF5YEj2pc6uaj
                    lOTDX4Eg7OBEkTzU8cX04b15bJfE
                  </ds:X509Certificate>
                </ds:X509Data>
              </ds:KeyInfo>
            </KeyDescriptor>
            <ArtifactResolutionService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://sso.school.edu:8443/idp/profile/SAML2/SOAP/ArtifactResolution" index="1"/>
            <ArtifactResolutionService Binding="urn:oasis:names:tc:SAML:1.0:bindings:SOAP-binding" Location="https://sso.school.edu:8443/idp/profile/SAML1/SOAP/ArtifactResolution" index="2"/>
            <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://sso.school.edu/idp/profile/SAML2/Redirect/SLO"/>
            <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://sso.school.edu/idp/profile/SAML2/POST/SLO"/>
            <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://sso.school.edu/idp/profile/SAML2/SOAP/SLO"/>
            <SingleSignOnService Binding="urn:mace:shibboleth:1.0:profiles:AuthnRequest" Location="https://sso.school.edu/idp/profile/Shibboleth/SSO"/>
            <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://sso.school.edu/idp/profile/SAML2/POST/SSO"/>
            <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://sso.school.edu/idp/profile/SAML2/Redirect/SSO"/>
          </IDPSSODescriptor>
        </EntityDescriptor>
      XML
    end

    it "adds a new auth config successfully" do
      cas = {
        auth_type: "cas",
        auth_base: "http://example.com",
      }
      post "create", params: { account_id: account.id }.merge(cas)

      account.reload
      aac = account.authentication_providers.active.where(auth_type: "cas").first
      expect(aac).to be_present
    end

    it "adds a singleton type successfully" do
      linkedin = {
        auth_type: "linkedin",
        client_id: "1",
        client_secret: "2"
      }
      post "create", params: { account_id: account.id }.merge(linkedin)

      account.reload
      aac = account.authentication_providers.active.where(auth_type: "linkedin").first
      expect(aac).to be_present
    end

    it "rejects a singleton type if it already exists" do
      linkedin = {
        auth_type: "linkedin",
        client_id: "1",
        client_secret: "2"
      }
      account.authentication_providers.create!(linkedin)

      post "create", format: :json, params: { account_id: account.id }.merge(linkedin)
      expect(response).to have_http_status :unprocessable_entity
    end

    it "allows multiple non-singleton types" do
      cas = {
        auth_type: "cas",
        auth_base: "http://example.com/cas2",
      }
      account.authentication_providers.create!({
                                                 auth_type: "cas",
                                                 auth_base: "http://example.com/cas"
                                               })
      post "create", params: { account_id: account.id }.merge(cas)

      account.reload
      aac_count = account.authentication_providers.active.where(auth_type: "cas").count
      expect(aac_count).to eq 2
    end

    it "allows re-adding a singleton type that was previously deleted" do
      linkedin = {
        auth_type: "linkedin",
        client_id: "1",
        client_secret: "2"
      }
      aac = account.authentication_providers.create!(linkedin)
      aac.destroy

      post "create", params: { account_id: account.id }.merge(linkedin)
      account.reload
      aac = account.authentication_providers.active.where(auth_type: "linkedin").first
      expect(aac).to be_present
    end

    it "populates SAML from metadata" do
      post "create", params: { account_id: account.id, auth_type: "saml", metadata: idp_xml }
      expect(response).to be_redirect

      ap = account.authentication_providers.active.last
      expect(ap.idp_entity_id).to eq("https://sso.school.edu/idp/shibboleth")
      expect(ap.log_in_url).to eq("https://sso.school.edu/idp/profile/SAML2/Redirect/SSO")
      expect(ap.log_out_url).to eq("https://sso.school.edu/idp/profile/SAML2/Redirect/SLO")
      expect(ap.certificate_fingerprint).to eq("8c:dd:28:ba:49:a2:ed:fb:ed:56:9a:2f:58:b2:79:e1:0b:46:6e:81")
    end

    context "mfa_option into individual fields" do
      before do
        account.settings[:mfa_settings] = :optional
        account.save!
      end

      it "handles required" do
        post "create", params: { account_id: account.id, auth_type: "cas", auth_base: "http://example.com", mfa_option: "required" }
        expect(response).to be_redirect

        ap = account.authentication_providers.active.last
        expect(ap.mfa_required).to be(true)
        expect(ap.skip_internal_mfa).to be(false)
      end

      it "handles bypass" do
        post "create", params: { account_id: account.id, auth_type: "cas", auth_base: "http://example.com", mfa_option: "bypass" }
        expect(response).to be_redirect

        ap = account.authentication_providers.active.last
        expect(ap.mfa_required).to be(false)
        expect(ap.skip_internal_mfa).to be(true)
      end

      it "handles default" do
        post "create", params: { account_id: account.id, auth_type: "cas", auth_base: "http://example.com", mfa_option: "default" }
        expect(response).to be_redirect

        ap = account.authentication_providers.active.last
        expect(ap.mfa_required).to be(false)
        expect(ap.skip_internal_mfa).to be(false)
      end
    end
  end
end
