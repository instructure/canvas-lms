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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe DeveloperKeysController, type: :request do
  describe "GET 'index'" do
    it 'should require authorization' do
      unauthorized_api_call(:get, "/api/v1/developer_keys.json",
                      {:controller => 'developer_keys', :action => 'index', 
                       :format => 'json'})
    end
    
    it 'should return the list of developer keys' do
      index_call
    end
  end
  
  describe "POST 'create'" do
    it 'should require authorization' do
      unauthorized_api_call(:post, "/api/v1/developer_keys.json",
                      {:controller => 'developer_keys', :action => 'create', 
                       :format => 'json'}, {:developer_key => {}})
    end
    
    it 'should create a new developer key' do
      create_call
    end
  end
  
  describe "PUT 'update'" do
    it 'should require authorization' do
      key = DeveloperKey.create!
      unauthorized_api_call(:put, "/api/v1/developer_keys/#{key.id}.json",
                      {:controller => 'developer_keys', :action => 'update', :id => key.id.to_s,
                       :format => 'json'}, {:developer_key => {}})
    end
    
    
    it 'should update an existing developer key' do
      update_call
    end
  end
  
  describe "DELETE 'destroy'" do
    it 'should require authorization' do
      key = DeveloperKey.create!
      unauthorized_api_call(:delete, "/api/v1/developer_keys/#{key.id}.json",
                      {:controller => 'developer_keys', :action => 'destroy', :id => key.id.to_s,
                       :format => 'json'})
    end
    
    it 'should delete an existing developer key' do
      destroy_call
    end
  end


  def admin_session
    account_admin_user(:account => Account.site_admin)
  end

  def index_call
    admin_session
    key = DeveloperKey.create!
    json = api_call(:get, "/api/v1/developer_keys.json",
                    {:controller => 'developer_keys', :action => 'index', :format => 'json'})

    confirm_valid_key(json[0], key)
  end

  def create_call
    admin_session
    post_hash = {:developer_key => {'name' => 'cool tool', :tool_id => 'cool_tool', :icon_url => ''}}
    json = api_call(:post, "/api/v1/developer_keys.json",
                    {:controller => 'developer_keys', :action => 'create', :format => 'json',
                     }, post_hash)

    DeveloperKey.count.should == 1
    confirm_valid_key(json, DeveloperKey.last)
  end

  def update_call
    admin_session
    key = DeveloperKey.create!
    post_hash = {:developer_key => {'name' => 'cool tool', :tool_id => 'cool_tool'}}
    json = api_call(:put, "/api/v1/developer_keys/#{key.id}.json",
                    {:controller => 'developer_keys', :action => 'update', :format => 'json',
                     :id => key.id.to_s}, post_hash)

    key.reload
    confirm_valid_key(json, key)
  end
  
  def destroy_call
    admin_session
    key = DeveloperKey.create!
    api_call(:delete, "/api/v1/developer_keys/#{key.id}.json",
                    {:controller => 'developer_keys', :action => 'destroy', :format => 'json',
                     :id => key.id.to_s})
    
    DeveloperKey.find_by_id(key.id).should be_nil
  end
  
  def unauthorized_api_call(*args)
    raw_api_call(*args)
    response.code.should == "401"
  end
  
  def confirm_valid_key(hash, key)
    hash['id'].should == key.global_id
    hash['tool_id'].should == key.tool_id
    hash['icon_url'].should == key.icon_url
    hash['name'].should == key.name
  end
end
