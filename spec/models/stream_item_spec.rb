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
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe StreamItem do
  it "should not infer a user_id for DiscussionTopic" do
    user
    context = Course.create!
    dt = DiscussionTopic.create!(:context => context)
    dt.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.data(@user.id)
    data.should be_a DiscussionTopic
    data.user_id.should be_nil
  end

  it "should prefer a Context for Message stream item context" do
    notification_model(:name => 'Assignment Created')
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
    item = @user.stream_item_instances.first.stream_item
    item.data.notification_name.should == 'Assignment Created'
    item.context.should == @course

    course_items = @user.recent_stream_items(:contexts => [@course])
    course_items.should == [item]
  end

  describe "destroy_stream_items_using_setting" do
    it "should have a default ttl" do
      si1 = StreamItem.create! { |si| si.asset_type = 'Message'; si.data = {} }
      si2 = StreamItem.create! { |si| si.asset_type = 'Message'; si.data = {} }
      StreamItem.where(:id => si2).update_all(:updated_at => 1.year.ago)
      expect {
        StreamItem.destroy_stream_items_using_setting
      }.to change(StreamItem, :count).by(-1)
    end
  end

  context "across shards" do
    it_should_behave_like "sharding"

    it "should create stream items on the user's shard" do
      group_with_user
      @user1 = @user
      @user2 = @shard1.activate { user_model }
      @coll = @group.collections.create!

      UserFollow.create_follow(@user1, @coll)
      UserFollow.create_follow(@user2, @coll)

      @item = collection_item_model(:collection => @coll, :user => @user1)
      @user2.reload.stream_item_instances.map { |i| i.stream_item.data }.should == [@item]
      @user2.stream_item_instances.first.shard.should == @shard1
      @user2.stream_item_instances.first.stream_item.shard.should == Shard.current
    end

    it "should delete instances on all associated shards" do
      course_with_teacher(:active_all => 1)
      @user2 = @shard1.activate { user_model }
      @course.enroll_student(@user2).accept!

      dt = @course.discussion_topics.create!(:title => 'title')
      @user2.reload.recent_stream_items.should == [dt.stream_item]
      dt.stream_item.associated_shards.should == [Shard.current, @shard1]
      dt.stream_item.destroy
      @user2.recent_stream_items.should == []
    end

    it "should not find stream items for courses from the wrong shard" do
      course_with_teacher(:active_all => 1)
      @shard1.activate do
        @user2 = user_model
        @course.enroll_student(@user2).accept!
        account = Account.create!
        @course2 = account.courses.create! { |c| c.id = @course.local_id }
        @course2.offer!
        @course2.enroll_student(@user2).accept!
        @dt2 = @course2.discussion_topics.create!
      end
      @dt = @course.discussion_topics.create!

      @user2.recent_stream_items.map(&:data).sort_by(&:id).should == [@dt, @dt2].sort_by(&:id)
      @user2.recent_stream_items(:context => @course).map(&:data).should == [@dt]
      @shard1.activate do
        @user2.recent_stream_items(:context => @course2).map(&:data).should == [@dt2]
      end
    end
  end
end
