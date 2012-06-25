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

  it "should not be marked as deleted when parent is deleted" do
    topic = course.discussion_topics.create!
    entry = topic.discussion_entries.create!

    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry.id
    sub_entry.save!

    topic.discussion_entries.active.length.should == 2
    entry.destroy
    sub_entry.reload
    sub_entry.should_not be_deleted
    topic.discussion_entries.active.length.should == 1
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

  context "entry notifications" do
    before do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)

      @notification_name = "New Discussion Entry"
      n = Notification.create(:name => @notification_name, :category => "TestImmediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @student.communication_channel, :frequency => "immediately")
    end

    it "should send them for course discussion topics" do
      topic = @course.discussion_topics.create!(:user => @teacher, :message => "Hi there")
      entry = topic.discussion_entries.create!(:user => @student, :message => "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user)
      to_users.should include(@teacher)
      to_users.should_not include(@student)

      entry = topic.discussion_entries.create!(:user => @teacher, :message => "Nice to meet you")
      to_users = entry.messages_sent[@notification_name].map(&:user)
      to_users.should_not include(@teacher)
      to_users.should include(@student)
    end

    it "should send them for group discussion topics" do
      group(:group_context => @course)

      s1 = @student
      student_in_course(:active_user => true)
      s2 = @student

      @group.participating_users << s1
      @group.participating_users << s2
      @group.save!

      topic = @group.discussion_topics.create!(:user => @teacher, :message => "Hi there")
      entry = topic.discussion_entries.create!(:user => s1, :message => "Hi I'm a student")
      entry.messages_sent[@notification_name].should be_blank

      entry = topic.discussion_entries.create!(:user => s2, :message => "Hi I'm a student")
      to_users = entry.messages_sent[@notification_name].map(&:user)
      to_users.should_not include(@teacher)
      to_users.should include(s1)
      to_users.should_not include(s2)
    end

    it "should not send them to irrelevant users" do
      teacher  = @teacher
      student1 = @student
      course   = @course

      student_in_course
      quitter  = @student

      course_with_teacher
      student_in_course
      outsider = @student

      topic = course.discussion_topics.create!(:user => teacher, :message => "Hi there")

      entry = topic.discussion_entries.create!(:user => quitter, :message => "Hi, I'm going to drop this class")
      quitter.enrollments.each { |e| e.destroy }

      weird_entry = topic.discussion_entries.create!(:user => outsider, :message => "Hi I'm a student from another class")
      entry = topic.discussion_entries.create!(:user => student1, :message => "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user)
      to_users.should include teacher
      to_users.should_not include outsider
      to_users.should_not include student1
      to_users.should_not include quitter
    end
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
      @group_entry.grants_right?(@second_user, nil, :update).should eql(false)
      @sub_entry.grants_right?(@first_user, nil, :update).should eql(true)
      @sub_entry.grants_right?(@second_user, nil, :update).should eql(false)
    end
  end

  context "update_topic" do
    before :each do
      course_with_student(:active_all => true)
      @course.enroll_student(@user).accept
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message")

      # get rid of stupid milliseconds, since mysql won't preserve them
      @original_updated_at = @topic.updated_at = Time.zone.at(1.minute.ago.to_i)
      @original_last_reply_at = @topic.last_reply_at = Time.zone.at(2.minutes.ago.to_i)
      @topic.save

      @entry = @topic.discussion_entries.create!(:message => "entry", :user => @user)
    end

    it "should tickle updated_at on the associated discussion_topic" do
      @entry.update_topic
      @topic.reload
      @topic.updated_at.should_not == @original_updated_at
    end

    it "should set last_reply_at on the associated discussion_topic given a newer entry" do
      @new_last_reply_at = @entry.created_at = @original_last_reply_at + 5.minutes
      @entry.save

      @entry.update_topic
      @topic.reload
      @topic.last_reply_at.should == @new_last_reply_at
    end

    it "should leave last_reply_at on the associated discussion_topic alone given an older entry" do
      @new_last_reply_at = @entry.created_at = @original_last_reply_at - 5.minutes
      @entry.save

      @entry.update_topic
      @topic.reload
      @topic.last_reply_at.should == @original_last_reply_at
    end
  end

  it "should touch all parent discussion_topics through root_topic_id, on update" do
    course_with_student(:active_all => true)
    @topic = @course.discussion_topics.create!(:title => "title", :message => "message")
    @subtopic = @course.discussion_topics.create!(:title => "subtopic")
    @subtopic.root_topic = @topic
    @subtopic.save!

    DiscussionTopic.update_all({ :updated_at => 1.hour.ago }, { :id => [@topic.id, @subtopic.id] })
    @topic_updated_at = @topic.reload.updated_at
    @subtopic_updated_at = @subtopic.reload.updated_at

    @subtopic_entry = @subtopic.discussion_entries.create!(:message => "hello", :user => @user)

    @subtopic_updated_at.to_i.should_not == @subtopic.reload.updated_at.to_i
    @topic_updated_at.to_i.should_not == @topic.reload.updated_at.to_i
  end

  context "read/unread state" do
    before(:each) do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher)
      @entry = @topic.discussion_entries.create!(:message => "entry", :user => @teacher)
    end

    it "should mark a entry you created as read" do
      @entry.read?(@teacher).should be_true
      @topic.unread_count(@teacher).should == 0
    end

    it "should be unread by default" do
      @entry.read?(@student).should be_false
      @topic.unread_count(@student).should == 1
    end

    it "should allow being marked unread" do
      @entry.change_read_state("unread", @teacher)
      @entry.read?(@teacher).should be_false
      @topic.unread_count(@teacher).should == 1
    end

    it "should allow being marked read" do
      @entry.change_read_state("read", @student)
      @entry.read?(@student).should be_true
      @topic.unread_count(@student).should == 0
    end

    it "should update counts for an entry without a user" do
      @other_entry = @topic.discussion_entries.create!(:message => "no user entry")
      @topic.unread_count(@teacher).should == 1
      @topic.unread_count(@student).should == 2
    end

    it "should allow a complex series of read/unread updates" do
      @s1 = @student
      student_in_course(:active_all => true); @s2 = @student
      student_in_course(:active_all => true); @s3 = @student

      @topic.change_read_state("read", @s1)
      @entry.change_read_state("read", @s1)
      @s1entry = @topic.discussion_entries.create!(:message => "s1 entry", :user => @s1)
      @topic.unread_count(@s1).should == 0

      @entry.change_read_state("read", @s2)
      @topic.discussion_topic_participants.find_by_user_id(@s2.id).should_not be_nil
      @topic.change_read_state("read", @s2)
      @s2entry = @topic.discussion_entries.create!(:message => "s2 entry", :user => @s2)
      @s1entry.change_read_state("read", @s2)
      @s1entry.change_read_state("unread", @s2)
      @topic.unread_count(@s2).should == 1

      @topic.unread_count(@s3).should == 3
      @entry.change_read_state("read", @s3)
      @s3reply = @entry.discussion_subentries.create!(:discussion_topic => @topic, :message => "s3 reply", :user => @s3)
      @topic.unread_count(@s3).should == 2

      @topic.unread_count(@s1).should == 2
      @topic.unread_count(@s2).should == 2
      @topic.unread_count(@teacher).should == 3

      @topic.change_all_read_state("read", @s1)
      @topic.unread_count(@s1).should == 0
      @topic.read?(@s1).should be_true
      @entry.read?(@s1).should be_true

      @topic.change_all_read_state("unread", @s2)
      @topic.unread_count(@s2).should == 4
      @topic.read?(@s2).should be_false
      @entry.read?(@s2).should be_false

      student_in_course(:active_all => true); @s4 = @student
      @topic.unread_count(@s4).should == 4
      @topic.change_all_read_state("unread", @s4)
      @topic.read?(@s4).should be_false
      @entry.read?(@s4).should be_false

      student_in_course(:active_all => true); @s5 = @student
      @topic.change_all_read_state("read", @s5)
      @topic.unread_count(@s5).should == 0
    end

    it "should use unique_constaint_retry when updating read state" do
      DiscussionEntry.expects(:unique_constraint_retry).once
      @entry.change_read_state("read", @student)
    end
  end

  context "threaded discussions" do
    it "should force a root entry as parent if the discussion isn't threaded" do
      course_with_teacher
      discussion_topic_model
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      sub1 = root.reply_from(:user => @teacher, :html => "sub entry")
      sub1.parent_entry.should == root
      sub1.root_entry.should == root
      sub2 = sub1.reply_from(:user => @teacher, :html => "sub-sub entry")
      sub2.parent_entry.should == root
      sub2.root_entry.should == root
    end

    it "should allow a sub-entry as parent if the discussion is threaded" do
      course_with_teacher
      discussion_topic_model(:threaded => true)
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      sub1 = root.reply_from(:user => @teacher, :html => "sub entry")
      sub1.parent_entry.should == root
      sub1.root_entry.should == root
      sub2 = sub1.reply_from(:user => @teacher, :html => "sub-sub entry")
      sub2.parent_entry.should == sub1
      sub2.root_entry.should == root
    end
  end

  context "Flat discussions" do
    it "should not have a parent entry if the discussion is flat" do
      course_with_teacher
      discussion_topic_model
      @topic.discussion_type = DiscussionTopic::DiscussionTypes::FLAT
      @topic.save!
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      sub1 = root.reply_from(:user => @teacher, :html => "shouldn't really be a subentry")
      sub1.reload.parent_entry.should be_nil
    end
  end

  context "DiscussionEntryParticipant.read_entry_ids" do
    it "should return the ids of the read entries" do
      topic_with_nested_replies
      @root2.change_read_state('read', @teacher)
      @reply_reply1.change_read_state('read', @teacher)
      @reply_reply2.change_read_state('read', @teacher)
      @reply3.change_read_state('read', @teacher)
      # change one back to unread, it shouldn't be returned
      @reply_reply2.change_read_state('unread', @teacher)
      read = DiscussionEntryParticipant.read_entry_ids(@topic.discussion_entries.map(&:id), @teacher).sort
      read.should == [@root2, @reply1, @reply2, @reply_reply1, @reply3].map(&:id)
    end
  end
end
