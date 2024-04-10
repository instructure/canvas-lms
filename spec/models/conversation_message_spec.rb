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

describe ConversationMessage do
  context "notifications" do
    before :once do
      Notification.create(name: "Conversation Message", category: "TestImmediately")
      Notification.create(name: "Added To Conversation", category: "TestImmediately")

      course_with_teacher(active_all: true)
      @students = []
      3.times { @students << student_in_course(active_all: true).user }
      @first_student = @students.first
      @initial_students = @students.first(2)
      @last_student = @students.last

      [@teacher, *@students].each do |user|
        communication_channel(user, { username: "test_channel_email_#{user.id}@test.com", active_cc: true })
      end

      @conversation = @teacher.initiate_conversation(@initial_students)
      user = User.find(@conversation.user_id)
      @account = Account.find(user.account.id)
      add_message # need initial message for add_participants to not barf
    end

    def add_message(options = {})
      @conversation.add_message("message", options.merge(root_account_id: @account.id))
    end

    def add_last_student
      @conversation.add_participants([@last_student])
    end

    it "formats an author line with shared contexts" do
      message = add_message
      expect(message.author_short_name_with_shared_contexts(@first_student)).to eq "#{message.author.short_name} (#{@course.name})"
    end

    it "formats an author line without shared contexts" do
      user_factory
      @conversation = @teacher.initiate_conversation([@user])
      message = add_message
      expect(message.author_short_name_with_shared_contexts(@user)).to eq message.author.short_name
    end

    it "creates appropriate notifications on new message", priority: "1" do
      message = add_message
      expect(message.messages_sent).to include("Conversation Message")
      expect(message.messages_sent).not_to include("Added To Conversation")
    end

    it "creates appropriate notifications on added participants" do
      event = add_last_student
      expect(event.messages_sent).not_to include("Conversation Message")
      expect(event.messages_sent).to include("Added To Conversation")
    end

    it "does not notify the author" do
      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).not_to include(@teacher.id)

      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).not_to include(@teacher.id)
    end

    it "does not notify unsubscribed participants" do
      student_view = @first_student.conversations.first
      student_view.subscribed = false
      student_view.save

      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).not_to include(@first_student.id)
    end

    it "notifies subscribed participants on new message" do
      message = add_message
      expect(message.messages_sent["Conversation Message"].map(&:user_id)).to include(@first_student.id)
    end

    it "limits notifications to message recipients, still excluding the author" do
      message = add_message(only_users: [@teacher, @students.first])
      message_user_ids = message.messages_sent["Conversation Message"].map(&:user_id)
      expect(message_user_ids).not_to include(@teacher.id)
      expect(message_user_ids).to include(@students.first.id)
      @students[1..].each do |student|
        expect(message_user_ids).not_to include(student.id)
      end
    end

    it "notifies new participants" do
      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).to include(@last_student.id)
    end

    it "does not notify existing participants on added participant" do
      event = add_last_student
      expect(event.messages_sent["Added To Conversation"].map(&:user_id)).not_to include(@first_student.id)
    end

    it "adds a new message when a user replies to a notification" do
      conversation_message = add_message
      message = conversation_message.messages_sent["Conversation Message"].first

      expect(message.context).to eq conversation_message
      message.context.reply_from(user: message.user,
                                 purpose: "general",
                                 subject: message.subject,
                                 text: "Reply to notification")
      # The initial message, the one the sent the notification,
      # and the response to the notification
      expect(@conversation.messages.size).to eq 3
      expect(@conversation.messages.first.body).to match(/Reply to notification/)
    end
  end

  context "generate_user_note" do
    context "when the deprecate_faculty_journal flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "adds a user note under nominal circumstances" do
        Account.default.update_attribute :enable_user_notes, true
        course_with_teacher(active_all: true)
        student = student_in_course(active_all: true).user
        conversation = @teacher.initiate_conversation([student])
        conversation.add_message("reprimanded!", generate_user_note: true, root_account_id: Account.default.id)
        expect(student.user_notes.size).to be(1)
        note = student.user_notes.first
        expect(note.creator).to eql(@teacher)
        expect(note.title).to eql("Private message")
        expect(note.note).to eql("reprimanded!")
      end

      it "allows user notes on more than one recipient" do
        Account.default.update_attribute :enable_user_notes, true
        course_with_teacher(active_all: true)
        student1 = student_in_course(active_all: true).user
        student2 = student_in_course(active_all: true).user
        conversation = @teacher.initiate_conversation([student1, student2])
        conversation.add_message("reprimanded!", generate_user_note: true, root_account_id: Account.default.id)
        expect(student1.user_notes.size).to be(1)
        expect(student2.user_notes.size).to be(1)
      end
    end

    context "when the deprecate_faculty_journal flag is enabled" do
      it "does not add a user note under nominal circumstances" do
        Account.default.update_attribute :enable_user_notes, true
        course_with_teacher(active_all: true)
        student = student_in_course(active_all: true).user
        conversation = @teacher.initiate_conversation([student])
        conversation.add_message("reprimanded!", generate_user_note: true, root_account_id: Account.default.id)
        expect(student.user_notes.size).to be(0)
      end
    end

    it "fails if notes are disabled on the account" do
      Account.default.update_attribute :enable_user_notes, false
      course_with_teacher(active_all: true)
      student = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student])
      conversation.add_message("reprimanded!", generate_user_note: true, root_account_id: Account.default.id)
      expect(student.user_notes.size).to be(0)
    end
  end

  context "stream_items" do
    before :once do
      course_with_teacher
      student_in_course
    end

    it "creates a stream item based on the conversation" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      message = conversation.add_message("initial message")

      expect(StreamItem.count).to eql(old_count + 1)
      stream_item = StreamItem.last
      expect(stream_item.asset).to eq message.conversation
    end

    it "does not create a conversation stream item for a submission comment" do
      assignment_model(course: @course)
      @assignment.workflow_state = "published"
      @assignment.save
      @submission = @assignment.submit_homework(@user, body: "some message")
      @submission.add_comment(author: @user, comment: "hello")

      expect(StreamItem.select { |i| i.asset_string.include?("conversation_") }).to be_empty
    end

    it "does not create additional stream_items for additional messages in the same conversation" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("first message")
      stream_item = StreamItem.last
      conversation.add_message("second message")
      conversation.add_message("third message")

      expect(StreamItem.count).to eql(old_count + 1)
      expect(StreamItem.last).to eql(stream_item)
    end

    it "does not delete the stream_item if a message is deleted, just regenerate" do
      old_count = StreamItem.count

      conversation = @teacher.initiate_conversation([@user])
      conversation.add_message("initial message")
      message = conversation.add_message("second message")

      message.destroy
      expect(StreamItem.count).to eql(old_count + 1)
    end

    it "should delete the stream_item if the conversation is deleted" # not yet implemented
  end

  context "sharding" do
    specs_require_sharding

    it "preserves attachments across shards" do
      @shard1.activate do
        course_with_teacher(active_all: true)
      end
      a = @teacher.shard.activate do
        attachment_model(context: @teacher, folder: @teacher.conversation_attachments_folder)
      end
      m = nil
      @shard2.activate do
        student_in_course(active_all: true)
        m = @teacher.initiate_conversation([@student]).add_message("test", attachment_ids: [a.id])
        expect(m.attachments).to match_array([a])
      end
      @shard1.activate do
        expect(m.attachments).to match_array([a])
      end
    end

    context "when the deprecate_faculty_journal flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "user_note uses the recipients shard" do
        conversation = nil
        acc = nil
        @shard1.activate do
          acc = Account.default
          acc.enable_user_notes = true
          acc.save!
          course_with_teacher(active_all: true)
        end
        a = @teacher.shard.activate do
          attachment_model(context: @teacher, folder: @teacher.conversation_attachments_folder)
        end
        m = nil
        @shard2.activate do
          student_in_course(active_all: true)
          m = @teacher.initiate_conversation([@student]).add_message("test", attachment_ids: [a.id])
          conversation = m.conversation
        end
        @shard1.activate do
          allow(Account).to receive(:default) { acc }
          conversation_participant = conversation.conversation_participants.where(user_id: @teacher.id).first
          conversation_participant.add_message("reprimanded!", generate_user_note: true, root_account_id: acc)
          conversation_participant.reload
          expect(@student.user_notes.last.root_account_id).to eq(Shard.relative_id_for(acc.id, acc.shard, @student.shard))
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      it "preserves media comment across shards" do
        @shard1.activate do
          course_with_teacher(active_all: true)
          @student_1 =  student_in_course(active_all: true).user
          @student_2 =  student_in_course(active_all: true).user
        end

        m = nil
        @shard2.activate do
          course_with_teacher(active_all: true)
          @course.enroll_student(@student_1, enrollment_state: "active")
          @course.enroll_student(@student_2, enrollment_state: "active")

          @mc = MediaObject.new
          @mc.media_type = "audio"
          @mc.media_id = "asdf"
          @mc.context = @mc.user = @student_1
          @mc.save
          m = @student_1.initiate_conversation([@student_2]).add_message("ohai", media_comment: @mc)
        end

        @shard1.activate do
          expect(m.conversation.reload.conversation_messages.first.media_comment).to eq(@mc)
        end
      end

      it "returns correct recipients for cross-shard users" do
        @shard1.activate do
          @account_1 = Account.create
          @student = user_with_pseudonym(active_all: true, account: @account_1)
        end
        @shard2.activate do
          @account_2 = Account.create
          course_with_teacher(active_all: true)
          @teacher_1 = @teacher
          @course_1 = @course
          @course_1.enroll_student(@student).accept!

          @cp = @teacher_1.initiate_conversation([@student])
          @convo = @cp.conversation
          @m1 = @cp.add_message("Hi from shard 2", root_account_id: @account_2)
        end

        @shard1.activate do
          @m2 = @convo.add_message(@student, "replying from shard 1", only_users: [@teacher_1], root_account_id: @account_1)
          @m2 = ConversationMessage.find(@m2.id)
          expect(@m2.recipients).to include(@teacher_1)
        end
      end
    end
  end

  context "infer_defaults" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "sets has_attachments if there are attachments" do
      a = attachment_model(context: @teacher, folder: @teacher.conversation_attachments_folder)
      m = @teacher.initiate_conversation([@student]).add_message("ohai", attachment_ids: [a.id])
      expect(m.read_attribute(:has_attachments)).to be_truthy
      expect(m.conversation.reload.has_attachments).to be_truthy
      expect(m.conversation.conversation_participants.all?(&:has_attachments?)).to be_truthy
    end

    it "sets has_attachments if there are forwareded attachments" do
      a = attachment_model(context: @teacher, folder: @teacher.conversation_attachments_folder)
      m1 = @teacher.initiate_conversation([user_factory]).add_message("ohai", attachment_ids: [a.id])
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", forwarded_message_ids: [m1.id])
      expect(m2.read_attribute(:has_attachments)).to be_truthy
      expect(m2.conversation.reload.has_attachments).to be_truthy
      expect(m2.conversation.conversation_participants.all?(&:has_attachments?)).to be_truthy
    end

    it "sets has_media_objects if there is a media comment" do
      mc = MediaObject.new
      mc.media_type = "audio"
      mc.media_id = "asdf"
      mc.context = mc.user = @teacher
      mc.save
      m = @teacher.initiate_conversation([@student]).add_message("ohai", media_comment: mc)
      expect(m.read_attribute(:has_media_objects)).to be_truthy
      expect(m.conversation.reload.has_media_objects).to be_truthy
      expect(m.conversation.conversation_participants.all?(&:has_media_objects?)).to be_truthy
    end

    it "sets has_media_objects if there are forwarded media comments" do
      mc = MediaObject.new
      mc.media_type = "audio"
      mc.media_id = "asdf"
      mc.context = mc.user = @teacher
      mc.save
      m1 = @teacher.initiate_conversation([user_factory]).add_message("ohai", media_comment: mc)
      m2 = @teacher.initiate_conversation([@student]).add_message("lulz", forwarded_message_ids: [m1.id])
      expect(m2.read_attribute(:has_media_objects)).to be_truthy
      expect(m2.conversation.reload.has_media_objects).to be_truthy
      expect(m2.conversation.conversation_participants.all?(&:has_media_objects?)).to be_truthy
    end
  end

  context "log_conversation_message_metrics" do
    it "logs inbox.message.created.react when react_inbox is ON in root account" do
      Account.default.enable_feature! :react_inbox
      allow(InstStatsd::Statsd).to receive(:increment)

      course_with_teacher(active_all: true)
      student1 = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student1])
      conversation.add_message("hello", generate_user_note: false, root_account_id: Account.default.id)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.created.react").at_least(:once)
    end

    it "logs inbox.message.created.legacy when react_inbox is OFF in root account" do
      Account.default.disable_feature! :react_inbox
      allow(InstStatsd::Statsd).to receive(:increment)

      course_with_teacher(active_all: true)
      student1 = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student1])
      conversation.add_message("hello", generate_user_note: false, root_account_id: Account.default.id)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.created.legacy").at_least(:once)
    end

    it "logs inbox.message.created.react when react_inbox is ON in site admin" do
      Account.site_admin.enable_feature! :react_inbox
      allow(InstStatsd::Statsd).to receive(:increment)

      course_with_teacher(active_all: true)
      student1 = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student1])
      conversation.add_message("hello", generate_user_note: false, root_account_id: Account.default.id)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.created.react").at_least(:once)
    end

    it "logs inbox.message.created.legacy when react_inbox is OFF in site admin" do
      Account.site_admin.disable_feature! :react_inbox
      allow(InstStatsd::Statsd).to receive(:increment)

      course_with_teacher(active_all: true)
      student1 = student_in_course(active_all: true).user
      conversation = @teacher.initiate_conversation([student1])
      conversation.add_message("hello", generate_user_note: false, root_account_id: Account.default.id)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.created.legacy").at_least(:once)
    end
  end

  describe "reply_from" do
    before do
      course_with_teacher
    end

    it "ignores replies on deleted accounts" do
      student_in_course
      conversation = @teacher.initiate_conversation([@user])
      cm = conversation.add_message("initial message", root_account_id: Account.default.id)

      Account.default.destroy
      cm.reload

      expect do
        cm.reply_from({
                        purpose: "general",
                        user: @teacher,
                        subject: "an email reply",
                        html: "body",
                        text: "body"
                      })
      end.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "ignores replies to conversations in hard concluded courses" do
      student_in_course
      convo = @teacher.initiate_conversation([@user])
      convo.add_message("you cannot reply to this because it is concluded")
      convo.conversation.update_attribute(:context, @course)
      @course.update!(workflow_state: "completed")

      last_message = convo.conversation.conversation_messages.last
      expect do
        last_message.reply_from({
                                  purpose: "general",
                                  user: @user,
                                  subject: "this reply should return an error",
                                  html: "body",
                                  text: "body"
                                })
      end.to raise_error(IncomingMail::Errors::InvalidParticipant)
    end

    context "soft concluded course" do
      before do
        student_in_course
        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.save!

        @convo = @teacher.initiate_conversation([@user])
        @convo.add_message("you cannot reply to this because it is concluded")
        @convo.conversation.update_attribute(:context, @course)
        @last_message = @convo.conversation.conversation_messages.last
      end

      it "ignores replies from students in soft concluded courses with date restrictions" do
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        expect do
          @last_message.reply_from({
                                     purpose: "general",
                                     user: @user,
                                     subject: "this reply should return an error",
                                     html: "body",
                                     text: "body"
                                   })
        end.to raise_error(IncomingMail::Errors::InvalidParticipant)
      end

      it "allows replies from students with ongoing section overrides" do
        my_section = @course.course_sections.create!(name: "test section")
        my_section.start_at = 1.day.ago
        my_section.end_at = 5.days.from_now
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!
        @course.save!

        @course.enroll_student(@user,
                               allow_multiple_enrollments: true,
                               enrollment_state: "active",
                               section: my_section)

        email_reply = @last_message.reply_from({
                                                 purpose: "general",
                                                 user: @user,
                                                 subject: "this reply should return an error",
                                                 html: "body",
                                                 text: "body"
                                               })

        expect(email_reply.body).to eq "body"
      end

      it "only section date restriction - allows replies from students with term role overrides" do
        term = @course.enrollment_term
        term.enrollment_dates_overrides.create!(
          enrollment_type: "StudentEnrollment", start_at: 10.days.ago, end_at: 10.days.from_now, context: term.root_account
        )
        @course.restrict_enrollments_to_course_dates = false

        my_section = @course.course_sections.create!(name: "test section")

        @course.enroll_student(@student,
                               allow_multiple_enrollments: true,
                               enrollment_state: "active",
                               section: my_section)

        @course.enroll_teacher(@teacher,
                               allow_multiple_enrollments: true,
                               enrollment_state: "active",
                               section: my_section)

        # test the OR case by concluding the section
        my_section.start_at = 5.days.ago
        my_section.end_at = 4.days.ago
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!

        email_reply = @last_message.reply_from({
                                                 purpose: "general",
                                                 user: @user,
                                                 subject: "this reply should return an error",
                                                 html: "body",
                                                 text: "body"
                                               })

        expect(email_reply.body).to eq "body"
      end
    end

    it "replies only to the message author on conversations2 conversations" do
      student1 = student_in_course.user
      student2 = student_in_course.user
      student3 = student_in_course.user

      cp = student1.initiate_conversation([student1, student2, student3])
      cp.add_message("initial message", root_account_id: Account.default.id, recipients: [student1])
      cm2 = cp.add_message("subsequent message", root_account_id: Account.default.id, recipients: [student2])
      expect(cm2.conversation_message_participants.size).to eq 3
      cm3 = cm2.reply_from({
                             purpose: "general",
                             user: student2,
                             subject: "an email reply",
                             html: "body",
                             text: "body"
                           })
      expect(cm3.conversation_message_participants.size).to eq 2
      expect(cm3.conversation_message_participants.map(&:user_id).sort).to eq [student1.id, student2.id].sort
    end

    it "marks conversations as read for the replying author" do
      student_in_course
      cp = @teacher.initiate_conversation([@user])
      cm = cp.add_message("initial message", root_account_id: Account.default.id)

      cp2 = cp.conversation.conversation_participants.where(user_id: @user).first
      expect(cp2.workflow_state).to eq "unread"
      cm.reply_from({
                      purpose: "general",
                      user: @user,
                      subject: "an email reply",
                      html: "body",
                      text: "body"
                    })
      cp2.reload
      expect(cp2.workflow_state).to eq "read"
    end
  end
end
