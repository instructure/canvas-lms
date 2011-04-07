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

  it "should log in and log out a user CAS has validated" do
    account = account_with_cas({:account => Account.default})
    user = user_with_pseudonym({:active_all => true})

    get 'new'
    response.should redirect_to(controller.cas_client.add_service_to_login_url(login_url))

    controller.cas_client.should_receive(:validate_service_ticket).and_return { |st|
      st.response = CASClient::ValidationResponse.new("yes\n#{user.pseudonyms.first.unique_id}\n")
    }

    get 'new', :ticket => 'ST-abcd'
    response.should redirect_to(dashboard_url)
    session[:cas_login].should == true

    get 'destroy'
    response.should redirect_to(controller.cas_client.logout_url(login_url))
  end

  it "should inform the user CAS validation denied" do
    account = account_with_cas({:account => Account.default})

    get 'new'
    response.should redirect_to(controller.cas_client.add_service_to_login_url(login_url))

    controller.cas_client.should_receive(:validate_service_ticket).and_return { |st|
      st.response = CASClient::ValidationResponse.new("no\n\n")
    }

    get 'new', :ticket => 'ST-abcd'
    response.should redirect_to(:action => 'new', :no_auto => true)
    flash[:delegated_message].should match(/There was a problem logging in/)
  end

  it "should inform the user CAS validation failed" do
    account = account_with_cas({:account => Account.default})

    get 'new'
    response.should redirect_to(controller.cas_client.add_service_to_login_url(login_url))

    controller.cas_client.should_receive(:validate_service_ticket).and_return { |st|
      raise "can't contact CAS"
    }

    get 'new', :ticket => 'ST-abcd'
    response.should redirect_to(:action => 'new', :no_auto => true)
    flash[:delegated_message].should match(/There was a problem logging in/)
  end

  it "should inform the user that CAS account doesn't exist" do
    account = account_with_cas({:account => Account.default})

    get 'new'
    response.should redirect_to(controller.cas_client.add_service_to_login_url(login_url))

    controller.cas_client.should_receive(:validate_service_ticket).and_return { |st|
      st.response = CASClient::ValidationResponse.new("yes\nnonexistentuser\n")
    }

    get 'new', :ticket => 'ST-abcd'
    response.should redirect_to(:action => 'destroy')
    get 'destroy'
    response.should redirect_to(:action => 'new', :no_auto => true)
    flash[:delegated_message].should match(/Canvas doesn't have an account for user/)
  end


end
