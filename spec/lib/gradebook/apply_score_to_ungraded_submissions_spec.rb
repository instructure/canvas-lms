# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe Gradebook::ApplyScoreToUngradedSubmissions do
  let(:course) { Course.create! }
  let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

  let(:assignment1) { course.assignments.create! }

  let(:student1) { User.create! }

  before do
    course.enroll_student(student1, enrollment_state: "active")

    assignment1.update!(due_at: 10.days.ago(Time.zone.now), grading_type: "percent", points_possible: 20.0)
  end

  def test_submission(assignment: assignment1, student: student1)
    Submission.find_by!(assignment:, user: student)
  end

  def build_options(**overrides)
    default_options = {
      excused: false,
      mark_as_missing: false,
      only_apply_to_past_due: false,
      percent: "60",
      assignment_ids: [assignment1.id.to_s],
      student_ids: [student1.id.to_s]
    }

    Gradebook::ApplyScoreToUngradedSubmissions::Options.new(
      default_options.merge(overrides)
    )
  end

  describe ".queue_apply_score" do
    it "returns a Progress object" do
      options = build_options(percent: "100")

      progress = Gradebook::ApplyScoreToUngradedSubmissions.queue_apply_score(
        course:,
        grader: teacher,
        options:
      )

      expect(progress).to be_a(Progress)
    end
  end

  describe ".process_apply_score" do
    def run(grader: teacher, **overrides)
      options = build_options(**overrides)

      progress = Progress.create!(context: course, tag: "apply_score_to_ungraded_assignments")
      progress.start!
      Gradebook::ApplyScoreToUngradedSubmissions.process_apply_score(progress, course, grader, options)
      progress
    end

    it "grades all ungraded submissions using the specified grade" do
      run

      aggregate_failures do
        expect(test_submission.grade).to eq "60%"
        expect(test_submission.score).to eq 12
      end
    end

    it "uses the supplied grader as the grader" do
      run

      expect(test_submission.grader).to eq teacher
    end

    it "does not change submissions that are already graded" do
      assignment1.grade_student(student1, grader: teacher, grade: "80%")

      expect do
        run
      end.not_to change {
        test_submission.grade
      }
    end

    it "does not change submissions marked as excused" do
      assignment1.grade_student(student1, grader: teacher, excused: true)

      expect do
        run
      end.not_to change {
        test_submission.grade
      }
    end

    context "when only_apply_to_past_due is true" do
      it "grades submissions that are past due" do
        run(only_apply_to_past_due: true)

        expect(test_submission.grade).to eq "60%"
      end

      it "does not grade submissions due in the future" do
        assignment1.update!(due_at: 10.days.from_now(Time.zone.now))

        expect do
          run(only_apply_to_past_due: true)
        end.not_to change {
          test_submission.grade
        }
      end

      it "does not grade submissions without a due date" do
        assignment1.update!(due_at: nil)

        expect do
          run(only_apply_to_past_due: true)
        end.not_to change {
          test_submission.grade
        }
      end

      it "works with assignment overrides" do
        assignment1.update!(due_at: 1.week.ago(Time.zone.now))
        create_adhoc_override_for_assignment(assignment1, [student1], due_at: 1.week.from_now(Time.zone.now))

        expect do
          run(only_apply_to_past_due: true)
        end.not_to change {
          test_submission.grade
        }
      end
    end

    describe "mark_as_missing" do
      it "marks affected submissions as missing when passed" do
        run(mark_as_missing: true)

        expect(test_submission.late_policy_status).to eq "missing"
      end

      it "uses the supplied grade instead of the grade that would be applied by the missing policy" do
        course.create_late_policy!(
          missing_submission_deduction_enabled: true,
          missing_submission_deduction: 99
        )

        run(mark_as_missing: true)
        expect(test_submission.grade).to eq "60%"
      end
    end

    it "sets affected submissions to excused when the 'excused' option is passed" do
      run(excused: true, percent: nil)
      expect(test_submission).to be_excused
    end

    it "ignores non-active submissions" do
      student1.enrollments.first.deactivate

      expect do
        run
      end.not_to change {
        test_submission.updated_at
      }
    end

    it "ignores ungraded assignments" do
      assignment1.update!(submission_types: "not_graded")

      expect do
        run
      end.not_to change {
        test_submission.updated_at
      }
    end

    it "ignores unpublished assignments" do
      assignment1.unpublish!

      expect do
        run
      end.not_to change {
        test_submission.updated_at
      }
    end

    it "ignores deleted assignments" do
      assignment1.destroy

      expect do
        run
      end.not_to change {
        test_submission.updated_at
      }
    end

    it "ignores moderated assignments whose grades have not been published" do
      assignment1.update!(moderated_grading: true, grader_count: 2, final_grader: teacher)

      expect do
        run
      end.not_to change {
        test_submission.updated_at
      }
    end

    it "ignores students who are not visible to the grader" do
      isolated_section = course.course_sections.create!
      isolated_ta = course.enroll_ta(
        User.create!,
        enrollment_state: "active",
        limit_privileges_to_course_section: true,
        section: isolated_section
      ).user

      expect do
        run(grader: isolated_ta)
      end.not_to change {
        test_submission.updated_at
      }
    end

    describe "grading types" do
      it "works with points-based assignments" do
        assignment1.update!(grading_type: "points", points_possible: 300)
        run

        expect(test_submission.score).to eq 180
        expect(test_submission.grade).to eq "180"
      end

      it "works with percent-based assignments" do
        assignment1.update!(grading_type: "percent", points_possible: 2000)
        run

        expect(test_submission.score).to eq 1200
        expect(test_submission.grade).to eq "60%"
      end

      it "works with GPA scale assignments" do
        assignment1.update!(grading_type: "gpa_scale", points_possible: 50)
        run

        expect(test_submission.score).to eq 30
        expect(test_submission.grade).to eq "F"
      end

      it "works with pass-fail assignments" do
        assignment1.update!(grading_type: "pass_fail", points_possible: 10)
        run

        expect(test_submission.score).to eq 6
        expect(test_submission.grade).to eq "complete"
      end

      it "ignores ungraded assignments" do
        assignment1.update!(grading_type: "not_graded", submission_types: "not_graded")

        expect do
          run
        end.not_to change {
          [test_submission.score, test_submission.grade]
        }
      end
    end
  end
end
