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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Account do

  it "should provide a list of courses" do
    @account = Account.new
    lambda{@account.courses}.should_not raise_error
  end
  
  context "equella_settings" do
    it "should respond to :equella_settings" do
      Account.new.should be_respond_to(:equella_settings)
      Account.new.equella_settings.should be_nil
    end
    
    it "should return the equella_settings data if defined" do
      a = Account.new
      a.equella_endpoint = "http://oer.equella.com/signon.do"
      a.equella_settings.should_not be_nil
      a.equella_settings.endpoint.should eql("http://oer.equella.com/signon.do")
      a.equella_settings.default_action.should_not be_nil
    end
  end
  
  # it "should have an atom feed" do
    # account_model
    # @a.to_atom.should be_is_a(Atom::Entry)
  # end
  
  context "services" do
    it "should be able to specify a list of enabled services" do
      a = Account.new
      a.allowed_services = 'facebook,twitter'
      a.service_enabled?(:facebook).should be_true
      a.service_enabled?(:twitter).should be_true
      a.service_enabled?(:diigo).should be_false
      a.service_enabled?(:avatars).should be_false
    end
    
    it "should not enable services off by default" do
      a = Account.new
      a.service_enabled?(:facebook).should be_true
      a.service_enabled?(:avatars).should be_false
    end
    
    it "should add and remove services from the defaults" do
      a = Account.new
      a.allowed_services = '+avatars,-facebook'
      a.service_enabled?(:avatars).should be_true
      a.service_enabled?(:twitter).should be_true
      a.service_enabled?(:facebook).should be_false
    end
  end
  
  context "settings=" do
    it "should filter disabled settings" do
      a = Account.new
      a.root_account_id = 1
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql(nil)
      
      a.root_account_id = nil
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql(nil)
      
      a.settings[:global_includes] = true
      a.settings = {'global_javascript' => 'something'}.with_indifferent_access
      a.settings[:global_javascript].should eql('something')

      a.settings = {'error_reporting' => 'string'}.with_indifferent_access
      a.settings[:error_reporting].should eql(nil)
      
      a.settings = {'error_reporting' => {
        'action' => 'email',
        'email' => 'bob@yahoo.com',
        'extra' => 'something'
      }}.with_indifferent_access
      a.settings[:error_reporting].should be_is_a(Hash)
      a.settings[:error_reporting][:action].should eql('email')
      a.settings[:error_reporting][:email].should eql('bob@yahoo.com')
      a.settings[:error_reporting][:extra].should eql(nil)
    end
  end
  
  context "turnitin secret" do
    it "should decrypt the turnitin secret to the original value" do
      a = Account.new
      a.turnitin_shared_secret = "asdf"
      a.turnitin_shared_secret.should eql("asdf")
      a.turnitin_shared_secret = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      a.turnitin_shared_secret.should eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end
  
end
