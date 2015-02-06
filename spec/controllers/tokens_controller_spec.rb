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

describe TokensController do
  describe "developer keys" do
    it "should require being logged in to create an access token" do
      post 'create', :access_token => {:purpose => "test"}
      expect(response).to be_redirect
      expect(assigns[:token]).to be_nil
    end
    
    it "should allow creating an access token" do
      user(:active_user => true)
      user_session(@user)
      post 'create', :access_token => {:purpose => "test", :expires_at => "jun 1 2011"}
      expect(response).to be_success
      expect(assigns[:token]).not_to be_nil
      expect(assigns[:token].developer_key).to eq DeveloperKey.default
      expect(assigns[:token].purpose).to eq "test"
      expect(assigns[:token].expires_at.to_date).to eq Time.parse("jun 1 2011").to_date
    end

    it "should not allow creating an access token while masquerading" do
      user(:active_user => true)
      user_session(@user)
      Account.site_admin.account_users.create!(user: @user)
      session[:become_user_id] = user_with_pseudonym.id

      post 'create', :access_token => {:purpose => "test", :expires_at => "jun 1 2011"}
      assert_status(401)
    end

    it "should not allow explicitly setting the token value" do
      user(:active_user => true)
      user_session(@user)
      post 'create', :access_token => {:purpose => "test", :expires_at => "jun 1 2011", :token => "mytoken"}
      expect(response).to be_success
      expect(response.body).not_to match(/mytoken/)
      expect(assigns[:token]).not_to be_nil
      expect(assigns[:token].full_token).not_to match(/mytoken/)
      expect(response.body).to match(/#{assigns[:token].full_token}/)
      expect(assigns[:token].developer_key).to eq DeveloperKey.default
      expect(assigns[:token].purpose).to eq "test"
      expect(assigns[:token].expires_at.to_date).to eq Time.parse("jun 1 2011").to_date
    end
    
    it "should require being logged in to delete an access token" do
      delete 'destroy', :id => 5
      expect(response).to be_redirect
    end
    
    it "should allow deleting an access token" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.create!
      expect(token.user_id).to eq @user.id
      delete 'destroy', :id => token.id
      expect(response).to be_success
      expect(assigns[:token]).to be_frozen
    end

    it "should not allow deleting an access token while masquerading" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.create!
      expect(token.user_id).to eq @user.id
      Account.site_admin.account_users.create!(user: @user)
      session[:become_user_id] = user_with_pseudonym.id

      delete 'destroy', :id => token.id
      assert_status(401)
    end

    it "should not allow deleting someone else's access token" do
      user(:active_user => true)
      user_session(@user)
      user2 = User.create!
      token = user2.access_tokens.create!
      expect(token.user_id).to eq user2.id
      delete 'destroy', :id => token.id
      assert_status(404)
    end
    
    it "should require being logged in to retrieve an access token" do
      get 'show', :id => 5
      expect(response).to be_redirect
    end
    
    it "should allow retrieving an access token, but not give the full token string" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.new
      token.developer_key = DeveloperKey.default
      token.save!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq false
      get 'show', :id => token.id
      expect(response).to be_success
      expect(assigns[:token]).to eq token
      expect(response.body).to match(/#{assigns[:token].token_hint}/)
    end
    
    it "should not include token for protected tokens" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.create!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq true
      get 'show', :id => token.id
      expect(response).to be_success
      expect(assigns[:token]).to eq token
      expect(response.body).not_to match(/#{assigns[:token].token_hint}/)
    end
    
    it "should not allow retrieving someone else's access token" do
      user(:active_user => true)
      user_session(@user)
      user2 = User.create!
      token = user2.access_tokens.create!
      expect(token.user_id).to eq user2.id
      get 'show', :id => token.id
      assert_status(404)
    end
    
    it "should allow updating a token" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.new
      token.developer_key = DeveloperKey.default
      token.save!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq false
      put 'update', :id => token.id, :access_token => {:purpose => 'new purpose'}
      expect(response).to be_success
      expect(assigns[:token]).to eq token
      expect(assigns[:token].purpose).to eq "new purpose"
      expect(response.body).to match(/#{assigns[:token].token_hint}/)
    end

    it "should allow regenerating an unprotected token" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.new
      token.developer_key = DeveloperKey.default
      token.save!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq false
      put 'update', :id => token.id, :access_token => {:regenerate => '1'}
      expect(response).to be_success
      expect(assigns[:token]).to eq token
      expect(assigns[:token].crypted_token).not_to eq token.crypted_token
      expect(response.body).to match(/#{assigns[:token].full_token}/)
    end

    it "should not allow regenerating a token while masquerading" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.new
      token.developer_key = DeveloperKey.default
      token.save!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq false
      Account.site_admin.account_users.create!(user: @user)
      session[:become_user_id] = user_with_pseudonym.id
      put 'update', :id => token.id, :access_token => {:regenerate => '1'}
      assert_status(401)
    end

    it "should not allow regenerating a protected token" do
      user(:active_user => true)
      user_session(@user)
      token = @user.access_tokens.new
      token.save!
      expect(token.user_id).to eq @user.id
      expect(token.protected_token?).to eq true
      put 'update', :id => token.id, :access_token => {:regenerate => '1'}
      expect(response).to be_success
      expect(assigns[:token]).to eq token
      expect(assigns[:token].crypted_token).to eq token.crypted_token
      expect(response.body).not_to match(/#{assigns[:token].token_hint}/)
    end
    
    it "should not allow updating someone else's token" do
      user(:active_user => true)
      user_session(@user)
      user2 = User.create!
      token = user2.access_tokens.create!
      expect(token.user_id).to eq user2.id
      put 'update', :id => token.id
      assert_status(404)
    end
  end
end
