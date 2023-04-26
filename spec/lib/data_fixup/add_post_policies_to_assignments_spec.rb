# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe DataFixup::AddPostPoliciesToAssignments do
  let_once(:course) { Course.create! }
  let_once(:assignment) do
    @assignment = course.assignments.create!
    @assignment.unmute!
    @assignment
  end

  let_once(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let_once(:student1) { course.enroll_student(User.create!, enrollment_state: "active").user }
  let_once(:student2) { course.enroll_student(User.create!, enrollment_state: "active").user }

  def run_for_submissions
    submission_ids = Submission.all.order(:id).pluck(:id)
    DataFixup::AddPostPoliciesToAssignments.set_submission_posted_at_dates(submission_ids.first, submission_ids.last)
  end

  def run_for_courses
    DataFixup::AddPostPoliciesToAssignments.create_post_policies(course.id, course.id + 1)
  end

  def clear_post_policy(assignment:)
    assignment.post_policy&.destroy
    assignment.reload
  end

  describe ".set_submission_posted_at_dates" do
    before(:once) do
      clear_post_policy(assignment: assignment)
    end

    context "for an assignment that would receive a manual post policy" do
      it "sets the posted_at of submissions to nil" do
        run_for_submissions
        expect(assignment.submission_for_student(student1).posted_at).to be_nil
      end
    end

    context "for an assignment that would receive an automatic post policy" do
      it "sets the posted_at of graded submissions to their graded_at time" do
        assignment.grade_student(student1, grader: teacher, score: 10)
        assignment.unmute!
        student1_submission = assignment.submission_for_student(student1)

        student1_submission.update!(posted_at: nil)
        assignment.reload.update!(muted: false)
        clear_post_policy(assignment: assignment)
        run_for_submissions

        expect(student1_submission.reload.posted_at).to eq(student1_submission.graded_at)
      end

      it "sets the posted_at of ungraded submissions to nil" do
        run_for_submissions
        expect(assignment.submission_for_student(student1).reload.posted_at).to be_nil
      end
    end

    it "does not update submissions for an assignment that already has a post policy" do
      expect do
        run_for_submissions
      end.not_to change {
        assignment.submission_for_student(student1).reload.updated_at
      }
    end

    context "for an assignment with an existing post policy" do
      it "does not update the submissions associated with the assignment" do
        assignment.ensure_post_policy(post_manually: true)

        expect do
          run_for_submissions
        end.not_to change {
          assignment.submission_for_student(student1).reload.updated_at
        }
      end
    end
  end

  describe ".create_post_policies" do
    context "when a course does not have an existing post policy" do
      before(:once) do
        course.default_post_policy.destroy
        clear_post_policy(assignment: assignment)
      end

      describe "assignment post policy creation" do
        it "creates a manual post policy when the assignment is moderated" do
          moderated_assignment = course.assignments.create!(
            final_grader: teacher,
            grader_count: 2,
            moderated_grading: true
          )
          clear_post_policy(assignment: moderated_assignment)

          run_for_courses
          expect(moderated_assignment.reload.post_policy).to be_post_manually
        end

        it "creates a manual post policy when the assignment is anonymously graded" do
          anonymous_assignment = course.assignments.create!(anonymous_grading: true)
          clear_post_policy(assignment: anonymous_assignment)

          run_for_courses
          expect(anonymous_assignment.reload.post_policy).to be_post_manually
        end

        it "creates a manual post policy when the assignment is muted" do
          assignment.mute!
          clear_post_policy(assignment: assignment)

          run_for_courses
          expect(assignment.reload.post_policy).to be_post_manually
        end

        it "creates an automatic post policy when the assignment does not need to be manually-posted" do
          run_for_courses
          expect(assignment.post_policy).not_to be_post_manually
        end

        it "does not update assignments that already have a post policy" do
          assignment.ensure_post_policy(post_manually: true)

          expect do
            run_for_courses
          end.not_to change {
            PostPolicy.find_by!(assignment: assignment).updated_at
          }
        end
      end

      it "creates an automatic post policy for the course" do
        run_for_courses
        expect(course.default_post_policy).not_to be_post_manually
      end
    end

    context "when a course already has a post policy" do
      before(:once) do
        PostPolicy.create!(course_id: course, assignment_id: nil, post_manually: false)

        assignment.ensure_post_policy(post_manually: true)
      end

      it "does not update the course post policy" do
        expect do
          run_for_courses
        end.not_to change {
          PostPolicy.find_by!(course: course, assignment: nil).updated_at
        }
      end

      it "does not update assignments within the course" do
        expect do
          run_for_courses
        end.not_to change {
          PostPolicy.find_by!(assignment: assignment).updated_at
        }
      end
    end
  end
end
