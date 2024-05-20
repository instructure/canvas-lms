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

require "feedjira"
require_relative "../helpers/k5_common"

describe CoursesController do
  include K5Common

  describe "GET 'index'" do
    before do
      controller.instance_variable_set(:@domain_root_account, Account.default)
    end

    def get_index(user = nil)
      user_session(user) if user
      user ||= @user
      controller.instance_variable_set(:@current_user, user)
      controller.load_enrollments_for_index
      get "index"
    end

    it "forces login" do
      course_with_student(active_all: true)
      get "index"
      expect(response).to be_redirect
    end

    it "assigns variables" do
      course_with_student_logged_in(active_all: true)
      get_index
      expect(response).to be_successful
      expect(assigns[:current_enrollments]).not_to be_nil
      expect(assigns[:current_enrollments]).not_to be_empty
      expect(assigns[:current_enrollments][0]).to eql(@enrollment)
      expect(assigns[:past_enrollments]).not_to be_nil
      expect(assigns[:future_enrollments]).not_to be_nil
      expect(assigns[:js_env][:CREATE_COURSES_PERMISSIONS][:PERMISSION]).to be_nil
      expect(assigns[:js_env][:CREATE_COURSES_PERMISSIONS][:RESTRICT_TO_MCC_ACCOUNT]).to be_falsey
    end

    it "does not duplicate enrollments in variables" do
      course_with_student_logged_in(active_all: true)
      course_factory
      @course.start_at = Time.now + 2.weeks
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @course.offer!
      @course.enroll_student(@user)
      get_index
      expect(response).to be_successful
      assigns[:future_enrollments].each do |e|
        expect(assigns[:current_enrollments]).not_to include e
      end
    end

    it "sets k5_theme when k5 is enabled" do
      course_with_student_logged_in
      toggle_k5_setting(@course.account)

      get_index @student
      expect(assigns[:js_bundles].flatten).to include :k5_theme
      expect(assigns[:css_bundles].flatten).to include :k5_theme, :k5_font
    end

    it "does not set k5_theme when k5 is off" do
      course_with_student_logged_in

      get_index @student
      expect(assigns[:js_bundles].flatten).not_to include :k5_theme
      expect(assigns[:css_bundles].flatten).not_to include :k5_theme, :k5_font
    end

    it "does not include k5_font css bundle if use_classic_font? is true" do
      course_with_student_logged_in
      toggle_k5_setting(@course.account)
      toggle_classic_font_setting(@course.account)

      get_index @student
      expect(assigns[:css_bundles].flatten).to include :k5_theme
      expect(assigns[:css_bundles].flatten).not_to include :k5_font
    end

    describe "homeroom courses" do
      before :once do
        @account = Account.default
        @account.enable_as_k5_account!

        @teacher1 = user_factory(active_all: true, account: @account)
        @student1 = user_factory(active_all: true, account: @account)

        @subject = course_factory(account: @account, course_name: "Subject", active_all: true)
        @homeroom = course_factory(account: @account, course_name: "Homeroom", active_all: true)
        @homeroom.homeroom_course = true
        @homeroom.save!

        @subject.enroll_teacher(@teacher1).accept!
        @subject.enroll_student(@student1).accept!
        @homeroom.enroll_teacher(@teacher1).accept!
        @homeroom.enroll_student(@student1).accept!
      end

      it "is not included for students" do
        controller.instance_variable_set(:@current_user, @student1)
        controller.load_enrollments_for_index
        expect(assigns[:current_enrollments].length).to be 1
        expect(assigns[:current_enrollments][0].course.name).to eq "Subject"
      end

      it "is included for teachers" do
        controller.instance_variable_set(:@current_user, @teacher1)
        controller.load_enrollments_for_index
        expect(assigns[:current_enrollments].length).to be 2
      end

      it "is included for users with teacher and student enrollments" do
        course_factory(active_all: true)
        @course.enroll_teacher(@student1).accept!
        controller.instance_variable_set(:@current_user, @student1)
        controller.load_enrollments_for_index
        expect(assigns[:current_enrollments].length).to be 3
      end
    end

    describe "current_enrollments" do
      it "groups enrollments by course and type" do
        # enrollments with multiple sections of the same type should be de-duped
        course_factory(active_all: true)
        user_factory(active_all: true)
        sec1 = @course.course_sections.create!(name: "section1", end_at: 1.week.ago)
        sec2 = @course.course_sections.create!(name: "section2")
        ens = []
        ens << @course.enroll_student(@user, section: sec1, allow_multiple_enrollments: true)
        ens << @course.enroll_student(@user, section: sec2, allow_multiple_enrollments: true)
        ens << @course.enroll_teacher(@user, section: sec2, allow_multiple_enrollments: true)
        ens.each(&:accept!)

        ens[1].conclude # the current enrollment should take precedence over the concluded one

        user_session(@user)
        get_index
        expect(response).to be_successful
        current_ens = assigns[:current_enrollments]
        expect(current_ens.count).to be(2)

        student_e = current_ens.detect(&:student?)
        teacher_e = current_ens.detect(&:teacher?)
        expect(student_e.course_section).to eq sec2 # pick the "current" one
        expect(teacher_e.course_section).to eq sec2

        expect(assigns[:past_enrollments]).to eql([])
        expect(assigns[:future_enrollments]).to eql([])
      end

      it "includes courses with no applicable start/end dates" do
        # no dates at all
        enrollment1 = student_in_course active_all: true, course_name: "A"

        course2 = Account.default.courses.create! start_at: 2.weeks.ago,
                                                  conclude_at: 1.week.from_now,
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "B"
        course2.offer!
        enrollment2 = student_in_course user: @student, course: course2, active_all: true

        # future date that doesn't count
        course3 = Account.default.courses.create! start_at: 1.week.from_now,
                                                  conclude_at: 2.weeks.from_now,
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "C"
        course3.offer!
        enrollment3 = student_in_course user: @student, course: course3, active_all: true

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to eq [enrollment1, enrollment2, enrollment3]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "includes courses with current start/end dates" do
        course1 = Account.default.courses.create! start_at: 1.week.ago,
                                                  conclude_at: 1.week.from_now,
                                                  restrict_enrollments_to_course_dates: true,
                                                  name: "A"
        course1.offer!
        enrollment1 = student_in_course course: course1

        enrollment2 = course_with_student user: @student, course_name: "B", active_all: true
        current_term = Account.default.enrollment_terms.create! name: "current term", start_at: 1.month.ago, end_at: 1.month.from_now
        enrollment2.course.enrollment_term = current_term
        enrollment2.course.save!

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to eq [enrollment1, enrollment2]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "includes 'invited' enrollments, and list them before 'active'" do
        enrollment1 = course_with_student course_name: "Z"
        @student.register!
        @course.offer!
        enrollment1.invite!

        enrollment2 = course_with_student user: @student, course_name: "A", active_all: true

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to eq [enrollment1, enrollment2]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "includes unpublished courses" do
        enrollment = course_with_student
        expect(@course).to be_unpublished
        enrollment.invite!

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to eq [enrollment]
        expect(assigns[:future_enrollments]).to be_empty
      end

      describe "unpublished_courses" do
        it "lists unpublished courses after published" do
          # unpublished course
          course1 = Account.default.courses.create! name: "A"
          enrollment1 = course_with_student user: @student, course: course1
          enrollment1.invite!
          expect(course1).to be_unpublished

          # published course
          course2 = Account.default.courses.create! name: "Z"
          course2.offer!
          course_with_student course: course2, user: @student, active_all: true

          user_session(@student)
          get_index
          expect(assigns[:current_enrollments].map(&:course_id)).to eq [course2.id, course1.id]
        end
      end

      context "as enrollment admin" do
        it "includes courses with no applicable start/end dates" do
          # no dates at all
          enrollment1 = teacher_in_course active_all: true, course_name: "A"

          course2 = Account.default.courses.create! start_at: 2.weeks.ago,
                                                    conclude_at: 1.week.from_now,
                                                    restrict_enrollments_to_course_dates: false,
                                                    name: "B"
          course2.offer!
          enrollment2 = teacher_in_course user: @teacher, course: course2, active_all: true

          # future date that doesn't count
          course3 = Account.default.courses.create! start_at: 1.week.from_now,
                                                    conclude_at: 2.weeks.from_now,
                                                    restrict_enrollments_to_course_dates: false,
                                                    name: "C"
          course3.offer!
          enrollment3 = teacher_in_course user: @teacher, course: course3, active_all: true

          user_session(@teacher)
          get_index
          expect(response).to be_successful
          expect(assigns[:past_enrollments]).to be_empty
          expect(assigns[:current_enrollments]).to eq [enrollment1, enrollment2, enrollment3]
          expect(assigns[:future_enrollments]).to be_empty
        end
      end
    end

    describe "past_enrollments" do
      it "includes 'completed' courses" do
        enrollment1 = course_with_student active_all: true
        expect(enrollment1).to be_active
        enrollment1.course.complete!

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eql([enrollment1])
        expect(assigns[:current_enrollments]).to eql([])
        expect(assigns[:future_enrollments]).to eql([])
      end

      it "includes 'rejected' and 'completed' enrollments" do
        active_enrollment = course_with_student name: "active", active_course: true
        active_enrollment.accept!
        rejected_enrollment = course_with_student user: @student, course_name: "rejected", active_course: true
        rejected_enrollment.update_attribute(:workflow_state, "rejected")
        completed_enrollment = course_with_student user: @student, course_name: "completed", active_course: true
        completed_enrollment.update_attribute(:workflow_state, "completed")

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eq [completed_enrollment, rejected_enrollment]
        expect(assigns[:current_enrollments]).to eq [active_enrollment]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "prioritizes completed enrollments over inactive ones" do
        course_with_student(active_all: true)
        old_enroll = @student.enrollments.first

        section2 = @course.course_sections.create!
        inactive_enroll = @course.enroll_student(@student, section: section2, allow_multiple_enrollments: true)
        inactive_enroll.deactivate

        @course.update(start_at: 2.days.ago, conclude_at: 1.day.ago, restrict_enrollments_to_course_dates: true)

        user_session(@student)

        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eq [old_enroll]
      end

      it "includes 'active' enrollments whose term is past" do
        @student = user_factory

        # by course date, unrestricted
        course1 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.ago, # oh hey this already "ended" (not really because it's unrestricted) but whatever
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "One"
        course1.offer!
        enrollment1 = course_with_student course: course1, user: @student, active_all: true

        # by course date, restricted
        course2 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.ago,
                                                  restrict_enrollments_to_course_dates: true,
                                                  name: "Two"
        course2.offer!
        enrollment2 = course_with_student course: course2, user: @student, active_all: true

        # by enrollment term
        enrollment3 = course_with_student user: @student, course_name: "Three", active_all: true
        past_term = Account.default.enrollment_terms.create! name: "past term", start_at: 1.month.ago, end_at: 1.day.ago
        enrollment3.course.enrollment_term = past_term
        enrollment3.course.save!

        # by course date, unrestricted but the course dates aren't over yet
        course4 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.from_now,
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "Fore"
        course4.offer!
        enrollment4 = course_with_student course: course4, user: @student, active_all: true

        # by course date, unrestricted past view
        course5 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.ago,
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "Phive",
                                                  restrict_student_past_view: false
        course5.offer!
        enrollment5 = course_with_student course: course5, user: @student, active_all: true

        # by course date, restricted past view & enrollment dates
        course6 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.ago,
                                                  restrict_enrollments_to_course_dates: true,
                                                  name: "Styx",
                                                  restrict_student_past_view: true
        course6.offer!
        course_with_student course: course6, user: @student, active_all: true

        # past course date, restricted past view & enrollment dates not concluded
        course7 = Account.default.courses.create! start_at: 2.months.ago,
                                                  conclude_at: 1.month.ago,
                                                  restrict_enrollments_to_course_dates: false,
                                                  name: "Ptheven",
                                                  restrict_student_past_view: true
        course7.offer!
        enrollment7 = course_with_student course: course7, user: @student, active_all: true

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to match_array([enrollment7, enrollment5, enrollment3, enrollment2, enrollment1])
        expect(assigns[:current_enrollments]).to eq [enrollment4]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "does other terrible date logic based on sections" do
        @student = user_factory

        # section date in past
        course1 = Account.default.courses.create! start_at: 2.months.ago, conclude_at: 1.month.from_now
        course1.default_section.update(end_at: 1.month.ago)
        course1.offer!
        enrollment1 = course_with_student course: course1, user: @student, active_all: true

        # by section date, in future
        course2 = Account.default.courses.create! start_at: 2.months.ago, conclude_at: 1.month.ago
        course2.default_section.update(end_at: 1.month.from_now)
        course2.offer!
        enrollment2 = course_with_student course: course2, user: @student, active_all: true

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eq [enrollment1]
        expect(assigns[:current_enrollments]).to eq [enrollment2]
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "does even more terrible date logic based on sections" do
        @student = user_factory

        # both section dates in past
        course1 = Account.default.courses.create! start_at: 2.months.ago, conclude_at: 1.month.from_now
        course1.default_section.update(end_at: 1.month.ago)
        section2 = course1.course_sections.create!(end_at: 1.week.ago)
        course1.offer!
        course_with_student course: course1, user: @student, active_all: true
        course_with_student course: course1, section: section2, user: @student, active_all: true, allow_multiple_enrollments: true

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments].count).to eq 1
        expect(assigns[:past_enrollments].first.course).to eq course1
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "does not include hard-inactive enrollments even in the future" do
        course1 = Account.default.courses.create!(start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true)
        course1.offer!
        enrollment = course_with_student course: course1, user: @student, active_all: true
        enrollment.deactivate

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "does not include 'invited' enrollments whose term is past" do
        @student = user_factory

        # by enrollment term
        enrollment = course_with_student user: @student, course_name: "Three", active_course: true
        past_term = Account.default.enrollment_terms.create! name: "past term", start_at: 1.month.ago, end_at: 1.day.ago
        enrollment.course.enrollment_term = past_term
        enrollment.course.save!
        enrollment.reload

        expect(enrollment.workflow_state).to eq "invited"
        expect(enrollment).to_not be_invited # state_based_on_date

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "does not include the course if the caller is a student or observer and the course restricts students viewing courses after the end date" do
        course1 = Account.default.courses.create!(restrict_student_past_view: true)
        course1.offer!

        enrollment = course_with_student course: course1
        enrollment.accept!

        teacher = user_with_pseudonym(active_all: true)
        teacher_enrollment = course_with_teacher course: course1, user: teacher
        teacher_enrollment.accept!

        course1.start_at = 2.months.ago
        course1.conclude_at = 1.month.ago
        course1.save!

        course1.enrollment_term.update_attribute(:end_at, 1.month.ago)

        get_index(@student)
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty

        observer = user_with_pseudonym(active_all: true)
        add_linked_observer(@student, observer)
        get_index(observer)
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty

        get_index(teacher)
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eq [teacher_enrollment]
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty
      end

      it "includes the student's course when the course restricts students viewing courses after the end date if they're not actually soft-concluded" do
        course1 = Account.default.courses.create!(restrict_student_past_view: true)
        course1.offer!

        enrollment = course_with_student course: course1
        enrollment.accept!

        course1.start_at = 2.months.ago
        course1.conclude_at = 1.month.ago
        course1.save!

        course1.enrollment_term.update_attribute(:end_at, 1.month.from_now)

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to eq [enrollment]
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to be_empty
      end

      describe "unpublished_courses" do
        it "lists unpublished courses after published" do
          @student = user_factory

          # past unpublished course
          course1 = Account.default.courses.create! start_at: 2.months.ago, conclude_at: 1.month.ago, name: "A"
          course1.offer!
          enrollment1 = course_with_student course: course1, user: @student
          enrollment1.accept!
          course1.update! workflow_state: "created"

          # past published course
          course2 = Account.default.courses.create! start_at: 2.months.ago, conclude_at: 1.month.ago, name: "Z"
          course2.offer!
          course_with_student course: course2, user: @student, active_all: true

          user_session(@student)
          get_index
          expect(assigns[:past_enrollments].map(&:course_id)).to eq [course2.id, course1.id] # Z, then A
        end
      end
    end

    describe "future_enrollments" do
      it "includes courses with a start date in the future, regardless of published state" do
        # published course
        course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, name: "A"
        course1.offer!
        course_with_student course: course1

        # unpublished course
        course2 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, name: "B"
        expect(course2).to be_unpublished
        course_with_student user: @student, course: course2

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments].map(&:course_id)).to eq [course1.id, course2.id]

        observer = user_with_pseudonym(active_all: true)
        add_linked_observer(@student, observer)
        user_session(observer)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments].map(&:course_id)).to eq [course1.id, course2.id]
      end

      it "includes courses with accepted enrollments and future start dates" do
        course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, name: "A"
        course1.offer!
        student_in_course course: course1, active_all: true
        user_session(@student)
        get_index
        expect(assigns[:future_enrollments].map(&:course_id)).to eq [course1.id]
      end

      it "is not empty if the caller is a student or observer and the root account restricts students viewing courses before the start date" do
        course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true
        course1.offer!
        enrollment1 = course_with_student course: course1
        enrollment1.root_account.settings[:restrict_student_future_view] = true
        enrollment1.root_account.save!
        expect(course1.restrict_student_future_view?).to be_truthy # should inherit

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to eq [enrollment1]

        observer = user_with_pseudonym(active_all: true)
        add_linked_observer(@student, observer)
        user_session(observer)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to eq [observer.enrollments.first]

        teacher = user_with_pseudonym(active_all: true)
        teacher_enrollment = course_with_teacher course: course1, user: teacher
        user_session(teacher)
        get_index
        expect(response).to be_successful
        expect(assigns[:past_enrollments]).to be_empty
        expect(assigns[:current_enrollments]).to be_empty
        expect(assigns[:future_enrollments]).to eq [teacher_enrollment]
      end

      it "does not include published course enrollments if account disallows future view and listing" do
        Account.default.tap do |a|
          a.settings.merge!(restrict_student_future_view: true, restrict_student_future_listing: true)
          a.save!
        end

        course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, workflow_state: "available"
        enrollment1 = course_with_student course: course1
        expect(enrollment1.workflow_state).to eq "invited"
        expect(enrollment1.restrict_future_listing?).to be_truthy

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:future_enrollments]).to eq []
      end

      it "does not include unpublished course enrollments if account disallows future listing" do
        # even if it _would_ be accessible if it were published
        Account.default.tap do |a|
          a.settings.merge!(restrict_student_future_view: true, restrict_student_future_listing: true)
          a.save!
        end

        course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true
        course1.restrict_student_future_view = false
        course1.save!
        enrollment1 = course_with_student course: course1
        expect(enrollment1.workflow_state).to eq "creation_pending"
        expect(enrollment1.restrict_future_listing?).to be_truthy

        user_session(@student)
        get_index
        expect(response).to be_successful
        expect(assigns[:future_enrollments]).to eq []

        course1.offer!
        get_index
        expect(response).to be_successful
        expect(assigns[:future_enrollments]).to eq [enrollment1] # show it because it's accessible now
      end

      describe "unpublished_courses" do
        it "lists unpublished courses after published" do
          # unpublished course
          course1 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, name: "A"
          expect(course1).to be_unpublished
          course_with_student user: @student, course: course1

          # published course
          course2 = Account.default.courses.create! start_at: 1.month.from_now, restrict_enrollments_to_course_dates: true, name: "Z"
          course2.offer!
          course_with_student user: @student, course: course2

          user_session(@student)
          get_index
          expect(assigns[:future_enrollments].map(&:course_id)).to eq [course2.id, course1.id] # Z, then A
        end
      end
    end

    describe "per-assignment permissions" do
      let(:assignment_permissions) { assigns[:js_env][:PERMISSIONS][:by_assignment_id] }

      before do
        @course = Course.create!(default_view: "assignments")
        @teacher = course_with_user("TeacherEnrollment", course: @course, active_all: true).user
        @ta = course_with_user("TaEnrollment", course: @course, active_all: true).user
        @course.enable_feature!(:moderated_grading)

        @assignment = @course.assignments.create!(
          moderated_grading: true,
          grader_count: 2,
          final_grader: @teacher
        )

        ta_in_course(active_all: true)
      end

      it "sets the 'update' attribute to true when user is the final grader" do
        user_session(@teacher)
        get "show", params: { id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(true)
      end

      it "sets the 'update' attribute to true when user has the Select Final Grade permission" do
        user_session(@ta)
        get "show", params: { id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(true)
      end

      it "sets the 'update' attribute to false when user does not have the Select Final Grade permission" do
        @course.account.role_overrides.create!(permission: :select_final_grade, enabled: false, role: ta_role)
        user_session(@ta)
        get "show", params: { id: @course.id }
        expect(assignment_permissions[@assignment.id][:update]).to be(false)
      end
    end

    describe "Course notification settings" do
      before do
        @course = Course.create!(default_view: "assignments")
        @teacher = course_with_user("TeacherEnrollment", course: @course, active_all: true).user
      end

      it "shows the course notification settings page" do
        user_session(@teacher)
        get "show", params: { id: @course.id, view: "notifications" }
        expect(response).to be_successful
        expect(assigns[:js_bundles].flatten).to include(:course_notification_settings)
      end

      it "sets discussions_reporting to falsey if react_discussions_post is off" do
        @course.disable_feature! :react_discussions_post
        user_session(@user)
        get "show", params: { id: @course.id, view: "notifications" }
        expect(assigns[:js_env][:discussions_reporting]).to be_falsey
      end

      it "sets discussions_reporting to truthy if react_discussions_post is on" do
        @course.enable_feature! :react_discussions_post
        user_session(@user)
        get "show", params: { id: @course.id, view: "notifications" }
        expect(assigns[:js_env][:discussions_reporting]).to be_truthy
      end
    end
  end

  describe "GET 'statistics'" do
    it "does not break using new student_ids method from course" do
      course_with_teacher_logged_in(active_all: true)
      get "statistics", params: { course_id: @course.id }, format: "json"
      expect(response).to be_successful
    end
  end

  describe "observer_pairing_codes" do
    before :once do
      course_with_teacher(active_all: true)
      student = user_with_pseudonym(name: "Bob Jones", sis_user_id: "bobjones1")
      student_in_course(course: @course, user: student, active_all: true)
      @teacher.name = "teacher"
      @teacher.save!
    end

    it "returns unauthorized if self registration is off" do
      user_session(@teacher)
      @course.root_account.root_account.role_overrides.create!(role: teacher_role, enabled: true, permission: :generate_observer_pairing_code)
      ObserverPairingCode.create(user: @student, expires_at: 1.day.from_now, code: SecureRandom.hex(3))
      get :observer_pairing_codes_csv, params: { course_id: @course.id }
      expect(response).to be_unauthorized
    end

    it "returns unauthorized if role does not have permission" do
      user_session(@teacher)
      @course.root_account.root_account.role_overrides.create!(role: teacher_role, enabled: false, permission: :generate_observer_pairing_code)
      @teacher.account.canvas_authentication_provider.update_attribute(:self_registration, true)
      ObserverPairingCode.create(user: @student, expires_at: 1.day.from_now, code: SecureRandom.hex(3))
      get :observer_pairing_codes_csv, params: { course_id: @course.id }
      expect(response).to be_unauthorized
    end

    it "generates an observer pairing codes csv" do
      user_session(@teacher)
      @course.root_account.root_account.role_overrides.create!(role: teacher_role, enabled: true, permission: :generate_observer_pairing_code)
      @teacher.account.canvas_authentication_provider.update_attribute(:self_registration, true)
      get :observer_pairing_codes_csv, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(response.header["Content-Type"]).to eql("text/csv")
      headings = response.body.split("\n").first.split(",")
      row = response.body.split("\n").second.split(",")
      expect(headings).to eq(["Last Name", "First Name", "SIS ID", "Pairing Code", "Expires At"])
      expect(row).to eq(["Jones", "Bob", "bobjones1", "\"=\"\"#{ObserverPairingCode.last.code}\"\"\"", ObserverPairingCode.last.expires_at.to_s])
    end

    it "generates observer pairing codes only for students" do
      user_session(@teacher)
      @course.root_account.root_account.role_overrides.create!(role: teacher_role, enabled: true, permission: :generate_observer_pairing_code)
      @teacher.account.canvas_authentication_provider.update_attribute(:self_registration, true)
      get :observer_pairing_codes_csv, params: { course_id: @course.id }
      expect(response).to be_successful
      expect(response.header["Content-Type"]).to eql("text/csv")
      expect(response.body).to include(@student.first_name)
      expect(response.body.include?(@teacher.name)).to be_falsey
      expect(response.body.split(",").last.strip).to eql(ObserverPairingCode.last.expires_at.to_s)
      expect(response.body.split(",")[-2]).to include(ObserverPairingCode.last.code)
    end
  end

  describe "GET 'settings'" do
    subject do
      user_session user
      get "settings", params: { course_id: course.id }
    end

    let(:course) { @course }
    let(:user) { @teacher }

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "sets MSFT sync cooldown in the JS ENV" do
      subject
      expect(controller.js_env[:MANUAL_MSFT_SYNC_COOLDOWN]).to eq(
        MicrosoftSync::Group.manual_sync_cooldown
      )
    end

    it "sets MSFT enabled in the JS ENV" do
      subject
      expect(controller.js_env[:MSFT_SYNC_ENABLED]).to be false
    end

    it "sets MSFT enrollment limits in the JS ENV" do
      subject
      expect(controller.js_env[:MSFT_SYNC_MAX_ENROLLMENT_MEMBERS]).to eq(
        MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS
      )
      expect(controller.js_env[:MSFT_SYNC_MAX_ENROLLMENT_OWNERS]).to eq(
        MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS
      )
    end

    it "sets MSFT_SYNC_CAN_BYPASS_COOLDOWN in the JS ENV" do
      subject
      expect(controller.js_env[:MSFT_SYNC_CAN_BYPASS_COOLDOWN]).to be false
    end

    it "sets the external tools create url" do
      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:EXTERNAL_TOOLS_CREATE_URL]).to eq(
        "http://test.host/courses/#{@course.id}/external_tools"
      )
    end

    it "sets the tool configuration show url" do
      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:TOOL_CONFIGURATION_SHOW_URL]).to eq(
        "http://test.host/api/lti/courses/#{@course.id}/developer_keys/:developer_key_id/tool_configuration"
      )
    end

    it "sets tool creation permissions true for roles that are granted rights" do
      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:PERMISSIONS][:add_tool_manually]).to be(true)
    end

    it "does not set tool creation permissions for roles not granted rights" do
      user_session(@student)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:PERMISSIONS]).to be_nil
    end

    it "only sets course color js_env vars for elementary courses" do
      @course.account.enable_as_k5_account!
      @course.course_color = "#BAD"
      @course.save!

      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:COURSE_COLOR]).to eq "#BAD"
      expect(controller.js_env[:COURSE_COLORS_ENABLED]).to be true
    end

    it "does not set course color js_env vars for non-elementary courses" do
      @course.course_color = "#BAD"
      @course.save!

      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(controller.js_env[:COURSE_COLOR]).to be_falsy
      expect(controller.js_env[:COURSE_COLORS_ENABLED]).to be false
    end

    it "requires authorization" do
      get "settings", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "shoulds not allow students" do
      user_session(@student)
      get "settings", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "renders properly" do
      user_session(@teacher)
      get "settings", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(response).to render_template("settings")
    end

    it "gives a helpful error message for students that can't access yet" do
      user_session(@student)
      @course.workflow_state = "claimed"
      @course.save!
      get "settings", params: { course_id: @course.id }
      assert_status(401)
      expect(assigns[:unauthorized_reason]).to eq :unpublished
      expect(assigns[:unauthorized_message]).not_to be_nil

      @course.workflow_state = "available"
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      get "settings", params: { course_id: @course.id }
      assert_status(401)
      expect(assigns[:unauthorized_reason]).to eq :unpublished
      expect(assigns[:unauthorized_message]).not_to be_nil
    end

    it "does not record recent activity for unauthorize actions" do
      user_session(@student)
      @course.workflow_state = "available"
      @course.restrict_student_future_view = true
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.last_activity_at = nil
      @enrollment.save!
      get "settings", params: { course_id: @course.id }
      assert_status(401)
      expect(assigns[:unauthorized_reason]).to eq(:unpublished)
      expect(@enrollment.reload.last_activity_at).to be_nil
    end

    it "assigns active course_settings_sub_navigation external tools" do
      user_session(@teacher)
      shared_settings = { consumer_key: "test", shared_secret: "secret", url: "http://example.com/lti" }
      inactive_tool = @course.context_external_tools.create(shared_settings.merge(name: "inactive", course_settings_sub_navigation: { enabled: true }))
      active_tool = @course.context_external_tools.create(shared_settings.merge(name: "active", course_settings_sub_navigation: { enabled: true }))
      inactive_tool.workflow_state = "deleted"
      inactive_tool.save!

      get "settings", params: { course_id: @course.id }
      expect(assigns[:course_settings_sub_navigation_tools].size).to eq 1
      assigned_tool = assigns[:course_settings_sub_navigation_tools].first
      expect(assigned_tool.id).to eq active_tool.id
    end
  end

  describe "GET 'enrollment_invitation'" do
    it "rejects invitation for logged-in user" do
      course_with_student_logged_in(active_course: true)
      post "enrollment_invitation", params: { course_id: @course.id, reject: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(dashboard_url)
      expect(assigns[:pending_enrollment]).to eql(@enrollment)
      expect(assigns[:pending_enrollment]).to be_rejected
    end

    it "rejects invitation for not-logged-in user" do
      course_with_student(active_course: true, active_user: true)
      post "enrollment_invitation", params: { course_id: @course.id, reject: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(root_url)
      expect(assigns[:pending_enrollment]).to eql(@enrollment)
      expect(assigns[:pending_enrollment]).to be_rejected
    end

    it "rejects temporary invitation" do
      user_with_pseudonym(active_all: 1)
      user_session(@user, @pseudonym)
      user = User.create! { |u| u.workflow_state = "creation_pending" }
      user.communication_channels.create!(path: @cc.path)
      course_factory(active_all: true)
      @enrollment = @course.enroll_student(user)
      post "enrollment_invitation", params: { course_id: @course.id, reject: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(root_url)
      expect(assigns[:pending_enrollment]).to eql(@enrollment)
      expect(assigns[:pending_enrollment]).to be_rejected
    end

    it "does not reject invitation for bad parameters" do
      course_with_student(active_course: true, active_user: true)
      post "enrollment_invitation", params: { course_id: @course.id, reject: "1", invitation: "#{@enrollment.uuid}https://canvas.instructure.com/courses/#{@course.id}?invitation=#{@enrollment.uuid}" }
      expect(response).to be_redirect
      expect(response).to redirect_to(course_url(@course.id))
      expect(assigns[:pending_enrollment]).to be_nil
    end

    it "accepts invitation for logged-in user" do
      course_with_student_logged_in(active_course: true, active_user: true)
      post "enrollment_invitation", params: { course_id: @course.id, accept: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(course_url(@course.id))
      expect(assigns[:context_enrollment]).to eql(@enrollment)
      expect(assigns[:context_enrollment]).to be_active
    end

    it "asks user to login for registered not-logged-in user" do
      user_with_pseudonym(active_course: true, active_user: true)
      course_factory(active_all: true)
      @enrollment = @course.enroll_user(@user)
      post "enrollment_invitation", params: { course_id: @course.id, accept: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(login_url)
    end

    it "defers to registration_confirmation for pre-registered not-logged-in user" do
      user_with_pseudonym
      course_factory(active_course: true, active_user: true)
      @enrollment = @course.enroll_user(@user)
      post "enrollment_invitation", params: { course_id: @course.id, accept: "1", invitation: @enrollment.uuid }
      expect(response).to be_redirect
      expect(response).to redirect_to(registration_confirmation_url(@pseudonym.communication_channel.confirmation_code, enrollment: @enrollment.uuid))
    end

    it "defers to registration_confirmation if logged-in user does not match enrollment user" do
      user_with_pseudonym
      @u2 = @user
      course_with_student_logged_in(active_course: true, active_user: true)
      @e2 = @course.enroll_user(@u2)
      post "enrollment_invitation", params: { course_id: @course.id, accept: "1", invitation: @e2.uuid }
      expect(response).to redirect_to(registration_confirmation_url(nonce: @pseudonym.communication_channel.confirmation_code, enrollment: @e2.uuid))
    end

    it "asks user to login if logged-in user does not match enrollment user, and enrollment user doesn't have an e-mail" do
      user_factory
      @user.register!
      @u2 = @user
      course_with_student_logged_in(active_course: true, active_user: true)
      @e2 = @course.enroll_user(@u2)
      post "enrollment_invitation", params: { course_id: @course.id, accept: "1", invitation: @e2.uuid }
      expect(response).to redirect_to(login_url(force_login: 1))
    end

    it "accepts an enrollment for a restricted by dates course" do
      course_with_student_logged_in(active_all: true)

      @course.update(restrict_enrollments_to_course_dates: true,
                     start_at: Time.now + 2.weeks)
      @enrollment.update(workflow_state: "invited", last_activity_at: nil)

      post "enrollment_invitation", params: { course_id: @course.id,
                                              accept: "1",
                                              invitation: @enrollment.uuid }

      expect(response).to redirect_to(course_url(@course))
      @enrollment.reload
      expect(@enrollment.workflow_state).to eq("active")
      expect(@enrollment.last_activity_at).to be_nil
    end
  end

  describe "GET 'show'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      get "show", params: { id: @course.id }
      assert_unauthorized
    end

    it "does not find deleted courses" do
      user_session(@teacher)
      @course.destroy
      assert_page_not_found do
        get "show", params: { id: @course.id }
      end
    end

    it "assigns variables" do
      user_session(@student)
      get "show", params: { id: @course.id }
      expect(response).to be_successful
      expect(assigns[:context]).to eql(@course)
      expect(assigns[:modules].to_a).to eql([])
    end

    it "gives a helpful error message for students that can't access yet" do
      user_session(@student)
      @course.workflow_state = "claimed"
      @course.restrict_student_future_view = true
      @course.save!
      get "show", params: { id: @course.id }
      assert_status(401)
      expect(assigns[:unauthorized_reason]).to eq :unpublished
      expect(assigns[:unauthorized_message]).not_to be_nil

      @course.workflow_state = "available"
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      controller.instance_variable_set(:@js_env, nil)
      get "show", params: { id: @course.id }
      assert_status(401)
      expect(assigns[:unauthorized_reason]).to eq :unpublished
      expect(assigns[:unauthorized_message]).not_to be_nil
    end

    it "renders a flash with the appropriate param" do
      user_session(@teacher)
      get "show", params: { id: @course.id, for_reload: 1 }
      expect(flash[:notice]).to match(/Course was successfully updated./)
    end

    it "allows student view student to view unpublished courses" do
      @course.update_attribute :workflow_state, "claimed"
      user_session(@teacher)
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get "show", params: { id: @course.id }
      expect(response).to be_successful
    end

    it "does not allow student view students to view other courses" do
      course_with_teacher_logged_in(active_user: true)
      @c1 = @course

      course_factory(active_course: true)
      @c2 = @course

      @fake1 = @c1.student_view_student
      session[:become_user_id] = @fake1.id

      get "show", params: { id: @c2.id }
      assert_unauthorized
    end

    it "includes analytics 2 link if installed" do
      tool = analytics_2_tool_factory
      Account.default.enable_feature!(:analytics_2)

      get "show", params: { id: @course.id }
      expect(controller.course_custom_links).to include({
                                                          text: "Analytics 2",
                                                          url: "http://test.host/courses/#{@course.id}/external_tools/#{tool.id}?launch_type=course_navigation",
                                                          icon_class: "icon-analytics",
                                                          tool_id: ContextExternalTool::ANALYTICS_2
                                                        })
    end

    def check_course_show(should_show)
      controller.instance_variable_set(:@context_all_permissions, nil)
      controller.instance_variable_set(:@js_env, nil)

      get "show", params: { id: @course.id }
      if should_show
        expect(response).to be_successful
        expect(assigns[:context]).to eql(@course)
      else
        assert_status(401)
      end
    end

    it "shows unauthorized/authorized to a student for a future course depending on restrict_student_future_view setting" do
      course_with_student_logged_in(active_course: 1)

      @course.start_at = Time.now + 2.weeks
      @course.restrict_enrollments_to_course_dates = true
      @course.restrict_student_future_view = true
      @course.save!

      check_course_show(false)
      expect(assigns[:unauthorized_message]).not_to be_nil

      @course.restrict_student_future_view = false
      @course.save!

      check_course_show(true)
    end

    it "shows unauthorized/authorized to a student for a past course depending on restrict_student_past_view setting" do
      course_with_student_logged_in(active_course: 1)

      @course.start_at = 3.weeks.ago
      @course.conclude_at = 2.weeks.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.restrict_student_past_view = true
      @course.save!

      check_course_show(false)

      # manually completed
      @course.conclude_at = 2.weeks.from_now
      @course.save!
      @student.enrollments.first.complete!

      check_course_show(false)

      @course.restrict_student_past_view = false
      @course.save!

      check_course_show(true)
    end

    context "when default_view is `syllabus`" do
      before do
        course_with_student_logged_in(active_course: 1)
        @course.default_view = "syllabus"
        @course.syllabus_body = "<p>This is your syllabus.</p>"
        @course.save!
      end

      it "assigns syllabus_body" do
        get :show, params: { id: @course.id }
        expect(assigns[:syllabus_body]).not_to be_nil
      end

      it "assigns groups" do
        get :show, params: { id: @course.id }
        expect(assigns[:groups]).not_to be_nil
      end
    end

    context "show feedback for the current course only on course front page" do
      before(:once) do
        course_with_teacher(active_all: true)
        @course1 = @course
        student_in_course(active_all: true, course: @course1)
        @me = @user

        course_with_teacher(active_all: true, user: @teacher)
        @course2 = @course
        student_in_course(active_all: true, course: @course2, user: @me)

        @a1 = @course1.assignments.new(title: "some assignment course 1")
        @a1.workflow_state = "published"
        @a1.save
        @s1 = @a1.submit_homework(@student)
        @c1 = @s1.add_comment(author: @teacher, comment: "some comment1")

        # this shouldn't show up in any course 1 list
        @a2 = @course2.assignments.new(title: "some assignment course 2")
        @a2.workflow_state = "published"
        @a2.save
        @s2 = @a2.submit_homework(@student)
        @c2 = @s2.add_comment(author: @teacher, comment: "some comment2")
      end

      context "as a teacher" do
        before do
          @course1.update!(default_view: "assignments")
          student_in_course(active_all: true, course: @course1)
          @assignment = @course1.assignments.create!(due_at: 1.day.from_now)
          user_session(@teacher)
        end

        it "shows unpublished upcoming assignments" do
          @assignment.unpublish
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments)).to include @assignment
        end

        it "does not show duplicate upcoming assignments" do
          create_adhoc_override_for_assignment(@assignment, @me, due_at: 2.days.from_now)
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments).count).to eq 1
        end

        it "includes assignments where at least one assigned student has the assignment upcoming" do
          create_adhoc_override_for_assignment(@assignment, @me, due_at: 1.day.ago)
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments)).to include @assignment
        end

        it "excludes assignments where no assigned students have the assignment upcoming" do
          @assignment.update!(only_visible_to_overrides: true)
          create_adhoc_override_for_assignment(@assignment, @me, due_at: 1.day.ago)
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments)).not_to include @assignment
        end

        it "sorts assignments by their earliest upcoming due date, ascending" do
          create_adhoc_override_for_assignment(@assignment, @me, due_at: 3.days.from_now)
          later_assignment = @course1.assignments.create!(due_at: 2.days.from_now)
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments)).to eq [@assignment, later_assignment]
        end
      end

      context "as a student" do
        before do
          user_session(@me)
        end

        it "works for module view" do
          @course1.default_view = "modules"
          @course1.save
          get "show", params: { id: @course1.id }
          expect(assigns(:recent_feedback).count).to eq 1
          expect(assigns(:recent_feedback).first.assignment_id).to eq @a1.id
        end

        it "works for assignments view" do
          @course1.default_view = "assignments"
          @course1.save!
          get "show", params: { id: @course1.id }
          expect(assigns(:recent_feedback).count).to eq 1
          expect(assigns(:recent_feedback).first.assignment_id).to eq @a1.id
        end

        it "disables management and set env urls on assignment homepage" do
          @course1.default_view = "assignments"
          @course1.save!
          get "show", params: { id: @course1.id }
          expect(controller.js_env[:URLS][:new_assignment_url]).not_to be_nil
          expect(controller.js_env[:PERMISSIONS][:manage]).to be_falsey
        end

        it "sets ping_url" do
          get "show", params: { id: @course1.id }
          expect(controller.js_env[:ping_url]).not_to be_nil
        end

        it "does not show unpublished assignments to students" do
          @course1.default_view = "assignments"
          @course1.save!
          @a1a = @course1.assignments.new(title: "some assignment course 1", due_at: 1.day.from_now)
          @a1a.save
          @a1a.unpublish
          get "show", params: { id: @course1.id }
          expect(assigns(:upcoming_assignments).map(&:id).include?(@a1a.id)).to be_falsey
        end

        it "works for wiki view" do
          @course1.default_view = "wiki"
          @course1.save
          get "show", params: { id: @course1.id }
          expect(assigns(:recent_feedback).count).to eq 1
          expect(assigns(:recent_feedback).first.assignment_id).to eq @a1.id
        end

        it "works for wiki view with draft state enabled" do
          @course1.wiki_pages.create!(title: "blah").set_as_front_page!
          @course1.reload
          @course1.default_view = "wiki"
          @course1.save!
          get "show", params: { id: @course1.id }
          expect(controller.js_env[:WIKI_RIGHTS].symbolize_keys).to eql({ read: true })
          expect(controller.js_env[:PAGE_RIGHTS].symbolize_keys).to eql({ read: true })
          expect(controller.js_env[:COURSE_TITLE]).to eql @course1.name
        end

        it "works for wiki view with home page announcements enabled" do
          @course1.wiki_pages.create!(title: "blah").set_as_front_page!
          @course1.reload
          @course1.default_view = "wiki"
          @course1.show_announcements_on_home_page = true
          @course1.home_page_announcement_limit = 3
          @course1.save!
          get "show", params: { id: @course1.id }
          expect(controller.js_env[:COURSE_HOME]).to be_truthy
          expect(controller.js_env[:SHOW_ANNOUNCEMENTS]).to be_truthy
          expect(controller.js_env[:ANNOUNCEMENT_LIMIT]).to eq(3)
        end

        it "does not show announcements for public users" do
          @course1.wiki_pages.create!(title: "blah").set_as_front_page!
          @course1.reload
          @course1.default_view = "wiki"
          @course1.show_announcements_on_home_page = true
          @course1.home_page_announcement_limit = 3
          @course1.is_public = true
          @course1.save!
          remove_user_session
          get "show", params: { id: @course1.id }
          expect(response).to be_successful
          expect(controller.js_env[:COURSE_HOME]).to be_truthy
          expect(controller.js_env[:SHOW_ANNOUNCEMENTS]).to be_falsey
        end

        it "works for syllabus view" do
          @course1.default_view = "syllabus"
          @course1.save
          get "show", params: { id: @course1.id }
          expect(assigns(:recent_feedback).count).to eq 1
          expect(assigns(:recent_feedback).first.assignment_id).to eq @a1.id
        end

        it "works for feed view" do
          @course1.default_view = "feed"
          @course1.save
          get "show", params: { id: @course1.id }
          expect(assigns(:recent_feedback).count).to eq 1
          expect(assigns(:recent_feedback).first.assignment_id).to eq @a1.id
        end

        it "only shows recent feedback if user is student in specified course" do
          course_with_teacher(active_all: true, user: @student)
          @course3 = @course
          get "show", params: { id: @course3.id }
          expect(assigns(:show_recent_feedback)).to be_falsey
        end
      end
    end

    context "invitations" do
      before :once do
        Account.default.settings[:allow_invitation_previews] = true
        Account.default.save!
        course_with_teacher(active_course: true)
        @teacher_enrollment = @enrollment
        student_in_course(course: @course)
      end

      it "allows an invited user to see the course" do
        expect(@enrollment).to be_invited
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment
      end

      it "still shows unauthorized if unpublished, regardless of if previews are allowed" do
        # unpublished course with invited student in default account (allows previews)
        @course.workflow_state = "claimed"
        @course.save!

        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        assert_unauthorized
        expect(assigns[:unauthorized_message]).not_to be_nil

        # unpublished course with invited student in account that disallows previews
        @account = Account.create!
        course_with_student(account: @account)
        @course.workflow_state = "claimed"
        @course.save!

        controller.instance_variable_set(:@js_env, nil)
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        assert_unauthorized
        expect(assigns[:unauthorized_message]).not_to be_nil
      end

      it "does not show unauthorized for invited teachers when unpublished" do
        # unpublished course with invited teacher
        @course.workflow_state = "claimed"
        @course.save!

        get "show", params: { id: @course.id, invitation: @teacher_enrollment.uuid }
        expect(response).to be_successful
      end

      it "re-invites an enrollment that has previously been rejected" do
        expect(@enrollment).to be_invited
        @enrollment.reject!
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to be_successful
        @enrollment.reload
        expect(@enrollment).to be_invited
      end

      it "auto-accepts if previews are not allowed" do
        # Currently, previews are only allowed for the default account
        @account = Account.create!
        course_with_student_logged_in(active_course: 1, account: @account)
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to be_successful
        expect(response).to render_template("show")
        expect(assigns[:context_enrollment]).to eq @enrollment
        @enrollment.reload
        expect(@enrollment).to be_active
      end

      it "does not error when navigating to unpublished course after admin enrollment invitation" do
        account = Account.create!
        account.settings[:allow_invitation_previews] = false
        account.save!

        course_factory(account:)
        user_factory(active_all: true)
        enrollment = @course.enroll_teacher(@user, enrollment_state: "invited")
        user_session(@user)

        get "show", params: { id: @course.id }

        expect(response).to be_successful
        expect(response).to render_template("show")
        expect(assigns[:context_enrollment]).to eq enrollment
        expect(enrollment.reload).to be_active
      end

      it "ignores invitations that have been accepted (not logged in)" do
        @enrollment.accept!
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        assert_unauthorized
      end

      it "ignores invitations that have been accepted (logged in)" do
        @enrollment.accept!
        user_session(@student)
        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to be_nil
      end

      it "uses the invitation enrollment, rather than the current enrollment" do
        @student.register!
        user_session(@student)
        @student1 = @student
        @enrollment1 = @enrollment
        student_in_course
        expect(@enrollment).to be_invited

        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment
        expect(assigns[:current_user]).to eq @student1
        expect(session[:enrollment_uuid]).to eq @enrollment.uuid
        expect(session[:permissions_key]).not_to be_nil
        @enrollment.reload
        expect(@enrollment).to be_invited

        controller.instance_variable_set(:@js_env, nil)
        get "show", params: { id: @course.id } # invitation should be in the session now
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment
        expect(assigns[:current_user]).to eq @student1
        expect(session[:enrollment_uuid]).to eq @enrollment.uuid
        expect(session[:permissions_key]).not_to be_nil
        @enrollment.reload
        expect(@enrollment).to be_invited
      end

      it "auto-redirects to registration page when it's a self-enrollment" do
        @user = User.new
        cc = @user.communication_channels.build(path: "jt@instructure.com")
        cc.user = @user
        @user.workflow_state = "creation_pending"
        @user.save!
        @enrollment = @course.enroll_student(@user)
        @enrollment.update_attribute(:self_enrolled, true)
        expect(@enrollment).to be_invited

        get "show", params: { id: @course.id, invitation: @enrollment.uuid }
        expect(response).to redirect_to(registration_confirmation_url(@user.email_channel.confirmation_code, enrollment: @enrollment.uuid))
      end

      it "does not use the session enrollment if it's for the wrong course" do
        @enrollment1 = @enrollment
        @course1 = @course
        course_factory(active_course: 1)
        student_in_course(user: @user)
        @enrollment2 = @enrollment
        @course2 = @course
        user_session(@user)

        get "show", params: { id: @course1.id }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment1
        expect(session[:enrollment_uuid]).to eq @enrollment1.uuid
        expect(session[:permissions_key]).not_to be_nil
        permissions_key = session[:permissions_key]

        controller.instance_variable_set(:@pending_enrollment, nil)
        controller.instance_variable_set(:@js_env, nil)
        get "show", params: { id: @course2.id }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment2
        expect(session[:enrollment_uuid]).to eq @enrollment2.uuid
        expect(session[:permissions_key]).not_to eq permissions_key
      end

      it "finds temporary enrollments that match the logged in user" do
        @temporary = User.create! { |u| u.workflow_state = "creation_pending" }
        @temporary.communication_channels.create!(path: "user@example.com")
        @enrollment = @course.enroll_student(@temporary)
        @user = user_with_pseudonym(active_all: 1, username: "user@example.com")
        expect(@enrollment).to be_invited
        user_session(@user)

        get "show", params: { id: @course.id }
        expect(response).to be_successful
        expect(assigns[:pending_enrollment]).to eq @enrollment
      end
    end

    it "sets ENV.COURSE_ID for assignments view" do
      course_with_teacher_logged_in(active_all: true)
      @course.default_view = "assignments"
      @course.save!
      get "show", params: { id: @course.id }
      expect(assigns(:js_env)[:COURSE_ID]).to eq @course.id.to_s
    end

    it "sets new_quizzes flags for assignments view" do
      course_with_teacher_logged_in(active_all: true)
      @course.default_view = "assignments"
      @course.save!
      get "show", params: { id: @course.id }
      expect(assigns(:js_env)[:FLAGS].keys).to include :newquizzes_on_quiz_page
    end

    it "sets speed grader link flags for assignments view" do
      course_with_teacher_logged_in(active_all: true)
      @course.default_view = "assignments"
      @course.save!
      get "show", params: { id: @course.id }
      expect(assigns(:js_env)[:FLAGS].keys).to include :show_additional_speed_grader_link
    end

    it "redirects html to settings page when user can :read_as_admin, but not :read" do
      # an account user on the site admin will always have :read_as_admin
      # permission to any course, but will not have :read permission unless
      # they've been granted the :read_course_content role override, which
      # defaults to false for everyone except those with the AccountAdmin role
      role = custom_account_role("LimitedAccess", account: Account.site_admin)
      user_factory(active_all: true)
      Account.site_admin.account_users.create!(user: @user, role:)
      user_session(@user)

      get "show", params: { id: @course.id }
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/settings})
    end

    it "does not redirect xhr to settings page when user can :read_as_admin, but not :read" do
      role = custom_account_role("LimitedAccess", account: Account.site_admin)
      user_factory(active_all: true)
      Account.site_admin.account_users.create!(user: @user, role:)
      user_session(@user)

      get "show", params: { id: @course.id }, xhr: true
      expect(response).to be_successful
    end

    describe "redirecting to crosslisted courses" do
      before do
        @course1 = @course
        @course2 = course_factory(active_all: true)
        @student1 = @student
      end

      context "as a student" do
        before do
          user_session(@student1)
        end

        it "redirects to the xlisted course when there's no enrollment in the requested course" do
          @course1.default_section.crosslist_to_course(@course2, run_jobs_immediately: true)
          get "show", params: { id: @course1.id }
          expect(response).to redirect_to(course_url(@course2))
        end

        it "does not redirect to the xlisted course when there's an enrollment in the requested course" do
          section2 = @course1.course_sections.create!(name: "section2")
          @course1.enroll_student(@student1, section: section2, enrollment_state: "active", allow_multiple_enrollments: true)
          @course1.default_section.crosslist_to_course(@course2, run_jobs_immediately: true)
          get "show", params: { id: @course1.id }
          expect(response).not_to be_redirect
        end
      end

      context "as an observer" do
        before do
          @observer = course_with_observer(course: @course1, associated_user_id: @student1.id, active_all: true).user
          user_session(@observer)
        end

        it "redirects to the xlisted course when there's no enrollment in the requested course" do
          @course1.default_section.crosslist_to_course(@course2, run_jobs_immediately: true)
          get "show", params: { id: @course1.id }
          expect(response).to redirect_to(course_url(@course2))
        end

        it "does not redirect to the xlisted course when there's an unlinked enrollment in the requested course" do
          section2 = @course1.course_sections.create!(name: "section2")
          @course1.enroll_user(@observer, "ObserverEnrollment", section: section2, enrollment_state: :active)
          @course1.default_section.crosslist_to_course(@course2, run_jobs_immediately: true)
          get "show", params: { id: @course1.id }
          expect(response).not_to be_redirect
        end

        it "does not redirect to the xlisted course when there's a linked enrollment in the requested course" do
          section2 = @course1.course_sections.create!(name: "section2")
          student2 = student_in_course(course: @course1, section: section2, active_all: true).user
          course_with_observer(
            user: @observer,
            course: @course1,
            section: section2,
            associated_user_id: student2.id,
            active_all: true,
            allow_multiple_enrollments: true
          )
          @course1.default_section.crosslist_to_course(@course2, run_jobs_immediately: true)
          get "show", params: { id: @course1.id }
          expect(response).not_to be_redirect
        end
      end
    end

    context "page views enabled" do
      before do
        Setting.set("enable_page_views", "db")
        @old_thread_context = Thread.current[:context]
        Thread.current[:context] = { request_id: SecureRandom.uuid }
      end

      after do
        Thread.current[:context] = @old_thread_context
      end

      it "logs an AUA with membership_type" do
        user_session(@student)
        get "show", params: { id: @course.id }
        expect(response).to be_successful
        aua = AssetUserAccess.where(user_id: @student, context_type: "Course", context_id: @course).first
        expect(aua.asset_category).to eq "home"
        expect(aua.membership_type).to eq "StudentEnrollment"
      end

      it "logs an asset user access for api requests" do
        allow(@controller).to receive(:api_request?).and_return(true)
        user_session(@student)
        get "show", params: { id: @course.id }
        expect(response).to be_successful
        aua = AssetUserAccess.where(user_id: @student, context_type: "Course", context_id: @course).first
        expect(aua.asset_category).to eq "home"
        expect(aua.membership_type).to eq "StudentEnrollment"
      end
    end

    context "course_home_sub_navigation" do
      before :once do
        @tool = @course.context_external_tools.create(consumer_key: "test",
                                                      shared_secret: "secret",
                                                      url: "http://example.com/lti",
                                                      name: "tool",
                                                      course_home_sub_navigation: { enabled: true, visibility: "admins" })
      end

      it "shows admin-level course_home_sub_navigation external tools for teachers" do
        user_session(@teacher)

        get "show", params: { id: @course.id }
        expect(assigns[:course_home_sub_navigation_tools].size).to eq 1
      end

      it "rejects admin-level course_home_sub_navigation external tools for students" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:course_home_sub_navigation_tools].size).to eq 0
      end
    end

    describe "when account is enabled as k5 account" do
      before :once do
        toggle_k5_setting(@course.account)
      end

      it "sets the course_home_view to 'k5_dashboard'" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:course_home_view]).to eq "k5_dashboard"
      end

      it "registers k5_course js and css bundles and sets K5_USER = true in js_env" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_bundles].flatten).to include :k5_course
        expect(assigns[:js_bundles].flatten).to include :k5_theme
        expect(assigns[:css_bundles].flatten).to include :k5_common
        expect(assigns[:css_bundles].flatten).to include :k5_course
        expect(assigns[:css_bundles].flatten).to include :k5_theme
        expect(assigns[:css_bundles].flatten).to include :k5_font
        expect(assigns[:js_env][:K5_USER]).to be_truthy
      end

      it "does not include k5_font css bundle if account's use_classic_font_in_k5? is true, even if use_classic_font? is false" do
        allow(controller).to receive(:use_classic_font?).and_return(false)
        @course.account.settings[:use_classic_font_in_k5] = { value: true }
        @course.account.save!
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:css_bundles].flatten).to include :k5_theme
        expect(assigns[:css_bundles].flatten).not_to include :k5_font
      end

      it "registers module-related js and css bundles and sets CONTEXT_MODULE_ASSIGNMENT_INFO_URL in js_env" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_bundles].flatten).to include :context_modules
        expect(assigns[:css_bundles].flatten).to include :content_next
        expect(assigns[:css_bundles].flatten).to include :context_modules2
        expect(assigns[:js_env][:CONTEXT_MODULE_ASSIGNMENT_INFO_URL]).to be_truthy
      end

      it "does not render the sidebar navigation or breadcrumbs" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:show_left_side]).to be_falsy
        expect(assigns[:_crumbs].length).to be 1
      end

      it "sets STUDENT_PLANNER_ENABLED = true in js_env if the user has student enrollments" do
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_truthy
      end

      it "sets STUDENT_PLANNER_ENABLED = false in js_env if the user doesn't have student enrollments" do
        user_session(@teacher)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_falsy
      end

      it "sets PERMISSIONS appropriately in js_env" do
        user_session(@teacher)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS]).to eq({ manage: true,
                                                       manage_groups: true,
                                                       read_announcements: true,
                                                       read_as_admin: true })
      end

      it "sets COURSE.color appropriately in js_env" do
        @course.course_color = "#BB8"
        @course.save!
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:color]).to eq("#BB8")
      end

      it "loads announcements on home page when course is a k5 homeroom course" do
        @course.homeroom_course = true
        @course.save!
        user_session(@teacher)

        get "show", params: { id: @course.id }
        expect(assigns[:course_home_view]).to eq "announcements"
        bundle = assigns[:js_bundles].select { |b| b.include? :announcements }
        expect(bundle.size).to eq 1
      end

      it "sets the course_home_view to 'Important Info' if the teacher has no announcement reading permission for the homeroom" do
        @course.homeroom_course = true
        @course.save!

        @course.account.role_overrides.create!(permission: :read_announcements, role: teacher_role, enabled: false)
        user_session(@teacher)

        get "show", params: { id: @course.id }
        expect(assigns[:course_home_view]).to eq "syllabus"
      end

      it "sets COURSE.has_syllabus_body to true when syllabus exists" do
        @course.syllabus_body = "Welcome"
        @course.save!
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:has_syllabus_body]).to be_truthy
      end

      it "sets COURSE.has_syllabus_body to false when syllabus does not exist" do
        @course.syllabus_body = nil
        @course.save!
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:has_syllabus_body]).to be_falsey
      end

      it "sets ENV.OBSERVED_USERS_LIST with self and observed users" do
        user_session(@student)

        get "show", params: { id: @course.id }
        observers = assigns[:js_env][:OBSERVED_USERS_LIST]
        expect(observers.length).to be(1)
        expect(observers[0][:name]).to eq(@student.name)
        expect(observers[0][:id]).to eq(@student.id)
      end

      it "sets COURSE.student_outcome_gradebook_enabled when feature is on" do
        @course.enable_feature!(:student_outcome_gradebook)
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:student_outcome_gradebook_enabled]).to be_truthy
      end

      it "sets ENV.SHOW_IMMERSIVE_READER when user flag is enabled" do
        @student.enable_feature!(:user_immersive_reader_wiki_pages)
        user_session(@student)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:SHOW_IMMERSIVE_READER]).to be_truthy
      end

      context "ENV.COURSE.self_enrollment" do
        before :once do
          @course.root_account.allow_self_enrollment!
          @course.is_public = true
          @course.save!
          @student.enrollments.destroy_all
        end

        before do
          user_session(@student)
        end

        it "is set to to 'enroll' if self-enrollment is enabled" do
          @course.self_enrollment = true
          @course.open_enrollment = true
          @course.save!

          get "show", params: { id: @course.id }
          expect(assigns[:js_env][:COURSE][:self_enrollment][:option]).to be(:enroll)
          expect(assigns[:js_env][:COURSE][:self_enrollment][:url]).not_to be_nil
        end

        it "is set to to nil if self-enrollment is disabled" do
          get "show", params: { id: @course.id }
          expect(assigns[:js_env][:COURSE][:self_enrollment][:option]).to be_nil
          expect(assigns[:js_env][:COURSE][:self_enrollment][:url]).to be_nil
        end
      end

      describe "embed mode" do
        it "sets ENV.TAB_CONTENT_ONLY appropriately" do
          user_session(@student)

          get "show", params: { id: @course.id, embed: true }
          expect(assigns[:js_env][:TAB_CONTENT_ONLY]).to be_truthy

          get "show", params: { id: @course.id }
          expect(assigns[:js_env][:TAB_CONTENT_ONLY]).to be_falsy
        end
      end

      describe "update" do
        before :once do
          @subject = @course
          @homeroom = course_factory
          @homeroom.homeroom_course = true
          @homeroom.save!
        end

        it "syncs enrollments if setting is set" do
          progress = double("Progress").as_null_object
          allow(Progress).to receive(:new).and_return(progress)
          expect(progress).to receive(:process_job)

          user_session(@teacher)

          get "update", params: {
            id: @subject.id,
            course: {
              homeroom_course_id: @homeroom.id,
              sync_enrollments_from_homeroom: "1"
            }
          }
        end

        it "does not sync if course is a sis import" do
          progress = double("Progress").as_null_object
          allow(Progress).to receive(:new).and_return(progress)
          expect(progress).not_to receive(:process_job)

          user_session(@teacher)
          sis = @subject.account.sis_batches.create
          @subject.sis_batch_id = sis.id
          @subject.save!

          get "update", params: {
            id: @subject.id,
            course: {
              homeroom_course_id: @homeroom.id,
              sync_enrollments_from_homeroom: "1"
            }
          }
        end
      end
    end

    context "COURSE.latest_announcement" do
      let_once(:announcement1) do
        Announcement.create!(
          title: "Hello students",
          message: "Welcome to the grind",
          user: @teacher,
          context: @course,
          workflow_state: "published",
          posted_at: 1.hour.ago
        )
      end

      let_once(:announcement2) do
        Announcement.create!(
          title: "Hidden",
          message: "You shouldn't see me",
          user: @teacher,
          context: @course,
          workflow_state: "post_delayed"
        )
      end

      before :once do
        toggle_k5_setting(@course.account)
      end

      before do
        user_session(@student)
      end

      it "is set with most recent visible announcement" do
        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:latest_announcement][:title]).to eq "Hello students"
        expect(assigns[:js_env][:COURSE][:latest_announcement][:message]).to eq "Welcome to the grind"
      end

      it "is set to nil if there are no recent (within 2 weeks) announcements" do
        announcement1.posted_at = 3.weeks.ago
        announcement1.save!
        announcement2.destroy

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:latest_announcement]).to be_nil
      end

      it "is set to nil if there's announcements but user doesn't have :read_announcements" do
        @course.account.role_overrides.create!(permission: :read_announcements, role: student_role, enabled: false)

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:latest_announcement]).to be_nil
      end

      it "only shows announcements visible to student sections" do
        secret_section = CourseSection.create!(name: "Secret Section", course: @course)
        Announcement.create!(
          title: "For the other section only",
          message: "Hello",
          user: @teacher,
          context: @course,
          workflow_state: "published",
          posted_at: 1.minute.ago,
          is_section_specific: true,
          course_sections: [secret_section]
        )

        get "show", params: { id: @course.id }
        expect(assigns[:js_env][:COURSE][:latest_announcement][:title]).to eq "Hello students"
      end
    end

    context "when logged in as an observer with multiple student associations" do
      before do
        @student2 = User.create!
        @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")

        @observer = User.create!
        @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)
        @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student2.id)
        user_session(@observer)
      end

      it "sets context_enrollment using selected observed user" do
        cookies["#{ObserverEnrollmentsHelper::OBSERVER_COOKIE_PREFIX}#{@observer.id}"] = @student2.id
        get :show, params: { id: @course.id }
        enrollment = assigns[:context_enrollment]
        expect(enrollment.is_a?(ObserverEnrollment)).to be true
        expect(enrollment.user_id).to eq @observer.id
        expect(enrollment.associated_user_id).to eq @student2.id
      end

      it "sets js_env variables" do
        get :show, params: { id: @course.id }
        expect(assigns[:js_env]).to have_key(:OBSERVER_OPTIONS)
        expect(assigns[:js_env][:OBSERVER_OPTIONS][:OBSERVED_USERS_LIST].is_a?(Array)).to be true
        expect(assigns[:js_env][:OBSERVER_OPTIONS][:CAN_ADD_OBSERVEE]).to be false
      end
    end
  end

  describe "POST 'unenroll_user'" do
    before :once do
      course_with_teacher(active_all: true)
      @teacher_enrollment = @enrollment
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      post "unenroll_user", params: { course_id: @course.id, id: @enrollment.id }
      assert_unauthorized
    end

    it "does not allow students to unenroll" do
      user_session(@student)
      post "unenroll_user", params: { course_id: @course.id, id: @enrollment.id }
      assert_unauthorized
    end

    it "unenrolls users" do
      user_session(@teacher)
      post "unenroll_user", params: { course_id: @course.id, id: @enrollment.id }
      @course.reload
      expect(response).to be_successful
      expect(@course.enrollments.map(&:user)).not_to include(@student)
    end

    it "does not allow teachers to unenroll themselves" do
      user_session(@teacher)
      post "unenroll_user", params: { course_id: @course.id, id: @teacher_enrollment.id }
      assert_unauthorized
    end

    it "allows admins to unenroll themselves" do
      user_session(@teacher)
      @course.account.account_users.create!(user: @teacher)
      post "unenroll_user", params: { course_id: @course.id, id: @teacher_enrollment.id }
      @course.reload
      expect(response).to be_successful
      expect(@course.enrollments.map(&:user)).not_to include(@teacher)
    end
  end

  describe "POST 'enroll_users'" do
    before :once do
      account = Account.default
      account.settings = { open_registration: true }
      account.save!
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      post "enroll_users", params: { course_id: @course.id, user_list: "sam@yahoo.com" }
      assert_unauthorized
    end

    it "does not allow students to enroll people" do
      user_session(@student)
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
      assert_unauthorized
    end

    it "enrolls people" do
      user_session(@teacher)
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
      expect(response).to be_successful
      @course.reload
      expect(@course.students.map(&:name)).to include("Sam")
      expect(@course.students.map(&:name)).to include("Fred")
    end

    it "does not enroll people in hard-concluded courses" do
      user_session(@teacher)
      @course.complete
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
      expect(response).not_to be_successful
      @course.reload
      expect(@course.students.map(&:name)).not_to include("Sam")
      expect(@course.students.map(&:name)).not_to include("Fred")
    end

    it "does not enroll people in soft-concluded courses" do
      user_session(@teacher)
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
      expect(response).not_to be_successful
      @course.reload
      expect(@course.students.map(&:name)).not_to include("Sam")
      expect(@course.students.map(&:name)).not_to include("Fred")
    end

    it "records initial_enrollment_type on new users" do
      user_session(@teacher)
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>", enrollment_type: "ObserverEnrollment" }
      expect(response).to be_successful
      @course.reload
      expect(@course.observers.count).to eq 1
      expect(@course.observers.first.initial_enrollment_type).to eq "observer"
    end

    it "enrolls using custom role id" do
      user_session(@teacher)
      role = custom_student_role("customrole", account: @course.account)
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>", role_id: role.id }
      expect(response).to be_successful
      @course.reload
      expect(@course.students.map(&:name)).to include("Sam")
      expect(@course.student_enrollments.find_by(role_id: role.id)).to_not be_nil
    end

    it "allows TAs to enroll Observers (by default)" do
      course_with_teacher(active_all: true)
      @user = user_factory
      @course.enroll_ta(user_factory).accept!
      user_session(@user)
      post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>", enrollment_type: "ObserverEnrollment" }
      expect(response).to be_successful
      @course.reload
      expect(@course.students).to be_empty
      expect(@course.observers.map(&:name)).to include("Sam")
      expect(@course.observers.map(&:name)).to include("Fred")
      expect(@course.observer_enrollments.map(&:workflow_state)).to eql(["invited", "invited"])
    end

    it "will use json for limit_privileges_to_course_section param" do
      user_session(@teacher)
      post "enroll_users", params: { course_id: @course.id,
                                     user_list: "\"Sam\" <sam@yahoo.com>",
                                     enrollment_type: "TeacherEnrollment",
                                     limit_privileges_to_course_section: true }
      expect(response).to be_successful
      run_jobs
      enrollment = @course.reload.teachers.find { |t| t.name == "Sam" }.enrollments.first
      expect(enrollment.limit_privileges_to_course_section).to be true
    end

    it "alsoes accept a list of user tokens (instead of ye old UserList)" do
      u1 = user_factory
      u2 = user_factory
      user_session(@teacher)
      post "enroll_users", params: { course_id: @course.id, user_tokens: [u1.token, u2.token] }
      expect(response).to be_successful
      @course.reload
      expect(@course.students).to include(u1)
      expect(@course.students).to include(u2)
    end

    context "enrollment tracking" do
      before do
        user_session(@teacher)
      end

      it "tracks enrollments for unpaced courses" do
        allow(InstStatsd::Statsd).to receive(:count)
        post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
        expect(InstStatsd::Statsd).to have_received(:count).with("course.unpaced.student_enrollment_count", 3).once
      end

      it "tracks enrollments for paced courses" do
        allow(InstStatsd::Statsd).to receive(:count)
        @course.enable_course_paces = true
        @course.save!
        post "enroll_users", params: { course_id: @course.id, user_list: "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>" }
        expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.student_enrollment_count", 3).once
      end
    end
  end

  describe "POST create" do
    before do
      @account = Account.default
      @account.root_account.disable_feature!(:granular_permissions_manage_courses)
      role = custom_account_role "lamer", account: @account
      @account.role_overrides.create!(permission: "manage_courses", enabled: true, role:)
      @visperm = @account.role_overrides.create!(permission: "manage_course_visibility", enabled: true, role:)
      user_factory
      @account.account_users.create!(user: @user, role:)
      user_session @user
    end

    it "logs create course event" do
      course = @account.courses.build({
                                        name: "Course Name",
                                        lock_all_announcements: true
                                      })
      changes = course.changes
      changes.delete("settings")
      changes["lock_all_announcements"] = [nil, true]

      expect(Auditors::Course).to receive(:record_created)
        .with(anything, anything, changes, anything)

      post "create", params: { account_id: @account.id, course: { name: course.name, lock_all_announcements: true } }
    end

    it "sets the visibility settings when we have permission" do
      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: "new course",
               is_public: true,
               public_syllabus: true,
               is_public_to_auth_users: true,
               public_syllabus_to_auth: true
             }
           },
           format: :json

      json = response.parsed_body
      expect(json["is_public"]).to be true
      expect(json["public_syllabus"]).to be true
      expect(json["is_public_to_auth_users"]).to be true
      expect(json["public_syllabus_to_auth"]).to be true
    end

    it "sets grade_passback_setting" do
      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: "new course",
               grade_passback_setting: "nightly_sync",
             }
           },
           format: :json

      json = response.parsed_body
      expect(Course.find(json["id"]).grade_passback_setting).to eq "nightly_sync"
    end

    it "does not allow visibility to be set when we don't have permission" do
      @visperm.enabled = false
      @visperm.save

      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: "new course",
               is_public: true,
               public_syllabus: true,
               is_public_to_auth_users: true,
               public_syllabus_to_auth: true
             }
           },
           format: :json

      json = response.parsed_body
      expect(json["is_public"]).to be false
      expect(json["public_syllabus"]).to be false
      expect(json["is_public_to_auth_users"]).to be false
      expect(json["public_syllabus_to_auth"]).to be false
    end

    it "returns an error if syllabus_body content is nested too deeply" do
      stub_const("CanvasSanitize::SANITIZE", { parser_options: { max_tree_depth: 1 } })
      put "create", params: { account_id: @account.id, course: { syllabus_body: "<div><span>deeeeeeep</span></div>" }, format: :json }
      expect(response).to have_http_status :bad_request
      json = response.parsed_body
      expect(json["errors"].keys).to include "unparsable_content"
    end
  end

  describe "POST create (granular permissions)" do
    before do
      @account = Account.default
      @account.root_account.enable_feature!(:granular_permissions_manage_courses)
      role = custom_account_role "lamer", account: @account
      @account.role_overrides.create!(permission: "manage_courses_add", enabled: true, role:)
      @visperm =
        @account.role_overrides.create!(permission: "manage_course_visibility",
                                        enabled: true,
                                        role:)
      user_factory
      @account.account_users.create!(user: @user, role:)
      user_session @user
    end

    it "logs create course event" do
      course = @account.courses.build({ name: "Course Name", lock_all_announcements: true })
      changes = course.changes
      changes.delete("settings")
      changes["lock_all_announcements"] = [nil, true]

      expect(Auditors::Course).to receive(:record_created).with(
        anything,
        anything,
        changes,
        anything
      )

      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: course.name,
               lock_all_announcements: true
             }
           }
    end

    it "sets the visibility settings when we have permission" do
      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: "new course",
               is_public: true,
               public_syllabus: true,
               is_public_to_auth_users: true,
               public_syllabus_to_auth: true
             }
           },
           format: :json

      json = response.parsed_body
      expect(json["is_public"]).to be true
      expect(json["public_syllabus"]).to be true
      expect(json["is_public_to_auth_users"]).to be true
      expect(json["public_syllabus_to_auth"]).to be true
    end

    it "does not allow visibility to be set when we don't have permission" do
      @visperm.enabled = false
      @visperm.save

      post "create",
           params: {
             account_id: @account.id,
             course: {
               name: "new course",
               is_public: true,
               public_syllabus: true,
               is_public_to_auth_users: true,
               public_syllabus_to_auth: true
             }
           },
           format: :json

      json = response.parsed_body
      expect(json["is_public"]).to be false
      expect(json["public_syllabus"]).to be false
      expect(json["is_public_to_auth_users"]).to be false
      expect(json["public_syllabus_to_auth"]).to be false
    end
  end

  describe "PUT 'update'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      put "update", params: { id: @course.id, course: { name: "new course name" } }
      assert_unauthorized
    end

    it "does not let students update the course details" do
      user_session(@student)
      put "update", params: { id: @course.id, course: { name: "new course name" } }
      assert_unauthorized
    end

    it "updates course details" do
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { name: "new course name" } }
      expect(assigns[:course]).not_to be_nil
      expect(assigns[:course]).to eql(@course)
    end

    it "updates some settings and stuff" do
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { show_announcements_on_home_page: true, home_page_announcement_limit: 2 } }
      @course.reload
      expect(@course.show_announcements_on_home_page).to be_truthy
      expect(@course.home_page_announcement_limit).to eq 2
    end

    it "allows setting course default grading scheme back to default canvas grading scheme" do
      user_session(@teacher)

      @standard = @course.grading_standards.create!(title: "course standard", standard_data: { a: { name: "A", value: "95" }, b: { name: "B", value: "80" }, f: { name: "F", value: "" } })

      put "update", params: { id: @course.id, course: { grading_standard_enabled: 1, grading_standard_id: @standard.id } }
      @course.reload
      expect(@course.grading_standard_id).to eq @standard.id

      put "update", params: { id: @course.id, course: { grading_standard_enabled: 1, grading_standard_id: "" } }
      @course.reload
      expect(@course.grading_standard_id).to eq 0

      put "update", params: { id: @course.id, course: { grading_standard_enabled: 1, grading_standard_id: @standard.id } }
      @course.reload
      expect(@course.grading_standard_id).to eq @standard.id

      put "update", params: { id: @course.id, course: { grading_standard_enabled: 0 } }
      @course.reload
      expect(@course.grading_standard_id).to be_nil
    end

    it "allows sending events" do
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "complete" } }
      expect(assigns[:course]).not_to be_nil
      expect(assigns[:course].state).to be(:completed)
    end

    it "logs published event on update" do
      @course.claim!
      expect(Auditors::Course).to receive(:record_published).once
      user_session(@teacher)
      put "update", params: { id: @course.id, offer: true }
    end

    it "does not publish when offer is false" do
      @course.claim!
      expect(Auditors::Course).not_to receive(:record_published)
      user_session(@teacher)
      put "update", params: { id: @course.id, offer: "false" }
      expect(@course.reload).to be_claimed
    end

    it "does not log published event if course was already published" do
      expect(Auditors::Course).not_to receive(:record_published)
      user_session(@teacher)
      put "update", params: { id: @course.id, offer: true }
    end

    it "logs claimed event on update" do
      expect(Auditors::Course).to receive(:record_claimed).once
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "claim" } }
    end

    it "allows unpublishing of the course" do
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "claim" } }
      @course.reload
      expect(@course.workflow_state).to eq "claimed"
    end

    it "does not allow unpublishing of the course if submissions present" do
      course_with_student_submissions({ active_all: true, submission_points: true })
      put "update", params: { id: @course.id, course: { event: "claim" } }
      @course.reload
      expect(@course.workflow_state).to eq "available"
    end

    it "allows unpublishing of the course if submissions have no score or grade" do
      course_with_student_submissions
      put "update", params: { id: @course.id, course: { event: "claim" } }
      @course.reload
      expect(@course.workflow_state).to eq "claimed"
    end

    it "allows the course to be unpublished if it contains only graded student view submissions" do
      assignment = @course.assignments.create!(workflow_state: "published")
      sv_student = @course.student_view_student
      assignment.grade_student sv_student, { grade: 1, grader: @teacher }
      user_session @teacher
      put "update", params: { id: @course.id, course: { event: "claim" } }
      @course.reload
      expect(@course.workflow_state).to eq "claimed"
    end

    it "concludes a course" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      expect(Auditors::Course).to receive(:record_concluded).once
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "conclude" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "completed"
      @course.reload
      expect(@course.workflow_state).to eq "completed"
    end

    it "concludes a course if given :manage_courses_conclude (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_conclude",
        enabled: true
      )
      expect(Auditors::Course).to receive(:record_concluded).once
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "conclude" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "completed"
      @course.reload
      expect(@course.workflow_state).to eq "completed"
    end

    it "doesn't conclude course if :manage_courses_conclude is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_conclude",
        enabled: false
      )
      expect(Auditors::Course).not_to receive(:record_concluded)
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "conclude" }, format: :json }
      assert_unauthorized
    end

    it "publishes a course" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      @course.claim!
      expect(Auditors::Course).to receive(:record_published).once
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "offer" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "available"
      @course.reload
      expect(@course.workflow_state).to eq "available"
    end

    it "publishes a course if given :manage_courses_publish (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_publish",
        enabled: true
      )
      @course.claim!
      expect(Auditors::Course).to receive(:record_published).once
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "offer" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "available"
      @course.reload
      expect(@course.workflow_state).to eq "available"
    end

    it "doesn't publish course if :manage_courses_publish is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_publish",
        enabled: false
      )
      @course.claim!
      expect(Auditors::Course).not_to receive(:record_published)
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "offer" }, format: :json }
      assert_unauthorized
    end

    it "deletes a course" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      user_session(@teacher)
      expect(Auditors::Course).to receive(:record_deleted).once
      put "update", params: { id: @course.id, course: { event: "delete" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "deleted"
      @course.reload
      expect(@course.workflow_state).to eq "deleted"
    end

    it "deletes a course if given :manage_courses_delete (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_delete",
        enabled: true
      )
      user_session(@teacher)
      expect(Auditors::Course).to receive(:record_deleted).once
      put "update", params: { id: @course.id, course: { event: "delete" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "deleted"
      @course.reload
      expect(@course.workflow_state).to eq "deleted"
    end

    it "doesn't delete course if :manage_courses_delete is not enabled (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_delete",
        enabled: false
      )
      user_session(@teacher)
      expect(Auditors::Course).not_to receive(:record_deleted)
      put "update", params: { id: @course.id, course: { event: "delete" }, format: :json }
      assert_unauthorized
    end

    it "doesn't allow a teacher to undelete a course" do
      @course.destroy
      expect(Auditors::Course).not_to receive(:record_restored)
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "undelete" }, format: :json }
      expect(response).to have_http_status :unauthorized
    end

    it "undeletes a course" do
      @course.destroy
      expect(Auditors::Course).to receive(:record_restored).once
      user_session(account_admin_user)
      put "update", params: { id: @course.id, course: { event: "undelete" }, format: :json }
      json = response.parsed_body
      expect(json["course"]["workflow_state"]).to eq "claimed"
      @course.reload
      expect(@course.workflow_state).to eq "claimed"
    end

    it "returns an error if a bad event is given" do
      user_session(@teacher)
      put "update", params: { id: @course.id, course: { event: "boogie" }, format: :json }
      expect(response).to have_http_status :bad_request
      json = response.parsed_body
      expect(json["errors"].keys).to include "workflow_state"
    end

    it "locks active course announcements" do
      user_session(@teacher)
      active_announcement  = @course.announcements.create!(title: "active", message: "test")
      delayed_announcement = @course.announcements.create!(title: "delayed", message: "test")
      deleted_announcement = @course.announcements.create!(title: "deleted", message: "test")

      delayed_announcement.workflow_state  = "post_delayed"
      delayed_announcement.delayed_post_at = Time.now + 3.weeks
      delayed_announcement.save!

      deleted_announcement.destroy

      put "update", params: { id: @course.id, course: { lock_all_announcements: 1 } }
      expect(assigns[:course].lock_all_announcements).to be_truthy

      expect(active_announcement.reload).to be_locked
      expect(delayed_announcement.reload).to be_post_delayed
      expect(deleted_announcement.reload).to be_deleted
    end

    it "logs update course event" do
      user_session(@teacher)
      @course.lock_all_announcements = true
      @course.save!

      changes = {
        "name" => [@course.name, "new course name"],
        "lock_all_announcements" => [true, false]
      }

      expect(Auditors::Course).to receive(:record_updated)
        .with(anything, anything, changes, source: :manual)

      put "update", params: { id: @course.id,
                              course: {
                                name: changes["name"].last,
                                lock_all_announcements: false
                              } }
    end

    it "updates its lock_all_announcements setting" do
      user_session(@teacher)
      @course.lock_all_announcements = true
      @course.save!
      put "update", params: { id: @course.id, course: { lock_all_announcements: 0 } }
      expect(assigns[:course].lock_all_announcements).to be_falsey
    end

    it "updates its usage_rights_required setting" do
      user_session(@teacher)
      @course.usage_rights_required = true
      @course.save!
      put "update", params: { id: @course.id, course: { usage_rights_required: 0 } }
      expect(assigns[:course].usage_rights_required).to be_falsey
    end

    it "lets sub-account admins move courses to other accounts within their sub-account" do
      subaccount = account_model(parent_account: Account.default)
      sub_subaccount1 = account_model(parent_account: subaccount)
      sub_subaccount2 = account_model(parent_account: subaccount)
      course_factory(account: sub_subaccount1)

      @user = account_admin_user(account: subaccount, active_user: true)
      user_session(@user)

      put "update", params: { id: @course.id, course: { account_id: sub_subaccount2.id } }

      @course.reload
      expect(@course.account_id).to eq sub_subaccount2.id
    end

    it "does not let sub-account admins move courses to other accounts outside their sub-account" do
      subaccount1 = account_model(parent_account: Account.default)
      subaccount2 = account_model(parent_account: Account.default)
      course_factory(account: subaccount1)

      @user = account_admin_user(account: subaccount1, active_user: true)
      user_session(@user)

      put "update", params: { id: @course.id, course: { account_id: subaccount2.id } }

      @course.reload
      expect(@course.account_id).to eq subaccount1.id
    end

    it "lets site admins move courses to any account" do
      account1 = Account.create!(name: "account1")
      account2 = Account.create!(name: "account2")
      course_factory(account: account1)

      user_session(site_admin_user)

      put "update", params: { id: @course.id, course: { account_id: account2.id } }

      @course.reload
      expect(@course.account_id).to eq account2.id
    end

    describe "touching content when public visibility changes" do
      before do
        user_session(@teacher)
        @assignment = @course.assignments.create!(name: "name")
        @time = 1.day.ago
        Assignment.where(id: @assignment).update_all(updated_at: @time)

        @assignment.reload
      end

      it "touches content when is_public is updated" do
        put "update", params: { id: @course.id, course: { is_public: true } }

        @assignment.reload
        expect(@assignment.updated_at).to_not eq @time
      end

      it "touches content when is_public_to_auth_users is updated" do
        put "update", params: { id: @course.id, course: { is_public_to_auth_users: true } }

        @assignment.reload
        expect(@assignment.updated_at).to_not eq @time
      end

      it "does not touch content when neither is updated" do
        put "update", params: { id: @course.id, course: { name: "name" } }

        @assignment.reload
        expect(@assignment.updated_at).to eq @time
      end
    end

    it "lets admins without course edit rights update only the syllabus body" do
      @course.root_account.disable_feature!(:granular_permissions_manage_course_content)
      role = custom_account_role("grade viewer", account: Account.default)
      account_admin_user_with_role_changes(role:, role_changes: { manage_content: true })
      user_session(@user)

      name = "some name"
      body = "some body"
      put "update", params: { id: @course.id, course: { name:, syllabus_body: body } }

      @course.reload
      expect(@course.name).to_not eq name
      expect(@course.syllabus_body).to eq body
    end

    it "lets admins without course edit rights update only the syllabus body (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_course_content)
      role = custom_account_role("grade viewer", account: Account.default)
      account_admin_user_with_role_changes(
        role:,
        role_changes: { manage_course_content_edit: true }
      )
      user_session(@user)

      name = "some name"
      body = "some body"
      put "update", params: { id: @course.id, course: { name:, syllabus_body: body } }

      @course.reload
      expect(@course.name).to_not eq name
      expect(@course.syllabus_body).to eq body
    end

    it "renders the show page with a flash on error" do
      user_session(@teacher)
      # cause the course to be invalid
      Course.where(id: @course).update_all(restrict_enrollments_to_course_dates: true, start_at: Time.now.utc, conclude_at: 1.day.ago)
      put "update", params: { id: @course.id, course: { name: "name change" } }
      expect(flash[:error]).to match(/There was an error saving the changes to the course/)
    end

    describe "course images" do
      before do
        user_session(@teacher)
      end

      it "allows valid course file ids" do
        attachment_with_context(@course)
        put "update", params: { id: @course.id, course: { image_id: @attachment.id } }
        @course.reload
        expect(@course.settings[:image_id]).to eq @attachment.id.to_s
      end

      it "allows valid urls" do
        put "update", params: { id: @course.id, course: { image_url: "http://farm3.static.flickr.com/image.jpg" } }
        @course.reload
        expect(@course.settings[:image_url]).to eq "http://farm3.static.flickr.com/image.jpg"
      end

      it "rejects invalid urls" do
        put "update", params: { id: @course.id, course: { image_url: "exam ple.com" } }
        @course.reload
        expect(@course.settings[:image_url]).to be_nil
      end

      it "rejects random letters and numbers" do
        put "update", params: { id: @course.id, course: { image_id: "123a456b78c" } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
      end

      it "rejects setting both a url and an id at the same time" do
        put "update", params: { id: @course.id, course: { image_id: "123a456b78c", image_url: "http://example.com" } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
        expect(@course.settings[:image_url]).to be_nil
      end

      it "rejects non-course ids" do
        put "update", params: { id: @course.id, course: { image_id: 1_234_134_123 } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
      end

      it "clears the image_url when setting an image_id" do
        attachment_with_context(@course)
        put "update", params: { id: @course.id, course: { image_url: "http://farm3.static.flickr.com/image.jpg" } }
        put "update", params: { id: @course.id, course: { image_id: @attachment.id } }
        @course.reload
        expect(@course.settings[:image_id]).to eq @attachment.id.to_s
        expect(@course.settings[:image_url]).to be_nil
      end

      it "clears the image_id when setting an image_url" do
        put "update", params: { id: @course.id, course: { image_id: "12345678" } }
        put "update", params: { id: @course.id, course: { image_url: "http://farm3.static.flickr.com/image.jpg" } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
        expect(@course.settings[:image_url]).to eq "http://farm3.static.flickr.com/image.jpg"
      end

      it "clears image id after setting remove_image" do
        put "update", params: { id: @course.id, course: { image_id: "12345678" } }
        put "update", params: { id: @course.id, course: { remove_image: true } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
        expect(@course.settings[:image_url]).to be_nil
      end

      it "clears image url after setting remove_image" do
        put "update", params: { id: @course.id, course: { image_url: "http://farm3.static.flickr.com/image.jpg" } }
        put "update", params: { id: @course.id, course: { remove_image: true } }
        @course.reload
        expect(@course.settings[:image_id]).to be_nil
        expect(@course.settings[:image_url]).to be_nil
      end
    end

    describe "course colors" do
      before do
        user_session(@teacher)
      end

      it "allows valid hexcodes" do
        put "update", params: { id: @course.id, course: { course_color: "#112233" } }
        @course.reload
        expect(@course.settings[:course_color]).to eq "#112233"
      end

      it "rejects invalid hexcodes" do
        put "update", params: { id: @course.id, course: { course_color: "#NOOOO" } }
        put "update", params: { id: @course.id, course: { course_color: "1" } }
        put "update", params: { id: @course.id, course: { course_color: "#1a2b3c4e5f6" } }
        @course.reload
        expect(@course.settings[:course_color]).to be_nil
      end

      it "normalizes hexcodes without a leading #" do
        put "update", params: { id: @course.id, course: { course_color: "123456" } }
        @course.reload
        expect(@course.settings[:course_color]).to eq "#123456"
      end

      it "sets blank inputs to nil" do
        put "update", params: { id: @course.id, course: { course_color: "   " } }
        @course.reload
        expect(@course.settings[:course_color]).to be_nil
      end

      it "sets single character (e.g. just a pound sign) inputs to nil" do
        put "update", params: { id: @course.id, course: { course_color: "#" } }
        @course.reload
        expect(@course.settings[:course_color]).to be_nil
      end
    end

    describe "default due time" do
      before do
        user_session @teacher
      end

      it "sets the normalized due time if valid" do
        put "update", params: { id: @course.id, course: { default_due_time: "4:00 PM" } }
        expect(@course.reload.settings[:default_due_time]).to eq "16:00:00"
      end

      it "ignores invalid settings" do
        put "update", params: { id: @course.id, course: { default_due_time: "lolcats" } }
        expect(@course.reload.settings[:default_due_time]).to be_nil
      end

      it "inherits the account setting if `inherit` is given" do
        @course.account.update settings: { default_due_time: { value: "21:00:00" } }
        expect(@course.default_due_time).to eq "21:00:00"

        @course.default_due_time = "22:00:00"
        @course.save!
        expect(@course.default_due_time).to eq "22:00:00"

        put "update", params: { id: @course.id, course: { default_due_time: "inherit" } }
        @course.reload
        expect(@course.default_due_time).to eq "21:00:00"
        expect(@course.settings[:default_due_time]).to be_nil
      end

      it "leaves the setting alone if the parameter isn't given" do
        @course.default_due_time = "22:00:00"
        @course.save!
        put "update", params: { id: @course.id, course: { course_color: "#000000" } }
        expect(@course.reload.settings[:default_due_time]).to eq "22:00:00"
      end
    end

    describe "master courses" do
      before :once do
        account_admin_user
        course_factory
        ta_in_course
      end

      before do
        user_session(@admin)
      end

      it "requires :manage_master_courses permission" do
        user_session @ta
        put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
        expect(response).to be_unauthorized
      end

      it "sets a course as a master course" do
        put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
        expect(response).to be_successful
        expect(MasterCourses::MasterTemplate).to be_is_master_course @course
      end

      it "does not allow a course with students to be set as a master course" do
        student_in_course
        put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
        expect(response).to have_http_status :bad_request
        expect(response.body).to include "Cannot have a blueprint course with students"
      end

      it "does not allow a course with observers to be set as a master course" do
        observer_in_course
        put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
        expect(response).to have_http_status :bad_request
        expect(response.body).to include "Cannot have a blueprint course with observers"
      end

      it "does not allow a minion course to be set as a master course" do
        c1 = @course
        c2 = course_factory
        template = MasterCourses::MasterTemplate.set_as_master_course(c1)
        template.add_child_course!(c2)
        put "update", params: { id: c2.id, course: { blueprint: "1" } }, format: "json"
        expect(response).to have_http_status :bad_request
        expect(response.body).to include "Course is already associated"
      end

      it "allows setting of default template restrictions" do
        put "update",
            params: { id: @course.id,
                      course: { blueprint: "1",
                                blueprint_restrictions: { "content" => "0", "due_dates" => "1" } } },
            format: "json"
        expect(response).to be_successful
        template = MasterCourses::MasterTemplate.full_template_for(@course)
        expect(template.default_restrictions).to eq({ content: false, due_dates: true })
      end

      describe "changing restrictions" do
        before :once do
          @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
          @template.update_attribute(:default_restrictions, { content: true })
        end

        it "allows an admin to change restrictions" do
          put "update",
              params: { id: @course.id,
                        course: { blueprint: "1",
                                  blueprint_restrictions: { "content" => "0", "due_dates" => "1" } } },
              format: "json"
          expect(response).to be_successful
          template = MasterCourses::MasterTemplate.full_template_for(@course)
          expect(template.default_restrictions).to eq({ content: false, due_dates: true })
        end

        it "forbids a non-admin from changing restrictions" do
          user_session @ta
          put "update",
              params: { id: @course.id,
                        course: { blueprint: "1",
                                  blueprint_restrictions: { "content" => "0", "due_dates" => "1" } } },
              format: "json"
          expect(response).to be_unauthorized
        end

        it "allows a non-admin to perform a no-op request" do
          user_session @ta
          put "update",
              params: { id: @course.id,
                        course: { blueprint: "1",
                                  blueprint_restrictions: { "content" => "1" } } },
              format: "json"
          expect(response).to be_successful
        end
      end

      it "validates template restrictions" do
        put "update",
            params: { id: @course.id,
                      course: { blueprint: "1",
                                blueprint_restrictions: { "content" => "1", "doo_dates" => "1" } } },
            format: "json"
        expect(response).to_not be_successful
        expect(response.body).to include "Invalid restrictions"
      end

      it "allows setting whether to use template restrictions by object type" do
        put "update",
            params: { id: @course.id,
                      course: { blueprint: "1",
                                use_blueprint_restrictions_by_object_type: "1" } },
            format: "json"
        expect(response).to be_successful
        template = MasterCourses::MasterTemplate.full_template_for(@course)
        expect(template.use_default_restrictions_by_type).to be_truthy
      end

      it "allows setting default template restrictions by object type" do
        put "update",
            params: { id: @course.id,
                      course: { blueprint: "1",
                                blueprint_restrictions_by_object_type: { "assignment" => { "content" => "1", "due_dates" => "1" }, "quiz" => { "content" => "1" } } } },
            format: "json"
        expect(response).to be_successful
        template = MasterCourses::MasterTemplate.full_template_for(@course)
        expect(template.default_restrictions_by_type).to eq({
                                                              "Assignment" => { content: true, due_dates: true },
                                                              "Quizzes::Quiz" => { content: true }
                                                            })
      end

      it "validates default template restrictions by object type" do
        put "update",
            params: { id: @course.id,
                      course: { blueprint: "1",
                                blueprint_restrictions_by_object_type: { "notarealtype" => { "content" => "1", "due_dates" => "1" } } } },
            format: "json"
        expect(response).to_not be_successful
        expect(response.body).to include "Invalid restrictions"
      end

      context "logging master courses and course pacing" do
        before do
          Account.default.enable_feature!(:course_paces)
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        it "does not increment the counter when course pacing is not enabled" do
          put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.blueprint_course")
        end

        it "increments the counter when course pacing is already enabled" do
          put "update", params: { id: @course.id, course: { enable_course_paces: "1" } }, format: "json"
          put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
          expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blueprint_course").once
        end

        it "increments the counter when course pacing is enabled at the same time as blueprint" do
          put "update", params: { id: @course.id, course: { blueprint: "1", enable_course_paces: "1" } }, format: "json"
          expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blueprint_course").once
        end

        it "increments the counter when course pacing is enabled after blueprint has already been enabled" do
          put "update", params: { id: @course.id, course: { blueprint: "1" } }, format: "json"
          put "update", params: { id: @course.id, course: { enable_course_paces: "1" } }, format: "json"

          expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blueprint_course")
        end

        it "does not increment the count if a random course items is updated" do
          put "update", params: { id: @course.id, course: { course_format: "online" } }, format: "json"
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.blueprint_course")
        end
      end
    end

    it "updates pages' permissions even if course default is nil" do
      user_session(@teacher)
      wiki_page = @course.wiki_pages.create! title: "Wiki page 1", editing_roles: "teachers"
      new_permissions = "teachers,students"
      put "update", params: { id: @course.id, update_default_pages: true, course: { default_wiki_editing_roles: new_permissions } }
      @course.reload
      wiki_page.reload
      expect(@course.default_wiki_editing_roles).to eq new_permissions
      expect(wiki_page.editing_roles).to eq new_permissions
    end

    it "does not attempt to sync k5 homeroom to course if sync_enrollments_from_homeroom is falsey" do
      teacher = @teacher
      subject = @course
      toggle_k5_setting(subject.account, true)
      homeroom = course_factory(active_all: true, account: subject.account)
      homeroom.enroll_teacher(teacher, enrollment_state: :active)
      homeroom.homeroom_course = true
      homeroom.restrict_enrollments_to_course_dates = true
      homeroom.save!
      subject.homeroom_course_id = homeroom.id
      subject.save!

      user_session(teacher)
      put "update", params: { id: subject.id, course: { name: "something new", sync_enrollments_from_homeroom: "0", homeroom_course_id: homeroom.id } }
      run_jobs

      # if the sync job runs, we'll know because restrict_enrollments_to_course_dates will be synced as true
      expect(subject.reload.restrict_enrollments_to_course_dates).to be_falsey
    end

    context "course paces" do
      before do
        @course.account.enable_feature!(:course_paces)
        @course.enable_course_paces = true
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @course_pace = course_pace_model(course: @course)
      end

      it "republishes course paces when dates have changed" do
        user_session(@teacher)
        put "update", params: { id: @course.id, course: { start_at: 1.day.from_now } }
        expect(Progress.find_by(context: @course_pace)).to be_queued
        Progress.destroy_all
        put "update", params: { id: @course.id, course: { conclude_at: 1.year.from_now } }
        expect(Progress.find_by(context: @course_pace)).to be_queued
        Progress.destroy_all
        put "update", params: { id: @course.id, course: { restrict_enrollments_to_course_dates: false } }
        expect(Progress.find_by(context: @course_pace)).to be_queued
        Progress.destroy_all
        term = EnrollmentTerm.create!(start_at: 1.day.ago, end_at: 3.days.from_now, root_account: @course.account)
        put "update", params: { id: @course.id, course: { term_id: term.id } }
        expect(Progress.find_by(context: @course_pace)).to be_queued
      end

      it "does not republish course paces when dates have not changed" do
        user_session(@teacher)
        put "update", params: { id: @course.id, course: { name: "course paces" } }
        expect(Progress.find_by(context: @course_pace)).to be_nil
      end

      it "does not allow course to be made a homeroom course" do
        user_session(@teacher)
        put "update", params: { id: @course.id, course: { homeroom_course: "true" }, format: :json }
        expect(response).to have_http_status :bad_request
        json = response.parsed_body
        expect(json["errors"].keys).to include "homeroom_course"
        expect(@course.reload.homeroom_course).to be_falsey
      end
    end

    it "does not allow homeroom course to enable course pacing" do
      toggle_k5_setting(@course.account, true)
      homeroom = course_factory(active_all: true, account: @course.account)
      homeroom.homeroom_course = true
      homeroom.save!
      user_session(@teacher)

      put "update", params: { id: homeroom.id, course: { enable_course_paces: "true" }, format: :json }
      expect(response).to have_http_status :bad_request
      json = response.parsed_body
      expect(json["errors"].keys).to include "enable_course_paces"
      expect(@course.reload.enable_course_paces).to be_falsey
    end

    it "returns an error if syllabus_body content is nested too deeply" do
      user_session(@teacher)
      stub_const("CanvasSanitize::SANITIZE", { parser_options: { max_tree_depth: 1 } })
      put "update", params: { id: @course.id, course: { syllabus_body: "<div><span>deeeeeeep</span></div>" }, format: :json }
      expect(response).to have_http_status :bad_request
      json = response.parsed_body
      expect(json["errors"].keys).to include "unparsable_content"
    end

    it "doesn't overwrite stuck sis fields" do
      user_session(@teacher)
      init_course_name = @course.name

      put "update", params: { id: @course.id, course: { name: "123456" }, override_sis_stickiness: false, format: :json }

      @course.reload
      expect(@course.name).to eq init_course_name
    end

    context "course availability options" do
      before :once do
        @account = Account.default
      end

      it "updates a course's availability options" do
        user_session(@teacher)
        start_at = 5.weeks.ago.beginning_of_day
        conclude_at = 10.weeks.from_now.beginning_of_day
        put "update", params: { id: @course.id, course: { start_at:, conclude_at:, restrict_enrollments_to_course_dates: true } }
        @course.reload
        expect(@course.start_at).to eq start_at
        expect(@course.conclude_at).to eq conclude_at
        expect(@course.restrict_enrollments_to_course_dates).to be true
      end

      context "when prevent_course_availability_editing_by_teachers is enabled" do
        before :once do
          @account.settings[:prevent_course_availability_editing_by_teachers] = true
          @account.save!
        end

        it "returns 401 if the user is a teacher" do
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { restrict_enrollments_to_course_dates: true } }
          expect(response).to be_unauthorized
          put "update", params: { id: @course.id, course: { start_at: 1.day.ago, restrict_enrollments_to_course_dates: true } }
          expect(response).to be_unauthorized
          put "update", params: { id: @course.id, course: { conclude_at: 1.day.from_now, restrict_enrollments_to_course_dates: true } }
          expect(response).to be_unauthorized
        end

        it "returns 401 if a teacher tries to set end_at in an api request" do
          # NOTE: end_at is an alias for conclude_at supported only in api requests (ignored otherwise)
          allow(controller).to receive(:api_request?).and_return(true)
          user_session(@teacher)
          @course.update!(restrict_enrollments_to_course_dates: true)
          put "update", params: { id: @course.id, course: { end_at: 1.day.from_now } }
          expect(response).to be_unauthorized
        end

        it "allows admins to update course availability options still" do
          account_admin_user(active_all: true)
          user_session(@admin)
          start_at = 6.weeks.ago.beginning_of_day
          put "update", params: { id: @course.id, course: { start_at:, restrict_enrollments_to_course_dates: true } }
          expect(response).to be_redirect
          @course.reload
          expect(@course.start_at).to eq start_at
          expect(@course.restrict_enrollments_to_course_dates).to be true
        end

        it "allows teachers to update other course settings" do
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { name: "cool new course" } }
          expect(response).to be_redirect
          expect(@course.reload.name).to eq "cool new course"
        end

        it "allows teachers to update other settings along with course availability settings if the latter remains unchanged" do
          start_at = 6.weeks.ago.beginning_of_day
          conclude_at = 3.weeks.from_now.beginning_of_day
          @course.update!(start_at:, conclude_at:, restrict_enrollments_to_course_dates: true)
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { name: "cool new course", start_at:, conclude_at:, restrict_enrollments_to_course_dates: true } }
          expect(response).to be_redirect
          expect(@course.reload.name).to eq "cool new course"
        end

        it "allows teachers to update settings even if course dates have been set but restrict_enrollments_to_course_dates is false" do
          # in this case, the controller automatically drops the course dates, and this shouldn't be restricted by permissions
          start_at = 6.weeks.ago.beginning_of_day
          conclude_at = 3.weeks.from_now.beginning_of_day
          @course.update!(start_at:, conclude_at:)
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { name: "cool new course", start_at:, conclude_at: } }
          expect(response).to be_redirect
          expect(@course.reload.name).to eq "cool new course"
        end

        it "does not allow teachers to set course dates to nil if restrict_enrollments_to_course_dates is true" do
          start_at = 6.weeks.ago.beginning_of_day
          conclude_at = 3.weeks.from_now.beginning_of_day
          @course.update!(start_at:, conclude_at:, restrict_enrollments_to_course_dates: true)
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { start_at: nil, conclude_at: nil } }
          expect(response).to be_unauthorized
        end

        it "does not allow teachers to change course dates if restrict_enrollments_to_course_dates is true" do
          start_at = 6.weeks.ago.beginning_of_day
          conclude_at = 3.weeks.from_now.beginning_of_day
          @course.update!(start_at:, conclude_at:, restrict_enrollments_to_course_dates: true)
          user_session(@teacher)
          put "update", params: { id: @course.id, course: { start_at: start_at + 1.day } }
          expect(response).to be_unauthorized
        end
      end
    end
  end

  describe "POST 'unconclude'" do
    it "unconcludes the course" do
      course_factory(active_all: true)
      account_admin_user(active_all: true)
      user_session(@admin)
      delete "destroy", params: { id: @course.id, event: "conclude" }
      expect(response).to be_redirect
      expect(@course.reload).to be_completed
      expect(@course.conclude_at).to be <= Time.now
      expect(Auditors::Course).to receive(:record_unconcluded)
        .with(anything, anything, source: :manual)

      post "unconclude", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(@course.reload).to be_available
      expect(@course.conclude_at).to be_nil
    end
  end

  describe "GET 'self_enrollment'" do
    before :once do
      Account.default.update_attribute(:settings, self_enrollment: "any", open_registration: true)
      course_factory(active_all: true)
    end

    it "redirects to the new self enrollment form" do
      @course.update_attribute(:self_enrollment, true)
      get "self_enrollment", params: { course_id: @course.id, self_enrollment: @course.self_enrollment_code }
      expect(response).to redirect_to(enroll_url(@course.self_enrollment_code))
    end

    it "redirects to the new self enrollment form if using a long code" do
      @course.update_attribute(:self_enrollment, true)
      get "self_enrollment", params: { course_id: @course.id, self_enrollment: @course.long_self_enrollment_code.dup }
      expect(response).to redirect_to(enroll_url(@course.self_enrollment_code))
    end

    it "returns to the course page for an incorrect code" do
      @course.update_attribute(:self_enrollment, true)
      user_factory
      user_session(@user)

      get "self_enrollment", params: { course_id: @course.id, self_enrollment: "abc" }
      expect(response).to redirect_to(course_url(@course))
      expect(@user.enrollments.length).to eq 0
    end

    it "redirects to the new enrollment form even if self_enrollment is disabled" do
      @course.update_attribute(:self_enrollment, true) # generate code
      code = @course.self_enrollment_code
      @course.update_attribute(:self_enrollment, false)

      get "self_enrollment", params: { course_id: @course.id, self_enrollment: code }
      expect(response).to redirect_to(enroll_url(code))
    end
  end

  describe "POST 'self_unenrollment'" do
    before(:once) { course_with_student(active_all: true) }

    before { user_session(@student) }

    it "unenrolls" do
      @enrollment.update_attribute(:self_enrolled, true)

      post "self_unenrollment", params: { course_id: @course.id, self_unenrollment: @enrollment.uuid }
      expect(response).to be_successful
      @enrollment.reload
      expect(@enrollment).to be_completed
    end

    it "does not unenroll for incorrect code" do
      @enrollment.update_attribute(:self_enrolled, true)

      post "self_unenrollment", params: { course_id: @course.id, self_unenrollment: "abc" }
      assert_status(400)
      @enrollment.reload
      expect(@enrollment).to be_active
    end

    it "does not unenroll a non-self-enrollment" do
      post "self_unenrollment", params: { course_id: @course.id, self_unenrollment: @enrollment.uuid }
      assert_status(400)
      @enrollment.reload
      expect(@enrollment).to be_active
    end
  end

  describe "GET 'sis_publish_status'" do
    before(:once) { course_with_teacher(active_all: true) }

    it "checks for authorization" do
      course_with_student_logged_in course: @course, active_all: true
      get "sis_publish_status", params: { course_id: @course.id }
      assert_status(401)
    end

    it "does not try and publish grades" do
      expect_any_instance_of(Course).not_to receive(:publish_final_grades)
      user_session(@teacher)
      get "sis_publish_status", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(json_parse(response.body)).to eq({ "sis_publish_overall_status" => "unpublished", "sis_publish_statuses" => {} })
    end

    it "returns reasonable json for a few enrollments" do
      user_session(@teacher)
      user_ids = create_users(Array.new(3) { { name: "User" } })
      students = create_enrollments(@course, user_ids, return_type: :record)
      students[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      students[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      students[2].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      get "sis_publish_status", params: { course_id: @course.id }
      expect(response).to be_successful
      response_body = json_parse(response.body)
      response_body["sis_publish_statuses"]["Synced"].sort_by! { |x| x["id"] }
      expect(response_body).to eq({
                                    "sis_publish_overall_status" => "error",
                                    "sis_publish_statuses" => {
                                      "Error: cause of this reason" => [
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[1].user),
                                          "id" => students[1].user.id
                                        }
                                      ],
                                      "Synced" => [
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[0].user),
                                          "id" => students[0].user.id
                                        },
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[2].user),
                                          "id" => students[2].user.id
                                        }
                                      ].sort_by { |x| x["id"] }
                                    }
                                  })
    end
  end

  describe "POST 'publish_to_sis'" do
    it "publishes grades and return results" do
      course_with_teacher_logged_in active_all: true
      @teacher = @user
      user_ids = create_users(Array.new(3) { { name: "User" } })
      students = create_enrollments(@course, user_ids, return_type: :record)
      students[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      students[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      students[2].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end

      @plugin = Canvas::Plugin.find!("grade_export")
      @ps = PluginSetting.new(name: @plugin.id, settings: @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
                                                             format_type: "instructure_csv",
                                                             wait_for_success: "no",
                                                             publish_endpoint: "http://localhost/endpoint"
                                                           })
      @ps.save!

      @course.assignment_groups.create(name: "Assignments")
      @course.grading_standard_enabled = true
      @course.save!
      a1 = @course.assignments.create!(title: "A1", points_possible: 10)
      a2 = @course.assignments.create!(title: "A2", points_possible: 10)
      a1.grade_student(students[0].user, { grade: "9", grader: @teacher })
      a2.grade_student(students[0].user, { grade: "10", grader: @teacher })
      a1.grade_student(students[1].user, { grade: "6", grader: @teacher })
      a2.grade_student(students[1].user, { grade: "7", grader: @teacher })

      expect(SSLCommon).to receive(:post_data).once
      post "publish_to_sis", params: { course_id: @course.id }

      expect(response).to be_successful
      response_body = json_parse(response.body)
      response_body["sis_publish_statuses"]["Synced"].sort_by! { |x| x["id"] }
      expect(response_body).to eq({
                                    "sis_publish_overall_status" => "published",
                                    "sis_publish_statuses" => {
                                      "Synced" => [
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[0].user),
                                          "id" => students[0].user.id
                                        },
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[1].user),
                                          "id" => students[1].user.id
                                        },
                                        {
                                          "name" => "User",
                                          "sortable_name" => "User",
                                          "url" => course_user_url(@course, students[2].user),
                                          "id" => students[2].user.id
                                        }
                                      ].sort_by { |x| x["id"] }
                                    }
                                  })
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:once) do
      course_with_student(active_all: true)
      assignment_model(course: @course)
    end

    it "requires authorization" do
      get "public_feed", params: { feed_code: @enrollment.feed_code + "x" }, format: "atom"
      expect(assigns[:problem]).to match(/The verification code does not match/)
    end

    it "includes absolute path for rel='self' link" do
      get "public_feed", params: { feed_code: @enrollment.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.feed_url).to match(%r{http://})
    end

    it "includes an author for each entry" do
      get "public_feed", params: { feed_code: @enrollment.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all? { |e| e.author.present? }).to be_truthy
    end

    it "does not include unpublished assignments or discussions or pages" do
      discussion_topic_model(context: @course)
      @assignment.unpublish
      @topic.unpublish!
      @course.wiki_pages.create! title: "unpublished", workflow_state: "unpublished"
      get "public_feed", params: { feed_code: @enrollment.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).to be_empty
    end

    it "respects assignment overrides" do
      @assignment.update_attribute :only_visible_to_overrides, true
      @a0 = @assignment
      graded_discussion_topic(context: @course)
      @topic.assignment.update_attribute :only_visible_to_overrides, true

      get "public_feed", params: { feed_code: @enrollment.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries.map(&:id).join(" ")).not_to include @a0.asset_string
      expect(feed.entries.map(&:id).join(" ")).not_to include @topic.asset_string

      assignment_override_model assignment: @a0, set: @enrollment.course_section
      assignment_override_model assignment: @topic.assignment, set: @enrollment.course_section

      get "public_feed", params: { feed_code: @enrollment.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries.map(&:id).join(" ")).to include @a0.asset_string
      expect(feed.entries.map(&:id).join(" ")).to include @topic.asset_string
    end
  end

  describe "POST 'reset_content'" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "allows teachers to reset" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      user_session(@teacher)
      post "reset_content", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(@course.reload).to be_deleted
    end

    it "only allows teachers to reset if granted :manage_courses_reset (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_reset",
        enabled: true
      )
      user_session(@teacher)
      post "reset_content", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(@course.reload).to be_deleted
    end

    it "does not allow TAs to reset" do
      course_with_ta(active_all: true, course: @course)
      user_session(@user)
      post "reset_content", params: { course_id: @course.id }
      assert_status(401)
      expect(@course.reload).to be_available
    end

    it "does not allow resetting blueprint courses" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      user_session(@teacher)
      post "reset_content", params: { course_id: @course.id }
      expect(response).to be_bad_request
    end

    it "does not allow resetting blueprint courses (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_reset",
        enabled: true
      )
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      user_session(@teacher)
      post "reset_content", params: { course_id: @course.id }
      expect(response).to be_bad_request
    end

    it "does not allow resetting course templates (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_reset",
        enabled: true
      )
      @course.enrollments.each(&:destroy)
      @course.update!(template: true)
      user_session(@teacher)
      post "reset_content", params: { course_id: @course.id }
      assert_status(401)
      expect(@course.reload).to be_available
    end

    it "logs reset audit event" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      user_session(@teacher)
      expect(Auditors::Course).to receive(:record_reset).once
                                                        .with(@course, anything, @user, anything)
      post "reset_content", params: { course_id: @course.id }
    end

    it "logs reset audit event (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.role_overrides.create!(
        role: teacher_role,
        permission: "manage_courses_reset",
        enabled: true
      )
      user_session(@teacher)
      expect(Auditors::Course).to receive(:record_reset).once
                                                        .with(@course, anything, @user, anything)
      post "reset_content", params: { course_id: @course.id }
    end
  end

  context "visibility_configuration" do
    let(:controller) { CoursesController.new }

    before do
      controller.instance_variable_set(:@course, Course.new(root_account: Account.default))
    end

    it "allows setting course visibility with flag" do
      controller.visibility_configuration({ course_visibility: "public" })
      course = controller.instance_variable_get(:@course)

      expect(course.is_public).to be true

      controller.visibility_configuration({ course_visibility: "institution" })
      expect(course.is_public).to be false
      expect(course.is_public_to_auth_users).to be true

      controller.visibility_configuration({ course_visibility: "course" })
      expect(course.is_public).to be false
      expect(course.is_public).to be false
    end

    it "allows setting syllabus visibility with flag" do
      controller.visibility_configuration({ course_visibility: "course", syllabus_visibility_option: "public" })
      course = controller.instance_variable_get(:@course)

      expect(course.public_syllabus).to be true

      controller.visibility_configuration({ course_visibility: "course", syllabus_visibility_option: "institution" })
      expect(course.public_syllabus).to be false
      expect(course.public_syllabus_to_auth).to be true

      controller.visibility_configuration({ course_visibility: "course", syllabus_visibility_option: "course" })
      expect(course.public_syllabus).to be false
      expect(course.public_syllabus_to_auth).to be false
    end
  end

  context "changed_settings" do
    let(:controller) { CoursesController.new }

    it "has changed settings for a new course" do
      course = Course.new
      course.hide_final_grade = false
      course.hide_distribution_graphs = false
      course.assert_defaults
      changes = course.changes

      changed_settings = controller.changed_settings(changes, course.settings)

      changes[:hide_final_grade] = false
      changes[:hide_distribution_graphs] = false

      expect(changed_settings).to eq changes
    end

    it "has changed settings for an updated course" do
      course = Account.default.courses.create!
      old_values = course.settings

      course.hide_final_grade = false
      course.hide_distribution_graphs = false
      changes = course.changes

      changed_settings = controller.changed_settings(changes, course.settings, old_values)

      changes[:hide_final_grade] = false
      changes[:hide_distribution_graphs] = false

      expect(changed_settings).to eq changes
    end
  end

  describe "quotas" do
    context "with :manage_storage_quotas" do
      before :once do
        @account = Account.default
        account_admin_user account: @account
      end

      before do
        user_session @user
      end

      describe "create" do
        it "sets storage_quota" do
          post "create", params: { account_id: @account.id, course: { name: "xyzzy", storage_quota: 111.megabytes } }
          @course = @account.courses.where(name: "xyzzy").first
          expect(@course.storage_quota).to eq 111.megabytes
        end

        it "sets storage_quota_mb" do
          post "create", params: { account_id: @account.id, course: { name: "xyzpdq", storage_quota_mb: 111 } }
          @course = @account.courses.where(name: "xyzpdq").first
          expect(@course.storage_quota_mb).to eq 111
        end
      end

      describe "update" do
        before :once do
          @course = @account.courses.create!
        end

        it "sets storage_quota" do
          post "update", params: { id: @course.id, course: { storage_quota: 111.megabytes } }
          expect(@course.reload.storage_quota).to eq 111.megabytes
        end

        it "sets storage_quota_mb" do
          post "update", params: { id: @course.id, course: { storage_quota_mb: 111 } }
          expect(@course.reload.storage_quota_mb).to eq 111
        end
      end
    end

    context "without :manage_storage_quotas" do
      describe "create" do
        before :once do
          @account = Account.default
          @account.disable_feature!(:granular_permissions_manage_courses)
          role = custom_account_role "lamer", account: @account
          @account.role_overrides.create!(permission: "manage_courses",
                                          enabled: true,
                                          role:)
          user_factory
          @account.account_users.create!(user: @user, role:)
        end

        before do
          user_session @user
        end

        it "ignores storage_quota" do
          post "create", params: { account_id: @account.id, course: { name: "xyzzy", storage_quota: 111.megabytes } }
          @course = @account.courses.where(name: "xyzzy").first
          expect(@course.storage_quota).to eq @account.default_storage_quota
        end

        it "ignores storage_quota_mb" do
          post "create", params: { account_id: @account.id, course: { name: "xyzpdq", storage_quota_mb: 111 } }
          @course = @account.courses.where(name: "xyzpdq").first
          expect(@course.storage_quota_mb).to eq @account.default_storage_quota / 1.megabyte
        end
      end

      describe "create (granular permissions)" do
        before :once do
          @account = Account.default
          @account.enable_feature!(:granular_permissions_manage_courses)
          role = custom_account_role "lamer", account: @account
          @account.role_overrides.create!(permission: "manage_courses_add",
                                          enabled: true,
                                          role:)
          user_factory
          @account.account_users.create!(user: @user, role:)
        end

        before do
          user_session @user
        end

        it "ignores storage_quota" do
          post "create",
               params: {
                 account_id: @account.id,
                 course: {
                   name: "xyzzy",
                   storage_quota: 111.megabytes
                 }
               }
          @course = @account.courses.where(name: "xyzzy").first
          expect(@course.storage_quota).to eq @account.default_storage_quota
        end

        it "ignores storage_quota_mb" do
          post "create",
               params: {
                 account_id: @account.id,
                 course: {
                   name: "xyzpdq",
                   storage_quota_mb: 111
                 }
               }
          @course = @account.courses.where(name: "xyzpdq").first
          expect(@course.storage_quota_mb).to eq @account.default_storage_quota / 1.megabyte
        end
      end

      describe "update" do
        before :once do
          @account = Account.default
          course_with_teacher(account: @account, active_all: true)
        end

        before { user_session(@teacher) }

        it "ignores storage_quota" do
          post "update", params: { id: @course.id, course: { public_description: "wat", storage_quota: 111.megabytes } }
          @course.reload
          expect(@course.public_description).to eq "wat"
          expect(@course.storage_quota).to eq @account.default_storage_quota
        end

        it "ignores storage_quota_mb" do
          post "update", params: { id: @course.id, course: { public_description: "wat", storage_quota_mb: 111 } }
          @course.reload
          expect(@course.public_description).to eq "wat"
          expect(@course.storage_quota_mb).to eq @account.default_storage_quota / 1.megabyte
        end
      end
    end
  end

  describe "DELETE 'test_student'" do
    before :once do
      @account = Account.default
      course_with_teacher(account: @account, active_all: true)
      @quiz = @course.quizzes.create!
      @quiz.workflow_state = "available"
      @quiz.save
    end

    it "removes existing quiz submissions created by the test student" do
      user_session(@teacher)
      post "student_view", params: { course_id: @course.id }
      test_student = @course.student_view_student
      @quiz.generate_submission(test_student)
      expect(test_student.quiz_submissions.size).not_to be_zero

      delete "reset_test_student", params: { course_id: @course.id }
      test_student.reload
      expect(test_student.quiz_submissions.size).to be_zero
    end

    it "removes submissions created by the test student" do
      user_session(@teacher)
      post "student_view", params: { course_id: @course.id }
      test_student = @course.student_view_student
      assignment = @course.assignments.create!(workflow_state: "published")
      assignment.grade_student test_student, { grade: 1, grader: @teacher }
      expect(test_student.submissions.size).not_to be_zero
      submission = test_student.submissions.first
      auditor_rec = submission.auditor_grade_change_records.first
      expect(auditor_rec).to_not be_nil
      attachment = attachment_model
      OriginalityReport.create!(attachment:, originality_score: "1", submission: test_student.submissions.first)
      submission.canvadocs_annotation_contexts.create!(
        root_account: @course.root_account,
        attachment:,
        launch_id: "1234"
      )
      delete "reset_test_student", params: { course_id: @course.id }
      test_student.reload
      expect(test_student.submissions.size).to be_zero
      expect(Auditors::ActiveRecord::GradeChangeRecord.where(id: auditor_rec.id).count).to be_zero
    end

    it "removes provisional grades for the test student" do
      user_session(@teacher)
      post "student_view", params: { course_id: @course.id }
      test_student = @course.student_view_student
      assignment = @course.assignments.create!(workflow_state: "published", moderated_grading: true, grader_count: 2)
      assignment.grade_student test_student, { grade: 1, grader: @teacher, provisional: true }
      file = assignment.attachments.create! uploaded_data: default_uploaded_data
      assignment.submissions.first.add_comment(commenter: @teacher, message: "blah", provisional: true, attachments: [file])
      assignment.moderated_grading_selections.where(student: test_student).first.update_attribute(:provisional_grade, ModeratedGrading::ProvisionalGrade.last)

      expect(test_student.submissions.size).not_to be_zero
      delete "reset_test_student", params: { course_id: @course.id }
      test_student.reload
      expect(test_student.submissions.size).to be_zero
    end

    it "decrements needs grading counts" do
      user_session(@teacher)
      post "student_view", params: { course_id: @course.id }
      test_student = @course.student_view_student
      assignment = @course.assignments.create!(workflow_state: "published")
      s = assignment.find_or_create_submission(test_student)
      s.submission_type = "online_quiz"
      s.workflow_state = "submitted"
      s.save!
      assignment.reload

      original_needs_grading_count = assignment.needs_grading_count

      delete "reset_test_student", params: { course_id: @course.id }
      assignment.reload

      expect(assignment.needs_grading_count).to eq original_needs_grading_count - 1
    end

    it "removes outcome results for the test student" do
      user_session(@teacher)
      outcome_with_rubric(course: @course)
      rubric_association_model(rubric: @rubric)

      test_student = @course.student_view_student
      session[:become_user_id] = test_student.id
      rubric_assessment_model(rubric_association: @rubric_association, user: test_student)
      expect(test_student.learning_outcome_results.active.size).not_to be_zero
      expect(@outcome.assessed?).to be_truthy

      delete "reset_test_student", params: { course_id: @course.id }

      test_student.reload
      expect(test_student.learning_outcome_results.active.size).to be_zero
      expect(@outcome.assessed?).to be_falsey
    end
  end

  describe "GET #permissions" do
    before do
      course_with_teacher(active_all: true)
      user_session(@teacher)
    end

    it "returns a json representation for provided permission keys" do
      get :permissions, params: { course_id: @course.id, permissions: :manage_grades }, format: :json
      json = json_parse(response.body)
      expect(json.keys).to include "manage_grades"
    end
  end

  describe "POST start_offline_web_export" do
    it "starts a web zip export" do
      course_with_student_logged_in(active_all: true)
      @course.root_account.settings[:enable_offline_web_export] = true
      @course.root_account.save!
      @course.update_attribute(:enable_offline_web_export, true)
      @course.save!
      expect { post "start_offline_web_export", params: { course_id: @course.id } }
        .to change { @course.reload.web_zip_exports.count }.by(1)
      expect(response).to be_redirect
    end
  end

  describe "GET start_offline_web_export" do
    it "starts a web zip export" do
      course_with_student_logged_in(active_all: true)
      @course.root_account.settings[:enable_offline_web_export] = true
      @course.root_account.save!
      @course.update_attribute(:enable_offline_web_export, true)
      @course.save!
      expect { get "start_offline_web_export", params: { course_id: @course.id } }
        .to change { @course.reload.web_zip_exports.count }.by(1)
      expect(response).to be_redirect
    end
  end

  describe "#users" do
    let(:course) { Course.create! }

    let(:teacher) { teacher_in_course(course:, active_all: true).user }

    let(:student1) { student_in_course(course:, active_all: true).user }

    let(:student2) { student_in_course(course:, active_all: true).user }

    let!(:group1) do
      group = course.groups.create!(name: "group one")
      group.users << student1
      group.users << student2
      group.group_memberships.last.update!(workflow_state: "deleted")
      group.reload
    end

    let!(:group2) do
      group = course.groups.create!(name: "group one")
      group.users << student1
      group.users << student2
      group.group_memberships.first.update!(workflow_state: "deleted")
      group.reload
    end

    it "does not set pagination total_pages/last page link" do
      user_session(teacher)
      # need two pages or the first page will also be the last_page
      student1
      student2

      get "users", params: {
        course_id: course.id,
        format: "json",
        enrollment_role: "StudentEnrollment",
        per_page: 1
      }
      expect(response).to be_successful
      expect(response.headers.to_a.find { |a| a.first.downcase == "link" }.last).to_not include("last")
    end

    it "only returns group_ids for active group memberships when requested" do
      user_session(teacher)
      get "users", params: {
        course_id: course.id,
        format: "json",
        include: ["group_ids"],
        enrollment_role: "StudentEnrollment"
      }
      json = json_parse(response.body)
      expect(json[0]).to include({ "id" => student1.id, "group_ids" => [group1.id] })
      expect(json[1]).to include({ "id" => student2.id, "group_ids" => [group2.id] })
    end

    it "can take student uuids as inputs and output uuids in json" do
      user_session(teacher)
      get "users", params: {
        course_id: course.id,
        user_uuids: [student1.uuid],
        format: "json",
        include: ["uuid"],
        enrollment_role: "StudentEnrollment"
      }
      json = json_parse(response.body)
      expect(json.count).to eq(1)
      expect(json[0]).to include({ "id" => student1.id, "uuid" => student1.uuid })
    end

    it "can sort users" do
      student1.update!(name: "Student B")
      student2.update!(name: "Student A")

      user_session(teacher)
      get "users", params: {
        course_id: course.id,
        format: "json",
        enrollment_role: "StudentEnrollment",
        sort: "username"
      }
      json = json_parse(response.body)
      expect(json[0]).to include({ "id" => student2.id })
      expect(json[1]).to include({ "id" => student1.id })
    end
  end

  describe "#content_share_users" do
    before :once do
      course_with_teacher(name: "search teacher", active_all: true)
    end

    it "requires a search term" do
      user_session(@teacher)
      get "content_share_users", params: { course_id: @course.id }
      expect(response).to be_bad_request
    end

    it "requires the user to have an admin role for the course" do
      course_with_student_logged_in
      get "content_share_users", params: { course_id: @course.id, search_term: "teacher" }
      expect(response).to be_unauthorized

      course_with_designer(name: "course designer", course: @course, active_all: true)
      user_session(@designer)
      get "content_share_users", params: { course_id: @course.id, search_term: "teacher" }
      json = json_parse(response.body)
      expect(json[0]).to include({ "name" => "search teacher" })
    end

    it "returns email, url avatar (if avatars are enabled), and name" do
      user_session(@teacher)
      @search_context = @course
      course_with_teacher(name: "course teacher")
      @teacher.account.enable_service(:avatars)
      get "content_share_users", params: { course_id: @search_context.id, search_term: "course" }
      json = json_parse(response.body)
      expect(json[0]).to include({ "email" => nil, "name" => "course teacher" })
    end

    it "searches by name and email" do
      user_session(@teacher)
      @teacher.account.enable_service(:avatars)
      user_model(name: "course teacher")
      communication_channel_model(user: @user, path: "course_teacher@test.edu")
      course_with_teacher(user: @user, course: @course)

      user_model(name: "course designer")
      communication_channel_model(user: @user, path: "course_designer@test.edu")
      course_with_teacher(user: @user, course: @course)

      get "content_share_users", params: { course_id: @course.id, search_term: "course teacher" }
      json = json_parse(response.body)
      expect(json[0]).to include({ "email" => "course_teacher@test.edu", "name" => "course teacher" })

      get "content_share_users", params: { course_id: @course.id, search_term: "course_designer@test.edu" }
      json = json_parse(response.body)
      expect(json[0]).to include({ "email" => "course_designer@test.edu", "name" => "course designer" })
    end

    it "searches for teachers, TAs, and designers" do
      user_session(@teacher)
      @search_context = @course
      course_with_teacher(name: "course teacher")
      course_with_ta(name: "course ta")
      course_with_designer(name: "course designer")
      course_with_student(name: "course student")
      course_with_observer(name: "course observer")
      get "content_share_users", params: { course_id: @search_context.id, search_term: "course" }
      json = json_parse(response.body)
      expect(json.pluck("name")).to eq(["course designer", "course ta", "course teacher"])
    end

    it "does not return users with only deleted enrollments or deleted courses" do
      user_session(@teacher)
      @search_context = @course
      course_with_teacher(name: "course teacher").destroy
      get "content_share_users", params: { course_id: @search_context.id, search_term: "course" }
      json = json_parse(response.body)
      expect(json.pluck("name")).not_to include("course teacher")

      course_with_ta(name: "course ta")
      @course.destroy
      get "content_share_users", params: { course_id: @search_context.id, search_term: "course" }
      json = json_parse(response.body)
      expect(json.pluck("name")).not_to include("course ta")
    end

    it "search for root and sub-account admins" do
      user_session(@teacher)
      @search_context = @course
      sub_account = account_model(parent_account: @course.root_account)
      account_admin = user_factory(name: "account admin")
      sub_account_admin = user_factory(name: "sub-account admin")
      account_admin_user(account: @course.root_account, user: account_admin)
      account_admin_user(account: sub_account, user: sub_account_admin)

      get "content_share_users", params: { course_id: @search_context.id, search_term: "admin" }
      json = json_parse(response.body)
      expect(json.pluck("name")).to eq(["account admin", "sub-account admin"])
    end

    it "does not return users with deleted admin accounts" do
      user_session(@teacher)
      sub_account = account_model(parent_account: @course.root_account)
      account_admin = user_factory(name: "account admin")
      sub_account_admin = user_factory(name: "sub-account admin")
      account_admin_user(account: @course.root_account, user: account_admin).destroy
      account_admin_user(account: sub_account, user: sub_account_admin)
      sub_account.destroy

      get "content_share_users", params: { course_id: @course.id, search_term: "admin" }
      json = json_parse(response.body)
      expect(json.pluck("name")).not_to include("account admin", "sub-account admin")
    end

    it "returns the searching user" do
      user_session(@teacher)
      @search_context = @course
      course_with_teacher(name: "course teacher")
      get "content_share_users", params: { course_id: @search_context.id, search_term: "teacher" }
      json = json_parse(response.body)
      expect(json.pluck("name")).to match_array(["course teacher", "search teacher"])
    end

    it 'does not return admin roles that do not have the "manage_content" permission' do
      user_session(@teacher)
      account_admin = user_factory(name: "less privileged account admin")
      role = custom_account_role("manage_content", account: @course.root_account)
      account_admin_user(account: @course.root_account, user: account_admin, role:)

      get "content_share_users", params: { course_id: @course.id, search_term: "less privileged" }
      json = json_parse(response.body)
      expect(json.pluck("name")).not_to include("less privileged account admin")

      role.role_overrides.create!(enabled: true, permission: "manage_content", context: @course.root_account)
      get "content_share_users", params: { course_id: @course.id, search_term: "less privileged" }
      json = json_parse(response.body)
      expect(json.pluck("name")).to include("less privileged account admin")
    end

    it "does not return users from other root accounts" do
      user_session(@teacher)
      a1_course = @course
      a2 = Account.create!(name: "other root account")
      a2_admin = user_factory(name: "account 2 admin")
      a2_teacher = user_factory(name: "account 2 teacher")
      account_admin_user(account: a2, user: a2_admin)
      course_with_teacher(name: "account 2 teacher", account: a2, user: a2_teacher)

      get "content_share_users", params: { course_id: a1_course.id, search_term: "account 2" }
      json = json_parse(response.body)
      expect(json.pluck("name")).not_to include("account 2 admin", "account 2 teacher")
    end

    it "still works for teachers whose course is concluded by term" do
      term = Account.default.enrollment_terms.create!(name: "long over")
      term.set_overrides(Account.default, "TeacherEnrollment" => { start_at: "2014-12-01", end_at: "2014-12-31" })
      course_with_teacher_logged_in(active_all: true)
      @course.update(enrollment_term: term)

      get "content_share_users", params: { course_id: @course.id, search_term: "teacher" }
      json = json_parse(response.body)
      expect(json[0]).to include({ "name" => "search teacher" })
    end

    it "does not include pending users" do
      user_session(@teacher)
      @search_context = @course
      course_with_teacher(name: "pending user")
      @user.update_attribute(:workflow_state, "creation_pending")
      course_with_teacher(name: "not pending user", active_all: true)
      get "content_share_users", params: { course_id: @search_context.id, search_term: "pending" }
      json = json_parse(response.body)
      expect(json.length).to be(1)
      expect(json[0]).to include({ "name" => "not pending user" })
    end

    context "sharding" do
      specs_require_sharding

      it "still has a functional query when user is from another shard" do
        @shard1.activate do
          @cs_user = User.create!
        end
        @course.enroll_teacher(@cs_user, enrollment_state: "active")
        user_session(@cs_user)

        sql = nil
        allow(Api).to receive(:paginate) do |scope, _controller, _url|
          sql = scope.to_sql
        end

        get "content_share_users", params: { course_id: @course.id, search_term: "hiyo" }
        expect(sql).to_not include(@shard1.name) # can't just check for success since the query can still work depending on test shard setup
      end
    end
  end

  describe "POST update" do
    it "allows an admin to change visibility" do
      admin = account_admin_user
      course = Course.create!
      user_session(admin)

      post "update", params: { id: course.id,
                               course: { course_visibility: "public", indexed: true } }

      course.reload
      expect(course.is_public).to be true
      expect(course.indexed).to be true
    end

    it "allows the teacher to change visibility" do
      course = Course.create!
      teacher = teacher_in_course(course:, active_all: true).user
      user_session(teacher)

      post "update", params: { id: course.id,
                               course: { course_visibility: "public", indexed: true } }

      course.reload
      expect(course.is_public).to be true
      expect(course.indexed).to be true
    end

    it "does not allow a teacher without the permission to change visibility" do
      course = Course.create!
      teacher = teacher_in_course(course:, active_all: true).user
      course.account.role_overrides.create!(role: teacher_role, permission: "manage_course_visibility", enabled: false)
      user_session(teacher)

      post "update", params: { id: course.id,
                               course: { course_visibility: "public", indexed: true } }

      course.reload
      expect(course.is_public).not_to be true
      expect(course.indexed).not_to be true
    end

    it "does not allow an account admin without the permission to change visibility" do
      admin = account_admin_user_with_role_changes(role_changes: { "manage_course_visibility" => false })
      course = Course.create!
      user_session(admin)

      post "update", params: { id: course.id,
                               course: { course_visibility: "public", indexed: true } }

      course.reload
      expect(course.is_public).not_to be true
      expect(course.indexed).not_to be true
    end

    it "allows a site admin to change visibility even if account admins cannot" do
      site_admin = site_admin_user
      account = Account.create(name: "fake-o")
      account_with_role_changes(account:, role_changes: { "manage_course_visibility" => false })
      course = course_factory(account:)
      user_session(site_admin)

      post "update", params: { id: course.id,
                               course: { course_visibility: "public", indexed: true } }

      course.reload
      expect(course.is_public).to be true
      expect(course.indexed).to be true
    end
  end

  describe "POST 'copy_course'" do
    let(:course) { Course.create! }

    before do
      course.wiki_pages.create!(title: "my page")
      user_session(site_admin_user)
    end

    it "copies a course" do
      post "copy_course", params: { course_id: course.id,
                                    course: { name: "copied course", course_code: "copied" } }
      expect(response).to be_redirect
      run_jobs
      new_course = Course.last
      expect(new_course.name).to eq "copied course"
      expect(new_course.wiki_pages.length).to eq 1
      expect(new_course.wiki_pages.first.title).to eq "my page"
    end

    it "does not apply an account's course template" do
      template = course.account.courses.create!(name: "Template Course", template: true)
      template.assignments.create!(title: "my assignment")
      course.root_account.enable_feature!(:course_templates)
      course.account.update!(course_template: template)

      post "copy_course", params: { course_id: course.id,
                                    course: { name: "copied course", course_code: "copied" } }
      expect(response).to be_redirect
      run_jobs
      new_course = Course.last
      expect(new_course.name).to eq "copied course"
      expect(new_course.wiki_pages.length).to eq 1
      expect(new_course.assignments.length).to eq 0
    end
  end

  describe "visible_self_enrollment_option" do
    before :once do
      Account.default.allow_self_enrollment!
      @user = user_factory(active_all: true)
      @course = course_factory(active_all: true)
    end

    before do
      user_session(@user)
    end

    context "when self_enrollment and open_enrollment is enabled" do
      before :once do
        @course.self_enrollment = true
        @course.open_enrollment = true
        @course.save!
      end

      it "returns :enroll if user is not enrolled" do
        get "show", params: { id: @course.id }

        expect(controller.visible_self_enrollment_option).to be(:enroll)
      end

      it "returns :unenroll if user has self-enrolled" do
        enrollment = @course.enroll_student(@user, enrollment_state: "active")
        enrollment.self_enrolled = true
        enrollment.save!

        get "show", params: { id: @course.id }
        expect(controller.visible_self_enrollment_option).to be(:unenroll)
      end

      it "returns nil if user is enrolled (but not self_enrolled)" do
        @course.enroll_student(@user, enrollment_state: "active")

        get "show", params: { id: @course.id }
        expect(controller.visible_self_enrollment_option).to be_nil
      end

      it "returns nil if user self-enrolled but the course is concluded" do
        enrollment = @course.enroll_student(@user, enrollment_state: "active")
        enrollment.self_enrolled = true
        enrollment.save!
        @course.complete!

        get "show", params: { id: @course.id }
        expect(controller.visible_self_enrollment_option).to be_nil
      end

      it "returns nil if course enabled options but account disabled self-enrollment" do
        Account.default.allow_self_enrollment!("")

        get "show", params: { id: @course.id }
        expect(controller.visible_self_enrollment_option).to be_nil
      end
    end

    it "returns nil if self_enrollment is disabled" do
      @course.open_enrollment = true
      @course.save!

      get "show", params: { id: @course.id }
      expect(controller.visible_self_enrollment_option).to be_nil
    end

    it "returns nil if open_enrollment is disabled" do
      @course.self_enrollment = true
      @course.save!

      get "show", params: { id: @course.id }
      expect(controller.visible_self_enrollment_option).to be_nil
    end
  end

  describe "POST 'dismiss_migration_limitation_msg'" do
    before do
      course_with_teacher(name: "search teacher", active_all: true)
      @quiz_migration_alert =
        QuizMigrationAlert.create!(user_id: @teacher.id, course_id: @course.id, migration_id: "10000000000040")
    end

    context "when the current user has a quiz migration alert for the course" do
      before do
        user_session(@teacher)
      end

      it "returns a successful response" do
        post "dismiss_migration_limitation_msg", params: { id: @course.id }
        expect(response).to be_successful
      end

      it "destroys the quiz migration alert" do
        expect do
          post "dismiss_migration_limitation_msg", params: { id: @course.id }
        end.to change { @teacher.quiz_migration_alerts.count }.from(1).to(0)
      end
    end

    context "when the current user does not have a quiz migration alert for the course" do
      before do
        other_user = user_model
        user_session(other_user)
      end

      it "returns a not_found response" do
        post "dismiss_migration_limitation_msg", params: { id: @course.id }
        expect(response).to be_not_found
      end

      it "does not destroy quiz migration alerts" do
        expect do
          post "dismiss_migration_limitation_msg", params: { id: @course.id }
        end.to not_change { QuizMigrationAlert.count }
      end
    end
  end
end
