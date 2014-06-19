#
# Copyright (C) 2012 Instructure, Inc.
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

describe AccountsController do

  context "SAML meta data" do
    before(:each) do
      pending("requires SAML extension") unless AccountAuthorizationConfig.saml_enabled
      ConfigFile.stub('saml', {
              :tech_contact_name => nil,
              :tech_contact_email => nil
      })
      @account = Account.create!(:name => "test")
    end

    it 'should render for non SAML configured accounts' do
      get "/saml_meta_data"
      response.should be_success
      response.body.should_not == ""
    end
    
    it "should use the correct entity_id" do
      HostUrl.stubs(:default_host).returns('bob.cody.instructure.com')
      @aac = @account.account_authorization_configs.create!(:auth_type => "saml")
      
      get "/saml_meta_data"
      response.should be_success
      doc = Nokogiri::XML(response.body)
      doc.at_css("EntityDescriptor")['entityID'].should == "http://bob.cody.instructure.com/saml2"
    end

  end

end
