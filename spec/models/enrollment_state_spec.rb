# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe EnrollmentState do
  describe "#enrollments_needing_calculation" do
    it "finds enrollments that need calculation" do
      course_factory
      student_in_course(course: @course)

      invalidated_enroll1 = student_in_course(course: @course)
      EnrollmentState.where(enrollment_id: invalidated_enroll1).update_all(state_is_current: false)
      invalidated_enroll2 = student_in_course(course: @course)
      EnrollmentState.where(enrollment_id: invalidated_enroll2).update_all(access_is_current: false)

      expect(EnrollmentState.enrollments_needing_calculation.to_a).to match_array([invalidated_enroll1, invalidated_enroll2])
    end

    it "is able to use a scope" do
      course_factory
      enroll = student_in_course(course: @course)
      EnrollmentState.where(enrollment_id: enroll).update_all(state_is_current: false)

      expect(EnrollmentState.enrollments_needing_calculation(Enrollment.where.not(id: nil)).to_a).to eq [enroll]
      expect(EnrollmentState.enrollments_needing_calculation(Enrollment.where(id: nil)).to_a).to be_empty
    end
  end

  describe "#process_states_for" do
    before :once do
      course_factory(active_all: true)
      @enrollment = student_in_course(course: @course)
    end

    it "reprocesses invalidated states" do
      EnrollmentState.where(enrollment_id: @enrollment).update_all(state_is_current: false, state: "somethingelse")

      @enrollment.reload
      EnrollmentState.process_states_for(@enrollment)

      @enrollment.reload
      expect(@enrollment.enrollment_state.state_is_current?).to be_truthy
      expect(@enrollment.enrollment_state.state).to eq "invited"
    end

    it "reprocesses invalidated accesses" do
      EnrollmentState.where(enrollment_id: @enrollment).update_all(access_is_current: false, restricted_access: true)

      @enrollment.reload
      EnrollmentState.process_states_for(@enrollment)

      @enrollment.reload
      expect(@enrollment.enrollment_state.access_is_current?).to be_truthy
      expect(@enrollment.enrollment_state.restricted_access?).to be_falsey
    end
  end

  describe "state invalidation" do
    it "invalidates enrollments after enrollment term date change" do
      course_factory(active_all: true)
      other_enroll = student_in_course(course: @course)

      term = Account.default.enrollment_terms.create!
      course_factory(active_all: true)
      @course.enrollment_term = term
      @course.save!
      term_enroll = student_in_course(course: @course)

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once).with(not_eq(other_enroll))

      term.reload
      end_at = 2.days.ago
      term.end_at = end_at
      term.save!

      term_enroll.reload
      expect(term_enroll.enrollment_state.state_is_current?).to be_falsey

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      state = term_enroll.enrollment_state
      state.ensure_current_state
      expect(state.state).to eq "completed"
      expect(state.state_started_at).to eq end_at
    end

    it "invalidates enrollments after enrollment term role-specific date change" do
      term = Account.default.enrollment_terms.create!
      course_factory(active_all: true)
      @course.enrollment_term = term
      @course.save!
      other_enroll = teacher_in_course(course: @course)
      term_enroll = student_in_course(course: @course)

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once).with(term_enroll)

      override = term.enrollment_dates_overrides.new(enrollment_type: "StudentEnrollment", enrollment_term: term, context: term.root_account)
      start_at = 2.days.from_now
      override.start_at = start_at
      override.save!

      term_enroll.reload
      expect(term_enroll.enrollment_state.state_is_current?).to be_falsey

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      state = term_enroll.enrollment_state
      state.ensure_current_state
      expect(state.state).to eq "pending_invited"
      expect(state.state_valid_until).to eq start_at
    end

    it "invalidates enrollments after course date changes" do
      course_factory(active_all: true)
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(course: @course)
      enroll_state = enroll.enrollment_state

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once) { |e| expect(e.course).to eq @course }

      @course.start_at = 4.days.ago
      ended_at = 3.days.ago
      @course.conclude_at = ended_at
      @course.save!

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq "completed"
      expect(enroll_state.state_started_at).to eq ended_at
    end

    it "invalidates enrollments after changing course setting overriding term dates" do
      course_factory(active_all: true)
      enroll = student_in_course(course: @course)
      enroll_state = enroll.enrollment_state

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once) { |e| expect(e.course).to eq @course }

      @course.start_at = 4.days.ago
      ended_at = 3.days.ago
      @course.conclude_at = ended_at
      @course.save!

      # should not have changed yet - not overriding term dates
      expect(enroll_state.state_is_current?).to be_truthy

      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq "completed"
      expect(enroll_state.state_started_at).to eq ended_at
    end

    it "invalidates enrollments after changing course section dates" do
      course_factory(active_all: true)
      other_enroll = student_in_course(course: @course)

      section = @course.course_sections.create!
      enroll = student_in_course(course: @course, section:)
      enroll_state = enroll.enrollment_state

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once) { |e| expect(e.course_section).to eq section }

      section.restrict_enrollments_to_section_dates = true
      section.save!
      start_at = 1.day.from_now
      section.start_at = start_at
      section.save!

      other_enroll.reload
      expect(other_enroll.enrollment_state.state_is_current?).to be_truthy

      enroll_state.reload
      expect(enroll_state.state_is_current?).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.state).to eq "pending_invited"
      expect(enroll_state.state_valid_until).to eq start_at
    end

    context "temporary enrollments" do
      let_once(:start_at) { 1.day.ago }
      let_once(:end_at) { 1.day.from_now }

      before(:once) do
        Account.default.enable_feature!(:temporary_enrollments)
        @provider = user_factory(active_all: true)
        @recipient = user_factory(active_all: true)
        course1 = course_with_teacher(active_all: true, user: @provider).course
        course2 = course_with_teacher(active_all: true, user: @provider).course
        temporary_enrollment_pairing = TemporaryEnrollmentPairing.create!(root_account: Account.default, created_by: account_admin_user)
        @enrollment1 = course1.enroll_user(
          @recipient,
          "TeacherEnrollment",
          {
            role: teacher_role,
            temporary_enrollment_source_user_id: @provider.id,
            temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
            start_at:,
            end_at:
          }
        )
        @enrollment2 = course2.enroll_user(
          @recipient,
          "TeacherEnrollment",
          {
            role: teacher_role,
            temporary_enrollment_source_user_id: @provider.id,
            temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
            start_at:,
            end_at:
          }
        )
        @enrollment_state1 = @enrollment1.enrollment_state
        @enrollment_state2 = @enrollment2.enrollment_state
      end

      it "invalidates temporary enrollments after end_date has been reached" do
        @enrollment1.update!(end_at: 1.day.ago)

        expect(@enrollment1.reload).to be_deleted
        expect(@enrollment2.reload).to be_active
        expect(@enrollment_state1.reload.state).to eq "deleted"
        expect(@enrollment_state1.reload.state_started_at).to be_truthy
        expect(@enrollment_state2.reload.state).to eq "active"
      end

      it "respects accepted pairing ending enrollment states after end_date has been reached" do
        @enrollment1.temporary_enrollment_pairing.update!(ending_enrollment_state: "completed")
        @enrollment1.update!(end_at: 1.day.ago)

        expect(@enrollment1.reload.workflow_state).to eq "active"
        expect(@enrollment2.reload).to be_active
        expect(@enrollment_state1.reload.state).to eq "completed"
        expect(@enrollment_state2.reload.state).to eq "active"

        @enrollment1.temporary_enrollment_pairing.update!(ending_enrollment_state: "inactive")
        @enrollment1.update!(end_at: 1.day.ago)
        expect(@enrollment_state1.reload.state).to eq "inactive"

        @enrollment1.temporary_enrollment_pairing.update!(ending_enrollment_state: "deleted")
        @enrollment1.update!(end_at: 1.day.ago)
        expect(@enrollment_state1.reload.state).to eq "deleted"
      end

      it "defaults to deleted for null pairing ending enrollment state" do
        @enrollment1.temporary_enrollment_pairing.update!(ending_enrollment_state: nil)
        @enrollment1.update!(end_at: 1.day.ago)
        expect(@enrollment_state1.reload.state).to eq "deleted"
      end
    end

    it "doesn't recompute enrollment states due to course date truncation" do
      student_in_course(active_all: true)
      @course.restrict_enrollments_to_course_dates = true
      @course.conclude_at = "2023-07-16T03:59:59.999999Z"
      @course.save!

      expect(EnrollmentState).not_to receive(:invalidate_states_for_course_or_section)
      course = Course.find(@course.id)
      course.conclude_at = "2023-07-16T03:59:59.999990Z"
      course.save!
    end

    it "doesn't recompute enrollment states due to section date truncation" do
      student_in_course(active_all: true)
      section = @course.default_section
      section.restrict_enrollments_to_section_dates = true
      section.end_at = "2023-07-16T03:59:59.999999Z"
      section.save!

      expect(EnrollmentState).not_to receive(:invalidate_states_for_course_or_section)
      section = CourseSection.find(section.id)
      section.end_at = "2023-07-16T03:59:59.999990Z"
      section.save!
    end
  end

  describe "access invalidation" do
    def restrict_view(account, type)
      account.settings[type] = { value: true, locked: false }
      account.save!
    end

    it "invalidates access for future students when account future access settings are changed" do
      course_factory(active_all: true)
      other_enroll = student_in_course(course: @course)
      other_state = other_enroll.enrollment_state

      future_enroll = student_in_course(course: @course)
      start_at = 2.days.from_now
      future_enroll.start_at = start_at
      future_enroll.end_at = 3.days.from_now
      future_enroll.save!

      future_state = future_enroll.enrollment_state
      expect(future_state.state).to eq "pending_invited"
      expect(future_state.state_valid_until).to eq start_at
      expect(future_state.restricted_access?).to be_falsey

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once).with(not_eq(other_enroll))

      restrict_view(Account.default, :restrict_student_future_view)

      future_state.reload
      expect(future_state.access_is_current).to be_falsey
      other_state.reload
      expect(other_state.access_is_current).to be_truthy

      future_state.ensure_current_state
      expect(future_state.restricted_access).to be_truthy
      future_enroll.reload
      expect(future_enroll).to be_inactive
    end

    it "invalidates access for past students when past access settings are changed" do
      course_factory(active_all: true)
      other_enroll = student_in_course(course: @course)
      other_state = other_enroll.enrollment_state

      sub_account = Account.default.sub_accounts.create!

      course_factory(active_all: true, account: sub_account)
      @course.start_at = 3.days.ago
      @course.conclude_at = 2.days.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      past_enroll = student_in_course(course: @course)

      past_state = past_enroll.enrollment_state
      expect(past_state.state).to eq "completed"

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once).with(not_eq(other_enroll))

      restrict_view(Account.default, :restrict_student_past_view)

      past_state.reload
      expect(past_state.access_is_current).to be_falsey
      other_state.reload
      expect(other_state.access_is_current).to be_truthy

      past_state.ensure_current_state
      expect(past_state.restricted_access).to be_truthy
      past_enroll.reload
      expect(past_enroll).to be_inactive
    end

    it "invalidates access when course access settings change" do
      course_factory(active_all: true)
      @course.start_at = 3.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(course: @course)
      enroll_state = enroll.enrollment_state

      expect(enroll_state.state).to eq "pending_invited"

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once) { |e| expect(e.course).to eq @course }
      @course.restrict_student_future_view = true
      @course.save!

      enroll_state.reload
      expect(enroll_state.access_is_current).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.restricted_access).to be_truthy
      enroll.reload
      expect(enroll).to be_inactive
    end

    it "invalidates access properly if dates and access settings are changed simultaneously" do
      course_factory(active_all: true)
      @course.start_at = 3.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      enroll = student_in_course(course: @course)
      enroll_state = enroll.enrollment_state

      expect(enroll_state.state).to eq "pending_invited"

      expect(EnrollmentState).to receive(:update_enrollment).at_least(:once) { |e| expect(e.course).to eq @course }
      @course.start_at = 2.days.from_now
      @course.restrict_student_future_view = true
      @course.save!

      enroll_state.reload
      expect(enroll_state.access_is_current).to be_falsey
      expect(enroll_state.state_is_current).to be_falsey

      enroll_state.ensure_current_state
      expect(enroll_state.restricted_access).to be_truthy
    end
  end

  describe "#recalculate_expired_states" do
    it "recalculates expired states" do
      course_factory(active_all: true)
      @course.start_at = 3.days.from_now
      end_at = 5.days.from_now
      @course.conclude_at = end_at
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      enroll = student_in_course(course: @course)
      enroll_state = enroll.enrollment_state
      expect(enroll_state.state).to eq "pending_invited"

      Timecop.freeze(4.days.from_now) do
        EnrollmentState.recalculate_expired_states
        enroll_state.reload
        expect(enroll_state.state).to eq "invited"
      end

      Timecop.freeze(6.days.from_now) do
        EnrollmentState.recalculate_expired_states
        enroll_state.reload
        expect(enroll_state.state).to eq "completed"
      end
    end
  end

  it "does not cache the wrong state when setting to 'invited'" do
    course_factory(active_all: true)
    e = student_in_course(course: @course)
    e.reject!
    RequestCache.enable do
      e.workflow_state = "invited"
      e.save!
      expect(e.invited?).to be_truthy
    end
  end
end
