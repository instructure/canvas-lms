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

describe "UserFollow" do
  describe "validate_following_logic" do
    it "should not allow following yourself" do
      user_model
      @follow = @user.user_follows.build(:followed_item => @user)
      @follow.save.should == false
      @follow.errors.on(:followed_item).should be_present
    end

    it "should not allow following your own collection" do
      user_model
      @collection = @user.collections.create!(:name => "my collection")
      @follow = @user.user_follows.build(:followed_item => @collection)
      @follow.save.should == false
      @follow.errors.on(:followed_item).should be_present
    end
  end

  context "across shards" do
    it_should_behave_like "sharding"

    before do
      @user1 = user_model
      @shard1.activate {
        @user2 = user_model
        @collection = @user2.collections.create!(:name => "my collection")
        @collection2 = @user2.collections.create!(:name => "my other collection", :visibility => "public")
      }
      @cols = @user2.collections(true).to_a
    end

    it "should delete on the other shard on un-follow" do
      @uf = @user1.user_follows.create!(:followed_item => @collection)
      @uf.shard.should == Shard.default
      @uf2 = @collection.shard.activate { UserFollow.first(:conditions => { :following_user_id => @user1.id, :followed_item_id => @collection.id }) }
      @uf2.shard.should == @collection.shard
      @uf.destroy
      expect { @collection.shard.activate { @uf2.reload } }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should delete from the other shard to the current" do
      @uf = @user1.user_follows.create!(:followed_item => @collection)
      @uf.shard.should == Shard.default
      @uf2 = @collection.shard.activate { UserFollow.first(:conditions => { :following_user_id => @user1.id, :followed_item_id => @collection.id }) }
      @uf2.shard.should == @collection.shard
      @uf2.destroy
      expect { @uf.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    def verify
      yield
      @shard1.activate { yield }
      @shard2.activate { yield }
    end

    shared_examples_for "sharded user following" do
      it "should find things the user is following" do
        @user1.shard.activate { UserFollow.first.should == @user1.user_follows.first }
        verify {
          @user1.reload.user_follows.map(&:followed_item).should == [ @collection ]
          # optimization for filtering a list to followed items
          UserFollow.followed_by_user(@cols, @user1).should == [ @collection ]
          UserFollow.followed_by_user(@cols, @user2).should == []
        }
      end

      it "should find users that are following the thing" do
        @collection.shard.activate { UserFollow.first.should == @collection.following_user_follows.first }
        verify {
          @collection.following_user_follows.map(&:following_user).should == [ @user1 ]
        }
      end
    end

    context "follow from user shard" do
      it_should_behave_like "sharded user following"

      before do
        @uf = @user1.user_follows.create!(:followed_item => @collection)
        @uf.shard.should == @user1.shard
      end
    end

    context "follow from thing shard" do
      it_should_behave_like "sharded user following"

      before do
        @uf = @collection.shard.activate { UserFollow.create!(:following_user => @user1, :followed_item => @collection) }
        @uf.shard.should == @user1.shard
      end
    end

    context "follow from a third shard" do
      it_should_behave_like "sharded user following"

      before do
        @uf = @shard2.activate { UserFollow.create!(:following_user => @user1, :followed_item => @collection) }
        @uf.shard.should == @user1.shard
      end
    end
  end
end
