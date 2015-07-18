#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

require_relative '../../spec_helper'

describe Login::SamlController do
  before do
    skip("requires SAML extension") unless AccountAuthorizationConfig::SAML.enabled?
  end

  it "should scope logins to the correct domain root account" do
    unique_id = 'foo@example.com'

    account1 = account_with_saml
    user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account1
    @pseudonym.save!

    account2 = account_with_saml
    user2 = user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account2
    @pseudonym.save!

    Onelogin::Saml::Response.stubs(:new).returns(
      stub('response',
           is_valid?: true,
           success_status?: true,
           name_id: unique_id,
           name_qualifier: nil,
           session_index: nil,
           process: nil,
           issuer: "saml_entity"
          )
    )

    controller.request.env['canvas.domain_root_account'] = account1
    post :create, :SAMLResponse => "foo"
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:saml_unique_id]).to eq unique_id
    expect(Pseudonym.find(session['pseudonym_credentials_id'])).to eq user1.pseudonyms.first

    (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each do |var|
      controller.send :remove_instance_variable, var
    end
    session.clear

    controller.request.env['canvas.domain_root_account'] = account2
    post :create, :SAMLResponse => "bar"
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:saml_unique_id]).to eq unique_id
    expect(Pseudonym.find(session['pseudonym_credentials_id'])).to eq user2.pseudonyms.first
  end

  it "does not enforce a valid entity id" do
    unique_id = 'foo@example.com'

    account1 = account_with_saml
    user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account1
    @pseudonym.save!

    Onelogin::Saml::Response.stubs(:new).returns(
        stub('response',
             is_valid?: true,
             success_status?: true,
             name_id: unique_id,
             name_qualifier: nil,
             session_index: nil,
             process: nil,
             issuer: "such a lie"
        )
    )

    controller.request.env['canvas.domain_root_account'] = account1
    post :create, :SAMLResponse => "foo"
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:saml_unique_id]).to eq unique_id
    expect(Pseudonym.find(session['pseudonym_credentials_id'])).to eq user1.pseudonyms.first
  end

  it "should redirect when a user is authenticated but is not found in canvas" do
    unique_id = 'foo@example.com'

    account = account_with_saml

    Onelogin::Saml::Response.stubs(:new).returns(
      stub('response',
           is_valid?: true,
           success_status?: true,
           name_id: unique_id,
           name_qualifier: nil,
           session_index: nil,
           process: nil,
           issuer: "saml_entity"
          )
    )

    # We dont want to log them out of everything.
    controller.expects(:logout_user_action).never
    controller.request.env['canvas.domain_root_account'] = account

    # Default to Login url if set to nil or blank
    post :create, :SAMLResponse => "foo"
    expect(response).to redirect_to(login_url)
    expect(flash[:delegated_message]).to_not be_nil
    expect(session[:saml_unique_id]).to be_nil

    account.unknown_user_url = ''
    account.save!
    controller.instance_variable_set(:@aac, nil)
    post :create, :SAMLResponse => "foo"
    expect(response).to redirect_to(login_url)
    expect(flash[:delegated_message]).to_not be_nil
    expect(session[:saml_unique_id]).to be_nil

    # Redirect to a specifiec url
    unknown_user_url = "https://example.com/unknown_user"
    account.unknown_user_url = unknown_user_url
    account.save!
    controller.instance_variable_set(:@aac, nil)
    post :create, :SAMLResponse => "foo"
    expect(response).to redirect_to(unknown_user_url)
    expect(session[:saml_unique_id]).to be_nil
  end

  context "multiple authorization configs" do
    before :once do
      @account = Account.create!
      @unique_id = 'foo@example.com'
      @user1 = user_with_pseudonym(:active_all => true, :username => @unique_id, :account => @account)
      @account.authentication_providers.create!(:auth_type => 'saml', :identifier_format => 'uid')

      @aac2 = @account.authentication_providers.build(auth_type: 'saml')
      @aac2.idp_entity_id = "https://example.com/idp1"
      @aac2.log_out_url = "https://example.com/idp1/slo"
      @aac2.save!

      @stub_hash = {
          :issuer => @aac2.idp_entity_id,
          :is_valid? => true,
          :success_status? => true,
          :name_id => @unique_id,
          :name_qualifier => nil,
          :session_index => nil,
          :process => nil,
      }
    end

    it "should saml_consume login with multiple authorization configs" do
      Onelogin::Saml::Response.stubs(:new).returns(stub('response', @stub_hash))
      controller.request.env['canvas.domain_root_account'] = @account
      post :create, :SAMLResponse => "foo", :RelayState => "/courses"
      expect(response).to redirect_to(courses_url)
      expect(session[:saml_unique_id]).to eq @unique_id
    end

    it "should saml_logout with multiple authorization configs" do
      Onelogin::Saml::LogoutResponse.stubs(:parse).returns(
        stub('response', @stub_hash)
      )
      controller.request.env['canvas.domain_root_account'] = @account
      get :destroy, :SAMLResponse => "foo", :RelayState => "/courses"

      expect(response).to redirect_to(saml_login_url(@aac2))
    end
  end

  context "multiple SAML configs" do
    before :once do
      @account = account_with_saml(:saml_log_in_url => "https://example.com/idp1/sli")
      @unique_id = 'foo@example.com'
      @user1 = user_with_pseudonym(:active_all => true, :username => @unique_id, :account => @account)
      @aac1 = @account.authentication_providers.first
      @aac1.idp_entity_id = "https://example.com/idp1"
      @aac1.log_out_url = "https://example.com/idp1/slo"
      @aac1.save!

      @aac2 = @aac1.clone
      @aac2.idp_entity_id = "https://example.com/idp2"
      @aac2.log_in_url = "https://example.com/idp2/sli"
      @aac2.log_out_url = "https://example.com/idp2/slo"
      @aac2.position = nil
      @aac2.save!

      @stub_hash = {
        issuer: @aac2.idp_entity_id,
        is_valid?: true,
        success_status?: true,
        name_id: @unique_id,
        name_qualifier: nil,
        session_index: nil,
        process: nil
      }
    end

    context "#create" do
      def post_create
        Onelogin::Saml::Response.stubs(:new).returns(
          stub('response', @stub_hash)
        )
        controller.request.env['canvas.domain_root_account'] = @account
        post :create, :SAMLResponse => "foo", :RelayState => "/courses"
      end

      it "finds the SAML config by entity_id" do
        @aac1.any_instantiation.expects(:saml_settings).never
        @aac2.any_instantiation.expects(:saml_settings)

        post_create

        expect(response).to redirect_to(courses_url)
        expect(session[:saml_unique_id]).to eq @unique_id
      end

      it "redirects to login screen with message if no AAC found" do
        @stub_hash[:issuer] = "hahahahahahaha"

        post_create

        expect(response).to redirect_to(login_url)
        expect(flash[:delegated_message]).to eq "The institution you logged in from is not configured on this account."
      end
    end

    context "/new" do
      def get_new(aac_id=nil)
        controller.request.env['canvas.domain_root_account'] = @account
        if aac_id
          get 'new', id: aac_id
        else
          get 'new'
        end
      end

      it "should redirect to default login" do
        get_new
        expect(response.location.starts_with?(controller.delegated_auth_redirect_uri(@aac1.log_in_url))).to be_truthy
      end

      it "should use the specified AAC" do
        get_new("#{@aac1.id}")
        expect(response.location.starts_with?(controller.delegated_auth_redirect_uri(@aac1.log_in_url))).to be_truthy
        controller.instance_variable_set(:@aac, nil)
        get_new("#{@aac2.id}")
        expect(response.location.starts_with?(controller.delegated_auth_redirect_uri(@aac2.log_in_url))).to be_truthy
      end

      it "reject  unknown specified AAC" do
        get_new("0")
        expect(response.status).to eq 404
      end
    end

    context "logging out" do
      before do
        Onelogin::Saml::Response.stubs(:new).returns(
          stub('response', @stub_hash)
        )
        controller.request.env['canvas.domain_root_account'] = @account
        post :create, :SAMLResponse => "foo", :RelayState => "/courses"

        expect(response).to redirect_to(courses_url)
        expect(session[:saml_unique_id]).to eq @unique_id
        expect(session[:login_aac]).to eq @aac2.id
      end

      describe '#destroy' do
        it "should return bad request if a SAMLResponse or SAMLRequest parameter is not provided" do
          controller.expects(:logout_user_action).never
          get :destroy
          expect(response.status).to eq 400
        end

        it "should find the correct AAC" do
          @aac1.any_instantiation.expects(:saml_settings).never
          @aac2.any_instantiation.expects(:saml_settings).at_least_once

          Onelogin::Saml::LogoutResponse.stubs(:parse).returns(
            stub('response', @stub_hash)
          )

          controller.request.env['canvas.domain_root_account'] = @account
          get :destroy, :SAMLResponse => "foo"
          expect(response).to redirect_to(saml_login_url(@aac2))
        end

        it "should redirect a response to idp on logout with a SAMLRequest parameter" do
          controller.expects(:logout_current_user)
          @stub_hash[:id] = '_42'

          Onelogin::Saml::LogoutRequest.stubs(:parse).returns(
            stub('request', @stub_hash)
          )

          controller.request.env['canvas.domain_root_account'] = @account
          get :destroy, :SAMLRequest => "foo"

          expect(response).to be_redirect
          expect(response.location).to match %r{^https://example.com/idp2/slo\?SAMLResponse=}
        end
      end
    end
  end

  context "/saml_logout" do
    it "should return bad request if SAML is not configured for account" do
      Onelogin::Saml::LogoutResponse.expects(:parse).returns(
        stub('response', issuer: 'entity')
      )

      controller.expects(:logout_user_action).never
      controller.request.env['canvas.domain_root_account'] = @account
      get :destroy, :SAMLResponse => "foo", :RelayState => "/courses"
      expect(response.status).to eq 400
    end
  end

  context "login attributes" do
    before :once do
      @unique_id = 'foo'

      @account = account_with_saml
      @user = user_with_pseudonym({:active_all => true, :username => @unique_id})
      @pseudonym.account = @account
      @pseudonym.save!

      @aac = @account.authentication_providers.first
    end

    it "should use the eduPersonPrincipalName attribute with the domain stripped" do
      @aac.login_attribute = 'eduPersonPrincipalName_stripped'
      @aac.save

      Onelogin::Saml::Response.stubs(:new).returns(
        stub('response',
             is_valid?: true,
             success_status?: true,
             name_id: nil,
             name_qualifier: nil,
             session_index: nil,
             process: nil,
             issuer: "saml_entity",
             saml_attributes: {
                 'eduPersonPrincipalName' => "#{@unique_id}@example.edu"
             }
            )
      )

      controller.request.env['canvas.domain_root_account'] = @account
      post :create, :SAMLResponse => "foo", :RelayState => "/courses"
      expect(response).to redirect_to(courses_url)
      expect(session[:saml_unique_id]).to eq @unique_id
    end

    it "should use the NameID if no login attribute is specified" do
      @aac.login_attribute = nil
      @aac.save

      Onelogin::Saml::Response.stubs(:new).returns(
        stub('response',
             is_valid?: true,
             success_status?: true,
             name_id: @unique_id,
             name_qualifier: nil,
             session_index: nil,
             process: nil,
             issuer: "saml_entity"
            )
      )

      controller.request.env['canvas.domain_root_account'] = @account
      post :create, :SAMLResponse => "foo", :RelayState => "/courses"
      expect(response).to redirect_to(courses_url)
      expect(session[:saml_unique_id]).to eq @unique_id
    end
  end

  it "should use the eppn saml attribute if configured" do
    unique_id = 'foo'

    account = account_with_saml
    @aac = @account.authentication_providers.first
    @aac.login_attribute = 'eduPersonPrincipalName_stripped'
    @aac.save

    user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account
    @pseudonym.save!

    Onelogin::Saml::Response.stubs(:new).returns(
      stub('response',
           is_valid?: true,
           success_status?: true,
           name_id: nil,
           name_qualifier: nil,
           session_index: nil,
           process: nil,
           issuer: "saml_entity",
           saml_attributes: {
             'eduPersonPrincipalName' => "#{unique_id}@example.edu"
           }
          )
    )

    controller.request.env['canvas.domain_root_account'] = account
    post :create, :SAMLResponse => "foo", :RelayState => "/courses"
    expect(response).to redirect_to(courses_url)
    expect(session[:saml_unique_id]).to eq unique_id
  end

  it "should redirect to RelayState relative urls" do
    unique_id = 'foo@example.com'

    account = account_with_saml
    user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account
    @pseudonym.save!

    Onelogin::Saml::Response.stubs(:new).returns(
      stub('response',
           is_valid?: true,
           success_status?: true,
           name_id: unique_id,
           name_qualifier: nil,
           session_index: nil,
           process: nil,
           issuer: "saml_entity"
          )
    )

    controller.request.env['canvas.domain_root_account'] = account
    post :create, :SAMLResponse => "foo", :RelayState => "/courses"
    expect(response).to redirect_to(courses_url)
    expect(session[:saml_unique_id]).to eq unique_id
  end

  it "should decode an actual saml response" do
    unique_id = 'student@example.edu'

    account_with_saml

    @aac = @account.authentication_providers.first
    @aac.idp_entity_id = 'http://phpsite/simplesaml/saml2/idp/metadata.php'
    @aac.login_attribute = 'eduPersonPrincipalName'
    @aac.certificate_fingerprint = 'AF:E7:1C:28:EF:74:0B:C8:74:25:BE:13:A2:26:3D:37:97:1D:A1:F9'
    @aac.save

    user_with_pseudonym(:active_all => true, :username => unique_id)
    @pseudonym.account = @account
    @pseudonym.save!

    controller.request.env['canvas.domain_root_account'] = @account
    post :create, :SAMLResponse => <<-SAML
        PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJv
        dG9jb2wiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElE
        PSJfMzJmMTBlOGU0NjVmY2VmNzIzNjhlMjIwZmFlYjgxZGI0YzcyZjBjNjg3IiBWZXJzaW9uPSIyLjAi
        IElzc3VlSW5zdGFudD0iMjAxMi0wOC0wM1QyMDowNzoxNVoiIERlc3RpbmF0aW9uPSJodHRwOi8vc2hh
        cmQxLmxvY2FsZG9tYWluOjMwMDAvc2FtbF9jb25zdW1lIiBJblJlc3BvbnNlVG89ImQwMDE2ZWM4NThk
        OTIzNjBjNTk3YTAxZDE1NTk0NGY4ZGY4ZmRiMTE2ZCI+PHNhbWw6SXNzdWVyPmh0dHA6Ly9waHBzaXRl
        L3NpbXBsZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVy
        ZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25l
        ZEluZm8+PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9y
        Zy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGht
        PSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJl
        bmNlIFVSST0iI18zMmYxMGU4ZTQ2NWZjZWY3MjM2OGUyMjBmYWViODFkYjRjNzJmMGM2ODciPjxkczpU
        cmFuc2Zvcm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5
        L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRw
        Oi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRp
        Z2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGEx
        Ii8+PGRzOkRpZ2VzdFZhbHVlPlM2TmUxMW5CN2cxT3lRQUdZckZFT251NVFBUT08L2RzOkRpZ2VzdFZh
        bHVlPjwvZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+bWdxWlVp
        QTNtYXRyajZaeTREbCsxZ2hzZ29PbDh3UEgybXJGTTlQQXFyWUIwc2t1SlVaaFlVa0NlZ0ViRVg5V1JP
        RWhvWjJiZ3dKUXFlVVB5WDdsZU1QZTdTU2RVRE5LZjlraXV2cGNDWVpzMWxGU0VkNTFFYzhmK0h2ZWpt
        SFVKQVUrSklSV3BwMVZrWVVaQVRpaHdqR0xvazNOR2kveWdvYWpOaDQydlo0PTwvZHM6U2lnbmF0dXJl
        VmFsdWU+CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVEND
        QWVvQ0NRQ2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4
        R0RBV0JnTlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lE
        VlFRS0V3ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2tx
        aGtpRzl3MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZh
        Rncwd056QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVr
        Y21WaGN5QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4
        R0RBV0JnTlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVr
        Y21WaGMwQjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURp
        dmJoUjdQNTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51
        TWNQc0l4QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVcz
        VGNmQ0dQdEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBH
        Q1NxR1NJYjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cy
        V3lrVXFSWEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWlo
        WnEzWlVkbXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9C
        WGhvcGhTTXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+
        PC9kczpTaWduYXR1cmU+PHNhbWxwOlN0YXR1cz48c2FtbHA6U3RhdHVzQ29kZSBWYWx1ZT0idXJuOm9h
        c2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnN0YXR1czpTdWNjZXNzIi8+PC9zYW1scDpTdGF0dXM+PHNhbWw6
        QXNzZXJ0aW9uIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFu
        Y2UiIHhtbG5zOnhzPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSIgSUQ9Il82MjEyYjdl
        OGMwNjlkMGY5NDhjODY0ODk5MWQzNTdhZGRjNDA5NWE4MmYiIFZlcnNpb249IjIuMCIgSXNzdWVJbnN0
        YW50PSIyMDEyLTA4LTAzVDIwOjA3OjE1WiI+PHNhbWw6SXNzdWVyPmh0dHA6Ly9waHBzaXRlL3NpbXBs
        ZXNhbWwvc2FtbDIvaWRwL21ldGFkYXRhLnBocDwvc2FtbDpJc3N1ZXI+PGRzOlNpZ25hdHVyZSB4bWxu
        czpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+CiAgPGRzOlNpZ25lZEluZm8+
        PGRzOkNhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAx
        LzEwL3htbC1leGMtYzE0biMiLz4KICAgIDxkczpTaWduYXR1cmVNZXRob2QgQWxnb3JpdGhtPSJodHRw
        Oi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjcnNhLXNoYTEiLz4KICA8ZHM6UmVmZXJlbmNlIFVS
        ST0iI182MjEyYjdlOGMwNjlkMGY5NDhjODY0ODk5MWQzNTdhZGRjNDA5NWE4MmYiPjxkczpUcmFuc2Zv
        cm1zPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRz
        aWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3
        LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiLz48L2RzOlRyYW5zZm9ybXM+PGRzOkRpZ2VzdE1l
        dGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8+PGRz
        OkRpZ2VzdFZhbHVlPmthWk4xK21vUzMyOHByMnpuOFNLVU1MMUVsST08L2RzOkRpZ2VzdFZhbHVlPjwv
        ZHM6UmVmZXJlbmNlPjwvZHM6U2lnbmVkSW5mbz48ZHM6U2lnbmF0dXJlVmFsdWU+MWtVRWtHMzNaR1FN
        Zi8xSDFnenFCT2hUNU4ySTM1dk0wNEpwNjd4VmpuWlhGNTRBcVBxMVphTStXamd4KytBakViTDdrc2FZ
        dU0zSlN5SzdHbFo3N1ZtenBMc01xbjRlTTAwSzdZK0NlWnk1TEIyNHZjbmdYUHhCazZCZFVZa1ZrMHZP
        c1VmQUFaK21SWC96ekJXN1o0QzdxYmpOR2hBQUpnaTEzSm9CV3BVPTwvZHM6U2lnbmF0dXJlVmFsdWU+
        CjxkczpLZXlJbmZvPjxkczpYNTA5RGF0YT48ZHM6WDUwOUNlcnRpZmljYXRlPk1JSUNnVENDQWVvQ0NR
        Q2JPbHJXRGRYN0ZUQU5CZ2txaGtpRzl3MEJBUVVGQURDQmhERUxNQWtHQTFVRUJoTUNUazh4R0RBV0Jn
        TlZCQWdURDBGdVpISmxZWE1nVTI5c1ltVnlaekVNTUFvR0ExVUVCeE1EUm05dk1SQXdEZ1lEVlFRS0V3
        ZFZUa2xPUlZSVU1SZ3dGZ1lEVlFRREV3OW1aV2xrWlM1bGNteGhibWN1Ym04eElUQWZCZ2txaGtpRzl3
        MEJDUUVXRW1GdVpISmxZWE5BZFc1cGJtVjBkQzV1YnpBZUZ3MHdOekEyTVRVeE1qQXhNelZhRncwd056
        QTRNVFF4TWpBeE16VmFNSUdFTVFzd0NRWURWUVFHRXdKT1R6RVlNQllHQTFVRUNCTVBRVzVrY21WaGN5
        QlRiMnhpWlhKbk1Rd3dDZ1lEVlFRSEV3TkdiMjh4RURBT0JnTlZCQW9UQjFWT1NVNUZWRlF4R0RBV0Jn
        TlZCQU1URDJabGFXUmxMbVZ5YkdGdVp5NXViekVoTUI4R0NTcUdTSWIzRFFFSkFSWVNZVzVrY21WaGMw
        QjFibWx1WlhSMExtNXZNSUdmTUEwR0NTcUdTSWIzRFFFQkFRVUFBNEdOQURDQmlRS0JnUURpdmJoUjdQ
        NTE2eC9TM0JxS3h1cFFlMExPTm9saXVwaUJPZXNDTzNTSGJEcmwzK3E5SWJmbmZtRTA0ck51TWNQc0l4
        QjE2MVRkRHBJZXNMQ243YzhhUEhJU0tPdFBsQWVUWlNuYjhRQXU3YVJqWnEzK1BiclA1dVczVGNmQ0dQ
        dEtUeXRIT2dlL09sSmJvMDc4ZFZoWFExNGQxRUR3WEpXMXJSWHVVdDRDOFFJREFRQUJNQTBHQ1NxR1NJ
        YjNEUUVCQlFVQUE0R0JBQ0RWZnA4NkhPYnFZK2U4QlVvV1E5K1ZNUXgxQVNEb2hCandPc2cyV3lrVXFS
        WEYrZExmY1VIOWRXUjYzQ3RaSUtGRGJTdE5vbVBuUXo3bmJLK29ueWd3QnNwVkVibkh1VWloWnEzWlVk
        bXVtUXFDdzRVdnMvMVV2cTNvck9vL1dKVmhUeXZMZ0ZWSzJRYXJRNC82N09aZkhkN1IrUE9CWGhvcGhT
        TXYxWk9vPC9kczpYNTA5Q2VydGlmaWNhdGU+PC9kczpYNTA5RGF0YT48L2RzOktleUluZm8+PC9kczpT
        aWduYXR1cmU+PHNhbWw6U3ViamVjdD48c2FtbDpOYW1lSUQgU1BOYW1lUXVhbGlmaWVyPSJodHRwOi8v
        c2hhcmQxLmxvY2FsZG9tYWluL3NhbWwyIiBGb3JtYXQ9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIu
        MDpuYW1laWQtZm9ybWF0OnRyYW5zaWVudCI+XzNiM2U3NzE0YjcyZTI5ZGM0MjkwMzIxYTA3NWZhMGI3
        MzMzM2E0ZjI1Zjwvc2FtbDpOYW1lSUQ+PHNhbWw6U3ViamVjdENvbmZpcm1hdGlvbiBNZXRob2Q9InVy
        bjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpjbTpiZWFyZXIiPjxzYW1sOlN1YmplY3RDb25maXJtYXRp
        b25EYXRhIE5vdE9uT3JBZnRlcj0iMjAxMi0wOC0wM1QyMDoxMjoxNVoiIFJlY2lwaWVudD0iaHR0cDov
        L3NoYXJkMS5sb2NhbGRvbWFpbjozMDAwL3NhbWxfY29uc3VtZSIgSW5SZXNwb25zZVRvPSJkMDAxNmVj
        ODU4ZDkyMzYwYzU5N2EwMWQxNTU5NDRmOGRmOGZkYjExNmQiLz48L3NhbWw6U3ViamVjdENvbmZpcm1h
        dGlvbj48L3NhbWw6U3ViamVjdD48c2FtbDpDb25kaXRpb25zIE5vdEJlZm9yZT0iMjAxMi0wOC0wM1Qy
        MDowNjo0NVoiIE5vdE9uT3JBZnRlcj0iMjAxMi0wOC0wM1QyMDoxMjoxNVoiPjxzYW1sOkF1ZGllbmNl
        UmVzdHJpY3Rpb24+PHNhbWw6QXVkaWVuY2U+aHR0cDovL3NoYXJkMS5sb2NhbGRvbWFpbi9zYW1sMjwv
        c2FtbDpBdWRpZW5jZT48L3NhbWw6QXVkaWVuY2VSZXN0cmljdGlvbj48L3NhbWw6Q29uZGl0aW9ucz48
        c2FtbDpBdXRoblN0YXRlbWVudCBBdXRobkluc3RhbnQ9IjIwMTItMDgtMDNUMjA6MDc6MTVaIiBTZXNz
        aW9uTm90T25PckFmdGVyPSIyMDEyLTA4LTA0VDA0OjA3OjE1WiIgU2Vzc2lvbkluZGV4PSJfMDJmMjZh
        ZjMwYTM3YWZiOTIwODFmM2E3MzcyODgxMDE5M2VmZDdmYTZlIj48c2FtbDpBdXRobkNvbnRleHQ+PHNh
        bWw6QXV0aG5Db250ZXh0Q2xhc3NSZWY+dXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmFjOmNsYXNz
        ZXM6UGFzc3dvcmQ8L3NhbWw6QXV0aG5Db250ZXh0Q2xhc3NSZWY+PC9zYW1sOkF1dGhuQ29udGV4dD48
        L3NhbWw6QXV0aG5TdGF0ZW1lbnQ+PHNhbWw6QXR0cmlidXRlU3RhdGVtZW50PjxzYW1sOkF0dHJpYnV0
        ZSBOYW1lPSJ1cm46b2lkOjEuMy42LjEuNC4xLjU5MjMuMS4xLjEuMSIgTmFtZUZvcm1hdD0idXJuOm9h
        c2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1hdDp1cmkiPjxzYW1sOkF0dHJpYnV0ZVZh
        bHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPm1lbWJlcjwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6
        QXR0cmlidXRlPjxzYW1sOkF0dHJpYnV0ZSBOYW1lPSJ1cm46b2lkOjEuMy42LjEuNC4xLjU5MjMuMS4x
        LjEuNiIgTmFtZUZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmF0dHJuYW1lLWZvcm1h
        dDp1cmkiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlIHhzaTp0eXBlPSJ4czpzdHJpbmciPnN0dWRlbnRAZXhh
        bXBsZS5lZHU8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48L3NhbWw6QXR0cmli
        dXRlU3RhdGVtZW50Pjwvc2FtbDpBc3NlcnRpb24+PC9zYW1scDpSZXNwb25zZT4=
    SAML
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:saml_unique_id]).to eq unique_id
  end
end
