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

require "nokogiri"

describe Announcement do
  it "creates a new instance given valid attributes" do
    @context = Course.create
    @context.announcements.create!(valid_announcement_attributes)
  end

  context "with attachment associations" do
    before do
      course_model
      @course.root_account.enable_feature!(:file_association_access)

      @attachment1 = attachment_with_context(@course)
      @attachment2 = attachment_with_context(@course)

      html_with_attachments = <<~HTML.strip
        <p>Announcement content</p>
        <p><a href="/courses/#{@course.id}/files/#{@attachment1.id}/download">file 1</a></p>
        <img src="/courses/#{@course.id}/files/#{@attachment2.id}/preview">
      HTML

      announcement_model(context: @course, message: html_with_attachments, updating_user: @teacher)
    end

    it "creates attachment associations for parent topic" do
      expect(@a.attachment_associations.count).to eq 2
    end
  end

  describe "locking" do
    it "locks if its course has the lock_all_announcements setting" do
      course_with_student(active_all: true)
      teacher_in_course(active_all: true)

      @course.lock_all_announcements = true
      @course.save!

      # should not trigger an update callback by re-saving inside a before_save
      expect_any_instance_of(Announcement).not_to receive(:clear_streams_if_not_published)
      announcement = @course.announcements.create!(valid_announcement_attributes)

      expect(announcement).to be_locked
      expect(announcement.grants_right?(@student, :reply)).to be_falsey
      expect(announcement.grants_right?(@teacher, :reply)).to be_falsey
    end

    it "does not lock if its course does not have the lock_all_announcements setting" do
      course_with_student(active_all: true)

      announcement = @course.announcements.create!(valid_announcement_attributes)

      expect(announcement).not_to be_locked
      expect(announcement.grants_right?(@student, :reply)).to be_truthy
    end

    it "does not automatically lock if it is a delayed post" do
      course = Course.new
      course.lock_all_announcements = true
      course.save!
      announcement = course.announcements.build(valid_announcement_attributes.merge(delayed_post_at: 1.week.from_now))
      announcement.workflow_state = "post_delayed"
      announcement.save!

      expect(announcement).to be_post_delayed
    end

    it "creates a single job for delayed posting even though we do a double-save" do
      course = Course.new
      course.lock_all_announcements = true
      course.save!
      expect do
        course.announcements.create!(valid_announcement_attributes.merge(delayed_post_at: 1.week.from_now))
      end.to change(Delayed::Job, :count).by(1)
    end

    it "unlocks the attachment when the job runs" do
      course_factory(active_all: true)
      att = attachment_model(context: @course)
      announcement = @course.announcements.create!(valid_announcement_attributes
        .merge(delayed_post_at: 1.week.from_now, workflow_state: "post_delayed", attachment: att))
      att.reload
      expect(att).to be_locked

      Timecop.freeze(2.weeks.from_now) do
        run_jobs
        expect(announcement.reload).to be_active
        expect(att.reload).to_not be_locked
      end
    end
  end

  context "section specific announcements" do
    before(:once) do
      course_with_teacher(active_course: true)
      @section = @course.course_sections.create!(name: "test section")

      @announcement = @course.announcements.create!(user: @teacher, message: "hello my favorite section!")
      @announcement.is_section_specific = true
      @announcement.course_sections = [@section]
      @announcement.save!

      @student1, @student2 = create_users(2, return_type: :record)
      @course.enroll_student(@student1, enrollment_state: "active")
      @course.enroll_student(@student2, enrollment_state: "active")
      student_in_section(@section, user: @student1)
    end

    it "is visible to students in specific section" do
      expect(@announcement.visible_for?(@student1)).to be_truthy
    end

    it "is visible to section-limited students in specific section" do
      @student1.enrollments.where(course_section_id: @section).update_all(limit_privileges_to_course_section: true)
      expect(@announcement.visible_for?(@student1)).to be_truthy
    end

    it "is not visible to students not in specific section" do
      expect(@announcement.visible_for?(@student2)).to be_falsey
    end
  end

  context "multi-section announcement visibility" do
    before(:once) do
      course_with_teacher(active_course: true)
      @section_a = @course.default_section
      @section_b = @course.course_sections.create!(name: "Section B")
      @section_c = @course.course_sections.create!(name: "Section C")

      @student_a = user_factory(name: "Student A", active_all: true)
      @student_b = user_factory(name: "Student B", active_all: true)
      @student_ab = user_factory(name: "Student AB", active_all: true)

      student_in_section(@section_a, user: @student_a)
      student_in_section(@section_b, user: @student_b)
      @course.enroll_student(@student_ab, section: @section_a, enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_student(@student_ab, section: @section_b, enrollment_state: "active", allow_multiple_enrollments: true)
    end

    it "announcement for section A+B is visible to students in either section" do
      announcement = @course.announcements.create!(
        user: @teacher,
        message: "For sections A and B"
      )
      announcement.is_section_specific = true
      announcement.course_sections = [@section_a, @section_b]
      announcement.save!

      expect(announcement.visible_for?(@student_a)).to be_truthy
      expect(announcement.visible_for?(@student_b)).to be_truthy
      expect(announcement.visible_for?(@student_ab)).to be_truthy
    end

    it "filters announcements correctly for student in multiple sections" do
      ann_a = @course.announcements.create!(user: @teacher, message: "Section A only")
      ann_a.is_section_specific = true
      ann_a.course_sections = [@section_a]
      ann_a.save!

      ann_b = @course.announcements.create!(user: @teacher, message: "Section B only")
      ann_b.is_section_specific = true
      ann_b.course_sections = [@section_b]
      ann_b.save!

      ann_c = @course.announcements.create!(user: @teacher, message: "Section C only")
      ann_c.is_section_specific = true
      ann_c.course_sections = [@section_c]
      ann_c.save!

      expect(ann_a.visible_for?(@student_ab)).to be_truthy
      expect(ann_b.visible_for?(@student_ab)).to be_truthy
      expect(ann_c.visible_for?(@student_ab)).to be_falsey
    end
  end

  context "permissions" do
    it "does not allow announcements on a course" do
      course_with_student(active_user: 1)
      expect(Announcement.context_allows_user_to_create?(@course, @user, {})).to be_falsey
    end

    it "does not allow announcements creation by students on a group" do
      course_with_student
      group_with_user(is_public: true, active_user: 1, context: @course)
      expect(Announcement.context_allows_user_to_create?(@group, @student, {})).to be_falsey
    end

    it "allows announcements creation by teacher on a group" do
      course_with_teacher(active_all: true)
      group_with_user(is_public: true, active_user: 1, context: @course)
      expect(Announcement.context_allows_user_to_create?(@group, @teacher, {})).to be_truthy
    end

    it "allows announcements to be viewed without :read_forum" do
      course_with_student(active_all: true)
      @course.account.role_overrides.create!(permission: "read_forum", role: student_role, enabled: false)
      a = @course.announcements.create!(valid_announcement_attributes)
      expect(a.grants_right?(@user, :read)).to be(true)
    end

    it "does not allow announcements to be viewed without :read_announcements" do
      course_with_student(active_all: true)
      @course.account.role_overrides.create!(permission: "read_announcements", role: student_role, enabled: false)
      a = @course.announcements.create!(valid_announcement_attributes)
      expect(a.grants_right?(@user, :read)).to be(false)
    end

    it "does not allow announcements to be viewed without :read_announcements (even with moderate_forum)" do
      course_with_teacher(active_all: true)
      @course.account.role_overrides.create!(permission: "read_announcements", role: teacher_role, enabled: false)
      a = @course.announcements.create!(valid_announcement_attributes)
      expect(a.grants_right?(@user, :read)).to be(false)
    end

    it "does allows announcements to be viewed only if visible_for? is true" do
      course_with_student(active_all: true)
      a = @course.announcements.create!(valid_announcement_attributes)
      allow(a).to receive(:visible_for?).and_return true
      expect(a.grants_right?(@user, :read)).to be(true)
    end

    it "does not allow announcements to be viewed if visible_for? is false" do
      course_with_student(active_all: true)
      a = @course.announcements.create!(valid_announcement_attributes)
      allow(a).to receive(:visible_for?).and_return false
      expect(a.grants_right?(@user, :read)).to be(false)
    end
  end

  context "broadcast policy" do
    context "sanitization" do
      before :once do
        announcement_model
      end

      it "sanitizes message" do
        @a.message = "<a href='#' onclick='alert(12);'>only this should stay</a>"
        @a.save!
        expect(@a.message).to eql("<a href=\"#\">only this should stay</a>")
      end

      it "sanitizes objects in a message" do
        @a.message = "<object data=\"http://www.youtuube.com/test\" othertag=\"bob\"></object>"
        @a.save!
        dom = Nokogiri(@a.message)
        expect(dom.css("object").length).to be(1)
        expect(dom.css("object")[0]["data"]).to eql("http://www.youtuube.com/test")
        expect(dom.css("object")[0]["othertag"]).to be_nil
      end
    end

    it "broadcasts to students and observers" do
      course_with_student(active_all: true)
      course_with_observer(course: @course, active_all: true)

      notification_name = "New Announcement"
      Notification.create(name: notification_name, category: "TestImmediately")
      Notification.create(name: "Announcement Created By You", category: "TestImmediately")

      communication_channel(@teacher, { username: "test_channel_email_#{@teacher.id}@test.com", active_cc: true })

      @context = @course
      announcement_model(user: @teacher)

      to_users = @a.messages_sent[notification_name].map(&:user)
      expect(to_users).to include(@student)
      expect(to_users).to include(@observer)
      expect(@a.messages_sent["Announcement Created By You"].map(&:user)).to include(@teacher)
    end

    it "does send a notification to the creator of the announcement after update" do
      course_with_student(active_all: true)
      Notification.create(name: "Announcement Created By You", category: "TestImmediately")

      communication_channel(@teacher, { username: "test_channel_email_#{@teacher.id}@test.com", active_cc: true })

      @context = @course
      announcement_model(user: @teacher, notify_users: true)
      expect(@a.messages_sent["Announcement Created By You"].map(&:user)).to include(@teacher)

      message = "Updated message"
      @a.update(message:)

      sent_messages = @a.messages_sent["Announcement Created By You"].select { |m| m.id.present? }

      expect(sent_messages.size).to eq(2)
      expect(sent_messages.map(&:user)).to include(@teacher)
      expect(sent_messages[1].body).to include(message)
    end

    it "does not broadcast if read_announcements is diabled" do
      Account.default.role_overrides.create!(role: student_role, permission: "read_announcements", enabled: false)
      course_with_student(active_all: true)
      notification_name = "New Announcement"
      n = Notification.create(name: notification_name, category: "TestImmediately")
      NotificationPolicy.create(notification: n, communication_channel: @student.communication_channel, frequency: "immediately")

      @context = @course
      announcement_model(user: @teacher)

      expect(@a.messages_sent[notification_name]).to be_blank
    end

    it "does not broadcast if student's section is soft-concluded" do
      course_with_student(active_all: true)
      section2 = @course.course_sections.create!
      other_student = user_factory(active_all: true)
      @course.enroll_student(other_student, section: section2, enrollment_state: "active")
      section2.update(start_at: 2.months.ago, end_at: 1.month.ago, restrict_enrollments_to_section_dates: true)

      notification_name = "New Announcement"
      n = Notification.create(name: notification_name, category: "TestImmediately")
      NotificationPolicy.create(notification: n, communication_channel: @student.communication_channel, frequency: "immediately")

      @context = @course
      announcement_model(user: @teacher)
      to_users = @a.messages_sent[notification_name].map(&:user)
      expect(to_users).to include(@student)
      expect(to_users).to_not include(other_student)
    end

    it "does not broadcast if it just got edited to active, if notify_users is false" do
      course_with_student(active_all: true)
      notification_name = "New Announcement"
      Notification.create(name: notification_name, category: "TestImmediately")

      announcement_model(user: @teacher, workflow_state: :post_delayed, notify_users: false, context: @course)

      expect do
        @a.publish!
      end.not_to change { @a.messages_sent[notification_name] }
    end

    it "still broadcasts if it just got edited to active, if notify_users is true" do
      course_with_student(active_all: true)
      notification_name = "New Announcement"
      Notification.create(name: notification_name, category: "TestImmediately")

      announcement_model(user: @teacher, workflow_state: :post_delayed, notify_users: true, context: @course)

      expect do
        @a.publish!
      end.to change { @a.messages_sent[notification_name] }
    end

    it "still broadcasts on delayed_post event even if notify_users was false" do
      course_with_student(active_all: true)
      notification_name = "New Announcement"
      Notification.create(name: notification_name, category: "TestImmediately")

      announcement_model(user: @teacher, workflow_state: :post_delayed, notify_users: false, context: @course)

      expect do
        @a.delayed_post
      end.to change { @a.messages_sent[notification_name] }
    end

    context "with different locked_for states" do
      it "does not broadcast on update if announcement is locked_for user" do
        course_with_student(active_all: true)
        notification_name = "New Announcement"
        Notification.create(name: notification_name, category: "TestImmediately")
        pseudo_teacher_role = @course.account.roles.create!(
          name: "Pseudo Teacher",
          base_role_type: "TeacherEnrollment"
        )
        @course.account.role_overrides.create!(permission: "moderate_forum", role: pseudo_teacher_role, enabled: false)

        pseudo_teacher = user_factory(active_all: true)
        # pseudo teacher have been enrolled as a teacher but only has read permissions
        # hence they should not receive announcements that are locked (unlock_at in future)
        @course.enroll_user(pseudo_teacher, "TeacherEnrollment", role: pseudo_teacher_role, enrollment_state: "active")
        communication_channel(pseudo_teacher)
        announcement = @course.announcements.create!(user: @teacher, message: "Test", title: "Test", unlock_at: 1.week.from_now)
        to_users = announcement.messages_sent[notification_name]&.map(&:user) || []
        expect(to_users).not_to include(pseudo_teacher)
      end

      it "does broadcast if announcement is locked for comments" do
        # the locked_for? method returns a hash if the user is only able to see the announcement but not comment
        course_with_student(active_all: true)
        notification_name = "New Announcement"
        Notification.create(name: notification_name, category: "TestImmediately")
        second_teacher = user_factory(active_all: true)
        @course.enroll_teacher(second_teacher, enrollment_state: "active")
        announcement_model(user: @teacher, context: @course, locked: true)
        expect(@a.messages_sent[notification_name].map(&:user)).to include(@student)
        expect(@a.messages_sent[notification_name].map(&:user)).to include(second_teacher)
      end
    end
  end

  describe "show_in_search_for_user?" do
    shared_examples_for "expected_values_for_teacher_student" do |teacher_expected, student_expected|
      it "returns #{teacher_expected} for teacher" do
        expect(announcement.show_in_search_for_user?(@teacher)).to eq(teacher_expected)
      end

      it "returns #{student_expected} for student" do
        expect(announcement.show_in_search_for_user?(@student)).to eq(student_expected)
      end
    end

    let(:announcement) { @course.announcements.create!(message: "announcement") }

    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it_behaves_like "expected_values_for_teacher_student", true, true

    context "when locked" do
      let(:announcement) { @course.announcements.create!(message: "announcement", locked: true) }

      it_behaves_like "expected_values_for_teacher_student", true, false
    end
  end

  describe "participant creation" do
    before do
      course_with_teacher(active_all: true)
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user
      @student3 = student_in_course(active_all: true).user
    end

    it "creates participants for all course students when announcement is created" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher))

      # Author should have participant record
      author_participant = announcement.discussion_topic_participants.find_by(user: @teacher)
      expect(author_participant).to be_present
      expect(author_participant.workflow_state).to eq("read")
      expect(author_participant.unread_entry_count).to eq(0)

      # All students should have participant records
      [@student1, @student2, @student3].each do |student|
        participant = announcement.discussion_topic_participants.find_by(user: student)
        expect(participant).to be_present
        expect(participant.workflow_state).to eq("unread")
        expect(participant.unread_entry_count).to eq(1)
        expect(participant.subscribed).to be_falsey
        expect(participant.root_account_id).to eq(announcement.root_account_id)
      end
    end

    it "does not create participants for course students when delayed_post_at is set" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher, delayed_post_at: 1.day.from_now, workflow_state: "post_delayed"))

      # Author should have participant record
      author_participant = announcement.discussion_topic_participants.find_by(user: @teacher)
      expect(author_participant).to be_present
      expect(author_participant.workflow_state).to eq("read")
      expect(author_participant.unread_entry_count).to eq(0)

      # Students should not have participant records yet for delayed announcements
      [@student1, @student2, @student3].each do |student|
        participant = announcement.discussion_topic_participants.find_by(user: student)
        expect(participant).to be_nil
      end
    end

    it "creates participants for course students when delayed announcement becomes active" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher, delayed_post_at: 1.day.from_now, workflow_state: "post_delayed"))

      # Initially, students should NOT have participant records
      [@student1, @student2, @student3].each do |student|
        participant = announcement.discussion_topic_participants.find_by(user: student)
        expect(participant).to be_nil
      end

      # Simulate time passing and the delayed job running
      Timecop.travel(2.days.from_now) do
        announcement.delayed_post
        announcement.save!
      end

      # Now students should have participant records
      [@student1, @student2, @student3].each do |student|
        participant = announcement.discussion_topic_participants.find_by(user: student)
        expect(participant).to be_present
        expect(participant.workflow_state).to eq("unread")
        expect(participant.unread_entry_count).to eq(1)
        expect(participant.subscribed).to be_falsey
        expect(participant.root_account_id).to eq(announcement.root_account_id)
      end
    end

    it "does not create duplicate participants if called multiple times" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher))
      initial_count = announcement.discussion_topic_participants.count

      # Call the method again (simulating edge case) - should handle gracefully
      expect { announcement.send(:create_participants_for_course) }.not_to raise_error

      # Should not create duplicates due to unique constraint handling
      expect(announcement.discussion_topic_participants.count).to eq(initial_count)
    end

    it "only creates participants for announcements, not regular discussions" do
      regular_discussion = @course.discussion_topics.create!(
        title: "Regular Discussion",
        message: "This is not an announcement",
        user: @teacher
      )

      # Only author should have participant record
      expect(regular_discussion.discussion_topic_participants.count).to eq(1)
      expect(regular_discussion.discussion_topic_participants.first.user).to eq(@teacher)
    end

    it "handles courses with no students gracefully" do
      empty_course = course_factory
      teacher = teacher_in_course(course: empty_course, active_all: true).user

      announcement = empty_course.announcements.create!(valid_announcement_attributes.merge(user: teacher))

      # Only author should have participant record
      expect(announcement.discussion_topic_participants.count).to eq(1)
      expect(announcement.discussion_topic_participants.first.user).to eq(teacher)
    end

    it "works with large numbers of students" do
      # Create 50 additional students (already have 3 from setup)
      50.times { student_in_course(course: @course, active_all: true) }

      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher))

      # Should have participants for all active enrollments (students, teachers, TAs, etc.)
      total_active_enrollments = @course.enrollments.active.count
      expect(announcement.discussion_topic_participants.count).to eq(total_active_enrollments)

      # All non-author participants should be unread
      non_author_participants = announcement.discussion_topic_participants.where.not(user: @teacher)
      expected_non_author_count = total_active_enrollments - 1 # exclude the teacher/author
      expect(non_author_participants.count).to eq(expected_non_author_count)
      expect(non_author_participants.pluck(:workflow_state).uniq).to eq(["unread"])
    end

    it "excludes the author from bulk participant creation" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher))

      # Teacher should have exactly one participant record (not duplicated)
      teacher_participants = announcement.discussion_topic_participants.where(user: @teacher)
      expect(teacher_participants.count).to eq(1)
      expect(teacher_participants.first.workflow_state).to eq("read")
    end

    it "sets correct default values for bulk-created participants" do
      announcement = @course.announcements.create!(valid_announcement_attributes.merge(user: @teacher))

      student_participant = announcement.discussion_topic_participants.find_by(user: @student1)
      expect(student_participant.workflow_state).to eq("unread")
      expect(student_participant.unread_entry_count).to eq(1)
      expect(student_participant.subscribed).to be_falsey
      expect(student_participant.root_account_id).to eq(announcement.root_account_id)
    end

    context "with group context" do
      before do
        @group = group_with_user(user: @teacher, active_all: true).group
        @group.add_user(@student1, "active")
      end

      it "does not create bulk participants for group announcements" do
        announcement = @group.announcements.create!(valid_announcement_attributes.merge(user: @teacher))

        # Only author should have participant record for group announcements
        expect(announcement.discussion_topic_participants.count).to eq(1)
        expect(announcement.discussion_topic_participants.first.user).to eq(@teacher)
      end
    end

    describe "#bulk_insert_participants" do
      before do
        @isolated_course = course_factory
        @isolated_teacher = teacher_in_course(course: @isolated_course, active_all: true).user
        @isolated_student1 = student_in_course(course: @isolated_course, active_all: true).user
        @isolated_student2 = student_in_course(course: @isolated_course, active_all: true).user

        @announcement = @isolated_course.announcements.build(valid_announcement_attributes.merge(user: @isolated_teacher, workflow_state: "active"))
        @announcement.save!(validate: false) # Skip callbacks to test method directly
      end

      it "does nothing when given no user IDs" do
        initial_count = @announcement.discussion_topic_participants.count
        expect { @announcement.send(:bulk_insert_participants, []) }.not_to raise_error
        # No new participants should be created, count remains the same
        expect(@announcement.discussion_topic_participants.count).to eq(initial_count)
      end

      it "creates participants with correct attributes when called directly" do
        # Clear any existing participants first to ensure clean state
        @announcement.discussion_topic_participants.destroy_all

        @announcement.send(:bulk_insert_participants, [@isolated_student1.id, @isolated_student2.id])

        participants = @announcement.discussion_topic_participants.where(user: [@isolated_student1, @isolated_student2])
        expect(participants.count).to eq(2)

        participants.each do |participant|
          expect(participant.discussion_topic_id).to eq(@announcement.id)
          expect(participant.workflow_state).to eq("unread")
          expect(participant.unread_entry_count).to eq(1)
          expect(participant.subscribed).to be_falsey
          expect(participant.root_account_id).to eq(@announcement.root_account_id)
        end
      end
    end
  end

  describe "section-specific participant creation and updates" do
    before do
      course_with_teacher(active_all: true)

      # Create two sections
      @section1 = @course.course_sections.create!(name: "Section 1")
      @section2 = @course.course_sections.create!(name: "Section 2")

      # Create students in each section
      @student1 = user_model(name: "Student 1")
      @student2 = user_model(name: "Student 2")

      @course.enroll_student(@student1, enrollment_state: "active", section: @section1)
      @course.enroll_student(@student2, enrollment_state: "active", section: @section2)
    end

    it "creates participants only for users in specified sections when section-specific" do
      announcement = @course.announcements.build(valid_announcement_attributes.merge(user: @teacher))
      announcement.is_section_specific = true
      announcement.course_sections = [@section1]
      announcement.save!

      # Should only create participants for teacher + section1 students
      expected_users = [@teacher, @student1]

      expected_users.each do |user|
        participant = announcement.discussion_topic_participants.find_by(user:)
        expect(participant).to be_present
      end

      # Student2 should not have participants
      participant = announcement.discussion_topic_participants.find_by(user: @student2)
      expect(participant).to be_nil
    end

    describe "#sync_participants_with_visibility" do
      before do
        @announcement = @course.announcements.build(valid_announcement_attributes.merge(user: @teacher))
        @announcement.is_section_specific = true
        @announcement.course_sections = [@section1]
        @announcement.save!
      end

      it "does not fail when a participant already exists" do
        expect(@announcement.discussion_topic_participants.find_by(user: @student1)).to be_present

        expect { @announcement.send(:sync_participants_with_visibility) }.not_to raise_error

        expect(@announcement.discussion_topic_participants.where(user: @student1).count).to eq(1)
      end

      it "handles race conditions where participant is created between check and insert" do
        expect(@announcement.discussion_topic_participants.find_by(user: @student1)).to be_present

        allow(@announcement.discussion_topic_participants).to receive(:pluck).and_call_original
        allow(@announcement.discussion_topic_participants).to receive(:pluck).with(:user_id).and_return([])
        expect { @announcement.send(:sync_participants_with_visibility) }.not_to raise_error

        # Should still have exactly one participant for @student1
        expect(@announcement.discussion_topic_participants.where(user: @student1).count).to eq(1)
      end
    end

    describe "participant updates on section changes" do
      before do
        @announcement = @course.announcements.build(valid_announcement_attributes.merge(user: @teacher))
        @announcement.is_section_specific = true
        @announcement.course_sections = [@section1]
        @announcement.save!
      end

      it "adds participants when sections are added" do
        initial_participant_count = @announcement.discussion_topic_participants.count

        @announcement.instance_variable_set(:@sections_changed, true)
        @announcement.discussion_topic_section_visibilities.create!(course_section: @section2)
        @announcement.save!

        new_participant_count = @announcement.discussion_topic_participants.count
        expect(new_participant_count).to be > initial_participant_count

        participant = @announcement.discussion_topic_participants.find_by(user: @student2)
        expect(participant).to be_present
      end

      it "removes participants when sections are removed" do
        @announcement.instance_variable_set(:@sections_changed, true)
        @announcement.discussion_topic_section_visibilities.create!(course_section: @section2)
        @announcement.save!

        expect(@announcement.discussion_topic_participants.where(user: [@student1, @student2]).count).to eq(2)

        # Remove section2 visibility
        @announcement.discussion_topic_section_visibilities.find_by(course_section: @section2).destroy
        @announcement.save!
        @announcement.instance_variable_set(:@sections_changed, true)

        # Should only have participants for section1
        expect(@announcement.discussion_topic_participants.find_by(user: @student1)).to be_present
        expect(@announcement.discussion_topic_participants.find_by(user: @student2)).to be_nil
      end

      it "adds participants when is_section_specific is changed to false" do
        @announcement.discussion_topic_section_visibilities.find_by(course_section: @section1).destroy
        @announcement.is_section_specific = false
        @announcement.course_sections = []
        @announcement.save!

        expect(@announcement.discussion_topic_participants.where(user: [@student1, @student2]).count).to eq(2)
      end
    end
  end

  describe "accessibility scan" do
    let(:course) { course_model }

    it_behaves_like "an accessibility scannable resource" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
        Account.site_admin.enable_feature!(:a11y_checker_ga2_features)
      end

      let(:course) { course_model }
      let(:valid_attributes) { { title: "Test Page", message: "Initial message", course: } }
      let(:relevant_attributes_for_scan) { { message: "<p>Lorem ipsum</p>" } }
      let(:irrelevant_attributes_for_scan) { { lock_at: 1.week.ago } }
    end

    context "when a11y_checker_additional_resources is disabled" do
      before do
        Account.site_admin.disable_feature!(:a11y_checker_additional_resources)
        course.root_account.enable_feature!(:a11y_checker)
        course.enable_feature!(:a11y_checker_eap)
        Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
      end

      it "does not trigger accessibility scan for announcements on create" do
        expect(Accessibility::ResourceScannerService).not_to receive(:call)

        Announcement.create!(title: "Test Announcement", message: "Test message", course:)
      end

      it "does not trigger accessibility scan for announcements on update" do
        announcement = Announcement.create!(title: "Test Announcement", message: "Test message", course:)

        expect(Accessibility::ResourceScannerService).not_to receive(:call)

        announcement.update!(message: "Updated message")
      end

      it "triggers destroy when deleting announcement" do
        announcement = Announcement.create!(title: "Test Announcement", message: "Test message", course:)
        AccessibilityResourceScan.create!(context: announcement, course:)

        expect { announcement.destroy! }.to change { AccessibilityResourceScan.where(announcement_id: announcement.id).count }.from(1).to(0)
      end
    end

    context "when a11y_checker_additional_resources is enabled" do
      before do
        Account.site_admin.enable_feature!(:a11y_checker_additional_resources)
        course.root_account.enable_feature!(:a11y_checker)
        course.enable_feature!(:a11y_checker_eap)
        Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
      end

      it "triggers accessibility scan on create" do
        expect(Accessibility::ResourceScannerService).to receive(:call).with(resource: an_instance_of(Announcement))

        Announcement.create!(title: "Test Announcement", message: "Test message", course:)
      end

      it "triggers accessibility scan on update" do
        announcement = Announcement.create!(title: "Test Announcement", message: "Test message", course:)

        expect(Accessibility::ResourceScannerService).to receive(:call).with(resource: an_instance_of(Announcement))

        announcement.update!(message: "Updated message")
      end

      it "triggers destroy when deleting announcement" do
        announcement = Announcement.create!(title: "Test Announcement", message: "Test message", course:)

        expect { announcement.destroy! }.to change { AccessibilityResourceScan.where(announcement_id: announcement.id).count }.from(1).to(0)
      end
    end
  end
end
