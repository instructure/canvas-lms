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

require_relative "../lib/validates_as_url"

describe Submission do
  subject(:submission) { Submission.new }

  before(:once) do
    course_with_teacher(active_all: true)
    course_with_student(active_all: true, course: @course)
    @context = @course
    @assignment = @context.assignments.create!(
      title: "some assignment",
      workflow_state: "published"
    )
    @valid_attributes = {
      assignment: @assignment,
      user: @user,
      grade: "1.5",
      grader: @teacher,
      url: "www.instructure.com",
      workflow_state: "submitted"
    }
  end

  it { is_expected.to validate_numericality_of(:points_deducted).is_greater_than_or_equal_to(0).allow_nil }
  it { is_expected.to validate_numericality_of(:seconds_late_override).is_greater_than_or_equal_to(0).allow_nil }
  it { is_expected.to validate_inclusion_of(:late_policy_status).in_array(%w[none missing late extended]).allow_nil }
  it { is_expected.to validate_inclusion_of(:cached_tardiness).in_array(["missing", "late"]).allow_nil }

  it { is_expected.to delegate_method(:auditable?).to(:assignment).with_prefix(true) }
  it { is_expected.to delegate_method(:can_be_moderated_grader?).to(:assignment).with_prefix(true) }

  describe "inferred values" do
    subject do
      submission.infer_values
      submission.workflow_state
    end

    let(:student) { @student }
    let(:assignment) { @assignment }

    describe "workflow_state" do
      context "when current state is unsubmitted and submitted_at is present" do
        before do
          submission.workflow_state = Submission.workflow_states.unsubmitted
          submission.submission_type = "online_text_entry"
          submission.submitted_at = Time.zone.now
        end

        it { is_expected.to eq Submission.workflow_states.submitted }
      end

      context "when current state is submitted and has_submission is false" do
        before do
          submission.workflow_state = Submission.workflow_states.submitted
        end

        it { is_expected.to eq Submission.workflow_states.unsubmitted }
      end

      context "when grade and score are present and grade matches current submission" do
        before do
          submission.submission_type = "online_text_entry"
          submission.submitted_at = Time.zone.now
          submission.grade = "5"
          submission.score = 5

          allow(submission).to receive(:grade_matches_current_submission).and_return(true)
        end

        it { is_expected.to eq Submission.workflow_states.graded }
      end

      context "when submission_type is online_quiz and latest submission is pending review" do
        before do
          submission.workflow_state = Submission.workflow_states.pending_review
          submission.submission_type = "online_quiz"

          allow(submission).to receive(:quiz_submission).and_return(double("QuizSubmission", "pending_review?" => true))
        end

        it { is_expected.to eq Submission.workflow_states.pending_review }
      end

      context "when workflow state is pending_review" do
        before do
          submission.workflow_state = Submission.workflow_states.pending_review
        end

        context "and the submission was graded by quizzes" do
          before do
            submission.grader_id = -1
            submission.cached_quiz_lti = true
          end

          it { is_expected.to eq Submission.workflow_states.pending_review }

          context "and the submission was manually given a late policy status of missing" do
            before do
              submission.grader_id = @teacher.id
              submission.cached_quiz_lti = true
              submission.late_policy_status = "missing"
            end

            it { is_expected.to eq Submission.workflow_states.pending_review }
          end

          context "and the submission was manually given a late policy status of late" do
            before do
              submission.grader_id = @teacher.id
              submission.cached_quiz_lti = true
              submission.late_policy_status = "late"
            end

            it { is_expected.to eq Submission.workflow_states.pending_review }
          end
        end
      end

      context "the submission's Lti::Result was marked as PendingManual by an external tool" do
        let(:tool) { external_tool_1_3_model }
        let(:result) { lti_result_model(result_overrides) }
        let(:submission) { result.submission }
        let(:result_overrides) do
          {
            assignment:,
            grading_progress: "PendingManual",
            result_score: assignment.points_possible,
            result_maximum: assignment.points_possible,
            tool:
          }
        end

        it "marks the submission as needing review" do
          submission.infer_values
          expect(submission.workflow_state).to eq Submission.workflow_states.pending_review
        end
      end
    end
  end

  describe ".json_serialization_full_parameters" do
    it "can be provided additional methods to include in the params" do
      params = Submission.json_serialization_full_parameters(methods: [:missing])
      expect(params[:methods]).to include :missing
    end

    it "can provide an additional method with singular form (no array)" do
      params = Submission.json_serialization_full_parameters(methods: :missing)
      expect(params[:methods]).to include :missing
    end
  end

  describe "#anonymous_id" do
    subject { submission.anonymous_id }

    let(:student) { @student }
    let(:assignment) { @assignment }

    it { is_expected.to be_blank }

    it "sets an anoymous_id on validation" do
      submission.validate
      expect(submission.anonymous_id).to be_present
    end

    it "does not change if already persisted" do
      submission = assignment.submissions.find_by!(user: student)
      expect { submission.save! }.not_to change { submission.anonymous_id }
    end
  end

  describe "#type_for_attempt" do
    before(:once) do
      @assignment.update!(submission_types: "online_text_entry,online_url")
      now = Time.zone.now
      Timecop.freeze(10.minutes.from_now(now)) do
        @assignment.submit_homework(@student, body: "hi", submission_type: "online_text_entry")
      end

      Timecop.freeze(20.minutes.from_now(now)) do
        @assignment.submit_homework(@student, url: "https://www.google.com", submission_type: "online_url")
      end
    end

    let(:submission) { @assignment.submissions.find_by(user: @student) }

    it "returns the correct submission type given the attempt number" do
      aggregate_failures do
        expect(submission.type_for_attempt(1)).to eq "online_text_entry"
        expect(submission.type_for_attempt(2)).to eq "online_url"
      end
    end

    it "returns nil if given a non-existent attempt number" do
      expect(submission.type_for_attempt(3)).to be_nil
    end
  end

  describe ".anonymous_ids_for" do
    subject { Submission.anonymous_ids_for(@first_assignment) }

    before do
      student_with_anonymous_ids = @student
      student_without_anonymous_ids = student_in_course(course: @course, active_all: true).user
      @first_assignment = @course.assignments.create!
      @course.assignments.create! # second_assignment
      @first_assignment_submission = @first_assignment.submissions.find_by!(user: student_with_anonymous_ids)
      Submission.where(user: student_without_anonymous_ids).update_all(anonymous_id: nil)
    end

    it "only contains submissions with anonymous_ids" do
      expect(subject).to contain_exactly(@first_assignment_submission.anonymous_id)
    end
  end

  describe "with grading periods" do
    let(:in_closed_grading_period) { 9.days.ago }
    let(:in_open_grading_period) { 1.day.from_now }
    let(:outside_of_any_grading_period) { 10.days.from_now }

    before(:once) do
      @root_account = @context.root_account
      group = @root_account.grading_period_groups.create!
      @closed_period = group.grading_periods.create!(
        title: "Closed!",
        start_date: 2.weeks.ago,
        end_date: 1.week.ago,
        close_date: 3.days.ago
      )
      @open_period = group.grading_periods.create!(
        title: "Open!",
        start_date: 3.days.ago,
        end_date: 3.days.from_now,
        close_date: 5.days.from_now
      )
      group.enrollment_terms << @context.enrollment_term
    end

    describe "permissions" do
      before(:once) do
        @admin = user_factory(active_all: true)
        @root_account.account_users.create!(user: @admin)
        @teacher = user_factory(active_all: true)
        @context.enroll_teacher(@teacher)
      end

      describe "grade" do
        context "the submission is deleted" do
          before(:once) do
            @assignment.due_at = in_open_grading_period
            @assignment.save!
            submission_spec_model
            @submission.update(workflow_state: "deleted")
          end

          it "does not have grade permissions if the user is a root account admin" do
            expect(@submission.grants_right?(@admin, :grade)).to be(false)
          end

          it "does not have grade permissions if the user is non-root account admin with manage_grades permissions" do
            expect(@submission.grants_right?(@teacher, :grade)).to be(false)
          end

          it "doesn't have grade permissions if the user is non-root account admin without manage_grades permissions" do
            @student = user_factory(active_all: true)
            @context.enroll_student(@student)
            expect(@submission.grants_right?(@student, :grade)).to be(false)
          end
        end

        context "the submission is due in an open grading period" do
          before(:once) do
            @assignment.due_at = in_open_grading_period
            @assignment.save!
            submission_spec_model
          end

          it "has grade permissions if the user is a root account admin" do
            expect(@submission.grants_right?(@admin, :grade)).to be(true)
          end

          it "has grade permissions if the user is non-root account admin with manage_grades permissions" do
            expect(@submission.grants_right?(@teacher, :grade)).to be(true)
          end

          it "doesn't have grade permissions if the user is non-root account admin without manage_grades permissions" do
            @student = user_factory(active_all: true)
            @context.enroll_student(@student)
            expect(@submission.grants_right?(@student, :grade)).to be(false)
          end
        end

        context "the submission is due outside of any grading period" do
          before(:once) do
            @assignment.due_at = outside_of_any_grading_period
            @assignment.save!
            submission_spec_model
          end

          it "has grade permissions if the user is a root account admin" do
            expect(@submission.grants_right?(@admin, :grade)).to be(true)
          end

          it "has grade permissions if the user is non-root account admin with manage_grades permissions" do
            expect(@submission.grants_right?(@teacher, :grade)).to be(true)
          end

          it "doesn't have grade permissions if the user is non-root account admin without manage_grades permissions" do
            @student = user_factory(active_all: true)
            @context.enroll_student(@student)
            expect(@submission.grants_right?(@student, :grade)).to be(false)
          end
        end

        context "when part of a moderated assignment" do
          before(:once) do
            @assignment.update!(
              moderated_grading: true,
              grader_count: 2
            )
            submission_spec_model(assignment: @assignment)
          end

          it "may not be graded if grades are not published" do
            expect(@submission.grants_right?(@teacher, :grade)).to be false
          end

          it "sets an error message indicating moderation is in progress if grades are not published" do
            @submission.grants_right?(@teacher, :grade)
            expect(@submission.grading_error_message).to eq "This assignment is currently being moderated"
          end

          it "may be graded if grades are not published but grade_posting_in_progress is true" do
            @submission.grade_posting_in_progress = true
            expect(@submission.grants_right?(@teacher, :grade)).to be true
          end

          it "may be graded when grades for the assignment are published" do
            @submission.assignment.update!(grades_published_at: Time.zone.now)
            expect(@submission.grants_right?(@teacher, :grade)).to be true
          end
        end
      end

      describe "make_group_comment" do
        let_once(:course) { Course.create! }
        let_once(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
        let_once(:student2) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
        let_once(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

        before(:once) do
          all_groups = @course.group_categories.create!(name: "all groups")
          all_groups.groups.create!(context: @course, name: "group 1").add_user(student)
          all_groups.groups.create!(context: @course, name: "group 2").add_user(student2)

          @group_assignment = course.assignments.create!(
            grade_group_students_individually: false,
            group_category: all_groups,
            name: "group assignment"
          )
          @submission = @group_assignment.submissions.find_by(user: student)
        end

        it "allows a student to make a group comment for their own submission" do
          expect(@submission.grants_right?(student, :make_group_comment)).to be true
        end

        it "allows a teacher to make a group comment" do
          expect(@submission.grants_right?(teacher, :make_group_comment)).to be true
        end

        it "allows a peer reviewer to make a group comment for their assigned submission" do
          @group_assignment.update!(peer_reviews: true)
          peer_submission = @group_assignment.submissions.find_by(user: student2)
          AssessmentRequest.create!(assessor: student2, assessor_asset: peer_submission, asset: @submission, user: student)
          expect(@submission.grants_right?(student2, :make_group_comment)).to be true
        end

        it "does not allow a student not peer reviewing to make a group comment" do
          @group_assignment.update!(peer_reviews: true)
          expect(@submission.grants_right?(student2, :make_group_comment)).to be false
        end
      end
    end
  end

  describe "update_quiz_submission" do
    before do
      submission.workflow_state = Submission.workflow_states.pending_review
      submission.submission_type = "online_quiz"
    end

    it "does not set_final_score if kept_score equals score without deductions" do
      quiz_submission_mock = double("QuizSubmission", "kept_score" => 123)
      allow(submission).to receive(:quiz_submission).and_return(quiz_submission_mock)
      submission.update(score: 100, points_deducted: 23, quiz_submission_id: 1)
      expect(quiz_submission_mock).not_to receive(:set_final_score)
      submission.update_quiz_submission
    end

    it "does set_final_score if kept_score differs from score without deductions" do
      quiz_submission_mock = double("QuizSubmission", "kept_score" => 100)
      allow(submission).to receive(:quiz_submission).and_return(quiz_submission_mock)
      submission.update(score: 100, points_deducted: 23, quiz_submission_id: 1)
      expect(quiz_submission_mock).to receive(:set_final_score)
      submission.update_quiz_submission
    end
  end

  describe "entered_score" do
    let(:submission) { @assignment.submissions.find_by!(user_id: @student) }

    it "returns nil if score is not present" do
      expect(submission.entered_score).to be_nil
    end

    it "returns score if no points deducted" do
      submission.update(score: 123)
      expect(submission.entered_score).to eql(submission.score)
    end

    it "returns score without deduction" do
      submission.update(score: 100, points_deducted: 23)
      expect(submission.entered_score).to eq 123
    end

    it "returns the score without deduction when late policy is disabled" do
      late_policy_factory(course: @course, deduct: 2.35, every: :day)
      @assignment.update!(due_at: 1.hour.ago, points_possible: 10, submission_types: "online_text_entry")
      @assignment.submit_homework(@student, body: "late submission")
      @assignment.grade_student(@student, grade: 10, grader: @teacher)
      @course.late_policy.update!(late_submission_deduction_enabled: false)
      expect(submission.entered_score).to eq 10.0
    end
  end

  describe "entered_grade" do
    let(:submission) { @assignment.submissions.find_by!(user_id: @student) }

    it "returns grade without deduction" do
      @assignment.update(grading_type: "percent", points_possible: 100)
      submission.update(score: 25.5, points_deducted: 60)
      expect(submission.entered_grade).to eql("85.5%")
    end

    it "returns grade if grading_type is pass_fail" do
      @assignment.update(grading_type: "pass_fail")
      submission.update(grade: "complete")
      expect(submission.entered_grade).to eql("complete")
    end

    it "returns the grade for a letter grade assignment with no points possible" do
      @assignment.update(grading_type: "letter_grade", points_possible: 0)
      submission.update(grade: "B")
      expect(submission.entered_grade).to eql("B")
    end

    it "returns the grade for a GPA scale assignment with no points possible" do
      @assignment.update(grading_type: "gpa_scale", points_possible: nil)
      submission.update(grade: "B")
      expect(submission.entered_grade).to eql("B")
    end
  end

  describe "cached_due_date" do
    before(:once) do
      @now = Time.zone.local(2013, 10, 18)
    end

    let(:submission) { @assignment.submissions.find_by!(user_id: @student) }

    it "gets initialized during submission creation" do
      # create an invited user, so that the submission is not automatically
      # created by the SubmissionLifecycleManager
      student_in_course(active_all: true)
      @assignment.update_attribute(:due_at, 1.day.ago)

      override = @assignment.assignment_overrides.build
      override.title = "Some Title"
      override.set = @course.default_section
      override.override_due_at(1.day.from_now)
      override.save!

      submission = @assignment.submissions.find_by!(user: @user)
      expect(submission.cached_due_date).to eq override.reload.due_at.change(usec: 0)
    end

    it "does not truncate seconds off of cached due dates" do
      time = DateTime.parse("2018-12-24 23:59:59")
      @assignment.update_attribute(:due_at, time)
      submission = @assignment.submissions.find_by!(user: @user)
      expect(submission.cached_due_date.to_i).to eq time.to_i
    end

    context "due date changes after student submits" do
      before(:once) do
        Timecop.freeze(@now) do
          @assignment.update!(due_at: 20.minutes.ago, submission_types: "online_text_entry")
          @assignment.submit_homework(@student, body: "a body")
        end
      end

      it "changes if the assignment due date changes" do
        expect { @assignment.update!(due_at: 15.minutes.ago(@now)) }.to change {
          submission.reload.cached_due_date
        }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
      end

      context "student overrides" do
        before(:once) do
          @override = @assignment.assignment_overrides.create!(due_at: 15.minutes.ago(@now), due_at_overridden: true)
        end

        it "changes if an override is added for the student" do
          expect { @override.assignment_override_students.create!(user: @student) }.to change {
            submission.reload.cached_due_date
          }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "changes if an individual override is added for the student, even when the due date is earlier " \
           "than an existing override that applies to the student for the assignment" do
          section = @course.course_sections.create!(name: "My Awesome Section")
          student_in_section(section, user: @student)
          @assignment.assignment_overrides.create!(
            due_at: 10.minutes.ago(@now),
            due_at_overridden: true,
            set: section
          )

          override = @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true
          )

          expect { override.assignment_override_students.create!(user: @student) }.to change {
            submission.reload.cached_due_date
          }.from(10.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "does not change if a non-individual-override is added for the student and the due date " \
           "is earlier than an existing override that applies to the student for the assignment" do
          category = @course.group_categories.create!(name: "New Group Category")
          group = @course.groups.create!(group_category: category)
          group.add_user(@student, "active")
          assignment = @course.assignments.create!(group_category: category)

          section = @course.course_sections.create!(name: "My Awesome Section")
          student_in_section(section, user: @student)
          assignment.assignment_overrides.create!(
            due_at: 10.minutes.ago(@now),
            due_at_overridden: true,
            set: section
          )

          expect do
            assignment.assignment_overrides.create!(
              due_at: 15.minutes.ago(@now),
              due_at_overridden: true,
              set: group
            )
          end.not_to change { submission.reload.cached_due_date }
        end

        it "changes if an override is removed for the student" do
          @override.assignment_override_students.create!(user: @student)
          expect { @override.assignment_override_students.find_by(user_id: @student).destroy }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(20.minutes.ago(@now))
        end

        it "changes if the due date for the override is changed" do
          @override.assignment_override_students.create!(user: @student, workflow_state: "active")
          expect { @override.update!(due_at: 14.minutes.ago(@now)) }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(14.minutes.ago(@now))
        end
      end

      context "section overrides" do
        before(:once) do
          @section = @course.course_sections.create!(name: "My Awesome Section")
        end

        it "changes if an override is added for the section the student is in" do
          student_in_section(@section, user: @student)
          expect do
            @assignment.assignment_overrides.create!(
              due_at: 15.minutes.ago(@now),
              due_at_overridden: true,
              set: @section
            )
          end.to change {
            submission.reload.cached_due_date
          }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "changes if a student is added to the section after the override is added for the section" do
          @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @section
          )

          expect { student_in_section(@section, user: @student) }.to change {
            submission.reload.cached_due_date
          }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "changes if a student is removed from a section with a due date for the assignment" do
          @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @section
          )

          @course.enroll_student(@student, section: @section, allow_multiple_enrollments: true).accept!
          expect { @student.enrollments.find_by(course_section_id: @section).destroy }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(20.minutes.ago(@now))
        end

        it "changes if the due date for the override is changed" do
          student_in_section(@section, user: @student)
          override = @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @section
          )
          expect { override.update!(due_at: 14.minutes.ago(@now)) }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(14.minutes.ago(@now))
        end
      end

      context "group overrides" do
        before(:once) do
          category = @course.group_categories.create!(name: "New Group Category")
          @group = @course.groups.create!(group_category: category)
          @assignment = @course.assignments.create!(group_category: category, due_at: 20.minutes.ago(@now))
          @assignment.submit_homework(@student, body: "a body")
        end

        it "changes if an override is added for the group the student is in" do
          @group.add_user(@student, "active")

          expect do
            @assignment.assignment_overrides.create!(
              due_at: 15.minutes.ago(@now),
              due_at_overridden: true,
              set: @group
            )
          end.to change {
            submission.reload.cached_due_date
          }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "changes if a student is added to the group after the override is added for the group" do
          @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @group
          )

          expect { @group.add_user(@student, "active") }.to change {
            submission.reload.cached_due_date
          }.from(20.minutes.ago(@now)).to(15.minutes.ago(@now))
        end

        it "changes if a student is removed from a group with a due date for the assignment" do
          @group.add_user(@student, "active")
          @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @group
          )

          expect { @group.group_memberships.find_by(user_id: @student).destroy }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(20.minutes.ago(@now))
        end

        it "changes if the due date for the override is changed" do
          @group.add_user(@student, "active")
          override = @assignment.assignment_overrides.create!(
            due_at: 15.minutes.ago(@now),
            due_at_overridden: true,
            set: @group
          )

          expect { override.update!(due_at: 14.minutes.ago(@now)) }.to change {
            submission.reload.cached_due_date
          }.from(15.minutes.ago(@now)).to(14.minutes.ago(@now))
        end
      end

      it "uses the individual override date, otherwise most lenient, if there are multiple overrides" do
        category = @course.group_categories.create!(name: "New Group Category")
        group = @course.groups.create!(group_category: category)
        assignment = @course.assignments.create!(group_category: category, due_at: 20.minutes.ago(@now))
        assignment.submit_homework(@student, body: "a body")

        section = @course.course_sections.create!(name: "My Awesome Section")
        @course.enroll_student(@student, section:, allow_multiple_enrollments: true).accept!
        assignment.assignment_overrides.create!(
          due_at: 6.minutes.ago(@now),
          due_at_overridden: true,
          set: section
        )

        group.add_user(@student, "active")
        assignment.assignment_overrides.create!(
          due_at: 21.minutes.ago(@now),
          due_at_overridden: true,
          set: group
        )

        student_override = assignment.assignment_overrides.create!(
          due_at: 14.minutes.ago(@now),
          due_at_overridden: true
        )
        override_student = student_override.assignment_override_students.create!(user: @student)

        submission = assignment.submissions.find_by!(user: @student)
        expect { override_student.destroy }.to change {
          submission.reload.cached_due_date
        }.from(14.minutes.ago(@now)).to(6.minutes.ago(@now))

        expect { @student.enrollments.find_by(course_section: section).destroy }.to change {
          submission.reload.cached_due_date
        }.from(6.minutes.ago(@now)).to(21.minutes.ago(@now))
      end

      it "uses override due dates instead of assignment due dates, even if the assignment due date is more lenient" do
        student_override = @assignment.assignment_overrides.create!(
          due_at: 21.minutes.ago(@now),
          due_at_overridden: true
        )

        student_override.assignment_override_students.create!(user: @student)
        expect(submission.cached_due_date).to eq(21.minutes.ago(@now))
      end

      it "falls back to use the assignment due date if all overrides are destroyed" do
        student_override = @assignment.assignment_overrides.create!(
          due_at: 21.minutes.ago(@now),
          due_at_overridden: true
        )

        override_student = student_override.assignment_override_students.create!(user: @student)
        expect { override_student.destroy }.to change {
          submission.reload.cached_due_date
        }.from(21.minutes.ago(@now)).to(20.minutes.ago(@now))
      end
    end
  end

  describe "#excused" do
    let(:submission) do
      submission = @assignment.submissions.find_by!(user: @student)
      submission.update!(excused: true)
      submission
    end

    let(:custom_grade_status) do
      admin = account_admin_user(account: @assignment.root_account)
      @assignment.root_account.custom_grade_statuses.create!(
        color: "#ABC",
        name: "yolo",
        created_by: admin
      )
    end

    it "sets excused to false if the late_policy_status is being changed to a not-nil value" do
      submission.update!(late_policy_status: "missing")
      expect(submission).not_to be_excused
    end

    it "does not set excused to false if the late_policy_status is being changed to a nil value" do
      # need to skip callbacks so excused does not get set to false
      submission.update_column(:late_policy_status, "missing")
      submission.update!(late_policy_status: nil)
      expect(submission).to be_excused
    end

    it "sets excused to false when a custom status is set" do
      expect { submission.update!(custom_grade_status:) }.to change {
        submission.excused?
      }.from(true).to(false)
    end

    it "does not set excused to false when a custom status is removed" do
      # need to skip callbacks so excused does not get set to false
      submission.update_column(:custom_grade_status_id, custom_grade_status.id)
      expect { submission.update!(custom_grade_status: nil) }.not_to change {
        submission.excused?
      }.from(true)
    end
  end

  describe "#late_policy_status" do
    let(:submission) do
      submission = @assignment.submissions.find_by!(user: @student)
      submission.update!(late_policy_status: "late", seconds_late_override: 60)
      submission
    end

    it "sets late_policy_status to nil if the submission is updated to be excused" do
      submission.update!(excused: true)
      expect(submission.late_policy_status).to be_nil
    end

    it "sets seconds_late_override to nil if the submission is updated to be excused" do
      submission.update!(excused: true)
      expect(submission.seconds_late_override).to be_nil
    end

    it "does not set late_policy_status to nil if the submission is updated to not be excused" do
      # need to skip callbacks so late_policy_status does not get set to nil
      submission.update_column(:excused, true)
      submission.update!(excused: false)
      expect(submission.late_policy_status).to eql "late"
    end

    it "does not set seconds_late_override to nil if the submission is updated to not be excused" do
      # need to skip callbacks so seconds_late_override does not get set to nil
      submission.update_column(:excused, true)
      submission.update!(excused: false)
      expect(submission.seconds_late_override).to be 60
    end

    context "custom statuses" do
      let(:custom_grade_status) do
        admin = account_admin_user(account: @assignment.root_account)
        @assignment.root_account.custom_grade_statuses.create!(
          color: "#ABC",
          name: "yolo",
          created_by: admin
        )
      end

      it "sets late_policy_status to nil if the custom_grade_status_id is being changed to a not-nil value" do
        submission.update!(custom_grade_status:)
        expect(submission.late_policy_status).to be_nil
      end

      it "sets seconds_late_override to nil if the submission is updated to have a custom status" do
        submission.update!(custom_grade_status:)
        expect(submission.seconds_late_override).to be_nil
      end

      it "does not set late_policy_status to nil if the custom_grade_status_id is being changed to a nil value" do
        # need to skip callbacks so excused does not get set to false
        submission.update_column(:custom_grade_status_id, custom_grade_status.id)
        submission.update!(custom_grade_status_id: nil)
        expect(submission.late_policy_status).to eql "late"
      end

      it "does not set seconds_late_override to nil if the submission is updated to not have a custom status" do
        # need to skip callbacks so seconds_late_override does not get set to nil
        submission.update_column(:custom_grade_status_id, custom_grade_status.id)
        submission.update!(custom_grade_status_id: nil)
        expect(submission.seconds_late_override).to be 60
      end
    end
  end

  describe "seconds_late_override" do
    let(:submission) { @assignment.submissions.find_by!(user: @student) }

    it "sets seconds_late_override to nil if the late_policy_status is set to anything other than 'late'" do
      submission.update!(late_policy_status: "late", seconds_late_override: 60)
      expect do
        submission.update!(late_policy_status: "missing")
      end.to change { submission.seconds_late_override }.from(60).to(nil)
    end

    it "does not set seconds_late_override if late_policy status is not 'late'" do
      submission.update!(seconds_late_override: 60)
      expect(submission.seconds_late_override).to be_nil
    end
  end

  describe "seconds_late" do
    before(:once) do
      @date = Time.zone.local(2017, 1, 15, 12)
      Timecop.travel(@date) do
        Auditors::ActiveRecord::Partitioner.process
      end
      @assignment.update!(due_at: 1.hour.ago(@date), submission_types: "online_text_entry")
    end

    let(:submission) { @assignment.submissions.find_by!(user_id: @student) }

    it "returns time between submitted_at and cached_due_date" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to eql 60.minutes.to_i
      end
    end

    it "is adjusted if the student resubmits" do
      Timecop.freeze(@date) { @assignment.submit_homework(@student, body: "a body") }
      Timecop.freeze(30.minutes.from_now(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to eql 90.minutes.to_i
      end
    end

    it "returns seconds_late_override if the submission has a late_policy_status of 'late' " \
       "and a seconds_late_override" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(late_policy_status: "late", seconds_late_override: 90.minutes)
        expect(submission.seconds_late).to eql 90.minutes.to_i
      end
    end

    it "is not adjusted if the student resubmits and the submission has a late_policy_status of 'late' " \
       "and a seconds_late_override" do
      Timecop.freeze(@date) { @assignment.submit_homework(@student, body: "a body") }
      submission.update!(late_policy_status: "late", seconds_late_override: 90.minutes)
      Timecop.freeze(40.minutes.from_now(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to eql 90.minutes.to_i
      end
    end

    it "returns 0 if the submission has a late_policy_status of 'late' but no seconds_late_override is present" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(late_policy_status: "late")
        expect(submission.seconds_late).to be 0
      end
    end

    it "is zero if it is not late" do
      Timecop.freeze(2.hours.ago(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to be 0
      end
    end

    it "is zero if it was turned in late but the teacher sets the late_policy_status to 'late' " \
       "and sets seconds_late_override to zero" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(late_policy_status: "late", seconds_late_override: 0)
        expect(submission.seconds_late).to be 0
      end
    end

    it "is zero if cached_due_date is nil" do
      Timecop.freeze(@date) do
        @assignment.update!(due_at: nil)
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to be 0
      end
    end

    it "subtracts 60 seconds from the time of submission when submission_type is 'online_quiz'" do
      Timecop.freeze(@date) do
        @assignment.update!(submission_types: "online_quiz")
        @assignment.submit_homework(@student, submission_type: "online_quiz", body: "a body")
        expect(submission.seconds_late).to eql 59.minutes.to_i
      end
    end

    context "when the submission is for a new quiz" do
      before do
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )

        @assignment.quiz_lti!
        @assignment.save!
      end

      it "subtracts 60 seconds from the submitted_at" do
        Timecop.freeze(@date) do
          submission = @assignment.submissions.find_by!(user: @student)
          submission.update!(submitted_at: Time.now.utc)
          expect(submission.seconds_late).to eql 59.minutes.to_i
        end
      end
    end

    it "includes seconds" do
      Timecop.freeze(30.seconds.from_now(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        expect(submission.seconds_late).to eql((60.minutes + 30.seconds).to_i)
      end
    end

    it "uses the current time if submitted_at is nil" do
      Timecop.freeze(1.day.from_now(@date)) do
        @assignment.grade_student(@student, score: 10, grader: @teacher)
        expect(submission.seconds_late).to eql 25.hours.to_i
      end
    end
  end

  describe "#apply_late_policy" do
    before(:once) do
      @date = Time.zone.local(2017, 1, 15, 12)
      Timecop.travel(@date) do
        Auditors::ActiveRecord::Partitioner.process
      end
      @assignment.update!(due_at: 3.hours.ago(@date), points_possible: 1000, submission_types: "online_text_entry")
      @late_policy = late_policy_model(deduct: 10.0, every: :hour, missing: 80.0)
    end

    let(:submission) { @assignment.submissions.find_by(user_id: @student) }

    context "as a before_save" do
      before(:once) do
        @late_policy.update!(course_id: @course)
      end

      it "deducts a percentage per interval late if grade_matches_current_submission is true" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          submission.score = 700
          submission.grade_matches_current_submission = true
          submission.save!
          expect(submission.points_deducted).to eq 300.0
        end
      end

      it "deducts a percentage per interval late if grade_matches_current_submission is nil" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          submission.score = 700
          submission.grade_matches_current_submission = nil
          submission.save!
          expect(submission.points_deducted).to eq 300.0
        end
      end

      it "deducts nothing if grade_matches_current_submission is false" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          submission.score = 700
          submission.grade_matches_current_submission = false
          submission.save!
          expect(submission.points_deducted).to be_nil
        end
      end

      it "sets points_deducted to nil if a submission's status is changed to missing" do
        submission.update!(score: 5, points_deducted: 2)
        expect { submission.update!(late_policy_status: "missing") }.to change {
          submission.points_deducted
        }.from(2).to(nil)
      end

      it "sets score to raw_score if a submission has points_deducted and the status is changed to missing" do
        submission.update!(score: 5, points_deducted: 2)
        expect { submission.update!(late_policy_status: "missing") }.to change {
          submission.score
        }.from(5).to(7)
      end

      it "keeps the given score if a submission is set to missing and given a score" do
        submission.update!(score: 5, points_deducted: 2)
        expect { submission.update!(score: 3, late_policy_status: "missing") }.to change {
          submission.score
        }.from(5).to(3)
      end
    end

    it "deducts nothing if grading period is closed" do
      grading_period = double("grading_period", closed?: true)
      expect(submission).to receive(:grading_period).and_return(grading_period)
      @assignment.submit_homework(@student, body: "a body")
      submission.score = 700
      submission.apply_late_policy(@late_policy, @assignment)
      expect(submission.score).to eq 700
      expect(submission.points_deducted).to be_nil
    end

    it "deducts a percentage per interval late" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.score = 700
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 400
        expect(submission.points_deducted).to eq 300
      end
    end

    it "deducts nothing if there is no late policy" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.score = 700
        submission.apply_late_policy(nil, @assignment)
        expect(submission.score).to eq 700
        expect(submission.points_deducted).to eq 0
      end
    end

    it "deducts nothing if the submission is not late" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "gary, what have you done?")
        submission.score = 700
        submission.late_policy_status = "missing"
        submission.apply_late_policy(@late_policy, @assignment)

        expect(submission.score).to eq 700
        expect(submission.points_deducted).to be_nil
      end
    end

    it "does not round decimal places in the score" do
      Timecop.freeze(2.days.ago(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        original_score = 1.3800000000000001
        submission.score = original_score
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq original_score
      end
    end

    it "deducts only once even if called twice" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.score = 800
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 500
        expect(submission.points_deducted).to eq 300
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 500
        expect(submission.points_deducted).to eq 300
      end
    end

    it "sets the points_deducted to 0.0 if the score is set to nil and the submission is late" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(score: 400, points_deducted: 300)
        submission.score = nil
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.points_deducted).to eq 0.0
      end
    end

    it "sets the points_deducted to nil if the score is set to nil and the submission is not late" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(score: 400, points_deducted: 300)
        submission.score = nil
        submission.late_policy_status = "none"
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.points_deducted).to be_nil
      end
    end

    it "applies missing policy if submission is missing" do
      Timecop.freeze(1.day.from_now(@date)) do
        submission.score = nil
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 200
      end
    end

    context "past due date" do
      it "removes missing status when missing submission is graded" do
        Timecop.freeze(1.day.from_now(@date)) do
          expect(submission.missing?).to be true
          @assignment.grade_student(@student, score: 500, grader: @teacher)
          submission.reload
          expect(submission.missing?).to be false
        end
      end

      it "does not remove missing status when missing status was given manually" do
        Timecop.freeze(1.day.from_now(@date)) do
          expect(submission.missing?).to be true
          submission.update!(late_policy_status: "missing")
          expect(submission.missing?).to be true
          @assignment.grade_student(@student, score: 500, grader: @teacher)
          submission.reload
          expect(submission.missing?).to be true
        end
      end
    end

    it "does not remove missing status when missing status was given manually" do
      @assignment.update!(due_at: 3.hours.from_now(@date), points_possible: 1000, submission_types: "online_text_entry")
      submission.reload
      Timecop.freeze(@date) do
        expect(submission.missing?).to be false
        submission.update!(late_policy_status: "missing")
        expect(submission.missing?).to be true
        @assignment.grade_student(@student, score: 500, grader: @teacher)
        submission.reload
        expect(submission.missing?).to be true
      end
    end

    it "sets grade_matches_current_submission to true when missing policy is applied" do
      Timecop.freeze(1.day.from_now(@date)) do
        submission.score = nil
        submission.grade_matches_current_submission = false
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.grade_matches_current_submission).to be true
      end
    end

    it "sets the workflow state to 'graded' when submission is missing" do
      Timecop.freeze(1.day.from_now(@date)) do
        submission.score = nil
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.workflow_state).to eq "graded"
      end
    end

    describe "posting of missing submissions" do
      before(:once) do
        late_policy_factory(course: @course, missing: 50)
      end

      context "when the submission was not previously posted" do
        context "for an automatically-posted assignment" do
          it "posts a previously-unscored submission if deducting points for missing submissions" do
            submission.update!(late_policy_status: :missing)
            expect(submission.posted_at).not_to be_nil
          end

          it "does not post the submission if missing submission deduction is not enabled" do
            @course.late_policy.update!(missing_submission_deduction_enabled: false)
            expect do
              submission.update!(late_policy_status: :missing)
            end.not_to change { submission.reload.posted_at }
          end

          it "does not update the posted-at date of an already-posted submission" do
            @assignment.post_submissions

            expect do
              submission.update!(late_policy_status: :missing)
            end.not_to change { submission.reload.posted_at }
          end
        end

        it "does not post submissions if the assignment is manually posted" do
          @assignment.post_policy.update!(post_manually: true)

          expect do
            submission.update!(late_policy_status: :missing)
          end.not_to change { submission.reload.posted_at }
        end
      end
    end

    it "does not change the score of a missing submission if it already has one" do
      Timecop.freeze(1.day.from_now(@date)) do
        @assignment.grade_student(@student, grade: 1000, grader: @teacher)
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to be 1000.0
      end
    end

    context "with regraded" do
      it "does not apply the deduction multiple times if submission saved multiple times" do
        @late_policy.update!(course_id: @course)
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          # The submission is saved once in grade_student.  Using sub
          # here to avoid masking/using the submission in the let
          # above. I want to make sure I'm using the exact same object
          # as returned by grade_student.
          sub = @assignment.grade_student(@student, grade: 1000, grader: @teacher).first
          sub.save!
          expect(sub.score).to be 700.0
        end
      end
    end

    context "assignment on paper" do
      before(:once) do
        @date = Time.zone.local(2017, 1, 15, 12)
        Timecop.travel(@date) do
          Auditors::ActiveRecord::Partitioner.process
        end
        @assignment.update!(due_at: 3.hours.ago(@date), points_possible: 1000, submission_types: "on_paper")
        @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :hour, missing: 80.0)
      end

      it "does not deduct from late assignment" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 700, grader: @teacher)
          expect(submission.score).to eq 700
          expect(submission.points_deducted).to be_nil
        end
      end

      it "does not grade missing assignment" do
        Timecop.freeze(@date) do
          submission.apply_late_policy
          expect(submission.score).to be_nil
          expect(submission.points_deducted).to be_nil
        end
      end

      it "deducts a percentage per interval late if manually marked late" do
        @assignment.submit_homework(@student, body: "a body")
        submission.late_policy_status = "late"
        submission.seconds_late_override = 4.hours
        submission.score = 700
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to be 300.0
        expect(submission.points_deducted).to eq 400
      end

      context "when change late_policy_status from late to none" do
        before do
          @assignment.course.update!(late_policy: @late_policy)
          @assignment.submit_homework(@student, body: "a body")

          submission.update!(
            score: 700,
            late_policy_status: "late",
            seconds_late_override: 4.hours
          )
        end

        it "removes late penalty from score" do
          expect { submission.update!(late_policy_status: "none") }
            .to change { submission.score }.from(300).to(700)
        end

        it "sets points_deducted to nil" do
          expect { submission.update!(late_policy_status: "none") }
            .to change { submission.points_deducted }.from(400).to(nil)
        end
      end

      context "when change late_policy_status from late to extended" do
        before do
          @assignment.course.update!(late_policy: @late_policy)
          @assignment.submit_homework(@student, body: "a body")

          submission.update!(
            score: 700,
            late_policy_status: "late",
            seconds_late_override: 4.hours
          )
        end

        it "removes late penalty from score" do
          expect { submission.update!(late_policy_status: "extended") }
            .to change { submission.score }.from(300).to(700)
        end

        it "sets points_deducted to nil" do
          expect { submission.update!(late_policy_status: "extended") }
            .to change { submission.points_deducted }.from(400).to(nil)
        end
      end

      context "when changing late_policy_status from none to nil" do
        before do
          @assignment.update!(due_at: 1.hour.from_now)
          @assignment.course.update!(late_policy: @late_policy)
          @assignment.submit_homework(@student, body: "a body")
          submission.update!(score: 700, late_policy_status: "late", seconds_late_override: 4.hours)
        end

        it "applies the late policy to the score" do
          expect { submission.update!(late_policy_status: "none") }
            .to change { submission.score }.from(300).to(700)
        end

        it "applies the late policy to points_deducted" do
          expect { submission.update!(late_policy_status: "none") }
            .to change { submission.points_deducted }.from(400).to(nil)
        end
      end

      it "applies missing policy if submission is manually marked missing" do
        Timecop.freeze(1.day.from_now(@date)) do
          submission.score = nil
          submission.late_policy_status = "missing"
          submission.apply_late_policy(@late_policy, @assignment)
          expect(submission.score).to eq 200
        end
      end
    end

    context "assignment expecting no submission" do
      before(:once) do
        @date = Time.zone.local(2017, 1, 15, 12)
        Timecop.travel(@date) do
          Auditors::ActiveRecord::Partitioner.process
        end
        @assignment.update!(due_at: 3.hours.ago(@date), points_possible: 1000, submission_types: "none")
        @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :hour, missing: 80.0)
      end

      it "does not deduct from late assignment" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 700, grader: @teacher)
          expect(submission.score).to eq 700
          expect(submission.points_deducted).to be_nil
        end
      end

      it "does not grade missing assignment" do
        Timecop.freeze(@date) do
          submission.apply_late_policy
          expect(submission.score).to be_nil
          expect(submission.points_deducted).to be_nil
        end
      end

      it "deducts a percentage per interval late if manually marked late" do
        @assignment.submit_homework(@student, body: "a body")
        submission.late_policy_status = "late"
        submission.seconds_late_override = 4.hours
        submission.score = 700
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 300
        expect(submission.points_deducted).to eq 400
      end

      it "applies missing policy if submission is manually marked missing" do
        Timecop.freeze(1.day.from_now(@date)) do
          submission.score = nil
          submission.late_policy_status = "missing"
          submission.apply_late_policy(@late_policy, @assignment)
          expect(submission.score).to eq 200
        end
      end
    end

    context "when applied late policy deducts 100%" do
      before(:once) do
        @date = Time.zone.local(2017, 1, 15, 12)
        Timecop.travel(@date) do
          Auditors::ActiveRecord::Partitioner.process
        end
        @assignment.update!(due_at: @date - 12.days, points_possible: 1, submission_types: "online_text_entry")
        @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :day)
      end

      it "sets the score to 0 when grade has three decimal points and ending in 5" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 0.555, grader: @teacher)
          expect(submission.score).to eq 0.0
        end
      end
    end

    context "when submitting to an LTI assignment" do
      before(:once) do
        @date = Time.zone.local(2017, 1, 15, 12)
        Timecop.travel(@date) do
          Auditors::ActiveRecord::Partitioner.process
        end
        @assignment.update!(due_at: @date - 3.hours, points_possible: 1_000, submission_types: "external_tool")
        @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :hour, missing: 80.0)
      end

      it "deducts a percentage per interval late if submitted late" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 700, grader: @teacher)
          expect(submission.points_deducted).to eq 300
        end
      end

      it "applies the deduction to the awarded score if submitted late" do
        Timecop.freeze(@date) do
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 700, grader: @teacher)
          expect(submission.score).to eq 400
        end
      end

      it "does not grade missing submissions" do
        Timecop.freeze(@date) do
          submission.apply_late_policy
          expect(submission.score).to be_nil
        end
      end

      it "deducts a percentage per interval late if the submission is manually marked late" do
        @assignment.submit_homework(@student, body: "a body")
        submission.late_policy_status = "late"
        submission.seconds_late_override = 4.hours
        submission.score = 700
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.points_deducted).to eq 400
      end

      it "applies the deduction to the awarded score if the submission is manually marked late" do
        @assignment.submit_homework(@student, body: "a body")
        submission.late_policy_status = "late"
        submission.seconds_late_override = 4.hours
        submission.score = 700
        submission.apply_late_policy(@late_policy, @assignment)
        expect(submission.score).to eq 300
      end

      it "applies the missing policy if the submission is manually marked missing" do
        Timecop.freeze(@date + 1.day) do
          submission.score = nil
          submission.late_policy_status = "missing"
          submission.apply_late_policy(@late_policy, @assignment)
          expect(submission.score).to eq 200
        end
      end
    end

    context "when submitting to a New Quiz LTI assignment" do
      before(:once) do
        @date = Time.zone.local(2017, 1, 15, 12)
        Timecop.travel(@date) do
          Auditors::ActiveRecord::Partitioner.process
        end
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )

        @assignment.quiz_lti!
        @assignment.save!
        @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :hour, missing: 80.0)
      end

      it "does grade missing new quiz submissions" do
        Timecop.freeze(@date) do
          submission.apply_late_policy
          expect(submission.score).to eq 200
        end
      end
    end
  end

  describe "#apply_late_policy_before_save" do
    before(:once) do
      @date = Time.zone.local(2017, 3, 25, 11)
      Timecop.travel(@date) do
        Auditors::ActiveRecord::Partitioner.process
      end
      @assignment.update!(due_at: 4.days.ago(@date), points_possible: 1000, submission_types: "online_text_entry")
      @late_policy = late_policy_factory(course: @course, deduct: 5.0, every: :day, missing: 80.0)
    end

    let(:submission) { @assignment.submissions.find_by(user_id: @student) }

    it "applies the missing policy to the score when changing from excused to missing" do
      @assignment.grade_student(@student, grader: @teacher, excused: true)
      expect { submission.update!(late_policy_status: "missing") }.to change {
        submission.score
      }.from(nil).to(200)
    end

    it "applies the missing policy to the grade when changing from excused to missing" do
      @assignment.grade_student(@student, grader: @teacher, excused: true)
      expect { submission.update!(late_policy_status: "missing") }.to change {
        submission.grade
      }.from(nil).to("200")
    end

    it "applies the late policy when score changes" do
      Timecop.freeze(2.days.ago(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        @assignment.grade_student(@student, grade: 600, grader: @teacher)
        expect(submission.score).to eq 500
        expect(submission.points_deducted).to eq 100
      end
    end

    it "applies the late policy when entered grade is equal to previous penalized grade" do
      Timecop.freeze(2.days.ago(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        @assignment.grade_student(@student, grade: 600, grader: @teacher)

        @assignment.grade_student(@student, grade: 500, grader: @teacher)
        expect(submission.score).to eq 400
      end
    end

    context "custom grade statuses" do
      let(:custom_grade_status) do
        admin = account_admin_user(account: @assignment.root_account)
        @assignment.root_account.custom_grade_statuses.create!(
          name: "Custom Status",
          color: "#ABC",
          created_by: admin
        )
      end

      it "does not apply the late policy when score changes if a custom status is applied" do
        Timecop.freeze(2.days.ago(@date)) do
          @assignment.submit_homework(@student, body: "a body")
          submission.update!(custom_grade_status:)
          expect { @assignment.grade_student(@student, grade: 600, grader: @teacher) }.not_to change {
            submission.reload.points_deducted
          }.from(nil)
        end
      end

      it "applies the late policy for a late submission when a custom status is removed" do
        Timecop.freeze(2.days.ago(@date)) do
          submission.update!(custom_grade_status:)
          @assignment.submit_homework(@student, body: "a body")
          @assignment.grade_student(@student, grade: 600, grader: @teacher)
          expect { submission.update!(custom_grade_status: nil) }.to change {
            submission.reload.points_deducted
          }.from(nil).to(100)
        end
      end

      it "does not apply the missing policy when a custom status is applied" do
        submission.update_columns(score: nil, grade: nil, posted_at: nil, workflow_state: "unsubmitted")
        expect { submission.update!(custom_grade_status:) }.not_to change {
          submission.reload.score
        }.from(nil)
      end
    end

    it "does not apply the late policy when what-if score changes" do
      Timecop.freeze(2.days.ago(@date)) do
        @assignment.submit_homework(@student, body: "a body")
        @assignment.grade_student(@student, grade: 600, grader: @teacher)
      end
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        submission.update!(student_entered_score: 900)
        expect(submission.score).to eq 500
        expect(submission.points_deducted).to eq 100
      end
    end

    it "does not apply the late policy more than once when working with decimals with a scale of more than 2" do
      Timecop.freeze(3.days.ago(@date)) do
        @course.late_policy.update!(late_submission_deduction: 2.35)
        @assignment.submit_homework(@student, body: "a body")
        @assignment.update!(points_possible: 10)
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        SubmissionLifecycleManager.recompute(@assignment, update_grades: true)
        expect(submission.score).to be 9.76
      end
    end

    it "does not change a previous grade when student submits ungraded work" do
      asg = @course.assignments.create!(points_possible: 1000, submission_types: "online_text_entry")
      Timecop.freeze(2.days.ago(@date)) do
        asg.update!(due_at: 4.days.ago(@date))
        ph = asg.submissions.last
        expect(ph.missing?).to be true
        expect(ph.score).to eq 200
        expect(ph.points_deducted).to be_nil
      end
      Timecop.freeze(@date) do
        hw = asg.submit_homework(@student, body: "a body", submission_type: "online_text_entry")
        hw.save!
        expect(hw.late?).to be true
        expect(hw.score).to eq 200
        expect(hw.points_deducted).to be_nil
      end
    end

    it "re-applies the late policy when seconds_late_override changes" do
      Timecop.freeze(@date) do
        @assignment.submit_homework(@student, body: "a body")
        @assignment.grade_student(@student, grade: 800, grader: @teacher)
      end
      submission.update!(seconds_late_override: 3.days, late_policy_status: "late")
      expect(submission.score).to eq 650
      expect(submission.points_deducted).to eq 150
    end
  end

  include_examples "url validation tests"
  it "checks url validity" do
    test_url_validation(submission_spec_model)
  end

  it "adds http:// to the body for long urls, too" do
    s = submission_spec_model(submit_homework: true)
    expect(s.url).to eq "http://www.instructure.com"

    long_url = (("a" * 300) + ".com")
    s.url = long_url
    s.save!
    expect(s.url).to eq "http://#{long_url}"
    # make sure it adds the "http://" to the body for long urls, too
    expect(s.body).to eq "http://#{long_url}"
  end

  it "offers the context, if one is available" do
    @course = Course.new
    @assignment = Assignment.new(context: @course)
    expect(@assignment).to receive(:context).and_return(@course)

    @submission = Submission.new
    expect { @submission.context }.not_to raise_error
    expect(@submission.context).to be_nil
    @submission.assignment = @assignment
    expect(@submission.context).to eql(@course)
  end

  it "has an interesting state machine" do
    submission_spec_model(submit_homework: true)
    expect(@submission.state).to be(:submitted)
    @submission.grade_it
    expect(@submission.state).to be(:graded)
  end

  it "is versioned" do
    submission_spec_model
    expect(@submission).to respond_to(:versions)
  end

  it "does not save new versions by default" do
    submission_spec_model
    expect do
      @submission.save!
    end.not_to change(@submission.versions, :count)
  end

  it "does not create a new version if only the posted_at field is updated" do
    submission_spec_model
    expect do
      @submission.update!(posted_at: Time.zone.now)
    end.not_to change {
      @submission.reload.versions.count
    }
  end

  it "does not update the most recent version if only the posted_at field is updated" do
    submission_spec_model
    expect do
      @submission.update!(posted_at: Time.zone.now)
    end.not_to change {
      @submission.reload.versions.first.model.posted_at
    }
  end

  describe "version indexing" do
    it "creates a SubmissionVersion when a new submission is created" do
      expect do
        submission_spec_model
      end.to change(SubmissionVersion, :count)
    end

    it "creates a SubmissionVersion when a new version is saved" do
      submission_spec_model
      expect do
        @submission.with_versioning(explicit: true) { @submission.save }
      end.to change(SubmissionVersion, :count)
    end

    it "does not fail preload if versionable is nil" do
      submission_spec_model
      version = Version.find_by(versionable: @submission)
      version.update_attribute(:versionable_id, Submission.last.id + 1)
      expect do
        ActiveRecord::Associations.preload([version].map(&:model), :originality_reports)
      end.not_to raise_error
    end
  end

  it "ensures the media object exists" do
    assignment_model
    se = @course.enroll_student(user_factory)
    expect(MediaObject).to receive(:ensure_media_object).with("fake", { context: se.user, user: se.user })
    @submission = @assignment.submit_homework(se.user, media_comment_id: "fake", media_comment_type: "audio")
  end

  describe "#grade_change_audit" do
    before(:once) { Auditors::ActiveRecord::Partitioner.process }

    let_once(:submission) { @assignment.submissions.find_by(user: @student) }

    it "logs submissions with grade changes" do
      expect(Auditors::GradeChange).to receive(:record).once
      submission.update!(grader: @teacher, score: 5)
    end

    it "grade change event author can be set" do
      assistant = User.create!
      @course.enroll_ta(assistant, enrollment_state: "active")

      expect(Auditors::GradeChange).to receive(:record).once do |args|
        expect(args[:submission].grader_id).to eq assistant.id
      end

      submission.grade_change_event_author_id = assistant.id
      submission.update!(score: 5)
    end

    it "uses the existing grader_id as the author if grade_change_event_author_id is not set" do
      @assignment.grade_student(@student, grade: 10, grader: @teacher)

      expect(Auditors::GradeChange).to receive(:record).once do |args|
        expect(args[:submission].grader_id).to eq @teacher.id
      end

      submission.reload.update!(score: 5)
    end

    it "logs excused submissions" do
      expect(Auditors::GradeChange).to receive(:record).once
      submission.update!(excused: true, grader: @user)
    end

    it "logs just one submission affected by assignment update" do
      expect(Auditors::GradeChange).to receive(:record).twice
      # only graded submissions are updated by assignment
      submission.update!(score: 111, workflow_state: "graded")
      @assignment.update!(points_possible: 999)
    end

    it "does not log ungraded submission change when assignment muted" do
      expect(Auditors::GradeChange).not_to receive(:record)
      @assignment.mute!
      @assignment.unmute!
    end

    it "inserts a grade change audit record by default" do
      expect(Auditors::GradeChange).to receive(:record).once
      submission.grade_change_audit(force_audit: true)
    end

    it "does not insert a grade change audit record if grade not changed" do
      expect(Auditors::GradeChange::Stream).not_to receive(:insert)
      submission.grade_change_audit(force_audit: true)
    end

    it "inserts a grade change audit record if grade changed" do
      expect(Auditors::GradeChange::Stream).to receive(:insert)
      submission.score = 11
      submission.save!
    end

    it "emits a grade change live event when force_audit" do
      expect(Canvas::LiveEvents).to receive(:grade_changed).once
      submission.grade_change_audit(force_audit: true)
    end

    it "moves mastery path along on force audit if appropriate" do
      expect(ConditionalRelease::Rule).to receive(:is_trigger_assignment?).with(submission.assignment).once
      submission.update! score: 1, workflow_state: :graded, posted_at: Time.now
      submission.grade_change_audit(force_audit: true)
    end
  end

  context "#graded_anonymously" do
    it "saves when grade changed and set explicitly" do
      submission_spec_model
      expect(@submission.graded_anonymously).to be_falsey
      @submission.score = 42
      @submission.graded_anonymously = true
      @submission.save!
      expect(@submission.graded_anonymously).to be_truthy
      @submission.reload
      expect(@submission.graded_anonymously).to be_truthy
    end

    it "retains its value when grade does not change" do
      submission_spec_model(graded_anonymously: true, score: 3, grade: "3")
      @submission = Submission.find(@submission.id) # need new model object
      expect(@submission.graded_anonymously).to be_truthy
      @submission.body = "test body"
      @submission.save!
      @submission.reload
      expect(@submission.graded_anonymously).to be_truthy
    end

    it "resets when grade changed and not set explicitly" do
      submission_spec_model(graded_anonymously: true, score: 3, grade: "3")
      @submission = Submission.find(@submission.id) # need new model object
      expect(@submission.graded_anonymously).to be_truthy
      @submission.score = 42
      @submission.save!
      @submission.reload
      expect(@submission.graded_anonymously).to be_falsey
    end
  end

  context "Discussion Topic" do
    it "submitted_at does not change when a second discussion entry is created" do
      course_with_student(active_all: true)
      @topic = @course.discussion_topics.create(title: "some topic")
      @assignment = @course.assignments.create(title: "some discussion assignment")
      @assignment.submission_types = "discussion_topic"
      @assignment.save!
      @entry1 = @topic.discussion_entries.create(message: "first entry", user: @user)
      @topic.assignment_id = @assignment.id
      @topic.save!

      Timecop.freeze(30.minutes.from_now) do
        expect do
          @topic.discussion_entries.create(message: "second entry", user: @user)
        end.not_to(change { @assignment.submissions.find_by(user: @user).submitted_at })
      end
    end

    it "does not create multiple versions on submission for discussion topics" do
      course_with_student(active_all: true)
      @topic = @course.discussion_topics.create(title: "some topic")
      @assignment = @course.assignments.create(title: "some discussion assignment")
      @assignment.submission_types = "discussion_topic"
      @assignment.save!
      @topic.assignment_id = @assignment.id
      @topic.save!

      Timecop.freeze(1.second.ago) do
        @assignment.submit_homework(@student, submission_type: "discussion_topic")
      end
      @assignment.submit_homework(@student, submission_type: "discussion_topic")
      expect(@student.submissions.first.submission_history.count).to eq 1
    end
  end

  context "broadcast policy" do
    context "Submission Notifications" do
      before :once do
        Notification.create(name: "Assignment Submitted", category: "TestImmediately")
        Notification.create(name: "Assignment Resubmitted")
        Notification.create(name: "Assignment Submitted Late")
        Notification.create(name: "Group Assignment Submitted Late")

        course_with_teacher(course: @course, active_all: true)
      end

      it "sends the correct message when an assignment is turned in on-time" do
        @assignment.workflow_state = "published"
        @assignment.update(due_at: Time.now + 1000)

        submission_spec_model(user: @student, submit_homework: true)
        expect(@submission.messages_sent.keys).to eq ["Assignment Submitted"]
      end

      it "does not send a message to a TA without grading rights" do
        limited_role = custom_ta_role("limitedta", account: @course.account)
        [:view_all_grades, :manage_grades].each do |permission|
          @course.account.role_overrides.create!(permission:, enabled: false, role: limited_role)
        end

        limited_ta = user_factory(active_all: true, active_cc: true)
        @course.enroll_user(limited_ta, "TaEnrollment", role: limited_role, enrollment_state: "active")
        normal_ta = user_factory(active_all: true, active_cc: true)
        @course.enroll_user(normal_ta, "TaEnrollment", enrollment_state: "active")

        Notification.where(name: "Assignment Submitted").first

        @assignment.workflow_state = "published"
        @assignment.update(due_at: Time.now + 1000)

        submission_spec_model(user: @student, submit_homework: true)

        expect(@submission.messages_sent["Assignment Submitted"].map(&:user)).not_to include(limited_ta)
        expect(@submission.messages_sent["Assignment Submitted"].map(&:user)).to include(normal_ta)
      end

      it "sends the correct message when an assignment is turned in late" do
        @assignment.workflow_state = "published"
        @assignment.update(due_at: Time.now - 1000)

        submission_spec_model(user: @student, submit_homework: true)
        expect(@submission.messages_sent.keys).to eq ["Assignment Submitted Late"]
      end

      it "sends the correct message when an assignment is resubmitted on-time" do
        @assignment.submission_types = ["online_text_entry"]
        @assignment.due_at = Time.now + 1000
        @assignment.save!

        @assignment.submit_homework(@student, body: "lol")
        resubmission = @assignment.submit_homework(@student, body: "frd")
        expect(resubmission.messages_sent.keys).to eq ["Assignment Resubmitted"]
      end

      it "sends the correct message when an assignment is resubmitted late" do
        @assignment.submission_types = ["online_text_entry"]
        @assignment.due_at = Time.now - 1000
        @assignment.save!

        @assignment.submit_homework(@student, body: "lol")
        resubmission = @assignment.submit_homework(@student, body: "frd")
        expect(resubmission.messages_sent.keys).to eq ["Assignment Submitted Late"]
      end

      it "sends the correct message when a group assignment is submitted late" do
        @a = assignment_model(course: @context, group_category: "Study Groups", due_at: Time.now - 1000, submission_types: ["online_text_entry"])
        @group1 = @a.context.groups.create!(name: "Study Group 1", group_category: @a.group_category)
        @group1.add_user(@student)
        submission = @a.submit_homework @student, submission_type: "online_text_entry", body: "blah"

        expect(submission.messages_sent.keys).to eq ["Group Assignment Submitted Late"]
      end

      context "Submission Posted" do
        let(:submission) { @assignment.submissions.find_by!(user: @student) }
        let(:submission_posted_messages) do
          Message.where(
            communication_channel: @student.email_channel,
            notification: @submission_posted_notification
          )
        end

        before(:once) do
          @submission_posted_notification = Notification.find_or_create_by(
            category: "Grading",
            name: "Submission Posted"
          )
          @student.update!(email: "fakeemail@example.com")
          @student.email_channel.update!(workflow_state: :active)
        end

        it "does not send a notification when a submission is not being posted" do
          expect { submission.update!(body: "hello") }.not_to change { submission_posted_messages.count }
        end

        context "when grade_posting_in_progress is true" do
          before do
            submission.grade_posting_in_progress = true
          end

          it "sends a notification when a submission is posted and assignment posts manually" do
            @assignment.ensure_post_policy(post_manually: true)

            expect do
              submission.update!(posted_at: Time.zone.now)
            end.to change {
              submission_posted_messages.count
            }.by(1)
          end

          it "sends a notification when a submission is posted and assignment posts automatically" do
            expect do
              submission.update!(posted_at: Time.zone.now)
            end.to change {
              submission_posted_messages.count
            }.by(1)
          end
        end

        context "when grade_posting_in_progress is false" do
          before do
            submission.grade_posting_in_progress = false
          end

          it "does not send a notification when a submission is posted and assignment posts manually" do
            @assignment.ensure_post_policy(post_manually: true)

            expect do
              submission.update!(posted_at: Time.zone.now)
            end.not_to change {
              submission_posted_messages.count
            }
          end

          it "does not send a notification when a submission is posted and assignment posts automatically" do
            expect do
              submission.update!(posted_at: Time.zone.now)
            end.not_to change {
              submission_posted_messages.count
            }
          end
        end
      end
    end

    context "Submission Graded" do
      before :once do
        Auditors::ActiveRecord::Partitioner.process
        @assignment.ensure_post_policy(post_manually: false)
        Notification.create(name: "Submission Graded", category: "TestImmediately")
        submission_spec_model(submit_homework: true)
      end

      it "updates 'graded_at' on the submission when the late_policy_status is changed" do
        now = Time.zone.now
        Timecop.freeze(1.hour.ago(now)) do
          @submission.update!(late_policy_status: "late")
        end
        Timecop.freeze(now) do
          @submission.update!(late_policy_status: "missing")
        end
        expect(@submission.graded_at).to eq now
      end

      it "creates a message when the assignment has been graded and published" do
        communication_channel(@user, { username: "somewhere@test.com" })
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to be(:published)
        @submission = @assignment.grade_student(@student, grader: @teacher, score: 5).first
        expect(@submission.messages_sent).to include("Submission Graded")
      end

      it "does not create a message for a soft-concluded student" do
        @course.start_at = 2.weeks.ago
        @course.conclude_at = 1.week.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        communication_channel(@user, { username: "somewhere@test.com" })
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to be(:published)
        @submission = @assignment.grade_student(@student, grader: @teacher, score: 5).first
        expect(@submission.messages_sent).to_not include("Submission Graded")
      end

      it "notifies observers" do
        course_with_observer(course: @course, associated_user_id: @user.id, active_all: true, active_cc: true)
        @assignment.grade_student(@student, grader: @teacher, score: 5)
        expect(@observer.email_channel.messages.length).to eq 1
      end

      it "does not create a message when a muted assignment has been graded and published" do
        communication_channel(@user, { username: "somewhere@test.com" })
        @assignment.ensure_post_policy(post_manually: true)
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to be(:published)
        @submission = @assignment.grade_student(@student, grader: @teacher, score: 5).first
        expect(@submission.messages_sent).not_to include "Submission Graded"
      end

      it "does not create a message when this is a quiz submission" do
        communication_channel(@user, { username: "somewhere@test.com" })
        @quiz = Quizzes::Quiz.create!(context: @course)
        @submission.quiz_submission = @quiz.generate_submission(@user)
        @submission.save!
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to be(:published)
        @submission = @assignment.grade_student(@student, grader: @teacher, score: 5).first
        expect(@submission.messages_sent).not_to include("Submission Graded")
      end

      it "creates a hidden stream_item_instance when muted, graded, and published" do
        communication_channel(@user, { username: "somewhere@test.com" })
        @assignment.ensure_post_policy(post_manually: true)
        expect do
          @assignment.grade_student(@user, grade: 10, grader: @teacher).first
        end.to change StreamItemInstance, :count
        expect(@user.stream_item_instances.last).to be_hidden
      end

      it "hides any existing stream_item_instances when grades are hidden" do
        communication_channel(@user, { username: "somewhere@test.com" })
        expect do
          @assignment.grade_student(@student, grader: @teacher, score: 5).first
        end.to change StreamItemInstance, :count
        expect(@user.stream_item_instances.last).not_to be_hidden
        @assignment.hide_submissions
        expect(@user.stream_item_instances.last).to be_hidden
      end

      it "shows hidden stream_item_instances when grades are posted" do
        communication_channel(@user, { username: "somewhere@test.com" })
        @assignment.ensure_post_policy(post_manually: true)
        expect do
          @assignment.update_submission(@student, author: @teacher, comment: "some comment")
        end.to change StreamItemInstance, :count
        expect(@submission.submission_comments.last).to be_hidden
        expect(@user.stream_item_instances.last).to be_hidden
        @assignment.post_submissions
        expect(@submission.submission_comments.last).to_not be_hidden
        expect(@submission.reload.submission_comments_count).to eq 1
        expect(@user.stream_item_instances.last).to_not be_hidden
      end

      it "does not create hidden stream_item_instances for instructors when muted, graded, and published" do
        communication_channel(@teacher, { username: "somewhere@test.com" })
        @assignment.mute!
        expect do
          @submission.add_comment(author: @student, comment: "some comment")
        end.to change StreamItemInstance, :count
        expect(@teacher.stream_item_instances.last).to_not be_hidden
      end

      it "does not hide any existing stream_item_instances for instructors when muted" do
        communication_channel(@teacher, { username: "somewhere@test.com" })
        expect do
          @submission.add_comment(author: @student, comment: "some comment")
        end.to change StreamItemInstance, :count
        expect(@teacher.stream_item_instances.last).to_not be_hidden
        @assignment.mute!
        @teacher.reload
        expect(@teacher.stream_item_instances.last).to_not be_hidden
      end

      it "does not create a message for admins and teachers with quiz submissions" do
        course_with_teacher(active_all: true)
        assignment = @course.assignments.create!(
          title: "assignment",
          points_possible: 10
        )
        quiz = @course.quizzes.build(
          assignment_id: assignment.id,
          title: "test quiz",
          points_possible: 10
        )
        quiz.workflow_state = "available"
        quiz.save!

        user = account_admin_user
        communication_channel(user, { username: "admin@example.com" })
        submission = quiz.generate_submission(user, false)
        Quizzes::SubmissionGrader.new(submission).grade_submission

        communication_channel(@teacher, { username: "chang@example.com" })
        submission2 = quiz.generate_submission(@teacher, false)
        Quizzes::SubmissionGrader.new(submission2).grade_submission

        expect(submission.submission.messages_sent).not_to include("Submission Graded")
        expect(submission2.submission.messages_sent).not_to include("Submission Graded")
      end
    end

    it "creates a stream_item_instance when graded and published" do
      Notification.create name: "Submission Graded"
      submission_spec_model
      communication_channel(@user, { username: "somewhere@test.com" })
      expect do
        @assignment.grade_student(@user, grade: 10, grader: @teacher)
      end.to change StreamItemInstance, :count
    end

    it "creates a stream_item_instance when graded, and then made it visible when unmuted" do
      Notification.create name: "Submission Graded"
      submission_spec_model
      communication_channel(@user, { username: "somewhere@test.com" })
      @assignment.mute!
      expect do
        @assignment.grade_student(@user, grade: 10, grader: @teacher)
      end.to change StreamItemInstance, :count

      @assignment.unmute!
      stream_item_ids       = StreamItem.where(asset_type: "Submission", asset_id: @assignment.submissions.all).pluck(:id)
      stream_item_instances = StreamItemInstance.where(stream_item_id: stream_item_ids)
      stream_item_instances.each { |sii| expect(sii).not_to be_hidden }
    end

    context "Submission Grade Changed" do
      before :once do
        Auditors::ActiveRecord::Partitioner.process
        @assignment.ensure_post_policy(post_manually: false)
      end

      it "creates a message when the score is changed and the grades were already published" do
        Notification.create(name: "Submission Grade Changed")
        allow(@assignment).to receive_messages(score_to_grade: "10.0", due_at: Time.zone.now - 100)
        submission_spec_model

        communication_channel(@user, { username: "somewhere@test.com" })
        s = @assignment.grade_student(@user, grade: 10, grader: @teacher)[0] # @submission
        s.graded_at = Time.zone.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, grade: 9, grader: @teacher)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).to include("Submission Grade Changed")
      end

      it "does not create a grade changed message when theres a quiz attached" do
        Notification.create(name: "Submission Grade Changed")
        allow(@assignment).to receive_messages(score_to_grade: "10.0", due_at: Time.now - 100)
        submission_spec_model

        @quiz = Quizzes::Quiz.create!(context: @course)
        @submission.quiz_submission = @quiz.generate_submission(@user)
        @submission.save!
        communication_channel(@user, { username: "somewhere@test.com" })
        s = @assignment.grade_student(@user, grade: 10, grader: @teacher)[0] # @submission
        s.graded_at = Time.zone.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, grade: 9, grader: @teacher)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to include("Submission Grade Changed")
      end

      it "does not create a message when grades were already published for an assignment with hidden grades" do
        @assignment.ensure_post_policy(post_manually: true)
        Notification.create(name: "Submission Grade Changed")
        allow(@assignment).to receive_messages(score_to_grade: "10.0", due_at: Time.zone.now - 100)
        submission_spec_model

        communication_channel(@user, { username: "somewhere@test.com" })
        s = @assignment.grade_student(@user, grade: 10, grader: @teacher)[0] # @submission
        s.graded_at = Time.zone.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, grade: 9, grader: @teacher)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to include("Submission Grade Changed")
      end

      it "does not create a message when the submission was recently graded" do
        Notification.create(name: "Submission Grade Changed")
        allow(@assignment).to receive_messages(score_to_grade: "10.0", due_at: Time.zone.now - 100)
        submission_spec_model

        communication_channel(@user, { username: "somewhere@test.com" })
        s = @assignment.grade_student(@user, grade: 10, grader: @teacher)[0] # @submission
        @submission = @assignment.grade_student(@user, grade: 9, grader: @teacher)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to include("Submission Grade Changed")
      end
    end
  end

  describe "permission policy" do
    describe "can :grade" do
      before do
        @submission = Submission.new
        @grader = User.new
      end

      it "delegates to can_grade?" do
        [true, false].each do |value|
          allow(@submission).to receive(:can_grade?).with(@grader).and_return(value)

          expect(@submission.grants_right?(@grader, :grade)).to eq(value)
        end
      end
    end

    describe "can :read_grade" do
      before(:once) do
        @course = Course.create!
        @student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
        @assignment = @course.assignments.create!
        @submission = @assignment.submissions.find_by(user: @student)
      end

      it "returns true when their submission is posted and assignment manually posts" do
        @assignment.ensure_post_policy(post_manually: true)
        @submission.update!(posted_at: Time.zone.now)
        expect(@submission.grants_right?(@student, :read_grade)).to be true
      end

      it "returns false when their submission is not posted and assignment manually posts" do
        @assignment.ensure_post_policy(post_manually: true)
        expect(@submission.grants_right?(@student, :read_grade)).to be false
      end

      it "returns true when their submission is posted and assignment automatically posts" do
        @assignment.ensure_post_policy(post_manually: false)
        @submission.update!(posted_at: Time.zone.now)
        expect(@submission.grants_right?(@student, :read_grade)).to be true
      end

      it "returns true when their submission is not posted and assignment automatically posts" do
        @assignment.ensure_post_policy(post_manually: false)
        expect(@submission.grants_right?(@student, :read_grade)).to be true
      end
    end
  end

  describe "computation of scores" do
    before(:once) do
      @assignment.ensure_post_policy(post_manually: false)
      @assignment.update!(points_possible: 10)
      submission_spec_model
    end

    let(:scores) do
      enrollment = Enrollment.where(user_id: @submission.user_id, course_id: @submission.context).first
      enrollment.scores.order(:grading_period_id)
    end

    let(:grading_period_scores) do
      scores.where.not(grading_period_id: nil)
    end

    let(:course_scores) do
      scores.where(course_score: true)
    end

    let(:course_and_grading_period_scores) do
      scores.where(course_score: true).or(scores.where.not(grading_period_id: nil).where(assignment_group_id: nil))
    end

    it "recomputes course scores when the submission score changes" do
      expect { @assignment.grade_student(@student, grader: @teacher, score: 5) }.to change {
        course_scores.pluck(:current_score)
      }.from([nil]).to([50.0])
    end

    context "with grading periods" do
      before(:once) do
        @now = Time.zone.now
        course = @submission.context
        assignment_outside_of_period = course.assignments.create!(
          due_at: 10.days.from_now(@now),
          points_possible: 10
        )
        assignment_outside_of_period.grade_student(@user, grade: 8, grader: @teacher)
        @assignment.update!(due_at: @now)
        @root_account = course.root_account
        group = @root_account.grading_period_groups.create!
        group.enrollment_terms << course.enrollment_term
        @grading_period = group.grading_periods.create!(
          title: "Current Grading Period",
          start_date: 5.days.ago(@now),
          end_date: 5.days.from_now(@now)
        )
      end

      it "updates the course score and grading period score if a submission " \
         "in a grading period is graded" do
        expect { @assignment.grade_student(@student, grader: @teacher, score: 5) }.to change {
          course_and_grading_period_scores.pluck(:current_score)
        }.from([nil, 80.0]).to([50.0, 65.0])
      end

      it "only updates the course score (not the grading period score) if a submission " \
         "not in a grading period is graded" do
        day_after_grading_period_ends = 1.day.from_now(@grading_period.end_date)
        @assignment.update!(due_at: day_after_grading_period_ends)
        expect { @assignment.grade_student(@student, grader: @teacher, score: 5) }.to change {
          course_and_grading_period_scores.pluck(:current_score)
        }.from([nil, 80.0]).to([nil, 65.0])
      end
    end
  end

  describe "#can_grade?" do
    before do
      @account = Account.new
      @course = Course.new(account: @account)
      @assignment = Assignment.new(course: @course)
      @submission = Submission.new(assignment: @assignment)

      @grader = User.new
      @grader.id = 10
      @student = User.new
      @student.id = 42

      allow(@course).to receive(:account_membership_allows).with(@grader).and_return(true)
      allow(@course).to receive(:grants_right?).with(@grader, nil, :manage_grades).and_return(true)

      @assignment.course = @course
      allow(@assignment).to receive(:published?).and_return(true)
      grading_period = double("grading_period", closed?: false)
      allow(@submission).to receive(:grading_period).and_return(grading_period)

      @submission.grader = @grader
      @submission.user = @student
    end

    it 'returns true for published assignments if the grader is a teacher who is allowed to
        manage grades' do
      expect(@submission.grants_right?(@grader, :grade)).to be_truthy
    end

    context "when assignment is unpublished" do
      before do
        allow(@assignment).to receive(:published?).and_return(false)

        @status = @submission.grants_right?(@grader, :grade)
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("unpublished")
      end
    end

    context "when the grader does not have the right to manage grades for the course" do
      before do
        allow(@course).to receive(:grants_right?).with(@grader, nil, :manage_grades).and_return(false)

        @status = @submission.grants_right?(@grader, :grade)
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("manage grades")
      end
    end

    context "when the grader is a teacher and the assignment is in a closed grading period" do
      before do
        allow(@course).to receive(:account_membership_allows).with(@grader).and_return(false)
        grading_period = double("grading_period", closed?: true)
        allow(@submission).to receive(:grading_period).and_return(grading_period)

        @status = @submission.grants_right?(@grader, :grade)
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("closed grading period")
      end
    end

    context "when grader_id is a teacher's id and the assignment is in a closed grading period" do
      before do
        allow(@course).to receive(:account_membership_allows).with(@grader).and_return(false)
        grading_period = double("grading_period", closed?: true)
        allow(@submission).to receive(:grading_period).and_return(grading_period)
        @submission.grader = nil
        @submission.grader_id = 10

        @status = @submission.grants_right?(@grader, :grade)
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("closed grading period")
      end
    end

    it 'returns true if the grader is an admin even if the assignment is in
        a closed grading period' do
      allow(@course).to receive(:account_membership_allows).with(@grader).and_return(true)
      grading_period = double("grading_period", closed?: false)
      allow(@submission).to receive(:grading_period).and_return(grading_period)

      expect(@submission.grants_right?(@grader, :grade)).to be_truthy
    end
  end

  describe "#can_autograde?" do
    before do
      @account = Account.new
      @course = Course.new(account: @account)
      @assignment = Assignment.new(course: @course)
      @submission = Submission.new(assignment: @assignment)

      @submission.grader_id = -1
      @submission.user_id = 10

      allow(@assignment).to receive(:published?).and_return(true)
      grading_period = double("grading_period", closed?: false)
      allow(@submission).to receive(:grading_period).and_return(grading_period)
    end

    it 'returns true for published assignments with an autograder and when the assignment is not
        in a closed grading period' do
      expect(@submission.can_autograde?).to be_truthy
    end

    context "when assignment is unpublished" do
      before do
        allow(@assignment).to receive(:published?).and_return(false)

        @status = @submission.can_autograde?
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("unpublished")
      end
    end

    context "when the grader is not an autograder" do
      before do
        @submission.grader_id = 1

        @status = @submission.can_autograde?
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("autograded")
      end
    end

    context "when the assignment is in a closed grading period for the student" do
      before do
        grading_period = double("grading_period", closed?: true)
        allow(@submission).to receive(:grading_period).and_return(grading_period)

        @status = @submission.can_autograde?
      end

      it "returns false" do
        expect(@status).to be_falsey
      end

      it "sets an appropriate error message" do
        expect(@submission.grading_error_message).to include("closed grading period")
      end
    end
  end

  describe "#can_read_submission_user_name?" do
    before(:once) do
      @course = Course.create!
      @student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
      assignment = @course.assignments.create!(anonymous_grading: true)
      @submission = assignment.submissions.find_by(user: @student)
    end

    context "anonymous assignments" do
      it "returns true when the user is the submission's owner" do
        expect(@submission.can_read_submission_user_name?(@student, nil)).to be true
      end

      it "returns false when the user is not the submission's owner" do
        teacher = User.create!
        @course.enroll_teacher(teacher, enrollment_state: :active)
        expect(@submission.can_read_submission_user_name?(@teacher, nil)).to be false
      end
    end
  end

  describe "#user_can_read_grade?" do
    before(:once) do
      @course = Course.create!
      @student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
      @assignment = @course.assignments.create!
      @submission = @assignment.submissions.find_by(user: @student)
    end

    it "returns true when their submission is posted and assignment manually posts" do
      @assignment.ensure_post_policy(post_manually: true)
      @submission.update!(posted_at: Time.zone.now)
      expect(@submission.user_can_read_grade?(@student)).to be true
    end

    it "returns false when their submission is not posted and assignment manually posts" do
      @assignment.ensure_post_policy(post_manually: true)
      expect(@submission.user_can_read_grade?(@student)).to be false
    end

    it "returns true when their submission is posted and assignment automatically posts" do
      @assignment.ensure_post_policy(post_manually: false)
      @submission.update!(posted_at: Time.zone.now)
      expect(@submission.user_can_read_grade?(@student)).to be true
    end

    it "returns true when their submission is not posted and assignment automatically posts" do
      @assignment.ensure_post_policy(post_manually: false)
      expect(@submission.user_can_read_grade?(@student)).to be true
    end
  end

  context "OriginalityReport" do
    let(:attachment) { attachment_model(context: group) }
    let(:course) { course_model }
    let(:submission) { submission_model }
    let(:group) { Group.create!(name: "test group", context: course) }

    let(:originality_report) do
      submission.update(attachment_ids: attachment.id.to_s)
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)
    end

    describe "#originality_data" do
      it "generates the originality data" do
        originality_report.originality_report_url = "http://example.com"
        originality_report.save!
        expect(submission.originality_data).to eq(
          {
            attachment.asset_string => {
              similarity_score: originality_report.originality_score,
              state: originality_report.state,
              attachment_id: originality_report.attachment_id,
              report_url: originality_report.originality_report_url,
              status: originality_report.workflow_state,
              error_message: nil,
              created_at: originality_report.created_at,
              updated_at: originality_report.updated_at
            }
          }
        )
      end

      context "multiple originality reports for the same attachment" do
        let(:preferred_report) do
          OriginalityReport.create!(attachment:,
                                    submission:,
                                    workflow_state: preferred_state,
                                    originality_score: (preferred_state == "scored") ? 1 : nil)
        end
        let(:other_report) do
          OriginalityReport.create!(attachment:,
                                    submission:,
                                    workflow_state: other_state,
                                    originality_score: (other_state == "scored") ? 2 : nil)
        end

        before do
          submission.update(attachment_ids: attachment.id.to_s)
        end

        OriginalityReport::ORDERED_VALID_WORKFLOW_STATES.each do |state|
          context "and both reports have a workflow_state of #{state}" do
            let(:preferred_state) { state }
            let(:other_state) { state }

            it "chooses the more up-to-date report" do
              preferred_report.update!(updated_at: 1.minute.from_now)
              other_report.update!(updated_at: Time.zone.now)
              report_data = submission.originality_data[attachment.asset_string]
              expect(report_data[:similarity_score]).to eq preferred_report.originality_score
            end
          end
        end

        shared_examples_for "submission with duplicate reports with different states" do
          it "uses the preferred report" do
            preferred_report
            other_report
            report_data = submission.originality_data[attachment.asset_string]
            expect(report_data[:similarity_score]).to eq preferred_report.originality_score
            expect(report_data[:status]).to eq preferred_report.workflow_state
          end

          it "uses the preferred report even if the other report was updated later" do
            preferred_report.update(updated_at: Time.zone.now)
            other_report.update(updated_at: 1.minute.from_now)

            report_data = submission.originality_data[attachment.asset_string]
            expect(report_data[:similarity_score]).to eq preferred_report.originality_score
            expect(report_data[:status]).to eq preferred_report.workflow_state
          end
        end

        context "and the reports have differing workflow_states" do
          context "of scored and error" do
            let(:preferred_state) { "scored" }
            let(:other_state) { "error" }

            it_behaves_like "submission with duplicate reports with different states"
          end

          context "of scored and pending" do
            let(:preferred_state) { "scored" }
            let(:other_state) { "pending" }

            it_behaves_like "submission with duplicate reports with different states"
          end

          context "of error and pending" do
            let(:preferred_state) { "error" }
            let(:other_state) { "pending" }

            it_behaves_like "submission with duplicate reports with different states"
          end
        end
      end

      it "includes tii data" do
        tii_data = {
          similarity_score: 10,
          state: "acceptable",
          report_url: "http://example.com",
          status: "scored"
        }
        submission.turnitin_data[attachment.asset_string] = tii_data
        expect(submission.originality_data).to eq({
                                                    attachment.asset_string => tii_data
                                                  })
      end

      it "overrites the tii data with the originality data" do
        originality_report.originality_report_url = "http://example.com"
        originality_report.save!
        tii_data = {
          similarity_score: 10,
          state: "acceptable",
          report_url: "http://example.com/tii",
          status: "pending"
        }
        submission.turnitin_data[attachment.asset_string] = tii_data
        expect(submission.originality_data).to eq(
          {
            attachment.asset_string => {
              similarity_score: originality_report.originality_score,
              attachment_id: attachment.id,
              state: originality_report.state,
              report_url: originality_report.originality_report_url,
              status: originality_report.workflow_state,
              error_message: nil,
              created_at: originality_report.created_at,
              updated_at: originality_report.updated_at
            }
          }
        )
      end

      it "does not cause error if originality score is nil" do
        originality_report.update(originality_score: nil)
        expect { submission.originality_data }.not_to raise_error
      end

      it "rounds the score to 2 decimal places" do
        originality_report.originality_score = 2.94997
        originality_report.save!
        expect(submission.originality_data[attachment.asset_string][:similarity_score]).to eq(2.95)
      end

      it "filters out :provider key and value" do
        originality_report.originality_report_url = "http://example.com"
        originality_report.save!
        tii_data = {
          provider: "vericite",
          similarity_score: 10,
          state: "acceptable",
          report_url: "http://example.com/tii",
          status: "pending"
        }
        submission.turnitin_data[attachment.asset_string] = tii_data
        expect(submission.originality_data).not_to include :vericite
      end

      it "finds originality data text entry submissions" do
        submission.update!(attachment_ids: attachment.id.to_s)
        originality_report.update!(attachment: nil)
        expect(submission.originality_data).to eq({
                                                    OriginalityReport.submission_asset_key(submission) => {
                                                      similarity_score: originality_report.originality_score,
                                                      attachment_id: nil,
                                                      state: originality_report.state,
                                                      report_url: originality_report.originality_report_url,
                                                      status: originality_report.workflow_state,
                                                      error_message: nil,
                                                      created_at: originality_report.created_at,
                                                      updated_at: originality_report.updated_at,
                                                    }
                                                  })
      end

      context "when originality report has an error message" do
        subject { submission.originality_data[attachment.asset_string] }

        let(:error_message) { "We can't process that file :(" }

        before { originality_report.update!(error_message:) }

        it "includes the error message" do
          expect(subject[:error_message]).to eq error_message
        end
      end
    end

    describe "#attachment_ids_for_version" do
      let(:attachments) do
        [
          attachment_model(filename: "submission-a.doc", context: @student),
          attachment_model(filename: "submission-b.doc", context: @student),
          attachment_model(filename: "submission-c.doc", context: @student)
        ]
      end
      let(:single_attachment) { attachment_model(filename: "single.doc", context: @student) }

      before { student_in_course(active_all: true) }

      it "includes attachment ids from 'attachment_id'" do
        submission = @assignment.submit_homework(@student, submission_type: "online_upload", attachments:)
        submission.update!(attachment_id: single_attachment)
        expect(submission.attachment_ids_for_version).to match_array attachments.map(&:id) + [single_attachment.id]
      end
    end

    describe "#has_originality_report?" do
      let(:test_course) do
        test_course = course_model
        test_course.enroll_teacher(test_teacher, enrollment_state: "active")
        test_course.enroll_student(test_student, enrollment_state: "active")
        test_course
      end
      let(:test_teacher) { User.create }
      let(:test_student) { User.create }
      let(:assignment) { Assignment.create!(title: "test assignment", context: test_course) }
      let(:attachment) { attachment_model(filename: "submission.doc", context: test_student) }
      let(:report_url) { "http://www.test-score.com" }

      it "returns true for standard reports" do
        submission = assignment.submit_homework(test_student, attachments: [attachment])
        OriginalityReport.create!(
          attachment:,
          submission:,
          originality_score: 0.5,
          originality_report_url: report_url
        )
        expect(submission.has_originality_report?).to be true
      end

      it "returns true for text entry reports" do
        submission = assignment.submit_homework(test_student, body: "hi")
        OriginalityReport.create!(
          submission:,
          originality_score: 0.5,
          originality_report_url: report_url
        )
        expect(submission.has_originality_report?).to be true
      end

      it "returns true for group reports" do
        user_two = test_student.dup
        user_two.update!(lti_context_id: SecureRandom.uuid, lti_id: SecureRandom.uuid, uuid: CanvasSlug.generate_securish_uuid)
        assignment.course.enroll_student(user_two)

        group = group_model(context: assignment.course)
        group.update!(users: [user_two, test_student])

        submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
        submission_two = assignment.submit_homework(user_two, submission_type: "online_upload", attachments: [attachment])

        submission.update!(group:)
        submission_two.update!(group:)

        assignment.submissions.each do |s|
          s.update!(group:, turnitin_data: { blah: 1 })
        end

        report = OriginalityReport.create!(originality_score: "1", submission:, attachment:)
        report.copy_to_group_submissions!

        expect(assignment.submissions.map(&:has_originality_report?)).to match_array [true, true]
      end

      it "returns false when no reports are present" do
        submission = assignment.submit_homework(test_student, attachments: [attachment])
        expect(submission.has_originality_report?).to be false
      end
    end

    describe "#originality_report_url" do
      let_once(:test_course) do
        test_course = course_model
        test_course.enroll_teacher(test_teacher, enrollment_state: "active")
        test_course.enroll_student(test_student, enrollment_state: "active")
        test_course
      end

      let_once(:test_teacher) { User.create }
      let_once(:test_student) { User.create }
      let_once(:assignment) { Assignment.create!(title: "test assignment", context: test_course) }
      let_once(:attachment) { attachment_model(filename: "submission.doc", context: test_student) }
      let_once(:submission) { assignment.submit_homework(test_student, attachments: [attachment]) }
      let_once(:report_url) { "http://www.test-score.com" }
      let(:originality_report) do
        OriginalityReport.create!(attachment:,
                                  submission:,
                                  originality_score: 0.5,
                                  originality_report_url: report_url)
      end

      it "returns nil if no originality report exists for the submission" do
        originality_report.destroy
        expect(submission.originality_report_url(attachment.asset_string, test_teacher)).to be_nil
      end

      it "returns nil if no report url is present in the report" do
        originality_report.update_attribute(:originality_report_url, nil)
        expect(submission.originality_report_url(attachment.asset_string, test_teacher)).to be_nil
      end

      it "returns the originality_report_url if present" do
        originality_report
        expect(submission.originality_report_url(attachment.asset_string, test_teacher)).to eq(report_url)
      end

      it "returns the report url for text entry submission reports" do
        originality_report.update!(attachment: nil)
        expect(submission.originality_report_url(submission.asset_string, test_teacher)).to eq report_url
      end

      it "requires the :grade permission" do
        unauthorized_user = User.new
        expect(submission.originality_report_url(attachment.asset_string, unauthorized_user)).to be_nil
      end

      context "when there are multiple originality reports" do
        context "for text entry submissions" do
          let(:other_submission) { assignment.submit_homework(test_student, body: "hello world") }
          let(:other_report_url) { "https://another-report.com" }
          let(:other_report) do
            OriginalityReport.create!(attachment: nil,
                                      submission: other_submission,
                                      originality_score: 0.4,
                                      originality_report_url: other_report_url)
          end

          it "can use attempt number to find the report url" do
            originality_report.update!(attachment: nil)
            other_report

            expect(other_submission.attempt).to be > submission.attempt
            expect(submission.originality_report_url(submission.asset_string,
                                                     test_teacher,
                                                     submission.attempt.to_s)).to eq report_url
            expect(submission.originality_report_url(submission.asset_string,
                                                     test_teacher,
                                                     other_submission.attempt.to_s)).to eq(other_report_url)
          end
        end

        context "for multiple attachments" do
          let(:other_attachment) { attachment_model(filename: "submission-b.doc", context: test_student) }
          let(:other_report_url) { "http://another-report.com" }
          let(:other_report) do
            OriginalityReport.create!(attachment: other_attachment,
                                      submission:,
                                      originality_score: 0.4,
                                      originality_report_url: other_report_url)
          end

          it "considers all attachments in submission history valid" do
            Timecop.freeze(2.days.ago) do
              assignment.submit_homework(test_student,
                                         submission_type: "online_upload",
                                         attachments: [attachment])
            end

            Timecop.freeze(1.day.ago) do
              assignment.submit_homework(test_student,
                                         submission_type: "online_upload",
                                         attachments: [other_attachment])
            end

            originality_report
            other_report
            expect(submission.originality_report_url(attachment.asset_string, test_teacher))
              .to eq(report_url)
            expect(submission.originality_report_url(other_attachment.asset_string, test_teacher))
              .to eq(other_report_url)
          end

          it "gives the correct url for each attachment" do
            assignment.submit_homework(test_student,
                                       submission_type: "online_upload",
                                       attachments: [attachment, other_attachment])
            originality_report
            other_report
            expect(submission.originality_report_url(attachment.asset_string, test_teacher))
              .to eq(report_url)
            expect(submission.originality_report_url(other_attachment.asset_string, test_teacher))
              .to eq(other_report_url)
          end

          # This combines having multiple attachments with some duplicate OriginalityReports.
          context "with some duplicate reports for an attachment" do
            let(:duplicate_url) { "http://duplicate.com" }
            let(:duplicate_report) do
              OriginalityReport.create!(attachment:,
                                        submission:,
                                        workflow_state: "pending",
                                        originality_report_url: duplicate_url)
            end

            before do
              assignment.submit_homework(test_student,
                                         submission_type: "online_upload",
                                         attachments: [attachment, other_attachment])
            end

            it "uses the scored report's URL" do
              originality_report
              other_report
              duplicate_report
              expect(submission.originality_report_url(attachment.asset_string, test_teacher))
                .to eq(report_url)
            end

            it "uses the scored report's URL even if the other report is newer" do
              originality_report.update(updated_at: 1.day.ago)
              other_report
              duplicate_report.update(updated_at: 1.day.from_now)

              expect(submission.originality_report_url(attachment.asset_string, test_teacher))
                .to eq(report_url)
            end

            it "can still get other attachment's URLs" do
              originality_report
              other_report
              duplicate_report

              expect(submission.originality_report_url(other_attachment.asset_string, test_teacher))
                .to eq(other_report_url)
            end
          end
        end

        # If we have multiple reports for the same attachment-submission combo, then
        # those reports are considered duplicates. However, they might have different states
        # so we have to be sure we're using the correct report.
        context "and the reports are for the same attachment" do
          let(:preferred_url) { "http://preferred-score.com" }
          let(:other_url) { "http://other-score.com" }
          let(:preferred_report) do
            OriginalityReport.create!(attachment:,
                                      submission:,
                                      originality_score: (preferred_state == "scored") ? 1 : nil,
                                      workflow_state: preferred_state,
                                      originality_report_url: preferred_url)
          end
          let(:other_report) do
            OriginalityReport.create!(attachment:,
                                      submission:,
                                      originality_score: (other_state == "scored") ? 2 : nil,
                                      workflow_state: other_state,
                                      originality_report_url: other_url)
          end

          before do
            submission.update(attachment_ids: attachment.id.to_s)
          end

          OriginalityReport::ORDERED_VALID_WORKFLOW_STATES.each do |state|
            context "and have the same workflow_state of #{state}" do
              let(:preferred_state) { state }
              let(:other_state) { state }

              it "chooses the more up-to-date report's URL" do
                preferred_report.update(updated_at: 1.minute.from_now)
                other_report.update(updated_at: Time.zone.now)
                expect(submission.originality_report_url(attachment.asset_string,
                                                         test_teacher)).to eq preferred_url
              end
            end
          end

          shared_examples_for "submission with duplicate reports with different states" do
            it "chooses the preferred report's URL" do
              preferred_report
              other_report
              expect(submission.originality_report_url(attachment.asset_string,
                                                       test_teacher)).to eq preferred_url
            end

            it "chooses the preferred report's URL even when the other report is newer" do
              preferred_report.update(updated_at: Time.zone.now)
              other_report.update(updated_at: 1.minute.from_now)
              expect(submission.originality_report_url(attachment.asset_string,
                                                       test_teacher)).to eq preferred_url
            end
          end

          context "and the reports have differing workflow_states" do
            context "of scored and error" do
              let(:preferred_state) { "scored" }
              let(:other_state) { "error" }

              it_behaves_like "submission with duplicate reports with different states"
            end

            context "of scored and pending" do
              let(:preferred_state) { "scored" }
              let(:other_state) { "pending" }

              it_behaves_like "submission with duplicate reports with different states"
            end

            context "of error and pending" do
              let(:preferred_state) { "error" }
              let(:other_state) { "pending" }

              it_behaves_like "submission with duplicate reports with different states"
            end
          end
        end
      end
    end
  end

  context "turnitin" do
    context "Turnitin LTI" do
      let(:lti_tii_data) do
        {
          "attachment_42" => {
            status: "error",
            outcome_response: {
              "outcomes_tool_placement_url" => "https://api.turnitin.com/api/lti/1p0/invalid?lang=en_us",
              "paperid" => "607954245",
              "lis_result_sourcedid" => "10-5-42-8-invalid"
            },
            public_error_message: "Turnitin has not returned a score after 11 attempts to retrieve one."
          }
        }
      end

      let(:submission) { Submission.new }

      describe "#turnitinable_by_lti?" do
        it "returns true if there is an associated lti tool and data stored" do
          submission.turnitin_data = lti_tii_data
          expect(submission.turnitinable_by_lti?).to be true
        end
      end

      describe "#resubmit_lti_tii" do
        let(:tool) do
          @course.context_external_tools.create(
            name: "a",
            consumer_key: "12345",
            shared_secret: "secret",
            url: "http://example.com/launch"
          )
        end

        it "resubmits errored tii attachments" do
          a = @course.assignments.create!(title: "test",
                                          submission_types: "external_tool",
                                          external_tool_tag_attributes: { url: tool.url })
          submission.assignment = a
          submission.turnitin_data = lti_tii_data
          submission.user = @user
          outcome_response_processor_mock = double("outcome_response_processor")
          expect(outcome_response_processor_mock).to receive(:resubmit).with(submission, "attachment_42")
          allow(Turnitin::OutcomeResponseProcessor).to receive(:new).and_return(outcome_response_processor_mock)
          submission.retrieve_lti_tii_score
        end

        it "resubmits errored tii attachments even if turnitin_data has non-hash values" do
          a = @course.assignments.create!(title: "test",
                                          submission_types: "external_tool",
                                          external_tool_tag_attributes: { url: tool.url })
          submission.assignment = a
          submission.turnitin_data = lti_tii_data.merge(last_processed_attempt: 1)
          submission.user = @user
          outcome_response_processor_mock = double("outcome_response_processor")
          expect(outcome_response_processor_mock).to receive(:resubmit).with(submission, "attachment_42")
          allow(Turnitin::OutcomeResponseProcessor).to receive(:new).and_return(outcome_response_processor_mock)
          submission.retrieve_lti_tii_score
        end
      end
    end

    context "submission" do
      def init_turnitin_api
        @turnitin_api = Turnitin::Client.new("test_account", "sekret")
        expect(@submission.context).to receive(:turnitin_settings).at_least(1).and_return([:placeholder])
        expect(Turnitin::Client).to receive(:new).at_least(1).with(:placeholder).and_return(@turnitin_api)
      end

      before(:once) do
        setup_account_for_turnitin(@assignment.context.account)
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { body: "hello there", submission_type: "online_text_entry" })
      end

      it "submits to turnitin after a delay" do
        job = Delayed::Job.list_jobs(:future, 100).find { |j| j.tag == "Submission#submit_to_turnitin" }
        expect(job).not_to be_nil
        expect(job.run_at).to be > Time.now.utc
      end

      it "initially sets turnitin submission to pending" do
        init_turnitin_api
        expect(@turnitin_api).to receive(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).and_return({ assignment_id: "1234" })
        expect(@turnitin_api).to receive(:enrollStudent).with(@context, @user).and_return(double(success?: true))
        expect(@turnitin_api).to receive(:submitPaper).and_return({
                                                                    @submission.asset_string => {
                                                                      object_id: "12345"
                                                                    }
                                                                  })
        @submission.submit_to_turnitin
        expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq "pending"
      end

      it "schedules a retry if something fails initially" do
        init_turnitin_api
        expect(@turnitin_api).to receive(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).and_return({ assignment_id: "1234" })
        expect(@turnitin_api).to receive(:enrollStudent).with(@context, @user).and_return(double(success?: false))
        @submission.submit_to_turnitin
        expect(Delayed::Job.list_jobs(:future, 100).count { |j| j.tag == "Submission#submit_to_turnitin" }).to eq 2
      end

      it "sets status as failed if something fails on a retry" do
        init_turnitin_api
        expect(@assignment).to receive(:create_in_turnitin).and_return(false)
        expect(@turnitin_api).to receive(:enrollStudent).with(@context, @user).and_return(double(success?: false, error?: true, error_hash: {}))
        expect(@turnitin_api).not_to receive(:submitPaper)
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        expect(@submission.reload.turnitin_data[:status]).to eq "error"
      end

      it "sets status back to pending on retry" do
        init_turnitin_api
        # first a submission, to get us into failed state
        expect(@assignment).to receive(:create_in_turnitin).and_return(false)
        expect(@turnitin_api).to receive(:enrollStudent).with(@context, @user).and_return(double(success?: false, error?: true, error_hash: {}))
        expect(@turnitin_api).not_to receive(:submitPaper)
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        expect(@submission.reload.turnitin_data[:status]).to eq "error"

        # resubmit
        @submission.resubmit_to_turnitin
        expect(@submission.reload.turnitin_data[:status]).to be_nil
        expect(@submission.turnitin_data[@submission.asset_string][:status]).to eq "pending"
      end

      it "sets status to scored on success" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { object_id: "1234", status: "pending" }
        expect(@turnitin_api).to receive(:generateReport).with(@submission, @submission.asset_string).and_return({
                                                                                                                   similarity_score: 56,
                                                                                                                   web_overlap: 22,
                                                                                                                   publication_overlap: 0,
                                                                                                                   student_overlap: 33
                                                                                                                 })

        @submission.check_turnitin_status
        expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq "scored"
      end

      it "sets status as failed if something fails after several attempts" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { object_id: "1234", status: "pending" }
        expect(@turnitin_api).to receive(:generateReport).with(@submission, @submission.asset_string).and_return({})

        expects_job_with_tag("Submission#check_turnitin_status") do
          @submission.check_turnitin_status(Submission::TURNITIN_STATUS_RETRY - 1)
          expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq "pending"
        end

        @submission.check_turnitin_status(Submission::TURNITIN_STATUS_RETRY)
        @submission.reload
        updated_data = @submission.turnitin_data[@submission.asset_string]
        expect(updated_data[:status]).to eq "error"
      end

      it "checks status for all assets" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { object_id: "1234", status: "pending" }
        @submission.turnitin_data["other_asset"] = { object_id: "xxyy", status: "pending" }
        expect(@turnitin_api).to receive(:generateReport).with(@submission, @submission.asset_string).and_return({
                                                                                                                   similarity_score: 56, web_overlap: 22, publication_overlap: 0, student_overlap: 33
                                                                                                                 })
        expect(@turnitin_api).to receive(:generateReport).with(@submission, "other_asset").and_return({ similarity_score: 20 })

        @submission.check_turnitin_status
        @submission.reload
        expect(@submission.turnitin_data[@submission.asset_string][:status]).to eq "scored"
        expect(@submission.turnitin_data["other_asset"][:status]).to eq "scored"
      end

      it "does not blow up if submission_type has changed when job runs" do
        @submission.submission_type = "online_url"
        expect(@submission.context).not_to receive(:turnitin_settings)
        expect { @submission.submit_to_turnitin }.not_to raise_error
      end
    end

    describe "group" do
      before(:once) do
        @teacher = User.create(name: "some teacher")
        @student = User.create(name: "a student")
        @student1 = User.create(name: "student 1")
        @context.enroll_teacher(@teacher)
        @context.enroll_student(@student)
        @context.enroll_student(@student1)
        setup_account_for_turnitin(@context.account)

        @a = assignment_model(course: @context, group_category: "Study Groups")
        @a.submission_types = "online_upload,online_text_entry"
        @a.turnitin_enabled = true
        @a.save!

        @group1 = @a.context.groups.create!(name: "Study Group 1", group_category: @a.group_category)
        @group1.add_user(@student)
        @group1.add_user(@student1)
      end

      it "submits to turnitin for the original submitter" do
        submission = @a.submit_homework @student, submission_type: "online_text_entry", body: "blah"
        Submission.where(assignment_id: @a).each do |s|
          if s.id == submission.id
            expect(s.turnitin_data[:last_processed_attempt]).to be > 0
          else
            expect(s.turnitin_data).to eq({})
          end
        end
      end
    end

    context "report" do
      before :once do
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.turnitin_settings = @assignment.turnitin_settings # rubocop:disable Lint/SelfAssignment
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { body: "hello there", submission_type: "online_text_entry" })
        @submission.turnitin_data = {
          "submission_#{@submission.id}" => {
            web_overlap: 92,
            error: true,
            publication_overlap: 0,
            state: "failure",
            object_id: "123456789",
            student_overlap: 90,
            similarity_score: 92
          }
        }
        @submission.save!
      end

      before do
        api = Turnitin::Client.new("test_account", "sekret")
        expect(Turnitin::Client).to receive(:new).at_least(1).and_return(api)
        expect(api).to receive(:sendRequest).with(:generate_report, 1, include(oid: "123456789")).at_least(1).and_return("http://foo.bar")
      end

      it "lets teachers view the turnitin report" do
        @teacher = User.create
        @context.enroll_teacher(@teacher)
        expect(@submission).to be_grants_right(@teacher, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @teacher)).not_to be_nil
      end

      it "lets students view the turnitin report after grading" do
        @assignment.turnitin_settings[:originality_report_visibility] = "after_grading"
        @assignment.save!
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @submission.score = 1
        @submission.grade_it!
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end

      it "lets students view the turnitin report immediately if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = "after_grading"
        @assignment.save
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @assignment.turnitin_settings[:originality_report_visibility] = "immediate"
        @assignment.save
        @submission.reload
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end

      it "lets students view the turnitin report after the due date if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = "after_due_date"
        @assignment.due_at = Time.now + 1.day
        @assignment.save
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @assignment.due_at = Time.now - 1.day
        @assignment.save
        @submission.reload
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end
    end
  end

  describe "'view_turnitin_report' right" do
    subject { @submission }

    let(:teacher) { @teacher }
    let(:student) { @student }

    before :once do
      @assignment.update!(submission_types: "online_upload,online_text_entry")
      @submission = @assignment.submit_homework(student, { body: "hello there", submission_type: "online_text_entry" })
      @submission.update!(turnitin_data: {
                            "submission_#{@submission.id}" => {
                              web_overlap: 92,
                              error: true,
                              publication_overlap: 0,
                              state: "failure",
                              object_id: "123456789",
                              student_overlap: 90,
                              similarity_score: 92
                            }
                          })
    end

    it "is available when the plagiarism report is from turnitin" do
      expect(@submission).to be_grants_right(teacher, nil, :view_turnitin_report)
    end

    it "is available when the plagiarism report is blank (defaults to turnitin)" do
      @submission.turnitin_data.delete(:provider)
      expect(@submission).to be_grants_right(teacher, nil, :view_turnitin_report)
    end

    it "is not available when the plagiarism report is from vericite" do
      @submission.turnitin_data[:provider] = "vericite"
      expect(@submission).not_to be_grants_right(teacher, nil, :view_turnitin_report)
    end

    it "is available when the plagiarism data shows vericite and there is an LTI 2 assignment configuration for something else" do
      @submission.turnitin_data[:provider] = "vericite"
      AssignmentConfigurationToolLookup.create!(
        assignment: @assignment,
        tool_product_code: "turnitin-lti",
        tool_type: "Lti::MessageHandler",
        context_type: "Account",
        tool_resource_type_code: "code",
        tool_vendor_code: "turnitin.com"
      )
      expect(@submission).to be_grants_right(teacher, nil, :view_turnitin_report)
    end

    it "is not available when the plagiarism data shows vericite and there is an LTI 2 assignment configuration for vericite" do
      @submission.turnitin_data[:provider] = "vericite"
      AssignmentConfigurationToolLookup.create!(
        assignment: @assignment,
        tool_product_code: "vericite",
        tool_type: "Lti::MessageHandler",
        context_type: "Account",
        tool_resource_type_code: "code",
        tool_vendor_code: "vericite"
      )
      expect(@submission).not_to be_grants_right(teacher, nil, :view_turnitin_report)
    end

    it { expect(@submission).to be_grants_right(student, nil, :view_turnitin_report) }

    context "when originality report visibility is after_grading" do
      before do
        @assignment.update!(
          turnitin_settings: @assignment.turnitin_settings.merge(originality_report_visibility: "after_grading")
        )
      end

      it { is_expected.not_to be_grants_right(student, nil, :view_turnitin_report) }

      context "when the submission is graded" do
        subject(:submission) { @assignment.grade_student(student, grade: 10, grader: teacher).first }

        it { is_expected.to be_grants_right(student, nil, :view_turnitin_report) }
      end
    end

    context "when originality report visibility is after_due_date" do
      before do
        @assignment.update!(
          turnitin_settings: @assignment.turnitin_settings.merge(originality_report_visibility: "after_due_date")
        )
      end

      it { is_expected.not_to be_grants_right(student, nil, :view_turnitin_report) }

      context "when assignment.due_date is in the past" do
        before { @assignment.update!(due_at: 1.day.ago) }

        it { is_expected.to be_grants_right(student, nil, :view_turnitin_report) }
      end
    end

    context "when originality report visibility is never" do
      before do
        @assignment.update!(
          turnitin_settings: @assignment.turnitin_settings.merge(originality_report_visibility: "never")
        )
      end

      it { is_expected.not_to be_grants_right(student, nil, :view_turnitin_report) }

      context "when the teacher's enrollment is concluded" do
        before do
          @course.enrollments.where(user: teacher).each(&:conclude)
        end

        it "still allows the teacher (with view_all_grades) to see reports" do
          expect(@submission).to be_grants_right(teacher, nil, :view_turnitin_report)
        end
      end
    end
  end

  describe "'view_vericite_report' right" do
    let(:teacher) do
      user = User.create
      @context.enroll_teacher(user)
      user
    end

    before :once do
      Auditors::ActiveRecord::Partitioner.process
      @assignment.update!(submission_types: "online_upload,online_text_entry")

      @submission = @assignment.submit_homework(@user, { body: "hello there", submission_type: "online_text_entry" })
      @submission.turnitin_data = {
        "submission_#{@submission.id}" => {
          web_overlap: 92,
          error: true,
          publication_overlap: 0,
          state: "failure",
          object_id: "123456789",
          student_overlap: 90,
          similarity_score: 92
        },
        :provider => "vericite"
      }
      @submission.save!
    end

    it "is available when the plagiarism report is from vericite" do
      expect(@submission).to be_grants_right(teacher, nil, :view_vericite_report)
    end

    it "is not available when the plagiarism report is from turnitin" do
      @submission.turnitin_data[:provider] = "turnitin"
      expect(@submission).not_to be_grants_right(teacher, nil, :view_vericite_report)
    end

    it "is not available when the plagiarism report is blank (defaults to turnitin)" do
      @submission.turnitin_data.delete(:provider)
      expect(@submission).not_to be_grants_right(teacher, nil, :view_vericite_report)
    end
  end

  context "#external_tool_url" do
    let(:submission) { Submission.new }
    let(:lti_submission) { @assignment.submit_homework @user, submission_type: "basic_lti_launch", url: "http://www.example.com" }

    context 'submission_type of "basic_lti_launch"' do
      it "returns a url containing the submitted url" do
        expect(lti_submission.external_tool_url).to eq(lti_submission.url)
      end
    end

    context 'submission_type of anything other than "basic_lti_launch"' do
      it "returns nothing" do
        expect(submission.external_tool_url).to be_nil
      end
    end
  end

  it "returns the correct quiz_submission_version" do
    # set up the data to have a submission with a quiz submission with multiple versions
    course_factory
    quiz = @course.quizzes.create!
    quiz_submission = quiz.generate_submission @user, false
    quiz_submission.save

    @assignment.submissions.find_by!(user: @user).update!(quiz_submission_id: quiz_submission.id)

    submission = @assignment.submit_homework @user, submission_type: "online_quiz"
    submission.quiz_submission_id = quiz_submission.id

    # set the microseconds of the submission.submitted_at to be less than the
    # quiz_submission.finished_at.

    # first set them to be exactly the same (with microseconds)
    time_to_i = submission.submitted_at.to_i
    usec = submission.submitted_at.usec
    timestamp = "#{time_to_i}.#{usec}".to_f

    quiz_submission.finished_at = Time.at(timestamp)
    quiz_submission.save

    # get the data in a strange state where the quiz_submission.finished_at is
    # microseconds older than the submission (caused the bug in #6048)
    quiz_submission.finished_at = Time.at(timestamp + 0.00001)
    quiz_submission.save

    # verify the data is weird, to_i says they are equal, but the usecs are off
    expect(quiz_submission.finished_at.to_i).to eq submission.submitted_at.to_i
    expect(quiz_submission.finished_at.usec).to be > submission.submitted_at.usec

    # create the versions that Submission#quiz_submission_version uses
    quiz_submission.with_versioning do
      quiz_submission.save
      quiz_submission.save
    end

    # the real test, quiz_submission_version shouldn't care about usecs
    expect(submission.reload.quiz_submission_version).to eq 2
  end

  it "returns only comments readable by the user" do
    course_with_teacher(active_all: true)
    @course.default_post_policy.update!(post_manually: false)
    @student1 = student_in_course(active_user: true).user
    @student2 = student_in_course(active_user: true).user

    @assignment = @course.assignments.new(title: "some assignment")
    @assignment.submission_types = "online_text_entry"
    @assignment.workflow_state = "published"
    @assignment.save

    @submission = @assignment.submit_homework(@student1, body: "some message")
    @submission.add_comment(author: @teacher, comment: "a")
    @submission.add_comment(author: @teacher, comment: "b", hidden: true)
    @submission.add_comment(author: @student1, comment: "c")
    @submission.add_comment(author: @student2, comment: "d")
    @submission.add_comment(author: @teacher, comment: "e", draft: true)
    @submission.reload

    @submission.limit_comments(@teacher)
    expect(@submission.submission_comments.count).to be 5
    expect(@submission.visible_submission_comments.count).to be 4

    @submission.limit_comments(@student1)
    expect(@submission.submission_comments.count).to be 4
    expect(@submission.visible_submission_comments.count).to be 4

    @submission.limit_comments(@student2)
    expect(@submission.submission_comments.count).to be 1
    expect(@submission.visible_submission_comments.count).to be 1
  end

  describe "read/unread state" do
    it "is read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@user)
      expect(@submission.read?(@user)).to be_truthy
    end

    it "is unread after assignment is graded" do
      @submission = @assignment.grade_student(@user, grade: 3, grader: @teacher).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "is unread after submission is graded" do
      @assignment.submit_homework(@user)
      @submission = @assignment.grade_student(@user, grade: 3, grader: @teacher).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "is unread after submission is commented on by teacher" do
      @student = @user
      course_with_teacher(course: @context, active_all: true)
      @submission = @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" }).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "is read after submission is commented on by teacher and then teacher deletes comment" do
      student = @user
      submission = @assignment.submission_for_student(@student)

      submission.add_comment(author: @teacher, comment: "some comment")

      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1

      comment = submission.submission_comments.first

      expect do
        comment.updating_user = @current_user
        comment.destroy!
      end.to change { SubmissionComment.count }.from(1).to(0)

      expect(submission.read?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 0
    end

    it "is read after submission is commented on twice by teacher and then teacher deletes the first comment" do
      student = @user
      submission = @assignment.submission_for_student(student)

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1

      comment = submission.submission_comments.first

      expect do
        comment.updating_user = @current_user
        comment.destroy!
      end.to change { SubmissionComment.count }.from(2).to(1)

      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1
    end

    it "is read after submission is commented on by teacher, student views comment, teacher comments again, and then teacher deletes the not viewed comment" do
      student = @user
      submission = @assignment.submission_for_student(student)

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1

      submission.mark_submission_comments_read(student)
      submission.mark_item_read("comment")
      expect(submission.read?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 0

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      comment = submission.submission_comments[1]

      expect do
        comment.updating_user = @current_user
        comment.destroy!
      end.to change { SubmissionComment.count }.from(2).to(1)

      expect(submission.read?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 0
    end

    it "is unread after submission is commented on by teacher, student views comment, teacher comments again, and then teacher deletes the viewed comment" do
      student = @user
      submission = @assignment.submission_for_student(student)

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1

      submission.mark_submission_comments_read(student)
      submission.mark_item_read("comment")
      expect(submission.read?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: @student.id).first
      expect(content_participation_count.unread_count).to eq 0

      submission.add_comment(author: @teacher, comment: "some comment")
      expect(submission.unread?(student)).to be_truthy

      comment = submission.submission_comments.first

      expect do
        comment.updating_user = @current_user
        comment.destroy!
      end.to change { SubmissionComment.count }.from(2).to(1)

      expect(submission.unread?(student)).to be_truthy

      content_participation_count = ContentParticipationCount.where(user_id: student.id).first
      expect(content_participation_count.unread_count).to eq 1
    end

    it "is read if other submission fields change" do
      @submission = @assignment.submit_homework(@user)
      @submission.workflow_state = "graded"
      @submission.graded_at = Time.now
      @submission.save!
      expect(@submission.read?(@user)).to be_truthy
    end

    it "mark read/unread" do
      @submission = @assignment.submit_homework(@user)
      @submission.workflow_state = "graded"
      @submission.graded_at = Time.now
      @submission.save!
      expect(@submission.read?(@user)).to be_truthy
      @submission.mark_unread(@user)
      expect(@submission.read?(@user)).to be_falsey
      @submission.mark_read(@user)
      expect(@submission.read?(@user)).to be_truthy
    end

    it "is unread after submission is graded by teacher" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      expect(@submission.read?(@student)).to be_falsey
    end

    it "is unread after submission is graded and commented on by teacher" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @submission = @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" }).first

      expect(@submission.read?(@student)).to be_falsey
    end

    it "is unread after grade is read and teacher posts a comment" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @submission.mark_item_read("grade")
      @submission = @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" }).first

      expect(@submission.reload.read?(@student)).to be_falsey
    end

    it "is read after grade is read and student posts a comment" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @submission.mark_item_read("grade")
      @submission = @assignment.update_submission(@student, { commenter: @student, comment: "good!" }).first

      expect(@submission.reload.read?(@student)).to be_truthy
    end

    it "is unread after student and teacher post a comment" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_submission(@student, { commenter: @student, comment: "good!" })
      @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" })

      expect(@submission.read?(@student)).to be_falsey
    end

    it "is unread if there is any unread rubric" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      ContentParticipation.participate(content: @submission, user: @student, content_item: "rubric")

      expect(@submission.read?(@student)).to be_falsey
    end

    it "is read if grade and rubric are read" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      ContentParticipation.participate(content: @submission, user: @student, content_item: "rubric")

      @submission.mark_item_read("grade")
      @submission.mark_item_read("rubric")

      expect(@submission.read?(@student)).to be_truthy
    end

    it "changes the state from read to unread" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" })

      @submission.mark_item_unread("comment")

      expect(@submission.unread?(@student)).to be_truthy
    end

    it "marks submission comments as read" do
      @student = @user
      @assignment.submit_homework(@student)
      @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
      @assignment.update_submission(@student, { commenter: @teacher, comment: "good!" })
      @submission.mark_submission_comments_read(@student)

      visible_comment = @submission.visible_submission_comments[0]
      viewed_comment = visible_comment.viewed_submission_comments[0]
      expect(viewed_comment.user).to eql @student
      expect(viewed_comment.submission_comment).to eql visible_comment
    end
  end

  describe "mute" do
    let(:submission) { Submission.new }

    before do
      submission.published_score = 100
      submission.published_grade = "A"
      submission.graded_at = Time.now
      submission.grade = "B"
      submission.score = 90
      submission.mute
    end

    specify { expect(submission.published_score).to be_nil }
    specify { expect(submission.published_grade).to be_nil }
    specify { expect(submission.graded_at).to be_nil }
    specify { expect(submission.grade).to be_nil }
    specify { expect(submission.score).to be_nil }
  end

  describe "muted_assignment?" do
    it "returns true if assignment is muted" do
      assignment = double(muted?: true)
      @submission = Submission.new
      expect(@submission).to receive(:assignment).and_return(assignment)
      expect(@submission.muted_assignment?).to be true
    end

    it "returns false if assignment is not muted" do
      assignment = double(muted?: false)
      @submission = Submission.new
      expect(@submission).to receive(:assignment).and_return(assignment)
      expect(@submission.muted_assignment?).to be false
    end
  end

  describe "without_graded_submission?" do
    let(:submission) { Submission.new }

    it "returns false if submission does not has_submission?" do
      allow(submission).to receive_messages(has_submission?: false, graded?: true)
      expect(submission.without_graded_submission?).to be false
    end

    it "returns false if submission does is not graded" do
      allow(submission).to receive_messages(has_submission?: true, graded?: false)
      expect(submission.without_graded_submission?).to be false
    end

    it "returns true if submission is not graded and has no submission" do
      allow(submission).to receive_messages(has_submission?: false, graded?: false)
      expect(submission.without_graded_submission?).to be true
    end
  end

  describe "graded?" do
    it "is false before graded" do
      submission, _ = @assignment.find_or_create_submission(@user)
      expect(submission).to_not be_graded
    end

    it "is true for graded assignments" do
      submission = @assignment.grade_student(@user, grade: 1, grader: @teacher)[0]
      expect(submission).to be_graded
    end

    it "is also true for excused assignments" do
      submission, _ = @assignment.find_or_create_submission(@user)
      submission.excused = true
      expect(submission).to be_graded
    end
  end

  describe "autograded" do
    let(:submission) { Submission.new }

    it "returns false when its not autograded" do
      submission = Submission.new
      expect(submission).to_not be_autograded

      submission.grader_id = Shard.global_id_for(@user.id)
      expect(submission).to_not be_autograded
    end

    it "returns true when its autograded" do
      submission = Submission.new
      submission.grader_id = -1
      expect(submission).to be_autograded
    end
  end

  describe "past_due" do
    before :once do
      Auditors::ActiveRecord::Partitioner.process
      submission_spec_model
      @submission1 = @submission

      add_section("overridden section")
      u2 = student_in_section(@course_section, active_all: true)
      submission_spec_model(user: u2)
      @submission2 = @submission

      @assignment.update_attribute(:due_at, 1.day.ago)
      @submission1.reload
      @submission2.reload
    end

    it "updates when an assignment's due date is changed" do
      expect(@submission1).to be_past_due
      @assignment.reload.update_attribute(:due_at, 1.day.from_now)
      expect(@submission1.reload).not_to be_past_due
    end

    it "updates when an applicable override is changed" do
      expect(@submission1).to be_past_due
      expect(@submission2).to be_past_due

      assignment_override_model assignment: @assignment,
                                due_at: 1.day.from_now,
                                set: @course_section
      expect(@submission1.reload).to be_past_due
      expect(@submission2.reload).not_to be_past_due
    end

    it "gives a quiz submission 30 extra seconds before making it past due" do
      quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }]) do
        {
          "text_after_answers" => "",
          "question_#{@questions[0].id}" => "<p>Lorem ipsum answer.</p>",
          "context_id" => @course.id.to_s,
          "context_type" => "Course",
          "user_id" => @user.id.to_s,
          "quiz_id" => @quiz.id.to_s,
          "course_id" => @course.id.to_s,
          "question_text" => "Lorem ipsum question",
        }
      end
      @assignment.due_at = "20130101T23:59Z"
      @assignment.save!

      submission = @quiz_submission.submission.reload
      submission.write_attribute(:submitted_at, @assignment.due_at + 3.days)
      expect(submission).to be_past_due

      submission.write_attribute(:submitted_at, @assignment.due_at + 30.seconds)
      expect(submission).not_to be_past_due
    end
  end

  describe "late" do
    before :once do
      submission_spec_model(submit_homework: true)
    end

    it "is false if not past due" do
      @submission.submitted_at = 2.days.ago
      @submission.cached_due_date = 1.day.ago
      expect(@submission).not_to be_late
    end

    it "is false if not submitted, even if past due" do
      @submission.submission_type = nil
      @submission.cached_due_date = 1.day.ago # forces submitted_at to be nil
      expect(@submission).not_to be_late
    end

    it "is true if submitted and past due" do
      @submission.submitted_at = 1.day.ago
      @submission.cached_due_date = 2.days.ago
      expect(@submission).to be_late
    end
  end

  describe "scope: not_submitted_or_graded" do
    before do
      @assignment = @course.assignments.create!(submission_types: "online_text_entry")
      @submission = @assignment.submissions.find_by(user: @student)
    end

    it "includes submissions where the student has not submitted and has not been graded" do
      expect(Submission.not_submitted_or_graded).to include @submission
    end

    it "excludes submissions where the student has submitted" do
      @assignment.submit_homework(@student, body: "hi")
      expect(Submission.not_submitted_or_graded).not_to include @submission
    end

    it "excludes submissions where the student has been graded" do
      @assignment.grade_student(@student, grader: @teacher, grade: 10)
      expect(Submission.not_submitted_or_graded).not_to include @submission
    end

    it "excludes excused submissions" do
      @assignment.grade_student(@student, grader: @teacher, excused: true)
      expect(Submission.not_submitted_or_graded).not_to include @submission
    end
  end

  describe "scope: postable" do
    subject(:submissions) { assignment.submissions.postable }

    let(:assignment) { @course.assignments.create! }
    let(:submission) { assignment.submissions.find_by(user: @student) }

    before do
      assignment.ensure_post_policy(post_manually: true)
    end

    it "does not include submissions that neither have grades nor hidden comments" do
      submission.add_comment(author: @teacher, comment: "good job!", hidden: false)
      expect(subject).not_to include(submission)
    end

    it "includes submissions with hidden comments" do
      submission.add_comment(author: @teacher, comment: "good job!", hidden: true)
      expect(subject).to include(submission)
    end

    it "includes submissions with a grade" do
      assignment.grade_student(@student, grader: @teacher, grade: 10)
      expect(subject).to include(submission)
    end

    it "includes submissions that are excused" do
      assignment.grade_student(@student, grader: @teacher, excused: true)
      expect(subject).to include(submission)
    end
  end

  describe "scope: with_hidden_comments" do
    subject(:submissions) { assignment.submissions.with_hidden_comments }

    let(:assignment) { @course.assignments.create! }
    let(:submission) { assignment.submissions.find_by(user: @student) }

    before do
      assignment.grade_student(@student, grader: @teacher, score: 5)
    end

    it "does not include submissions without a hidden comment" do
      submission.add_comment(author: @teacher, comment: "good job!", hidden: false)
      expect(subject).not_to include(submission)
    end

    it "includes submissions with hidden comments" do
      submission.add_comment(author: @teacher, comment: "good job!", hidden: true)
      expect(subject).to include(submission)
    end
  end

  describe "scope: anonymized" do
    subject(:submissions) { assignment.all_submissions.anonymized }

    let(:assignment) { @course.assignments.create! }
    let(:first_student) { @student }
    let(:second_student) { student_in_course(course: @course, active_all: true).user }
    let(:submission_with_anonymous_id) { submission_model(assignment:, user: first_student) }
    let(:submission_without_anonymous_id) do
      submission_model(assignment:, user: second_student).tap do |submission|
        submission.update_attribute(:anonymous_id, nil)
      end
    end

    it "only contains submissions that have anonymous_ids" do
      expect(subject).to contain_exactly(submission_with_anonymous_id)
    end
  end

  describe "scope: due_in_past" do
    subject(:submissions) { student.submissions.due_in_past }

    let(:future_assignment) { @course.assignments.create!(due_at: 2.days.from_now) }
    let(:past_assignment) { @course.assignments.create!(due_at: 2.days.ago) }
    let(:whenever_assignment) { @course.assignments.create!(due_at: nil) }
    let(:student) { @student }
    let(:future_submission) { future_assignment.submission_for_student(student) }
    let(:past_submission) { past_assignment.submission_for_student(student) }
    let(:whenever_submission) { whenever_assignment.submission_for_student(student) }

    it "includes submissions with a due date in the past" do
      expect(subject).to include(past_submission)
    end

    it "excludes submissions with a due date in the future" do
      expect(subject).not_to include(future_submission)
    end

    it "excludes submissions without a due date" do
      expect(subject).not_to include(whenever_submission)
    end
  end

  describe "scope: excused" do
    before :once do
      submission_spec_model
    end

    it "includes submission when excused is true" do
      @submission.update(excused: true)
      expect(Submission.excused).to include @submission
    end

    it "does not include submission when excused is false" do
      @submission.update(excused: false)
      expect(Submission.excused).not_to include @submission
    end

    it "does not include the submission when excused is nil" do
      @submission.update(excused: nil)
      expect(Submission.excused).not_to include @submission
    end
  end

  describe "scope: unposted" do
    before :once do
      submission_spec_model
    end

    it "includes submission when posted_at is nil" do
      @submission.update(posted_at: nil, grade: 10, score: 10)
      expect(Submission.unposted).to include @submission
    end

    it "does not include submission when posted_at is not nil" do
      @submission.update(posted_at: Time.zone.now, grade: 10, score: 10)
      expect(Submission.unposted).not_to include @submission
    end
  end

  describe "scope: missing" do
    context "not submitted" do
      before :once do
        @now = Time.zone.now
        submission_spec_model(cached_due_date: 1.day.ago(@now), submission_type: nil)
        @submission.assignment.update!(submission_types: "online_upload")
      end

      it "excludes an otherwise missing submission that has been marked with a custom status" do
        @submission.update!(grader_id: nil)
        admin = account_admin_user(account: @course.root_account)
        custom_grade_status = @course.root_account.custom_grade_statuses.create!(
          name: "Custom Status",
          color: "#ABC",
          created_by: admin
        )

        expect { @submission.update!(custom_grade_status:) }.to change {
          Submission.missing.include?(@submission)
        }.from(true).to(false)
      end

      it "includes submission when due date has passed with no submission, late_policy_status is nil, excused is nil and grader is nil" do
        @submission.update(grader_id: nil)
        expect(Submission.missing).to include @submission
      end

      it 'includes submission when late_policy_status is "missing"' do
        @submission.update(late_policy_status: "missing")

        expect(Submission.missing).to include @submission
      end

      it "includes submission when late_policy_status is not nil, not missing" do
        @submission.update(late_policy_status: "none")

        expect(Submission.missing).to include @submission
      end

      it "excludes submission when past due and excused" do
        @submission.update(excused: true)

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when past due and extended" do
        @submission.update(late_policy_status: "extended")

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when past due and assignment does not expect a submission" do
        @submission.assignment.update(submission_types: "none")

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when it is excused and late_policy_status is missing" do
        @submission.update(excused: true, late_policy_status: "missing")

        expect(Submission.missing).to be_empty
      end

      it "includes submission when late_policy_status is missing and assignment does not expect a submission" do
        @submission.update(late_policy_status: "missing")
        @submission.assignment.update(submission_types: "none")

        expect(Submission.missing).to include @submission
      end

      it "excludes submission when due date has not passed" do
        @submission.update(cached_due_date: 1.day.from_now(@now))

        expect(Submission.missing).to be_empty
      end

      it "includes missing quiz_lti assignments" do
        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
        @assignment.quiz_lti!
        @assignment.due_at = 1.day.ago(@now)
        @assignment.save!

        @submission.update(grader_id: nil)
        expect(Submission.missing).to include @submission
      end
    end

    context "submitted" do
      before :once do
        @now = Time.zone.now
        submission_spec_model(cached_due_date: 1.day.ago(@now), submission_type: nil, submit_homework: true)
        @submission.assignment.update!(submission_types: "online_upload")
      end

      it "excludes submission when late_policy_status is nil" do
        expect(Submission.missing).to be_empty
      end

      it 'includes submission when late_policy_status is "missing"' do
        @submission.update(late_policy_status: "missing")

        expect(Submission.missing).not_to be_empty
      end

      it "excludes submission when late_policy_status is not nil, not missing" do
        @submission.update(late_policy_status: "foo")

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when late_policy_status is extended" do
        @submission.update(late_policy_status: "extended")

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when submitted before the due date" do
        @submission.update(submitted_at: 2.days.ago(@now))

        expect(Submission.missing).to be_empty
      end

      it "excludes submission when submitted after the due date" do
        @submission.update(submitted_at: @now)

        expect(Submission.missing).to be_empty
      end
    end
  end

  describe "scope: in_current_grading_period_for_courses" do
    before :once do
      @term = Account.default.enrollment_terms.create!(start_at: 10.years.ago)
      @course.enrollment_term_id = @term.id
      @course.save!

      period_group = Account.default.grading_period_groups.create!
      period_group.enrollment_terms << @course.enrollment_term
      now = Time.zone.now
      period_group.grading_periods.create!(
        title: "Closed Period",
        start_date: 5.months.ago(now),
        end_date: 2.months.ago(now),
        close_date: 2.months.ago(now)
      )
      period_group.grading_periods.create!(
        title: "Current Period",
        start_date: 2.months.ago(now),
        end_date: 2.months.from_now(now),
        close_date: 2.months.from_now(now)
      )

      @course.assignments.create!(
        name: "Assignment in closed period",
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 4.months.ago(now)
      )
      @course.assignments.create!(
        name: "Assignment in current period",
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 1.month.ago
      )
    end

    it "only returns submissions in the current grading period" do
      submissions = Submission.in_current_grading_period_for_courses([@course.id])
      expect(submissions.map { |s| s.assignment.name }.sort).to eq(["Assignment in current period", "some assignment"].sort)
    end

    it "includes assignments without a due date" do
      @course.assignments.create!(
        name: "Assignment without due date",
        workflow_state: "published",
        submission_types: "online_text_entry"
      )
      submissions = Submission.in_current_grading_period_for_courses([@course.id])
      expect(submissions.count).to be(3)
      expect(submissions.map { |s| s.assignment.name }).to include("Assignment without due date")
    end

    it "includes assignments from all specified courses" do
      course1 = @course
      course_factory(enrollment_term_id: @term.id, active_all: true)
      @course.enroll_student(@student, enrollment_state: :active)
      @course.assignments.create!(
        name: "Another in current period",
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 1.month.ago
      )
      submissions = Submission.in_current_grading_period_for_courses([course1.id, @course.id])
      expect(submissions.count).to be(3)
      expect(submissions.map { |s| s.assignment.name }).to include("Another in current period")
    end

    it "ignores courses not included in array" do
      course_factory(enrollment_term_id: @term.id, active_all: true)
      @course.enroll_student(@student, enrollment_state: :active)
      @course.assignments.create!(
        name: "Another in current period",
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 1.month.ago
      )
      submissions = Submission.in_current_grading_period_for_courses([@course.id])
      expect(submissions.count).to be(1)
      expect(submissions.first.assignment.name).to eq("Another in current period")
    end

    it "includes all submissions from courses without grading periods" do
      course1 = @course
      course_factory(active_all: true)
      @course.enroll_student(@student, enrollment_state: :active)
      @course.assignments.create!(
        name: "No GP 1",
        workflow_state: "published",
        submission_types: "online_text_entry",
        due_at: 1.month.ago
      )
      @course.assignments.create!(
        name: "No GP 2",
        workflow_state: "published",
        submission_types: "online_text_entry"
      )
      submissions = Submission.in_current_grading_period_for_courses([course1.id, @course.id])
      expect(submissions.map { |s| s.assignment.name }.sort).to eq(["Assignment in current period", "No GP 1", "No GP 2", "some assignment"].sort)
    end
  end

  describe "#late?" do
    before(:once) do
      @course = Course.create!
      student = User.create!
      @course.enroll_student(student, enrollment_state: "active")
      now = Time.zone.now
      assignment = @course.assignments.create!(submission_types: "online_text_entry", due_at: 10.days.ago(now))
      @submission = assignment.submit_homework(student, body: "Submitting late :(")
    end

    it "returns true if the submission is past due" do
      expect(@submission).to be_late
    end

    it "returns false if the submission is excused" do
      @submission.excused = true
      expect(@submission).not_to be_late
    end

    it "returns false if the submission is past due but has its late_policy_status set to something other than 'late'" do
      @submission.late_policy_status = "missing"
      expect(@submission).not_to be_late
    end

    it "returns false when an otherwise late submission has a custom status" do
      admin = account_admin_user(account: @course.root_account)
      custom_grade_status = @course.root_account.custom_grade_statuses.create!(
        name: "Custom Status",
        color: "#ABC",
        created_by: admin
      )
      expect { @submission.update!(custom_grade_status:) }.to change {
        @submission.late?
      }.from(true).to(false)
    end
  end

  describe "#extended?" do
    before(:once) do
      @course = Course.create!
      student = User.create!
      @course.enroll_student(student, enrollment_state: "active")
      assignment = @course.assignments.create!(submission_types: "online_text_entry")
      @submission = assignment.submissions.find_by(user: student)
    end

    it "returns false when a custom status has been applied" do
      @submission.update(late_policy_status: "extended")
      admin = account_admin_user(account: @course.root_account)
      custom_grade_status = @course.root_account.custom_grade_statuses.create!(
        name: "Custom Status",
        color: "#ABC",
        created_by: admin
      )
      expect { @submission.update!(custom_grade_status:) }.to change {
        @submission.extended?
      }.from(true).to(false)
    end
  end

  describe "#missing" do
    before :once do
      @now = Time.zone.now
      submission_spec_model(cached_due_date: 1.day.ago(@now), submission_type: nil, submit_homework: true)
      @submission.assignment.update!(submission_types: "on_paper")
      @another_assignment = assignment_model(course: @course, due_at: 1.day.ago)
      @another_submission = @another_assignment.submissions.last
    end

    submissions_that_cant_be_missing = %w[none on_paper external_tool]
    %w[none
       on_paper
       online_quiz
       discussion_topic
       external_tool
       online_upload
       online_text_entry
       online_url
       media_recording].each do |sub_type|
      should_not_be_missing = submissions_that_cant_be_missing.include?(sub_type)
      expected_status = should_not_be_missing ? "false" : "true"
      it "returns #{expected_status} when late_policy_status is nil and submission_type is #{sub_type}" do
        @another_assignment.update(submission_types: sub_type)

        if should_not_be_missing
          expect(@another_submission.reload).not_to be_missing
        else
          expect(@another_submission.reload).to be_missing
        end
      end
    end

    it "returns false when an otherwise missing submission has a custom status" do
      @another_assignment.update!(submission_types: "online_upload")
      admin = account_admin_user(account: @course.root_account)
      custom_grade_status = @course.root_account.custom_grade_statuses.create!(
        name: "Custom Status",
        color: "#ABC",
        created_by: admin
      )
      expect { @another_submission.update!(custom_grade_status:) }.to change {
        @another_submission.missing?
      }.from(true).to(false)
    end

    it "returns false when late_policy_status is nil standalone" do
      expect(@submission).not_to be_missing
    end

    it 'returns true when late_policy_status is "missing"' do
      @submission.update(late_policy_status: "missing")

      expect(@submission).to be_missing
    end

    it 'returns false when the submission is excused and late_policy_status is "missing"' do
      @submission.excused = true
      @submission.late_policy_status = "missing"
      expect(@submission).not_to be_missing
    end

    it "returns false when late_policy_status is not nil, not missing" do
      @submission.update(late_policy_status: "late")

      expect(@submission).not_to be_missing
    end

    it "returns false when not past due" do
      @submission.update(submitted_at: 2.days.ago(@now))

      expect(@submission).not_to be_missing
    end

    it "returns false when past due and submitted" do
      @submission.update(submitted_at: @now)

      expect(@submission).not_to be_missing
    end

    it "returns false when past due, not submitted, assignment does not expect a submission, is excused" do
      @submission.assignment.update(submission_types: "none")
      @submission.update(excused: true)
      @submission.update_columns(submission_type: nil)

      expect(@submission).not_to be_missing
    end

    it "returns false when past due, not submitted, assignment does not expect a submission, not excused, and no score" do
      @submission.assignment.update(submission_types: "none")
      @submission.update_columns(submission_type: nil)

      expect(@submission).not_to be_missing
    end

    it 'returns false when past due, not submitted, assignment does not expect a submission, not excused, has a score, workflow state is not "graded"' do
      @submission.update(score: 1)
      @submission.update_columns(submission_type: nil)

      expect(@submission).not_to be_missing
    end

    it 'returns false when past due, not submitted, assignment does not expect a submission, not excused, has a score, workflow state is "graded", and score is 0' do
      @submission.update(score: 0, workflow_state: "graded")
      @submission.update_columns(submission_type: nil)

      expect(@submission).not_to be_missing
    end

    it 'returns false when past due, not submitted, assignment does not expect a submission, not excused, has a score, workflow state is "graded", and score is greater than 0' do
      @submission.update(score: 1, workflow_state: "graded")
      @submission.update_columns(submission_type: nil)

      expect(@submission).not_to be_missing
    end

    it "returns true for missing quiz_lti submissions" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )

      @another_assignment.quiz_lti!
      @another_assignment.save!

      @another_submission.reload
      expect(@another_submission).to be_missing
    end

    it "returns true for missing quiz_lti submissions when cached_quiz_lti is false but assignment.quiz_lti is true" do
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )

      @another_assignment.quiz_lti!
      @another_assignment.save!

      @another_submission.reload
      @another_submission.update!(cached_quiz_lti: false)
      expect(@another_submission).to be_missing
    end
  end

  describe "update_attachment_associations" do
    before do
      course_with_student active_all: true
      @assignment = @course.assignments.create!
    end

    it "doesn't include random attachment ids" do
      f = Attachment.create! uploaded_data: StringIO.new("blah"),
                             context: @course,
                             filename: "blah.txt"
      sub = @assignment.submit_homework(@user, attachments: [f])
      expect(sub.attachments).to eq []
    end

    it "includes attachments in a user group that are not in a section group" do
      @group = @course.groups.create!
      @group.add_user(@user)
      f = Attachment.create! uploaded_data: StringIO.new("blah"),
                             context: @group,
                             filename: "blah.txt",
                             user: @user
      sub = @assignment.submit_homework(@user, attachments: [f])
      expect(sub.attachments).to eq [f]
    end
  end

  describe "versioned_attachments" do
    it "includes user attachments" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", context: @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      expect(sub.versioned_attachments).to eq [att]
    end

    it "does not include attachments with a context of Submission" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", context: @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      sub.attachments.update_all(context_type: "Submission", context_id: sub.id)
      expect(sub.reload.versioned_attachments).to be_empty
    end

    it "includes attachments owned by other users in a group for a group submission" do
      student1, student2 = n_students_in_course(2, { course: @course })
      assignment = @course.assignments.create!(name: "A1", submission_types: "online_upload")

      group_category = @course.group_categories.create!(name: "Project Groups")
      group = group_category.groups.create!(name: "A Team", context: @course)
      group.add_user(student1)
      group.add_user(student2)
      assignment.update(group_category:)

      user_attachment = attachment_model(context: student1)
      assignment.submit_homework(student1, submission_type: "online_upload", attachments: [user_attachment])

      [student1, student2].each do |student|
        submission = assignment.submission_for_student(student)
        submission.versioned_attachments
        expect(submission.versioned_attachments).to include user_attachment
      end
    end

    it "includes attachments uploaded from group by user without matching section id" do
      @group = @course.groups.create!
      @group.add_user(@user)
      f = Attachment.create! uploaded_data: StringIO.new("blah"),
                             context: @group,
                             filename: "blah.txt",
                             user: @user
      sub = @assignment.submit_homework(@user, attachments: [f])
      expect(sub.versioned_attachments).to eq [f]
    end
  end

  describe "includes_attachment?" do
    it "includes current attachments" do
      spoiler = attachment_model(context: @student)
      attachment_model context: @student
      sub = @assignment.submit_homework @student, attachments: [@attachment]
      expect(sub.attachments).to eq([@attachment])
      expect(sub.includes_attachment?(spoiler)).to be false
      expect(sub.includes_attachment?(@attachment)).to be true
    end

    it "includes attachments to previous versions" do
      old_attachment_1 = attachment_model(context: @student)
      old_attachment_2 = attachment_model(context: @student)
      @assignment.submit_homework @student, attachments: [old_attachment_1, old_attachment_2]
      attachment_model context: @student
      sub = @assignment.submit_homework @student, attachments: [@attachment]
      expect(sub.attachments.to_a).to eq([@attachment])
      expect(sub.includes_attachment?(old_attachment_1)).to be true
      expect(sub.includes_attachment?(old_attachment_2)).to be true
    end
  end

  describe "#versioned_originality_reports" do
    it "loads originality reports for the submission" do
      student_in_course(active_all: true)
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submission = @assignment.submit_homework(@student, attachments: [attachment])
      report = OriginalityReport.create!(attachment:, originality_score: "1", submission:)

      expect(submission.versioned_originality_reports).to eq [report]
    end

    it "memoizes the loaded originality reports" do
      student_in_course(active_all: true)
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submission = @assignment.submit_homework(@student, attachments: [attachment])
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)

      submission.versioned_originality_reports
      expect(OriginalityReport).not_to receive(:where)
      submission.versioned_originality_reports
    end

    it "returns an empty array when there are no reports" do
      student_in_course(active_all: true)
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submission = @assignment.submit_homework(@student, attachments: [attachment])

      expect(submission.versioned_originality_reports).to eq []
    end

    it "returns an empty array when there are no attachments" do
      student_in_course(active_all: true)
      submission = @assignment.submit_homework(@student, body: "Oh my!")

      expect(submission.versioned_originality_reports).to eq []
    end

    it "works correctly on originality reports without submission times with multiple text entry or same attachment ids" do
      reports = []
      submissions = (1..3).map do |i|
        sub = @assignment.submit_homework(@student, body: "body #{i}")
        report = OriginalityReport.create!(attachment: nil, originality_score: i, submission: sub)
        report.update_columns(submission_time: nil)
        reports << report
        sub
      end
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submissions += (1..3).map do |i|
        sub = @assignment.submit_homework(@student, attachments: [attachment])
        report = OriginalityReport.create!(attachment:, originality_score: i, submission: sub)
        report.update_columns(submission_time: nil)
        reports << report
        sub
      end

      submissions[0..2].each_with_index do |s, i|
        expect(s.versioned_originality_reports).to match_array reports[i..2]
      end
      submissions[3..].each_with_index do |s, i|
        expect(s.versioned_originality_reports).to match_array reports[(i + 3)..]
      end
    end
  end

  describe "#bulk_load_versioned_originality_reports" do
    before :once do
      student_in_course(active_all: true)
    end

    it "bulk loads originality reports for many submissions at once" do
      originality_reports = []
      submissions = Array.new(3) do |i|
        student_in_course(active_all: true)
        attachments = [
          attachment_model(filename: "submission#{i}-a.doc", context: @student),
          attachment_model(filename: "submission#{i}-b.doc", context: @student)
        ]

        sub = @assignment.submit_homework(@student, attachments:)
        originality_reports << attachments.map do |a|
          OriginalityReport.create!(attachment: a, originality_score: "1", submission: sub)
        end
        sub
      end

      Submission.bulk_load_versioned_originality_reports(submissions)
      submissions.each_with_index do |s, i|
        expect(s.versioned_originality_reports).to eq originality_reports[i]
      end
    end

    it "avoids N+1s in the bulk load" do
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submission = @assignment.submit_homework(@student, attachments: [attachment])
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)

      Submission.bulk_load_versioned_originality_reports([submission])
      expect(OriginalityReport).not_to receive(:where)
      submission.versioned_originality_reports
    end

    it "ignores invalid attachment ids" do
      s = @assignment.submit_homework(@student, submission_type: "online_url", url: "http://example.com")
      s.update_attribute(:attachment_ids, "99999999")
      Submission.bulk_load_versioned_originality_reports([s])
      expect(s.versioned_originality_reports).to eq []
    end

    it "loads only the originality reports that pertain to that version" do
      originality_reports = []
      attachment = attachment_model(filename: "submission-a.doc", context: @student)
      Timecop.freeze(10.seconds.ago) do
        sub = @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [attachment])
        originality_reports <<
          OriginalityReport.create!(attachment:, originality_score: "1", submission: sub)
      end

      attachment = attachment_model(filename: "submission-b.doc", context: @student)
      Timecop.freeze(5.seconds.ago) do
        sub = @assignment.submit_homework(@student, attachments: [attachment])
        originality_reports <<
          OriginalityReport.create!(attachment:, originality_score: "1", submission: sub)
      end

      attachment = attachment_model(filename: "submission-c.doc", context: @student)
      Timecop.freeze(1.second.ago) do
        sub = @assignment.submit_homework(@student, attachments: [attachment])
        originality_reports <<
          OriginalityReport.create!(attachment:, originality_score: "1", submission: sub)
      end

      submission = @assignment.submission_for_student(@student)
      Submission.bulk_load_versioned_originality_reports(submission.submission_history)

      submission.submission_history.each_with_index do |s, index|
        expect(s.versioned_originality_reports.first).to eq originality_reports[index]
      end
    end

    it "works with unsubmitted submissions" do
      submissions = @assignment.submissions.where(user: @student)
      Submission.bulk_load_versioned_originality_reports(submissions)
      submissions.each do |s|
        expect(s.versioned_originality_reports).to eq []
      end
    end

    it "works correctly on originality reports without submission times with multiple text entry or same attachment ids" do
      reports = []
      submissions = (1..3).map do |i|
        sub = @assignment.submit_homework(@student, body: "body #{i}")
        report = OriginalityReport.create!(attachment: nil, originality_score: i, submission: sub)
        report.update_columns(submission_time: nil)
        reports << report
        sub
      end
      attachment = attachment_model(filename: "submission.doc", context: @student)
      submissions += (1..3).map do |i|
        sub = @assignment.submit_homework(@student, attachments: [attachment])
        report = OriginalityReport.create!(attachment:, originality_score: i, submission: sub)
        report.update_columns(submission_time: nil)
        reports << report
        sub
      end

      Submission.bulk_load_versioned_originality_reports(submissions)
      submissions[0..2].each_with_index do |s, i|
        expect(s.versioned_originality_reports).to match_array reports[i..2]
      end
      submissions[3..].each_with_index do |s, i|
        expect(s.versioned_originality_reports).to match_array reports[(i + 3)..]
      end
    end
  end

  context "bulk loading attachments" do
    def ensure_attachments_arent_queried
      expect(Attachment).not_to receive(:where)
    end

    def submission_for_some_user
      student_in_course active_all: true
      @assignment.submit_homework(@student,
                                  submission_type: "online_url",
                                  url: "http://example.com")
    end

    describe "#bulk_load_versioned_attachments" do
      it "loads attachments for many submissions at once" do
        attachments = []

        submissions = Array.new(3) do |i|
          student_in_course(active_all: true)
          attachments << [
            attachment_model(filename: "submission#{i}-a.doc", context: @student),
            attachment_model(filename: "submission#{i}-b.doc", context: @student)
          ]

          @assignment.submit_homework @student, attachments: attachments[i]
        end

        Submission.bulk_load_versioned_attachments(submissions)
        ensure_attachments_arent_queried
        submissions.each_with_index do |s, i|
          expect(s.versioned_attachments).to eq attachments[i]
        end
      end

      it "filters out deleted attachments" do
        student = student_in_course(active_all: true).user
        attachment = attachment_model(filename: "submission.doc", context: student)
        submission = @assignment.submit_homework(student, attachments: [attachment])
        attachment.destroy_permanently!
        submission_with_attachments = Submission.bulk_load_versioned_attachments([submission]).first
        expect(submission_with_attachments.versioned_attachments).to be_empty
      end

      it "includes url submission attachments" do
        s = submission_for_some_user
        s.attachment = attachment_model(filename: "screenshot.jpg",
                                        context: @student)

        Submission.bulk_load_versioned_attachments([s])
        ensure_attachments_arent_queried
        expect(s.versioned_attachments).to eq [s.attachment]
      end

      it "handles bad data" do
        s = submission_for_some_user
        s.update_attribute(:attachment_ids, "99999999")
        Submission.bulk_load_versioned_attachments([s])
        expect(s.versioned_attachments).to eq []
      end

      it "handles submission histories with different attachments" do
        student_in_course(active_all: true)
        attachments = [attachment_model(filename: "submission-a.doc", context: @student)]
        Timecop.freeze(10.seconds.ago) do
          @assignment.submit_homework(@student,
                                      submission_type: "online_upload",
                                      attachments: [attachments[0]])
        end

        attachments << attachment_model(filename: "submission-b.doc", context: @student)
        Timecop.freeze(5.seconds.ago) do
          @assignment.submit_homework @student, attachments: [attachments[1]]
        end

        attachments << attachment_model(filename: "submission-c.doc", context: @student)
        Timecop.freeze(1.second.ago) do
          @assignment.submit_homework @student, attachments: [attachments[2]]
        end

        submission = @assignment.submission_for_student(@student)
        Submission.bulk_load_versioned_attachments(submission.submission_history)

        submission.submission_history.each_with_index do |s, index|
          expect(s.attachment_ids.to_i).to eq attachments[index].id
        end
      end
    end

    describe "#bulk_load_attachments_for_submissions" do
      it "loads attachments for many submissions at once and returns a hash" do
        expected_attachments_for_submissions = {}

        submissions = Array.new(3) do |i|
          student_in_course(active_all: true)
          attachment = [attachment_model(filename: "submission#{i}.doc", context: @student)]
          sub = @assignment.submit_homework @student, attachments: attachment
          expected_attachments_for_submissions[sub] = attachment
          sub
        end

        result = Submission.bulk_load_attachments_for_submissions(submissions)
        ensure_attachments_arent_queried
        expect(result).to eq(expected_attachments_for_submissions)
      end

      it "handles bad data" do
        s = submission_for_some_user
        s.update_attribute(:attachment_ids, "99999999")
        expected_attachments_for_submissions = { s => [] }
        result = Submission.bulk_load_attachments_for_submissions(s)
        expect(result).to eq(expected_attachments_for_submissions)
      end

      it "filters out attachment associations that don't point to an attachment" do
        student = student_in_course(active_all: true).user
        attachment = attachment_model(filename: "submission.doc", context: student)
        submission = @assignment.submit_homework(student, attachments: [attachment])
        submission.attachment_associations.find_by(attachment_id: attachment.id).update!(attachment_id: nil)
        attachments = Submission.bulk_load_attachments_for_submissions([submission]).first.second
        expect(attachments).to be_empty
      end

      it "filters out attachment associations that point to deleted attachments" do
        student = student_in_course(active_all: true).user
        attachment = attachment_model(filename: "submission.doc", context: student)
        submission = @assignment.submit_homework(student, attachments: [attachment])
        attachment.destroy_permanently!
        attachments = Submission.bulk_load_attachments_for_submissions([submission]).first.second
        expect(attachments).to be_empty
      end

      it "includes valid attachments and filters out deleted attachments" do
        student = student_in_course(active_all: true).user
        attachment = attachment_model(filename: "submission.doc", context: student)
        submission = @assignment.submit_homework(student, attachments: [attachment])
        attachment.destroy_permanently!

        another_student = student_in_course(active_all: true).user
        another_attachment = attachment_model(filename: "submission.doc", context: another_student)
        another_submission = @assignment.submit_homework(another_student, attachments: [another_attachment])

        bulk_loaded_submissions = Submission.bulk_load_attachments_for_submissions([submission, another_submission])
        submission_attachments = bulk_loaded_submissions.find { |s| s.first.id == submission.id }.second
        expect(submission_attachments).to be_empty

        another_submission_attachments = bulk_loaded_submissions.find { |s| s.first.id == another_submission.id }.second
        expect(another_submission_attachments).not_to be_empty
      end
    end
  end

  describe "#assign_assessor" do
    def peer_review_assignment
      assignment = @course.assignments.build(title: "Peer review",
                                             due_at: Time.now - 1.day,
                                             points_possible: 5,
                                             submission_types: "online_text_entry")
      assignment.peer_reviews_assigned = true
      assignment.peer_reviews = true
      assignment.automatic_peer_reviews = true
      assignment.save!

      assignment
    end

    before do
      student_in_course(active_all: true)
      @student2 = user_factory
      @student2_enrollment = @course.enroll_student(@student2)
      @student2_enrollment.accept!
      @assignment = peer_review_assignment
      @student1_homework = @assignment.submit_homework(@student,  body: "Lorem ipsum dolor")
      @student2_homework = @assignment.submit_homework(@student2, body: "Sit amet consectetuer")
    end

    it "sends a reminder notification" do
      expect_any_instance_of(AssessmentRequest).to receive(:send_reminder!).once
      submission1, submission2 = @assignment.submissions
      submission1.assign_assessor(submission2)
    end

    it "does not allow read access when assignment's peer reviews are off" do
      @student1_homework.assign_assessor(@student2_homework)
      expect(@student1_homework.grants_right?(@student2, :read)).to be true
      @assignment.peer_reviews = false
      @assignment.save!
      @student1_homework.reload
      AdheresToPolicy::Cache.clear
      expect(@student1_homework.grants_right?(@student2, :read)).to be false
    end

    it "does not allow read access when other student's enrollment is not active" do
      @student2_homework.assign_assessor(@student1_homework)
      @student2_enrollment.conclude
      expect(@student2_homework.grants_right?(@student, :read)).to be false
    end
  end

  describe "#get_web_snapshot" do
    it "does not blow up if web snapshotting fails" do
      sub = submission_spec_model
      expect(CutyCapt).to receive(:enabled?).and_return(true)
      expect(CutyCapt).to receive(:snapshot_attachment_for_url).with(sub.url, context: sub).and_return(nil)
      sub.get_web_snapshot
    end
  end

  describe "capturing screenshots for online_url submissions" do
    let_once(:course) { Course.create! }
    let_once(:student) { course.enroll_student(User.create!, active_all: true).user }
    let(:assignment) { course.assignments.create!(submission_types: ["online_url"]) }
    let(:sub) { assignments.find_by(user: student) }
    let(:submitted_url) { "https://example.com" }
    let(:get_web_snapshot_jobs) { Delayed::Job.where(tag: "Submission#get_web_snapshot").order(:id) }

    before do
      allow(CutyCapt).to receive(:enabled?).and_return(true)
    end

    it "calls #get_web_snapshot when it's the first submission attempt" do
      expect do
        assignment.submit_homework(student, submission_type: "online_url", url: submitted_url)
      end.to change {
        get_web_snapshot_jobs.count
      }.by(1)
    end

    it "calls #get_web_snapshot when it's not the first submission attempt" do
      assignment.submit_homework(student, submission_type: "online_url", url: submitted_url)
      expect do
        assignment.submit_homework(student, submission_type: "online_url", url: "https://example.com/different")
      end.to change {
        get_web_snapshot_jobs.count
      }.by(1)
    end

    it "calls #get_web_snapshot when it's not the first submission attempt and the url hasn't changed" do
      assignment.submit_homework(student, submission_type: "online_url", url: submitted_url)
      expect do
        assignment.submit_homework(student, submission_type: "online_url", url: submitted_url)
      end.to change {
        get_web_snapshot_jobs.count
      }.by(1)
    end

    it "does not call #get_web_snapshot when a url is not included" do
      expect do
        assignment.submit_homework(student, submission_type: "online_url", url: nil)
      end.not_to change {
        get_web_snapshot_jobs.count
      }
    end
  end

  describe "#submit_attachments_to_canvadocs" do
    it "creates crocodoc documents" do
      allow(Canvas::Crocodoc).to receive(:enabled?).and_return true
      s = @assignment.submit_homework(@user,
                                      submission_type: "online_text_entry",
                                      body: "hi")

      # creates crocodoc documents
      a1 = crocodocable_attachment_model context: @user
      s.attachments = [a1]
      s.save
      cd = a1.crocodoc_document
      expect(cd).not_to be_nil

      # shouldn't mess with existing crocodoc documents
      a2 = crocodocable_attachment_model context: @user
      s.attachments = [a1, a2]
      s.save
      expect(a1.reload_crocodoc_document).to eq cd
      expect(a2.crocodoc_document).to eq a2.crocodoc_document
    end

    context "canvadocs_submissions records" do
      before(:once) do
        @student1, @student2 = n_students_in_course(2)
        @attachment = crocodocable_attachment_model(context: @student1)
        @assignment = @course.assignments.create! name: "A1",
                                                  submission_types: "online_upload"
      end

      before do
        allow(Canvadocs).to receive_messages(enabled?: true, annotations_supported?: true, config: nil)
      end

      it "ties submissions to canvadocs" do
        s = @assignment.submit_homework(@student1,
                                        submission_type: "online_upload",
                                        attachments: [@attachment])
        expect(@attachment.canvadoc.submissions).to eq [s]
      end

      context "preferred_plugins" do
        it "does not send o365 as preferred plugins by default" do
          @assignment.submit_homework(@student1,
                                      submission_type: "online_upload",
                                      attachments: [@attachment])

          job = Delayed::Job.where(strand: "canvadocs").last
          expect(job.payload_object.kwargs[:preferred_plugins]).to eq [
            Canvadocs::RENDER_PDFJS,
            Canvadocs::RENDER_BOX,
            Canvadocs::RENDER_CROCODOC
          ]
        end

        it "sends o365 as a preferred plugin when the 'Prefer Office 365 file viewer' account setting is enabled" do
          @assignment.context.root_account.settings[:canvadocs_prefer_office_online] = true
          @assignment.context.root_account.save!
          @assignment.submit_homework(@student1,
                                      submission_type: "online_upload",
                                      attachments: [@attachment])

          job = Delayed::Job.where(strand: "canvadocs").last
          expect(job.payload_object.kwargs[:preferred_plugins]).to eq [
            Canvadocs::RENDER_O365,
            Canvadocs::RENDER_PDFJS,
            Canvadocs::RENDER_BOX,
            Canvadocs::RENDER_CROCODOC
          ]
        end
      end

      it "create records for each group submission" do
        gc = @course.group_categories.create! name: "Project Groups"
        group = gc.groups.create! name: "A Team", context: @course
        group.add_user(@student1)
        group.add_user(@student2)

        @assignment.update_attribute :group_category, gc
        @assignment.submit_homework(@student1,
                                    submission_type: "online_upload",
                                    attachments: [@attachment])

        [@student1, @student2].each do |student|
          submission = @assignment.submission_for_student(student)
          expect(@attachment.canvadoc.submissions).to include submission
        end
      end
    end

    it "doesn't create jobs for non-previewable documents" do
      job_scope = Delayed::Job.where(strand: "canvadocs")
      orig_job_count = job_scope.count

      attachment = attachment_model(context: @user)
      @assignment.submit_homework(@user,
                                  submission_type: "online_upload",
                                  attachments: [attachment])
      expect(job_scope.count).to eq orig_job_count
    end
  end

  describe "#annotation_context" do
    before(:once) do
      @attachment = attachment_model(context: @user)
      @assignment.update!(annotatable_attachment_id: @attachment.id)
      @submission = @assignment.submissions.find_by(user: @user)
    end

    it "creates a canvadocs_annotation_context if draft is true" do
      new_student = @course.enroll_student(User.create!).user
      new_submission = @assignment.submissions.find_by(user: new_student)

      expect do
        new_submission.annotation_context(draft: true)
      end.to change {
        new_submission.canvadocs_annotation_contexts.where(attachment: @attachment, submission_attempt: nil).count
      }.by(1)
    end

    it "returns the already existing canvadocs_annotation_context when passed draft multiple times" do
      existing_context = @submission.annotation_context(draft: true)
      expect(@submission.annotation_context(draft: true)).to eq existing_context
    end

    it "returns nil if a canvadocs_annotation_context does not exist" do
      expect(@submission.annotation_context(attempt: 1)).to be_nil
    end

    it "returns the annotation_context if one exists for the attempt" do
      @submission.update!(attempt: 1)
      context = @submission.canvadocs_annotation_contexts.create!(
        attachment: @attachment,
        submission_attempt: @submission.attempt
      )
      expect(@submission.annotation_context(attempt: @submission.attempt)).to eq context
    end
  end

  describe ".process_bulk_update" do
    before(:once) do
      course_with_teacher active_all: true
      @u1, @u2 = n_students_in_course(2)
      @a1, @a2 = Array.new(2) do
        @course.assignments.create! points_possible: 10
      end
      @progress = Progress.create!(context: @course, tag: "submissions_update")
    end

    it "updates submissions on an assignment" do
      Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                       @a1.id.to_s => {
                                         @u1.id => { posted_grade: 5 },
                                         @u2.id => { posted_grade: 10 }
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to eql "5"
      expect(@a1.submission_for_student(@u2).grade).to eql "10"
    end

    it "only recalculates scores for users with changed submissions" do
      data1 = { @a1.id.to_s => { @u1.id => { posted_grade: 5 }, @u2.id => { posted_grade: 10 } } }
      data2 = { @a1.id.to_s => { @u1.id => { posted_grade: 5 }, @u2.id => { posted_grade: 11 } } } # leave u1 the same
      Submission.process_bulk_update(@progress, @course, nil, @teacher, data1)

      expect_any_instantiation_of(@course).to receive(:recompute_student_scores).with([@u2.id])
      Submission.process_bulk_update(@progress, @course, nil, @teacher, data2)
    end

    it "updates submissions on multiple assignments" do
      Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                       @a1.id => {
                                         @u1.id => { posted_grade: 5 },
                                         @u2.id => { posted_grade: 10 }
                                       },
                                       @a2.id.to_s => {
                                         @u1.id => { posted_grade: 10 },
                                         @u2.id => { posted_grade: 5 }
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to eql "5"
      expect(@a1.submission_for_student(@u2).grade).to eql "10"
      expect(@a2.submission_for_student(@u1).grade).to eql "10"
      expect(@a2.submission_for_student(@u2).grade).to eql "5"
    end

    it "maintains grade when only updating comments" do
      @a1.grade_student(@u1, grade: 3, grader: @teacher)
      Submission.process_bulk_update(@progress,
                                     @course,
                                     nil,
                                     @teacher,
                                     {
                                       @a1.id => {
                                         @u1.id => { text_comment: "comment" }
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to eql "3"
    end

    it "nils grade when receiving empty posted_grade" do
      @a1.grade_student(@u1, grade: 3, grader: @teacher)
      Submission.process_bulk_update(@progress,
                                     @course,
                                     nil,
                                     @teacher,
                                     {
                                       @a1.id => {
                                         @u1.id => { posted_grade: nil }
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to be_nil
    end

    it "does not explode if the assignment is deleted" do
      @a1.destroy
      expect do
        Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                         @a1.id.to_s => {
                                           @u1.id => { posted_grade: 5 },
                                           @u2.id => { posted_grade: 10 }
                                         }
                                       })
      end.to_not raise_error
      expect(@progress.reload.failed?).to be_truthy

      expect(@a1.submission_for_student(@u1).grade).to be_nil
      expect(@a1.submission_for_student(@u2).grade).to be_nil
    end

    it "does not update grader_id if submission is blank or missing with -" do
      Submission.process_bulk_update(@progress,
                                     @course,
                                     nil,
                                     @teacher,
                                     {
                                       @a1.id => {
                                         @u1.id => { posted_grade: nil }
                                       },
                                       @a1.id => {
                                         @u2.id => { posted_grade: "-" }
                                       }
                                     })

      submission1 = @a1.submission_for_student(@u1)
      submission2 = @a1.submission_for_student(@u2)

      expect(submission1.grade).to be_nil
      expect(submission2.grade).to be_nil
      expect(submission1.grader_id).to be_nil
      expect(submission2.grader_id).to be_nil
    end

    describe "submitting comments via bulk update" do
      let(:auto_assignment) { @a1 }
      let(:manual_assignment) do
        @a2.post_policy.update!(post_manually: true)
        @a2
      end

      it "sets the comment to visible if the assignment is automatically posted" do
        Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                         auto_assignment.id.to_s => {
                                           @u1.id => { text_comment: "hello there" }
                                         }
                                       })

        comment = auto_assignment.submission_for_student(@u1).submission_comments.last
        expect(comment).not_to be_hidden
      end

      it "sets the comment to visible if the relevant submission has already been posted" do
        auto_assignment.grade_student(@u1, grade: 0, grader: @teacher)
        Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                         auto_assignment.id.to_s => {
                                           @u1.id => { text_comment: "hello there" }
                                         }
                                       })

        comment = auto_assignment.submission_for_student(@u1).submission_comments.last
        expect(comment).not_to be_hidden
      end

      it "sets the comment to visible if a grade is also included in the update" do
        Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                         auto_assignment.id.to_s => {
                                           @u1.id => { posted_grade: 0, text_comment: "hello there" }
                                         }
                                       })

        comment = auto_assignment.submission_for_student(@u1).submission_comments.last
        expect(comment).not_to be_hidden
      end

      context "for a manually-posted assignment" do
        let(:submission) { manual_assignment.submission_for_student(@u1) }

        it "shows the comment if the associated submission is already posted" do
          manual_assignment.post_submissions(submission_ids: [submission.id])

          Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                           manual_assignment.id.to_s => {
                                             @u1.id => { text_comment: "hello there" }
                                           }
                                         })
          expect(submission.submission_comments.last).not_to be_hidden
        end

        it "leaves the comment hidden if the associated submission is not posted" do
          Submission.process_bulk_update(@progress, @course, nil, @teacher, {
                                           manual_assignment.id.to_s => {
                                             @u1.id => { text_comment: "clandestine comment" }
                                           }
                                         })
          expect(submission.submission_comments.last).to be_hidden
        end
      end
    end
  end

  describe "find_or_create_provisional_grade!" do
    before(:once) do
      @assignment.grader_count = 1
      @assignment.moderated_grading = true
      @assignment.final_grader = @teacher
      @assignment.save!
      submission_spec_model

      @teacher2 = User.create(name: "some teacher 2")
      @context.enroll_teacher(@teacher2)
    end

    context "when force_save is true" do
      it do
        expect { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }
          .to change { AnonymousOrModerationEvent.provisional_grade_created.count }.by(1)
      end

      it do
        expect { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }
          .to_not change { AnonymousOrModerationEvent.provisional_grade_updated.count }
      end

      context "given an existing provisional grade" do
        before(:once) { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }

        it do
          expect { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }
            .to change { AnonymousOrModerationEvent.provisional_grade_updated.count }.by(1)
        end

        it do
          expect { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }
            .not_to change { AnonymousOrModerationEvent.provisional_grade_created.count }
        end
      end
    end

    it "properly creates a provisional grade with all default values but scorer" do
      @submission.find_or_create_provisional_grade!(@teacher)

      expect(@submission.provisional_grades.length).to be 1

      pg = @submission.provisional_grades.first

      expect(pg.scorer_id).to eql @teacher.id
      expect(pg.final).to be false
      expect(pg.graded_anonymously).to be_nil
      expect(pg.grade).to be_nil
      expect(pg.score).to be_nil
      expect(pg.source_provisional_grade).to be_nil
    end

    it "properly amends information to an existing provisional grade" do
      @submission.find_or_create_provisional_grade!(@teacher)
      @submission.find_or_create_provisional_grade!(
        @teacher,
        score: 15.0,
        grade: "20",
        graded_anonymously: true
      )

      expect(@submission.provisional_grades.length).to be 1

      pg = @submission.provisional_grades.first

      expect(pg.scorer_id).to eql @teacher.id
      expect(pg.final).to be false
      expect(pg.graded_anonymously).to be true
      expect(pg.grade).to eql "20"
      expect(pg.score).to be 15.0
      expect(pg.source_provisional_grade).to be_nil
    end

    it "computes provisional grade grade if not given" do
      @submission.find_or_create_provisional_grade!(@teacher)
      @submission.find_or_create_provisional_grade!(
        @teacher,
        score: 15.0
      )

      expect(@submission.provisional_grades.length).to be 1

      pg = @submission.provisional_grades.first

      expect(pg.grade).to eql "15"
    end

    it "does not update grade or score if not given" do
      @submission.find_or_create_provisional_grade!(@teacher, grade: "20", score: 12.0)

      expect(@submission.provisional_grades.first.grade).to eql "20"
      expect(@submission.provisional_grades.first.score).to be 12.0

      @submission.find_or_create_provisional_grade!(@teacher)

      expect(@submission.provisional_grades.first.grade).to eql "20"
      expect(@submission.provisional_grades.first.score).to be 12.0
    end

    it "does not update graded_anonymously if not given" do
      @submission.find_or_create_provisional_grade!(@teacher, graded_anonymously: true)

      expect(@submission.provisional_grades.first.graded_anonymously).to be true

      @submission.find_or_create_provisional_grade!(@teacher)

      expect(@submission.provisional_grades.first.graded_anonymously).to be true
    end

    it "raises an exception if final is true and user is not allowed to select final grade" do
      expect { @submission.find_or_create_provisional_grade!(@student, final: true) }
        .to raise_error(Assignment::GradeError, "User not authorized to give final provisional grades")
    end

    it "raises an exception if grade is not final and student does not need a provisional grade" do
      @assignment.grade_student(@student, grade: 2, grader: @teacher2, provisional: true)
      third_teacher = User.create!
      @course.enroll_teacher(third_teacher, enrollment_state: :active)

      expect { @submission.find_or_create_provisional_grade!(third_teacher, final: false) }
        .to raise_error(Assignment::GradeError, "Student already has the maximum number of provisional grades")
    end

    it "raises an exception if the grade is final and no non-final provisional grades exist" do
      expect { @submission.find_or_create_provisional_grade!(@teacher, final: true) }
        .to raise_error(Assignment::GradeError,
                        "Cannot give a final mark for a student with no other provisional grades")
    end

    it "raises an exception if the grade has been selected and is associated with a provisional grader" do
      pg = @submission.find_or_create_provisional_grade!(@teacher2, grade: "2", score: 2)
      selection = @assignment.moderated_grading_selections.where(student: @submission.user).first
      selection.provisional_grade = pg
      selection.save!

      expect do
        @submission.find_or_create_provisional_grade!(@teacher2, grade: "3", score: 3)
      end.to raise_error(Assignment::GradeError) do |error|
        expect(error.error_code).to eq Assignment::GradeError::PROVISIONAL_GRADE_MODIFY_SELECTED
      end
    end

    it "does not raise an exception if the grade has been selected and is associated with the final grader" do
      pg = @submission.find_or_create_provisional_grade!(@teacher, grade: "2", score: 2)
      selection = @assignment.moderated_grading_selections.where(student: @submission.user).first
      selection.provisional_grade = pg
      selection.save!

      expect do
        @submission.find_or_create_provisional_grade!(@teacher, grade: "3", score: 3)
      end.not_to raise_error
    end

    it "sets the source provisional grade if one is provided" do
      new_source = ModeratedGrading::ProvisionalGrade.new
      provisional_grade = @submission.find_or_create_provisional_grade!(@teacher, source_provisional_grade: new_source)
      expect(provisional_grade.source_provisional_grade).to be new_source
    end

    it "does not wipe out the existing source provisional grade, if a source_provisional_grade is not provided" do
      @submission.find_or_create_provisional_grade!(@teacher)
      expect { @submission.find_or_create_provisional_grade!(@teacher, force_save: true) }
        .not_to change { @submission.provisional_grades.last.source_provisional_grade }
    end
  end

  describe "moderated_grading_allow_list" do
    before(:once) do
      @student = @user
      @assignment.update!(
        final_grader: @teacher,
        grader_comments_visible_to_graders: false,
        grader_count: 3,
        moderated_grading: true,
        submission_types: :online_text_entry
      )
      @assignment.submit_homework(@student, body: "my submission", submission_type: :online_text_entry)
      @submission = @assignment.submissions.find_by(user: @student)
    end

    let(:user_ids_in_allow_list) { allow_list.map { |user| user.fetch(:global_id)&.to_i } }

    it "returns nil when the assignment is not moderated" do
      # Skipping validations here because they'd prevent turning off Moderated Grading
      # for an assignment with graded submissions.
      @assignment.update_column(:moderated_grading, false)
      expect(@submission.moderated_grading_allow_list).to be_nil
    end

    it "returns nil when the user is not present" do
      expect(@submission.moderated_grading_allow_list(nil)).to be_nil
    end

    it "can be passed a collection of attachments for checking if crocodoc is available" do
      attachment = double
      expect(attachment).to receive(:crocodoc_available?).and_return(true)
      @submission.moderated_grading_allow_list(loaded_attachments: [attachment])
    end

    it "returns a collection of moderated grading ids" do
      moderated_grading_ids = @student.moderated_grading_ids(false)
      expect(@submission.moderated_grading_allow_list.first).to eq moderated_grading_ids
    end

    it "calls moderation_allow_list_for_user to generate the allow_list" do
      expect(@submission).to receive(:moderation_allow_list_for_user).with(@student).once.and_call_original
      @submission.moderated_grading_allow_list
    end
  end

  describe "moderation_allow_list_for_user" do
    before(:once) do
      @student = @user
      @provisional_grader = User.create!
      @other_provisional_grader = User.create!
      @course.enroll_teacher(@provisional_grader, enrollment_state: :active)
      @course.enroll_teacher(@other_provisional_grader, enrollment_state: :active)
      @eligible_provisional_grader = User.create!
      @course.enroll_teacher(@eligible_provisional_grader, enrollment_state: :active)
      @admin = account_admin_user(account: @course.root_account)
      @assignment.update!(
        final_grader: @teacher,
        grader_comments_visible_to_graders: false,
        grader_count: 3,
        moderated_grading: true,
        submission_types: :online_text_entry
      )
      @assignment.submit_homework(@student, body: "my submission", submission_type: :online_text_entry)
      @submission = @assignment.submissions.find_by(user: @student)
      @assignment.grade_student(@student, grader: @teacher, provisional: true, score: 5)
      @assignment.grade_student(@student, grader: @provisional_grader, provisional: true, score: 1)
      @assignment.grade_student(@student, grader: @other_provisional_grader, provisional: true, score: 3)
    end

    let(:user_ids_in_allow_list) { allow_list.map { |user| user.fetch(:global_id)&.to_i } }

    it "returns an empty array when the assignment is not moderated" do
      # Skipping validations here because they'd prevent turning off Moderated Grading
      # for an assignment with graded submissions.
      @assignment.update_column(:moderated_grading, false)
      expect(@submission.moderation_allow_list_for_user(@teacher)).to be_empty
    end

    it "returns an empty array when the user is not present" do
      expect(@submission.moderation_allow_list_for_user(nil)).to be_empty
    end

    it "returns an empty array when the user is not permitted to view annotations for the submission" do
      other_student = User.create!
      @course.enroll_student(other_student, enrollment_state: :active)
      expect(@submission.moderation_allow_list_for_user(other_student)).to be_empty
    end

    it "always includes the submission owner when the assignment is of type Student Annotation" do
      ta = @course.enroll_ta(User.create!).user
      @assignment.update!(grader_count: 2, submission_types: "student_annotation")
      expect(@submission.moderation_allow_list_for_user(ta)).to eq [@student]
    end

    context "when the submission is not posted" do
      context "when the user is the final grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@teacher) }

        it "includes the current user" do
          expect(allow_list).to include @teacher
        end

        it "includes all provisional graders" do
          expect(allow_list).to include(*@assignment.moderation_grader_users)
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end
      end

      context "when the user is a provisional grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@provisional_grader) }

        context "when grader comments are visible to other graders" do
          before(:once) do
            @assignment.update!(grader_comments_visible_to_graders: true)
          end

          it "includes all provisional graders" do
            expect(allow_list).to include(*@assignment.moderation_grader_users)
          end

          it "includes the final grader" do
            expect(allow_list).to include @teacher
          end

          it "includes the student" do
            expect(allow_list).to include @student
          end

          it "does not include eligible provisional graders" do
            expect(allow_list).not_to include @eligible_provisional_grader
          end

          it "does not include duplicates" do
            expect(allow_list.uniq).to eq allow_list
          end

          it "does not include nil values" do
            expect(allow_list).not_to include nil
          end
        end

        context "when grader comments are not visible to other graders" do
          it "includes the current user" do
            expect(allow_list).to include @provisional_grader
          end

          it "does not include other provisional graders" do
            expect(allow_list).not_to include @other_provisional_grader
          end

          it "does not include the final grader" do
            expect(allow_list).not_to include @teacher
          end

          it "includes the student" do
            expect(allow_list).to include @student
          end

          it "does not include eligible provisional graders" do
            expect(allow_list).not_to include @eligible_provisional_grader
          end

          it "does not include duplicates" do
            expect(allow_list.uniq).to eq allow_list
          end

          it "does not include nil values" do
            expect(allow_list).not_to include nil
          end
        end
      end

      context "when the user is an eligible provisional grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@eligible_provisional_grader) }

        context "when grader comments are visible to other graders" do
          before(:once) do
            @assignment.update!(grader_comments_visible_to_graders: true)
          end

          it "includes the current user" do
            expect(allow_list).to include @eligible_provisional_grader
          end

          it "includes all provisional graders" do
            expect(allow_list).to include(*@assignment.moderation_grader_users)
          end

          it "includes the final grader" do
            expect(allow_list).to include @teacher
          end

          it "includes the student" do
            expect(allow_list).to include @student
          end

          it "does not include other eligible provisional graders" do
            other_eligible_provisional_grader = User.create!
            @course.enroll_teacher(other_eligible_provisional_grader, enrollment_state: :active)
            expect(allow_list).not_to include other_eligible_provisional_grader
          end

          it "does not include duplicates" do
            expect(allow_list.uniq).to eq allow_list
          end

          it "does not include nil values" do
            expect(allow_list).not_to include nil
          end
        end

        context "when grader comments are not visible to other graders" do
          it "includes the current user" do
            expect(allow_list).to include @eligible_provisional_grader
          end

          it "does not include provisional graders" do
            expect(allow_list).not_to include(*@assignment.moderation_grader_users)
          end

          it "does not include the final grader" do
            expect(allow_list).not_to include @teacher
          end

          it "includes the student" do
            expect(allow_list).to include @student
          end

          it "does not include other eligible provisional graders" do
            other_eligible_provisional_grader = User.create!
            @course.enroll_teacher(other_eligible_provisional_grader, enrollment_state: :active)
            expect(allow_list).not_to include other_eligible_provisional_grader
          end

          it "does not include duplicates" do
            expect(allow_list.uniq).to eq allow_list
          end

          it "does not include nil values" do
            expect(allow_list).not_to include nil
          end
        end
      end

      context "when the user is an admin" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@admin) }

        it "includes the current user" do
          expect(allow_list).to include @admin
        end

        it "includes all provisional graders" do
          expect(allow_list).to include(*@assignment.moderation_grader_users)
        end

        it "includes the final grader" do
          expect(allow_list).to include @teacher
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end
      end

      context "when the user is a student" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@student) }

        it "includes the current user" do
          expect(allow_list).to include @student
        end

        it "does not include the admin" do
          expect(allow_list).not_to include @admin
        end

        it "does not include provisional graders" do
          expect(allow_list).not_to include(*@assignment.moderation_grader_users)
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end
      end
    end

    context "when the submission is posted" do
      before(:once) do
        provisional_grade = @submission.find_or_create_provisional_grade!(@provisional_grader)
        selection = @assignment.moderated_grading_selections.find_by(student: @student)
        selection.update!(provisional_grade:)
        provisional_grade.publish!
        @assignment.update!(grades_published_at: 1.hour.ago)
        @assignment.post_submissions
        @submission.reload
      end

      context "when the user is the final grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@teacher) }

        it "includes the current user" do
          expect(allow_list).to include @teacher
        end

        it "includes the provisional grader whose grade was selected" do
          expect(allow_list).to include @provisional_grader
        end

        it "does not include the provisional grader whose grade was not selected" do
          expect(allow_list).not_to include @other_provisional_grader
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end

        it "does not raise an error when the submission has no grader" do
          @submission.update!(grader: nil, score: nil)
          expect { allow_list }.not_to raise_error
        end
      end

      context "when the user is a provisional grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@provisional_grader) }

        it "includes the current user" do
          expect(allow_list).to include @provisional_grader
        end

        it "does not include other provisional graders whose grades were not selected" do
          expect(allow_list).not_to include @other_provisional_grader
        end

        it "does not include the final grader if their grade was not selected" do
          expect(allow_list).not_to include @teacher
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end

        it "does not raise an error when the submission has no grader" do
          @submission.update!(grader: nil, score: nil)
          expect { allow_list }.not_to raise_error
        end
      end

      context "when the user is an eligible provisional grader" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@eligible_provisional_grader) }

        it "includes the current user" do
          expect(allow_list).to include @eligible_provisional_grader
        end

        it "includes the provisional grader whose grade was selected" do
          expect(allow_list).to include @provisional_grader
        end

        it "does not include the provisional grader whose grade was not selected" do
          expect(allow_list).not_to include @other_provisional_grader
        end

        it "does not include the final grader if their grade was not selected" do
          expect(allow_list).not_to include @teacher
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include other eligible provisional graders" do
          other_eligible_provisional_grader = User.create!
          @course.enroll_teacher(other_eligible_provisional_grader, enrollment_state: :active)
          expect(allow_list).not_to include other_eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end

        it "does not raise an error when the submission has no grader" do
          @submission.update!(grader: nil, score: nil)
          expect { allow_list }.not_to raise_error
        end
      end

      context "when the user is an admin" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@admin) }

        it "includes the current user" do
          expect(allow_list).to include @admin
        end

        it "includes the provisional grader whose grade was selected" do
          expect(allow_list).to include @provisional_grader
        end

        it "does not include the provisional grader whose grade was not selected" do
          expect(allow_list).not_to include @other_provisional_grader
        end

        it "does not include the final grader if their grade was not selected" do
          expect(allow_list).not_to include @teacher
        end

        it "includes the student" do
          expect(allow_list).to include @student
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end

        it "does not raise an error when the submission has no grader" do
          @submission.update!(grader: nil, score: nil)
          expect { allow_list }.not_to raise_error
        end
      end

      context "when the user is a student" do
        let(:allow_list) { @submission.moderation_allow_list_for_user(@student) }

        it "includes the current user" do
          expect(allow_list).to include @student
        end

        it "includes the provisional grader whose grade was selected" do
          expect(allow_list).to include @provisional_grader
        end

        it "does not include the provisional grader whose grade was not selected" do
          expect(allow_list).not_to include @other_provisional_grader
        end

        it "does not include the final grader if their grade was not selected" do
          expect(allow_list).not_to include @teacher
        end

        it "does not include eligible provisional graders" do
          expect(allow_list).not_to include @eligible_provisional_grader
        end

        it "does not include duplicates" do
          expect(allow_list.uniq).to eq allow_list
        end

        it "does not include nil values" do
          expect(allow_list).not_to include nil
        end

        it "does not raise an error when the submission has no grader" do
          @submission.update!(grader: nil, score: nil)
          expect { allow_list }.not_to raise_error
        end
      end
    end
  end

  describe "anonymous_identities" do
    let(:submission) { @assignment.submissions.first }

    it "includes the student in the list" do
      expect(submission.anonymous_identities).to have_key @student.id
    end

    it "includes the anonymous name" do
      expect(submission.anonymous_identities.dig(@student.id, :name)).to eq "Student"
    end

    it "includes the anonymous id" do
      expect(submission.anonymous_identities.dig(@student.id, :id)).to eq submission.anonymous_id
    end
  end

  describe "#visible_rubric_assessments_for" do
    subject { @submission.visible_rubric_assessments_for(@viewing_user) }

    before :once do
      submission_model assignment: @assignment, user: @student
      @viewing_user = @teacher
      @assessed_user = @student
      rubric_association_model association_object: @assignment, purpose: "grading"
      [@teacher, @student].each do |user|
        @rubric_association.rubric_assessments.create!({
                                                         artifact: @submission,
                                                         assessment_type: "grading",
                                                         assessor: user,
                                                         rubric: @rubric,
                                                         user: @assessed_user
                                                       })
      end
      @teacher_assessment = @submission.rubric_assessments.where(assessor_id: @teacher).first
      @student_assessment = @submission.rubric_assessments.where(assessor_id: @student).first
    end

    context "when the submission is unposted and the viewing user cannot :read_grade" do
      before(:once) do
        @assignment.post_policy.update!(post_manually: true)
        @viewing_user = @student
      end

      it "excludes assessments by other users" do
        expect(subject).not_to include(@teacher_assessment)
      end

      it "includes assessments authored by the viewing user" do
        course = Course.create!
        assessed_student = course.enroll_student(User.create!, workflow_state: "active").user
        assessing_student = course.enroll_student(User.create!, workflow_state: "active").user

        assignment = course.assignments.create!(peer_reviews: true)
        rubric_association = rubric_association_model(context: course, association_object: assignment, purpose: "grading")

        submission = assignment.submission_for_student(assessed_student)
        submission.assessment_requests.create!(
          user: assessed_student,
          assessor: assessing_student,
          assessor_asset: assignment.submission_for_student(assessing_student)
        )
        peer_review_assessment = rubric_association.rubric_assessments.create!({
                                                                                 artifact: submission,
                                                                                 assessment_type: "grading",
                                                                                 assessor: assessing_student,
                                                                                 rubric: rubric_association.rubric,
                                                                                 user: assessed_student
                                                                               })

        expect(submission.visible_rubric_assessments_for(assessing_student)).to include(peer_review_assessment)
      end
    end

    it "returns the rubric assessments if user can :read_grade" do
      expect(subject).to contain_exactly(@teacher_assessment, @student_assessment)
    end

    it "returns the rubric assessments if the submission is posted" do
      @submission.update!(posted_at: Time.zone.now)
      expect(subject).to contain_exactly(@teacher_assessment, @student_assessment)
    end

    it "does not return rubric assessments if assignment has no rubric" do
      @assignment.rubric_association.destroy!

      expect(subject).not_to include(@teacher_assessment)
    end

    it "only returns rubric assessments from associated rubrics" do
      other = @rubric_association.dup
      other.save!
      other_assessment = other.rubric_assessments.create!({
                                                            artifact: @submission,
                                                            assessment_type: "grading",
                                                            assessor: @teacher,
                                                            rubric: @rubric,
                                                            user: @assessed_user
                                                          })

      expect(subject).to eq([other_assessment])
    end

    context "attempt argument" do
      before(:once) do
        @submission2 = @assignment.submit_homework(@student, body: "bar", submitted_at: 1.hour.since)
      end

      it "returns an empty list if no rubric assessments exist for the desired attempt" do
        expect(
          @submission2.visible_rubric_assessments_for(@viewing_user, attempt: @submission2.attempt)
        ).to be_empty
      end

      it "can find historic rubric assessments of older attempts" do
        expect(
          @submission2.visible_rubric_assessments_for(@viewing_user, attempt: @submission.attempt)
        ).to contain_exactly(@teacher_assessment, @student_assessment)
      end

      it "returns assessments for every attempt if attempt is nil" do
        @teacher_assessment.update!(artifact_attempt: 0)
        @student_assessment.update!(artifact_attempt: 1)
        expect(
          @submission2.visible_rubric_assessments_for(@viewing_user, attempt: nil)
        ).to contain_exactly(@teacher_assessment, @student_assessment)
      end

      it "specifically returns assessments with a nil artifact_attempt if an attempt of 0 is specified" do
        assignment = @course.assignments.create!(submission_types: "online_text_entry")
        rubric_association = rubric_association_model(association_object: assignment, purpose: "grading")
        submission = assignment.submission_for_student(@student)

        assessment_before_submitting = rubric_association.rubric_assessments.create!({
                                                                                       artifact: submission,
                                                                                       assessment_type: "grading",
                                                                                       assessor: @student,
                                                                                       rubric: rubric_association.rubric,
                                                                                       user: @student
                                                                                     })

        submission = assignment.submit_homework(@student, body: "hi")

        rubric_association.rubric_assessments.create!({
                                                        artifact: submission,
                                                        assessment_type: "grading",
                                                        assessor: @teacher,
                                                        rubric: rubric_association.rubric,
                                                        user: @student
                                                      })

        expect(submission.visible_rubric_assessments_for(@student, attempt: 0))
          .to contain_exactly(assessment_before_submitting)
      end
    end

    context "anonymous peer reviews" do
      before(:once) do
        course = Course.create!
        @reviewed_student = course.enroll_student(User.create!, workflow_state: "active").user
        @reviewing_student = course.enroll_student(User.create!, workflow_state: "active").user
        @grading_teacher = course.enroll_teacher(User.create!, workflow_state: "active").user

        assignment = course.assignments.create!(peer_reviews: true, anonymous_peer_reviews: true)
        rubric_association = rubric_association_model(context: course, association_object: assignment, purpose: "grading")

        @submission = assignment.submission_for_student(@reviewed_student)
        @submission.assessment_requests.create!(
          user: @reviewed_student,
          assessor: @reviewing_student,
          assessor_asset: assignment.submission_for_student(@reviewing_student)
        )
        rubric_association.rubric_assessments.create!({
                                                        artifact: @submission,
                                                        assessment_type: "peer_review",
                                                        assessor: @reviewing_student,
                                                        rubric: rubric_association.rubric,
                                                        user: @reviewed_student
                                                      })

        rubric_association.rubric_assessments.create!({
                                                        artifact: @submission,
                                                        assessment_type: "grading",
                                                        assessor: @grading_teacher,
                                                        rubric: rubric_association.rubric,
                                                        user: @reviewed_student
                                                      })
      end

      it "viewed by reviewed_student include rubric assessments from teachers with identity attached" do
        expect(@submission.visible_rubric_assessments_for(@reviewed_student)[0].assessor).to eql(@grading_teacher)
      end

      it "viewed by reviewed_student does not include peer reviewer's identity when viewed by the reviewee" do
        expect(@submission.visible_rubric_assessments_for(@reviewed_student)[1].assessor).to be_nil
      end

      it "includes peer reviewer's identity when viewed by the reviewer" do
        expect(@submission.visible_rubric_assessments_for(@reviewing_student)[0].assessor).to eql(@reviewing_student)
      end
    end
  end

  describe "#rubric_assessment" do
    let(:submission) { @assignment.submission_for_student(@student) }

    it "excludes non-grading assessments" do
      grading_rubric_association = rubric_association_model(association_object: @assignment, purpose: "grading")
      grading_assessment = grading_rubric_association.rubric_assessments.create!(
        artifact: submission,
        assessment_type: "grading",
        assessor: @teacher,
        rubric: grading_rubric_association.rubric,
        user: @student
      )

      non_grading_rubric_association = rubric_association_model(association_object: @assignment, purpose: "pleasurable event")
      non_grading_rubric_association.rubric_assessments.create!(
        artifact: submission,
        assessment_type: "pleasurable event",
        assessor: @teacher,
        rubric: non_grading_rubric_association.rubric,
        user: @student
      )

      expect(submission.rubric_assessment).to eq grading_assessment
    end

    it "prioritizes assessments with a non-nil rubric_association when multiple grading assessments exist" do
      old_rubric_association = rubric_association_model(association_object: @assignment, purpose: "grading")
      old_assessment = old_rubric_association.rubric_assessments.create!(
        artifact: submission,
        assessment_type: "grading",
        assessor: @teacher,
        rubric: old_rubric_association.rubric,
        user: @student
      )
      old_rubric_association.destroy

      new_rubric_association = rubric_association_model(association_object: @assignment, purpose: "grading")
      new_assessment = new_rubric_association.rubric_assessments.create!(
        artifact: submission,
        assessment_type: "grading",
        assessor: @teacher,
        rubric: new_rubric_association.rubric,
        user: @student
      )

      aggregate_failures do
        expect(submission.rubric_assessments).to contain_exactly(old_assessment, new_assessment)
        expect(submission.rubric_assessment).to eq new_assessment
      end
    end
  end

  describe "#add_comment" do
    before(:once) do
      submission_spec_model
    end

    it "creates a draft comment when passed true in the draft_comment option" do
      comment = @submission.add_comment(author: @teacher, comment: "42", draft_comment: true)

      expect(comment).to be_draft
    end

    it "creates a final comment when not passed in a draft_comment option" do
      comment = @submission.add_comment(author: @teacher, comment: "42")

      expect(comment).not_to be_draft
    end

    it "creates a final comment when passed false in the draft_comment option" do
      comment = @submission.add_comment(author: @teacher, comment: "42", draft_comment: false)

      expect(comment).not_to be_draft
    end

    it "creates a comment without an author when skip_author option is true" do
      comment = @submission.add_comment(comment: "42", skip_author: true)

      expect(comment.author).to be_nil
    end

    it "allows you to specify submission attempt for the comment" do
      @submission.update!(attempt: 4)
      comment = @submission.add_comment(author: @teacher, comment: "42", attempt: 3)
      expect(comment.attempt).to eq 3
    end

    it "sets the attempt to latest submission attempt when an attempt option is not specified" do
      @submission.update!(attempt: 5, workflow_state: "graded")
      comment = @submission.add_comment(author: @teacher, comment: "42")
      expect(comment.attempt).to eq 5
    end

    it "sets comment hidden to false if comment causes posting" do
      @assignment.ensure_post_policy(post_manually: false)
      @assignment.grade_student(@student, grader: @teacher, score: 5)
      @submission.update!(posted_at: nil)
      comment = @submission.add_comment(author: @teacher, comment: "a comment!", hidden: true)
      expect(comment).not_to be_hidden
    end

    it "does not set comment hidden to false if comment does not cause posting" do
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.grade_student(@student, grader: @teacher, score: 5)
      @submission.update!(posted_at: nil)
      comment = @submission.add_comment(author: @teacher, comment: "a comment!", hidden: true)
      expect(comment).to be_hidden
    end

    describe "audit event logging" do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(title: "ok", anonymous_grading: true) }
      let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
      let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
      let(:submission) { assignment.submissions.find_by!(user: student) }
      let(:comment_params) { { comment: "my great submission", author: student } }
      let(:last_event) { AnonymousOrModerationEvent.where(assignment:, submission:).last }

      context "for an auditable assignment" do
        it "creates an event when a non-draft comment is published" do
          expect { submission.add_comment(comment_params) }.to change {
            AnonymousOrModerationEvent.where(assignment:, submission:).count
          }.by(1)
        end

        it 'sets "submission_comment_created" as the event type' do
          submission.add_comment(comment_params)
          expect(last_event.event_type).to eq "submission_comment_created"
        end

        it "sets the user ID to the author of the comment" do
          submission.add_comment(comment_params)
          expect(last_event.user_id).to eq student.id
        end

        it "does not create events for draft comments" do
          draft_params = comment_params.merge(draft_comment: true)
          expect { submission.add_comment(draft_params) }.not_to change {
            AnonymousOrModerationEvent.where(assignment:, submission:).count
          }
        end

        describe "auditable attributes" do
          it 'captures the value of the "comment" attribute' do
            submission.add_comment(comment_params)
            expect(last_event.payload["comment"]).to eq "my great submission"
          end

          it 'captures the value of the "author_id" attribute' do
            submission.add_comment(comment_params)
            expect(last_event.payload["author_id"]).to eq student.id
          end

          it 'captures the value of the "media_comment_id" attribute' do
            submission.add_comment(comment_params.merge(media_comment_id: 12))
            expect(last_event.payload["media_comment_id"]).to eq "12"
          end

          it 'captures the value of the "media_comment_type" attribute' do
            submission.add_comment(comment_params.merge(media_comment_type: "audio"))
            expect(last_event.payload["media_comment_type"]).to eq "audio"
          end

          it 'captures the value of the "group_comment_id" attribute' do
            submission.add_comment(comment_params.merge(group_comment_id: 12))
            expect(last_event.payload["group_comment_id"]).to eq "12"
          end

          it 'captures the value of the "assessment_request" attribute' do
            assessment_request = submission.assessment_requests.create!(
              user: student,
              assessor: student,
              assessor_asset: submission
            )
            submission.add_comment(comment_params.merge(assessment_request:))
            expect(last_event.payload["assessment_request_id"]).to eq assessment_request.id
          end

          it 'captures the value of the "attachments" attribute' do
            attachment = Attachment.create!(
              filename: "my_great_file.txt",
              uploaded_data: StringIO.new("hello!"),
              context: course
            )
            submission.add_comment(comment_params.merge(attachments: [attachment]))
            expect(last_event.payload["attachment_ids"]).to eq attachment.id.to_s
          end

          it 'captures the value of the "anonymous" attribute' do
            assignment.update!(anonymous_peer_reviews: true)
            submission.add_comment(comment_params)
            expect(last_event.payload["anonymous"]).to be true
          end

          it 'captures the value of the "provisional_grade_id" attribute' do
            assignment.update!(moderated_grading: true, final_grader: teacher, grader_count: 1)
            provisional_grade = submission.find_or_create_provisional_grade!(teacher)

            provisional_comment_params = comment_params.merge(provisional: true, author: teacher)
            submission.add_comment(provisional_comment_params)
            expect(last_event.payload["provisional_grade_id"]).to eq provisional_grade.id
          end
        end

        describe "external tool autograding" do
          let(:external_tool) do
            Account.default.context_external_tools.create!(
              name: "Undertow",
              url: "http://www.example.com",
              consumer_key: "12345",
              shared_secret: "secret"
            )
          end

          it "creates an event when graded by an external tool" do
            expect { assignment.grade_student(student, grader_id: -external_tool.id, score: 80) }.to change {
              AnonymousOrModerationEvent.where(assignment:, submission:).count
            }.by(1)
          end
        end

        describe "quiz autograding" do
          let(:quiz) do
            quiz = course.quizzes.create!
            quiz.workflow_state = "available"
            quiz.quiz_questions.create!({ question_data: test_quiz_data.first })
            quiz.save!
            quiz.assignment.updating_user = teacher
            quiz.assignment.update_attribute(:anonymous_grading, true)
            quiz
          end
          let(:quiz_assignment) { quiz.assignment }
          let(:quiz_submission) do
            qsub = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(student)
            qsub.quiz_data = test_quiz_data
            qsub.started_at = 1.minute.ago
            qsub.attempt = 1
            qsub.submission_data = [{ points: 0, text: "7051", question_id: 128, correct: false, answer_id: 7051 }]
            qsub.score = 0
            qsub.save!
            qsub.finished_at = Time.now.utc
            qsub.workflow_state = "complete"
            qsub.submission = quiz.assignment.find_or_create_submission(student)
            qsub
          end

          it "creates an event when graded by a quiz" do
            real_submission = quiz_submission.submission
            real_submission.audit_grade_changes = true
            expect { quiz_submission.with_versioning(true) { quiz_submission.save! } }.to change {
              AnonymousOrModerationEvent.where(assignment: quiz_assignment, submission: real_submission).count
            }.by(1)
          end
        end
      end

      it "does not create audit events when the assignment is not auditable" do
        assignment1 = course.assignments.create!(title: "ok", anonymous_grading: false)
        submission1 = assignment1.submission_for_student(student)
        expect { submission1.add_comment(comment_params) }.not_to change {
          AnonymousOrModerationEvent.where(assignment:, submission:).count
        }
      end
    end

    describe "submission posting" do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(title: "ok") }
      let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
      let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
      let(:submission) { assignment.submissions.find_by!(user: student) }
      let(:comment_params) { { comment: "oh no", author: teacher } }

      context "when the submission is unposted" do
        it "posts the submission if the comment is from an instructor in the course" do
          submission.add_comment(comment_params)
          expect(submission).to be_posted
        end

        it "posts the submission if the comment is from an admin" do
          admin = User.create!
          course.root_account.account_users.create!(user: admin)
          submission.add_comment(comment_params.merge({ author: admin }))
          expect(submission).to be_posted
        end

        it "does not post the submission if the comment is not from an instructor or admin" do
          submission.add_comment(comment_params.merge({ author: student }))
          expect(submission).not_to be_posted
        end

        it "does not post the submission if the comment is a draft" do
          submission.add_comment(comment_params.merge({ draft_comment: true }))
          expect(submission).not_to be_posted
        end

        it "does not post the submission if the comment has no author" do
          comment_params.delete(:author)
          submission.add_comment(comment_params)
          expect(submission).not_to be_posted
        end

        it "does not post the submission if the comment is provisional" do
          moderated_assignment = course.assignments.create!(
            title: "aa",
            moderated_grading: true,
            final_grader: teacher,
            grader_count: 2
          )

          moderated_submission = moderated_assignment.submission_for_student(student)
          moderated_submission.add_comment(comment_params.merge({ provisional: true }))
          expect(moderated_submission).not_to be_posted
        end

        it "does not post the submission if the assignment is manually-posted" do
          assignment.ensure_post_policy(post_manually: true)
          submission.add_comment(comment_params)
          expect(submission).not_to be_posted
        end

        it "does not post the submission if post policies are not enabled and the assignment is muted" do
          assignment.mute!
          expect(submission).not_to be_posted
        end
      end

      it "does not update the posted_at date if a submission is already posted" do
        submission.update!(posted_at: 1.day.ago)

        expect do
          submission.add_comment(comment_params)
        end.not_to change {
          assignment.submission_for_student(student).posted_at
        }
      end
    end
  end

  describe "#last_teacher_comment" do
    before(:once) do
      submission_spec_model
    end

    it "returns the last published comment made by the teacher" do
      @submission.add_comment(author: @teacher, comment: "a comment")
      expect(@submission.last_teacher_comment).to be_present
    end

    it "does not include draft comments" do
      @submission.add_comment(author: @teacher, comment: "a comment", draft_comment: true)
      expect(@submission.last_teacher_comment).to be_nil
    end
  end

  describe "#ensure_grader_can_grade" do
    before do
      @submission = Submission.new
    end

    context "when #grader_can_grade? returns true" do
      before do
        expect(@submission).to receive(:grader_can_grade?).and_return(true)
      end

      it "returns true" do
        expect(@submission.ensure_grader_can_grade).to be_truthy
      end

      it "does not add any errors to @submission" do
        @submission.ensure_grader_can_grade

        expect(@submission.errors.full_messages).to be_empty
      end
    end

    context "when #grader_can_grade? returns false" do
      before do
        expect(@submission).to receive(:grader_can_grade?).and_return(false)
      end

      it "returns false" do
        expect(@submission.ensure_grader_can_grade).to be_falsey
      end

      it "adds an error to the :grade field" do
        @submission.ensure_grader_can_grade

        expect(@submission.errors[:grade]).not_to be_empty
      end

      describe "skip_grader_check" do
        it "does not add an error to the :grade field if skip_grader_check is true" do
          @submission.skip_grader_check = true
          @submission.ensure_grader_can_grade
          expect(@submission.errors[:grade]).to be_empty
        end

        it "adds an error to the :grade field if skip_grader_check is false" do
          @submission.skip_grader_check = false
          @submission.ensure_grader_can_grade
          expect(@submission.errors[:grade]).not_to be_empty
        end

        it "adds an error to the :grade field if skip_grader_check is not set" do
          @submission.ensure_grader_can_grade
          expect(@submission.errors[:grade]).not_to be_empty
        end
      end
    end
  end

  describe "#grader_can_grade?" do
    before do
      @submission = Submission.new
    end

    it "returns true if grade hasn't been changed" do
      expect(@submission).to receive(:grade_changed?).and_return(false)

      expect(@submission.grader_can_grade?).to be_truthy
    end

    it "returns true if the submission is autograded and the submission can be autograded" do
      expect(@submission).to receive(:grade_changed?).and_return(true)

      expect(@submission).to receive(:autograded?).and_return(true)
      expect(@submission).to receive(:can_autograde?).and_return(true)

      expect(@submission.grader_can_grade?).to be_truthy
    end

    it "returns true if the submission isn't autograded but can still be graded" do
      expect(@submission).to receive(:grade_changed?).and_return(true)
      expect(@submission).to receive(:autograded?).and_return(false)

      @submission.grader = @grader = User.new

      expect(@submission).to receive(:grants_right?).with(@grader, :grade).and_return(true)

      expect(@submission.grader_can_grade?).to be_truthy
    end

    it "returns false if the grade changed but the submission can't be graded at all" do
      @submission.grader = @grader = User.new

      expect(@submission).to receive(:grade_changed?).and_return(true)
      expect(@submission).to receive(:autograded?).and_return(false)
      expect(@submission).to receive(:grants_right?).with(@grader, :grade).and_return(false)

      expect(@submission.grader_can_grade?).to be_falsey
    end
  end

  describe "#submission_history" do
    let!(:student) { student_in_course(active_all: true).user }
    let(:attachment) { attachment_model(filename: "submission-a.doc", context: student) }
    let(:submission) { @assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment]) }

    it "includes originality data" do
      OriginalityReport.create!(submission:, attachment:, originality_score: 1.0, workflow_state: "pending")
      submission.originality_reports.load_target
      expect(submission.submission_history.first.turnitin_data[attachment.asset_string][:similarity_score]).to eq 1.0
    end

    it "doesn't include the originality_data if originality_report isn't pre loaded" do
      OriginalityReport.create!(submission:, attachment:, originality_score: 1.0, workflow_state: "pending")
      expect(submission.submission_history.first.turnitin_data[attachment.asset_string]).to be_nil
    end

    it "returns self as complete history when no history record is present" do
      student.submissions.destroy_all

      create_sql = "INSERT INTO #{Submission.quoted_table_name}
                     (assignment_id, user_id, workflow_state, created_at, updated_at, course_id)
                     values
                     (#{@assignment.id}, #{student.id}, 'unsubmitted', now(), now(), #{@assignment.context_id})"

      sub = Submission.find(Submission.connection.create(create_sql))
      expect(sub.submission_history).to eq([sub])
    end
  end

  describe "#comments_excluding_drafts_for" do
    before do
      @teacher = course_with_user("TeacherEnrollment", course: @course, name: "Teacher", active_all: true).user
      ta = course_with_user("TaEnrollment", course: @course, name: "First Ta", active_all: true).user
      student = course_with_user("StudentEnrollment", course: @course, name: "Student", active_all: true).user
      assignment = @course.assignments.create!(name: "plain assignment")
      assignment.ensure_post_policy(post_manually: true)
      @submission = assignment.submissions.find_by(user: student)
      @student_comment = @submission.add_comment(author: student, comment: "Student comment")
      @teacher_comment = @submission.add_comment(author: @teacher, comment: "Teacher comment", draft_comment: true)
      @ta_comment = @submission.add_comment(author: ta, comment: "Ta comment")
    end

    it "returns non-draft comments, filtering out draft comments" do
      comments = @submission.comments_excluding_drafts_for(@teacher)
      expect(comments).to include @student_comment, @ta_comment
      expect(comments).not_to include @teacher_comment
    end

    context "when comments are preloaded" do
      it "returns non-draft comments, filtering out draft comments" do
        preloaded_submission = Submission.where(id: @submission.id).preload(:submission_comments).first
        comments = preloaded_submission.comments_excluding_drafts_for(@teacher)
        expect(comments).to include @student_comment, @ta_comment
        expect(comments).not_to include @teacher_comment
      end
    end
  end

  describe "#feedback_for_current_attempt?" do
    before(:once) do
      @teacher = course_with_user("TeacherEnrollment", course: @course, name: "Teacher", active_all: true).user
      @student = course_with_user("StudentEnrollment", course: @course, name: "Student", active_all: true).user
      @peer = course_with_user("StudentEnrollment", course: @course, name: "Peer", active_all: true).user
      @assignment = @course.assignments.create!(name: "HasFeedback Assignment")
      @submission = @assignment.submissions.find_by(user: @student)
    end

    it "is true when a teacher leaves a comment" do
      @submission.attempt = 1
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: 1)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is true when a peer leaves a comment" do
      @submission.attempt = 1
      @submission.add_comment(author: @peer, comment: "Peer comment", attempt: 1)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is true when a teacher leaves a comment on the latest attempt" do
      @submission.attempt = 3
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: 3)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is true when a teacher has left a comment prior to the first attempt (nil)" do
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: nil)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is true when a teacher has left a comment prior to the first attempt (zero)" do
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: 0)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is true when a teacher leaves a comment prior to the first attempt and it has been submitted" do
      @submission.attempt = 1
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: nil)
      expect(@submission).to be_feedback_for_current_attempt
    end

    it "is false when no comments exist" do
      expect(@submission).not_to be_feedback_for_current_attempt
    end

    it "is false when a teacher leaves comment on prior attempt" do
      @submission.attempt = 2
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: 1)
      expect(@submission).not_to be_feedback_for_current_attempt
    end

    it "is false when a teacher leaves a comment prior to first attempt and a second is started" do
      @submission.attempt = 2
      @submission.add_comment(author: @teacher, comment: "Teacher comment", attempt: nil)
      expect(@submission).not_to be_feedback_for_current_attempt
    end

    it "is false when a peer leaves comment on prior attempt" do
      @submission.attempt = 2
      @submission.add_comment(author: @peer, comment: "Peer comment", attempt: 1)
      expect(@submission).not_to be_feedback_for_current_attempt
    end

    it "is false when only submitter has commented on the current attempt" do
      @submission.attempt = 1
      @submission.add_comment(author: @student, comment: "Student comment", attempt: 1)
      expect(@submission).not_to be_feedback_for_current_attempt
    end
  end

  describe "#visible_submission_comments_for" do
    before(:once) do
      @teacher = course_with_user("TeacherEnrollment", course: @course, name: "Teacher", active_all: true).user
      @first_ta = course_with_user("TaEnrollment", course: @course, name: "First Ta", active_all: true).user
      @second_ta = course_with_user("TaEnrollment", course: @course, name: "Second Ta", active_all: true).user
      @third_ta = course_with_user("TaEnrollment", course: @course, name: "Third Ta", active_all: true).user
      @student = course_with_user("StudentEnrollment", course: @course, name: "Student", active_all: true).user
      @admin = account_admin_user(account: @course.account)

      @assignment = @course.assignments.create!(name: "plain assignment")
      @assignment.ensure_post_policy(post_manually: true)

      @submission = @assignment.submissions.find_by(user: @student)
      @student_comment = @submission.add_comment(author: @student, comment: "Student comment")
      @teacher_comment = @submission.add_comment(author: @teacher, comment: "Teacher comment")
      @first_ta_comment = @submission.add_comment(author: @first_ta, comment: "First Ta comment")
    end

    it "shows teacher all comments" do
      comments = @submission.visible_submission_comments_for(@teacher)
      expect(comments).to match_array([@student_comment, @teacher_comment, @first_ta_comment])
    end

    it "shows ta all comments" do
      comments = @submission.visible_submission_comments_for(@first_ta)
      expect(comments).to match_array([@student_comment, @teacher_comment, @first_ta_comment])
    end

    it "shows student all comments, when submission is posted" do
      @submission.update!(posted_at: Time.zone.now)
      comments = @submission.visible_submission_comments_for(@student)
      expect(comments).to match_array([@student_comment, @teacher_comment, @first_ta_comment])
    end

    it "shows student only their own comment, when submission is unposted" do
      comments = @submission.visible_submission_comments_for(@student)
      expect(comments).to match_array([@student_comment])
    end

    context "for an assignment with peer reviews" do
      let_once(:assignment) do
        @course.assignments.create!(name: "peer review assignment", peer_reviews: true, muted: true)
      end

      before(:once) do
        assignment.ensure_post_policy(post_manually: true)
        @submission = assignment.submissions.find_by(user: @student)
        @student2 = course_with_user("StudentEnrollment", course: @course, name: "Student2", active_all: true).user
        student2_sub = assignment.submissions.find_by(user: @student2)
        student2_request = AssessmentRequest.create!(assessor: @student2, assessor_asset: student2_sub, asset: @submission, user: @student)
        @teacher_comment = @submission.add_comment(author: @teacher, comment: "A teacher comment")
        @peer_review_comment = @submission.add_comment(author: @student2, comment: "A peer reviewer's comment", assessment_request: student2_request)
        @student_comment = @submission.add_comment(author: @student, comment: "A comment by the submitter")
      end

      context "when grades are hidden" do
        before(:once) do
          other_assessor = @course.enroll_student(User.create!(name: "Student3")).user
          other_request = AssessmentRequest.create!(
            assessor: other_assessor,
            assessor_asset: @assignment.submission_for_student(other_assessor),
            asset: @submission,
            user: @student
          )
          @alternate_assessment_comment = @submission.add_comment(author: other_assessor, comment: "Other assessment", assessment_request: other_request)
        end

        it "shows the submitting student their own comments and any peer review comments" do
          comments = @submission.visible_submission_comments_for(@student)
          expect(comments).to match_array([@peer_review_comment, @student_comment, @alternate_assessment_comment])
        end

        it "shows a peer-reviewing student only their own comments" do
          comments = @submission.visible_submission_comments_for(@student2)
          expect(comments).to match_array([@peer_review_comment])
        end
      end

      context "when grades have been posted" do
        before(:once) do
          assignment.post_submissions
        end

        it "shows the submitting student comments from all users" do
          comments = @submission.visible_submission_comments_for(@student)
          expect(comments).to match_array([@peer_review_comment, @student_comment, @teacher_comment])
        end

        it "shows a peer-reviewing student only their own comments" do
          comments = @submission.visible_submission_comments_for(@student2)
          expect(comments).to match_array([@peer_review_comment])
        end
      end
    end

    context "when assignment is graded as a group" do
      let_once(:all_groups) { @course.group_categories.create!(name: "all groups") }

      before(:once) do
        student2 = course_with_user("StudentEnrollment", course: @course, name: "Student2", active_all: true).user
        group1 = all_groups.groups.create!(context: @course)
        group1.add_user(@student)
        group1.add_user(student2)
        assignment = @course.assignments.create!(
          grade_group_students_individually: false,
          group_category: all_groups,
          name: "group assignment"
        )
        @submission = assignment.submissions.find_by(user: @student)
        @student_comment = @submission.add_comment(author: @student, comment: "Student comment", group_comment_id: group1.id)
        @student2_comment = @submission.add_comment(author: student2, comment: "Student2 comment", group_comment_id: group1.id)
      end

      it "returns comments scoped to that group" do
        comments = @submission.visible_submission_comments_for(@teacher)
        expect(comments).to match_array([@student_comment, @student2_comment])
      end

      context "when peer reviews are enabled" do
        before(:once) do
          @student = @course.enroll_student(User.create!, enrollment_state: "active").user
          @student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
          all_groups.groups.create!(context: @course).add_user(@student)
          all_groups.groups.create!(context: @course).add_user(@student2)
          assignment = @course.assignments.create!(
            grade_group_students_individually: false,
            group_category: all_groups,
            name: "group assignment",
            peer_reviews: true
          )
          @submission = assignment.submissions.find_by(user: @student)
          student2_sub = assignment.submissions.find_by(user: @student2)
          AssessmentRequest.create!(
            assessor: @student2,
            assessor_asset: student2_sub,
            asset: @submission,
            user: @student
          )
          @peer_review_comment = @submission.add_comment(author: @student2, comment: "Student2", group_comment_id: "ab")
          @student_comment = @submission.add_comment(author: @student, comment: "Student", group_comment_id: "ac")
          @teacher_comment = @submission.add_comment(author: @teacher, comment: "Teacher", group_comment_id: "ad")
        end

        it "shows a peer reviewer only their own comments" do
          comments = @submission.visible_submission_comments_for(@student2)
          expect(comments).to match_array([@peer_review_comment])
        end

        it "shows all comments to the submitting student" do
          comments = @submission.visible_submission_comments_for(@student)
          expect(comments).to match_array([@peer_review_comment, @student_comment, @teacher_comment])
        end

        it "shows all comments to a teacher" do
          comments = @submission.visible_submission_comments_for(@teacher)
          expect(comments).to match_array([@peer_review_comment, @student_comment, @teacher_comment])
        end
      end
    end

    context "when the assignment is a group peer-reviewed assignment" do
      let_once(:student1) { @course.enroll_student(User.create!, active_all: true).user }
      let_once(:student2) { @course.enroll_student(User.create!, active_all: true).user }
      let_once(:student3) { @course.enroll_student(User.create!, active_all: true).user }
      let_once(:student4) { @course.enroll_student(User.create!, active_all: true).user }

      let_once(:group_category) do
        group_category = @course.group_categories.create!(name: "a group")
        group_category.create_groups(3)

        group_category.groups.first.add_user(student1)
        group_category.groups.second.add_user(student2)
        group_category.groups.second.add_user(student3)
        group_category.groups.third.add_user(student4)
        group_category
      end

      let_once(:assignment) do
        @course.assignments.create!(group_category:, peer_reviews: true)
      end

      before(:once) do
        assignment.submit_homework(student1, body: "I am student 1")
        assignment.submit_homework(student2, body: "I am student 2")
        assignment.submit_homework(student3, body: "I am student 3")
        assignment.submit_homework(student4, body: "I am student 4")

        assignment.assign_peer_review(student1, student2)
        assignment.assign_peer_review(student1, student4)
      end

      context "when the assignment is manually posted" do
        before(:once) do
          assignment.post_policy.update!(post_manually: true)

          # Call update_submission to post the comment (rather than add_comment)
          # so that it gets propagated to other group members
          student2_submission_params = {
            assessment_request: AssessmentRequest.find_by(assessor: student1, user: student2),
            author: student1,
            comment: "good job",
            group_comment: true
          }
          assignment.update_submission(student2, student2_submission_params)

          student4_submission_params = {
            assessment_request: AssessmentRequest.find_by(assessor: student1, user: student4),
            author: student1,
            comment: "bad job",
            group_comment: true
          }
          assignment.update_submission(student4, student4_submission_params)
        end

        it "allows the specific recipient of the comment to view it" do
          comment = SubmissionComment.find_by(submission: assignment.submission_for_student(student2), author: student1)

          expect(comment).to be_grants_right(student2, :read)
        end

        it "allows other students in the recipient's group to view their respective comment" do
          comment = SubmissionComment.find_by(submission: assignment.submission_for_student(student3), author: student1)

          expect(comment).to be_grants_right(student3, :read)
        end

        it "does not allow assessed students in a different group to view the comment" do
          comment = SubmissionComment.find_by(submission: assignment.submission_for_student(student2), author: student1)

          expect(comment).not_to be_grants_right(student4, :read)
        end
      end
    end

    context "for a moderated assignment" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "moderated assignment",
          moderated_grading: true,
          grader_count: 10,
          final_grader: @teacher
        )
        @assignment.grade_student(@student, grade: 1, grader: @first_ta, provisional: true)
        @assignment.grade_student(@student, grade: 1, grader: @second_ta, provisional: true)
        @assignment.grade_student(@student, grade: 1, grader: @teacher, provisional: true)
        @submission = @assignment.submissions.find_by(user: @student)
        @student_comment = @submission.add_comment(author: @student, comment: "Student comment")
        @first_ta_comment = @submission.add_comment(author: @first_ta, comment: "First Ta comment", provisional: true)
        @second_ta_comment = @submission.add_comment(author: @second_ta, comment: "Second Ta comment", provisional: true)
        @third_ta_comment = @submission.add_comment(author: @third_ta, comment: "Third Ta comment", provisional: true)
        @final_grader_comment = @submission.add_comment(author: @teacher, comment: "Final Grader comment", provisional: true)
      end

      context "when graders can view other graders' comments" do
        context "when grades are unpublished" do
          it "shows final grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@teacher)
            expect(comments).to match_array([
                                              @student_comment,
                                              @first_ta_comment,
                                              @second_ta_comment,
                                              @third_ta_comment,
                                              @final_grader_comment
                                            ])
          end

          it "shows provisional grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@first_ta)
            expect(comments).to match_array([
                                              @student_comment,
                                              @first_ta_comment,
                                              @second_ta_comment,
                                              @third_ta_comment,
                                              @final_grader_comment
                                            ])
          end

          it "shows student only their own comments" do
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments).to match_array([@student_comment])
          end

          it "shows admins all submission comments" do
            comments = @submission.visible_submission_comments_for(@admin)
            expect(comments).to match_array([
                                              @student_comment,
                                              @first_ta_comment,
                                              @second_ta_comment,
                                              @third_ta_comment,
                                              @final_grader_comment
                                            ])
          end
        end

        context "when grades are published" do
          before(:once) do
            ModeratedGrading::ProvisionalGrade.find_by(submission: @submission, scorer: @first_ta).publish!
            @assignment.update!(grades_published_at: Time.zone.now)
            @submission.reload
          end

          it "shows final grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@teacher)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Third Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows provisional grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@first_ta)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Third Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows student only their own comments" do
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments).to match_array([@student_comment])
          end

          it "when grades are posted, shows student their own, chosen grader's, and final grader's comments" do
            @assignment.post_submissions
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows admins all submission comments" do
            comments = @submission.visible_submission_comments_for(@admin)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Third Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end
        end
      end

      context "when graders cannot view other graders' comments" do
        before(:once) do
          @assignment.update!(grader_comments_visible_to_graders: false)
        end

        context "when grades are unpublished" do
          it "shows final grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@teacher)
            expect(comments).to match_array([
                                              @student_comment,
                                              @first_ta_comment,
                                              @second_ta_comment,
                                              @third_ta_comment,
                                              @final_grader_comment
                                            ])
          end

          it "shows provisional grader their own and student's" do
            comments = @submission.visible_submission_comments_for(@second_ta)
            expect(comments.pluck(:comment)).to match_array(["Student comment", "Second Ta comment"])
          end

          it "shows student only their own comments" do
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments).to match_array([@student_comment])
          end

          it "shows admins all submission comments" do
            comments = @submission.visible_submission_comments_for(@admin)
            expect(comments).to match_array([
                                              @student_comment,
                                              @first_ta_comment,
                                              @second_ta_comment,
                                              @third_ta_comment,
                                              @final_grader_comment
                                            ])
          end
        end

        context "when grades are published" do
          before(:once) do
            ModeratedGrading::ProvisionalGrade.find_by(submission: @submission, scorer: @first_ta).publish!
            @assignment.update!(grades_published_at: Time.zone.now)
            @submission.reload
          end

          it "shows final grader all submission comments" do
            comments = @submission.visible_submission_comments_for(@teacher)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Third Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows provisional grader their own, student's, chosen grader's, and final grader's comments" do
            comments = @submission.visible_submission_comments_for(@second_ta)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows student only their own comments" do
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments).to match_array([@student_comment])
          end

          it "when grades are posted, shows student own, chosen grader's, and final grader's comments" do
            @assignment.post_submissions
            comments = @submission.visible_submission_comments_for(@student)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end

          it "shows admins all submission comments" do
            comments = @submission.visible_submission_comments_for(@admin)
            expect(comments.pluck(:comment)).to match_array([
                                                              "Student comment",
                                                              "First Ta comment",
                                                              "Second Ta comment",
                                                              "Third Ta comment",
                                                              "Final Grader comment"
                                                            ])
          end
        end
      end
    end
  end

  describe ".needs_grading" do
    before :once do
      @submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "a body")
    end

    it "includes submission that has not been graded" do
      expect(Submission.needs_grading.count).to eq(1)
    end

    it "includes submission by enrolled student" do
      @student.enrollments.take!.complete
      expect(Submission.needs_grading.count).to eq(0)
      @course.enroll_student(@student).accept
      expect(Submission.needs_grading.count).to eq(1)
    end

    it "includes submission by user with multiple enrollments in the course only once" do
      another_section = @course.course_sections.create(name: "two")
      @course.enroll_student(@student, section: another_section, allow_multiple_enrollments: true).accept
      expect(Submission.needs_grading.count).to eq(1)
    end

    it "does not include submission that has been graded" do
      @assignment.grade_student(@student, grade: "100", grader: @teacher)
      expect(Submission.needs_grading.count).to eq(0)
    end

    it "does include submissions that have been graded but the score was reset to nil" do
      @assignment.grade_student(@student, grade: "100", grader: @teacher)
      @assignment.grade_student(@student, grade: nil, grader: @teacher)
      expect(Submission.needs_grading.count).to eq(1)
    end

    it "does not include submission by non-student user" do
      @student.enrollments.take!.complete
      @course.enroll_user(@student, "TaEnrollment").accept
      expect(Submission.needs_grading.count).to eq(0)
    end

    it "does not include excused submissions" do
      @assignment.grade_student(@student, excused: true, grader: @teacher)
      expect(Submission.needs_grading.count).to eq(0)
    end

    it "does not include submissions for inactive/concluded students who have other active enrollments somewhere" do
      @course.enroll_student(@student).update_attribute(:workflow_state, "inactive")
      course_with_student(user: @student, active_all: true)
      expect(Submission.needs_grading).not_to include @assignment.submissions.first
    end

    context "sharding" do
      specs_require_sharding

      it "serializes relative to current scope's shard" do
        @shard1.activate do
          expect(Submission.shard(Shard.default).needs_grading.count).to eq(1)
        end
      end

      it "works with cross shard attachments" do
        @shard1.activate do
          @student = user_factory(active_user: true)
          @attachment = Attachment.create! uploaded_data: StringIO.new("blah"), context: @student, filename: "blah.txt"
        end
        course_factory(active_all: true)
        @course.enroll_user(@student, "StudentEnrollment").accept!
        @assignment = @course.assignments.create!

        sub = @assignment.submit_homework(@user, attachments: [@attachment])
        expect(sub.attachments).to eq [@attachment]
      end

      it "bulk_load_versioned_attachments works with attachments in a different shard" do
        course_factory(active_all: true)
        student = user_factory(active_user: true)
        attachment = attachment_model(filename: "submission.doc", context: student)

        @course.enroll_user(student, "StudentEnrollment").accept!
        assignment = @course.assignments.create!
        submission = assignment.submit_homework(student, attachments: [attachment])
        submission.update_attribute(:attachment_ids, attachment.id.to_s)

        @shard1.activate do
          submission_with_attachments = Submission.bulk_load_versioned_attachments([submission]).first
          expect(submission_with_attachments.versioned_attachments).to eq [attachment]
        end
      end
    end
  end

  describe "#can_view_details?" do
    before do
      @assignment.update!(anonymous_grading: true)
      @submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "a body")
    end

    context "for observers" do
      let(:observer) do
        course_with_observer(
          course: @assignment.course,
          associated_user_id: @submission.user_id,
          active_all: true
        ).user
      end

      it "allows observers of the submission's owner to view details" do
        expect(@submission).to be_can_view_details(observer)
      end

      it "does not allow observers to view details if they're not observing the submission's owner" do
        new_student = User.create!
        @context.enroll_student(new_student, enrollment_state: "active")
        new_student_submission = @assignment.submissions.find_by(user: new_student)
        expect(new_student_submission).not_to be_can_view_details(observer)
      end
    end

    context "for peer reviewers" do
      let(:reviewer) { @context.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
      let(:reviewer_sub) { @assignment.submissions.find_by!(user: reviewer) }

      before do
        @assignment.update!(submission_types: "online_text_entry", peer_reviews: true)
      end

      it "returns false for peer reviewer of student under view that has not submitted" do
        AssessmentRequest.create!(assessor: reviewer, assessor_asset: reviewer_sub, asset: @submission, user: @student)
        expect(@submission.can_view_details?(reviewer)).to be false
      end

      it "returns true for peer reviewer of student under view that has submitted" do
        AssessmentRequest.create!(assessor: reviewer, assessor_asset: reviewer_sub, asset: @submission, user: @student)
        @assignment.submit_homework(reviewer, body: "hi")
        expect(@submission.can_view_details?(reviewer)).to be true
      end

      it "returns false for peer reviewer of student not under view" do
        new_student = @context.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user
        new_student_sub = @assignment.submissions.find_by!(user: new_student)
        expect(new_student_sub.can_view_details?(reviewer)).to be false
      end
    end

    context "when the assignment is muted" do
      it "returns false if user isn't present" do
        expect(@submission).not_to be_can_view_details(nil)
      end

      it "returns true for submitting student if assignment anonymous grading" do
        expect(@submission.can_view_details?(@student)).to be true
      end

      it "returns false for non-submitting student if assignment anonymous grading" do
        new_student = User.create!
        @context.enroll_student(new_student, enrollment_state: "active")
        expect(@submission.can_view_details?(@new_student)).to be false
      end

      it "returns false for teacher if assignment anonymous grading" do
        expect(@submission.can_view_details?(@teacher)).to be false
      end

      it "returns false for admin if assignment anonymous grading" do
        expect(@submission.can_view_details?(account_admin_user)).to be false
      end

      it "returns true for site admin if assignment anonymous grading" do
        expect(@submission.can_view_details?(site_admin_user)).to be true
      end
    end

    context "when the assignment is unmuted" do
      before do
        @assignment.unmute!
      end

      it "returns false if user isn't present" do
        expect(@submission).not_to be_can_view_details(nil)
      end

      it "returns true for submitting student if assignment anonymous grading" do
        expect(@submission.can_view_details?(@student)).to be true
      end

      it "returns false for non-submitting student if assignment anonymous grading" do
        new_student = User.create!
        @context.enroll_student(new_student, enrollment_state: "active")
        expect(@submission.can_view_details?(@new_student)).to be false
      end

      it "returns true for teacher if assignment anonymous grading" do
        expect(@submission.can_view_details?(@teacher)).to be true
      end

      it "returns true for admin if assignment anonymous grading" do
        expect(@submission.can_view_details?(account_admin_user)).to be true
      end

      it "returns true for site admin if assignment anonymous grading" do
        expect(@submission.can_view_details?(site_admin_user)).to be true
      end
    end
  end

  describe "#needs_grading?" do
    before :once do
      @submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "a body")
    end

    it "returns true for submission that has not been graded" do
      expect(@submission.needs_grading?).to be true
    end

    it "returns false for submission that has been graded" do
      @assignment.grade_student(@student, grade: "100", grader: @teacher)
      @submission.reload
      expect(@submission.needs_grading?).to be false
    end

    it "returns true for submission that has been graded but the score was reset to nil" do
      @assignment.grade_student(@student, grade: "100", grader: @teacher)
      @assignment.grade_student(@student, grade: nil, grader: @teacher)
      @submission.reload
      expect(@submission.needs_grading?).to be true
    end

    it "returns true for submission that is pending review" do
      @submission.workflow_state = "pending_review"
      expect(@submission.needs_grading?).to be true
    end

    it "returns false for submission with nil submission_type" do
      @submission.submission_type = nil
      expect(@submission.needs_grading?).to be false
    end
  end

  describe "#plagiarism_service_to_use" do
    it "returns nil when no service is configured" do
      submission = @assignment.submit_homework(@student,
                                               submission_type: "online_text_entry",
                                               body: "whee")

      expect(submission.plagiarism_service_to_use).to be_nil
    end

    it "returns :turnitin when only turnitin is configured" do
      setup_account_for_turnitin(@context.account)
      submission = @assignment.submit_homework(@student,
                                               submission_type: "online_text_entry",
                                               body: "whee")

      expect(submission.plagiarism_service_to_use).to eq(:turnitin)
    end

    it "returns :vericite when only vericite is configured" do
      plugin = Canvas::Plugin.find(:vericite)
      PluginSetting.create!(name: plugin.id, settings: plugin.default_settings, disabled: false)

      submission = @assignment.submit_homework(@student,
                                               submission_type: "online_text_entry",
                                               body: "whee")

      expect(submission.plagiarism_service_to_use).to eq(:vericite)
    end

    it "returns :vericite when both vericite and turnitin are enabled" do
      setup_account_for_turnitin(@context.account)
      plugin = Canvas::Plugin.find(:vericite)
      PluginSetting.create!(name: plugin.id, settings: plugin.default_settings, disabled: false)

      submission = @assignment.submit_homework(@student,
                                               submission_type: "online_text_entry",
                                               body: "whee")

      expect(submission.plagiarism_service_to_use).to eq(:vericite)
    end
  end

  describe "#resubmit_to_vericite" do
    it "calls resubmit_to_plagiarism_later" do
      plugin = Canvas::Plugin.find(:vericite)
      PluginSetting.create!(name: plugin.id, settings: plugin.default_settings, disabled: false)

      submission = @assignment.submit_homework(@student,
                                               submission_type: "online_text_entry",
                                               body: "whee")

      expect(submission).to receive(:submit_to_plagiarism_later).once
      submission.resubmit_to_vericite
    end
  end

  describe "scope: late" do
    before :once do
      @now = Time.zone.now

      ### Quizzes
      @quiz = generate_quiz(@course)
      @quiz_assignment = @quiz.assignment

      @unsubmitted_quiz_submission = @assignment.submissions.create(user: User.create, submission_type: "online_quiz")
      Submission.where(id: @unsubmitted_quiz_submission.id).update_all(submitted_at: nil, cached_due_date: nil)

      @ongoing_unsubmitted_quiz = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_unsubmitted_quiz_submission = @ongoing_unsubmitted_quiz.submission
      @ongoing_unsubmitted_quiz_submission.save!
      Submission.where(id: @ongoing_unsubmitted_quiz_submission.id).update_all(submitted_at: nil)

      @timely_quiz1 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz1_submission = @timely_quiz1.submission
      Submission.where(id: @timely_quiz1_submission.id).update_all(submitted_at: @now, cached_due_date: nil)

      @timely_quiz2 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz2_submission = @timely_quiz2.submission
      Submission.where(id: @timely_quiz2_submission.id).update_all(submitted_at: @now, cached_due_date: @now + 1.hour)

      @timely_quiz3 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz3_submission = @timely_quiz3.submission
      Submission.where(id: @timely_quiz3_submission.id)
                .update_all(submitted_at: @now, cached_due_date: @now - 45.seconds)

      @late_quiz1 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz1_submission = @late_quiz1.submission
      Submission.where(id: @late_quiz1_submission).update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @late_quiz2 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz2_submission = @late_quiz2.submission
      Submission.where(id: @late_quiz2_submission).update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @late_quiz_extended = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz_extended_submission = @late_quiz_extended.submission
      Submission.where(id: @late_quiz_extended_submission).update_all(submitted_at: @now, cached_due_date: @now - 1.hour, late_policy_status: "extended")

      @timely_quiz_marked_late = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz_marked_late_submission = @timely_quiz_marked_late.submission
      Submission.where(id: @timely_quiz_marked_late_submission).update_all(submitted_at: @now, cached_due_date: nil)
      Submission.where(id: @timely_quiz_marked_late_submission).update_all(late_policy_status: "late")

      @ongoing_late_quiz1 = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_late_quiz1_submission = @ongoing_late_quiz1.submission
      @ongoing_late_quiz1_submission.save!
      Submission.where(id: @ongoing_late_quiz1_submission)
                .update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @ongoing_late_quiz2 = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_late_quiz2_submission = @ongoing_late_quiz2.submission
      @ongoing_late_quiz2_submission.save!
      Submission.where(id: @ongoing_late_quiz2_submission)
                .update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @ongoing_timely_quiz_marked_late = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_timely_quiz_marked_late_submission = @ongoing_timely_quiz_marked_late.submission
      @ongoing_timely_quiz_marked_late_submission.save!
      Submission.where(id: @ongoing_timely_quiz_marked_late_submission)
                .update_all(submitted_at: @now, cached_due_date: nil, late_policy_status: "late")

      ### Homeworks
      @unsubmitted_hw = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @unsubmitted_hw.id).update_all(submitted_at: nil, cached_due_date: nil)

      @timely_hw1 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw1.id).update_all(submitted_at: @now, cached_due_date: nil)

      @timely_hw2 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw2.id).update_all(submitted_at: @now, cached_due_date: @now + 1.hour)

      @late_hw1 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw1.id).update_all(submitted_at: @now, cached_due_date: @now - 45.seconds)

      @late_hw2 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw2.id).update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @late_hw3 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw3.id).update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @late_hw_excused = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw_excused.id).update_all(submitted_at: @now, cached_due_date: @now - 1.hour, excused: true)

      @timely_hw_marked_late = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw_marked_late.id).update_all(submitted_at: @now, cached_due_date: nil)
      Submission.where(id: @timely_hw_marked_late.id).update_all(late_policy_status: "late")
      @late_submission_ids = Submission.late.map(&:id)
    end

    ### Quizzes
    it "excludes unsubmitted quizzes" do
      expect(@late_submission_ids).not_to include(@unsubmitted_quiz_submission.id)
    end

    it "excludes ongoing quizzes that have never been submitted before" do
      expect(@late_submission_ids).not_to include(@ongoing_unsubmitted_quiz_submission.id)
    end

    it "excludes quizzes submitted with no due date" do
      expect(@late_submission_ids).not_to include(@timely_quiz1_submission.id)
    end

    it "excludes quizzes submitted before the due date" do
      expect(@late_submission_ids).not_to include(@timely_quiz2_submission.id)
    end

    it "excludes quizzes submitted less than 60 seconds after the due date" do
      expect(@late_submission_ids).not_to include(@timely_quiz3_submission.id)
    end

    it "includes quizzes submitted more than 60 seconds after the due date" do
      expect(@late_submission_ids).to include(@late_quiz1_submission.id)
    end

    it "excludes quizzes that were last submitted more than 60 seconds after the due date but are being retaken" do
      expect(@late_submission_ids).not_to include(@ongoing_late_quiz1_submission.id)
    end

    it "includes quizzes submitted after the due date" do
      expect(@late_submission_ids).to include(@late_quiz2_submission.id)
    end

    it "excludes quizzes that were last submitted after the due date but are being retaken" do
      expect(@late_submission_ids).not_to include(@ongoing_late_quiz2_submission.id)
    end

    it "includes quizzes that have been manually marked as late" do
      expect(@late_submission_ids).to include(@timely_quiz_marked_late_submission.id)
    end

    it "includes quizzes that have been manually marked as late but are being retaken" do
      expect(@late_submission_ids).to include(@ongoing_timely_quiz_marked_late_submission.id)
    end

    it "excludes quizzes that are late but have been marked as extended" do
      expect(@late_submission_ids).not_to include(@late_quiz_extended_submission.id)
    end

    ### Homeworks
    it "excludes an otherwise late submission that has been marked with a custom status" do
      admin = account_admin_user(account: @course.root_account)
      custom_grade_status = @course.root_account.custom_grade_statuses.create!(
        name: "Custom Status",
        color: "#ABC",
        created_by: admin
      )
      expect { @late_hw1.update!(custom_grade_status:) }.to change {
        Submission.late.include?(@late_hw1)
      }.from(true).to(false)
    end

    it "excludes unsubmitted homeworks" do
      expect(@late_submission_ids).not_to include(@unsubmitted_hw.id)
    end

    it "excludes homeworks submitted with no due date" do
      expect(@late_submission_ids).not_to include(@timely_hw1.id)
    end

    it "excludes homeworks submitted before the due date" do
      expect(@late_submission_ids).not_to include(@timely_hw2.id)
    end

    it "includes homeworks submitted less than 60 seconds after the due date" do
      expect(@late_submission_ids).to include(@late_hw1.id)
    end

    it "includes homeworks submitted more than 60 seconds after the due date" do
      expect(@late_submission_ids).to include(@late_hw2.id)
    end

    it "includes homeworks submitted after the due date" do
      expect(@late_submission_ids).to include(@late_hw3.id)
    end

    it "excludes excused homework submitted after the due date" do
      expect(@late_submission_ids).not_to include(@late_hw_excused.id)
    end

    it "includes homeworks that have been manually marked as late" do
      expect(@late_submission_ids).to include(@timely_hw_marked_late.id)
    end
  end

  describe "scope: not_late" do
    before :once do
      @now = Time.zone.now

      ### Quizzes
      @quiz = generate_quiz(@course)
      @quiz_assignment = @quiz.assignment

      @unsubmitted_quiz_submission = @assignment.submissions.create(user: User.create, submission_type: "online_quiz")
      Submission.where(id: @unsubmitted_quiz_submission.id).update_all(submitted_at: nil, cached_due_date: nil)

      @ongoing_unsubmitted_quiz = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_unsubmitted_quiz_submission = @ongoing_unsubmitted_quiz.submission
      @ongoing_unsubmitted_quiz_submission.save!
      Submission.where(id: @ongoing_unsubmitted_quiz_submission.id).update_all(submitted_at: nil)

      @timely_quiz1 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz1_submission = @timely_quiz1.submission
      Submission.where(id: @timely_quiz1_submission.id).update_all(submitted_at: @now, cached_due_date: nil)

      @timely_quiz2 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz2_submission = @timely_quiz2.submission
      Submission.where(id: @timely_quiz2_submission.id).update_all(submitted_at: @now, cached_due_date: @now + 1.hour)

      @timely_quiz3 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz3_submission = @timely_quiz3.submission
      Submission.where(id: @timely_quiz3_submission.id)
                .update_all(submitted_at: @now, cached_due_date: @now - 45.seconds)

      @late_quiz1 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz1_submission = @late_quiz1.submission
      Submission.where(id: @late_quiz1_submission).update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @late_quiz2 = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz2_submission = @late_quiz2.submission
      Submission.where(id: @late_quiz2_submission).update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @late_quiz_extended = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @late_quiz_extended_submission = @late_quiz_extended.submission
      Submission.where(id: @late_quiz_extended_submission).update_all(submitted_at: @now, cached_due_date: @now - 1.hour, late_policy_status: "extended")

      @timely_quiz_marked_late = generate_quiz_submission(@quiz, student: User.create, finished_at: @now)
      @timely_quiz_marked_late_submission = @timely_quiz_marked_late.submission
      Submission.where(id: @timely_quiz_marked_late_submission).update_all(submitted_at: @now, cached_due_date: nil)
      Submission.where(id: @timely_quiz_marked_late_submission).update_all(late_policy_status: "late")

      @ongoing_late_quiz1 = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_late_quiz1_submission = @ongoing_late_quiz1.submission
      @ongoing_late_quiz1_submission.save!
      Submission.where(id: @ongoing_late_quiz1_submission)
                .update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @ongoing_late_quiz2 = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_late_quiz2_submission = @ongoing_late_quiz2.submission
      @ongoing_late_quiz2_submission.save!
      Submission.where(id: @ongoing_late_quiz2_submission)
                .update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @ongoing_timely_quiz_marked_late = generate_quiz_submission(@quiz, student: User.create)
      @ongoing_timely_quiz_marked_late_submission = @ongoing_timely_quiz_marked_late.submission
      @ongoing_timely_quiz_marked_late_submission.save!
      Submission.where(id: @ongoing_timely_quiz_marked_late_submission)
                .update_all(submitted_at: @now, cached_due_date: nil, late_policy_status: "late")

      ### Homeworks
      @unsubmitted_hw = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @unsubmitted_hw.id).update_all(submitted_at: nil, cached_due_date: nil)

      @timely_hw1 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw1.id).update_all(submitted_at: @now, cached_due_date: nil)

      @timely_hw2 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw2.id).update_all(submitted_at: @now, cached_due_date: @now + 1.hour)

      @late_hw1 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw1.id).update_all(submitted_at: @now, cached_due_date: @now - 45.seconds)

      @late_hw2 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw2.id).update_all(submitted_at: @now, cached_due_date: @now - 61.seconds)

      @late_hw3 = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw3.id).update_all(submitted_at: @now, cached_due_date: @now - 1.hour)

      @late_hw_excused = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @late_hw_excused.id).update_all(submitted_at: @now, cached_due_date: @now - 1.hour, excused: true)

      @timely_hw_marked_late = @assignment.submissions.create(user: User.create, submission_type: "online_text_entry")
      Submission.where(id: @timely_hw_marked_late.id).update_all(submitted_at: @now, cached_due_date: nil)
      Submission.where(id: @timely_hw_marked_late.id).update_all(late_policy_status: "late")
      @not_late_submission_ids = Submission.not_late.map(&:id)
    end

    ### Quizzes
    it "includes unsubmitted quizzes" do
      expect(@not_late_submission_ids).to include(@unsubmitted_quiz_submission.id)
    end

    it "includes ongoing quizzes that have never been submitted before" do
      expect(@not_late_submission_ids).to include(@ongoing_unsubmitted_quiz_submission.id)
    end

    it "includes quizzes submitted with no due date" do
      expect(@not_late_submission_ids).to include(@timely_quiz1_submission.id)
    end

    it "includes quizzes submitted before the due date" do
      expect(@not_late_submission_ids).to include(@timely_quiz2_submission.id)
    end

    it "includes quizzes submitted less than 60 seconds after the due date" do
      expect(@not_late_submission_ids).to include(@timely_quiz3_submission.id)
    end

    it "excludes quizzes submitted more than 60 seconds after the due date" do
      expect(@not_late_submission_ids).not_to include(@late_quiz1_submission.id)
    end

    it "includes quizzes that were last submitted more than 60 seconds after the due date but are being retaken" do
      expect(@not_late_submission_ids).to include(@ongoing_late_quiz1_submission.id)
    end

    it "excludes quizzes submitted after the due date" do
      expect(@not_late_submission_ids).not_to include(@late_quiz2_submission.id)
    end

    it "includes quizzes that were last submitted after the due date but are being retaken" do
      expect(@not_late_submission_ids).to include(@ongoing_late_quiz2_submission.id)
    end

    it "excludes quizzes that have been manually marked as late" do
      expect(@not_late_submission_ids).not_to include(@timely_quiz_marked_late_submission.id)
    end

    it "excludes quizzes that have been manually marked as late but are being retaken" do
      expect(@not_late_submission_ids).not_to include(@ongoing_timely_quiz_marked_late_submission.id)
    end

    it "includes quizzes that are late but have been marked as extended" do
      expect(@not_late_submission_ids).to include(@late_quiz_extended_submission.id)
    end

    ### Homeworks
    it "includes an otherwise late submission that has been marked with a custom status" do
      admin = account_admin_user(account: @course.root_account)
      custom_grade_status = @course.root_account.custom_grade_statuses.create!(
        name: "Custom Status",
        color: "#ABC",
        created_by: admin
      )
      expect { @late_hw1.update!(custom_grade_status:) }.to change {
        Submission.not_late.include?(@late_hw1)
      }.from(false).to(true)
    end

    it "includes unsubmitted homeworks" do
      expect(@not_late_submission_ids).to include(@unsubmitted_hw.id)
    end

    it "includes homeworks submitted with no due date" do
      expect(@not_late_submission_ids).to include(@timely_hw1.id)
    end

    it "includes homeworks submitted before the due date" do
      expect(@not_late_submission_ids).to include(@timely_hw2.id)
    end

    it "excludes homeworks submitted less than 60 seconds after the due date" do
      expect(@not_late_submission_ids).not_to include(@late_hw1.id)
    end

    it "excludes homeworks submitted more than 60 seconds after the due date" do
      expect(@not_late_submission_ids).not_to include(@late_hw2.id)
    end

    it "excludes homeworks submitted after the due date" do
      expect(@not_late_submission_ids).not_to include(@late_hw3.id)
    end

    it "includes excused homework submitted after the due date" do
      expect(@not_late_submission_ids).to include(@late_hw_excused.id)
    end

    it "excludes homeworks that have been manually marked as late" do
      expect(@not_late_submission_ids).not_to include(@timely_hw_marked_late.id)
    end
  end

  describe "scope: with_assignment" do
    it "excludes submissions to deleted assignments" do
      expect { @assignment.destroy }.to change { @student.submissions.with_assignment.count }.by(-1)
    end
  end

  describe "scope: for_assignment" do
    it "includes all submissions for a given assignment" do
      first_assignment = @assignment
      @course.assignments.create!

      submissions = Submission.for_assignment(@assignment)
      expect(submissions).to match_array(first_assignment.submissions)
    end
  end

  describe "#filter_attributes_for_user" do
    let(:user) { instance_double("User", id: 1) }
    let(:session) { {} }
    let(:submission) { @assignment.submissions.build(user_id: 2) }

    context "assignment is set to manually post grades" do
      before do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.grade_student(@student, grader: @teacher, score: 5)
      end

      it "filters score" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "score" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("score")
      end

      it "filters grade" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "grade" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("grade")
      end

      it "filters published_score" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "published_score" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("published_score")
      end

      it "filters published_grade" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "published_grade" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("published_grade")
      end

      it "filters entered_score" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "entered_score" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("entered_score")
      end

      it "filters entered_grade" do
        expect(submission.assignment).to receive(:user_can_read_grades?).and_return(false)
        hash = { "entered_grade" => 10 }
        expect(submission.filter_attributes_for_user(hash, user, session)).not_to have_key("entered_grade")
      end
    end
  end

  describe "#provisional_grade" do
    before(:once) do
      @assignment.update!(moderated_grading: true, grader_count: 2, final_grader: @teacher)
      @assignment.grade_student(@student, score: 10, grader: @teacher, provisional: true)
      @assignment.grade_student(@student, score: 50, grader: @teacher, provisional: true, final: true)
    end

    let(:submission) { @assignment.submissions.first }

    it "returns the provisional grade matching the passed-in scorer if provided" do
      expect(submission.provisional_grade(@teacher).score).to eq 10
    end

    it "returns the final provisional grade if final is true" do
      expect(submission.provisional_grade(@teacher, final: true).score).to eq 50
    end

    context "when no matching grade is found" do
      let(:non_scorer) { User.new }

      it "returns a null provisional grade by default" do
        provisional_grade = submission.provisional_grade(non_scorer)
        expect(provisional_grade).to be_a(ModeratedGrading::NullProvisionalGrade)
      end

      it "returns nil if default_to_null_grade is false" do
        provisional_grade = submission.provisional_grade(non_scorer, default_to_null_grade: false)
        expect(provisional_grade).to be_nil
      end
    end
  end

  describe "#update_line_item_result" do
    let(:submission) { submission_model(assignment: @assignment) }

    context "when lti_result does not exist" do
      it "does nothing when there is no line item" do
        expect do
          submission.update!(score: 1.3)
        end.to_not change { submission.lti_result }.from(nil)
      end

      context "when there is a line item" do
        before { line_item_model(assignment: @assignment) }

        it "does nothing if score has not changed" do
          expect do
            submission.update!(body: "hello abc")
          end.to_not change { submission.lti_result }.from(nil)
        end

        it "creates an the lti_result with the correct score_given if the score has changed" do
          expect do
            submission.update!(score: 1.3)
          end.to change { submission.lti_result&.reload&.result_score }.from(nil).to(1.3)
        end

        it "does nothing if the lti_result was updated by a tool" do
          expect do
            submission.update!(score: 1.3, grader_id: -123)
          end.to_not change { submission.lti_result }.from(nil)
        end
      end
    end

    context "with lti_result" do
      let(:lti_result) { lti_result_model(assignment: @assignment) }
      let(:submission) { lti_result.submission }

      it "does nothing if score has not changed" do
        expect do
          submission.save!
        end.to_not change { lti_result.result_score }
      end

      it "updates the lti_result score_given if the score has changed" do
        expect do
          submission.update!(score: 1.3)
        end.to change { lti_result.reload.result_score }.from(nil).to(1.3)
      end

      it "does nothing if the lti_result was updated by a tool" do
        expect do
          submission.update!(score: 1.3, grader_id: -123)
        end.to_not change { lti_result.reload.result_score }
      end
    end
  end

  describe "#delete_ignores" do
    context "for submission ignores" do
      before :once do
        @submission = @assignment.submissions.find_by!(user_id: @student)
        @ignore = Ignore.create!(asset: @assignment, user: @student, purpose: "submitting")
      end

      it "deletes submission ignores when asset is submitted" do
        @assignment.submit_homework(@student, { submission_type: "online_text_entry", body: "Hi" })
        expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not delete submission ignores when asset is not submitted" do
        @submission.student_entered_score = 5
        @submission.save!
        expect(@ignore.reload).to eq @ignore
      end

      it "deletes submission ignores when asset is excused" do
        @submission.excused = true
        @submission.save!
        expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "for grading ignores" do
      before :once do
        @student1 = @student
        @student2 = student_in_course(course: @course, active_all: true).user
        @sub1 = @assignment.submit_homework(@student1, { submission_type: "online_text_entry", body: "Hi" })
        @sub2 = @assignment.submit_homework(@student2, { submission_type: "online_text_entry", body: "Hi" })
        @ignore = Ignore.create!(asset: @assignment, user: @teacher, purpose: "grading")
      end

      it "deletes grading ignores if every submission is graded or excused" do
        @sub1.score = 5
        @sub1.save!
        @sub2.excused = true
        @sub2.save!
        expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not delete grading ignores if some submissions are ungraded" do
        @sub1.score = 5
        @sub1.save!
        expect(@ignore.reload).to eq @ignore
      end
    end
  end

  def submission_spec_model(opts = {})
    submit_homework = opts.delete(:submit_homework)
    opts = submit_homework ? @valid_attributes.merge(opts) : @valid_attributes.except(:workflow_state, :url).merge(opts)
    assignment = opts.delete(:assignment) || Assignment.find(opts.delete(:assignment_id))
    user = opts.delete(:user) || User.find(opts.delete(:user_id))

    @submission = if submit_homework
                    assignment.submit_homework(user)
                  else
                    assignment.submissions.find_by!(user:)
                  end
    unless assignment.grades_published? || @submission.grade_posting_in_progress || assignment.permits_moderation?(user)
      opts.delete(:grade)
    end
    @submission.update!(opts)
    @submission
  end

  def setup_account_for_turnitin(account)
    account.update(turnitin_account_id: "test_account",
                   turnitin_shared_secret: "skeret",
                   settings: account.settings.merge(enable_turnitin: true))
  end

  context "generated observer alerts" do
    before :once do
      course_with_teacher
      @threshold = observer_alert_threshold_model(alert_type: "assignment_grade_high", threshold: "80", course: @course)
      @assignment = assignment_model(context: @course, points_possible: 10)
    end

    it "doesn't create an alert if the observer has been deleted" do
      # This sets up the environment for an error we've seen in the wild
      observer_user_ids = @course.observer_enrollments.pluck(:user_id).uniq
      User.where(id: observer_user_ids).destroy_all

      expect do
        @assignment.grade_student(@threshold.student, score: 10, grader: @teacher)
      end.not_to change {
        ObserverAlert.where(context: @assignment, alert_type: :assignment_grade_high).count
      }
    end

    it "logs if it can't create an observer alert" do
      allow(ObserverAlert).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new)
      submission_id = @assignment.submissions.find_by(user: @threshold.student).id

      expect(Rails.logger).to receive(:error)
        .with("Couldn't create ObserverAlert for submission #{submission_id} observer #{@threshold.observer_id}")

      @assignment.grade_student(@threshold.student, score: 10, grader: @teacher)
    end
  end

  describe "#grade_posting_in_progress" do
    subject { submission.grade_posting_in_progress }

    it { is_expected.to be_nil }

    it "reports its value" do
      submission.grade_posting_in_progress = true
      expect(submission.grade_posting_in_progress).to be true
    end
  end

  describe "#grade_posting_in_progress=" do
    it "can set a value" do
      expect { submission.grade_posting_in_progress = true }.to change {
        submission.grade_posting_in_progress
      }.from(nil).to(true)
    end
  end

  describe "sticker validations" do
    it "allows a nil sticker" do
      submission = @assignment.submissions.first
      submission.sticker = nil
      expect(submission).to be_valid
    end

    it "does not allow a sticker that is not in the approved list" do
      submission = @assignment.submissions.first
      submission.sticker = "my_custom_sticker"
      expect(submission).not_to be_valid
    end

    it "allows a sticker that is in the approved list" do
      submission = @assignment.submissions.first
      submission.sticker = "basketball"
      expect(submission).to be_valid
    end
  end

  describe "extra_attempts validations" do
    it { is_expected.to validate_numericality_of(:extra_attempts).is_greater_than_or_equal_to(0).allow_nil }

    describe "#extra_attempts_can_only_be_set_on_online_uploads" do
      it "does not allowe extra_attempts to be set for non online upload submission types" do
        submission = @assignment.submissions.first

        %w[online_upload online_url online_text_entry].each do |submission_type|
          submission.assignment.submission_types = submission_type
          submission.assignment.save!
          submission.extra_attempts = 10
          expect(submission).to be_valid
        end

        %w[discussion_entry online_quiz].each do |submission_type|
          submission.assignment.submission_types = submission_type
          submission.assignment.save!
          submission.extra_attempts = 10
          expect(submission).to_not be_valid
        end
      end
    end
  end

  describe "#ensure_attempts_are_in_range" do
    let(:submission) { @assignment.submissions.first }

    context "the assignment is of a type that is restricted by attempts" do
      before do
        @assignment.allowed_attempts = 10
        @assignment.submission_types = "online_upload"
        @assignment.save!
      end

      context "attempts_left <= 0" do
        before do
          submission.attempt = 10
          submission.save!
        end

        context "the submitted_at changed" do
          it "is invalid" do
            submission.submitted_at = Time.zone.now
            expect(submission).to_not be_valid
          end
        end

        context "the submitted_at did not change" do
          it "is valid" do
            expect(submission).to be_valid
          end
        end
      end
    end

    context "the assignment is of a type that is not restricted by attempts" do
      before do
        @assignment.allowed_attempts = 10
        @assignment.submission_types = "online_discussion"
        @assignment.save!
        submission.attempt = 10
        submission.save!
      end

      it "is valid" do
        expect(submission).to be_valid
      end
    end
  end

  describe "#attempts_left" do
    let(:submission) { @assignment.submissions.first }

    context "allowed_attempts is set to a number > 0 on the assignment" do
      before do
        @assignment.allowed_attempts = 10
        @assignment.submission_types = "online_upload"
        @assignment.save!
      end

      context "the submission has extra_attempts set to a value > 0" do
        it "returns assignment.allowed_attempts + submission.extra_attempts - submission.attempt" do
          submission.extra_attempts = 12
          submission.attempt = 6
          submission.save!
          expect(submission.attempts_left).to eq(10 + 12 - 6)
        end

        it "correctly recalculates when allowed_attempts and extra_attempts change" do
          submission.extra_attempts = 12
          submission.attempt = 22
          submission.save!
          expect(submission.attempts_left).to eq(0)
          @assignment.allowed_attempts = 11
          @assignment.save!
          expect(submission.attempts_left).to eq(1)
          submission.extra_attempts = 13
          submission.save!
          expect(submission.attempts_left).to eq(2)
        end

        it "will never return negative values" do
          submission.attempt = 1000
          submission.save!
          expect(submission.attempts_left).to eq(0)
        end
      end

      context "the submission has extra_attempts set to nil" do
        it "returns allowed_attempts from the assignment" do
          submission.extra_attempts = nil
          submission.attempt = 6
          submission.save!
          expect(submission.attempts_left).to eq(10 - 6)
        end
      end
    end

    context "allowed_attempts is set to nil or -1 on the assignment" do
      it "returns nil" do
        @assignment.allowed_attempts = nil
        @assignment.save!
        expect(submission.attempts_left).to be_nil
        @assignment.allowed_attempts = -1
        @assignment.save!
        expect(submission.attempts_left).to be_nil
      end
    end
  end

  describe "#attempt" do
    it "is nil when homework has not been submitted" do
      submission = Submission.find_by(user: @student)
      expect(submission.attempt).to be_nil
    end

    it "is 1 when homework is submitted" do
      submission = @assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "body"
      )
      expect(submission.attempt).to eq 1
    end

    it "is incremented when homework is resubmitted" do
      submission = @assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "body",
        submitted_at: 1.hour.ago
      )

      # Due to unit tests being ran in a transaction and not actually committed
      # to the database, we can't call submit_homework multiple times. We are
      # instead just updating the submitted_at time, which triggers the before_save
      # callback.
      submission.update!(submitted_at: 2.hours.ago)
      submission.update!(submitted_at: 1.hour.ago)
      expect(submission.attempt).to eq 3
    end
  end

  describe "sticker removal" do
    before(:once) do
      @submission = Submission.find_by(user: @student)
    end

    it "removes the sticker when a new attempt is submitted" do
      @submission.update!(sticker: "basketball")
      @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "foo")
      expect(@submission.reload.sticker).to be_nil
    end

    it "does not remove the sticker when the submission is updated but there's not a new attempt" do
      @submission.update!(sticker: "basketball")
      @assignment.grade_student(@student, score: 5, grader: @teacher)
      expect(@submission.reload.sticker).to eq "basketball"
    end

    it "preserves previously awarded stickers in submission history" do
      submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "foo")
      submission.update!(sticker: "basketball")
      Timecop.freeze(10.minutes.from_now) do
        submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "bar")
        submission.update!(sticker: "paintbrush")
      end

      sticker = submission.submission_history.find { |sub| sub.attempt == 1 }.sticker
      expect(sticker).to eq "basketball"
    end
  end

  describe "#submission_drafts" do
    before(:once) do
      @submission = Submission.find_by(user: @student)
    end

    it "is empty by default" do
      expect(@submission.submission_drafts).to eq []
    end

    describe "with drafts for multiple attempts" do
      before(:once) do
        @submission = @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "foo")
        @draft1 = SubmissionDraft.new(submission: @submission, submission_attempt: 0)
        @draft2 = SubmissionDraft.new(submission: @submission, submission_attempt: 1)
        @submission.submission_drafts << @draft1
        @submission.submission_drafts << @draft2
      end

      it "can have drafts for different submission attempts" do
        expect(@submission.submission_drafts.sort).to eq [@draft1, @draft2]
      end

      it "deletes all drafts for all submission attempts when homework is submitted" do
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "foo")
        @submission.reload
        expect(@submission.submission_drafts).to eq []
        expect(SubmissionDraft.count).to be 0
      end
    end

    describe "with attachments" do
      before(:once) do
        @attachment1 = attachment_model
        @attachment2 = attachment_model
        @submission_draft = SubmissionDraft.create!(
          submission: @submission,
          submission_attempt: 0
        )
        @submission_draft.attachments = [@attachment1, @attachment2]
      end

      it "can access the attachments" do
        expect(@submission.submission_drafts.first.attachments.sort).to eq [@attachment1, @attachment2]
      end

      it "will cascade deletes to SubmissionDraftAttachments when homework is submitted" do
        @assignment.submit_homework(@student, submission_type: "online_text_entry", body: "foo")
        @submission.reload
        expect(@submission.submission_drafts).to eq []
        expect(SubmissionDraft.count).to be 0
        expect(SubmissionDraftAttachment.count).to be 0
      end
    end
  end

  describe "#hide_grade_from_student?" do
    subject(:submission) { assignment.submissions.find_by!(user: student) }

    let(:course) { @course }
    let(:assignment) { @assignment }
    let(:teacher) { @teacher }
    let(:student) { @student }

    before do
      course.enroll_student(student)
      course.enroll_teacher(teacher)
    end

    it { is_expected.not_to be_hide_grade_from_student }

    context "when assignment posts manually" do
      before { assignment.ensure_post_policy(post_manually: true) }

      it { is_expected.to be_hide_grade_from_student }
      it { is_expected.not_to be_hide_grade_from_student(for_plagiarism: true) }

      context "when a submission is posted" do
        before { submission.update!(posted_at: Time.zone.now) }

        it { is_expected.not_to be_hide_grade_from_student }
      end
    end

    context "when assignment posts automatically" do
      before { assignment.ensure_post_policy(post_manually: false) }

      it { is_expected.not_to be_hide_grade_from_student }

      context "when a submission is posted" do
        before { submission.update!(posted_at: Time.zone.now) }

        it { is_expected.not_to be_hide_grade_from_student }
      end

      context "when a submission is graded but not posted" do
        before do
          assignment.grade_student(student, score: 5, grader: teacher)
          assignment.hide_submissions
        end

        it { is_expected.to be_hide_grade_from_student }
      end

      context "when homework has been submitted, but the submission is not graded or posted" do
        before do
          assignment.update!(submission_types: "online_text_entry")
          assignment.submit_homework(student, submission_type: "online_text_entry", body: "hi")
        end

        it { is_expected.not_to be_hide_grade_from_student }
      end

      context "when a student re-submits to a previously graded and subsequently hidden submission" do
        before do
          assignment.update!(submission_types: "online_text_entry")
          assignment.submit_homework(student, submission_type: "online_text_entry", body: "hi")
          assignment.grade_student(student, score: 0, grader: teacher)
          assignment.hide_submissions
          assignment.submit_homework(student, submission_type: "online_text_entry", body: "I will never give up")
        end

        it { is_expected.to be_hide_grade_from_student }
      end
    end
  end

  describe "posting and unposting" do
    subject(:submission) { @assignment.submissions.first }

    describe "#posted?" do
      it { is_expected.not_to be_posted }

      it "returns true if the submission's posted_at date is not nil" do
        submission.update!(posted_at: Time.zone.now)
        expect(submission).to be_posted
      end
    end

    describe "#handle_posted_at_changed" do
      describe "when an studen that is also admin posts an submission" do
        it "unmutes the assignment if all submissions are now posted" do
          admin = account_admin_user(account: @account, name: "default admin")
          @course.enroll_student(admin)
          assignment = @course.assignments.create!(
            title: "some assignment",
            workflow_state: "published"
          )
          submission_model(user: admin, assignment:, body: "first student submission text")
          expect { assignment.reload }.not_to raise_error
        end
      end

      context "when posting an individual submission" do
        context "when post policies are enabled" do
          it "unmutes the assignment if all submissions are now posted" do
            submission.update!(posted_at: Time.zone.now)
            expect(@assignment.reload).not_to be_muted
          end

          it "does not unmute the assignment if some submissions remain unposted" do
            @course.enroll_student(User.create!, enrollment_state: "active")
            submission.update!(posted_at: Time.zone.now)
            expect(@assignment.reload).to be_muted
          end
        end
      end

      context "when unposting an individual submission" do
        before { submission.update!(posted_at: 1.day.ago) }

        context "when post policies are enabled" do
          it "mutes an unmuted assignment when a submission is hidden" do
            @assignment.post_submissions

            submission.update!(posted_at: nil)
            expect(@assignment.reload).to be_muted
          end
        end
      end
    end
  end

  context "caching" do
    specs_require_cache(:redis_cache_store)

    def check_cache_clear
      key = @student.cache_key(:submissions)
      yield
      expect(@student.cache_key(:submissions)).to_not eq key
    end

    it "clears key when submission is deleted" do
      check_cache_clear do
        sub = @student.submissions.first
        @student.enrollments.first.destroy
        expect(sub.reload).to be_deleted
      end
    end

    it "clears key when a submission comment is made" do
      check_cache_clear do
        @student.submissions.first.add_comment(author: @teacher, comment: "some comment")
      end
    end

    it "clears key when assignment is unmuted" do
      @assignment.mute!
      check_cache_clear do
        @assignment.unmute!
      end
    end
  end

  describe "postable scope" do
    specs_require_sharding

    it "works cross-shard" do
      @shard1.activate do
        expect(@assignment.submissions.postable.to_sql).to_not include(@shard1.name)
      end
    end
  end

  describe "root account ID" do
    let_once(:root_account) { Account.create! }
    let_once(:subaccount) { Account.create!(root_account:) }
    let_once(:course) { Course.create!(account: subaccount) }
    let_once(:student) { course.enroll_student(User.create!, workflow_state: "active").user }

    it "is set to the root account ID of the owning course" do
      assignment = course.assignments.create!
      expect(assignment.submission_for_student(student).root_account_id).to eq root_account.id
    end
  end

  describe "redo request" do
    subject(:submission) { @assignment.submissions.new user: User.create, workflow_state: "submitted", redo_request: true, attempt: 1 }

    it "redo request is reset on an updated submission" do
      submission.update!(attempt: 2)
      expect(submission.redo_request).to be false
    end
  end

  describe "word_count" do
    it "returns the word count" do
      submission.update(body: "test submission")
      expect(submission.word_count).to eq 2
    end

    it "returns nil if there is no body" do
      expect(submission.body).to be_nil
      expect(submission.word_count).to be_nil
    end

    it "returns nil if it's a quiz submission" do
      submission.update(submission_type: "online_quiz", body: "test submission")
      expect(submission.submission_type).to eq "online_quiz"
      expect(submission.body).not_to be_nil
      expect(submission.word_count).to be_nil
    end

    it "returns 0 if the body is empty" do
      submission.update(body: "")
      expect(submission.word_count).to eq 0
    end

    it "ignores HTML tags" do
      submission.update(body: "<span>test <div></div>submission</span> <p></p>")
      expect(submission.word_count).to eq 2
      submission.instance_variable_set :@word_count, nil
      submission.update(body: '<p>This is my submission, which has&nbsp;<strong>some bold&nbsp;<em>italic text</em> in</strong> it.</p>
        <p>A couple paragraphs, and maybe super<sup>script</sup>.&nbsp;</p>')
      expect(submission.word_count).to eq 18
    end

    it "sums word counts of attachments if there are any" do
      student_in_course(active_all: true)
      submission_text = "Text based submission with some words"
      attachment1 = attachment_model(uploaded_data: stub_file_data("submission.txt", submission_text, "text/plain"), context: @student)
      attachment2 = attachment_model(uploaded_data: stub_file_data("submission.txt", submission_text, "text/plain"), context: @student)
      sub = @assignment.submit_homework(@student, attachments: [attachment1, attachment2])
      run_jobs
      expect(sub.word_count).to eq 12
    end
  end

  context "Assignment Cache" do
    specs_require_cache(:redis_cache_store)

    describe "creating a new submission" do
      subject(:submission) { @assignment.submissions.new user: User.create, workflow_state: "submitted" }

      it "invalidates submited count cache if submitted" do
        Rails.cache.write(["submitted_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
        subject.run_callbacks :create
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(false)
      end

      it "does not invalidate submitted count cache if unsubmtted" do
        Rails.cache.write(["submitted_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
        subject.workflow_state = "unsubmitted"
        subject.run_callbacks :create
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
      end

      it "invalidates graded count cache if graded" do
        Rails.cache.write(["graded_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
        subject.score = 10
        subject.workflow_state = "graded"
        subject.run_callbacks :create
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(false)
      end

      it "does not invalidate graded count cache if unsubmtted" do
        Rails.cache.write(["graded_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
        subject.run_callbacks :create
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
      end
    end

    describe "updating a submission" do
      subject(:submission) { @assignment.submissions.first }

      it "invalidates submited count cache if submitted" do
        Rails.cache.write(["submitted_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
        subject.workflow_state = "submitted"
        subject.run_callbacks :update
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(false)
      end

      it "does not invalidate submitted count cache if unsubmtted" do
        Rails.cache.write(["submitted_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
        subject.workflow_state = "unsubmitted"
        subject.run_callbacks :update
        expect(Rails.cache.exist?(["submitted_count", @assignment].cache_key)).to be(true)
      end

      it "invalidates graded count cache if graded" do
        Rails.cache.write(["graded_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
        subject.score = 10
        subject.workflow_state = "graded"
        subject.run_callbacks :update
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(false)
      end

      it "does not invalidate graded count cache if unsubmtted" do
        Rails.cache.write(["graded_count", @assignment].cache_key, "test")
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
        subject.workflow_state = "submitted"
        subject.run_callbacks :create
        expect(Rails.cache.exist?(["graded_count", @assignment].cache_key)).to be(true)
      end
    end
  end

  describe "#observer?" do
    before do
      @student = user_factory
      course_with_observer(
        course: @course,
        associated_user_id: @student.id,
        active_all: true,
        active_cc: true
      )
      @submission = @assignment.submission_for_student(@student)
    end

    it "is true for observer" do
      expect(@submission.observer?(@observer)).to be true
    end

    it "is false for student" do
      expect(@submission.observer?(@student)).to be false
    end

    it "is false for teacher" do
      expect(@submission.observer?(@teacher)).to be false
    end

    it "is false for others" do
      expect(@submission.observer?(user_factory)).to be false
    end
  end

  describe "#peer_reviewer?" do
    before do
      student_in_course(active_all: true)
      @peer_reviewer = user_factory
      @course.enroll_student(@peer_reviewer).accept!
      @assignment = @course.assignments.build(
        title: "Peer Reviews",
        submission_types: "online_text_entry",
        peer_reviews: true
      )
      @assignment.save!
      @submission = @assignment.submission_for_student(@student)
      @submission.assessment_requests.create!(
        user: @student,
        assessor: @peer_reviewer,
        assessor_asset: @submission
      )
    end

    it "is true for reviewer" do
      expect(@submission.peer_reviewer?(@peer_reviewer)).to be true
    end

    it "is false for student" do
      expect(@submission.peer_reviewer?(@student)).to be false
    end

    it "is false for teacher" do
      expect(@submission.peer_reviewer?(@teacher)).to be false
    end

    it "is false for others" do
      expect(@submission.peer_reviewer?(user_factory)).to be false
    end
  end

  describe "send_timing_data_if_needed" do
    it "calls Statsd when a classic quiz is manually graded" do
      expect(InstStatsd::Statsd).to receive(:gauge).once.with("submission.manually_graded.grading_time", 600.0, 1.0, tags: { quiz_type: "classic_quiz" })

      now = Time.now
      Timecop.freeze(now) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 10, "question_type" => "essay_question" } }])
      end

      Timecop.freeze(10.minutes.from_now(now)) do
        @quiz_submission.set_final_score(7)
        @quiz_submission.save!
      end
    end

    it "calls Statsd when a new quiz is manually graded" do
      expect(InstStatsd::Statsd).to receive(:gauge).once.with("submission.manually_graded.grading_time", 300.0, 1.0, tags: { quiz_type: "new_quiz" })

      now = Time.now
      Timecop.freeze(now) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 10, "question_type" => "essay_question" } }])
      end

      allow(@quiz_submission.submission).to receive_messages(submission_type: "basic_lti_launch", url: "https://quiz-lti-iad-prod.instructure.com/lti/launch")
      Timecop.freeze(5.minutes.from_now(now)) do
        @quiz_submission.set_final_score(7)
        @quiz_submission.save!
      end
    end

    it "does not call Statsd when a quiz is automatically graded" do
      expect(InstStatsd::Statsd).not_to receive(:gauge)

      quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 10, "question_type" => "multiple_choice_question" } }])
    end

    it "does not call Statsd when a submission is updated" do
      expect(InstStatsd::Statsd).not_to receive(:gauge)

      now = Time.now
      Timecop.freeze(now) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 10, "question_type" => "essay_question" } }])
      end

      Timecop.freeze(10.minutes.from_now(now)) do
        submission = @quiz.submissions.first
        submission.excused = false
        submission.save!
      end
    end

    it "does not call Statsd when the time between submission and grading is less than 30 seconds" do
      expect(InstStatsd::Statsd).not_to receive(:gauge)

      now = Time.now
      Timecop.freeze(now) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 10, "question_type" => "essay_question" } }])
      end

      Timecop.freeze(29.seconds.from_now(now)) do
        @quiz_submission.set_final_score(7)
        @quiz_submission.save!
      end
    end
  end

  describe "checkpoint submissions" do
    before(:once) do
      course = course_model
      student = student_in_course(course:, active_all: true).user
      course.root_account.enable_feature!(:discussion_checkpoints)
      topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
      topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint_submission = topic.reply_to_topic_checkpoint.submissions.find_by(user: student)
      @parent_submission = topic.assignment.submissions.find_by(user: student)
    end

    it "updates the parent submission when tracked attrs change on a checkpoint submission" do
      expect { @checkpoint_submission.update!(score: 3) }.to change { @parent_submission.reload.score }.from(nil).to(3)
    end

    it "does not update the parent submission when attrs that changed are not tracked" do
      expect { @checkpoint_submission.update!(lti_user_id: "some-id") }.not_to change { @parent_submission.reload.updated_at }
    end

    it "does not update the parent submission when the checkpoints flag is disabled" do
      @checkpoint_submission.root_account.disable_feature!(:discussion_checkpoints)
      expect { @checkpoint_submission.update!(score: 3) }.not_to change { @parent_submission.reload.score }
    end
  end
end
