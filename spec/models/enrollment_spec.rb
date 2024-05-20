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

describe Enrollment do
  subject(:enrollment) { @enrollment }

  before(:once) do
    @user = User.create!
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
  end

  it { is_expected.to be_valid }

  describe "workflow" do
    subject(:enrollment) { @enrollment.tap(&:save!) }

    describe "invited" do
      it { is_expected.to be_invited }

      it "can transition to rejected" do
        enrollment.reject!
        expect(enrollment).to be_rejected
      end

      it "updates the user when rejected" do
        expect(enrollment.user).to receive(:touch).at_least(1).times
        enrollment.reject!
      end

      it "can transition to completed" do
        enrollment.complete!
        expect(enrollment).to be_completed
      end
    end

    describe "creation_pending" do
      subject(:enrollment) do
        @enrollment.tap { |e| e.update!(workflow_state: :creation_pending) }
      end

      it { is_expected.to be_creation_pending }

      it "can transition to invited" do
        enrollment.invite!
        expect(enrollment).to be_invited
      end
    end

    describe "active" do
      subject(:enrollment) do
        @enrollment.tap { |e| e.update!(workflow_state: :active) }
      end

      it { is_expected.to be_active }

      it "can transition to rejected" do
        enrollment.reject!
        expect(enrollment).to be_rejected
      end

      it "updates the user when rejected" do
        expect(enrollment.user).to receive(:touch).at_least(1).times
        enrollment.reject!
      end

      it "can transition to completed" do
        enrollment.complete!
        expect(enrollment).to be_completed
      end
    end

    describe "deleted" do
      subject { @enrollment.tap { |e| e.update!(workflow_state: :deleted) } }

      it { is_expected.to be_deleted }
    end

    describe "rejected" do
      subject(:enrollment) do
        @enrollment.tap { |e| e.update!(workflow_state: :rejected) }
      end

      it { is_expected.to be_rejected }

      it "can transition to invited" do
        enrollment.unreject!
        expect(enrollment).to be_invited
      end
    end

    describe "completed" do
      subject { @enrollment.tap { |e| e.update!(workflow_state: :completed) } }

      it { is_expected.to be_completed }
    end

    describe "inactive" do
      subject { @enrollment.tap { |e| e.update!(workflow_state: :inactive) } }

      it { is_expected.to be_inactive }
    end
  end

  it "is pending if it is invited or creation_pending" do
    enrollment_model(workflow_state: "invited")
    expect(@enrollment).to be_pending
    @enrollment.destroy_permanently!

    enrollment_model(workflow_state: "creation_pending")
    expect(@enrollment).to be_pending
  end

  it "has a context_id as the course_id" do
    expect(@enrollment.course.id).not_to be_nil
    expect(@enrollment.context_id).to eql(@enrollment.course.id)
  end

  it "has a readable_type of Teacher for a TeacherEnrollment" do
    e = TeacherEnrollment.new
    e.type = "TeacherEnrollment"
    expect(e.readable_type).to eql("Teacher")
  end

  it "has a readable_type of Student for a StudentEnrollment" do
    e = StudentEnrollment.new
    e.type = "StudentEnrollment"
    expect(e.readable_type).to eql("Student")
  end

  it "has a readable_type of TaEnrollment for a TA" do
    e = TaEnrollment.new(valid_enrollment_attributes)
    e.type = "TaEnrollment"
    expect(e.readable_type).to eql("TA")
  end

  it "has a defalt readable_type of Student" do
    e = Enrollment.new
    e.type = "Other"
    expect(e.readable_type).to eql("Student")
  end

  describe "#student_or_fake_student?" do
    it "returns true for students" do
      expect(StudentEnrollment.create!(valid_enrollment_attributes).student_or_fake_student?).to be true
    end

    it "returns true for fake students" do
      fake_student_enrollment = @course.enroll_user(@enrollment.user, "StudentViewEnrollment")
      expect(fake_student_enrollment.student_or_fake_student?).to be true
    end

    it "returns false for non-students" do
      expect(TaEnrollment.create!(valid_enrollment_attributes).student_or_fake_student?).to be false
    end
  end

  describe "sis_role" do
    it "returns role_name if present" do
      role = custom_account_role("Assistant Grader", account: Account.default)
      e = TaEnrollment.new
      e.role_id = role.id
      expect(e.sis_role).to eq "Assistant Grader"
    end

    it "returns the sis enrollment type otherwise" do
      c = Account.default.courses.create!
      e = TaEnrollment.new(course: c)
      expect(e.sis_role).to eq "ta"
    end
  end

  describe "#destroy" do
    context "with overrides" do
      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        assignment = @course.assignments.create!
        @override = assignment.assignment_overrides.create!
        @override.assignment_override_students.create!(user: @enrollment.user)
      end

      let(:override_student) { @override.assignment_override_students.unscope(:where).find_by(user_id: @enrollment.user) }

      it "does not destroy assignment override students on the user if other enrollments for the user exist in the course" do
        @course.enroll_user(
          @enrollment.user,
          "StudentEnrollment",
          section: @course.course_sections.create!,
          allow_multiple_enrollments: true
        )
        @enrollment.destroy
        expect(override_student).to be_present
        expect(override_student).to be_active
      end

      it "destroys assignment override students on the user if no other enrollments for the user exist in the course" do
        @enrollment.destroy
        expect(override_student).to be_deleted
      end

      context "when the user is a final grader" do
        before(:once) do
          @teacher = User.create!
          @another_teacher = User.create!
          @course.enroll_teacher(@teacher, enrollment_state: "active", allow_multiple_enrollments: true)
          @course.enroll_teacher(@another_teacher, enrollment_state: "active", allow_multiple_enrollments: true)
          2.times { @course.assignments.create!(moderated_grading: true, final_grader: @teacher, grader_count: 2) }
          @course.assignments.create!(moderated_grading: true, final_grader: @another_teacher, grader_count: 2)
        end

        it "removes the user as final grader from all course assignments" do
          expect { @course.enrollments.find_by!(user: @teacher).destroy }.to change {
            @course.assignments.order(:created_at).pluck(:final_grader_id)
          }.from([nil, @teacher.id, @teacher.id, @another_teacher.id]).to([nil, nil, nil, @another_teacher.id])
        end

        it "does not remove the user as final grader from assignments if the user has other active enrollments of the same type" do
          section_one = @course.course_sections.create!
          @course.enroll_teacher(@teacher, active_all: true, allow_multiple_enrollments: true, section: section_one)
          expect { @course.enrollments.find_by!(user: @teacher).destroy }.not_to change {
            @course.assignments.order(:created_at).pluck(:final_grader_id)
          }.from([nil, @teacher.id, @teacher.id, @another_teacher.id])
        end

        it "does not remove the user as final grader from assignments if the user has other active instructor enrollments" do
          @course.enroll_ta(@teacher, active_all: true, allow_multiple_enrollments: true)
          expect { @course.enrollments.find_by!(user: @teacher).destroy }.not_to change {
            @course.assignments.order(:created_at).pluck(:final_grader_id)
          }.from([nil, @teacher.id, @teacher.id, @another_teacher.id])
        end
      end
    end

    it "updates user_account_associations" do
      course_with_teacher(active_all: 1)
      expect(@user.associated_accounts).to eq [Account.default]
      @enrollment.destroy
      expect(@user.associated_accounts.reload).to eq []
    end

    it "removes assignment overrides if they are only linked to this enrollment" do
      course_with_student
      assignment = assignment_model(course: @course)
      ao = AssignmentOverride.new
      ao.assignment = assignment
      ao.title = "ADHOC OVERRIDE"
      ao.workflow_state = "active"
      ao.set_type = "ADHOC"
      ao.save!
      assignment.reload
      override_student = ao.assignment_override_students.build
      override_student.user = @user
      override_student.save!

      expect(ao.workflow_state).to eq("active")
      @user.enrollments.destroy_all

      ao.reload
      expect(ao.workflow_state).to eq("deleted")
    end

    it "destroys associated scores" do
      @enrollment.save
      score = @enrollment.scores.create!
      @enrollment.destroy
      expect(score.reload).to be_deleted

      # ensure callbacks don't run if enrollment was already deleted
      expect(Enrollment).not_to receive(:recompute_final_score_in_singleton)
      @enrollment.destroy
    end
  end

  describe "restoring" do
    before(:once) do
      @course.assignments.create!
      @enrollment.save!
      @enrollment.destroy
    end

    it "restores associated scores that are deleted" do
      @enrollment.restore
      score_workflow = Score.find_by(enrollment_id: @enrollment, course_score: true).workflow_state
      expect(score_workflow).to eq("active")
    end

    it "does not restore scores associated with other enrollments" do
      new_enrollment = StudentEnrollment.create!(user: User.create!, course: @course)
      score = new_enrollment.scores.first
      score.update!(workflow_state: :deleted)
      @enrollment.restore
      expect(score.workflow_state).to eq("deleted")
    end

    it "restores associated scores that are deleted if restored by workflow state" do
      @enrollment.update!(workflow_state: :active)
      score_workflow = Score.find_by(enrollment_id: @enrollment, course_score: true).workflow_state
      expect(score_workflow).to eq("active")
    end

    it "does not restore scores associated with other enrollments if restored by workflow_state" do
      new_enrollment = StudentEnrollment.create!(user: User.create!, course: @course)
      score = new_enrollment.scores.first
      score.update!(workflow_state: :deleted)
      @enrollment.update!(workflow_state: :active)
      expect(score.workflow_state).to eq "deleted"
    end

    it "restores associated scores that are deleted if restored to inactive by workflow state" do
      @enrollment.update!(workflow_state: :inactive)
      score_workflow = Score.find_by(enrollment_id: @enrollment, course_score: true).workflow_state
      expect(score_workflow).to eq("active")
    end
  end

  describe "enrolling into a previously enrolled course" do
    let(:assignment) { @course.assignments.create!(points_possible: 10) }
    let(:section) { @course.course_sections.create! }
    let(:student) { User.create! }
    let(:teacher) do
      user = User.create!
      @course.enroll_teacher(user).accept(true)
      user
    end

    before do
      original_enrollment = @course.enroll_student(student)
      original_enrollment.accept(true)
      assignment.grade_student(student, grade: "10", grader: teacher)
      original_enrollment.destroy!
    end

    it "when there are no active enrollments, grades are recalculated" do
      # Create a new assignment while the student has no enrollment, to prove
      # that scores are being recalculated on enrollment, rather than copied.
      @course.assignments.create!(points_possible: 10)
      new_enrollment = @course.enroll_student(student, allow_multiple_enrollments: true, section:)
      expect(new_enrollment.scores.find_by!(course_score: true).final_score).to be 50.0
    end
  end

  describe "scores and grades" do
    let(:new_student_enrollment) do
      @course.enroll_user(
        @enrollment.user,
        "StudentEnrollment",
        section: @course.course_sections.create!,
        allow_multiple_enrollments: true
      )
    end

    let(:new_fake_student_enrollment) do
      @course.enroll_user(
        @enrollment.user,
        "StudentViewEnrollment",
        section: @course.course_sections.create!,
        allow_multiple_enrollments: true
      )
    end

    describe "effective_current_grade" do
      let_once(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @enrollment.scores.create!(course_score: true, current_score: 88.0)
        @enrollment.scores.create!(grading_period_id: period.id, current_score: 82.0)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      before do
        allow(@course).to receive(:grading_standard_enabled?).and_return true
      end

      it "returns the course current grade" do
        expect(@enrollment.effective_current_grade).to eq "B+"
      end

      it "returns the grading period current grade, if given a grading period" do
        expect(@enrollment.effective_current_grade(grading_period_id: period.id)).to eq "B-"
      end

      it "returns the override grade" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        expect(@enrollment.effective_current_grade).to eq "A"
      end

      it "does not return the override grade if the feature is not allowed" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.effective_current_grade).to eq "B+"
      end

      it "does not return the override grade if the feature is not enabled" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.effective_current_grade).to eq "B+"
      end

      it "returns nil if a grading standard is not enabled" do
        allow(@course).to receive(:grading_standard_enabled?).and_return false
        expect(@enrollment.effective_final_grade).to be_nil
      end
    end

    describe "effective_current_score" do
      let(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      it "returns the course current score" do
        @enrollment.scores.create!(course_score: true, current_score: 88.0)
        expect(@enrollment.effective_current_score).to eq 88.0
      end

      it "returns the grading period current score, if given a grading period" do
        @enrollment.scores.create!(grading_period_id: period.id, current_score: 82.0)
        expect(@enrollment.effective_current_score(grading_period_id: period.id)).to eq 82.0
      end

      it "returns the override score" do
        @enrollment.scores.create!(current_score: 79.0, override_score: 97.0)
        expect(@enrollment.effective_current_score).to eq 97.0
      end

      it "does not return the override score if the feature is not allowed" do
        @enrollment.scores.create!(current_score: 79.0, override_score: 97.0)
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.effective_current_score).to eq 79.0
      end

      it "does not return the override score if the feature is not enabled" do
        @enrollment.scores.create!(current_score: 79.0, override_score: 97.0)
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.effective_current_score).to eq 79.0
      end
    end

    describe "effective_final_grade" do
      let_once(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @enrollment.scores.create!(course_score: true, final_score: 88.0)
        @enrollment.scores.create!(grading_period_id: period.id, final_score: 82.0)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      before do
        allow(@course).to receive(:grading_standard_enabled?).and_return true
      end

      it "returns the course final grade" do
        expect(@enrollment.effective_final_grade).to eq "B+"
      end

      it "returns the grading period final grade, if given a grading period" do
        expect(@enrollment.effective_final_grade(grading_period_id: period.id)).to eq "B-"
      end

      it "returns the override grade" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        expect(@enrollment.effective_final_grade).to eq "A"
      end

      it "does not return the override grade if the feature is not allowed" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.effective_final_grade).to eq "B+"
      end

      it "does not return the override grade if the feature is not enabled" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.effective_final_grade).to eq "B+"
      end

      it "returns nil if a grading standard is not enabled" do
        allow(@course).to receive(:grading_standard_enabled?).and_return false
        expect(@enrollment.effective_final_grade).to be_nil
      end
    end

    describe "effective_final_score" do
      let_once(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @enrollment.scores.create!(course_score: true, final_score: 88.0)
        @enrollment.scores.create!(grading_period_id: period.id, final_score: 82.0)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      it "returns the course final score" do
        expect(@enrollment.effective_final_score).to be 88.0
      end

      it "returns the grading period final score, if given a grading period" do
        expect(@enrollment.effective_final_score(grading_period_id: period.id)).to be 82.0
      end

      it "returns the override score" do
        @enrollment.scores.find_by!(course_score: true).update!(override_score: 97.0)
        expect(@enrollment.effective_current_score).to eq 97.0
      end

      it "does not return the override score if the feature is not allowed" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.disable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.effective_final_score).to be 88.0
      end

      it "does not return the override score if the feature is not enabled" do
        @enrollment.scores.find_by(course_score: true).update!(override_score: 97.0)
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.effective_final_score).to be 88.0
      end
    end

    describe "override_grade" do
      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @course = @enrollment.course
        @score = @enrollment.scores.create!(course_score: true, final_score: 19)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      before do
        @course.enable_feature!(:final_grades_override)
        @course.update!(grading_standard_enabled: true)
        @score.update!(override_score: 99.0)
      end

      it "returns nil if final_grades_override is not allowed" do
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.override_grade).to be_nil
      end

      it "returns nil if final_grades_override is not enabled" do
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.override_grade).to be_nil
      end

      it "returns nil if there is no override grade" do
        @score.update!(override_score: nil)
        expect(@enrollment.override_grade).to be_nil
      end

      it "returns nil if a grading standard is not enabled" do
        @course.update!(grading_standard_enabled: false)
        expect(@enrollment.override_grade).to be_nil
      end

      it "returns the override grade if an override score exists" do
        expect(@enrollment.override_grade).to eq "A"
      end

      it "can return a grading period's override grade" do
        period_group = @course.grading_period_groups.create!
        period = period_group.grading_periods.create!(
          close_date: 1.day.from_now,
          end_date: 1.day.from_now,
          start_date: 1.day.ago,
          title: "period"
        )
        @enrollment.scores.find_by(grading_period: period).update!(override_score: 71.0)
        expect(@enrollment.override_grade(grading_period_id: period.id)).to eq "C-"
      end

      it "optionally accepts a score to use" do
        period_group = @course.grading_period_groups.create!
        period = period_group.grading_periods.create!(
          close_date: 1.day.from_now,
          end_date: 1.day.from_now,
          start_date: 1.day.ago,
          title: "period"
        )
        score = @enrollment.scores.find_by(grading_period: period)
        score.update!(override_score: 71.0)
        expect(@enrollment.override_grade(score:)).to eq "C-"
      end
    end

    describe "override_score" do
      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
        @course = @enrollment.course
        @score = @enrollment.scores.create!(course_score: true, final_score: 19)
        @course.enable_feature!(:final_grades_override)
        @course.update!(allow_final_grade_override: true)
      end

      before do
        @score.update!(override_score: 99.0)
      end

      it "returns nil if final_grades_override is not allowed" do
        @course.update!(allow_final_grade_override: false)
        expect(@enrollment.override_score).to be_nil
      end

      it "returns nil if final_grades_override is not enabled" do
        @course.disable_feature!(:final_grades_override)
        expect(@enrollment.override_score).to be_nil
      end

      it "returns nil if there is no override score" do
        @score.update!(override_score: nil)
        expect(@enrollment.override_score).to be_nil
      end

      it "returns the override score if one exists" do
        expect(@enrollment.override_score).to be 99.0
      end

      it "can return a grading period's override score" do
        period_group = @course.grading_period_groups.create!
        period = period_group.grading_periods.create!(
          close_date: 1.day.from_now,
          end_date: 1.day.from_now,
          start_date: 1.day.ago,
          title: "period"
        )
        @enrollment.scores.find_by(grading_period: period).update!(override_score: 71.0)
        expect(@enrollment.override_score(grading_period_id: period.id)).to be 71.0
      end

      it "optionally accepts a score to use" do
        period_group = @course.grading_period_groups.create!
        period = period_group.grading_periods.create!(
          close_date: 1.day.from_now,
          end_date: 1.day.from_now,
          start_date: 1.day.ago,
          title: "period"
        )
        score = @enrollment.scores.find_by(grading_period: period)
        score.update!(override_score: 71.0)
        expect(@enrollment.override_score(score:)).to eq 71.0
      end
    end

    describe "current scores and grades" do
      before(:once) do
        @enrollment = StudentEnrollment.create!(valid_enrollment_attributes)
      end

      let(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      let(:a_group) { @course.assignment_groups.create!(name: "a group") }

      describe "#computed_current_score" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(current_score: 80.3)
          expect(@enrollment.computed_current_score).to eq 80.3
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(current_score: nil)
          expect(@enrollment.computed_current_score).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(current_score: 80.3, grading_period: period)
          expect(@enrollment.computed_current_score).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(current_score: 80.3)
          score.destroy
          expect(@enrollment.computed_current_score).to be_nil
        end

        it "computes current score for a given grading period id" do
          @enrollment.scores.create!(current_score: 80.3)
          @enrollment.scores.create!(current_score: 70.6, grading_period: period)
          current_score = @enrollment.computed_current_score(grading_period_id: period.id)
          expect(current_score).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          current_score = @enrollment.computed_current_score(grading_period_id: period.id)
          expect(current_score).to be_nil
        end
      end

      describe "#unposted_current_score" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(unposted_current_score: 80.3)
          expect(@enrollment.unposted_current_score).to eq 80.3
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(unposted_current_score: nil)
          expect(@enrollment.unposted_current_score).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(unposted_current_score: 80.3, grading_period: period)
          expect(@enrollment.unposted_current_score).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(unposted_current_score: 80.3)
          score.destroy
          expect(@enrollment.unposted_current_score).to be_nil
        end

        it "computes current score for a given grading period id" do
          @enrollment.scores.create!(current_score: 80.3)
          @enrollment.scores.create!(current_score: 70.6, grading_period: period)
          current_score = @enrollment.computed_current_score(grading_period_id: period.id)
          expect(current_score).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          current_score = @enrollment.computed_current_score(grading_period_id: period.id)
          expect(current_score).to be_nil
        end
      end

      describe "#computed_current_grade" do
        before do
          @course.grading_standard_enabled = true
          @course.save!
        end

        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(current_score: 80.3)
          expect(@enrollment.computed_current_grade).to eq "B-"
        end

        it "ignores grading period grades when passed no arguments" do
          @enrollment.scores.create!(current_score: 80.3, grading_period: period)
          expect(@enrollment.computed_current_grade).to be_nil
        end

        it "ignores grades from soft-deleted scores" do
          score = @enrollment.scores.create!(current_score: 80.3)
          score.destroy
          expect(@enrollment.computed_current_grade).to be_nil
        end

        it "computes current grade for a given grading period id" do
          @enrollment.scores.create!(current_score: 70.6, grading_period: period)
          current_grade = @enrollment.computed_current_grade(grading_period_id: period.id)
          expect(current_grade).to eq "C-"
        end

        it "returns nil if a grading period grade is requested and does not exist" do
          current_grade = @enrollment.computed_current_grade(grading_period_id: period.id)
          expect(current_grade).to be_nil
        end
      end

      describe "#unposted_current_grade" do
        before do
          @course.grading_standard_enabled = true
          @course.save!
        end

        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(unposted_current_score: 80.3)
          expect(@enrollment.unposted_current_grade).to eq "B-"
        end

        it "ignores grading period grades when passed no arguments" do
          @enrollment.scores.create!(unposted_current_score: 80.3, grading_period: period)
          expect(@enrollment.unposted_current_grade).to be_nil
        end

        it "ignores grades from soft-deleted scores" do
          score = @enrollment.scores.create!(unposted_current_score: 80.3)
          score.destroy
          expect(@enrollment.unposted_current_grade).to be_nil
        end

        it "computes current grade for a given grading period id" do
          @enrollment.scores.create!(unposted_current_score: 70.6, grading_period: period)
          unposted_current_grade = @enrollment.unposted_current_grade(grading_period_id: period.id)
          expect(unposted_current_grade).to eq "C-"
        end

        it "returns nil if a grading period grade is requested and does not exist" do
          unposted_current_grade = @enrollment.unposted_current_grade(grading_period_id: period.id)
          expect(unposted_current_grade).to be_nil
        end
      end

      describe "#computed_current_points" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(current_points: 80.3)
          expect(@enrollment.computed_current_points).to eq 80.3
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(current_points: nil)
          expect(@enrollment.computed_current_points).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(current_points: 80.3, grading_period: period)
          expect(@enrollment.computed_current_points).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(current_points: 80.3)
          score.destroy
          expect(@enrollment.computed_current_points).to be_nil
        end

        it "computes current points for a given grading period id" do
          @enrollment.scores.create!(current_points: 80.3)
          @enrollment.scores.create!(current_points: 70.6, grading_period: period)
          current_points = @enrollment.computed_current_points(grading_period_id: period.id)
          expect(current_points).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          current_points = @enrollment.computed_current_points(grading_period_id: period.id)
          expect(current_points).to be_nil
        end
      end

      describe "#computed_final_points" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(final_points: 80.3)
          expect(@enrollment.computed_final_points).to eq 80.3
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(final_points: nil)
          expect(@enrollment.computed_final_points).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(final_points: 80.3, grading_period: period)
          expect(@enrollment.computed_final_points).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(final_points: 80.3)
          score.destroy
          expect(@enrollment.computed_final_points).to be_nil
        end

        it "computes current points for a given grading period id" do
          @enrollment.scores.create!(final_points: 80.3)
          @enrollment.scores.create!(final_points: 70.6, grading_period: period)
          final_points = @enrollment.computed_final_points(grading_period_id: period.id)
          expect(final_points).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          final_points = @enrollment.computed_final_points(grading_period_id: period.id)
          expect(final_points).to be_nil
        end
      end

      describe "#unposted_current_points" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(unposted_current_points: 80.3)
          expect(@enrollment.unposted_current_points).to eq 80.3
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(unposted_current_points: nil)
          expect(@enrollment.unposted_current_points).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(unposted_current_points: 80.3, grading_period: period)
          expect(@enrollment.unposted_current_points).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(unposted_current_points: 80.3)
          score.destroy
          expect(@enrollment.unposted_current_points).to be_nil
        end

        it "computes current points for a given grading period id" do
          @enrollment.scores.create!(unposted_current_points: 80.3)
          @enrollment.scores.create!(unposted_current_points: 70.6, grading_period: period)
          current_points = @enrollment.unposted_current_points(grading_period_id: period.id)
          expect(current_points).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          current_score = @enrollment.unposted_current_points(grading_period_id: period.id)
          expect(current_score).to be_nil
        end
      end

      describe "#find_score" do
        before do
          @course.update!(grading_standard_enabled: true)
          allow(GradeCalculator).to receive(:recompute_final_score)
          @enrollment.scores.create!(current_score: 85.3)
          @enrollment.scores.create!(grading_period: period, current_score: 99.1)
          @enrollment.scores.create!(assignment_group: a_group, current_score: 66.3)
          allow(GradeCalculator).to receive(:recompute_final_score).and_call_original
        end

        it "returns the course score" do
          expect(@enrollment.find_score.current_score).to be 85.3
        end

        it "returns grading period scores" do
          expect(@enrollment.find_score(grading_period_id: period.id).current_score).to be 99.1
        end

        it "returns assignment group scores" do
          expect(@enrollment.find_score(assignment_group_id: a_group.id).current_score).to be 66.3
        end

        it "returns no score when given an invalid grading period id" do
          expect(@enrollment.find_score(grading_period_id: 99_999)).to be_nil
        end

        it "returns no score when given an invalid assignment group id" do
          expect(@enrollment.find_score(assignment_group_id: 8_888_888)).to be_nil
        end

        it "returns no score when given unrecognized id keys" do
          expect(@enrollment.find_score(flavor: "Anchovied Caramel")).to be_nil
        end
      end

      describe "#graded_at" do
        it "uses the updated_at from the associated score object, if one exists" do
          score = @enrollment.scores.create!(current_score: 80.3)
          score.update_attribute(:updated_at, 5.days.from_now)
          expect(@enrollment.graded_at).to eq score.updated_at
        end

        it "ignores grading period scores" do
          @enrollment.scores.create!(current_score: 80.3, grading_period: period)
          expect(@enrollment.graded_at).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(current_score: 80.3)
          score.destroy
          expect(@enrollment.graded_at).to be_nil
        end
      end

      describe "copying overridden scores on restoration" do
        before(:once) do
          teacher = User.create!
          @course.enroll_teacher(teacher, active_all: true)
          assignment = @course.assignments.create!(points_possible: 100)
          assignment.grade_student(@enrollment.user, grade: 95, grader: teacher)
          @enrollment.find_score.update!(override_score: 98)
        end

        it "restores override score from an existing enrollment" do
          new_student_enrollment.find_score.update!(override_score: 88)
          new_student_enrollment.destroy
          new_student_enrollment.update!(workflow_state: :completed)
          expect(new_student_enrollment.find_score.override_score).to eq 98
        end

        it "restores override score from soft-deleted scores when the existing enrollment does not have any scores" do
          @enrollment.scores.update_all(workflow_state: :deleted)
          new_student_enrollment.find_score.update!(override_score: 88)
          new_student_enrollment.destroy
          new_student_enrollment.update!(workflow_state: :completed)
          expect(new_student_enrollment.find_score.override_score).to eq 88
        end
      end

      describe "copying current scores" do
        before(:once) do
          teacher = User.create!
          @course.enroll_teacher(teacher, active_all: true)
          assignment = @course.assignments.create!(points_possible: 100)
          assignment.grade_student(@enrollment.user, grade: 95, grader: teacher)
        end

        context "on creation" do
          it "copies scores over from existing student enrollments to new student enrollments" do
            expect(new_student_enrollment.computed_current_score).to eq(@enrollment.computed_current_score)
          end

          it "copies scores over from existing fake student enrollments to new fake student enrollments" do
            @enrollment.update!(type: "StudentViewEnrollment")
            expect(new_fake_student_enrollment.computed_current_score).to eq(@enrollment.computed_current_score)
          end
        end

        # if a user is being restored to active, the SubmissionLifecycleManager
        # run will kick off a grade calculation, which will update
        # the score objects. To test we're not copying scores, we'll
        # restore to completed for these tests.
        context "on restoration" do
          it "copies scores over from existing student enrollments to restored student enrollments" do
            new_student_enrollment.destroy
            new_student_enrollment.update!(workflow_state: :completed)
            expect(new_student_enrollment.computed_current_score).to eq(@enrollment.computed_current_score)
          end

          it "copies scores over from existing fake student enrollments to restored fake student enrollments" do
            @enrollment.update!(type: "StudentViewEnrollment")
            new_fake_student_enrollment.destroy
            new_fake_student_enrollment.update!(workflow_state: :completed)
            expect(new_fake_student_enrollment.computed_current_score).to eq(@enrollment.computed_current_score)
          end
        end
      end
    end

    describe "final scores and grades" do
      before(:once) do
        @enrollment.save!
      end

      let(:period) do
        group = @course.root_account.grading_period_groups.create!
        group.grading_periods.create!(
          title: "period",
          start_date: "Jan 1, 2015",
          end_date: "Jan 5, 2015"
        )
      end

      describe "#find_score" do
        it "returns the course score when no arg is passed" do
          score = @enrollment.scores.create!(final_score: 80.3)
          @enrollment.scores.create!(final_score: 80.3, grading_period_id: period.id)
          expect(@enrollment.find_score).to eq score
        end

        it "returns the grading period score when grading_period_id is passed" do
          @enrollment.scores.create!(final_score: 80.3)
          score = @enrollment.scores.create!(final_score: 80.3, grading_period_id: period.id)
          expect(@enrollment.find_score(grading_period_id: period.id)).to eq score
        end
      end

      describe "#computed_final_score" do
        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(final_score: 80.3)
          expect(@enrollment.computed_final_score).to eq 80.3
        end

        it "forgets scores on destroyed enrollments" do
          @enrollment.scores.create!(final_score: 55.2)
          @enrollment.destroy
          expect(@enrollment.computed_final_score).to be_nil
        end

        it "uses the value from the associated score object, even if it is nil" do
          @enrollment.scores.create!(final_score: nil)
          expect(@enrollment.computed_final_score).to be_nil
        end

        it "ignores grading period scores when passed no arguments" do
          @enrollment.scores.create!(final_score: 80.3, grading_period: period)
          expect(@enrollment.computed_final_score).to be_nil
        end

        it "ignores soft-deleted scores" do
          score = @enrollment.scores.create!(final_score: 80.3)
          score.destroy
          expect(@enrollment.computed_final_score).to be_nil
        end

        it "computes final score for a given grading period id" do
          @enrollment.scores.create!(final_score: 70.6, grading_period: period)
          final_score = @enrollment.computed_final_score(grading_period_id: period.id)
          expect(final_score).to eq 70.6
        end

        it "returns nil if a grading period score is requested and does not exist" do
          final_score = @enrollment.computed_final_score(grading_period_id: period.id)
          expect(final_score).to be_nil
        end
      end

      describe "#computed_final_grade" do
        before do
          @course.grading_standard_enabled = true
          @course.save!
        end

        it "uses the value from the associated score object, if one exists" do
          @enrollment.scores.create!(final_score: 80.3)
          expect(@enrollment.computed_final_grade).to eq "B-"
        end

        it "ignores grading period grades when passed no arguments" do
          @enrollment.scores.create!(final_score: 80.3, grading_period: period)
          expect(@enrollment.computed_final_grade).to be_nil
        end

        it "ignores grades from soft-deleted scores" do
          score = @enrollment.scores.create!(final_score: 80.3)
          score.destroy
          expect(@enrollment.computed_final_grade).to be_nil
        end

        it "computes final grade for a given grading period id" do
          @enrollment.scores.create!(final_score: 80.3)
          @enrollment.scores.create!(final_score: 70.6, grading_period: period)
          final_grade = @enrollment.computed_final_grade(grading_period_id: period.id)
          expect(final_grade).to eq "C-"
        end

        it "returns nil if a grading period grade is requested and does not exist" do
          final_grade = @enrollment.computed_final_grade(grading_period_id: period.id)
          expect(final_grade).to be_nil
        end
      end

      context "copying final scores on creation" do
        before(:once) do
          teacher = User.create!
          @course.enroll_teacher(teacher, active_all: true)
          assignment = @course.assignments.create!(points_possible: 100)
          assignment.grade_student(@enrollment.user, grade: 95, grader: teacher)
          # create this so the enrollment's current_score differs from its final_score
          @course.assignments.create!(points_possible: 100)
        end

        it "copies scores over from the user's existing student enrollments to new student enrollments" do
          expect(new_student_enrollment.computed_final_score).to eq(@enrollment.computed_final_score)
        end

        it "copies scores over from the user's existing fake student enrollments to new fake student enrollments" do
          @enrollment.update!(type: "StudentViewEnrollment")
          expect(new_fake_student_enrollment.computed_final_score).to eq(@enrollment.computed_final_score)
        end
      end
    end

    describe "restoring enrollments directly from soft-deleted to completed state" do
      before do
        # Create two enrollments for this course
        @enrollment.save!
        user2 = User.create!
        @enrollment2 = StudentEnrollment.create!(user: user2, course: @course)

        # and ensure the course has two assignment groups with one assignment in each group
        @course.assignments.create!(title: "Assignment #1", points_possible: 10)
        group2 = @course.assignment_groups.create!(name: "Assignment Group #2")
        @course.assignments.create!(title: "Assignment #2", points_possible: 10, assignment_group: group2)

        # Soft-delete both enrollments so their corresponding scores are also soft-deleted
        @enrollment.destroy
        @enrollment2.destroy
      end

      it "restores deleted scores belonging to the specific enrollment" do
        expect do
          # Restore an enrollment directly from "deleted" to "completed" state
          @enrollment.workflow_state = "completed"
          @enrollment.save!
        end.to change { @enrollment.reload.scores.size }.from(0).to(3)
      end

      it "does not restore deleted scores belonging to the other enrollment" do
        expect do
          # Restore an enrollment directly from "deleted" to "completed" state
          @enrollment.workflow_state = "completed"
          @enrollment.save!
        end.not_to change { @enrollment2.reload.scores.size }
      end
    end
  end

  it "does not allow an associated_user_id on a non-observer enrollment" do
    observed = User.create!

    @enrollment.type = "ObserverEnrollment"
    @enrollment.associated_user_id = observed.id
    expect(@enrollment).to be_valid

    @enrollment.type = "StudentEnrollment"
    expect(@enrollment).not_to be_valid

    @enrollment.associated_user_id = nil
    expect(@enrollment).to be_valid
  end

  it "does not allow an associated_user_id = user_id" do
    observed = User.create!
    @enrollment.type = "ObserverEnrollment"
    @enrollment.user_id = observed.id
    @enrollment.associated_user_id = observed.id
    expect(@enrollment).to_not be_valid
  end

  it "does not allow an enrollment to be created in a template course" do
    course = course_factory
    course.template = true
    course.save!
    enrollment = course.teacher_enrollments.new
    enrollment.user = user_with_pseudonym
    expect(enrollment).not_to be_valid
    expect(enrollment.errors.to_a).to eq(["Course is a template course"])
  end

  context "permissions" do
    before(:once) do
      course_with_student(active_all: true)
    end

    it "allows post_to_forum permission on a course if date is current" do
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 4.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.save!

      expect(@enrollment.reload.state_based_on_date).to eq :active
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(true)
    end

    it "does not allow post_to_forum permission on a course if date in future" do
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.save!

      expect(@enrollment.reload.state_based_on_date).to eq :accepted
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(false)
    end

    it "does not allow read permission on a course if date inactive" do
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.save!

      @course.restrict_student_future_view = true
      @course.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to be(false)

      # post to forum comes from role_override; inactive enrollments should not
      # get any permissions form role_override
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(false)
    end

    it "does not allow read permission on a course if explicitly inactive" do
      @enrollment.workflow_state = "inactive"
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to be(false)
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(false)
    end

    it "allows read, but not post_to_forum on a course if date completed" do
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.workflow_state = "active"
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to be(true)
      # post to forum comes from role_override; completed enrollments should not
      # get any permissions form role_override
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(false)
    end

    it "allows read, but not post_to_forum on a course if explicitly completed" do
      @enrollment.workflow_state = "completed"
      @enrollment.save!
      expect(@course.grants_right?(@enrollment.user, :read)).to be(true)
      expect(@course.grants_right?(@enrollment.user, :post_to_forum)).to be(false)
    end

    it "grants read rights to account members with the ability to read_roster" do
      role = Role.get_built_in_role("AccountMembership", root_account_id: Account.default.id)
      user = account_admin_user(role:)
      RoleOverride.create!(context: Account.default,
                           permission: :read_roster,
                           role:,
                           enabled: true)
      @enrollment.save

      expect(@enrollment.user.grants_right?(user, :read)).to be false
      expect(@enrollment.grants_right?(user, :read)).to be true
    end

    it "is able to read grades if the course grants management rights to the enrollment" do
      @new_user = user_model
      @enrollment.save
      expect(@enrollment.grants_right?(@new_user, :read_grades)).to be_falsey
      @course.enroll_teacher(@new_user)
      @enrollment.reload
      AdheresToPolicy::Cache.clear
      expect(@enrollment.grants_right?(@user, :read_grades)).to be_truthy
    end

    it "allows the user itself to read its own grades" do
      expect(@enrollment.grants_right?(@user, :read_grades)).to be_truthy
    end
  end

  context "typed_enrollment" do
    it "allows StudentEnrollment" do
      expect(Enrollment.typed_enrollment("StudentEnrollment")).to eql(StudentEnrollment)
    end

    it "allows TeacherEnrollment" do
      expect(Enrollment.typed_enrollment("TeacherEnrollment")).to eql(TeacherEnrollment)
    end

    it "allows TaEnrollment" do
      expect(Enrollment.typed_enrollment("TaEnrollment")).to eql(TaEnrollment)
    end

    it "allows ObserverEnrollment" do
      expect(Enrollment.typed_enrollment("ObserverEnrollment")).to eql(ObserverEnrollment)
    end

    it "allows DesignerEnrollment" do
      expect(Enrollment.typed_enrollment("DesignerEnrollment")).to eql(DesignerEnrollment)
    end

    it "allows not NothingEnrollment" do
      expect(Enrollment.typed_enrollment("NothingEnrollment")).to be_nil
    end
  end

  context "drop scores" do
    before(:once) do
      course_with_teacher
      course_with_student(course: @course)
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 50, rules: "drop_lowest:1")
      @assignment = @group.assignments.build(title: "some assignments", points_possible: 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(title: "some assignment 2", points_possible: 40)
      @assignment2.context = @course
      @assignment2.save!
    end

    it "drops high scores for groups when specified" do
      @enrollment = @user.enrollments.first
      @group.update_attribute(:rules, "drop_highest:1")
      expect(@enrollment.reload.computed_current_score).to be_nil
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      expect(@submission[0].score).to be(9.0)
      expect(@enrollment.reload.computed_current_score).to be(90.0)
      @submission2 = @assignment2.grade_student(@user, grade: "20", grader: @teacher)
      expect(@submission2[0].score).to be(20.0)
      expect(@enrollment.reload.computed_current_score).to be(50.0)
      @group.update_attribute(:rules, nil)
      expect(@enrollment.reload.computed_current_score).to be(58.0)
    end

    it "drops low scores for groups when specified" do
      @enrollment = @user.enrollments.first
      expect(@enrollment.reload.computed_current_score).to be_nil
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      @submission2 = @assignment2.grade_student(@user, grade: "20", grader: @teacher)
      expect(@submission2[0].score).to be(20.0)
      expect(@enrollment.reload.computed_current_score).to be(90.0)
      @group.update_attribute(:rules, "")
      expect(@enrollment.reload.computed_current_score).to be(58.0)
    end

    it "does not drop the last score for a group, even if the settings say it should be dropped" do
      @enrollment = @user.enrollments.first
      @group.update_attribute(:rules, "drop_lowest:2")
      expect(@enrollment.reload.computed_current_score).to be_nil
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      expect(@submission[0].score).to be(9.0)
      expect(@enrollment.reload.computed_current_score).to be(90.0)
      @submission2 = @assignment2.grade_student(@user, grade: "20", grader: @teacher)
      expect(@submission2[0].score).to be(20.0)
      expect(@enrollment.reload.computed_current_score).to be(90.0)
    end
  end

  context "notifications" do
    it "sends out invitations if the course is already published" do
      Notification.create!(name: "Enrollment Registration")
      course_with_teacher(active_all: true)
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).to include("Enrollment Registration")
    end

    it "does not send out invitations immediately if the course restricts future viewing" do
      Notification.create!(name: "Enrollment Registration")
      course_with_teacher(active_all: true)
      @course.restrict_student_future_view = true
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 1.day.from_now
      @course.conclude_at = 3.days.from_now
      @course.save!

      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e).to be_inactive
      expect(e.messages_sent).to_not include("Enrollment Registration")

      Timecop.freeze(2.days.from_now) do
        expect(e).to be_invited
        expect_any_instantiation_of(e).to receive(:re_send_confirmation!).once
        run_jobs
      end
    end

    it "does not send out invitations to an observer if the student doesn't receive an invitation (e.g. sis import)" do
      Notification.create!(name: "Enrollment Registration", category: "Registration")

      course_with_teacher(active_all: true)
      student = user_with_pseudonym
      observer = user_with_pseudonym
      add_linked_observer(student, observer)

      @course.enroll_student(student, no_notify: true)
      expect(student.messages).to be_empty
      expect(observer.messages).to be_empty

      course_with_teacher(active_all: true)
      @course.enroll_student(student)
      student.reload
      observer.reload
      expect(student.messages).to_not be_empty
      expect(observer.messages).to be_empty
    end

    it "does not send out invitations to an observer if the course is not published" do
      Notification.create!(name: "Enrollment Registration", category: "Registration")

      course_with_teacher
      student = user_with_pseudonym
      observer = user_with_pseudonym
      add_linked_observer(student, observer)

      @course.enroll_student(student)
      expect(observer.messages).to be_empty
    end

    it "does not send out invitations if the course is not yet published" do
      Notification.create!(name: "Enrollment Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).not_to include("Enrollment Registration")
    end

    it "sends out invitations for previously-created enrollments when the course is published" do
      n = Notification.create(name: "Enrollment Registration", category: "Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      expect(e.messages_sent).not_to include("Enrollment Registration")
      expect(@user.pseudonym).not_to be_nil
      @course.offer
      e.reload
      expect(e).to be_invited
      expect(e.user).not_to be_nil
      expect(e.user.pseudonym).not_to be_nil
      expect(Message.last).not_to be_nil
      expect(Message.last.notification).to eql(n)
      expect(Message.last.to).to eql(@user.email)
    end

    it "sends out notifications for enrollment acceptance correctly" do
      teacher = user_with_pseudonym(active_all: true)
      n = Notification.create!(name: "Enrollment Accepted")
      NotificationPolicy.create!(notification: n, communication_channel: @user.communication_channel, frequency: "immediately")
      course_with_teacher(active_all: true, user: teacher)
      student = user_factory
      e = @course.enroll_student(student)
      e.accept!
      expect(teacher.messages).to be_exists
    end

    it "does not send out notifications for enrollment acceptance to admins who are section restricted and in other sections" do
      # even though section restrictions are still basically meaningless at this point
      teacher = user_with_pseudonym(active_all: true)
      n = Notification.create!(name: "Enrollment Accepted")
      NotificationPolicy.create!(notification: n, communication_channel: @user.communication_channel, frequency: "immediately")
      course_with_teacher(active_all: true, user: teacher)
      teacher.enrollments.first.update_attribute(:limit_privileges_to_course_section, true)
      other_section = @course.course_sections.create!
      e1 = @course.enroll_student(user_factory, section: other_section)
      e1.accept!
      expect(teacher.messages).to_not be_exists
      e2 = @course.enroll_student(user_factory, section: @course.default_section)
      e2.accept!
      expect(teacher.messages).to be_exists
    end
  end

  it "does not touch observer when set to skip" do
    course_model
    student = user_with_pseudonym
    observer = user_with_pseudonym
    old_time = observer.updated_at
    add_linked_observer(student, observer)
    @course.enrollments.create(user: student, skip_touch_user: true, type: "StudentEnrollment")
    expect(observer.reload.updated_at).to eq old_time
  end

  context "atom" do
    it "uses the course and user name to derive a title" do
      expect(@enrollment.to_atom[:title]).to eql("#{@enrollment.user.name} in #{@enrollment.course.name}")
    end

    it "links to the enrollment" do
      link_path = @enrollment.to_atom[:link]
      expect(link_path).to eql("/courses/#{@enrollment.course.id}/enrollments/#{@enrollment.id}")
    end
  end

  context "recompute_final_score_in_singleton" do
    before(:once) { course_with_student }

    it "raises an exception if called with more than one user" do
      expect { Enrollment.recompute_final_score_in_singleton([@user.id, 5], @course.id) }
        .to raise_error(ArgumentError)
    end

    it "sends later for a single student" do
      expect(Enrollment).to receive(:delay_if_production)
        .with(hash_including(singleton: "Enrollment.recompute_final_score:#{@user.id}:#{@course.id}:"))
        .and_call_original
      # The delegation works correctly in both cases, just the introspection of the method
      # kwargs by rspec is different between ruby versions
      if RUBY_VERSION >= "2.7.0"
        expect(Enrollment).to receive(:recompute_final_score).with(@user.id, @course.id)
      else
        expect(Enrollment).to receive(:recompute_final_score).with(@user.id, @course.id, {})
      end

      Enrollment.recompute_final_score_in_singleton(@user.id, @course.id)
    end
  end

  context "recompute_final_scores" do
    it "only recomputes once per student, per course" do
      course_with_student(active_all: true)
      @c1 = @course
      @s2 = @course.course_sections.create!(name: "s2")
      @course.enroll_student(@user, section: @s2, allow_multiple_enrollments: true)
      expect(@user.student_enrollments.reload.count).to eq 2
      course_with_student(user: @user)
      @c2 = @course
      expect(Enrollment).to receive(:recompute_final_score).with(@user.id, @c1.id)
      expect(Enrollment).to receive(:recompute_final_score).with(@user.id, @c2.id)
      Enrollment.recompute_final_scores(@user.id)
    end
  end

  context "date restrictions" do
    context "accept" do
      def enrollment_availability_test
        @enrollment.start_at = 2.days.ago
        @enrollment.end_at = 2.days.from_now
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to be(:active)
        expect(@enrollment.state_based_on_date).to be(:active)

        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.reload.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:completed)
        expect(@enrollment.accept).to be_falsey

        @enrollment.start_at = 2.days.from_now
        @enrollment.end_at = 4.days.from_now
        @enrollment.save!
        expect(@enrollment.reload.state).to be(:invited)
        if @enrollment.admin?
          expect(@enrollment.state_based_on_date).to eq(:inactive)
        else
          expect(@enrollment.state_based_on_date).to be(:invited)
          expect(@enrollment.accept).to be_truthy
        end
      end

      def course_section_availability_test(should_be_invited = false)
        @section = @course.course_sections.first
        expect(@section).not_to be_nil
        @enrollment.course_section = @section
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        @section.start_at = 2.days.ago
        @section.end_at = 2.days.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        expect(@enrollment.state).to be(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to be(:active)
        expect(@enrollment.state_based_on_date).to be(:active)

        @section.start_at = 4.days.ago
        @section.end_at = 2.days.ago
        @section.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.reload.state).to be(:invited)
        if should_be_invited
          expect(@enrollment.state_based_on_date).to be(:invited)
          expect(@enrollment.accept).to be_truthy
        else
          expect(@enrollment.state_based_on_date).to be(:completed)
          expect(@enrollment.accept).to be_falsey
        end

        @section.start_at = 2.days.from_now
        @section.end_at = 4.days.from_now
        @section.save!
        @enrollment.save!
        @enrollment.reload
        if should_be_invited
          expect(@enrollment.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
        else
          expect(@enrollment.state).to be(:invited)
          expect(@enrollment.state_based_on_date).to be(:invited)
          expect(@enrollment.accept).to be_truthy
        end
      end

      def course_availability_test(state_based_state)
        @course.start_at = 2.days.ago
        @course.conclude_at = 2.days.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to be(:active)
        expect(@enrollment.state_based_on_date).to be(:active)

        @course.start_at = 4.days.ago
        @course.conclude_at = 2.days.ago
        @course.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        @enrollment.accept if @enrollment.invited?
        expect(@enrollment.state_based_on_date).to eql(state_based_state)

        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:invited)
        expect(@enrollment.accept).to be_truthy

        @course.complete!
        expect(@enrollment.reload.state).to be(:completed)
        expect(@enrollment.state_based_on_date).to be(:completed)

        @enrollment.workflow_state = "active"
        @enrollment.save!
        expect(@enrollment.state_based_on_date).to be(:completed)
      end

      def enrollment_term_availability_test
        @term = @course.enrollment_term
        expect(@term).not_to be_nil
        @term.start_at = 2.days.ago
        @term.end_at = 2.days.from_now
        @term.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to be(:active)
        expect(@enrollment.state_based_on_date).to be(:active)

        @term.start_at = 4.days.ago
        @term.end_at = 2.days.ago
        @term.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:completed)
        expect(@enrollment.accept).to be_falsey

        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        @enrollment.reload
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:invited)
        expect(@enrollment.accept).to be_truthy
        expect(@enrollment.reload.state_based_on_date).to eql(@enrollment.admin? ? :active : :accepted)
      end

      def enrollment_dates_override_test
        @term = @course.enrollment_term
        expect(@term).not_to be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(enrollment_type: @enrollment.type, enrollment_term: @term, context: @term.root_account)
        @override.start_at = 2.days.ago
        @override.end_at = 2.days.from_now
        @override.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        @enrollment.accept
        expect(@enrollment.reload.state).to be(:active)
        expect(@enrollment.state_based_on_date).to be(:active)

        @override.start_at = 4.days.ago
        @override.end_at = 2.days.ago
        @override.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        expect(@enrollment.state).to be(:invited)
        expect(@enrollment.state_based_on_date).to be(:completed)

        @override.start_at = 2.days.from_now
        @override.end_at = 4.days.from_now
        @override.save!
        @enrollment.workflow_state = "invited"
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state).to be(:invited)
        if @enrollment.admin?
          expect(@enrollment.state_based_on_date).to be(:inactive)
        else
          expect(@enrollment.state_based_on_date).to be(:invited)
          expect(@enrollment.accept).to be_truthy
        end
        @course.restrict_student_future_view = true
        @course.save!
        @enrollment.update_attribute(:workflow_state, "active")
        @override.start_at = nil
        @override.end_at = nil
        @override.save!
        @term.start_at = 2.days.from_now
        @term.end_at = 4.days.from_now
        @term.save!
        expected = @enrollment.admin? ? :active : :inactive
        expect(@enrollment.reload.state_based_on_date).to eql(expected)
      end

      context "as a student" do
        before :once do
          course_with_student(active_all: true)
        end

        it "accepts into the right state based on availability dates on enrollment" do
          enrollment_availability_test
        end

        it "accepts into the right state based on availability dates on course_section" do
          course_section_availability_test
        end

        it "accepts into the right state based on availability dates on course" do
          course_availability_test(:completed)
        end

        it "accepts into the right state based on availability dates on enrollment_term" do
          enrollment_term_availability_test
        end

        it "accepts into the right state based on availability dates on enrollment_dates_override" do
          enrollment_dates_override_test
        end

        it "has the correct state for a half-open past course" do
          @term = @course.enrollment_term
          expect(@term).not_to be_nil
          @term.start_at = nil
          @term.end_at = 2.days.ago
          @term.save!

          @enrollment.workflow_state = "invited"
          @enrollment.save!
          expect(@enrollment.reload.state).to eq :invited
          expect(@enrollment.state_based_on_date).to eq :completed
        end

        it "recomputes scores for the student" do
          expect(Enrollment).to receive(:recompute_final_score).with(@enrollment.user_id, @enrollment.course_id)
          @enrollment.workflow_state = "invited"
          @enrollment.save!
          @enrollment.accept
        end
      end

      context "as a teacher" do
        before :once do
          course_with_teacher(active_all: true)
        end

        it "accepts into the right state based on availability dates on enrollment" do
          enrollment_availability_test
        end

        it "accepts into the right state based on availability dates on course_section" do
          course_section_availability_test(true)
        end

        it "accepts into the right state based on availability dates on course" do
          course_availability_test(:active)
        end

        it "accepts into the right state based on availability dates on enrollment_term" do
          enrollment_term_availability_test
        end

        it "accepts into the right state based on availability dates on enrollment_dates_override" do
          enrollment_dates_override_test
        end

        it "does not attempt to recompute scores since the user is not a student" do
          expect(Enrollment).not_to receive(:recompute_final_score)
          @enrollment.workflow_state = "invited"
          @enrollment.save!
          @enrollment.accept
        end
      end
    end

    shared_examples_for "term and enrollment dates" do
      describe "enrollment dates" do
        it "returns active enrollment" do
          @enrollment.start_at = 2.days.ago
          @enrollment.end_at = 2.days.from_now
          @enrollment.workflow_state = "active"
          @enrollment.save!
          expect(@enrollment.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
        end

        it "returns completed enrollment" do
          @enrollment.start_at = 4.days.ago
          @enrollment.end_at = 2.days.ago
          @enrollment.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:completed)
        end

        it "returns accepted if upcoming and available" do
          @enrollment.start_at = 2.days.from_now
          @enrollment.end_at = 4.days.from_now
          @enrollment.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to eql(@enrollment.admin? ? :inactive : :accepted)
        end

        it "returns inactive for students (accepted for admins) if upcoming and not available" do
          @enrollment.start_at = 2.days.from_now
          @enrollment.end_at = 4.days.from_now
          @enrollment.save!
          @course.restrict_student_future_view = true
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:inactive)
        end
      end

      describe "term dates" do
        before do
          @term = @course.enrollment_term
        end

        it "returns active" do
          @term.start_at = 2.days.ago
          @term.end_at = 2.days.from_now
          @term.save!
          @enrollment.workflow_state = "active"
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
          expect(Enrollment.where(id: @enrollment).active_by_date.first).to eq @enrollment
        end

        it "returns completed" do
          @term.start_at = 4.days.ago
          @term.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @term.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:completed)
          expect(Enrollment.where(id: @enrollment).active_by_date.first).to be_nil
        end

        it "returns accepted for students (inactive for admins) if upcoming and available" do
          @term.start_at = 2.days.from_now
          @term.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @term.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to eql(@enrollment.admin? ? :active : :accepted)
        end

        it "returns inactive for all users if upcoming and not available" do
          @term.start_at = 2.days.from_now
          @term.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @term.save!
          @course.restrict_student_future_view = true
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to eql(@enrollment.admin? ? :active : :inactive)
          if @enrollment.student?
            expect(Enrollment.where(id: @enrollment).active_by_date.first).to be_nil
          end
        end
      end

      describe "enrollment_dates_override dates" do
        before do
          @term = @course.enrollment_term
          @override = @term.enrollment_dates_overrides.create!(
            enrollment_type: @enrollment.type,
            enrollment_term: @term,
            context: @term.root_account
          )
        end

        it "infers root account by default" do
          expect(@override.root_account).to eq @term.root_account
        end

        it "allows setting the root account" do
          new_override = @term.enrollment_dates_overrides.create!(
            enrollment_type: @enrollment.type,
            enrollment_term: @term,
            context: @term.root_account,
            root_account: @course.root_account
          )
          expect(new_override.root_account).to eq @course.root_account
        end

        it "returns active" do
          @override.start_at = 2.days.ago
          @override.end_at = 2.days.from_now
          @override.save!
          @enrollment.workflow_state = "active"
          @enrollment.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
        end

        it "returns completed" do
          @override.start_at = 4.days.ago
          @override.end_at = 2.days.ago
          @term.reset_touched_courses_flag
          @override.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:completed)
        end

        it "returns accepted if upcoming and available (and inactive for admins)" do
          @override.start_at = 2.days.from_now
          @override.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @override.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to eql(@enrollment.admin? ? :inactive : :accepted)
        end

        it "returns inactive for all users if upcoming and not available" do
          @override.start_at = 2.days.from_now
          @override.end_at = 4.days.from_now
          @term.reset_touched_courses_flag
          @override.save!
          @course.restrict_student_future_view = true
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:inactive)
        end
      end
    end

    context "dates for students" do
      before :once do
        Timecop.freeze(10.minutes.ago) do
          course_with_student(active_all: true)
        end
      end

      include_examples "term and enrollment dates"

      describe "section dates" do
        before do
          @section = @course.course_sections.first
          @section.restrict_enrollments_to_section_dates = true
        end

        it "returns active" do
          @section.start_at = 2.days.ago
          @section.end_at = 2.days.from_now
          @section.save!
          expect(@enrollment.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
        end

        it "returns completed" do
          @section.start_at = 4.days.ago
          @section.end_at = 2.days.ago
          @section.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:completed)
        end

        it "returns accepted if upcoming and available" do
          @section.start_at = 2.days.from_now
          @section.end_at = 4.days.from_now
          @section.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:accepted)
        end

        it "returns inactive if upcoming and not available" do
          @section.start_at = 2.days.from_now
          @section.end_at = 4.days.from_now
          @section.save!
          @course.restrict_student_future_view = true
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:inactive)
        end
      end

      describe "course dates" do
        before do
          @course.restrict_enrollments_to_course_dates = true
        end

        it "returns active" do
          @course.start_at = 2.days.ago
          @course.conclude_at = 2.days.from_now
          @course.save!
          @enrollment.workflow_state = "active"
          @enrollment.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:active)
        end

        it "returns completed" do
          @course.start_at = 4.days.ago
          @course.conclude_at = 2.days.ago
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:completed)
        end

        it "returns accepted if upcoming and available" do
          @course.start_at = 2.days.from_now
          @course.conclude_at = 4.days.from_now
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:accepted)
        end

        it "returns inactive if upcoming and not available" do
          @course.start_at = 2.days.from_now
          @course.conclude_at = 4.days.from_now
          @course.restrict_student_future_view = true
          @course.save!
          expect(@enrollment.reload.state).to be(:active)
          expect(@enrollment.state_based_on_date).to be(:inactive)
        end
      end
    end

    context "dates for teachers" do
      before :once do
        Timecop.freeze(10.minutes.ago) do
          course_with_teacher(active_all: true)
        end
      end

      include_examples "term and enrollment dates"
    end

    it "allows teacher access if both course and term have dates" do
      @teacher_enrollment = course_with_teacher(active_all: 1)
      @student_enrollment = student_in_course(active_all: 1)
      @term = @course.enrollment_term

      expect(@teacher_enrollment.state).to eq :active
      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates completely before Term dates, now in course dates
      @course.start_at = 2.days.ago
      @course.conclude_at = 2.days.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @term.start_at = 4.days.from_now
      @term.end_at = 6.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Term dates completely before Course dates, now in course dates
      @term.start_at = 6.days.ago
      @term.end_at = 4.days.ago
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Terms dates superset of course dates, now in both
      @term.start_at = 4.days.ago
      @term.end_at = 4.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in both
      @course.start_at = 6.days.ago
      @course.conclude_at = 6.days.from_now
      @course.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in beginning non-overlap
      @term.start_at = 2.days.from_now
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Course dates superset of term dates, now in ending non-overlap
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      expect(@teacher_enrollment.state_based_on_date).to eq :active
      expect(@student_enrollment.state_based_on_date).to eq :active

      # Term dates superset of course dates, now in beginning non-overlap
      @term.start_at = 6.days.ago
      @term.end_at = 6.days.from_now
      @term.save!
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :accepted

      @course.restrict_student_future_view = true
      @course.save!
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Term dates superset of course dates, now in ending non-overlap
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Course dates completely before term dates, now in term dates
      @course.start_at = 6.days.ago
      @course.conclude_at = 4.days.ago
      @course.save!
      @term.start_at = 2.days.ago
      @term.end_at = 2.days.from_now
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Course dates completely after term dates, now in term dates
      @course.start_at = 4.days.from_now
      @course.conclude_at = 6.days.from_now
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now between course and term dates, term first
      @term.start_at = 4.days.ago
      @term.end_at = 2.days.ago
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :completed
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now after both dates
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :completed
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed

      # Now before both dates
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!
      @term.start_at = 2.days.from_now
      @term.end_at = 4.days.from_now
      @term.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :inactive

      # Now between course and term dates, course first
      @course.start_at = 4.days.ago
      @course.conclude_at = 2.days.ago
      @course.save!

      expect(@teacher_enrollment.reload.state_based_on_date).to eq :active
      expect(@student_enrollment.reload.state_based_on_date).to eq :completed
    end

    it "affects the active?/inactive?/completed? predicates" do
      course_with_student(active_all: true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.save!
      expect(@enrollment.active?).to be_truthy
      expect(@enrollment.inactive?).to be_falsey
      expect(@enrollment.completed?).to be_falsey

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.reload
      expect(@enrollment.active?).to be_falsey
      expect(@enrollment.inactive?).to be_falsey
      expect(@enrollment.completed?).to be_truthy

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      @enrollment.reload
      expect(@enrollment.active?).to be_falsey
      expect(@enrollment.completed?).to be_falsey
      expect(@enrollment.accepted?).to be_truthy
      @course.restrict_student_future_view = true
      @course.save!
      @enrollment.reload
      expect(@enrollment.inactive?).to be_truthy
    end

    it "does not affect the explicitly_completed? predicate" do
      course_with_student(active_all: true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      expect(@enrollment.explicitly_completed?).to be_falsey

      @enrollment.workflow_state = "completed"
      expect(@enrollment.explicitly_completed?).to be_truthy
    end

    it "affects the completed_at" do
      yesterday = 1.day.ago

      course_with_student(active_all: true)
      @enrollment.start_at = 2.days.ago
      @enrollment.end_at = 2.days.from_now
      @enrollment.workflow_state = "active"
      @enrollment.completed_at = nil
      @enrollment.save!

      expect(@enrollment.completed_at).to be_nil
      @enrollment.completed_at = yesterday
      expect(@enrollment.completed_at).to eq yesterday

      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.completed_at = nil
      @enrollment.save!
      @enrollment.reload

      expect(@enrollment.completed_at).to eq @enrollment.end_at
      @enrollment.completed_at = yesterday
      expect(@enrollment.completed_at).to eq yesterday
    end
  end

  context "audit_groups_for_deleted_enrollments" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "ungroups the user when the enrollment is deleted" do
      # set up course with two users in one section
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, "StudentEnrollment")
      section1.enroll_user(user2, "StudentEnrollment")

      # set up a group without a group category and put both users in it
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)

      # remove user2 from the section (effectively unenrolled from the course)
      user2.enrollments.first.destroy
      group.reload

      # he should be removed from the group
      expect(group.users.size).to eq 1
      expect(group.users).not_to include(user2)
      expect(group).to have_common_section
    end

    it "ungroups the user when the enrollment is rejected" do
      user1 = user_model
      # set up a group without a group category and put both users in it
      group = @course.groups.create
      gm = group.add_user(user1)
      section1 = @course.course_sections.create
      enrollment = section1.enroll_user(user1, "StudentEnrollment")
      enrollment.reject!
      expect(gm.reload).to be_deleted
    end

    it "ungroups the user when a changed enrollment causes conflict" do
      # set up course with two users in one section
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, "StudentEnrollment")
      section1.enroll_user(user2, "StudentEnrollment")

      # set up a group category in that course with restricted self sign-up and
      # put both users in one of its groups
      category = group_category
      category.configure_self_signup(true, true)
      category.save
      group = category.groups.create(context: @course)
      group.add_user(user1)
      group.add_user(user2)
      expect(category).not_to have_heterogenous_group

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user2.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should be removed from the group, keeping the group and the category
      # happily satisfying the self sign-up restriction.
      expect(group.users.size).to eq 1
      expect(group.users).not_to include(user2)
      expect(group).to have_common_section
      expect(category).not_to have_heterogenous_group
    end

    it "does not ungroup the user when a the group doesn't care" do
      # set up course with two users in one section
      user1 = user_model
      user2 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, "StudentEnrollment")
      section1.enroll_user(user2, "StudentEnrollment")

      # set up a group category in that course *without* restrictions on self
      # sign-up and put both users in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(context: @course)
      group.add_user(user1)
      group.add_user(user2)

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user2.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should still be in the group
      expect(group.users.size).to eq 2
      expect(group.users).to include(user2)
    end

    it "ungroups the user from all groups, restricted and unrestricted when completely unenrolling from the course" do
      user1 = user_model name: "Andy"
      user2 = user_model name: "Bruce"

      section1 = @course.course_sections.create name: "Section 1"

      @course.enroll_user(user1, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(user2, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)

      # created category for restricted groups
      res_category = group_category name: "restricted"
      res_category.configure_self_signup(true, true)
      res_category.save

      # created category for unrestricted groups
      unrestricted_category = group_category name: "unrestricted"
      unrestricted_category.configure_self_signup(true, false)
      unrestricted_category.save

      # Group 1 - restricted group
      group1 = res_category.groups.create(name: "Group1", context: @course)
      group1.add_user(user1)
      group1.add_user(user2)

      # Group 2 - unrestricted group
      group2 = unrestricted_category.groups.create(name: "Group2 (Unrestricted)", context: @course)
      group2.add_user(user1)
      group2.add_user(user2)

      user2.enrollments.where(course_section_id: section1.id).first.destroy
      group1.reload
      group2.reload

      expect(group1.users.size).to eq 1
      expect(group2.users.size).to eq 1
      expect(group1.users).not_to include(user2)
      expect(group2.users).not_to include(user2)
      expect(group1).to have_common_section
    end

    it "ungroups the user from the restricted group when deleting enrollment to one section but user is still enrolled in another section" do
      user1 = user_model name: "Andy"
      user2 = user_model name: "Bruce"

      section1 = @course.course_sections.create name: "Section 1"
      section2 = @course.course_sections.create name: "Section 2"

      # we should have more than one student enrolled in section to exercise common_to_section check.
      @course.enroll_user(user1, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(user2, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      # enroll user2 in a second section
      @course.enroll_user(user2, "StudentEnrollment", section: section2, enrollment_state: "active", allow_multiple_enrollments: true)

      # set up a group category for restricted groups
      # and put both users in one of its groups
      category = group_category name: "restricted category"
      category.configure_self_signup(true, true)
      category.save

      # restricted group
      group = category.groups.create(name: "restricted group", context: @course)
      group.add_user(user1)
      group.add_user(user2)

      # remove user2 from the section (effectively unenrolled from a section of the course)
      user2.enrollments.where(course_section_id: section1.id).first.destroy
      group.reload

      # user2 should be removed from the group
      expect(group.users.size).to eq 1
      expect(group.users).not_to include(user2)
      expect(group).to have_common_section
    end

    it "does not ungroup the user from unrestricted group when deleting enrollment to one section but user is still enrolled in another section" do
      user1 = user_model name: "Andy"
      user2 = user_model name: "Bruce"

      section1 = @course.course_sections.create name: "Section 1"
      section2 = @course.course_sections.create name: "Section 2"

      # we should have more than one student enrolled in section to exercise common_to_section check.
      @course.enroll_user(user1, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(user2, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      # enroll user2 in a second section
      @course.enroll_user(user2, "StudentEnrollment", section: section2, enrollment_state: "active", allow_multiple_enrollments: true)

      # set up a group category for unrestricted groups
      unrestricted_category = group_category name: "unrestricted category"
      unrestricted_category.configure_self_signup(true, false)
      unrestricted_category.save

      # unrestricted group
      group = unrestricted_category.groups.create(name: "unrestricted group", context: @course)
      group.add_user(user1)
      group.add_user(user2)

      # remove user2 from the section (effectively unenrolled from a section of the course)
      user2.enrollments.where(course_section_id: section1.id).first.destroy
      group.reload

      # user2 should not be removed from group 2
      expect(group.users.size).to eq 2
      expect(group.users).to include(user2)
      expect(group).not_to have_common_section
    end

    it "does not ungroup the user from restricted group when there's not another user in the group and user is still enrolled in another section" do
      user1 = user_model name: "Andy"

      section1 = @course.course_sections.create name: "Section 1"
      section2 = @course.course_sections.create name: "Section 2"

      # enroll user in two sections
      @course.enroll_user(user1, "StudentEnrollment", section: section1, enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(user1, "StudentEnrollment", section: section2, enrollment_state: "active", allow_multiple_enrollments: true)

      # set up a group category for restricted groups
      restricted_category = group_category name: "restricted category"
      restricted_category.configure_self_signup(true, true)
      restricted_category.save

      # restricted group
      group = restricted_category.groups.create(name: "restricted group", context: @course)
      group.add_user(user1)

      # remove user from the section (effectively unenrolled from a section of the course)
      user1.enrollments.where(course_section_id: section1.id).first.destroy
      group.reload

      # he should not be removed from the group
      expect(group.users.size).to eq 1
      expect(group.users).to include(user1)
      expect(group).to have_common_section
    end

    it "ungroups the user even when there's not another user in the group if the enrollment is deleted" do
      # set up course with only one user in one section
      user1 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, "StudentEnrollment")

      # set up a group category in that course with restricted self sign-up and
      # put the user in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(context: @course)
      group.add_user(user1)

      # remove the user from the section (effectively unenrolled from the course)
      user1.enrollments.first.destroy
      group.reload
      category.reload

      # he should not be in the group
      expect(group.users.size).to eq 0
    end

    it "does not ungroup the user when there's not another user in the group" do
      # set up course with only one user in one section
      user1 = user_model
      section1 = @course.course_sections.create
      section1.enroll_user(user1, "StudentEnrollment")

      # set up a group category in that course with restricted self sign-up and
      # put the user in one of its groups
      category = group_category
      category.configure_self_signup(true, false)
      category.save
      group = category.groups.create(context: @course)
      group.add_user(user1)

      # move a user to a new section
      section2 = @course.course_sections.create
      enrollment = user1.enrollments.first
      enrollment.course_section = section2
      enrollment.save
      group.reload
      category.reload

      # he should still be in the group
      expect(group.users.size).to eq 1
      expect(group.users).to include(user1)
    end

    it "ignores previously deleted memberships" do
      # set up course with a user in one section
      user = user_model
      section1 = @course.course_sections.create
      enrollment = section1.enroll_user(user, "StudentEnrollment")

      # set up a group without a group category and put the user in it
      group = @course.groups.create
      group.add_user(user)

      # mark the membership as deleted
      membership = group.group_memberships.where(user_id: user).first
      membership.workflow_state = "deleted"
      membership.save!

      # delete the enrollment to trigger audit_groups_for_deleted_enrollments processing
      expect { enrollment.destroy }.not_to raise_error

      # she should still be removed from the group
      expect(group.users.size).to eq 0
      expect(group.users).not_to include(user)
    end
  end

  describe "for_email" do
    before :once do
      course_factory(active_all: true)
    end

    it "returns candidate enrollments" do
      user_factory
      @user.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user, { username: "jt@instructure.com" })
      @course.enroll_user(@user)
      expect(Enrollment.invited.for_email("jt@instructure.com").count).to eq 1
    end

    it "does not return non-candidate enrollments" do
      # mismatched e-mail
      user_factory
      @user.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user, { username: "bob@instructure.com" })
      @course.enroll_user(@user)
      # registered user
      user_factory
      communication_channel(@user, { username: "jt@instructure.com" })
      @user.register!
      @course.enroll_user(@user)
      # active e-mail
      user_factory
      @user.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user, { username: "jt@instructure.com", active_cc: true })
      @course.enroll_user(@user)
      # accepted enrollment
      user_factory
      @user.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user, { username: "jt@instructure.com" })
      @course.enroll_user(@user).accept
      # rejected enrollment
      user_factory
      @user.update_attribute(:workflow_state, "creation_pending")
      communication_channel(@user, { username: "jt@instructure.com" })
      @course.enroll_user(@user).reject

      expect(Enrollment.invited.for_email("jt@instructure.com")).to eq []
    end
  end

  describe "cached_temporary_invitations" do
    it "uncaches temporary user invitations when state changes" do
      enable_cache do
        course_factory(active_all: true)
        user_factory
        @user.update_attribute(:workflow_state, "creation_pending")
        communication_channel(@user, { username: "jt@instructure.com" })
        @enrollment = @course.enroll_user(@user)
        expect(Enrollment.cached_temporary_invitations("jt@instructure.com").length).to eq 1
        @enrollment.accept
        expect(Enrollment.cached_temporary_invitations("jt@instructure.com")).to eq []
      end
    end

    it "uncaches user enrollments when rejected" do
      enable_cache do
        course_with_student(active_course: 1)
        User.where(id: @user).update_all(updated_at: 1.year.ago)
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq [@enrollment]
        @enrollment.reject!
        # have to get the new updated_at
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq []
      end
    end

    it "uncaches user enrollments when deleted" do
      enable_cache do
        course_with_student(active_course: 1)
        User.where(id: @user).update_all(updated_at: 1.year.ago)
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq [@enrollment]
        @enrollment.destroy
        # have to get the new updated_at
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq []
      end
    end

    context "sharding" do
      specs_require_sharding

      describe "limit_privileges_to_course_section!" do
        it "uses the right shard to find the enrollments" do
          @shard1.activate do
            account = Account.create!
            course_with_student(active_all: true, account:)
          end

          @shard2.activate do
            Enrollment.limit_privileges_to_course_section!(@course, @user, true)
          end

          expect(@enrollment.reload.limit_privileges_to_course_section).to be_truthy
        end
      end

      describe "cached_temporary_invitations" do
        before :once do
          course_factory(active_all: true)
          user_factory
          @user.update_attribute(:workflow_state, "creation_pending")
          communication_channel(@user, { username: "jt@instructure.com" })
          @enrollment1 = @course.enroll_user(@user)
          @shard1.activate do
            account = Account.create!
            course_factory(active_all: true, account:)
            user_factory
            @user.update_attribute(:workflow_state, "creation_pending")
            communication_channel(@user, { username: "jt@instructure.com" })
            @enrollment2 = @course.enroll_user(@user)
          end
        end

        before do
          allow(Enrollment).to receive(:cross_shard_invitations?).and_return(true)
          skip "working CommunicationChannel.associated_shards" unless CommunicationChannel.associated_shards("jt@instructure.com").length == 2
        end

        it "includes invitations from other shards" do
          expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          @shard1.activate do
            expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
          @shard2.activate do
            expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "has a single cache for all shards" do
          enable_cache do
            @shard2.activate do
              expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            expect(Shard).not_to receive(:with_each_shard)
            @shard1.activate do
              expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
            end
            expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
          end
        end

        it "invalidates the cache from any shard" do
          enable_cache do
            @shard2.activate do
              expect(Enrollment.cached_temporary_invitations("jt@instructure.com").sort_by(&:global_id)).to eq [@enrollment1, @enrollment2].sort_by(&:global_id)
              @enrollment2.reject!
            end
            @shard1.activate do
              expect(Enrollment.cached_temporary_invitations("jt@instructure.com")).to eq [@enrollment1]
              @enrollment1.reject!
            end
            expect(Enrollment.cached_temporary_invitations("jt@instructure.com")).to eq []
          end
        end
      end
    end
  end

  describe "effective_start_at" do
    before :once do
      course_with_student(active_all: true)
      @term = @course.enrollment_term
      @section = @enrollment.course_section

      # 7 different possible times, make sure they're distinct
      @enrollment_date_start_at = 7.days.ago
      @enrollment.start_at = 6.days.ago
      @section.start_at = 5.days.ago
      @course.start_at = 4.days.ago
      @term.start_at = 3.days.ago
      @section.created_at = 2.days.ago
      @course.created_at = 1.day.ago
    end

    it "utilizes to enrollment_dates if it has a value" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[@enrollment_date_start_at, nil]])
      expect(@enrollment.effective_start_at).to eq @enrollment_date_start_at
    end

    it "uses earliest value from enrollment_dates if it has multiple" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[@enrollment.start_at, nil], [@enrollment_date_start_at, nil]])
      expect(@enrollment.effective_start_at).to eq @enrollment_date_start_at
    end

    it "follows chain of fallbacks in correct order if no enrollment_dates" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[nil, Time.now]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      expect(@enrollment.effective_start_at).to eq @enrollment.start_at
      @enrollment.start_at = nil
      expect(@enrollment.effective_start_at).to eq @section.start_at
      @section.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.start_at
      @course.start_at = nil
      expect(@enrollment.effective_start_at).to eq @term.start_at
      @term.start_at = nil
      expect(@enrollment.effective_start_at).to eq @section.created_at
      @section.created_at = nil
      expect(@enrollment.effective_start_at).to eq @course.created_at
      @course.created_at = nil
      expect(@enrollment.effective_start_at).to be_nil
    end

    it "does not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil
      expect(@enrollment.effective_start_at).to eq @enrollment.start_at
      @enrollment.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.start_at
      @course.start_at = nil
      expect(@enrollment.effective_start_at).to eq @course.created_at
      @course.created_at = nil
      expect(@enrollment.effective_start_at).to be_nil
    end
  end

  describe "effective_end_at" do
    before :once do
      course_with_student(active_all: true)
      @term = @course.enrollment_term
      @section = @enrollment.course_section

      # 5 different possible times, make sure they're distinct
      @enrollment_date_end_at = 1.day.ago
      @enrollment.end_at = 2.days.ago
      @section.end_at = 3.days.ago
      @course.conclude_at = 4.days.ago
      @term.end_at = 5.days.ago
    end

    it "utilizes to enrollment_dates if it has a value" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[nil, @enrollment_date_end_at]])
      expect(@enrollment.effective_end_at).to eq @enrollment_date_end_at
    end

    it "uses earliest value from enrollment_dates if it has multiple" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[nil, @enrollment.end_at], [nil, @enrollment_date_end_at]])
      expect(@enrollment.effective_end_at).to eq @enrollment_date_end_at
    end

    it "follows chain of fallbacks in correct order if no enrollment_dates" do
      allow(@enrollment).to receive(:enrollment_dates).and_return([[nil, nil]])

      # start peeling away things from most preferred to least preferred to
      # test fallback chain
      expect(@enrollment.effective_end_at).to eq @enrollment.end_at
      @enrollment.end_at = nil
      expect(@enrollment.effective_end_at).to eq @section.end_at
      @section.end_at = nil
      expect(@enrollment.effective_end_at).to eq @course.conclude_at
      @course.conclude_at = nil
      expect(@enrollment.effective_end_at).to eq @term.end_at
      @term.end_at = nil
      expect(@enrollment.effective_end_at).to be_nil
    end

    it "does not explode when missing section or term" do
      @enrollment.course_section = nil
      @course.enrollment_term = nil

      expect(@enrollment.effective_end_at).to eq @enrollment.end_at
      @enrollment.end_at = nil
      expect(@enrollment.effective_end_at).to eq @course.conclude_at
      @course.conclude_at = nil
      expect(@enrollment.effective_end_at).to be_nil
    end
  end

  describe "conclude" do
    it "removes the enrollment from User#cached_currentish_enrollments" do
      enable_cache do
        course_with_student(active_all: 1)
        User.where(id: @user).update_all(updated_at: 1.day.ago)
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq [@enrollment]
        @enrollment.conclude
        @user.reload
        expect(@user.cached_currentish_enrollments).to eq []
      end
    end
  end

  describe "unconclude" do
    it "adds the enrollment to User#cached_currentish_enrollments" do
      enable_cache do
        course_with_student active_course: true, enrollment_state: "completed"
        User.where(id: @student).update_all(updated_at: 1.day.ago)
        @student.reload
        expect(@student.cached_currentish_enrollments).to eq []
        @enrollment.unconclude
        expect(@student.cached_currentish_enrollments).to eq [@enrollment]
      end
    end
  end

  describe "observing users" do
    before :once do
      @student = user_factory(active_all: true)
      @parent = user_with_pseudonym(active_all: true)
      add_linked_observer(@student, @parent)
    end

    it "gets new observer enrollments when an observed user gets a new enrollment" do
      se = course_with_student(active_all: true, user: @student)
      pe = @parent.observer_enrollments.first

      expect(pe).not_to be_nil
      expect(pe.course_id).to eql se.course_id
      expect(pe.course_section_id).to eql se.course_section_id
      expect(pe.workflow_state).to eql se.workflow_state
      expect(pe.associated_user_id).to eql se.user_id
    end

    it 'defaults observer enrollments to "active" state' do
      course_factory(active_all: true)
      @course.enroll_student(@student, enrollment_state: "invited")
      pe = @parent.observer_enrollments.where(course_id: @course).first
      expect(pe).not_to be_nil
      expect(pe.workflow_state).to eql "active"
    end

    it "updates their observer enrollments when an observed user's enrollment is updated" do
      se = course_with_student(user: @student)
      pe = @parent.observer_enrollments.first
      expect(pe).not_to be_nil

      se.invite
      se.accept
      expect(pe.reload).to be_active

      se.complete
      expect(pe.reload).to be_completed
    end

    it "does not undelete observer enrollments if the student enrollment wasn't already deleted" do
      se = course_with_student(user: @student)
      pe = @parent.observer_enrollments.first
      expect(pe).not_to be_nil
      pe.destroy

      se.invite
      expect(pe.reload).to be_deleted

      se.accept
      expect(pe.reload).to be_deleted
    end

    it "does not allow an observer to be observed by a user they are observing" do
      @observed = User.create!
      @observer = User.create!
      @course = Course.create!

      @enrollment = StudentEnrollment.create!(user: @observed, course: @course)
      @enrollment2 = StudentEnrollment.create!(user: @observer, course: @course)

      add_linked_observer(@observed, @observer)
      add_linked_observer(@observer, @observed)

      @enrollment.type = "ObserverEnrollment"
      @enrollment.associated_user_id = @enrollment2.user_id
      @enrollment.save!

      @enrollment2.type = "ObserverEnrollment"
      @enrollment2.associated_user_id = @enrollment.user_id

      expect(@enrollment).to be_valid
      expect { @enrollment2.save! }.to raise_error("Validation failed: Associated user Cannot observe observer observing self")
    end

    it "allows existing observer enrollment cycles to be deleted" do
      u1 = User.create!
      u2 = User.create!
      course = Course.create!

      e1 = ObserverEnrollment.create!(course:, user: u1, associated_user_id: u2.id)
      e2 = ObserverEnrollment.create!(course:, user: u2)
      ObserverEnrollment.where(id: e2).update_all(associated_user_id: u1.id) # bypass the validation

      expect(e1).not_to be_valid

      e1.destroy

      expect(e1).to be_valid
      expect(e1).to be_deleted
    end

    context "sharding" do
      specs_require_sharding

      it "allows enrolling a user that is observed from another shard" do
        se = @shard1.activate do
          @other_account = Account.create!
          expect_any_instance_of(User).to receive(:can_be_enrolled_in_course?).and_return(true)
          course_with_student(account: @other_account, active_all: true, user: @student)
        end
        add_linked_observer(@student, @parent, root_account: @other_account)
        pe = @parent.observer_enrollments.shard(@shard1).first

        expect(pe).not_to be_nil
        expect(pe.course_id).to eql se.course_id
        expect(pe.course_section_id).to eql se.course_section_id
        expect(pe.workflow_state).to eql se.workflow_state
        expect(pe.associated_user_id).to eql se.user_id
      end
    end
  end

  describe "temporary enrollments" do
    before(:once) do
      Account.default.enable_feature!(:temporary_enrollments)
      @source_user = user_factory(active_all: true)
      @temporary_enrollment_recipient = user_factory(active_all: true)
      temporary_enrollment_recipient2 = user_factory(active_all: true)
      @course1 = course_with_teacher(active_all: true, user: @source_user).course
      temporary_enrollment_pairing = TemporaryEnrollmentPairing.create!(root_account: Account.default, created_by: account_admin_user)
      @recipient_temp_enrollment = @course1.enroll_user(
        @temporary_enrollment_recipient,
        "TeacherEnrollment",
        {
          role: teacher_role,
          temporary_enrollment_source_user_id: @source_user.id,
          temporary_enrollment_pairing_id: temporary_enrollment_pairing.id
        }
      )
      course2 = course_with_teacher(active_all: true, user: @source_user).course
      @recipient2_temp_enrollment = course2.enroll_user(
        temporary_enrollment_recipient2,
        "TeacherEnrollment",
        {
          role: teacher_role,
          temporary_enrollment_source_user_id: @source_user.id,
          temporary_enrollment_pairing_id: temporary_enrollment_pairing.id
        }
      )
    end

    it "retrieves temporary enrollment recipients for provider" do
      expect(Enrollment.temporary_enrollment_recipients_for_provider(@source_user).sort)
        .to eq([@recipient_temp_enrollment, @recipient2_temp_enrollment].sort)
    end

    it "retrieves temporary enrollments for recipient" do
      expect(Enrollment.temporary_enrollments_for_recipient(@temporary_enrollment_recipient).take)
        .to eq(@recipient_temp_enrollment)
    end

    it "returns a boolean value if self is a temporary enrollment" do
      @recipient2_temp_enrollment.update!(temporary_enrollment_source_user_id: nil)
      expect(@recipient_temp_enrollment.temporary_enrollment?).to be_truthy
      expect(@recipient2_temp_enrollment.temporary_enrollment?).to be_falsey
    end
  end

  describe "#can_be_deleted_by" do
    describe "on a student enrollment with granular_permissions_manage_users" do
      let(:user) { double(id: 42) }
      let(:session) { double }

      before do
        course_with_student
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @enrollment.reload
      end

      it "is true for a user who has been granted :remove_student_from_course" do
        allow(@course).to receive(:grants_right?).with(user, session, :remove_student_from_course).and_return(true)
        allow(@course).to receive(:grants_right?).with(user, session, :allow_course_admin_actions).and_return(false)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_truthy
      end

      it "is false for a user without :remove_student_from_course" do
        allow(@course).to receive(:grants_right?).with(user, session, :remove_student_from_course).and_return(false)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end

      it "is false for someone with :allow_course_admin_actions in other context" do
        context = CourseSection.new(id: 10)
        allow(context).to receive(:grants_right?).with(user, session, :remove_student_from_course).and_return(true)
        allow(context).to receive(:grants_right?).with(user, session, :allow_course_admin_actions).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, context, session)).to be_falsey
      end

      it "is false if a user is trying to remove their own enrollment" do
        allow(@course).to receive(:grants_right?).with(user, session, :remove_student_from_course).and_return(true)
        allow(@course).to receive(:grants_right?).with(user, session, :allow_course_admin_actions).and_return(false)
        allow(@course).to receive_messages(account: @course)
        @enrollment.user_id = user.id
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end
    end

    describe "on an observer enrollment with granular_permission_manage_users" do
      let(:user) { double(id: 42) }
      let(:session) { double }

      before do
        course_with_observer
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @enrollment.reload
      end

      it "is true with :remove_observer_from_course" do
        allow(@course).to receive(:grants_right?).and_return(false)
        allow(@course).to receive(:grants_right?).with(user, session, :remove_observer_from_course).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_truthy
      end

      it "is false with :allow_course_admin_actions but not the granular" do
        allow(@course).to receive(:grants_right?).and_return(false)
        allow(@course).to receive(:grants_right?).with(user, session, :allow_course_admin_actions).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end

      it "is false otherwise" do
        allow(@course).to receive(:grants_right?).and_return(false)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end
    end

    describe "on a teacher enrollment with granular_permission_manage_users" do
      let(:user) { double(id: 42) }
      let(:session) { double }

      before do
        course_with_teacher
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @enrollment.reload
      end

      it "is false with :manage_students" do
        allow(@course).to receive(:grants_right?).and_return(false)
        allow(@course).to receive(:grants_right?).with(user, session, :manage_students).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end

      it "is true without :allow_course_admin_actions but with the :remove_teacher_from_account granular" do
        allow(@course).to receive(:grants_right?).and_return(false)
        allow(@course).to receive(:grants_right?).with(user, session, :remove_teacher_from_course).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_truthy
      end

      it "is false with only :allow_course_admin_actions" do
        allow(@course).to receive(:grants_right?).and_return(false)
        allow(@course).to receive(:grants_right?).with(user, session, :allow_course_admin_actions).and_return(true)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end

      it "is false otherwise" do
        allow(@course).to receive(:grants_right?).and_return(false)
        expect(@enrollment.can_be_deleted_by(user, @course, session)).to be_falsey
      end
    end
  end

  describe "updating cached due dates" do
    before :once do
      course_with_student
      @assignments = [
        assignment_model(course: @course),
        assignment_model(course: @course)
      ]
    end

    it "triggers a batch when enrollment is created" do
      added_user = user_factory
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(added_user.id, @course, nil, { update_grades: true })
      @course.enroll_student(added_user)
    end

    it "does not trigger a batch when enrollment is not student" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute_users_for_course)
      @course.enroll_teacher(user_factory)
    end

    it "triggers a batch when enrollment is deleted" do
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(@enrollment.user_id, @course, nil, { update_grades: false })
      @enrollment.destroy
    end

    it "does not trigger when nothing changed" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute_users_for_course)
      @enrollment.save
    end

    it "does not trigger when set_update_cached_due_dates callback is suspended" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute_users_for_course)
      Enrollment.suspend_callbacks(:set_update_cached_due_dates) do
        @course.enroll_student(user_factory)
      end
    end

    it "triggers once for enrollment.destroy" do
      override = assignment_override_model(assignment: @assignments.first)
      override.assignment_override_students.create(user: @student)
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).once
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      @enrollment.destroy
    end

    context "with mastery paths" do
      before do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
        assignment_override_model(
          assignment: @assignments.first,
          set_type: AssignmentOverride::SET_TYPE_NOOP,
          set_id: AssignmentOverride::NOOP_MASTERY_PATHS
        )
        @override = assignment_override_model(assignment: @assignments.first)
        @student_override = @override.assignment_override_students.create(user: @student)
      end

      it "restores assignment override from mastery paths" do
        @enrollment.destroy
        expect(@override.reload.workflow_state).to eq "deleted"
        expect(@student_override.reload.workflow_state).to eq "deleted"
        @enrollment.enrollment_state.update(state: "invited")
        @enrollment.update(workflow_state: "invited")
        @enrollment.reload.accept!
        expect(@override.reload.workflow_state).to eq "active"
        expect(@student_override.reload.workflow_state).to eq "active"
      end

      it "restores student assignment override from mastery paths" do
        other_student = User.create!
        @course.enroll_student(other_student, enrollment_state: :active)
        @override.assignment_override_students.create!(user: other_student)
        @enrollment.destroy
        expect(@override.reload.workflow_state).to eq "active"
        expect(@student_override.reload.workflow_state).to eq "deleted"
        @enrollment.enrollment_state.update(state: "invited")
        @enrollment.update(workflow_state: "invited")
        @enrollment.reload.accept!
        expect(@override.reload.workflow_state).to eq "active"
        expect(@student_override.reload.workflow_state).to eq "active"
      end
    end
  end

  describe "#student_with_conditions?" do
    it "returns false if the enrollment is neither a student enrollment nor a fake student enrollment" do
      allow(@enrollment).to receive_messages(student?: false, fake_student?: false)
      expect(@enrollment.student_with_conditions?(include_future: true, include_fake_student: true)).to be(false)
    end

    context "the enrollment is a student enrollment" do
      before do
        allow(@enrollment).to receive_messages(student?: true, fake_student?: false)
      end

      it "returns true if include_future is true" do
        expect(@enrollment.student_with_conditions?(include_future: true, include_fake_student: false)).to be(true)
      end

      it "returns true if include_future is false and the enrollment is active" do
        allow(@enrollment).to receive(:participating?).and_return(true)
        expect(@enrollment.student_with_conditions?(include_future: false, include_fake_student: false)).to be(true)
      end

      it "returns false if include_future is false and the enrollment is inactive" do
        allow(@enrollment).to receive(:participating?).and_return(false)
        expect(@enrollment.student_with_conditions?(include_future: false, include_fake_student: false)).to be(false)
      end
    end

    context "the enrollment is a fake student enrollment" do
      before do
        allow(@enrollment).to receive_messages(student?: false, fake_student?: true)
      end

      it "returns false if include_fake_student is false" do
        expect(@enrollment.student_with_conditions?(include_future: true, include_fake_student: false)).to be(false)
      end

      context "include_fake_student is passed in as true" do
        it "returns true if include_future is true" do
          expect(@enrollment.student_with_conditions?(include_future: true, include_fake_student: true)).to be(true)
        end

        it "returns true if include_future is false and the enrollment is active" do
          allow(@enrollment).to receive(:participating?).and_return(true)
          expect(@enrollment.student_with_conditions?(include_future: false, include_fake_student: true)).to be(true)
        end

        it "returns false if include_future is false and the enrollment is inactive" do
          allow(@enrollment).to receive(:participating?).and_return(false)
          expect(@enrollment.student_with_conditions?(include_future: false, include_fake_student: true)).to be(false)
        end
      end
    end
  end

  describe "readable_state_based_on_date" do
    before :once do
      course_factory(active_all: true)
      @enrollment = @course.enroll_student(user_factory)
      @enrollment.accept!
    end

    it "returns pending for future enrollments (even if view restricted)" do
      @course.start_at = 1.month.from_now
      @course.restrict_student_future_view = true
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      @enrollment.reload
      expect(@enrollment.state_based_on_date).to eq :inactive
      expect(@enrollment.readable_state_based_on_date).to eq :pending

      @course.restrict_student_future_view = false
      @course.save!

      @enrollment = Enrollment.find(@enrollment.id)
      expect(@enrollment.state_based_on_date).to eq :accepted
      expect(@enrollment.readable_state_based_on_date).to eq :pending
    end

    it "returns completed for completed enrollments (even if view restricted)" do
      @course.start_at = 2.months.ago
      @course.conclude_at = 1.month.ago
      @course.restrict_student_past_view = true
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      @enrollment.reload
      expect(@enrollment.state_based_on_date).to eq :inactive
      expect(@enrollment.readable_state_based_on_date).to eq :completed

      @course.complete!

      @enrollment = Enrollment.find(@enrollment.id)
      expect(@enrollment.state_based_on_date).to eq :inactive
      expect(@enrollment.readable_state_based_on_date).to eq :completed

      @course.restrict_student_past_view = false
      @course.save!

      @enrollment = Enrollment.find(@enrollment.id)
      expect(@enrollment.state_based_on_date).to eq :completed
      expect(@enrollment.readable_state_based_on_date).to eq :completed
    end
  end

  describe "update user account associations if necessary" do
    it "creates a user_account_association when restoring a deleted enrollment" do
      sub_account = Account.default.sub_accounts.create!
      course = Course.create!(account: sub_account)
      @enrollment = course.enroll_student(user_factory)
      expect(@user.user_account_associations.where(account: sub_account).exists?).to be true

      @enrollment.destroy
      expect(@user.user_account_associations.where(account: sub_account).exists?).to be false

      @enrollment.restore
      expect(@user.user_account_associations.where(account: sub_account).exists?).to be true
    end
  end

  it "orders by state based on date correctly" do
    u = user_factory(active_all: true)
    c1 = course_factory(active_all: true)
    c1.start_at = 1.day.from_now
    c1.conclude_at = 2.days.from_now
    c1.restrict_enrollments_to_course_dates = true
    c1.restrict_student_future_view = true
    c1.save!
    restricted_enroll = c1.enroll_student(u)

    c2 = course_factory(active_all: true)
    c2.start_at = 1.day.from_now
    c2.conclude_at = 2.days.from_now
    c2.restrict_enrollments_to_course_dates = true
    c2.save!
    future_enroll = c2.enroll_student(u)

    c3 = course_factory(active_all: true)
    active_enroll = c3.enroll_student(u)

    [restricted_enroll, future_enroll, active_enroll].each do |e|
      e.workflow_state = "active"
      e.save!
    end

    enrolls = Enrollment.where(id: [restricted_enroll, future_enroll, active_enroll])
                        .joins(:enrollment_state).order(Enrollment.state_by_date_rank_sql).to_a
    expect(enrolls).to eq [active_enroll, future_enroll, restricted_enroll]
  end

  describe "restoring completed enrollments" do
    before(:once) do
      @student = @user
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @enrollment = @course.enroll_student(@student, enrollment_state: :active)
      @assignment = @course.assignments.create!(submission_types: ["online_text_entry"], points_possible: 10)
    end

    it "restores deleted submissions for assignments that are still active" do
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        Submission.active.where(assignment_id: @assignment, user_id: @student.id).count
      }.from(0).to(1)
    end

    it "does not restore deleted submissions for assignments that are deleted" do
      @enrollment.destroy
      @assignment.destroy

      expect { @enrollment.update!(workflow_state: :completed) }.not_to(change do
        Submission.active.where(assignment_id: @assignment, user_id: @student.id).count
      end)
    end

    it "infers the appropriate workflow state for unsubmitted submissions when restoring them" do
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @assignment.all_submissions.find_by(user_id: @enrollment.user_id).workflow_state
      }.from("deleted").to("unsubmitted")
    end

    it "infers the appropriate workflow state for submitted, not-yet-graded submissions when restoring them" do
      @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "a submission!")
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @assignment.all_submissions.find_by(user_id: @enrollment.user_id).workflow_state
      }.from("deleted").to("submitted")
    end

    it "infers the appropriate workflow state for graded submissions when restoring them" do
      @assignment.grade_student(@user, grade: 8, grader: @teacher)
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @assignment.all_submissions.find_by(user_id: @enrollment.user_id).workflow_state
      }.from("deleted").to("graded")
    end

    it "infers the appropriate workflow state for excused submissions when restoring them" do
      @assignment.grade_student(@user, excused: true, grader: @teacher)
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @assignment.all_submissions.find_by(user_id: @enrollment.user_id).workflow_state
      }.from("deleted").to("graded")
    end

    it "infers the appropriate workflow state for pending review submissions when restoring them" do
      quiz_with_graded_submission(
        [{ question_data: { :name => "Q1", :points_possible => 1, "question_type" => "essay_question" } }],
        user: @student,
        course: @course
      )
      submission = @quiz.assignment.all_submissions.find_by(user_id: @enrollment.user_id)
      submission.update!(score: nil)
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        submission.reload.workflow_state
      }.from("deleted").to("pending_review")
    end

    it "restores deleted course scores" do
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @enrollment.scores.where(course_score: true).count
      }.from(0).to(1)
    end

    it "restores scores for assignment groups that are still active" do
      @enrollment.destroy
      assignment_group = @course.assignment_groups.active.first
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @enrollment.scores.where(assignment_group_id: assignment_group).count
      }.from(0).to(1)
    end

    it "does not restore scores for assignment groups that are deleted" do
      @enrollment.destroy
      assignment_group = @course.assignment_groups.active.first
      assignment_group.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.not_to(change do
        @enrollment.scores.where(assignment_group_id: assignment_group).count
      end)
    end

    it "restores scores for grading periods that are still active" do
      grading_period_group = @course.root_account.grading_period_groups.create!
      grading_period_group.enrollment_terms << @course.enrollment_term
      grading_period = grading_period_group.grading_periods.create!(
        title: "Grading Period",
        start_date: 2.months.ago,
        end_date: 1.month.ago
      )
      @enrollment.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.to change {
        @enrollment.scores.where(grading_period_id: grading_period).count
      }.from(0).to(1)
    end

    it "does not restore scores for grading periods that are deleted" do
      grading_period_group = @course.root_account.grading_period_groups.create!
      grading_period_group.enrollment_terms << @course.enrollment_term
      grading_period = grading_period_group.grading_periods.create!(
        title: "Grading Period",
        start_date: 2.months.ago,
        end_date: 1.month.ago
      )
      @enrollment.destroy
      grading_period.destroy
      expect { @enrollment.update!(workflow_state: :completed) }.not_to(change do
        @enrollment.scores.where(grading_period_id: grading_period).count
      end)
    end

    it "does not restore scores for grading periods that are not associated with the course" do
      grading_period_group = @course.root_account.grading_period_groups.create!
      grading_period_group.enrollment_terms << @course.enrollment_term
      grading_period = grading_period_group.grading_periods.create!(
        title: "Grading Period",
        start_date: 2.months.ago,
        end_date: 1.month.ago
      )
      @enrollment.destroy
      @course.enrollment_term.update!(grading_period_group_id: nil)
      expect { @enrollment.update!(workflow_state: :completed) }.not_to(change do
        @enrollment.scores.where(grading_period_id: grading_period).count
      end)
    end
  end

  describe "#sync_microsoft_group" do
    let(:course) { course_factory }
    let(:enrollment_type) { "StudentEnrollment" }

    before do
      MicrosoftSync::Group.create!(course:)
    end

    # enroll user without running callbacks like update_user_account_associations,
    # so that the only jobs getting enqueued are the MSFT sync group type
    def enroll_user
      course.enroll_user(user_factory, enrollment_type, skip_touch_user: true)
    end

    context "when feature flag is off" do
      before do
        course.root_account.disable_feature!(:microsoft_group_enrollments_syncing)
      end

      it "does not enqueue a job" do
        expect { enroll_user }.to not_change { Delayed::Job.where(tag: "MicrosoftSync::StateMachineJob#run_later").count }
      end
    end

    context "when feature flag is on" do
      before do
        course.root_account.enable_feature!(:microsoft_group_enrollments_syncing)
      end

      context "when account has turned sync off" do
        before do
          course.root_account.settings[:microsoft_sync_enabled] = false
          course.root_account.save!
        end

        it "does not enqueue a job" do
          expect { enroll_user }.to not_change { Delayed::Job.where(tag: "MicrosoftSync::StateMachineJob#run_later").count }
        end
      end

      context "when account has turned sync on" do
        before do
          course.root_account.settings[:microsoft_sync_enabled] = true
          course.root_account.save!
        end

        it "enqueues a job" do
          expect { enroll_user }.to change { Delayed::Job.where(tag: "MicrosoftSync::StateMachineJob#run_later").count }.by 1
        end

        it "calls MicrosoftSync::Group#enqueue_future_partial_sync" do
          expect_any_instance_of(MicrosoftSync::Group).to receive(:enqueue_future_partial_sync)
          enroll_user
        end

        context "when the enrollment is a StudentViewEnrollment" do
          let(:enrollment_type) { "StudentViewEnrollment" }

          it "does not enqueue a job" do
            expect { enroll_user }.to not_change { Delayed::Job.where(tag: "MicrosoftSync::StateMachineJob#run_later").count }
          end
        end
      end
    end
  end
end
