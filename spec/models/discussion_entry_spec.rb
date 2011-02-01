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

describe DiscussionEntry do
  
  it "should set parent_id to 0 if invalid or nil" do
    course
    topic = @course.discussion_topics.create!
    entry = topic.discussion_entries.create!
    entry.should_not be_nil
    entry.should_not be_new_record
    entry.parent_id.should eql(0)
    
    topic_2 = @course.discussion_topics.create!
    entry_2 = topic_2.discussion_entries.create!
    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry_2.id
    sub_entry.save!
    sub_entry.parent_id.should eql(0)
  end
  
  it "should only allow one level of nesting" do
    course
    topic = @course.discussion_topics.create!
    entry = topic.discussion_entries.create!
    entry.should_not be_nil
    entry.should_not be_new_record
    entry.parent_id.should eql(0)
    
    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry.id
    sub_entry.save!
    sub_entry.parent_id.should eql(entry.id)
    
    sub_sub_entry = topic.discussion_entries.build
    sub_sub_entry.parent_id = sub_entry.id
    sub_sub_entry.save!
    sub_sub_entry.parent_id.should eql(entry.id)
  end
  
  it "should preserve parent_id if valid" do
    course
    topic = @course.discussion_topics.create!
    entry = topic.discussion_entries.create!
    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry.id
    sub_entry.save!
    sub_entry.should_not be_nil
    sub_entry.parent_id.should eql(entry.id)
  end
  
  it "should santize message" do
    course_model
    topic = @course.discussion_topics.create!
    topic.discussion_entries.create!
    topic.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
    topic.save!
    topic.message.should eql("<a href=\"#\">only this should stay</a>")
  end
  
  context "send_to_inbox" do
    it "should send to inbox" do
      course
      @course.offer
      topic = @course.discussion_topics.create!
      @u = user_model
      entry = topic.discussion_entries.create!(:user => @u)
      @u2 = user_model
      sub_entry = topic.discussion_entries.build
      sub_entry.parent_id = entry.id
      sub_entry.user = @u2
      sub_entry.save!
      sub_entry.inbox_item_recipient_ids.should_not be_nil
      sub_entry.inbox_item_recipient_ids.should_not be_empty
      sub_entry.inbox_item_recipient_ids.should be_include(entry.user_id)
    end
  end
  
  context "clone_for" do
    it "should clone to another context" do
      course
      topic = @course.discussion_topics.create!
      entry = topic.discussion_entries.create!(:message => "some random message")
      course
      new_entry = entry.clone_for(@course)
      new_entry.message.should eql(entry.message)
    end
  end
  
  context "sub-topics" do
    it "should not allow students to edit sub-topic entries of other students" do
      course_with_student(:active_all => true)
      @first_user = @user
      @second_user = user_model
      @course.enroll_student(@second_user).accept
      @parent_topic = @course.discussion_topics.create!(:title => "parent topic", :message => "msg")
      @group = @course.groups.create!(:name => "course group")
      @group.add_user(@first_user)
      @group.add_user(@second_user)
      @group_topic = @group.discussion_topics.create!(:title => "group topic", :message => "ok to be edited", :user => @first_user)
      @group_entry = @group_topic.discussion_entries.create!(:message => "entry", :user => @first_user)
      @sub_topic = @group.discussion_topics.build(:title => "sub topic", :message => "not ok to be edited", :user => @first_user)
      @sub_topic.root_topic_id = @parent_topic.id
      @sub_topic.save!
      @sub_entry = @sub_topic.discussion_entries.create!(:message => "entry", :user => @first_user)
      @group_entry.grants_right?(@first_user, nil, :update).should eql(true)
      @group_entry.grants_right?(@second_user, nil, :update).should eql(true)
      @sub_entry.grants_right?(@first_user, nil, :update).should eql(true)
      @sub_entry.grants_right?(@second_user, nil, :update).should eql(false)
    end
  end
end
