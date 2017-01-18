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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20120106220543_set_saml_entity_id'

describe 'SetSamlEntityId' do
  before(:each) do
    ConfigFile.stub('saml', {
            :entity_id => "http://watup_fool.com/saml2"
    })
    HostUrl.stubs(:default_host).returns('bob.cody.instructure.com')
    @account = Account.new
    @account.save
    @aac = @account.authentication_providers.create!(:auth_type => "saml")
    AccountAuthorizationConfig.where(:id => @aac).update_all(:entity_id => nil)
  end
  
  it "should set the entity_id to the current setting if none is set" do
    SetSamlEntityId.up
    @aac.reload
    expect(@aac.entity_id).to eq "http://watup_fool.com/saml2"
  end
  
  it "should leave the entity_id the same if already set" do
    @aac.entity_id = "haha"
    @aac.save

    SetSamlEntityId.up
    
    @aac.reload
    expect(@aac.entity_id).to eq "haha"
  end
  
  it "should use the account's domain if no config is set" do
    ConfigFile.stub('saml', {
            :entity_id => nil
    })

    SetSamlEntityId.up

    @aac.reload
    expect(@aac.entity_id).to eq "http://bob.cody.instructure.com/saml2"
  end
  
  
end
