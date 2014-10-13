#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe PseudonymSessionsController do
  def redirect_until(uri)
    count = 0
    while true
      expect(response).to be_redirect
      return if response.location == uri
      count += 1
      expect(count).to be < 5
      follow_redirect!
    end
  end

  context "cas" do
    before do
      account_with_cas(account: Account.default)
    end

    def stubby(stub_response)
      @cas_client = CASClient::Client.new(
        cas_base_url: @account.account_authorization_config.auth_base,
        encode_extra_attributes_as: :raw
      )
      @cas_client.instance_variable_set(:@stub_response, stub_response)
      def @cas_client.validate_service_ticket(st)
        response = CASClient::ValidationResponse.new(@stub_response)
        st.user = response.user
        st.success = response.is_success?
        return st
      end
      PseudonymSessionsController.any_instance.stubs(:cas_client).returns(@cas_client)
    end

    it "should log in and log out a user CAS has validated" do
      user = user_with_pseudonym({:active_all => true})

      stubby("yes\n#{user.pseudonyms.first.unique_id}\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      expect(session[:cas_session]).to eq 'ST-abcd'

      delete logout_url
      expect(response).to redirect_to(@cas_client.logout_url(cas_login_url))
    end

    it "should inform the user CAS validation denied" do
      stubby("no\n\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(cas_login_url :no_auto => true)
      expect(flash[:delegated_message]).to match(/There was a problem logging in/)
    end

    it "should inform the user CAS validation failed" do
      stubby('')
      def @cas_client.validate_service_ticket(st)
        raise "Nope"
      end

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(cas_login_url :no_auto => true)
      expect(flash[:delegated_message]).to match(/There was a problem logging in/)
    end

    it "should inform the user that CAS account doesn't exist" do
      stubby("yes\nnonexistentuser\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(cas_login_url(:no_auto => true))
      get cas_login_url :no_auto => true
      expect(flash[:delegated_message]).to match(/Canvas doesn't have an account for user/)
    end

    it "should redirect to a custom url if the user CAS account doesn't exist" do
      redirect_url = login_url(:no_auto => 'true')
      aac = Account.default.account_authorization_config
      aac.unknown_user_url = redirect_url
      aac.save

      stubby("yes\nnonexistentuser\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(redirect_url)
    end

    it "should login case insensitively" do
      user = user_with_pseudonym({:active_all => true})

      stubby("yes\n#{user.pseudonyms.first.unique_id.capitalize}\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

      get cas_login_url :ticket => 'ST-abcd'
      expect(response).to redirect_to(dashboard_url(:login_success => 1))
      expect(session[:cas_session]).to eq 'ST-abcd'
    end

    context "single sign out" do
      before do
        skip "needs redis" unless Canvas.redis_enabled?
      end

      it "should do a single sign out" do
        user = user_with_pseudonym({:active_all => true})

        stubby("yes\n#{user.pseudonyms.first.unique_id}\n")

        get login_url
        redirect_until(@cas_client.add_service_to_login_url(cas_login_url))

        get cas_login_url :ticket => 'ST-abcd'
        expect(response).to redirect_to(dashboard_url(:login_success => 1))
        expect(session[:cas_session]).to eq 'ST-abcd'
        expect(Canvas.redis.get("cas_session:ST-abcd")).to eq @pseudonym.global_id.to_s

        # pretend we lost the cache somehow
        Canvas.redis.del("cas_session:ST-abcd")
        expect(Canvas.redis.get("cas_session:ST-abcd")).to eq nil

        back_channel = open_session
        # it starts out as a clone of the current session
        back_channel.reset!

        # single-sign-out from CAS server has no effect now
        back_channel.post cas_logout_url, :logoutRequest => <<-SAML
<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="1371236167rDkbdl8FGzbqwBhICvi" Version="2.0" IssueInstant="Fri, 14 Jun 2013 12:56:07 -0600">
<saml:NameID></saml:NameID>
<samlp:SessionIndex>ST-abcd</samlp:SessionIndex>
</samlp:LogoutRequest>
        SAML
        expect(back_channel.response.status.to_i).to eq 404

        # this should refresh it
        get dashboard_url
        expect(response).to be_success
        expect(Canvas.redis.get("cas_session:ST-abcd")).to eq @pseudonym.global_id.to_s

        # unrelated logout should have no effect
        back_channel.post cas_logout_url :garbage => 1
        expect(back_channel.response.status.to_i).to eq 404

        back_channel.post cas_logout_url :logoutRequest => "garbage"
        expect(back_channel.response.status.to_i).to eq 404

        back_channel.post cas_logout_url :logoutRequest => <<-SAML
<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="1371236167rDkbdl8FGzbqwBhICvi" Version="2.0" IssueInstant="Fri, 14 Jun 2013 12:56:07 -0600">
<saml:NameID></saml:NameID>
<samlp:SessionIndex>ST-abc</samlp:SessionIndex>
</samlp:LogoutRequest>
        SAML
        expect(back_channel.response.status.to_i).to eq 404

        # still logged in
        get dashboard_url
        expect(response).to be_success
        expect(Canvas.redis.get("cas_session:ST-abcd")).to eq @pseudonym.global_id.to_s

        # this time it works
        back_channel.post cas_logout_url :logoutRequest => <<-SAML
<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="1371236167rDkbdl8FGzbqwBhICvi" Version="2.0" IssueInstant="Fri, 14 Jun 2013 12:56:07 -0600">
<saml:NameID></saml:NameID>
<samlp:SessionIndex>ST-abcd</samlp:SessionIndex>
</samlp:LogoutRequest>
        SAML
        expect(back_channel.response).to be_success
        expect(Canvas.redis.get("cas_session:ST-abcd")).to eq nil

        # logged out!
        get dashboard_url
        redirect_until(@cas_client.add_service_to_login_url(cas_login_url))
      end
    end
  end

  context "SAML" do
    before do
      skip("requires SAML extension") unless AccountAuthorizationConfig.saml_enabled
    end

    it 'redirects to the discovery page when hitting a deep link while unauthenticated' do
      account = account_with_saml( :account => Account.default )
      discovery_url = 'http://discovery-url.example.com'
      account.auth_discovery_url = discovery_url
      account.save!

      get account_account_authorization_configs_url(account)
      redirect_until(discovery_url)
    end
  end

  it "should redirect back for jobs controller" do
    user_with_pseudonym(:password => 'qwerty', :active_all => 1)
    Account.site_admin.account_users.create!(user: @user)

    get jobs_url
    expect(response).to redirect_to login_url

    post login_url, :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
    expect(response).to redirect_to jobs_url
  end
end
