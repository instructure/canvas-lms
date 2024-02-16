# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::CreateConversation do
  before do
    allow(InstStatsd::Statsd).to receive(:count)
    allow(InstStatsd::Statsd).to receive(:increment)
  end

  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  def conversation(opts = {})
    num_other_users = opts[:num_other_users] || 1
    course = opts[:course] || @course
    user_data = Array.new(num_other_users) { { name: "User" } }
    users = create_users_in_course(course, user_data, account_associations: true, return_type: :record)
    @conversation = @user.initiate_conversation(users)
    @conversation.add_message(opts[:message] || "test")
    @conversation.conversation.update_attribute(:context, course)
    @conversation
  end

  def mutation_str(
    recipients: nil,
    subject: nil,
    body: nil,
    bulk_message: nil,
    force_new: nil,
    group_conversation: nil,
    attachment_ids: nil,
    media_comment_id: nil,
    media_comment_type: nil,
    context_code: nil,
    conversation_id: nil,
    user_note: nil,
    tags: nil
  )
    <<~GQL
      mutation {
        createConversation(input: {
          recipients: #{recipients}
          #{"subject: \"#{subject}\"" if subject}
          body: "#{body}"
          #{"bulkMessage: #{bulk_message}" unless bulk_message.nil?}
          #{"forceNew: #{force_new}" unless force_new.nil?}
          #{"groupConversation: #{group_conversation}" unless group_conversation.nil?}
          #{"attachmentIds: #{attachment_ids}" if attachment_ids}
          #{"mediaCommentId: \"#{media_comment_id}\"" if media_comment_id}
          #{"mediaCommentType: \"#{media_comment_type}\"" if media_comment_type}
          #{"contextCode: \"#{context_code}\"" if context_code}
          #{"conversationId: \"#{conversation_id}\"" if conversation_id}
          #{"userNote: #{user_note}" unless user_note.nil?}
          #{"tags: #{tags}" if tags}
        }) {
          conversations {
            conversation {
              _id
              contextId
              contextType
              subject
              conversationMessagesConnection {
                nodes {
                  _id
                  body
                  conversationId
                  author {
                    _id
                    name
                  }
                  attachmentsConnection {
                    nodes {
                      _id
                      displayName
                    }
                  }
                }
              }
              conversationParticipantsConnection {
                nodes {
                  _id
                  user {
                    _id
                    name
                  }
                }
              }
            }
          }
          errors {
            message
            attribute
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "creates a conversation" do
    new_user = User.create
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = "active"
    enrollment.save
    @student.media_objects.where(media_id: "m-whatever", media_type: "video/mp4").first_or_create!
    result = run_mutation(recipients: [new_user.id.to_s], body: "yo", context_code: @course.asset_string, media_comment_id: "m-whatever", media_comment_type: "video")
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.created.react")
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.react")
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.react")
    expect(InstStatsd::Statsd).to have_received(:count).with("inbox.message.sent.recipients.react", 1)
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.media.react")
    expect(result.dig("data", "createConversation", "errors")).to be_nil
    expect(
      result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
    ).to eq "yo"
  end

  it "creates a conversation with an attachment" do
    new_user = User.create
    attachment = @user.conversation_attachments_folder.attachments.create!(filename: "somefile.doc", context: @user, uploaded_data: StringIO.new("test"))
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = "active"
    enrollment.save
    @student.media_objects.where(media_id: "m-whatever", media_type: "video/mp4").first_or_create!
    result = run_mutation(
      recipients: [new_user.id.to_s],
      body: "yo",
      context_code: @course.asset_string,
      media_comment_id: "m-whatever",
      media_comment_type: "video",
      attachment_ids: [attachment.id]
    )
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.created.react")
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.react")
    expect(InstStatsd::Statsd).to have_received(:count).with("inbox.message.sent.recipients.react", 1)
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.media.react")
    expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.attachment.react")
    expect(result.dig("data", "createConversation", "errors")).to be_nil
    expect(
      result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
    ).to eq "yo"
  end

  it "does not allow creating conversations without context without read_roster permission (the normal case)" do
    new_user = User.create
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = "active"
    enrollment.save
    result = run_mutation(recipients: [new_user.id.to_s], body: "yo")

    error = result.dig("data", "createConversation", "errors")[0]
    expected_result = {
      attribute: "context_code",
      message: "Context cannot be blank"
    }.stringify_keys

    expect(error).to eq(expected_result)
  end

  it "does not allow creating conversations in concluded courses for students" do
    @course.update!(workflow_state: "completed")

    result = run_mutation(recipients: [@teacher.id.to_s], body: "yo", context_code: @course.asset_string)

    expect(result.dig("data", "createConversation", "conversations")).to be_nil
    expect(
      result.dig("data", "createConversation", "errors", 0, "message")
    ).to eq "Unable to send messages to users in #{@course.name}"
  end

  it "does not allow creating conversations in concluded courses for teachers" do
    teacher2 = teacher_in_course(active_all: true).user
    @course.update!(workflow_state: "completed")

    result = run_mutation({ recipients: [teacher2.id.to_s], body: "yo", context_code: @course.asset_string }, @teacher)

    expect(result.dig("data", "createConversation", "conversations")).to be_nil
    expect(
      result.dig("data", "createConversation", "errors", 0, "message")
    ).to eq "Unable to send messages to users in #{@course.name}"
  end

  context "soft-concluded course with with active enrollment overrides" do
    before do
      course_with_student(active_all: true)
      @course.enrollment_term.start_at = 2.days.ago
      @course.enrollment_term.end_at = 1.day.ago
      @course.restrict_student_future_view = true
      @course.restrict_student_past_view = true
      @course.enrollment_term.set_overrides(Account.default, "TeacherEnrollment" => { start_at: 1.day.ago, end_at: 2.days.from_now })
      @course.enrollment_term.set_overrides(Account.default, "StudentEnrollment" => { start_at: 1.day.ago, end_at: 2.days.from_now })
      @course.save!
      @course.enrollment_term.save!
    end

    it "allows a student to create a new conversation in soft_concluded course if enrollment override is active" do
      expect(@course.soft_concluded?).to be_truthy
      result = run_mutation(recipients: [@teacher.id.to_s], body: "yo", context_code: @course.asset_string)
      expect(result.dig("data", "createConversation", "errors")).to be_nil
      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
      ).to eq "yo"
    end

    it "allows a teacher to create a new conversation in soft_concluded course if enrollment override is active" do
      expect(@course.soft_concluded?).to be_truthy
      result = run_mutation({ recipients: [@student.id.to_s], body: "yo", context_code: @course.asset_string }, @teacher)
      expect(result.dig("data", "createConversation", "errors")).to be_nil
      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
      ).to eq "yo"
    end
  end

  context "soft concluded course with non-concluded section override" do
    before do
      @student1 = course_with_student(active_all: true).user
      @student2 = course_with_student(active_all: true).user
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      @my_section = @course.course_sections.create!(name: "test section")
      @my_section.start_at = 1.day.ago
      @my_section.end_at = 5.days.from_now
      @my_section.restrict_enrollments_to_section_dates = true
      @my_section.save!

      @course.enroll_student(@student1,
                             allow_multiple_enrollments: true,
                             enrollment_state: "active",
                             section: @my_section)

      @course.enroll_teacher(@teacher,
                             allow_multiple_enrollments: true,
                             enrollment_state: "active",
                             section: @my_section)
    end

    it "allows a student to create a new conversation in soft_concluded course if section override is active" do
      expect(@course.soft_concluded?).to be_truthy
      result = run_mutation({ recipients: [@teacher.id.to_s], body: "yo", context_code: @course.asset_string }, @student1)
      expect(result.dig("data", "createConversation", "errors")).to be_nil
      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
      ).to eq "yo"
    end

    it "allows a teacher to create a new conversation in soft_concluded course if section override is active" do
      expect(@course.soft_concluded?).to be_truthy
      result = run_mutation({ recipients: [@student1.id.to_s], body: "yo", context_code: @course.asset_string }, @teacher)
      expect(result.dig("data", "createConversation", "errors")).to be_nil
      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
      ).to eq "yo"
    end

    it "does not allow a student that is not part of the section override to send messages" do
      expect(@course.soft_concluded?).to be_truthy
      result = run_mutation({ recipients: [@student.id.to_s], body: "yo", context_code: @course.asset_string }, @student2)
      expect(result.dig("data", "createConversation", "conversations")).to be_nil
      expect(
        result.dig("data", "createConversation", "errors", 0, "message")
      ).to eq "Unable to send messages to users in #{@course.name}"
    end
  end

  it "does not allow creating conversations in soft concluded courses for students" do
    @course.soft_conclude!
    @course.save
    result = run_mutation(recipients: [@teacher.id.to_s], body: "yo", context_code: @course.asset_string)

    expect(result.dig("data", "createConversation", "conversations")).to be_nil
    expect(
      result.dig("data", "createConversation", "errors", 0, "message")
    ).to eq "Course concluded, unable to send messages"
  end

  it "does not allow creating conversations in soft concluded courses for teachers" do
    teacher2 = teacher_in_course(active_all: true).user
    @course.soft_conclude!
    @course.save
    result = run_mutation({ recipients: [teacher2.id.to_s], body: "yo", context_code: @course.asset_string }, @teacher)

    expect(result.dig("data", "createConversation", "conversations")).to be_nil
    expect(
      result.dig("data", "createConversation", "errors", 0, "message")
    ).to eq "Course concluded, unable to send messages"
  end

  it "requires permissions for sending to other students" do
    new_user = User.create
    enrollment = @course.enroll_student(new_user)
    enrollment.workflow_state = "active"
    enrollment.save
    @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)

    result = run_mutation(recipients: [new_user.id.to_s], body: "yo", context_code: @course.asset_string)
    expect(
      result.dig("data", "createConversation", "errors", 0, "message")
    ).to eq "Invalid recipients"
  end

  it "allows sending to instructors even if permissions are disabled" do
    @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)

    result = run_mutation(recipients: [@teacher.id.to_s], body: "yo", context_code: @course.asset_string)
    expect(
      result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
    ).to eq "yo"
  end

  it "allows observers to message linked students" do
    observer = user_with_pseudonym
    add_linked_observer(@student, observer, root_account: @course.root_account)

    result = run_mutation({ recipients: [@student.id.to_s], body: "Hello there", context_code: @course.asset_string }, observer)
    expect(
      result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
    ).to eq "Hello there"
  end

  it "infers context tags" do
    course_with_teacher_logged_in(active_all: true)
    @course1 = @course
    @course2 = course_factory(active_all: true)
    @course2.enroll_teacher(@user).accept
    @course3 = course_factory(active_all: true)
    @course3.enroll_student(@user)
    @group1 = @course1.groups.create!
    @group2 = @course1.groups.create!
    @group3 = @course3.groups.create!
    @group1.users << @user
    @group2.users << @user
    @group3.users << @user

    new_user1 = User.create
    enrollment1 = @course1.enroll_student(new_user1)
    enrollment1.workflow_state = "active"
    enrollment1.save
    @group1.users << new_user1
    @group2.users << new_user1

    new_user2 = User.create
    enrollment2 = @course1.enroll_student(new_user2)
    enrollment2.workflow_state = "active"
    enrollment2.save
    @group1.users << new_user2
    @group2.users << new_user2

    new_user3 = User.create
    enrollment3 = @course2.enroll_student(new_user3)
    enrollment3.workflow_state = "active"
    enrollment3.save

    result = run_mutation(
      {
        recipients: [
          @course2.asset_string + "_students",
          @group1.asset_string
        ],
        body: "yo",
        group_conversation: true,
        context_code: @group3.asset_string
      },
      @user
    )
    conversation_id = result.dig("data", "createConversation", "conversations", 0, "conversation", "_id")
    expect(conversation_id).not_to be_nil
    c = Conversation.find(conversation_id)
    expect(c.tags.sort).to eql [@course1.asset_string, @course2.asset_string, @course3.asset_string, @group1.asset_string, @group3.asset_string].sort
  end

  context "group conversations" do
    before(:once) do
      @old_count = Conversation.count

      @new_user1 = User.create
      @course.enroll_student(@new_user1).accept!

      @new_user2 = User.create
      @course.enroll_student(@new_user2).accept!

      @account_id = @course.account_id
    end

    it "creates a conversation shared by all recipients" do
      result = run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], body: "yo", group_conversation: true, context_code: @course.asset_string)

      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationParticipantsConnection", "nodes")
          .pluck("user")
          .pluck("_id").sort
      ).to eql [@student.id.to_s, @new_user1.id.to_s, @new_user2.id.to_s].sort
      expect(Conversation.count).to eql(@old_count + 1)
    end

    it "creates one conversation per recipient" do
      user_type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)
      @student.media_objects.where(media_id: "m-whatever", media_type: "video/mp4").first_or_create!

      run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], subject: "yo 1", group_conversation: true, bulk_message: true, context_code: @course.asset_string, media_comment_id: "m-whatever", media_comment_type: "video")
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.individual_message_option.react")
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.react")
      expect(InstStatsd::Statsd).to have_received(:count).with("inbox.message.sent.recipients.react", 2)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.media.react")
      run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], subject: "yo 2", group_conversation: true, bulk_message: true, context_code: @course.asset_string, media_comment_id: "m-whatever", media_comment_type: "video")
      expect(InstStatsd::Statsd).to have_received(:count).with("inbox.conversation.created.react", 2).at_least(:twice)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.react").at_least(:twice)
      expect(InstStatsd::Statsd).to have_received(:count).with("inbox.message.sent.recipients.react", 2).at_least(:twice)
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.message.sent.media.react").at_least(:twice)
      expect(Conversation.count).to eql(@old_count + 4)
      result = user_type.resolve("conversationsConnection(scope: \"sent\") { nodes { conversation { subject } } }")
      expect(result).to match(["yo 2", "yo 2", "yo 1", "yo 1"])
    end

    context "private conversation" do
      it "returns one private conversation per user-recipient pair" do
        user_type = GraphQLTypeTester.new(@student, current_user: @student, domain_root_account: @student.account, request: ActionDispatch::TestRequest.create)

        run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], subject: "yo 1", group_conversation: false, bulk_message: true, context_code: @course.asset_string)
        run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], subject: "yo 2", group_conversation: false, bulk_message: true, context_code: @course.asset_string)

        expect(Conversation.count).to eql(@old_count + 2)
        result = user_type.resolve("conversationsConnection(scope: \"sent\") { nodes { conversation { subject } } }")
        expect(result).to match(["yo 1", "yo 1"])
      end
    end

    it "sets the root account id to the participants for group conversations" do
      result = run_mutation(recipients: [@new_user1.id.to_s, @new_user2.id.to_s], body: "yo", group_conversation: true, context_code: @course.asset_string)

      participant_ids = result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationParticipantsConnection", "nodes")
                              .pluck("_id")
      participant_ids.each do |participant_id|
        cp = ConversationParticipant.find(participant_id)
        expect(cp.root_account_ids).to eq [@account_id]
      end
    end

    it "does not allow sending messages to other users in a group if the permission is disabled" do
      @course.account.role_overrides.create!(permission: :send_messages, role: student_role, enabled: false)
      result = run_mutation(recipients: [@new_user2.id.to_s], body: "ooo eee", group_conversation: true, context_code: @course.asset_string)

      expect(result.dig("data", "createConversation", "conversations")).to be_nil
      expect(
        result.dig("data", "createConversation", "errors", 0, "message")
      ).to eql "Invalid recipients"
    end
  end

  context "user_notes" do
    before do
      Account.default.update_attribute(:enable_user_notes, true)
      @students = create_users_in_course(@course, 2, account_associations: true, return_type: :record)
    end

    context "when the deprecate_faculty_journal feature flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "creates user notes" do
        run_mutation({ recipients: @students.map { |u| u.id.to_s }, body: "yo", subject: "greetings", user_note: true, context_code: @course.asset_string }, @teacher)
        @students.each { |x| expect(x.user_notes.size).to be(1) }
        expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.faculty_journal.react")
      end

      it "includes the domain root account in the user note" do
        run_mutation({ recipients: @students.map { |u| u.id.to_s }, body: "hi there", subject: "hi there", user_note: true, context_code: @course.asset_string }, @teacher)
        note = UserNote.last
        expect(note.root_account_id).to eql Account.default.id
      end
    end

    context "when the deprecate_faculty_journal feature flag is enabled" do
      it "does not create user notes" do
        run_mutation({ recipients: @students.map { |u| u.id.to_s }, body: "yo", subject: "greetings", user_note: true, context_code: @course.asset_string }, @teacher)
        @students.each { |x| expect(x.user_notes.size).to be(0) }
        expect(InstStatsd::Statsd).to_not have_received(:increment).with("inbox.conversation.sent.faculty_journal.react")
      end
    end
  end

  describe "for recipients the sender has no relationship with" do
    it "fails for normal users" do
      result = run_mutation(recipients: [User.create.id.to_s], body: "foo")

      expect(result.dig("data", "createConversation", "conversations")).to be_nil
      expect(
        result.dig("data", "createConversation", "errors", 0, "message")
      ).to eql "Invalid recipients"
    end

    it "succeeds for siteadmins with send_messages and read_roster grants" do
      result = run_mutation({ recipients: [User.create.id.to_s], body: "foo" }, site_admin_user)

      expect(
        result.dig("data", "createConversation", "conversations", 0, "conversation", "conversationMessagesConnection", "nodes", 0, "body")
      ).to eql "foo"
      expect(InstStatsd::Statsd).to have_received(:increment).with("inbox.conversation.sent.account_context.react")
    end
  end
end
