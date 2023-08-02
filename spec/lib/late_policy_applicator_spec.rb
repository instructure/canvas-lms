# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe LatePolicyApplicator do
  describe ".for_course" do
    before :once do
      course_factory(active_all: true)

      @published_assignment = @course.assignments.create!(workflow_state: "published")
    end

    it "instantiates an applicator for the course" do
      expect(LatePolicyApplicator).to receive(:new).with(@course).and_call_original

      LatePolicyApplicator.for_course(@course)
    end

    it "does not instantiate an applicator for an unpublished course" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @course.workflow_state = "created"
      LatePolicyApplicator.for_course(@course)
    end

    it "does not instantiate an applicator for a course with no published assignments" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.unpublish!
      LatePolicyApplicator.for_course(@course)
    end

    it "kicks off a singleton-by-course + n_strand-by-root-account background job" do
      queueing_args = {
        singleton: "late_policy_applicator:calculator:Course:#{@course.global_id}",
        n_strand: ["LatePolicyApplicator", @course.root_account.global_id]
      }

      applicator_double = instance_double("LatePolicyApplicator")
      allow(LatePolicyApplicator).to receive(:new).and_return(applicator_double)

      expect(applicator_double).to receive(:delay_if_production).with(**queueing_args).and_return(applicator_double)
      expect(applicator_double).to receive(:process)

      LatePolicyApplicator.for_course(@course)
    end
  end

  describe ".for_assignment" do
    before :once do
      course_factory(active_all: true)

      @published_assignment = @course.assignments.create!(workflow_state: "published", points_possible: 20)
    end

    it "instantiates an applicator for the assignment" do
      expect(LatePolicyApplicator).to receive(:new).with(@course, [@published_assignment]).and_call_original

      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "does not instantiate an applicator for an unpublished assignment" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.unpublish!
      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "does not instantiate an applicator for an assignment with no points possible" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.points_possible = nil
      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "does not instantiate an applicator for an assignment with zero points possible" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.points_possible = 0
      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "does not instantiate an applicator for an assignment with negative points possible" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.points_possible = -1
      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "does not instantiate an applicator for an assignment without a course" do
      expect(LatePolicyApplicator).not_to receive(:new)

      @published_assignment.course = nil
      LatePolicyApplicator.for_assignment(@published_assignment)
    end

    it "kicks off a singleton-by-assignment + n_strand-by-root-account background job" do
      queueing_args = {
        singleton: "late_policy_applicator:calculator:Assignment:#{@published_assignment.global_id}",
        n_strand: ["LatePolicyApplicator", @published_assignment.root_account.global_id]
      }

      applicator_double = instance_double("LatePolicyApplicator")
      allow(LatePolicyApplicator).to receive(:new).and_return(applicator_double)

      expect(applicator_double).to receive(:delay_if_production).with(**queueing_args).and_return(applicator_double)
      expect(applicator_double).to receive(:process)

      LatePolicyApplicator.for_assignment(@published_assignment)
    end
  end

  describe "#process" do
    before :once do
      @now = Time.zone.now
      course_factory(active_all: true, grading_periods: [:old, :current])

      @late_policy = late_policy_factory(course: @course, deduct: 50.0, every: :day, missing: 95.0)
      @course.late_policy = @late_policy
      @course.save!

      @students = Array.new(4) do
        user = User.create!
        @course.enroll_student(user, enrollment_state: "active")

        user
      end

      @assignment_in_closed_gp = @course.assignments.create!(
        points_possible: 20, due_at: @now - 3.months, submission_types: "online_text_entry"
      )

      @late_submission1 = @assignment_in_closed_gp.submissions.find_by(user: @students[0])
      # Update using update_all to prevent any callbacks that already apply late policies
      Submission.where(id: @late_submission1.id)
                .update_all(
                  submitted_at: @now - 3.months + 1.hour,
                  cached_due_date: @now - 3.months,
                  score: 20,
                  grade: 20,
                  submission_type: "online_text_entry"
                )

      @timely_submission1 = @assignment_in_closed_gp.submissions.find_by(user: @students[1])
      Submission.where(id: @timely_submission1)
                .update_all(
                  submitted_at: @now,
                  cached_due_date: @now + 1.hour,
                  score: 20,
                  grade: 20,
                  submission_type: "online_text_entry"
                )

      @missing_submission1 = @assignment_in_closed_gp.submissions.find_by(user: @students[2])
      Submission.where(id: @missing_submission1)
                .update_all(
                  submitted_at: nil,
                  cached_due_date: 1.month.ago(@now),
                  score: nil,
                  grade: nil
                )

      @assignment_in_open_gp = @course.assignments.create!(
        points_possible: 20, due_at: @now - 1.month, submission_types: "online_text_entry"
      )

      @late_submission2 = @assignment_in_open_gp.submissions.find_by(user: @students[0])
      Submission.where(id: @late_submission2.id)
                .update_all(
                  submitted_at: @now - 1.month + 1.hour,
                  cached_due_date: @now - 1.month,
                  score: 20,
                  grade: 20,
                  submission_type: "online_text_entry"
                )

      @timely_submission2 = @assignment_in_open_gp.submissions.find_by(user: @students[1])
      Submission.where(id: @timely_submission2)
                .update_all(
                  submitted_at: @now,
                  cached_due_date: @now + 1.hour,
                  score: 20,
                  grade: 20,
                  submission_type: "online_text_entry"
                )

      @missing_submission2 = @assignment_in_open_gp.submissions.find_by(user: @students[2])
      Submission.where(id: @missing_submission2)
                .update_all(
                  submitted_at: nil,
                  cached_due_date: @now - 1.month,
                  score: nil,
                  grade: nil
                )

      @previously_late_submission = @assignment_in_open_gp.submissions.find_by(user: @students[3])
      Submission.where(id: @previously_late_submission)
                .update_all(
                  submitted_at: @now,
                  cached_due_date: @now + 1.hour,
                  score: 10,
                  grade: 10,
                  points_deducted: 10,
                  submission_type: "online_text_entry"
                )
    end

    context "when the course has no late policy" do
      it "does not apply a late policy to late submissions" do
        @course.late_policy = nil
        @course.save!
        @late_policy_applicator = LatePolicyApplicator.new(@course, [@assignment_in_open_gp])

        expect(@late_policy_applicator).not_to receive(:process_submission)

        @late_policy_applicator.process
      end
    end

    context "when the course has a late policy" do
      let(:custom_grade_status) do
        admin = account_admin_user(account: @course.root_account)
        @course.root_account.custom_grade_statuses.create!(
          color: "#ABC",
          name: "yolo",
          created_by: admin
        )
      end

      it "does not apply the late policy to submissions unless late_submission_deduction_enabled or missing_submission_deduction_enabled" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)
        @late_policy.update_columns(late_submission_deduction_enabled: false, missing_submission_deduction_enabled: false)

        expect(@late_policy_applicator).not_to receive(:process_submission)
        @late_policy_applicator.process
      end

      it "applies the late policy to submissions if late_submission_deduction_enabled" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)
        @late_policy.update_columns(late_submission_deduction_enabled: true, missing_submission_deduction_enabled: false)

        expect(@late_policy_applicator).to receive(:process_submission).at_least(:once)
        @late_policy_applicator.process
      end

      it "applies the late policy to submissions if missing_submission_deduction_enabled" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)
        @late_policy.update_columns(late_submission_deduction_enabled: false, missing_submission_deduction_enabled: true)

        expect(@late_policy_applicator).to receive(:process_submission).at_least(:once)
        @late_policy_applicator.process
      end

      it "applies the late policy to late submissions in the open grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.to change { @late_submission2.reload.score }.by(-10)
      end

      it "does not apply the late policy to otherwise late submissions that have a custom status" do
        @late_submission2.update_columns(custom_grade_status_id: custom_grade_status.id)
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to change { @late_submission2.reload.score }
      end

      it "does not apply the late policy to late submissions for concluded students" do
        @course.enrollments.find_by(user: @late_submission2.user_id).conclude
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to(change { @late_submission2.reload.score })
      end

      it "recalculates late penalties with current due date in the open grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.to change { @previously_late_submission.reload.score }.by(+10)
      end

      it "does not recalculate late penalties with current due date in the open grading period if late deductions are disabled" do
        @late_policy.update_column(:late_submission_deduction_enabled, false)
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to change { @previously_late_submission.reload.score }
      end

      it "applies the missing policy to missing submissions in the open grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.to change { @missing_submission2.reload.score }.to(1)
      end

      it "does not apply the missing policy to missing submissions for concluded students" do
        @course.enrollments.find_by(user: @missing_submission2.user_id).conclude
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to(change { @missing_submission2.reload.score })
      end

      it "does not apply the late policy to timely submissions in the open grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to(change { @timely_submission2.reload.score })
      end

      it "does not apply the late policy to late submissions in the closed grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to change { @late_submission1.reload.score }
      end

      it "does not apply the late policy to missing submissions in the closed grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to change { @missing_submission1.reload.score }
      end

      it "does not apply the late policy to timely submissions in the closed grading period" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)

        expect { @late_policy_applicator.process }.not_to change { @timely_submission1.reload.score }
      end

      it "calls re-calculates grades in bulk after processing all submissions" do
        @late_policy_applicator = LatePolicyApplicator.new(@course)
        student_ids = [0, 2, 3].map { |i| @students[i].id }

        expect(@course).to receive(:recompute_student_scores)
          .with(array_including(student_ids))
          .with(Array.new(3, kind_of(Integer)))

        @late_policy_applicator.process
      end

      it "processes differentiated assignments that have a student in a closed grading period without error" do
        # turn off the late policy without calling callbacks
        @course.update_attribute(:late_policy, nil)

        # Build an assignment with two students in an open grading period and one in a closed
        assignment_to_override = @course.assignments.create!(
          points_possible: 20,
          due_at: @now - 1.month,
          submission_types: "online_text_entry",
          workflow_state: "published"
        )
        override = assignment_to_override.assignment_overrides.create(
          due_at_overridden: true, due_at: @now - 3.months, set_type: "ADHOC"
        )
        override.assignment_override_students.create!(user: @students[1])
        override.assignment_override_students.create!(user: @students[0])

        # turn on the late policy without calling callbacks
        @late_policy = late_policy_factory(course: @course, deduct: 50.0, every: :day, missing: 95.0)
        @course.update_attribute(:late_policy, @late_policy)

        late_policy_applicator = LatePolicyApplicator.new(@course, [assignment_to_override])
        expect { late_policy_applicator.process }.not_to raise_error
      end
    end
  end
end
