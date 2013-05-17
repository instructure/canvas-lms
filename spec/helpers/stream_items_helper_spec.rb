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

describe StreamItemsHelper do
  before do
    Notification.create!(:name => "Assignment Created", :category => "TestImmediately")
    course_with_teacher(:active_all => true)
    @other_user = user()
    @another_user = user()

    @context = @course
    @discussion = discussion_topic_model
    @announcement = announcement_model
    @assignment = assignment_model(:course => @course)
    # this conversation will not be shown, since the teacher is the last author
    conversation(@another_user, @teacher).conversation.add_message(@teacher, 'zomg')
    # whereas this one will be shown
    @participant = conversation(@other_user, @teacher)
    @conversation = @participant.conversation
  end

  context "categorize_stream_items" do
    it "should categorize different types correctly" do
      @items = @teacher.recent_stream_items
      @items.size.should == 5 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].size.should == 1
      @categorized["Conversation"].size.should == 1
      @categorized["Assignment"].size.should == 1
      @categorized["DiscussionTopic"].size.should == 1
    end

    it "should normalize output into common fields" do
      @items = @teacher.recent_stream_items
      @items.size.should == 5 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized.values.flatten.each do |presenter|
        item = @items.detect{ |si| si.id == presenter.stream_item_id }
        item.should_not be_nil
        presenter.updated_at.should_not be_nil
        presenter.path.should_not be_nil
        presenter.context.should_not be_nil
        presenter.summary.should_not be_nil
      end
    end
  end

  context "extract_path" do
    it "should link to correct place" do
      @items = @teacher.recent_stream_items
      @items.size.should == 5 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.path.should match("/courses/#{@course.id}/announcements/#{@announcement.id}")
      @categorized["Conversation"].first.path.should match("/conversations/#{@conversation.id}")
      @categorized["Assignment"].first.path.should match("/courses/#{@course.id}/assignments/#{@assignment.id}")
      @categorized["DiscussionTopic"].first.path.should match("/courses/#{@course.id}/discussion_topics/#{@discussion.id}")
    end
  end

  context "extract_context" do
    it "should find the correct context" do
      @items = @teacher.recent_stream_items
      @items.size.should == 5 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.context.id.should == @course.id
      @categorized["Conversation"].first.context.id.should == @other_user.id
      @categorized["Assignment"].first.context.id.should == @course.id
      @categorized["DiscussionTopic"].first.context.id.should == @course.id
    end
  end

  context "extract_summary" do
    it "should find the right content" do
      @items = @teacher.recent_stream_items
      @items.size.should == 5 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.summary.should == @announcement.title
      @categorized["Conversation"].first.summary.should == @participant.last_message.body
      @categorized["Assignment"].first.summary.should =~ /Assignment Created/
      @categorized["DiscussionTopic"].first.summary.should == @discussion.title
    end
  end
end
