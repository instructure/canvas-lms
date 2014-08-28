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

describe UserService do
  before :once do
    user_service_model
  end
  
  it "should have a useful workflow" do
    @user_service.state.should eql(:active)
    @user_service.failed_request
    @user_service.state.should eql(:failed)
  end
  
  it "should have a named scope for type" do
    @user_service.type = 'BookmarkService'
    @user_service.save!
    UserService.of_type('BookmarkService').first.id.should eql(@user_service.id)
  end
  
  it "should have a named scope for service" do
    UserService.for_service(@user_service).should == [@user_service]
    UserService.for_service(@user_service.service).should == [@user_service]
  end
  
  it "should have a service_name" do
    @user_service.service_name.should eql('Value For Service')
  end
  
  it "should be able to crypt a password" do
    @user_service.crypted_password.should be_nil
    @user_service.password = 'password'
    @user_service.crypted_password.should_not be_nil
    @user_service.decrypted_password.should eql('password')
  end
  
  context "registration" do
    it "should be able to register a UserService, defaulting to a GoogleDocs service" do
      @registration = UserService.register(
        :user => user_model, 
        :token => 'some token', 
        :secret => 'some secret',
        :service_user_id => @user.id,
        :service_user_name => @user.name,
        :service_user_url => 'some url',
        :password => 'password'
      )
      @registration.token.should eql('some token')
      @registration.secret.should eql('some secret')
      @registration.service_user_id.should eql(@user.id)
      @registration.service_user_name.should eql(@user.name)
      @registration.service_user_url.should eql('some url')
      @registration.decrypted_password.should eql('password')
      @registration.type.should eql('DocumentService')
    end

    it "should be able to register a delicious service" do
      params = {}
      params[:service] = 'delicious'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      us = UserService.register_from_params(user_model, params)

      us.service_domain.should eql('delicious.com')
      us.protocol.should eql('http-auth')
      us.service_user_id.should eql('some username')
      us.service_user_name.should eql('some username')
      us.decrypted_password.should eql('password')
    end
  
    it "should be able to register a diigo service" do
      params = {}
      params[:service] = 'diigo'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      us = UserService.register_from_params(user_model, params)

      us.service_domain.should eql('diigo.com')
      us.protocol.should eql('http-auth')
      us.service_user_id.should eql('some username')
      us.service_user_name.should eql('some username')
      us.decrypted_password.should eql('password')
    end
  
    it "should not be able to register an unknown service type" do
      params = {}
      params[:service] = 'some crazy service'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      lambda{UserService.register_from_params(user_model, params)}.should raise_error("Unknown Service Type")
    end
  end
  
  context "service type disambiguation" do
    it "should know that google_docs means 'DocumentService" do
      UserService.service_type('google_docs').should eql('DocumentService')
    end
    
    it "should know that diigo means BookmarkService" do
      UserService.service_type('diigo').should eql('BookmarkService')
    end
    
    it "should know that delicious means BookmarkService" do
      UserService.service_type('delicious').should eql('BookmarkService')
    end
    
    it "should use other things as a generic UserService" do
      UserService.service_type('anything else').should eql('UserService')
    end
  end

  context "password" do
    it "should decrypt the password to the original value" do
      s = UserService.new
      s.password = "asdf"
      s.decrypted_password.should eql("asdf")
      s.password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      s.decrypted_password.should eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end
end
