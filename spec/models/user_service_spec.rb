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
    expect(@user_service.state).to eql(:active)
    @user_service.failed_request
    expect(@user_service.state).to eql(:failed)
  end
  
  it "should have a named scope for type" do
    @user_service.type = 'BookmarkService'
    @user_service.save!
    expect(UserService.of_type('BookmarkService').first.id).to eql(@user_service.id)
  end
  
  it "should have a named scope for service" do
    expect(UserService.for_service(@user_service)).to eq [@user_service]
    expect(UserService.for_service(@user_service.service)).to eq [@user_service]
  end
  
  it "should have a service_name" do
    expect(@user_service.service_name).to eql('Value For Service')
  end
  
  it "should be able to crypt a password" do
    expect(@user_service.crypted_password).to be_nil
    @user_service.password = 'password'
    expect(@user_service.crypted_password).not_to be_nil
    expect(@user_service.decrypted_password).to eql('password')
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
      expect(@registration.token).to eql('some token')
      expect(@registration.secret).to eql('some secret')
      expect(@registration.service_user_id).to eql(@user.id)
      expect(@registration.service_user_name).to eql(@user.name)
      expect(@registration.service_user_url).to eql('some url')
      expect(@registration.decrypted_password).to eql('password')
      expect(@registration.type).to eql('DocumentService')
    end

    it "should be able to register a delicious service" do
      params = {}
      params[:service] = 'delicious'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      us = UserService.register_from_params(user_model, params)

      expect(us.service_domain).to eql('delicious.com')
      expect(us.protocol).to eql('http-auth')
      expect(us.service_user_id).to eql('some username')
      expect(us.service_user_name).to eql('some username')
      expect(us.decrypted_password).to eql('password')
    end
  
    it "should be able to register a diigo service" do
      params = {}
      params[:service] = 'diigo'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      us = UserService.register_from_params(user_model, params)

      expect(us.service_domain).to eql('diigo.com')
      expect(us.protocol).to eql('http-auth')
      expect(us.service_user_id).to eql('some username')
      expect(us.service_user_name).to eql('some username')
      expect(us.decrypted_password).to eql('password')
    end
  
    it "should not be able to register an unknown service type" do
      params = {}
      params[:service] = 'some crazy service'
      params[:user_name] = 'some username'
      params[:password] = 'password'

      expect{UserService.register_from_params(user_model, params)}.to raise_error("Unknown Service Type")
    end
  end
  
  context "service type disambiguation" do
    it "should know that google_docs means 'DocumentService" do
      expect(UserService.service_type('google_docs')).to eql('DocumentService')
    end
    
    it "should know that diigo means BookmarkService" do
      expect(UserService.service_type('diigo')).to eql('BookmarkService')
    end
    
    it "should know that delicious means BookmarkService" do
      expect(UserService.service_type('delicious')).to eql('BookmarkService')
    end
    
    it "should use other things as a generic UserService" do
      expect(UserService.service_type('anything else')).to eql('UserService')
    end
  end

  context "password" do
    it "should decrypt the password to the original value" do
      s = UserService.new
      s.password = "asdf"
      expect(s.decrypted_password).to eql("asdf")
      s.password = "2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3"
      expect(s.decrypted_password).to eql("2t87aot72gho8a37gh4g[awg'waegawe-,v-3o7fya23oya2o3")
    end
  end
end
