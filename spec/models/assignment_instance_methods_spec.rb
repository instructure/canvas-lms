# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Assignment do
  describe "#anonymous_student_identities" do
    before(:once) do
      @course = Course.create!
      @teacher = User.create!
      @first_student = User.create!
      @second_student = User.create!
      course_with_teacher(course: @course, user: @teacher, active_all: true)
      course_with_student(course: @course, user: @first_student, active_all: true)
      course_with_student(course: @course, user: @second_student, active_all: true)
      @assignment = @course.assignments.create!(anonymous_grading: true)
    end

    it "returns an anonymous student name and position for each assigned student" do
      @assignment.submissions.find_by(user: @first_student).update!(anonymous_id: "A")
      @assignment.submissions.find_by(user: @second_student).update!(anonymous_id: "B")
      identity = @assignment.anonymous_student_identities[@first_student.id]
      aggregate_failures do
        expect(identity[:name]).to eq "Student 1"
        expect(identity[:position]).to eq 1
      end
    end

    it "sorts identities by anonymous_id, case sensitive" do
      @assignment.submissions.find_by(user: @first_student).update!(anonymous_id: "A")
      @assignment.submissions.find_by(user: @second_student).update!(anonymous_id: "B")

      expect do
        @assignment.submissions.find_by(user: @first_student).update!(anonymous_id: "a")
      end.to change {
        Assignment.find(@assignment.id).anonymous_student_identities.dig(@first_student.id, :position)
      }.from(1).to(2)
    end

    it "performs a secondary sort on hashed ID" do
      sub1 = @assignment.submissions.find_by(user: @first_student)
      sub1.update!(anonymous_id: nil)
      sub2 = @assignment.submissions.find_by(user: @second_student)
      sub2.update!(anonymous_id: nil)
      initial_student_first = Digest::MD5.hexdigest(sub1.id.to_s) < Digest::MD5.hexdigest(sub2.id.to_s)
      first_student_position = @assignment.anonymous_student_identities.dig(@first_student.id, :position)
      expect(first_student_position).to eq(initial_student_first ? 1 : 2)
    end
  end

  describe "#hide_on_modules_view?" do
    before(:once) do
      @course = Course.create!
    end

    it "returns true when the assignment is in the failed_to_duplicate state" do
      assignment = @course.assignments.create!(workflow_state: "failed_to_duplicate", **assignment_valid_attributes)
      expect(assignment.hide_on_modules_view?).to be true
    end

    it "returns true when the assignment is in the duplicating state" do
      assignment = @course.assignments.create!(workflow_state: "duplicating", **assignment_valid_attributes)
      expect(assignment.hide_on_modules_view?).to be true
    end

    it "returns false when the assignment is in the published state" do
      assignment = @course.assignments.create!(workflow_state: "published", **assignment_valid_attributes)
      expect(assignment.hide_on_modules_view?).to be false
    end

    it "returns false when the assignment is in the unpublished state" do
      assignment = @course.assignments.create!(workflow_state: "unpublished", **assignment_valid_attributes)
      expect(assignment.hide_on_modules_view?).to be false
    end
  end

  describe "#grade_student" do
    describe "checkpointed discussions" do
      before do
        course_with_teacher(active_all: true)
        @student = student_in_course(active_all: true).user
        @course.root_account.enable_feature!(:discussion_checkpoints)
        assignment = @course.assignments.create!(checkpointed: true, checkpoint_label: CheckpointLabels::PARENT)
        assignment.checkpoint_assignments.create!(context: @course, checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC, due_at: 2.days.from_now)
        assignment.checkpoint_assignments.create!(context: @course, checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY, due_at: 3.days.from_now)
        @topic = @course.discussion_topics.create!(assignment:, reply_to_entry_required_count: 1)
      end

      let(:reply_to_topic_submission) do
        @topic.reply_to_topic_checkpoint.submissions.find_by(user: @student)
      end

      let(:reply_to_entry_submission) do
        @topic.reply_to_entry_checkpoint.submissions.find_by(user: @student)
      end

      it "supports grading checkpoints" do
        @topic.assignment.grade_student(@student, grader: @teacher, score: 5, checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC)
        @topic.assignment.grade_student(@student, grader: @teacher, score: 2, checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY)
        expect(reply_to_topic_submission.score).to eq 5
        expect(reply_to_entry_submission.score).to eq 2
      end

      it "raises an error if no checkpoint label is provided" do
        expect do
          @topic.assignment.grade_student(@student, grader: @teacher, score: 5)
        end.to raise_error(Assignment::GradeError, "Must provide a valid checkpoint label when grading checkpointed discussions")
      end

      it "raises an error if an invalid checkpoint label is provided" do
        expect do
          @topic.assignment.grade_student(@student, grader: @teacher, score: 5, checkpoint_label: "potato")
        end.to raise_error(Assignment::GradeError, "Must provide a valid checkpoint label when grading checkpointed discussions")
      end

      it "returns the submissions for the 'parent' assignment" do
        submissions = @topic.assignment.grade_student(@student, grader: @teacher, score: 5, checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC)
        expect(submissions.map(&:assignment_id).uniq).to eq [@topic.assignment.id]
      end

      it "ignores checkpoints when the feature flag is disabled" do
        @course.root_account.disable_feature!(:discussion_checkpoints)
        @topic.assignment.grade_student(@student, grader: @teacher, score: 5, checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC)
        expect(reply_to_topic_submission.score).to be_nil
        expect(@topic.assignment.submissions.find_by(user: @student).score).to eq 5
      end
    end
  end

  describe "checkpointed discussions" do
    before(:once) do
      course = course_model
      course.root_account.enable_feature!(:discussion_checkpoints)
      @topic = @course.discussion_topics.create!(title: "graded topic")
      @topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint_assignment = @topic.reply_to_topic_checkpoint
    end

    it "updates the parent assignment when tracked attrs change on a checkpoint assignment" do
      expect { @checkpoint_assignment.update!(points_possible: 4) }.to change {
        @topic.assignment.reload.points_possible
      }.from(10).to(11)
    end

    it "does not update the parent assignment when attrs that changed are not tracked" do
      expect { @checkpoint_assignment.update!(title: "potato") }.not_to change {
        @topic.assignment.reload.updated_at
      }
    end

    it "does not update the parent assignment when the checkpoints flag is disabled" do
      @topic.root_account.disable_feature!(:discussion_checkpoints)
      expect { @checkpoint_assignment.update!(points_possible: 4) }.not_to change {
        @topic.assignment.reload.points_possible
      }
    end
  end
end
