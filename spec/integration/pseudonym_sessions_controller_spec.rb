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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PseudonymSessionsController do
  def redirect_until(uri)
    count = 0
    while true
      response.should be_redirect
      return if response.location == uri
      count += 1
      count.should < 5
      follow_redirect!
    end
  end

  context "cas" do
    def stubby(stub_response)
      @cas_client = CASClient::Client.new({:cas_base_url => @account.account_authorization_config.auth_base})
      @cas_client.instance_variable_set(:@stub_response, stub_response)
      def @cas_client.validate_service_ticket(st)
        st.response = CASClient::ValidationResponse.new(@stub_response)
      end
      PseudonymSessionsController.any_instance.stubs(:cas_client).returns(@cas_client)
    end

    it "should log in and log out a user CAS has validated" do
      account_with_cas({:account => Account.default})
      user = user_with_pseudonym({:active_all => true})

      stubby("yes\n#{user.pseudonyms.first.unique_id}\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(login_url))

      get login_url :ticket => 'ST-abcd'
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:cas_login].should == true

      get logout_url
      response.should redirect_to(@cas_client.logout_url(login_url))
    end

    it "should inform the user CAS validation denied" do
      account_with_cas({:account => Account.default})

      stubby("no\n\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(login_url))

      get login_url :ticket => 'ST-abcd'
      response.should redirect_to(login_url :no_auto => true)
      flash[:delegated_message].should match(/There was a problem logging in/)
    end

    it "should inform the user CAS validation failed" do
      account_with_cas({:account => Account.default})

      stubby('')
      def @cas_client.validate_service_ticket(st)
        raise "Nope"
      end

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(login_url))

      get login_url :ticket => 'ST-abcd'
      response.should redirect_to(login_url :no_auto => true)
      flash[:delegated_message].should match(/There was a problem logging in/)
    end

    it "should inform the user that CAS account doesn't exist" do
      account_with_cas({:account => Account.default})

      stubby("yes\nnonexistentuser\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(login_url))

      get login_url :ticket => 'ST-abcd'
      response.should redirect_to(@cas_client.logout_url(login_url :no_auto => true))
      get login_url :no_auto => true
      flash[:delegated_message].should match(/Canvas doesn't have an account for user/)
    end

    it "should login case insensitively" do
      account_with_cas({:account => Account.default})
      user = user_with_pseudonym({:active_all => true})

      stubby("yes\n#{user.pseudonyms.first.unique_id.capitalize}\n")

      get login_url
      redirect_until(@cas_client.add_service_to_login_url(login_url))

      get login_url :ticket => 'ST-abcd'
      response.should redirect_to(dashboard_url(:login_success => 1))
      session[:cas_login].should == true
    end
  end

  it "should redirect back for jobs controller" do
    user_with_pseudonym(:password => 'qwerty', :active_all => 1)
    Account.site_admin.add_user(@user)

    get jobs_url
    response.should redirect_to login_url

    post login_url, :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
    response.should redirect_to jobs_url
  end
end