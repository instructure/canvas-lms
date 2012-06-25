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
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

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

      @user2.visible_stream_item_instances.should be_empty
      items = @user1.visible_stream_item_instances.map(&:stream_item)
      items.size.should == 1
      items.first.data.type.should == 'CollectionItem'
    end
  end

  context "across shards" do
    it_should_behave_like "sharding"

    it "should handle user upvotes on another shard" do
      @shard1.activate { @user1 = user_model }
      @shard2.activate { @item = collection_item_model(:collection => group_model.collections.create!, :user => user_model) }
      @upvote = CollectionItemUpvote.create!(:user => @user1, :collection_item_data => @item.data)
      @upvote.shard.should == @user1.shard
      @item.data.reload.upvote_count.should == 1

      [ Shard.default, @shard1, @shard2 ].each do |shard|
        shard.activate do
          CollectionItemData.load_upvoted_by_user([@item.reload.data], @user1)
          @item.data.upvoted_by_user.should == true
        end
      end

      @upvote.destroy
      @item.data.reload.upvote_count.should == 0

      [ Shard.default, @shard1, @shard2 ].each do |shard|
        shard.activate do
          CollectionItemData.load_upvoted_by_user([@item.reload.data], @user1)
          @item.data.upvoted_by_user.should == false
        end
      end
    end

    it "should handle clones on another shard" do
      @shard1.activate { @user1 = user_model }
      @shard2.activate { @item1 = collection_item_model(:collection => group_model.collections.create!, :user => user_model) }
      @item2 = @user1.collections.create!.collection_items.create!(:collection_item_data => @item1.data, :user => @user1)
      @item2.shard.should == @user1.shard
      @data = @item1.data.reload
      @data.should == @item2.data
      @data.shard.should == @item1.shard
      @data.post_count.should == 2

      @item2.destroy
      @data.reload.post_count.should == 1
      @item2.update_attribute(:workflow_state, 'active')
      @data.reload.post_count.should == 2
      @item2.destroy!
      @data.reload.post_count.should == 1
    end
  end
end
