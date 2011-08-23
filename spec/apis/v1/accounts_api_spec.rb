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

describe "Accounts API", :type => :integration do
  before do
    user_with_pseudonym(:active_all => true)
    @a1 = account_model(:name => 'root')
    @a1.add_user(@user)
    @a2 = account_model(:name => 'subby', :parent_account => @a1, :sis_source_id => 'sis1')
    @a2.add_user(@user)
    @a3 = account_model(:name => 'no-access')
    # even if we have access to it implicitly, it's not listed
    @a4 = account_model(:name => 'implicit-access', :parent_account => @a1)
  end

  it "should return the account list" do
    json = api_call(:get, "/api/v1/accounts.json",
                    { :controller => 'accounts', :action => 'index', :format => 'json' })
    json.sort_by { |a| a['id'] }.should == [
      {
        'id' => @a1.id,
        'name' => 'root',
        'root_account_id' => nil,
        'parent_account_id' => nil,
        'sis_account_id' => nil,
      },
      {
        'id' => @a2.id,
        'name' => 'subby',
        'root_account_id' => @a1.id,
        'parent_account_id' => @a1.id,
        'sis_account_id' => 'sis1',
      },
    ]
  end

  it "should return an individual account" do
    # by id
    json = api_call(:get, "/api/v1/accounts/#{@a1.id}",
                    { :controller => 'accounts', :action => 'show', :id => @a1.to_param, :format => 'json' })
    json.should ==
      {
        'id' => @a1.id,
        'name' => 'root',
        'root_account_id' => nil,
        'parent_account_id' => nil,
        'sis_account_id' => nil,
      }

    # by sis id
    json = api_call(:get, "/api/v1/accounts/sis_account_id:sis1",
                    { :controller => 'accounts', :action => 'show', :id => "sis_account_id:sis1", :format => 'json' })
    json.should ==
      {
        'id' => @a2.id,
        'name' => 'subby',
        'root_account_id' => @a1.id,
        'parent_account_id' => @a1.id,
        'sis_account_id' => 'sis1',
      }
  end
end

