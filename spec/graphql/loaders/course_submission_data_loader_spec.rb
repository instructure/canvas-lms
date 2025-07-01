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
#

require_relative "../../spec_helper"

describe Loaders::CourseSubmissionDataLoader do
  before :once do
    course_with_student(active_all: true)
  end

  def with_batch_loader
    GraphQL::Batch.batch do
      yield Loaders::CourseSubmissionDataLoader.for(current_user: @student)
    end
  end

  describe "#perform" do
    context "with regular assignments" do
      it "includes submissions for regular assignments" do
        assignment = @course.assignments.create!(
          title: "Regular Assignment",
          workflow_state: "published",
          submission_types: "online_text_entry"
        )

        submissions = with_batch_loader { |loader| loader.load(@course) }
        expect(submissions.map(&:assignment_id)).to include(assignment.id)
      end

      it "excludes submissions for unpublished assignments" do
        assignment = @course.assignments.create!(
          title: "Unpublished Assignment",
          workflow_state: "unpublished",
          submission_types: "online_text_entry"
        )

        submissions = with_batch_loader { |loader| loader.load(@course) }
        expect(submissions.map(&:assignment_id)).not_to include(assignment.id)
      end
    end

    context "with checkpointed discussions" do
      before :once do
        @course.root_account.enable_feature!(:discussion_checkpoints)
      end

      it "excludes submissions for parent assignments of checkpointed discussions" do
        parent_assignment = @course.assignments.create!(
          title: "Parent Assignment",
          workflow_state: "published",
          has_sub_assignments: true,
          submission_types: "discussion_topic"
        )

        sub_assignment = parent_assignment.sub_assignments.create!(
          context: @course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          title: "Sub Assignment",
          workflow_state: "published",
          submission_types: "discussion_topic"
        )

        submissions = with_batch_loader { |loader| loader.load(@course) }
        assignment_ids = submissions.map(&:assignment_id)

        expect(assignment_ids).not_to include(parent_assignment.id)
        expect(assignment_ids).to include(sub_assignment.id)
      end

      it "includes submissions for sub-assignments of checkpointed discussions" do
        parent_assignment = @course.assignments.create!(
          title: "Parent Assignment",
          workflow_state: "published",
          has_sub_assignments: true,
          submission_types: "discussion_topic"
        )

        reply_to_topic = parent_assignment.sub_assignments.create!(
          context: @course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          title: "Reply to Topic",
          workflow_state: "published",
          submission_types: "discussion_topic"
        )

        reply_to_entry = parent_assignment.sub_assignments.create!(
          context: @course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
          title: "Reply to Entry",
          workflow_state: "published",
          submission_types: "discussion_topic"
        )

        submissions = with_batch_loader { |loader| loader.load(@course) }
        assignment_ids = submissions.map(&:assignment_id)

        expect(assignment_ids).to include(reply_to_topic.id)
        expect(assignment_ids).to include(reply_to_entry.id)
      end

      it "excludes submissions for unpublished sub-assignments" do
        parent_assignment = @course.assignments.create!(
          title: "Parent Assignment",
          workflow_state: "published",
          has_sub_assignments: true,
          submission_types: "discussion_topic"
        )

        sub_assignment = parent_assignment.sub_assignments.create!(
          context: @course,
          sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
          title: "Unpublished Sub Assignment",
          workflow_state: "unpublished",
          submission_types: "discussion_topic"
        )

        submissions = with_batch_loader { |loader| loader.load(@course) }
        expect(submissions.map(&:assignment_id)).not_to include(sub_assignment.id)
      end
    end

    context "with no current user" do
      it "returns empty array" do
        result = GraphQL::Batch.batch do
          loader = Loaders::CourseSubmissionDataLoader.for(current_user: nil)
          loader.load(@course)
        end
        expect(result).to eq([])
      end
    end

    context "with multiple courses" do
      before :once do
        @original_course = @course
        course_factory(active_all: true)
        @course2 = @course
        @course = @original_course
        @course2.enroll_student(@student, enrollment_state: "active")
      end

      it "groups submissions by course" do
        assignment1 = @course.assignments.create!(
          title: "Course 1 Assignment",
          workflow_state: "published",
          submission_types: "online_text_entry"
        )
        assignment2 = @course2.assignments.create!(
          title: "Course 2 Assignment",
          workflow_state: "published",
          submission_types: "online_text_entry"
        )

        GraphQL::Batch.batch do
          loader = Loaders::CourseSubmissionDataLoader.for(current_user: @student)

          loader.load(@course).then do |submissions1|
            expect(submissions1.map(&:assignment_id)).to include(assignment1.id)
            expect(submissions1.map(&:assignment_id)).not_to include(assignment2.id)
          end

          loader.load(@course2).then do |submissions2|
            expect(submissions2.map(&:assignment_id)).to include(assignment2.id)
            expect(submissions2.map(&:assignment_id)).not_to include(assignment1.id)
          end
        end
      end
    end
  end
end
