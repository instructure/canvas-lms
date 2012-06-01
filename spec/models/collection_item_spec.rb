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

describe 'CollectionItem' do

  describe 'Stream Item' do
    it "should generate stream items for users following the collection" do
      group_with_user
      @user1 = @user
      @user2 = user_model
      @coll = @group.collections.create!

      UserFollow.create_follow(@user1, @coll)
      UserFollow.create_follow(@user2, @coll)

      @item = collection_item_model(:collection => @coll, :user => @user2)

      @user2.visible_stream_items.should be_empty
      items = @user1.visible_stream_items
      items.size.should == 1
      items.first.data.type.should == 'CollectionItem'
    end
  end
end
