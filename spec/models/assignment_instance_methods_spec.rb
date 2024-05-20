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
  describe "asset strings" do
    it "can be found via asset string" do
      course = Course.create!
      assignment = course.assignments.create!
      expect(ActiveRecord::Base.find_by_asset_string(assignment.asset_string)).to eq assignment
    end
  end

  describe "serialization" do
    before do
      course = Course.create!
      @assignment = course.assignments.create!
    end

    it "uses assignment as the root key for as_json" do
      expect(@assignment.as_json).to have_key "assignment"
    end

    it "uses assignment as the root key for to_json" do
      expect(JSON.parse(@assignment.to_json)).to have_key "assignment"
    end
  end

  describe "validations" do
    it "must have a blank sub_assignment_tag" do
      assignment = Assignment.new(sub_assignment_tag: "my_tag")
      assignment.validate
      expect(assignment.errors.full_messages).to include "Sub assignment tag must be blank"
    end
  end

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
        @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 4
        )

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 7
        )
      end

      let(:reply_to_topic_submission) do
        @topic.reply_to_topic_checkpoint.submissions.find_by(user: @student)
      end

      let(:reply_to_entry_submission) do
        @topic.reply_to_entry_checkpoint.submissions.find_by(user: @student)
      end

      let(:parent_submission) do
        @topic.assignment.submissions.find_by(user: @student)
      end

      it "supports grading checkpoints" do
        @topic.assignment.grade_student(@student, grader: @teacher, score: 5, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        @topic.assignment.grade_student(@student, grader: @teacher, score: 2, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)
        aggregate_failures do
          expect(reply_to_topic_submission.score).to eq 5
          expect(reply_to_entry_submission.score).to eq 2
          expect(parent_submission.score).to eq 7
        end
      end

      it "incorporates the checkpointed discussion's score into the overall current grade upon all checkpoints having been posted" do
        @topic.assignment.grade_student(@student, grader: @teacher, score: 5, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        enrollment = @course.enrollments.find_by(user: @student)

        expect do
          @topic.assignment.grade_student(@student, grader: @teacher, score: 2, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)
        end.to change {
          enrollment.reload.computed_current_score
        }.from(nil).to(63.64) # (5 + 2) / 11 points possible => 63.64%
      end

      it "raises an error if no checkpoint label is provided" do
        expect do
          @topic.assignment.grade_student(@student, grader: @teacher, score: 5)
        end.to raise_error(Assignment::GradeError, "Must provide a valid sub assignment tag when grading checkpointed discussions")
      end

      it "raises an error if an invalid checkpoint label is provided" do
        expect do
          @topic.assignment.grade_student(@student, grader: @teacher, score: 5, sub_assignment_tag: "potato")
        end.to raise_error(Assignment::GradeError, "Must provide a valid sub assignment tag when grading checkpointed discussions")
      end

      it "returns the submissions for the 'parent' assignment" do
        submissions = @topic.assignment.grade_student(@student, grader: @teacher, score: 5, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        expect(submissions.map(&:assignment_id).uniq).to eq [@topic.assignment.id]
      end

      it "ignores checkpoints when the feature flag is disabled" do
        @course.root_account.disable_feature!(:discussion_checkpoints)
        @topic.assignment.grade_student(@student, grader: @teacher, score: 5, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        expect(reply_to_topic_submission.score).to be_nil
        expect(@topic.assignment.submissions.find_by(user: @student).score).to eq 5
      end
    end
  end

  describe "#destroy" do
    subject { assignment.destroy! }

    context "with external tool assignment" do
      let(:course) { course_model }
      let(:tool) { external_tool_1_3_model(context: course) }
      let(:assignment) do
        course.assignments.create!(
          submission_types: "external_tool",
          external_tool_tag_attributes: {
            url: tool.url,
            content_type: "ContextExternalTool",
            content_id: tool.id
          },
          points_possible: 42
        )
      end

      it "destroys resource links and keeps them associated" do
        expect(assignment.lti_resource_links.first).to be_active
        subject
        expect(assignment.lti_resource_links.first).to be_deleted
      end
    end
  end

  describe "#restore" do
    subject { assignment.restore }

    context "with external tool assignment" do
      let(:course) { course_model }
      let(:tool) { external_tool_1_3_model(context: course) }
      let(:assignment) do
        course.assignments.create!(
          submission_types: "external_tool",
          external_tool_tag_attributes: {
            url: tool.url,
            content_type: "ContextExternalTool",
            content_id: tool.id
          },
          points_possible: 42
        )
      end

      before do
        assignment.destroy!
      end

      it "restores resource links" do
        expect(assignment.lti_resource_links.first).to be_deleted
        subject
        expect(assignment.lti_resource_links.first).to be_active
      end

      it "restores external tool tag" do
        expect(assignment.external_tool_tag.reload).to be_deleted
        subject
        expect(assignment.external_tool_tag.reload).to be_active
      end
    end
  end

  # TODO: move all these specs from old file to here
  describe "Lti::Migratable" do
    let(:url) { "http://www.example.com" }
    let(:account) { account_model }
    let(:course) { course_model(account:) }
    let(:developer_key) { dev_key_model_1_3(account:) }
    let(:old_tool) { external_tool_model(context: course, opts: { url: }) }
    let(:new_tool) { external_tool_1_3_model(context: course, developer_key:, opts: { url:, name: "1.3 tool" }) }
    let(:direct_assignment) do
      assignment_model(
        context: course,
        name: "Direct Assignment",
        submission_types: "external_tool",
        external_tool_tag_attributes: { content: old_tool },
        lti_context_id: SecureRandom.uuid
      )
    end
    let(:unpublished_direct) do
      a = direct_assignment.dup
      a.update!(lti_context_id: SecureRandom.uuid, workflow_state: "unpublished", external_tool_tag_attributes: { content: old_tool })
      a
    end
    let(:indirect_assignment) do
      assign = assignment_model(
        context: course,
        name: "Indirect Assignment",
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: },
        lti_context_id: SecureRandom.uuid
      )
      # There's an before_save hook that looks up the appropriate tool
      # based on the URL. Great for production, bad for testing :(
      assign.external_tool_tag.update_column(:content_id, nil)
      assign
    end
    let(:unpublished_indirect) do
      a = indirect_assignment.dup
      a.update!(lti_context_id: SecureRandom.uuid, workflow_state: "unpublished", external_tool_tag_attributes: { url: })
      a.external_tool_tag.update_column(:content_id, nil)
      a
    end

    describe "#migrate_to_1_3_if_needed!" do
      subject { direct_assignment.migrate_to_1_3_if_needed!(new_tool) }
      # existing specs in spec/models/assignment_spec.rb:11448

      context "when the line item fails to save" do
        before do
          allow(direct_assignment.line_items).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "rolls back the resource link creation" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          expect(direct_assignment.lti_resource_links).to be_empty
          expect(direct_assignment.line_items).to be_empty
        end
      end
    end
  end
end
