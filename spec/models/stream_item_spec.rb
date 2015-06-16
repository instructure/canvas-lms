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
    expect(data).to be_a DiscussionTopic
    expect(data.user_id).to be_nil
  end

  it "should prefer a Context for Message stream item context" do
    notification_model(:name => 'Assignment Created')
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
    item = @user.stream_item_instances.first.stream_item
    expect(item.data.notification_name).to eq 'Assignment Created'
    expect(item.context).to eq @course

    course_items = @user.recent_stream_items(:contexts => [@course])
    expect(course_items).to eq [item]
  end

  it "doesn't unlink discussion entries from their topics" do
    user
    context = Course.create!
    dt = DiscussionTopic.create!(:context => context, :require_initial_post => true)
    de = dt.root_discussion_entries.create!
    dt.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.data(@user.id)
    expect(de.reload.discussion_topic_id).not_to be_nil
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
    specs_require_sharding

    it "should delete instances on all associated shards" do
      course_with_teacher(:active_all => 1)
      @user2 = @shard1.activate { user_model }
      @course.enroll_student(@user2).accept!

      dt = @course.discussion_topics.create!(:title => 'title')
      expect(@user2.reload.recent_stream_items).to eq [dt.stream_item]
      expect(dt.stream_item.associated_shards).to eq [Shard.current, @shard1]
      dt.stream_item.destroy
      expect(@user2.recent_stream_items).to eq []
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

      expect(@user2.recent_stream_items.map(&:data).sort_by(&:id)).to eq [@dt, @dt2].sort_by(&:id)
      expect(@user2.recent_stream_items(:context => @course).map(&:data)).to eq [@dt]
      @shard1.activate do
        expect(@user2.recent_stream_items(:context => @course2).map(&:data)).to eq [@dt2]
      end
    end

    it "should always cache stream items on the user's shard" do
      course_with_teacher(:active_all => 1)
      @user2 = @shard1.activate { user_model }
      @course.enroll_student(@user2).accept!

      dt = @course.discussion_topics.create!(:title => 'title')
      enable_cache do
        items = @user2.cached_recent_stream_items
        items2 = @shard1.activate { @user2.cached_recent_stream_items }
        expect(items).to eq [dt.stream_item]
        expect(items).to be === items2 # same object, because same cache key

        item = @user2.visible_stream_item_instances.last
        item.update_attribute(:hidden, true)

        # after dismissing an item, the old items should no longer be cached
        items = @user2.cached_recent_stream_items
        items2 = @shard1.activate { @user2.cached_recent_stream_items }
        expect(items).to be_empty
        expect(items2).to be_empty
      end
    end
  end
end
