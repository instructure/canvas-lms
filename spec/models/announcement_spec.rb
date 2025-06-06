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

    include_examples "expected_values_for_teacher_student", true, true

    context "when locked" do
      let(:announcement) { @course.announcements.create!(message: "announcement", locked: true) }

      include_examples "expected_values_for_teacher_student", true, false
    end
  end
end
