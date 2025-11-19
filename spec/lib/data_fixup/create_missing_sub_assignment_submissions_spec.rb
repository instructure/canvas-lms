# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::CreateMissingSubAssignmentSubmissions do
  let(:course) { course_factory(active_course: true) }
  let(:student1) { user_factory(active_all: true) }
  let(:student2) { user_factory(active_all: true) }

  before do
    course.enroll_student(student1, enrollment_state: "active")
    course.enroll_student(student2, enrollment_state: "active")
  end

  describe ".run" do
    context "with SubAssignments missing submissions" do
      let(:parent_assignment) do
        course.assignments.create!(
          has_sub_assignments: true,
          workflow_state: "published",
          grading_type: "points"
        )
      end

      let(:sub_assignment1) do
        parent_assignment.sub_assignments.create!(
          context: course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          workflow_state: "published"
        )
      end

      let(:sub_assignment2) do
        parent_assignment.sub_assignments.create!(
          context: course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
          workflow_state: "published"
        )
      end

      it "creates missing submissions for students with visibility" do
        # Simulate the bug: delete all submissions to mimic the state where they were never created
        Submission.where(assignment_id: [sub_assignment1.id, sub_assignment2.id]).delete_all

        # Ensure no submissions exist (even in unscoped)
        expect(Submission.unscoped.where(assignment_id: sub_assignment1.id).count).to eq(0)
        expect(Submission.unscoped.where(assignment_id: sub_assignment2.id).count).to eq(0)

        described_class.run

        # Verify submissions were created for both students on both sub assignments
        expect(sub_assignment1.submissions.where(user_id: student1.id).count).to eq(1)
        expect(sub_assignment1.submissions.where(user_id: student2.id).count).to eq(1)
        expect(sub_assignment2.submissions.where(user_id: student1.id).count).to eq(1)
        expect(sub_assignment2.submissions.where(user_id: student2.id).count).to eq(1)
      end

      it "creates submissions with unsubmitted workflow state" do
        described_class.run

        sub_assignment1.submissions.each do |submission|
          expect(submission.workflow_state).to eq("unsubmitted")
        end
      end

      it "does not create duplicate submissions when run multiple times" do
        described_class.run
        initial_count = sub_assignment1.submissions.count

        described_class.run
        expect(sub_assignment1.submissions.count).to eq(initial_count)
      end

      it "does not create submission if one already exists" do
        # Create submission for student1 manually
        sub_assignment1.find_or_create_submission(student1)

        described_class.run

        # Should still be 2 total (student1 existing + student2 new)
        expect(sub_assignment1.submissions.count).to eq(2)
      end

      it "does not create submission if a deleted submission exists" do
        # Create and delete a submission for student1
        submission = sub_assignment1.find_or_create_submission(student1)
        submission.update!(workflow_state: "deleted")

        described_class.run

        # Should only create for student2, not recreate student1's deleted one
        expect(sub_assignment1.submissions.active.count).to eq(1)
        expect(sub_assignment1.submissions.active.first.user_id).to eq(student2.id)
      end
    end

    context "with deleted SubAssignments" do
      let(:parent_assignment) do
        course.assignments.create!(
          has_sub_assignments: true,
          workflow_state: "published",
          grading_type: "points"
        )
      end

      let(:deleted_sub_assignment) do
        parent_assignment.sub_assignments.create!(
          context: course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          workflow_state: "deleted"
        )
      end

      it "skips deleted SubAssignments" do
        described_class.run

        expect(deleted_sub_assignment.submissions.count).to eq(0)
      end
    end

    context "with no students enrolled" do
      let(:empty_course) { course_factory(active_course: true) }
      let(:parent_assignment) do
        empty_course.assignments.create!(
          has_sub_assignments: true,
          workflow_state: "published",
          grading_type: "points"
        )
      end

      let(:sub_assignment) do
        parent_assignment.sub_assignments.create!(
          context: empty_course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          workflow_state: "published"
        )
      end

      it "does not create any submissions" do
        described_class.run

        expect(sub_assignment.submissions.count).to eq(0)
      end
    end

    context "with differentiated assignments" do
      let(:section1) { course.course_sections.create!(name: "Section 1") }
      let(:section2) { course.course_sections.create!(name: "Section 2") }
      let(:student_section1) { user_factory(active_all: true) }
      let(:student_section2) { user_factory(active_all: true) }

      let(:parent_assignment) do
        course.assignments.create!(
          has_sub_assignments: true,
          workflow_state: "published",
          grading_type: "points",
          only_visible_to_overrides: true
        )
      end

      let(:sub_assignment) do
        parent_assignment.sub_assignments.create!(
          context: course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          workflow_state: "published"
        )
      end

      before do
        course.enroll_student(student_section1, section: section1, enrollment_state: "active")
        course.enroll_student(student_section2, section: section2, enrollment_state: "active")

        # Only give section1 visibility
        parent_assignment.assignment_overrides.create!(
          set: section1
        )
      end

      it "only creates submissions for students with visibility" do
        # Simulate the bug: delete all submissions to mimic the state where they were never created
        Submission.where(assignment_id: sub_assignment.id).delete_all

        described_class.run

        expect(sub_assignment.submissions.where(user_id: student_section1.id).count).to eq(1)
        expect(sub_assignment.submissions.where(user_id: student_section2.id).count).to eq(0)
      end
    end
  end
end
