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

  context "saml" do
    it "should scope logins to the correct domain root account" do
      Setting.set_config("saml", {})
      unique_id = 'foo@example.com'

      account1 = account_with_saml
      user1 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account1
      @pseudonym.save!

      account2 = account_with_saml
      user2 = user_with_pseudonym({:active_all => true, :username => unique_id})
      @pseudonym.account = account2
      @pseudonym.save!

      controller.stub!(:saml_response).and_return {
        mock(:response, :is_valid? => true, :success_status? => true, :name_id => unique_id, :name_qualifier => nil, :session_index => nil)
      }

      controller.request.env['canvas.domain_root_account'] = account1
      get 'saml_consume', :SAMLResponse => "foo"
      response.should redirect_to(dashboard_url)
      session[:name_id].should == unique_id
      session[:pseudonym_credentials_id].should == user1.pseudonyms.first.id

      (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each{ |var| controller.send :remove_instance_variable, var }
      session.reset

      controller.request.env['canvas.domain_root_account'] = account2
      get 'saml_consume', :SAMLResponse => "bar"
      response.should redirect_to(dashboard_url)
      session[:name_id].should == unique_id
      session[:pseudonym_credentials_id].should == user2.pseudonyms.first.id

      Setting.set_config("saml", nil)
    end
  end

  context "cas" do
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

      controller.stub!(:cas_client).and_return {
        obj = mock(:cas_client)
        obj.stub!(:validate_service_ticket).and_return { |st|
          st.response = CASClient::ValidationResponse.new("yes\n#{unique_id}\n")
        }
        obj
      }

      controller.request.env['canvas.domain_root_account'] = account1
      get 'new', :ticket => 'ST-abcd'
      response.should redirect_to(dashboard_url)
      session[:cas_login].should == true
      session[:pseudonym_credentials_id].should == user1.pseudonyms.first.id

      (controller.instance_variables.grep(/@[^_]/) - ['@mock_proxy']).each{ |var| controller.send :remove_instance_variable, var }
      session.reset

      controller.request.env['canvas.domain_root_account'] = account2
      get 'new', :ticket => 'ST-efgh'
      response.should redirect_to(dashboard_url)
      session[:cas_login].should == true
      session[:pseudonym_credentials_id].should == user2.pseudonyms.first.id
    end

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
  
    it "should redirect to alternate CAS login page if so configured, and frame bust on login" do
      account = account_with_cas({:account => Account.default, :cas_log_in_url => 'http://example.com/cas'})
  
      get 'new'
      response.should redirect_to('http://example.com/cas')
  
      get 'new', :ticket => 'ST-abcd'
      response.should render_template('shared/exit_frame')
    end
  
    it "should login case insensitively" do
      account = account_with_cas({:account => Account.default})
      user = user_with_pseudonym({:active_all => true})
  
      get 'new'
      response.should redirect_to(controller.cas_client.add_service_to_login_url(login_url))
  
      controller.cas_client.should_receive(:validate_service_ticket).and_return { |st|
        st.response = CASClient::ValidationResponse.new("yes\n#{user.pseudonyms.first.unique_id.capitalize}\n")
      }
  
      get 'new', :ticket => 'ST-abcd'
      response.should redirect_to(dashboard_url)
      session[:cas_login].should == true
    end
  end
end
