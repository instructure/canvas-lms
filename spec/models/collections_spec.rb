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

describe 'Collections' do
  def setup_collections
    @pub1 = @context.collections.create!(:visibility => "public")
    @pri1 = @context.collections.create!(:visibility => "private")
    @del1 = @context.collections.create!(:visibility => "public")
    run_jobs
  end

  shared_examples_for "auto-follow context" do
    it "should auto-follow for users following" do
      setup_collections
      @del1.destroy
      UserFollow.create_follow(@user, @context)
      run_jobs

      # user is now following context, and will auto-follow context's existing and
      # new collections
      @pub1.reload.followers.should == [@user]
      @pri1.reload.followers.should == (@follows_private ? [@user] : [])
      @del1.reload.followers.should == []

      @pub2 = @context.collections.create!(:visibility => "public")
      @pri2 = @context.collections.create!(:visibility => "private")
      run_jobs

      @pub2.reload.followers.should == [@user]
      @pri2.reload.followers.should == (@follows_private ? [@user] : [])

      @pub2.destroy
      @pub2.reload.followers.should == []
    end

    it "should correctly calculate followers_count" do
      setup_collections
      @del1.destroy
      5.times { UserFollow.create_follow(user_model, @context) }
      run_jobs

      @pub1.reload.followers_count.should == @pub1.reload.followers.count
      @pri1.reload.followers_count.should == (@follows_private ? @pri1.reload.followers.count : 0)
      @del1.reload.followers_count.should == 0

      UserFollow.destroy_all

      @pub1.reload.followers_count.should == 0
      @pri1.reload.followers_count.should == 0
    end

    it "should correctly calculate items_count" do
      setup_collections
      5.times do 
        [@pub1, @pri1, @del1].each do |col|
          collection_item_model(:user_comment => "item 1",
                                :user => @user,
                                :collection => col,
                                :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/one"))
        end
      end
      @del1.destroy

      @pub1.reload.items_count.should == 5
      @pri1.reload.items_count.should == 5
      @del1.reload.items_count.should == 5

      @del1.collection_items.destroy_all
      @del1.reload.items_count.should == 0
    end
  end

  describe "user collections" do
    it_should_behave_like "auto-follow context"
    before do
      @context = user_model
      @user = user_model
      @follows_private = false
    end
  end

  describe "group collections as non-member" do
    it_should_behave_like "auto-follow context"
    before do
      @context = group_model
      @user = user_model
      @follows_private = false
    end
  end

  describe "group collections as member" do
    it_should_behave_like "auto-follow context"
    before do
      group_with_user
      @context = @group
      @follows_private = true
    end

    it "should auto-unfollow from private collections when a member leaves" do
      setup_collections
      @del1.destroy

      @pub1.reload.followers.should == [@user]
      @pri1.reload.followers.should == [@user]
      @del1.reload.followers.should == []

      GroupMembership.destroy_all
      run_jobs

      @pub1.reload.followers.should == [@user]
      @pri1.reload.followers.should == []
      @del1.reload.followers.should == []
    end
  end
end

