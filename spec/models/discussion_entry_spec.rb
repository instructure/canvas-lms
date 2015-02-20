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

    expect(topic.discussion_entries.active.length).to eq 2
    entry.destroy
    sub_entry.reload
    expect(sub_entry).not_to be_deleted
    expect(topic.discussion_entries.active.length).to eq 1
  end

  it "should preserve parent_id if valid" do
    course
    topic = @course.discussion_topics.create!
    entry = topic.discussion_entries.create!
    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry.id
    sub_entry.save!
    expect(sub_entry).not_to be_nil
    expect(sub_entry.parent_id).to eql(entry.id)
  end

  it "should santize message" do
    course_model
    topic = @course.discussion_topics.create!
    topic.discussion_entries.create!
    topic.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
    topic.save!
    expect(topic.message).to eql("<a href=\"#\">only this should stay</a>")
  end

  context "entry notifications" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @non_posting_student = @student
      student_in_course(:active_all => true)

      @notification_name = "New Discussion Entry"
      n = Notification.create(:name => @notification_name, :category => "TestImmediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @student.communication_channel, :frequency => "immediately")

      n2 = Notification.create(:name => "Announcement Reply", :category => "TestImmediately")
      NotificationPolicy.create(:notification => n2, :communication_channel => @teacher.communication_channel, :frequency => "immediately")
    end

    it "should send them for course discussion topics" do
      topic = @course.discussion_topics.create!(:user => @teacher, :message => "Hi there")
      entry = topic.discussion_entries.create!(:user => @student, :message => "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user).map(&:id)
      expect(to_users).to include(@teacher.id) # teacher is auto-subscribed
      expect(to_users).not_to include(@student.id) # posters are auto-subscribed, but student is not notified of his own post
      expect(to_users).not_to include(@non_posting_student.id)

      entry = topic.discussion_entries.create!(:user => @teacher, :message => "Nice to meet you")
      to_users = entry.messages_sent[@notification_name].map(&:user).map(&:id)
      expect(to_users).not_to include(@teacher.id) # author
      expect(to_users).to include(@student.id)
      expect(to_users).not_to include(@non_posting_student.id)

      topic.subscribe(@non_posting_student)
      entry = topic.discussion_entries.create!(:user => @teacher, :message => "Welcome to the class")
      # now that the non_posting_student is subscribed, he should get notified of posts
      to_users = entry.messages_sent[@notification_name].map(&:user).map(&:id)
      expect(to_users).not_to include(@teacher.id)
      expect(to_users).to include(@student.id)
      expect(to_users).to include(@non_posting_student.id)
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
      # teacher is subscribed but is not in the "participating_users" for this group
      # s1 is the author, s2 is not subscribed
      expect(entry.messages_sent[@notification_name]).to be_blank

      # s1 should be subscribed from posting to the topic
      topic.subscribe(s2)
      entry = topic.discussion_entries.create!(:user => s2, :message => "Hi I'm a student")
      to_users = entry.messages_sent[@notification_name].map(&:user)
      expect(to_users).not_to include(@teacher)
      expect(to_users).to include(s1)
      expect(to_users).not_to include(s2) # s2 not notified of own post
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
      # make sure they all subscribed, somehow
      [teacher, student1, quitter, outsider].each { |user| topic.subscribe(user) }

      entry = topic.discussion_entries.create!(:user => quitter, :message => "Hi, I'm going to drop this class")
      quitter.enrollments.each { |e| e.destroy }

      weird_entry = topic.discussion_entries.create!(:user => outsider, :message => "Hi I'm a student from another class")
      entry = topic.discussion_entries.create!(:user => student1, :message => "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user)
      expect(to_users).to include teacher      # because teacher is subscribed and enrolled
      expect(to_users).not_to include outsider # because they're not in the class
      expect(to_users).not_to include student1 # because they wrote this entry
      expect(to_users).not_to include quitter  # because they dropped the class
    end

    it "should send relevent notifications on announcements" do
      topic = @course.announcements.create!(:user => @teacher, :message => "This is an important announcement")
      topic.subscribe(@student)
      entry = topic.discussion_entries.create!(:user => @teacher, :message => "Oh, and another thing...")
      expect(entry.messages_sent[@notification_name]).to be_blank
      expect(entry.messages_sent["Announcement Reply"]).not_to be_blank
    end

  end

  context "send_to_inbox" do
    it "should send to inbox" do
      course
      @course.offer
      topic = @course.discussion_topics.create!(:title => "abc " * 63 + "abc")
      expect(topic.title.length).to eq 255
      @u = user_model
      entry = topic.discussion_entries.create!(:user => @u)
      @u2 = user_model
      sub_entry = topic.discussion_entries.build
      sub_entry.parent_id = entry.id
      sub_entry.user = @u2
      sub_entry.save!
      expect(sub_entry.inbox_item_recipient_ids).not_to be_nil
      expect(sub_entry.inbox_item_recipient_ids).not_to be_empty
      expect(sub_entry.inbox_item_recipient_ids).to be_include(entry.user_id)
      item = InboxItem.last
      expect(item.subject.length).to be <= 255
      expect(item.subject).to match /abc /
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
      expect(@group_entry.grants_right?(@first_user, :update)).to eql(true)
      expect(@group_entry.grants_right?(@second_user, :update)).to eql(false)
      expect(@sub_entry.grants_right?(@first_user, :update)).to eql(true)
      expect(@sub_entry.grants_right?(@second_user, :update)).to eql(false)
    end
  end

  context "update_topic" do
    before :once do
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
      expect(@topic.updated_at).not_to eq @original_updated_at
    end

    it "should set last_reply_at on the associated discussion_topic given a newer entry" do
      @new_last_reply_at = @entry.created_at = @original_last_reply_at + 5.minutes
      @entry.save

      @entry.update_topic
      @topic.reload
      expect(@topic.last_reply_at).to eq @new_last_reply_at
    end

    it "should leave last_reply_at on the associated discussion_topic alone given an older entry" do
      @new_last_reply_at = @entry.created_at = @original_last_reply_at - 5.minutes
      @entry.save

      @entry.update_topic
      @topic.reload
      expect(@topic.last_reply_at).to eq @original_last_reply_at
    end
  end

  context "deleting entry" do
    before :once do
      course_with_student(:active_all => true)
      @author = @user
      @reader = user()
      @course.enroll_student(@author)
      @course.enroll_student(@reader)

      @topic = @course.discussion_topics.create!(:title => "title", :message => "message")

      # Create 4 entries, first 2 are 'read' by reader.
      @entry_1 = @topic.discussion_entries.create!(:message => "entry 1", :user => @author)
      @entry_1.change_read_state('read', @reader)
      @entry_2 = @topic.discussion_entries.create!(:message => "entry 2", :user => @author)
      @entry_2.change_read_state('read', @reader)
      @entry_3 = @topic.discussion_entries.create!(:message => "entry 3", :user => @author)
      @entry_4 = @topic.discussion_entries.create!(:message => "entry 4", :user => @author)
    end

    describe "#destroy" do
      it "should call decrement_unread_counts_for_this_entry" do
        @entry_4.expects(:decrement_unread_counts_for_this_entry)
        @entry_4.destroy
      end
    end

    it "should decrement unread topic counts" do
      expect(@topic.unread_count(@reader)).to eq 2

      # delete one read and one unread entry and check again
      @entry_1.destroy
      @entry_4.destroy
      expect(@topic.unread_count(@reader)).to eq 1
      # delete remaining unread
      @entry_3.destroy
      expect(@topic.unread_count(@reader)).to eq 0
      # delete final 'read' entry
      @entry_2.destroy
      expect(@topic.unread_count(@reader)).to eq 0
    end
  end

  it "should touch all parent discussion_topics through root_topic_id, on update" do
    course_with_student(:active_all => true)
    @topic = @course.discussion_topics.create!(:title => "title", :message => "message")
    @subtopic = @course.discussion_topics.create!(:title => "subtopic")
    @subtopic.root_topic = @topic
    @subtopic.save!

    DiscussionTopic.where(:id => [@topic, @subtopic]).update_all(:updated_at => 1.hour.ago)
    @topic_updated_at = @topic.reload.updated_at
    @subtopic_updated_at = @subtopic.reload.updated_at

    @subtopic_entry = @subtopic.discussion_entries.create!(:message => "hello", :user => @user)

    expect(@subtopic_updated_at.to_i).not_to eq @subtopic.reload.updated_at.to_i
    expect(@topic_updated_at.to_i).not_to eq @topic.reload.updated_at.to_i
  end

  context "read/unread state" do
    before(:once) do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher)
      @entry = @topic.discussion_entries.create!(:message => "entry", :user => @teacher)
    end

    it "should mark a entry you created as read" do
      expect(@entry.read?(@teacher)).to be_truthy
      expect(@topic.unread_count(@teacher)).to eq 0
    end

    it "should be unread by default" do
      expect(@entry.read?(@student)).to be_falsey
      expect(@topic.unread_count(@student)).to eq 1
    end

    it "should allow being marked unread" do
      @entry.change_read_state("unread", @teacher)
      expect(@entry.read?(@teacher)).to be_falsey
      expect(@topic.unread_count(@teacher)).to eq 1
    end

    it "should allow being marked read" do
      @entry.change_read_state("read", @student)
      expect(@entry.read?(@student)).to be_truthy
      expect(@topic.unread_count(@student)).to eq 0
    end

    it "should update counts for an entry without a user" do
      @other_entry = @topic.discussion_entries.create!(:message => "no user entry")
      expect(@topic.unread_count(@teacher)).to eq 1
      expect(@topic.unread_count(@student)).to eq 2
    end

    it "should allow a complex series of read/unread updates" do
      @s1 = @student
      student_in_course(:active_all => true); @s2 = @student
      student_in_course(:active_all => true); @s3 = @student

      @topic.change_read_state("read", @s1)
      @entry.change_read_state("read", @s1)
      @s1entry = @topic.discussion_entries.create!(:message => "s1 entry", :user => @s1)
      expect(@topic.unread_count(@s1)).to eq 0

      @entry.change_read_state("read", @s2)
      expect(@topic.discussion_topic_participants.where(user_id: @s2).first).not_to be_nil
      @topic.change_read_state("read", @s2)
      @s2entry = @topic.discussion_entries.create!(:message => "s2 entry", :user => @s2)
      @s1entry.change_read_state("read", @s2)
      @s1entry.change_read_state("unread", @s2)
      expect(@topic.unread_count(@s2)).to eq 1

      expect(@topic.unread_count(@s3)).to eq 3
      @entry.change_read_state("read", @s3)
      @s3reply = @entry.discussion_subentries.create!(:discussion_topic => @topic, :message => "s3 reply", :user => @s3)
      expect(@topic.unread_count(@s3)).to eq 2

      expect(@topic.unread_count(@s1)).to eq 2
      expect(@topic.unread_count(@s2)).to eq 2
      expect(@topic.unread_count(@teacher)).to eq 3

      @topic.change_all_read_state("read", @s1)
      expect(@topic.unread_count(@s1)).to eq 0
      expect(@topic.read?(@s1)).to be_truthy
      expect(@entry.read?(@s1)).to be_truthy

      @topic.change_all_read_state("unread", @s2)
      expect(@topic.unread_count(@s2)).to eq 4
      expect(@topic.read?(@s2)).to be_falsey
      expect(@entry.read?(@s2)).to be_falsey

      student_in_course(:active_all => true); @s4 = @student
      expect(@topic.unread_count(@s4)).to eq 4
      @topic.change_all_read_state("unread", @s4)
      expect(@topic.read?(@s4)).to be_falsey
      expect(@entry.read?(@s4)).to be_falsey

      student_in_course(:active_all => true); @s5 = @student
      @topic.change_all_read_state("read", @s5)
      expect(@topic.unread_count(@s5)).to eq 0
    end

    it "should use unique_constaint_retry when updating read state" do
      DiscussionEntry.expects(:unique_constraint_retry).once
      @entry.change_read_state("read", @student)
    end
  end

  context "threaded discussions" do
    before :once do
      course_with_teacher
    end

    it "should force a root entry as parent if the discussion isn't threaded" do
      discussion_topic_model
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      sub1 = root.reply_from(:user => @teacher, :html => "sub entry")
      expect(sub1.parent_entry).to eq root
      expect(sub1.root_entry).to eq root
      sub2 = sub1.reply_from(:user => @teacher, :html => "sub-sub entry")
      expect(sub2.parent_entry).to eq root
      expect(sub2.root_entry).to eq root
    end

    it "should allow a sub-entry as parent if the discussion is threaded" do
      discussion_topic_model(:threaded => true)
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      sub1 = root.reply_from(:user => @teacher, :html => "sub entry")
      expect(sub1.parent_entry).to eq root
      expect(sub1.root_entry).to eq root
      sub2 = sub1.reply_from(:user => @teacher, :html => "sub-sub entry")
      expect(sub2.parent_entry).to eq sub1
      expect(sub2.root_entry).to eq root
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
      expect(sub1.reload.parent_entry).to be_nil
    end
  end

  describe "DiscussionEntryParticipant" do
    before :once do
      topic_with_nested_replies
    end

    context ".read_entry_ids" do
      it "should return the ids of the read entries" do
        @root2.change_read_state('read', @teacher)
        @reply_reply1.change_read_state('read', @teacher)
        @reply_reply2.change_read_state('read', @teacher)
        @reply3.change_read_state('read', @teacher)
        # change one back to unread, it shouldn't be returned
        @reply_reply2.change_read_state('unread', @teacher)
        read = DiscussionEntryParticipant.read_entry_ids(@topic.discussion_entries.map(&:id), @teacher).sort
        expect(read).to eq [@root2, @reply1, @reply2, @reply_reply1, @reply3].map(&:id)
      end
    end

    context ".forced_read_state_entry_ids" do
      it "should return the ids of entries that have been marked as force_read_state" do
        marked_entries = [@root2, @reply_reply1, @reply_reply2, @reply3]
        marked_entries.each do |e|
          e.change_read_state('read', @teacher, :forced => true)
        end
        # change back, without :forced parameter, should stay forced
        @reply_reply2.change_read_state('unread', @teacher)
        # change forced to false so it shouldn't be in results
        @reply3.change_read_state('unread', @teacher, :forced => false)
        marked_entries -= [@reply3]

        forced = DiscussionEntryParticipant.forced_read_state_entry_ids(@all_entries.map(&:id), @teacher).sort
        expect(forced).to eq marked_entries.map(&:id).sort
      end
    end

    context ".find_existing_participant" do
      it "should return existing data" do
        @root2.change_read_state('read', @teacher, :forced => true)
        participant = @root2.find_existing_participant(@teacher)
        expect(participant.id).not_to be_nil
        expect(participant).to be_readonly
        expect(participant.user).to eq @teacher
        expect(participant.discussion_entry).to eq @root2
        expect(participant.workflow_state).to eq 'read'
        expect(participant.forced_read_state).to be_truthy
      end

      it "should return default data" do
        participant = @reply2.find_existing_participant(@student)
        expect(participant.id).to be_nil
        expect(participant).to be_readonly
        expect(participant.user).to eq @student
        expect(participant.discussion_entry).to eq @reply2
        expect(participant.workflow_state).to eq 'unread'
        expect(participant.forced_read_state).to be_falsey
      end
    end

  end

  describe "reply_from" do
    before :once do
      course_with_teacher
      discussion_topic_model
    end

    it "should ignore replies in deleted accounts" do
      root = @topic.reply_from(:user => @teacher, :text => "root entry")
      Account.default.destroy
      root.reload
      expect { root.reply_from(:user => @teacher, :text => "sub entry") }.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "should prefer html to text" do
      @entry = @topic.reply_from(:user => @teacher, :text => "topic")
      msg = @entry.reply_from(:user => @teacher, :text => "text body", :html => "<p>html body</p>")
      expect(msg).not_to be_nil
      expect(msg.message).to eq "<p>html body</p>"
    end

    it "should not allow students to reply to locked topics" do
      @entry = @topic.reply_from(:user => @teacher, :text => "topic")
      @topic.lock!
      @entry.reply_from(:user => @teacher, :text => "reply") # should not raise error
      student_in_course(:course => @course)
      expect { @entry.reply_from(:user => @student, :text => "reply") }.to raise_error(IncomingMail::Errors::ReplyToLockedTopic)
    end

    it "should not allow replies from students to topics locked based on date" do
      @entry = @topic.reply_from(:user => @teacher, :text => "topic")
      @topic.unlock_at = 1.day.from_now
      @topic.save!
      @entry.reply_from(:user => @teacher, :text => "reply") # should not raise error
      student_in_course(:course => @course)
      expect { @entry.reply_from(:user => @student, :text => "reply") }.to raise_error(IncomingMail::Errors::ReplyToLockedTopic)
    end
  end
end
