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

describe CourseSection, "moving to new course" do
  it "generates placeholder submissions for the students being cross-listed" do
    account = Account.create!
    course = account.courses.create!
    section = course.course_sections.create!
    student = User.create!
    course.enroll_student(student, enrollment_state: "active", section:)
    new_course = account.courses.create!
    assignment = new_course.assignments.create!

    expect { section.move_to_course(new_course) }.to change {
      assignment.submissions.where(user_id: student).count
    }.from(0).to(1)
  end

  it "transfers enrollments to the new root account" do
    account1 = Account.create!(name: "1")
    account2 = Account.create!(name: "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    course3 = account2.courses.create!
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course1.enroll_user(u, "StudentEnrollment", section: cs)
    e.workflow_state = "active"
    e.save!
    course1.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)

    cs.move_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).not_to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account2)
    expect(e.course).to eql(course2)

    cs.move_to_course(course3)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).not_to be_nil
    expect(e.root_account).to eql(account2)
    expect(e.course).to eql(course3)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)
  end

  it "associates a section with the course's account" do
    account = Account.default.manually_created_courses_account
    course = account.courses.create!
    section = course.default_section
    expect(section.course_account_associations.map(&:account_id).sort).to eq [Account.default.id, account.id].sort
  end

  it "updates user account associations for xlist between subaccounts" do
    root_account = Account.create!(name: "root")
    sub_account1 = Account.create!(parent_account: root_account, name: "account1")
    sub_account2 = Account.create!(parent_account: root_account, name: "account2")
    sub_account3 = Account.create!(parent_account: root_account, name: "account3")
    course1 = sub_account1.courses.create!(name: "course1")
    course2 = sub_account2.courses.create!(name: "course2")
    course3 = sub_account3.courses.create!(name: "course3")
    cs = course1.course_sections.create!
    expect(cs.nonxlist_course_id).to be_nil
    u = User.create!
    u.register!
    course1.enroll_user(u, "StudentEnrollment", section: cs)
    u.update_account_associations

    expect(course1.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort

    cs.crosslist_to_course(course2)
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts(include_crosslisted_courses: false).map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course2.reload.associated_accounts(include_crosslisted_courses: true).map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account2.id].sort

    cs.crosslist_to_course(course3)
    expect(cs.nonxlist_course_id).to eq course1.id
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts(include_crosslisted_courses: false).map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    expect(course3.reload.associated_accounts(include_crosslisted_courses: true).map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account3.id].sort

    cs.uncrosslist
    expect(cs.nonxlist_course_id).to be_nil
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id]
  end

  it "crosslists and uncrosslist" do
    account1 = Account.create!(name: "1")
    account2 = Account.create!(name: "2")
    account3 = Account.create!(name: "3")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    course3 = account3.courses.create!
    course2.assert_section
    course3.assert_section
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course2.enroll_user(u, "StudentEnrollment")
    e.workflow_state = "active"
    e.save!
    e = course1.enroll_user(u, "StudentEnrollment", section: cs)
    e.workflow_state = "active"
    e.save!
    # should also move deleted enrollments
    e.destroy
    course1.reload
    course2.reload
    course3.workflow_state = "active"
    course3.save
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to be_nil
    expect(e.root_account).to eql(account1)
    expect(cs.crosslisted?).to be_falsey
    expect(course1.workflow_state).to eq "created"
    expect(course2.workflow_state).to eq "created"
    expect(course3.workflow_state).to eq "created"

    cs.crosslist_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).not_to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to eql(course1)
    expect(e.root_account).to eql(account2)
    expect(cs.crosslisted?).to be_truthy
    expect(course1.workflow_state).to eq "created"
    expect(course2.workflow_state).to eq "created"
    expect(course3.workflow_state).to eq "created"

    cs.crosslist_to_course(course3)
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).not_to be_nil
    expect(cs.nonxlist_course).to eql(course1)
    expect(e.root_account).to eql(account3)
    expect(cs.crosslisted?).to be_truthy
    expect(course1.workflow_state).to eq "created"
    expect(course2.workflow_state).to eq "created"
    expect(course3.workflow_state).to eq "created"

    cs.uncrosslist
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to be_nil
    expect(e.root_account).to eql(account1)
    expect(cs.crosslisted?).to be_falsey
    expect(course1.workflow_state).to eq "created"
    expect(course2.workflow_state).to eq "created"
    expect(course3.workflow_state).to eq "created"
  end

  it "preserves favorites when crosslisting" do
    account1 = Account.create!(name: "1")
    account2 = Account.create!(name: "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    course2.assert_section

    cs = course1.course_sections.create!
    u = user_factory(active_all: true)
    course1.enroll_user(u, "StudentEnrollment", section: cs, enrollment_state: "active")
    u.favorites.where(context_type: "Course", context_id: course1).first_or_create!

    cs.crosslist_to_course(course2)
    expect(u.favorites.where(context_type: "Course", context_id: course2).exists?).to be true
  end

  it "removes discussion visibilites on crosslist" do
    course = course_factory({ course_name: "Course 1", active_all: true })
    section = course.course_sections.create!
    course.save!
    announcement1 = Announcement.create!(title: "some topic",
                                         message: "blah",
                                         context: course,
                                         is_section_specific: true,
                                         course_sections: [section])
    visibility = announcement1.reload.discussion_topic_section_visibilities.first

    course2 = course_factory
    section.crosslist_to_course(course2)

    expect(visibility.reload).to be_deleted
    expect(section.reload).to be_valid
  end

  describe "#delete_enrollments_if_deleted" do
    let(:account) { Account.create!(name: "1") }
    let(:course) { account.courses.create! }
    let(:section) { course.course_sections.create!(workflow_state: "active") }

    before do
      student_in_section(section)
    end

    it "must not have any effect when the section's workflow_state is not 'deleted'" do
      section.delete_enrollments_if_deleted
      enrollment_states = section.enrollments.pluck(:workflow_state)
      expect(enrollment_states).to_not include "deleted"
    end

    it "must mark the enrollments as deleted if the section's workflow_state is 'deleted'" do
      section.workflow_state = "deleted"
      section.delete_enrollments_if_deleted
      enrollment_states = Enrollment.where(course_section_id: section.id).pluck(:workflow_state)
      expect(enrollment_states.uniq).to contain_exactly "deleted"
    end
  end

  it "updates course account associations on save" do
    account1 = Account.create!(name: "1")
    account2 = account1.sub_accounts.create!(name: "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    cs1 = course1.course_sections.create!
    expect(CourseAccountAssociation.where(course_id: course1).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    course1.account = account2
    course1.save
    expect(CourseAccountAssociation.where(course_id: course1).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id].sort
    expect(CourseAccountAssociation.where(course_id: course2).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    course1.account = nil
    course1.save
    expect(CourseAccountAssociation.where(course_id: course1).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    cs1.crosslist_to_course(course2)
    expect(CourseAccountAssociation.where(course_id: course1).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).distinct.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id].sort
  end

  it "calls SubmissionLifecycleManager.recompute_users_for_course" do
    account1 = Account.create!(name: "1")
    account2 = Account.create!(name: "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course1.enroll_user(u, "StudentEnrollment", section: cs)
    e.workflow_state = "active"
    e.save!
    course1.reload

    expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course)
      .with([u.id], course2, nil, update_grades: true, executing_user: nil)
    cs.move_to_course(course2)
  end

  describe "validation" do
    before :once do
      course = Course.create_unique
      @section = CourseSection.create(course:)
      @long_string = "qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm"
    end

    it "validates the length of attributes" do
      @section.name = @long_string
      @section.sis_source_id = @long_string
      expect { @section.save! }.to raise_error("Validation failed: Sis source is too long (maximum is 255 characters), Name is too long (maximum is 255 characters)")
    end

    it "validates the length of sis_source_id" do
      @section.sis_source_id = @long_string
      expect { @section.save! }.to raise_error("Validation failed: Sis source is too long (maximum is 255 characters)")
    end

    it "validates the length of section name" do
      @section.name = @long_string
      expect { @section.save! }.to raise_error("Validation failed: Name is too long (maximum is 255 characters)")
    end
  end

  describe "dependent destroys" do
    before :once do
      course_with_teacher
      @course.assignments.build
      @assignment = @course.assignments.build("title" => "test")
      @assignment.save!
      @section = @course.course_sections.create!
    end

    it "softs destroy overrides when destroyed" do
      @override = @assignment.assignment_overrides.build
      @override.set = @section
      @override.save!
      expect(@override.workflow_state).to eq("active")
      @section.destroy
      @override.reload
      expect(@override.workflow_state).to eq("deleted")
    end

    it "softs destroy enrollments when destroyed" do
      @enrollment = @course.enroll_student(User.create, { section: @section })
      expect(@enrollment.workflow_state).to eq("creation_pending")
      @section.destroy
      @enrollment.reload
      expect(@enrollment.workflow_state).to eq("deleted")
    end

    it "clears gradebook filters for the section when destroyed" do
      teacher = @course.enroll_teacher(User.create, enrollment_state: :active).user
      teacher.set_preference(
        :gradebook_settings,
        @course.global_id,
        { "filter_rows_by" => { "section_id" => @section.id.to_s } }
      )

      expect { @section.destroy }.to change {
        settings = teacher.reload.get_preference(:gradebook_settings, @course.global_id)
        settings.dig("filter_rows_by", "section_id")
      }.from(@section.id.to_s).to(nil)
    end

    it "doesn't clear gradebook filters for other sections when destroyed" do
      new_section = @course.course_sections.create!
      teacher = @course.enroll_teacher(User.create, enrollment_state: :active).user
      teacher.set_preference(
        :gradebook_settings,
        @course.global_id,
        { "filter_rows_by" => { "section_id" => new_section.id.to_s } }
      )

      expect { @section.destroy }.not_to change {
        settings = teacher.reload.get_preference(:gradebook_settings, @course.global_id)
        settings.dig("filter_rows_by", "section_id")
      }.from(new_section.id.to_s)
    end

    it "doesn't associate with deleted discussion topics" do
      course = course_factory({ course_name: "Course 1", active_all: true })
      section = course.course_sections.create!
      course.save!
      announcement1 = Announcement.create!(
        title: "some topic",
        message: "I announce that i am lying",
        user: @teacher,
        context: course,
        workflow_state: "published"
      )
      announcement1.is_section_specific = true
      announcement2 = Announcement.create!(
        title: "some topic 2",
        message: "I announce that i am lying again",
        user: @teacher,
        context: course,
        workflow_state: "published"
      )
      announcement2.is_section_specific = true
      announcement1.discussion_topic_section_visibilities <<
        DiscussionTopicSectionVisibility.new(
          discussion_topic: announcement1,
          course_section: section
        )
      announcement2.discussion_topic_section_visibilities <<
        DiscussionTopicSectionVisibility.new(
          discussion_topic: announcement2,
          course_section: section
        )
      announcement1.save!
      announcement2.save!
      expect(section.discussion_topics.length).to eq 2
      announcement2.destroy
      section.reload
      expect(section.discussion_topics.length).to eq 1
      expect(section.discussion_topics.first.id).to eq announcement1.id
    end
  end

  describe "deletable?" do
    before :once do
      course_with_teacher
      @section = @course.course_sections.create!
    end

    it "is deletable if empty" do
      expect(@section).to be_deletable
    end

    it "is not deletable if it has real enrollments" do
      student_in_course section: @section
      expect(@section).not_to be_deletable
    end

    it "is deletable if it only has a student view enrollment" do
      @course.student_view_student
      expect(@section.enrollments.map(&:type)).to eql ["StudentViewEnrollment"]
      expect(@section).to be_deletable
    end

    it "is deletable if it only has rejected enrollments" do
      student_in_course section: @section
      @section.enrollments.first.update_attribute(:workflow_state, "rejected")
      expect(@section).to be_deletable
    end
  end

  context "permissions" do
    context ":read and section_visibilities" do
      before do
        RoleOverride.create!({
                               context: Account.default,
                               permission: "manage_students",
                               role: ta_role,
                               enabled: false
                             })
        course_with_ta(active_all: true)
        @other_section = @course.course_sections.create!(name: "Other Section")
      end

      it "works with section_limited true" do
        @ta.enrollments.update_all(limit_privileges_to_course_section: true)
        @ta.reload

        # make sure other ways to get :read are false
        expect(@other_section.course.grants_right?(@ta, :manage_sections_add)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_sections_edit)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_sections_delete)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_students)).to be_falsey

        expect(@other_section.grants_right?(@ta, :read)).to be_falsey
      end

      it "works with section_limited false" do
        # make sure other ways to get :read are false
        expect(@other_section.course.grants_right?(@ta, :manage_sections_add)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_sections_edit)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_sections_delete)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_students)).to be_falsey

        expect(@other_section.grants_right?(@ta, :read)).to be_truthy
      end
    end

    context ":manage_calendar" do
      before :once do
        @course1 = course_factory(active_all: true)
        @section1 = @course1.default_section
        @section2 = @course1.course_sections.create!
        @user = user_factory(active_all: true)
      end

      it "returns true for teachers, designers, and tas by default" do
        @course1.enroll_teacher(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
        @user.enrollments.destroy_all

        @course1.enroll_designer(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
        @user.enrollments.destroy_all

        @course1.enroll_ta(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
      end

      it "returns false for students and observers by default" do
        @course1.enroll_student(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
        @user.enrollments.destroy_all

        @course1.enroll_user(@user, "ObserverEnrollment", enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      it "returns false for teacher if RoleOverride disables :manage_calendar" do
        RoleOverride.create!(context: Account.default, permission: "manage_calendar", role: teacher_role, enabled: false)
        @course1.enroll_teacher(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      it "returns true if user has any role where :manage_calendar is enabled" do
        RoleOverride.create!(context: Account.default, permission: "manage_calendar", role: ta_role, enabled: false)
        @course1.enroll_teacher(@user, enrollment_state: :active)
        @course1.enroll_ta(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
      end

      it "returns appropriate permission for custom role" do
        limited_teacher_role = custom_teacher_role("Limited teacher", account: Account.default)
        RoleOverride.create!(context: Account.default, permission: "manage_calendar", role: limited_teacher_role, enabled: false)
        @course1.enroll_teacher(@user, role: limited_teacher_role, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      it "returns true for all sections if enrolled in one and not section_limited" do
        @course1.enroll_teacher(@user, enrollment_state: :active, section: @section2)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
      end

      it "returns false for limited section if only enrolled in one and section_limited" do
        @course1.enroll_teacher(@user, enrollment_state: :active, section: @section2)
        @user.enrollments.update_all(limit_privileges_to_course_section: true)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
      end

      it "returns false for a teacher in another course" do
        course2 = course_factory(active_all: true)
        course2.enroll_teacher(@user, enrollment_state: :active)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      it "returns false if teacher enrollment is concluded" do
        @course1.enroll_teacher(@user, enrollment_state: :completed)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      it "returns true for an admin whose account membership grants :manage_calendar" do
        account_admin_user(account: @course1.account, user: @user)
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_truthy
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_truthy
      end

      it "returns false for an admin whose account membership does not grant :manage_calendar" do
        account_admin_user_with_role_changes(account: @course1.account, user: @user, role_changes: { manage_calendar: false })
        expect(@section1.grants_right?(@user, :manage_calendar)).to be_falsey
        expect(@section2.grants_right?(@user, :manage_calendar)).to be_falsey
      end

      context "with sharding" do
        specs_require_sharding

        it "returns true for a section on another shard than the user (if the user has permission)" do
          @shard2.activate do
            account2 = Account.create!
            course_with_teacher(account: account2, user: @user, active_all: true)
          end
          section = @course.course_sections.first
          expect(section.grants_right?(@user, :manage_calendar)).to be_truthy
        end
      end
    end
  end

  context "enrollment state invalidation" do
    before :once do
      course_factory(active_all: true)
      @section = @course.course_sections.create!
      @enrollment = @course.enroll_student(user_factory(active_all: true), section: @section)
    end

    it "does not invalidate unless something date-related changes" do
      expect(EnrollmentState).not_to receive(:update_enrollment)
      @section.name = "durp"
      @section.save!
    end

    it "does not invalidate if dates change if it isn't restricted to dates yet" do
      expect(EnrollmentState).not_to receive(:update_enrollment)
      @section.start_at = 1.day.from_now
      @section.save!
    end

    it "invalidates if dates change and section is restricted to dates" do
      @section.restrict_enrollments_to_section_dates = true
      @section.save!
      expect(EnrollmentState).to receive(:update_enrollment).with(@enrollment).once
      @section.start_at = 1.day.from_now
      @section.save!
    end

    it "invalidates if cross-listed" do
      other_course = course_factory(active_all: true)
      expect(EnrollmentState).to receive(:update_enrollment).with(@enrollment).once
      @section.crosslist_to_course(other_course)
    end

    it "invalidates access if section is cross-listed" do
      @course.update(workflow_state: "available",
                     restrict_student_future_view: true,
                     restrict_enrollments_to_course_dates: true,
                     start_at: 1.day.from_now)
      expect(@enrollment.enrollment_state.reload.restricted_access?).to be true

      other_course = course_factory(active_all: true)
      other_course.update(restrict_enrollments_to_course_dates: true, start_at: 1.day.from_now)

      @section.crosslist_to_course(other_course)

      expect(@enrollment.enrollment_state.reload.restricted_access?).to be false
    end
  end

  it "delegates account to course" do
    course = course_model(account_id: Account.default)
    section = course.course_sections.create!
    expect(section.account).to eq(Account.default)
  end

  describe "republish_course_pace_if_needed" do
    before :once do
      course_factory(active_all: true)
      @section = @course.course_sections.create!
      @section_course_pace = @course.course_paces.create!(course_section_id: @section.id)
      @section_course_pace.publish
    end

    it "does nothing if course paces aren't turned on" do
      @section.update(start_at: 1.day.from_now)
      expect(Delayed::Job.where(singleton: "course_pace_publish:#{@section_course_pace.global_id}")).not_to exist
    end

    context "with course paces enabled" do
      before :once do
        @course.enable_course_paces = true
        @course.save!
      end

      it "doesn't queue an update if the course pace isn't published" do
        @section_course_pace.update workflow_state: "unpublished"
        @section.update(start_at: 1.day.from_now)
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@section_course_pace.global_id}")).not_to exist
      end

      it "publishes a section course pace (alone) if it exists" do
        course_pace = @course.course_paces.create!
        course_pace.publish
        @section.start_at = 2.days.from_now
        @section.save!
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@section_course_pace.global_id}")).to exist
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{course_pace.global_id}")).not_to exist
      end

      it "doesn't queue an update for irrelevant changes" do
        @section.name = "Test Name"
        @section.save!
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@section_course_pace.global_id}")).not_to exist
      end
    end
  end
end
