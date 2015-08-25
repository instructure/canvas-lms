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
require 'rotp'

describe Login::CasController do
  def stubby(stub_response, use_mock = true)
    cas_client = use_mock ? stub_everything(:cas_client) : controller.client
    cas_client.instance_variable_set(:@stub_response, stub_response)
    def cas_client.validate_service_ticket(st)
      response = CASClient::ValidationResponse.new(@stub_response)
      st.user = response.user
      st.success = response.is_success?
      st
    end
    AccountAuthorizationConfig::CAS.any_instance.stubs(:client).returns(cas_client) if use_mock
  end

  it "should logout with specific cas ticket" do
    account = account_with_cas(account: Account.default)
    user_with_pseudonym(active_all: true, account: account)

    cas_ticket = CanvasUuid::Uuid.generate_securish_uuid
    request_text = <<-REQUEST_TEXT
        <samlp:LogoutRequest
          xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
          xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
          ID="42"
          Version="2.0"
          IssueInstant="#{Time.zone.now.in_time_zone}">
          <saml:NameID>@NOT_USED@</saml:NameID>
          <samlp:SessionIndex>#{cas_ticket}</samlp:SessionIndex>
        </samlp:LogoutRequest>
    REQUEST_TEXT
    request_text.strip!

    session[:cas_session] = cas_ticket
    session[:login_aac] = Account.default.authentication_providers.first
    @pseudonym.claim_cas_ticket(cas_ticket)

    post :destroy, logoutRequest: request_text
    expect(response.status).to eq 200

    post :destroy, logoutRequest: request_text
    expect(response.status).to eq 404
  end

  it "should accept extra attributes" do
    account = account_with_cas(account: Account.default)
    user_with_pseudonym(active_all: true, account: account)

    response_text = <<-RESPONSE_TEXT
        <cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
          <cas:authenticationSuccess>
            <cas:user>#{@user.email}</cas:user>
            <cas:attributes>
              <cas:name>#{@user.name}</cas:name>
              <cas:email><![CDATA[#{@user.email}]]></cas:email>
              <cas:yaml><![CDATA[--- true]]></cas:yaml>
              <cas:json><![CDATA[{"id":#{@user.id}]]></cas:json>
            </cas:attributes>
          </cas:authenticationSuccess>
        </cas:serviceResponse>
    RESPONSE_TEXT

    controller.instance_variable_set(:@domain_root_account, Account.default)
    cas_client = controller.client
    cas_client.instance_variable_set(:@stub_response, response_text)
    def cas_client.request_cas_response(_uri, type, _options={})
      type.new(@stub_response, @conf_options)
    end

    get 'new', :ticket => 'ST-abcd'
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:cas_session]).to eq 'ST-abcd'
  end

  it "should scope logins to the correct domain root account" do
    unique_id = 'foo@example.com'

    account1 = account_with_cas
    user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account1
    @pseudonym.save!

    account2 = account_with_cas
    user2 = user_with_pseudonym({:active_all => true, :username => unique_id})
    @pseudonym.account = account2
    @pseudonym.save!

    stubby("yes\n#{unique_id}\n")

    controller.request.env['canvas.domain_root_account'] = account1
    get 'new', :ticket => 'ST-abcd'
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:cas_session]).to eq 'ST-abcd'
    expect(Pseudonym.find(session['pseudonym_credentials_id'])).to eq user1.pseudonyms.first

    (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each do |var|
      controller.send :remove_instance_variable, var
    end
    session.clear

    stubby("yes\n#{unique_id}\n")

    controller.request.env['canvas.domain_root_account'] = account2
    get 'new', :ticket => 'ST-efgh'
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:cas_session]).to eq 'ST-efgh'
    expect(Pseudonym.find(session['pseudonym_credentials_id'])).to eq user2.pseudonyms.first
  end

  context "unknown user" do
    let(:account) { account_with_cas(account: Account.default) }

    before do
      stubby("yes\nfoo@example.com\n")
    end

    it "should redirect when a user is authorized but not found in canvas" do
      # We dont want to log them out of everything.
      controller.expects(:logout_user_action).never

      # Default to Login url with a nil value
      get 'new', :ticket => 'ST-abcd'
      expect(response).to redirect_to(login_url)
      expect(session[:cas_session]).to be_nil
      expect(flash[:delegated_message]).to_not be_nil
    end

    it "send to login page if unknoown_user_url is blank" do
      # Default to Login url with an empty string value
      account.unknown_user_url = ''
      account.save!

      get 'new', :ticket => 'ST-abcd'
      expect(response).to redirect_to(login_url)
      expect(session[:cas_session]).to be_nil
      expect(flash[:delegated_message]).to_not be_nil
    end

    it "uses the unknown_user_url from the aac" do
      unknown_user_url = "https://example.com/unknown_user"
      account.unknown_user_url = unknown_user_url
      account.save!
      get 'new', :ticket => 'ST-abcd'
      expect(response).to redirect_to(unknown_user_url)
      expect(session[:cas_session]).to be_nil
    end
  end

  it "should time out correctly" do
    Setting.set('cas_timelimit', 0.01)
    account_with_cas(account: Account.default)

    cas_client = mock()
    controller.stubs(:client).returns(cas_client)
    start = Time.now.utc
    cas_client.expects(:validate_service_ticket).returns { sleep 5 }
    get 'new', :ticket => 'ST-abcd'
    expect(response).to redirect_to(login_url)
    expect(flash[:delegated_message]).to_not be_blank
    expect(Time.now.utc - start).to be < 1
  end

  it "should set a cookie for site admin login" do
    user_with_pseudonym(account: Account.site_admin)
    stubby("yes\n#{@pseudonym.unique_id}\n")
    account_with_cas(account: Account.site_admin)

    controller.request.env['canvas.domain_root_account'] = Account.site_admin
    get 'new', :ticket => 'ST-efgh'
    expect(response).to redirect_to(dashboard_url(:login_success => 1))
    expect(session[:cas_session]).to eq 'ST-efgh'
    expect(cookies['canvas_sa_delegated']).to eq '1'
  end

  it "should redirect to site admin CAS if cookie set" do
    user_with_pseudonym(account: Account.site_admin)
    stubby("yes\n#{@pseudonym.unique_id}\n")
    account_with_cas(account: Account.site_admin)
    controller.instance_variable_set(:@domain_root_account, Account.site_admin)
    controller.client.expects(:add_service_to_login_url).returns('someurl')

    cookies['canvas_sa_delegated'] = '1'
    # *don't* stub domain_root_account
    get 'new'
    expect(response).to be_redirect
  end

  it "should not force otp reconfiguration on succesful login" do
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    account_with_cas(account: Account.default)

    user_with_pseudonym(active_all: 1, username: 'user')
    @user.otp_secret_key = ROTP::Base32.random_base32
    @user.save!

    stubby("yes\nuser\n")

    get 'new', :ticket => 'ST-efgh'
    expect(response).to redirect_to(otp_login_url)
    expect(session[:cas_session]).to eq 'ST-efgh'
    expect(session[:pending_otp_secret_key]).to be_nil
  end
end
