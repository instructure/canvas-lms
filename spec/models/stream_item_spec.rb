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
    data = si.stream_data(@user.id)
    data.type.should == 'DiscussionTopic'
    data.user_id.should be_nil
  end

  it "should prefer a Context for Message stream item context" do
    notification_model(:name => 'Assignment Created')
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
    item = @user.stream_item_instances.first.stream_item
    item.data.notification_name.should == 'Assignment Created'
    item.context_code.should == @course.asset_string

    course_items = @user.recent_stream_items(:contexts => [@course])
    course_items.should == [item]
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
      @shard1.activate do
        @user2.reload.visible_stream_item_instances.map { |i| i.stream_item.data.type }.should == ['CollectionItem']
      end
    end
  end
end
