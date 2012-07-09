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

describe "CountExistingCollectionItemsAndFollowers" do
  it "works" do
    u1 = user_model
    u2 = user_model
    u3 = user_model

    c1 = u1.collections.create!(:name => 'c1', :visibility => 'public')
    c2 = u1.collections.create!(:name => 'c2', :visibility => 'private')
    c3 = u2.collections.create!(:name => 'c3', :visibility => 'public')
    c4 = u3.collections.create!(:name => 'c4', :visibility => 'public')
    c4.destroy

    i11 = collection_item_model(:user_comment => "item 1", :user => u1, :collection => c1, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/one"))
    i12 = collection_item_model(:user_comment => "item 2", :user => u1, :collection => c1, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/two"))
    i21 = collection_item_model(:user_comment => "item 1 private", :user => u1, :collection => c2, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/two"))

    UserFollow.create_follow(u2, c1)
    UserFollow.create_follow(u3, c3)
    UserFollow.create_follow(u1, c3)

    DataFixup::CountExistingCollectionItemsAndFollowers.run

    cs = [c1,c2,c3,c4]
    cs.map(&:reload)
    cs.map(&:followers_count).should == [1,0,2,0]
    cs.map(&:items_count).should == [2,1,0,0]
  end
end
