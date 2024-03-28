# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe DiscussionEntry do
  let(:topic) { discussion_topic_model }
  let(:anonymous_topic) { discussion_topic_model(anonymous_state: "full_anonymity") }
  let(:partially_anonymous_topic) { discussion_topic_model(anonymous_state: "partial_anonymity") }

  describe "callback lifecycle" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    let(:entry) do
      topic.discussion_entries.create!(user: @teacher)
    end

    it "subscribes the author on create" do
      discussion_topic_participant = topic.discussion_topic_participants.create!(user: @teacher, subscribed: false)
      entry
      expect(discussion_topic_participant.reload.subscribed).to be_truthy
    end

    it "sets the root_account_id using topic" do
      expect(entry.root_account_id).to eq topic.root_account_id
    end
  end

  it "is not marked as deleted when parent is deleted" do
    course_with_teacher(active_all: true)
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

  it "preserves parent_id if valid" do
    course_factory
    entry = topic.discussion_entries.create!
    sub_entry = topic.discussion_entries.build
    sub_entry.parent_id = entry.id
    sub_entry.save!
    expect(sub_entry).not_to be_nil
    expect(sub_entry.parent_id).to eql(entry.id)
  end

  it "santizes message" do
    course_model
    topic.discussion_entries.create!
    topic.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
    topic.save!
    expect(topic.message).to eql("<a href=\"#\">only this should stay</a>")
  end

  it "does not allow viewing when in an announcement without :read_announcements" do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course.account.role_overrides.create!(permission: "read_announcements", role: student_role, enabled: false)
    # because :post_to_forum implies :read in about half of discussions, and this is one such place
    @course.account.role_overrides.create!(permission: "post_to_forum", role: student_role, enabled: false)

    topic = @course.announcements.create!(user: @teacher, message: "announcement text")
    entry = topic.discussion_entries.create!(user: @teacher, message: "reply text")

    expect(entry.grants_right?(@student, :read)).to be(false)
  end

  context "mentions" do
    before :once do
      course_with_teacher(active_all: true)
    end

    before do
      allow(InstStatsd::Statsd).to receive(:increment)
    end

    let(:student) { student_in_course(active_all: true).user }
    let(:mentioned_student) { student_in_course(active_all: true).user }

    it "creates on entry save" do
      entry = topic.discussion_entries.new(user: student)
      allow(entry).to receive(:message).and_return("<p>hello <span class='mceNonEditable mention' data-mention=#{mentioned_student.id}>@#{mentioned_student.short_name}</span> what's up dude</p>")
      expect { entry.save! }.to change { entry.mentions.count }.from(0).to(1)
      expect(entry.mentions.take.user_id).to eq mentioned_student.id
      expect(entry.mentioned_users.count).to eq 1
      expect(InstStatsd::Statsd).to have_received(:increment).with("discussion_entry.created").at_least(:once)
    end

    describe "edits to an entry" do
      let!(:entry) do
        topic.discussion_entries.create(
          user: student,
          message: "<p>hello <span data-mention=#{mentioned_student.id} class=mention>@#{mentioned_student.short_name}</span> what's up dude</p>"
        )
      end

      context "a new user is mentioned" do
        it "creates a mention on save" do
          expect do
            entry.update(message: "<p>hello <span data-mention=#{student.id} class=mention>@#{mentioned_student.short_name}</span> what's up dude</p>")
          end.to change { entry.mentions.count }.by 1
        end
      end

      context "the same user is mentioned" do
        it "does not create a new mention on save" do
          expect do
            entry.update(message: "<p>hello <span data-mention=#{mentioned_student.id} class=mention>@#{mentioned_student.short_name}</span> what's up dude?!</p>")
          end.to not_change { entry.mentions.count }
        end
      end
    end
  end

  context "entry notifications" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @non_posting_student = @student
      student_in_course(active_all: true)

      @notification_mention = "Discussion Mention"
      n = Notification.create(name: @notification_mention, category: "TestImmediately")
      NotificationPolicy.create(notification: n, communication_channel: @student.communication_channel, frequency: "immediately")

      @notification_name = "New Discussion Entry"
      n = Notification.create(name: @notification_name, category: "TestImmediately")
      NotificationPolicy.create(notification: n, communication_channel: @student.communication_channel, frequency: "immediately")

      n2 = Notification.create(name: "Announcement Reply", category: "TestImmediately")
      NotificationPolicy.create(notification: n2, communication_channel: @teacher.communication_channel, frequency: "immediately")

      @notification_reported_entry = "Reported Reply"
      n = Notification.create(name: @notification_reported_entry, category: "TestImmediately")
      NotificationPolicy.create(notification: n, communication_channel: @teacher.communication_channel, frequency: "immediately")
    end

    it "sends them for course discussion topics" do
      topic = @course.discussion_topics.create!(user: @teacher, message: "Hi there")
      entry = topic.discussion_entries.create!(user: @student, message: "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user_id)
      expect(to_users).to include(@teacher.id) # teacher is auto-subscribed
      expect(to_users).not_to include(@student.id) # posters are auto-subscribed, but student is not notified of his own post
      expect(to_users).not_to include(@non_posting_student.id)

      entry = topic.discussion_entries.create!(user: @teacher, message: "Nice to meet you")
      to_users = entry.messages_sent[@notification_name].map(&:user_id)
      expect(to_users).not_to include(@teacher.id) # author
      expect(to_users).to include(@student.id)
      expect(to_users).not_to include(@non_posting_student.id)

      topic.subscribe(@non_posting_student)
      entry = topic.discussion_entries.create!(user: @teacher, message: "Welcome to the class")
      # now that the non_posting_student is subscribed, he should get notified of posts
      to_users = entry.messages_sent[@notification_name].map(&:user_id)
      expect(to_users).not_to include(@teacher.id)
      expect(to_users).to include(@student.id)
      expect(to_users).to include(@non_posting_student.id)
    end

    it "sends them for group discussion topics" do
      group(group_context: @course)

      s1 = @student
      student_in_course(active_user: true)
      s2 = @student

      @group.participating_users << s1
      @group.participating_users << s2
      @group.save!

      topic = @group.discussion_topics.create!(user: @teacher, message: "Hi there")
      entry = topic.discussion_entries.create!(user: s1, message: "Hi I'm a student")
      # teacher is subscribed but is not in the "participating_users" for this group
      # s1 is the author, s2 is not subscribed
      expect(entry.messages_sent[@notification_name]).to be_blank

      # s1 should be subscribed from posting to the topic
      topic.subscribe(s2)
      entry = topic.discussion_entries.create!(user: s2, message: "Hi I'm a student")
      to_users = entry.messages_sent[@notification_name].map(&:user)
      expect(to_users).not_to include(@teacher)
      expect(to_users).to include(s1)
      expect(to_users).not_to include(s2) # s2 not notified of own post
    end

    it "does not send them to irrelevant users" do
      teacher  = @teacher
      student1 = @student
      course   = @course

      student_in_course
      quitter = @student

      course_with_teacher
      student_in_course
      outsider = @student

      topic = course.discussion_topics.create!(user: teacher, message: "Hi there")
      # make sure they all subscribed, somehow
      [teacher, student1, quitter, outsider].each { |user| topic.subscribe(user) }

      topic.discussion_entries.create!(user: quitter, message: "Hi, I'm going to drop this class")
      quitter.enrollments.each(&:destroy)

      topic.discussion_entries.create!(user: outsider, message: "Hi I'm a student from another class")
      entry = topic.discussion_entries.create!(user: student1, message: "Hi I'm a student")

      to_users = entry.messages_sent[@notification_name].map(&:user)
      expect(to_users).to include teacher      # because teacher is subscribed and enrolled
      expect(to_users).not_to include outsider # because they're not in the class
      expect(to_users).not_to include student1 # because they wrote this entry
      expect(to_users).not_to include quitter  # because they dropped the class
    end

    it "sends relevent notifications on announcements" do
      topic = @course.announcements.create!(user: @teacher, message: "This is an important announcement")
      topic.subscribe(@student)
      entry = topic.discussion_entries.create!(user: @teacher, message: "Oh, and another thing...")
      expect(entry.messages_sent[@notification_name]).to be_blank
      expect(entry.messages_sent["Announcement Reply"]).not_to be_blank
    end

    it "sends one notification to mentioned users" do
      topic = @course.discussion_topics.create!(user: @teacher, message: "This is an important announcement")
      topic.subscribe(@student)
      entry = topic.discussion_entries.new(user: @teacher, message: "Oh, and another thing...")
      mention = entry.mentions.new(user: @student, root_account_id: @course.root_account_id)
      entry.save! # also saves the mention.
      expect(mention.messages_sent[@notification_name]).to be_blank
      expect(mention.messages_sent[@notification_mention]).not_to be_blank
      expect(mention.messages_sent["Announcement Reply"]).to be_blank
    end

    it "sends notification to teacher when a reply is reported" do
      @course.enable_feature!(:react_discussions_post)
      topic = @course.discussion_topics.create!(user: @teacher, message: "This is an important announcement")
      topic.subscribe(@student)
      entry = topic.discussion_entries.create!(user: @teacher, message: "Oh, and another thing...")
      expect(BroadcastPolicy.notifier).to receive(:send_notification).once
      entry.broadcast_report_notification("hello I have been reported")
    end
  end

  context "sub-topics" do
    it "does not allow students to edit sub-topic entries of other students" do
      course_with_student(active_all: true)
      @first_user = @user
      @second_user = user_model
      @course.enroll_student(@second_user).accept
      @parent_topic = @course.discussion_topics.create!(title: "parent topic", message: "msg")
      @group = @course.groups.create!(name: "course group")
      @group.add_user(@first_user)
      @group.add_user(@second_user)
      @group_topic = @group.discussion_topics.create!(title: "group topic", message: "ok to be edited", user: @first_user)
      @group_entry = @group_topic.discussion_entries.create!(message: "entry", user: @first_user)
      @sub_topic = @group.discussion_topics.build(title: "sub topic", message: "not ok to be edited", user: @first_user)
      @sub_topic.root_topic_id = @parent_topic.id
      @sub_topic.save!
      @sub_entry = @sub_topic.discussion_entries.create!(message: "entry", user: @first_user)
      expect(@group_entry.grants_right?(@first_user, :update)).to be(true)
      expect(@group_entry.grants_right?(@second_user, :update)).to be(false)
      expect(@sub_entry.grants_right?(@first_user, :update)).to be(true)
      expect(@sub_entry.grants_right?(@second_user, :update)).to be(false)
    end
  end

  context "update_topic" do
    before :once do
      course_with_student(active_all: true)
      @course.enroll_student(@user).accept
      @topic = @course.discussion_topics.create!(title: "title", message: "message")

      # get rid of stupid milliseconds, since mysql won't preserve them
      @original_updated_at = @topic.updated_at = Time.zone.at(1.minute.ago.to_i)
      @original_last_reply_at = @topic.last_reply_at = Time.zone.at(2.minutes.ago.to_i)
      @topic.save

      @entry = @topic.discussion_entries.create!(message: "entry", user: @user)
    end

    it "tickles updated_at on the associated discussion_topic" do
      @entry.update_topic
      @topic.reload
      expect(@topic.updated_at).not_to eq @original_updated_at
    end

    it "sets last_reply_at on the associated discussion_topic given a newer entry" do
      @new_last_reply_at = @entry.created_at = @original_last_reply_at + 5.minutes
      @entry.save

      @entry.update_topic
      @topic.reload
      expect(@topic.last_reply_at).to eq @new_last_reply_at
    end

    it "does not update last_reply_at on the associated discussion_topic if less than a minute" do
      fresh_topic = @course.discussion_topics.create!(title: "title", message: "fresh")
      initial_last_reply_at = fresh_topic.last_reply_at

      entry = fresh_topic.discussion_entries.create!(message: "entry", user: @user)
      entry.created_at = initial_last_reply_at + 30.seconds
      entry.update_topic
      fresh_topic.reload
      expect(fresh_topic.last_reply_at).to eq initial_last_reply_at
    end

    it "leaves last_reply_at on the associated discussion_topic alone given an older entry" do
      fresh_topic = @course.discussion_topics.create!(title: "title", message: "fresh")
      initial_last_reply_at = fresh_topic.last_reply_at

      entry = fresh_topic.discussion_entries.create!(message: "entry", user: @user)
      entry.created_at = initial_last_reply_at - 5.minutes
      entry.update_topic
      fresh_topic.reload
      expect(fresh_topic.last_reply_at).to eq initial_last_reply_at
    end

    it "for migrated discussions, last_reply_at starts at nill but updates at update_topic" do
      @topic.saved_by = :migration
      @topic.last_reply_at = nil
      @topic.save!
      expect(@topic.last_reply_at).to be_nil

      @entry.update_topic
      @topic.reload
      expect(@topic.last_reply_at).to be >= @topic.created_at
    end
  end

  context "deleting entry" do
    before :once do
      course_with_student(active_all: true)
      @author = @user
      @reader = user_factory
      @course.enroll_student(@author)
      @course.enroll_student(@reader)

      @topic = @course.discussion_topics.create!(title: "title", message: "message")

      # Create 4 entries, first 2 are 'read' by reader.
      @entry_1 = @topic.discussion_entries.create!(message: "entry 1", user: @author)
      @entry_1.change_read_state("read", @reader)
      @entry_2 = @topic.discussion_entries.create!(message: "entry 2", user: @author)
      @entry_2.change_read_state("read", @reader)
      @entry_3 = @topic.discussion_entries.create!(message: "entry 3", user: @author)
      @entry_4 = @topic.discussion_entries.create!(message: "entry 4", user: @author)
    end

    describe "#destroy" do
      it "calls decrement_unread_counts_for_this_entry" do
        expect(@entry_4).to receive(:decrement_unread_counts_for_this_entry)
        @entry_4.destroy
      end
    end

    it "allows teacher entry on assignment topic to be destroyed" do
      assignment = @course.assignments.create!(title: @topic.title, submission_types: "discussion_topic")
      topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, assignment:)
      entry = topic.discussion_entries.create!(message: "entry", user: @teacher)
      expect { entry.destroy }.to_not raise_error
    end

    it "decrements unread topic counts" do
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

  it "touches all parent discussion_topics through root_topic_id, on update" do
    course_with_student(active_all: true)
    @topic = @course.discussion_topics.create!(title: "title", message: "message")
    @subtopic = @course.discussion_topics.create!(title: "subtopic")
    @subtopic.root_topic = @topic
    @subtopic.save!

    DiscussionTopic.where(id: [@topic, @subtopic]).update_all(updated_at: 1.hour.ago)
    @topic_updated_at = @topic.reload.updated_at
    @subtopic_updated_at = @subtopic.reload.updated_at

    @subtopic_entry = @subtopic.discussion_entries.create!(message: "hello", user: @user)

    expect(@subtopic_updated_at.to_i).not_to eq @subtopic.reload.updated_at.to_i
    expect(@topic_updated_at.to_i).not_to eq @topic.reload.updated_at.to_i
  end

  describe ".unread_for_user_before(user, read_at)" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher)
    end

    it "returns all unread entries for user or entries unread before the given time" do
      # it returns entries read after the given time, but
      # it should be interpreted as, entries that were unread before the given time.

      # scenario: you visit a page for unread entries;
      # as you scroll the page you read entries at (later times, then you go to next page and entries are now read AFTER your initial QUERY time.

      Timecop.freeze(Time.utc(2013, 3, 13, 9, 12)) do
        @entry1 = @topic.discussion_entries.create!(message: "entry 1 outside", user: @teacher)
        @entry1.change_read_state("read", @student)
      end

      Timecop.freeze(Time.utc(2013, 3, 13, 10, 12)) do
        @entry2 = @topic.discussion_entries.create!(message: "entry 2", user: @teacher)
        @entry3 = @topic.discussion_entries.create!(message: "entry 3", user: @teacher)

        @entry2.change_read_state("read", @student)

        # Notice we read the entries 1 min after the the query issues
        expect(DiscussionEntry.unread_for_user_before(@student, Time.utc(2013, 3, 13, 10, 11)).order("id").map(&:message)).to eq(["entry 2", "entry 3"])
      end
    end
  end

  context "read/unread state" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher)
      @entry = @topic.discussion_entries.create!(message: "entry", user: @teacher)
    end

    it "marks a entry you created as read" do
      expect(@entry.read?(@teacher)).to be_truthy
      expect(@topic.unread_count(@teacher)).to eq 0
    end

    it "is unread by default" do
      expect(@entry.read?(@student)).to be_falsey
      expect(@topic.unread_count(@student)).to eq 1
    end

    it "allows being marked unread" do
      @entry.change_read_state("unread", @teacher)
      expect(@entry.read?(@teacher)).to be_falsey
      expect(@topic.unread_count(@teacher)).to eq 1
    end

    it "allows being marked read" do
      @entry.change_read_state("read", @student)
      expect(@entry.read?(@student)).to be_truthy
      expect(@topic.unread_count(@student)).to eq 0
    end

    it "updates counts for an entry without a user" do
      @other_entry = @topic.discussion_entries.create!(message: "no user entry")
      expect(@topic.unread_count(@teacher)).to eq 1
      expect(@topic.unread_count(@student)).to eq 2
    end

    it "allows a complex series of read/unread updates" do
      @s1 = @student
      student_in_course(active_all: true)
      @s2 = @student
      student_in_course(active_all: true)
      @s3 = @student

      @topic.change_read_state("read", @s1)
      @entry.change_read_state("read", @s1)
      @s1entry = @topic.discussion_entries.create!(message: "s1 entry", user: @s1)
      expect(@topic.unread_count(@s1)).to eq 0

      @entry.change_read_state("read", @s2)
      expect(@topic.discussion_topic_participants.where(user_id: @s2).first).not_to be_nil
      @topic.change_read_state("read", @s2)
      @s2entry = @topic.discussion_entries.create!(message: "s2 entry", user: @s2)
      @s1entry.change_read_state("read", @s2)
      @s1entry.change_read_state("unread", @s2)
      expect(@topic.unread_count(@s2)).to eq 1

      expect(@topic.unread_count(@s3)).to eq 3
      @entry.change_read_state("read", @s3)
      @s3reply = @entry.discussion_subentries.create!(discussion_topic: @topic, message: "s3 reply", user: @s3)
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

      student_in_course(active_all: true)
      @s4 = @student
      expect(@topic.unread_count(@s4)).to eq 4
      @topic.change_all_read_state("unread", @s4)
      expect(@topic.read?(@s4)).to be_falsey
      expect(@entry.read?(@s4)).to be_falsey

      student_in_course(active_all: true)
      @s5 = @student
      @topic.change_all_read_state("read", @s5)
      expect(@topic.unread_count(@s5)).to eq 0
    end

    it "does not increment unread count for students in group topics when posting to the root" do
      course_with_student(active_all: true)
      teacher1 = @teacher
      teacher2 = teacher_in_course(course: @course, active_all: true).user

      group_category = @course.group_categories.create(name: "new category")
      @group = @course.groups.create(name: "group", group_category:)
      @group.add_user(@student)

      root_topic = @course.discussion_topics.create!(title: "parent topic", message: "msg", group_category:)
      student_participant = root_topic.discussion_topic_participants.create!(user: @student)
      teacher_participant = root_topic.discussion_topic_participants.create!(user: teacher2)
      root_topic.discussion_entries.create!(message: "message", user: teacher1)

      expect(student_participant.reload.unread_entry_count).to eq 0
      expect(teacher_participant.reload.unread_entry_count).to eq 1 # still count as unread for the user that can read it
    end
  end

  context "rating" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher)
      @entry = @topic.discussion_entries.create!(message: "entry", user: @s1)
    end

    it "allows being rated" do
      expect(@entry.rating(@teacher)).to be_nil
      @entry.change_rating(1, @teacher)
      expect(@entry.rating(@teacher)).to eq 1
    end

    it "updates rating_count and rating_sum" do
      @entry.change_rating(1, @teacher)
      @entry.reload
      expect(@entry.rating_count).to eq 1
      expect(@entry.rating_sum).to eq 1

      student_in_course(active_all: true)
      @s2 = @student

      @entry.change_rating(1, @s2)
      @entry.reload
      expect(@entry.rating_count).to eq 2
      expect(@entry.rating_sum).to eq 2
      @entry.change_rating(0, @teacher)
      @entry.reload
      expect(@entry.rating_count).to eq 2
      expect(@entry.rating_sum).to eq 1
    end
  end

  context "threaded discussions" do
    before :once do
      course_with_teacher
    end

    it "forces a root entry as parent if the discussion isn't threaded" do
      discussion_topic_model
      root = @topic.reply_from(user: @teacher, text: "root entry")
      sub1 = root.reply_from(user: @teacher, html: "sub entry")
      expect(sub1.parent_entry).to eq root
      expect(sub1.root_entry).to eq root
      sub2 = sub1.reply_from(user: @teacher, html: "sub-sub entry")
      expect(sub2.parent_entry).to eq root
      expect(sub2.root_entry).to eq root
    end

    it "allows a sub-entry as parent if the discussion is threaded" do
      discussion_topic_model(threaded: true)
      root = @topic.reply_from(user: @teacher, text: "root entry")
      sub1 = root.reply_from(user: @teacher, html: "sub entry")
      expect(sub1.parent_entry).to eq root
      expect(sub1.root_entry).to eq root
      sub2 = sub1.reply_from(user: @teacher, html: "sub-sub entry")
      expect(sub2.parent_entry).to eq sub1
      expect(sub2.root_entry).to eq root
    end
  end

  context "Flat discussions" do
    it "does not have a parent entry if the discussion is flat" do
      course_with_teacher
      discussion_topic_model
      @topic.discussion_type = DiscussionTopic::DiscussionTypes::FLAT
      @topic.save!
      root = @topic.reply_from(user: @teacher, text: "root entry")
      sub1 = root.reply_from(user: @teacher, html: "shouldn't really be a subentry")
      expect(sub1.reload.parent_entry).to be_nil
    end
  end

  describe "DiscussionEntryParticipant" do
    before :once do
      topic_with_nested_replies
    end

    context ".read_entry_ids" do
      it "returns the ids of the read entries" do
        @root2.change_read_state("read", @teacher)
        @reply_reply1.change_read_state("read", @teacher)
        @reply_reply2.change_read_state("read", @teacher)
        @reply3.change_read_state("read", @teacher)
        # change one back to unread, it shouldn't be returned
        @reply_reply2.change_read_state("unread", @teacher)
        read = DiscussionEntryParticipant.read_entry_ids(@topic.discussion_entries.map(&:id), @teacher).sort
        expect(read).to eq [@root2, @reply1, @reply2, @reply_reply1, @reply3].map(&:id)
      end
    end

    context ".forced_read_state_entry_ids" do
      it "returns the ids of entries that have been marked as force_read_state" do
        marked_entries = [@root2, @reply_reply1, @reply_reply2, @reply3]
        marked_entries.each do |e|
          e.change_read_state("read", @teacher, forced: true)
        end
        # change back, without :forced parameter, should stay forced
        @reply_reply2.change_read_state("unread", @teacher)
        # change forced to false so it shouldn't be in results
        @reply3.change_read_state("unread", @teacher, forced: false)
        marked_entries -= [@reply3]

        forced = DiscussionEntryParticipant.forced_read_state_entry_ids(@all_entries.map(&:id), @teacher).sort
        expect(forced).to eq marked_entries.map(&:id).sort
      end
    end

    context ".find_existing_participant" do
      it "returns existing data" do
        @root2.change_read_state("read", @teacher, forced: true)
        participant = @root2.find_existing_participant(@teacher)
        expect(participant.id).not_to be_nil
        expect(participant).to be_readonly
        expect(participant.user).to eq @teacher
        expect(participant.discussion_entry).to eq @root2
        expect(participant.workflow_state).to eq "read"
        expect(participant.forced_read_state).to be_truthy
      end

      it "returns default data" do
        participant = @reply2.find_existing_participant(@student)
        expect(participant.id).to be_nil
        expect(participant).to be_readonly
        expect(participant.user).to eq @student
        expect(participant.discussion_entry).to eq @reply2
        expect(participant.workflow_state).to eq "unread"
        expect(participant.forced_read_state).to be_falsey
      end

      it "works with user_id or user" do
        participant = @reply2.find_existing_participant(@student.id)
        expect(participant.id).to be_nil
        @reply2.change_read_state("read", @student, forced: true)
        participant_from_id = @reply2.find_existing_participant(@student.id)
        participant_from_user = @reply2.find_existing_participant(@student)
        expect(participant_from_id.id).not_to be_nil
        expect(participant_from_id.id).to eq participant_from_user.id
      end

      it "updates stream item from a mention" do
        @reply2.mentions.create!(user_id: @student, root_account_id: @reply2.root_account_id)
        expect(@student.stream_item_instances.last.workflow_state).to eq "unread"
        @reply2.change_read_state("read", @student, forced: true)
        expect(@student.stream_item_instances.last.workflow_state).to eq "read"
      end
    end
  end

  describe "reply_from" do
    before :once do
      course_with_teacher
      discussion_topic_model
    end

    it "ignores replies in deleted accounts" do
      root = @topic.reply_from(user: @teacher, text: "root entry")
      Account.default.destroy
      root.reload
      expect { root.reply_from(user: @teacher, text: "sub entry") }.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "prefers html to text" do
      @entry = @topic.reply_from(user: @teacher, text: "topic")
      msg = @entry.reply_from(user: @teacher, text: "text body", html: "<p>html body</p>")
      expect(msg).not_to be_nil
      expect(msg.message).to eq "<p>html body</p>"
    end

    it "does not allow students to reply to locked topics" do
      @entry = @topic.reply_from(user: @teacher, text: "topic")
      @topic.lock!
      @entry.reply_from(user: @teacher, text: "reply") # should not raise error
      student_in_course(course: @course)
      expect { @entry.reply_from(user: @student, text: "reply") }.to raise_error(IncomingMail::Errors::ReplyToLockedTopic)
    end

    it "does not allow replies from students to topics locked based on date" do
      @entry = @topic.reply_from(user: @teacher, text: "topic")
      @topic.delayed_post_at = 1.day.from_now
      @topic.save!
      @entry.reply_from(user: @teacher, text: "reply") # should not raise error
      student_in_course(course: @course)
      expect { @entry.reply_from(user: @student, text: "reply") }.to raise_error(IncomingMail::Errors::ReplyToLockedTopic)
    end

    it "raises InvalidParticipant for invalid participants" do
      u = user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
      expect { @topic.reply_from(user: u, text: "entry 1") }.to raise_error IncomingMail::Errors::InvalidParticipant
    end
  end

  context "stream items" do
    before(:once) do
      course_with_student active_all: true
      @empty_section = @course.course_sections.create!
      @topic = @course.discussion_topics.build(title: "topic")
      @assignment = @course.assignments.build title: @topic.title,
                                              submission_types: "discussion_topic",
                                              only_visible_to_overrides: true
      @assignment.assignment_overrides.build set: @empty_section
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save
    end

    it "doesn't make stream items for students that aren't assigned" do
      @topic.reply_from(user: @teacher, text: "...")
      expect(@student.stream_item_instances).to be_empty
    end
  end

  context "planner items cache" do
    before(:once) do
      course_with_student active_all: true
      @topic = @course.discussion_topics.build(title: "topic")
      @topic.save
      @topic.discussion_topic_participants.create!(user: @student, subscribed: true)
    end

    it "is cleared for top level replies on a todo discussion" do
      @topic.todo_date = 1.day.from_now
      @topic.save

      cache_key = @student.cache_key
      @topic.discussion_entries.build(parent_id: nil).save!
      @student.reload
      expect(@student.cache_key).not_to eql(cache_key)
    end

    it "is not cleared on nested replies for non-assignment non-todo discussions" do
      entry = @topic.discussion_entries.build(parent_id: nil)
      entry.save!

      sub_entry = @topic.discussion_entries.build(parent_id: entry.id)
      sub_entry.save!

      @student.reload
      cache_key = @student.cache_key
      sub_entry2 = @topic.discussion_entries.build(parent_id: sub_entry.id)
      sub_entry2.save!
      @student.reload
      expect(@student.cache_key).to eql(cache_key)
    end

    it "is cleared on top level and for graded discussions" do
      assignment = @course.assignments.build(submission_types: "discussion_topic", title: topic.title, due_at: 1.day.from_now)
      assignment.saved_by = :discussion_topic
      @topic.assignment = assignment
      @topic.save

      cache_key = @student.cache_key
      @topic.discussion_entries.build(parent_id: nil).save!
      @student.reload
      expect(@student.cache_key).not_to eql(cache_key)
    end

    it "is cleared on nested replies for graded discussions" do
      assignment = @course.assignments.build(submission_types: "discussion_topic", title: topic.title, due_at: 1.day.from_now)
      assignment.saved_by = :discussion_topic
      @topic.assignment = assignment
      @topic.save

      entry = @topic.discussion_entries.build(parent_id: nil)
      entry.save!

      sub_entry1 = @topic.discussion_entries.build(parent_id: entry.id)
      sub_entry1.save!

      cache_key = @student.cache_key
      sub_entry2 = @topic.discussion_entries.build(parent_id: sub_entry1.id)
      sub_entry2.save!
      @student.reload
      expect(@student.cache_key).not_to eql(cache_key)
    end

    it "is cleared on nested replies for todo discussions" do
      @topic.todo_date = 1.day.from_now
      @topic.save

      entry = @topic.discussion_entries.build(parent_id: nil)
      entry.save!

      sub_entry1 = @topic.discussion_entries.build(parent_id: entry.id)
      sub_entry1.save!

      cache_key = @student.cache_key
      sub_entry2 = @topic.discussion_entries.build(parent_id: sub_entry1.id)
      sub_entry2.save!
      @student.reload
      expect(@student.cache_key).not_to eql(cache_key)
    end
  end

  describe "permissions" do
    let(:user) { user_model }
    let(:entry) { topic.discussion_entries.create!(message: "Hello!", user:) }

    describe "reply" do
      context "when a user is no longer enrolled in the course" do
        before do
          create_enrollment(topic.course, user, { enrollment_state: "completed" })
        end

        it "returns false for their own posts" do
          expect(entry.grants_right?(user, :reply)).to be false
        end
      end

      context "when course has announcement comments disabled" do
        before do
          create_enrollment(topic.course, user, { enrollment_state: "active" })
          topic.course.lock_all_announcements = true
          topic.course.save!
        end

        it "returns false when comments is locked for announcements" do
          announcement = topic.course.announcements.create!(title: "announcement", message: "message")
          announcement_entry = announcement.discussion_entries.create!(message: "Hello!", user:)
          expect(announcement_entry.grants_right?(user, :reply)).to be false
        end

        it "returns true for non-announcement discussions" do
          expect(entry.grants_right?(user, :reply)).to be true
        end
      end
    end

    describe "update" do
      context "when a user is no longer enrolled in the course" do
        before do
          create_enrollment(topic.course, user, { enrollment_state: "completed" })
        end

        it "returns false for their own posts" do
          expect(entry.grants_right?(user, :update)).to be false
        end
      end
    end

    describe "delete" do
      context "when a user is no longer enrolled in the course" do
        before do
          create_enrollment(topic.course, user, { enrollment_state: "completed" })
        end

        it "returns false for their own posts" do
          expect(entry.grants_right?(user, :delete)).to be false
        end
      end
    end

    describe "create" do
      context "with an active enrollment" do
        before :once do
          course_with_student active_all: true
        end

        let(:topic) { @course.discussion_topics.create(title: "topic", message: "message") }
        let(:announcement) { @course.announcements.create(title: "announcement", message: "message") }

        it "allows replies from students on topics" do
          entry = topic.discussion_entries.build(user: @student, message: "message")
          expect(entry.grants_right?(@student, :create)).to be true
        end

        it "does not allow replies from students on locked topics" do
          topic.lock!
          entry = topic.discussion_entries.build(user: @student, message: "message")
          expect(entry.grants_right?(@student, :create)).to be false
        end

        it "allows replies from students on announcements" do
          entry = announcement.discussion_entries.build(user: @student, message: "message")
          expect(entry.grants_right?(@student, :create)).to be true
        end

        it "does not allow replies from students on locked announcements" do
          announcement.lock!
          entry = announcement.discussion_entries.build(user: @student, message: "message")
          expect(entry.grants_right?(@student, :create)).to be false
        end

        context "when context.lock_all_announcements is true" do
          before do
            @course.lock_all_announcements = true
            @course.save!
          end

          it "does not allow replies from students on announcements" do
            entry = announcement.discussion_entries.build(user: @student, message: "message")
            expect(entry.grants_right?(@student, :create)).to be false
          end

          it "allows replies for non-announcement topics" do
            entry = topic.discussion_entries.build(user: @student, message: "message")
            expect(entry.grants_right?(@student, :create)).to be true
          end
        end
      end
    end
  end

  describe "#author_name" do
    let(:user) { user_model(name: "John Doe") }
    let(:entry) { topic.discussion_entries.create!(message: "Hello!", user:) }
    let(:anon_entry) { anonymous_topic.discussion_entries.create!(message: "Hello!", user:) }

    it "returns author name" do
      expect(entry.author_name).to eq "John Doe"
    end

    it "returns anonymous author name" do
      expect(anon_entry.author_name).to match(/Anonymous (.*)/)
    end

    it "returns You as anonymous author name" do
      expect(anon_entry.author_name(user)).to eq "John Doe"
    end

    context "discussion_topic.anonymous?" do
      context "TeacherEnrollment" do
        it "returns user.short_name" do
          anonymous_topic.course.enroll_user(user, "TeacherEnrollment", enrollment_state: "active")
          entry = anonymous_topic.discussion_entries.create!(message: "Hello!", user:)

          expect(entry.author_name).to eq(user.short_name)
        end
      end

      context "TaEnrollment" do
        it "returns user.short_name" do
          anonymous_topic.course.enroll_user(user, "TaEnrollment", enrollment_state: "active")
          entry = anonymous_topic.discussion_entries.create!(message: "Hello!", user:)

          expect(entry.author_name).to eq(user.short_name)
        end
      end

      context "DesignerEnrollment" do
        it "returns user.short_name" do
          anonymous_topic.course.enroll_user(user, "DesignerEnrollment", enrollment_state: "active")
          entry = anonymous_topic.discussion_entries.create!(message: "Hello!", user:)

          expect(entry.author_name).to eq(user.short_name)
        end
      end

      context "discussion_topic partial_anonymity && !entry.is_anonymous_author" do
        it "returns user.short_name" do
          entry = partially_anonymous_topic.discussion_entries.create!(message: "Hello!", user:, is_anonymous_author: false)
          expect(entry.author_name).to eq(user.short_name)
        end
      end
    end
  end

  describe "discussion_entry_versions" do
    let(:user) { user_model(name: "John Doe") }

    it "creates version 1 on new entry" do
      entry = topic.discussion_entries.create(message: "Test 1", user:)

      expect(entry.discussion_entry_versions.count).to eq(1)
      expect(entry.discussion_entry_versions.take.message).to eq(entry.message)
    end

    it "creates various versions on entry updates" do
      entry = topic.discussion_entries.create(message: "Test 1", user:)

      expect(entry.discussion_entry_versions.count).to eq(1)
      expect(entry.discussion_entry_versions.take.message).to eq(entry.message)

      entry.message = "Test 2"
      entry.save!

      expect(entry.discussion_entry_versions.count).to eq(2)
      expect(entry.discussion_entry_versions.first.message).to eq(entry.message)

      entry.message = "Test 3"
      entry.save!

      expect(entry.discussion_entry_versions.count).to eq(3)
      expect(entry.discussion_entry_versions.first.message).to eq(entry.message)

      expect(entry.discussion_entry_versions.pluck(:message)).to eq(["Test 3", "Test 2", "Test 1"])
    end
  end

  it "correctly sets depth property" do
    discussion_topic_model(threaded: true)
    root = @topic.reply_from(user: @teacher, text: "root entry")
    reply1 = root.reply_from(user: @teacher, html: "sub entry")
    reply2 = reply1.reply_from(user: @teacher, html: "sub-sub entry")
    reply3 = reply1.reply_from(user: @teacher, html: "sub-sub sibling entry")
    reply4 = reply2.reply_from(user: @teacher, html: "sub-sub-sub entry")

    expect(root.depth).to eq 1
    expect(reply1.depth).to eq 2
    expect(reply2.depth).to eq 3
    expect(reply3.depth).to eq 3
    expect(reply4.depth).to eq 4
  end
end
