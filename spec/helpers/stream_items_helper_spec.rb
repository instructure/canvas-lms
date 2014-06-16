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
  before :once do
    Notification.create!(:name => "Assignment Created", :category => "TestImmediately")
    course_with_teacher(:active_all => true)
    course_with_student(:active_all => true, :course => @course)
    @other_user = user()
    @another_user = user()

    @context = @course
    @discussion = discussion_topic_model
    @announcement = announcement_model
    @assignment = assignment_model(:course => @course)
    @submission = submission_model(assignment: @assignment, user: @student)
    @assessor_submission = submission_model(assignment: @assignment, user: @teacher)
    @assessment_request = AssessmentRequest.create!(assessor: @teacher, asset: @submission, user: @student, assessor_asset: @assessor_submission)
    @assessment_request.workflow_state = 'assigned'
    @assessment_request.save
    # this conversation will not be shown, since the teacher is the last author
    conversation(@another_user, @teacher).conversation.add_message(@teacher, 'zomg')
    # whereas this one will be shown
    @participant = conversation(@other_user, @teacher)
    @conversation = @participant.conversation
  end

  context "categorize_stream_items" do
    it "should categorize different types correctly" do
      @items = @teacher.recent_stream_items
      @items.size.should == 6 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].size.should == 1
      @categorized["Conversation"].size.should == 1
      @categorized["Assignment"].size.should == 1
      @categorized["DiscussionTopic"].size.should == 1
      @categorized["AssessmentRequest"].size.should == 1
    end

    it "should normalize output into common fields" do
      @items = @teacher.recent_stream_items
      @items.size.should == 6 # 1 for each type, 1 hidden conversation
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

    it "should skip items that are not visible to the current user" do
      # this discussion topic will not be shown since it is a graded discussion with a
      # future unlock at date
      @group_assignment_discussion = group_assignment_discussion({ :course => @course })
      @group_assignment_discussion.update_attribute(:user, @teacher)
      assignment = @group_assignment_discussion.assignment
      assignment.update_attributes({
        :due_at => 30.days.from_now,
        :lock_at => 30.days.from_now,
        :unlock_at => 20.days.from_now
      })
      @student.recent_stream_items.should_not include @group_assignment_discussion
      @teacher.recent_stream_items.should_not include @group_assignment_discussion
    end

    context "across shards" do
      specs_require_sharding

      it "stream item ids should always be relative to the user's shard" do
        course_with_teacher(:active_all => 1)
        @user2 = @shard1.activate { user_model }
        @course.enroll_student(@user2).accept!
        dt = @course.discussion_topics.create!(:title => 'title')

        items = @user2.recent_stream_items
        categorized = helper.categorize_stream_items(items, @user2)
        categorized1 = @shard1.activate{ helper.categorize_stream_items(items, @user2) }
        categorized2 = @shard2.activate{ helper.categorize_stream_items(items, @user2) }
        si_id = @shard1.activate { items[0].id }
        categorized["DiscussionTopic"][0].stream_item_id.should == si_id
        categorized1["DiscussionTopic"][0].stream_item_id.should == si_id
        categorized2["DiscussionTopic"][0].stream_item_id.should == si_id
      end
    end
  end

  context "extract_path" do
    it "should link to correct place" do
      @items = @teacher.recent_stream_items
      @items.size.should == 6 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.path.should match("/courses/#{@course.id}/announcements/#{@announcement.id}")
      @categorized["Conversation"].first.path.should match("/conversations/#{@conversation.id}")
      @categorized["Assignment"].first.path.should match("/courses/#{@course.id}/assignments/#{@assignment.id}")
      @categorized["DiscussionTopic"].first.path.should match("/courses/#{@course.id}/discussion_topics/#{@discussion.id}")
      @categorized["AssessmentRequest"].first.path.should match("/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}")
    end
  end

  context "extract_context" do
    it "should find the correct context" do
      @items = @teacher.recent_stream_items
      @items.size.should == 6 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.context.id.should == @course.id
      @categorized["Conversation"].first.context.id.should == @other_user.id
      @categorized["Assignment"].first.context.id.should == @course.id
      @categorized["DiscussionTopic"].first.context.id.should == @course.id
      @categorized["AssessmentRequest"].first.context.id.should == @course.id
    end
  end

  context "extract_summary" do
    it "should find the right content" do
      @items = @teacher.recent_stream_items
      @items.size.should == 6 # 1 for each type, 1 hidden conversation
      @categorized = helper.categorize_stream_items(@items, @teacher)
      @categorized["Announcement"].first.summary.should == @announcement.title
      @categorized["Conversation"].first.summary.should == @participant.last_message.body
      @categorized["Assignment"].first.summary.should =~ /Assignment Created/
      @categorized["DiscussionTopic"].first.summary.should == @discussion.title
      @categorized["AssessmentRequest"].first.summary.should include(@assignment.title)
    end
  end
end
