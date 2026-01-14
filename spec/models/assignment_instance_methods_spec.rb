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

  describe "cross-shard" do
    specs_require_sharding
    before(:once) do
      @shard1.activate do
        @cross_shard_student = User.create!
      end

      @shard2.activate do
        account = @account = Account.create!
        @course2 = Course.create!(account:, workflow_state: "available")
        @teacher = course_with_teacher(active_all: true, course: @course2).user
        @student1 = student_in_course(active_all: true).user
        @student2 = student_in_course(active_all: true).user
        @student3 = student_in_course(active_all: true).user
        @course2.enroll_student(@cross_shard_student, enrollment_state: "active")

        @assignment = @course2.assignments.create(points_possible: 100)
        @assignment.submit_homework @student1, body: "EHLO"
        @assignment.submit_homework @student2, body: "EHLO"
        @assignment.submit_homework @cross_shard_student, body: "EHLO_cross"
        @assignment.grade_student @student1, score: 99, grader: @teacher
        @assignment.grade_student(@cross_shard_student, grade: 9, grader: @teacher)
      end
    end

    it "returns all representatives with assignment overrides" do
      # we could spec some examples, but this way it works for any overrides.
      allow_any_instance_of(AbstractAssignment).to receive(:differentiated_assignments_applies?).and_return(true)
      @shard1.activate do
        expect(Assignment.find(@assignment.global_id).representatives(user: @teacher).map(&:id).sort).to match([@cross_shard_student.id, @student1.global_id, @student2.global_id, @student3.global_id].sort)
      end
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

  describe "unsupported_in_speedgrader_2?" do
    before do
      @course = Course.create!
      course_with_student(course: @course, active_all: true)
    end

    context "based on submission types" do
      it "allows dynamically dropping support for particular assignment types" do
        a = @course.assignments.create!(submission_types: "online_upload")

        expect { Setting.set("submission_types_unsupported_in_sg2", "online_upload") }.to change {
          a.unsupported_in_speedgrader_2?
        }.from(false).to(true)
      end

      it "for assignments with multiple types, does not support that assignment if any of its types are unsupported" do
        a = @course.assignments.create!(submission_types: "online_text_entry,online_upload")

        expect { Setting.set("submission_types_unsupported_in_sg2", "online_upload") }.to change {
          a.unsupported_in_speedgrader_2?
        }.from(false).to(true)
      end

      it "continues to support assignment types not specified in the Setting" do
        a = @course.assignments.create!(submission_types: "online_upload")

        expect { Setting.set("submission_types_unsupported_in_sg2", "online_text_entry") }.not_to change {
          a.unsupported_in_speedgrader_2?
        }.from(false)
      end

      it "ignores leading/trailing spaces in the Setting value" do
        a = @course.assignments.create!(submission_types: "online_upload")

        expect { Setting.set("submission_types_unsupported_in_sg2", " online_upload  ") }.to change {
          a.unsupported_in_speedgrader_2?
        }.from(false).to(true)
      end
    end

    context "based on grading type" do
      it "allows dynamically dropping support for particular grading types" do
        a = @course.assignments.create!(submission_types: "online_text_entry", grading_type: "letter_grade")

        expect { Setting.set("grading_types_unsupported_in_sg2", "letter_grade") }.to change {
          a.unsupported_in_speedgrader_2?
        }.from(false).to(true)
      end

      it "continues to support grading types not specified in the Setting" do
        a = @course.assignments.create!(submission_types: "online_text_entry", grading_type: "points")

        expect { Setting.set("grading_types_unsupported_in_sg2", "letter_grade") }.not_to change {
          a.unsupported_in_speedgrader_2?
        }.from(false)
      end

      it "ignores leading/trailing spaces in the Setting value" do
        a = @course.assignments.create!(submission_types: "online_text_entry", grading_type: "letter_grade")

        expect { Setting.set("grading_types_unsupported_in_sg2", " letter_grade ") }.to change {
          a.unsupported_in_speedgrader_2?
        }.from(false).to(true)
      end
    end

    context "based on features" do
      it "returns true by default for moderated assignments" do
        a = @course.assignments.create!(moderated_grading: true, grader_count: 1)
        expect(a).to be_unsupported_in_speedgrader_2
      end

      it "returns false if feature flag is enabled" do
        Account.site_admin.enable_feature!(:moderated_grading_modernized_speedgrader)
        a = @course.assignments.create!(moderated_grading: true, grader_count: 1)
        expect(a).not_to be_unsupported_in_speedgrader_2
      end

      it "conditionally allows moderated assignments" do
        a = @course.assignments.create!(moderated_grading: true, grader_count: 1)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "")
        end.to change { a.unsupported_in_speedgrader_2? }.from(true).to(false)
      end

      it "allows dynamically dropping support for peer review assignments" do
        a = @course.assignments.create!(peer_reviews: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "peer")
        end.to change { a.unsupported_in_speedgrader_2? }.from(false).to(true)
      end

      it "allows dynamically dropping support for group assignments" do
        group_category = @course.group_categories.create!(name: "My Group Category")
        a = @course.assignments.create!(group_category:)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "group")
        end.to change { a.unsupported_in_speedgrader_2? }.from(false).to(true)
      end

      it "allows dynamically dropping support for group assignments graded as group" do
        group_category = @course.group_categories.create!(name: "My Group Category")
        group_grade = @course.assignments.create!(group_category:, grade_group_students_individually: false)
        individual_grade = @course.assignments.create!(group_category:, grade_group_students_individually: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "group_graded_group")
        end.to change { [group_grade.unsupported_in_speedgrader_2?, individual_grade.unsupported_in_speedgrader_2?] }.from([false, false]).to([true, false])
      end

      it "allows dynamically dropping support for group assignments graded individually" do
        group_category = @course.group_categories.create!(name: "My Group Category")
        group_grade = @course.assignments.create!(group_category:, grade_group_students_individually: false)
        individual_grade = @course.assignments.create!(group_category:, grade_group_students_individually: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "group_graded_ind")
        end.to change { [group_grade.unsupported_in_speedgrader_2?, individual_grade.unsupported_in_speedgrader_2?] }.from([false, false]).to([false, true])
      end

      it "allows dynamically dropping support for anonymous assignments" do
        anonymous = @course.assignments.create!(anonymous_grading: true)
        anonymous.post_submissions
        anonymized = @course.assignments.create!(anonymous_grading: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "anonymous")
        end.to change { [anonymous.unsupported_in_speedgrader_2?, anonymized.unsupported_in_speedgrader_2?] }.from([false, false]).to([true, true])
      end

      it "allows dynamically dropping support for actively anonymized assignments (anon assignments that haven't been posted to students yet)" do
        anonymous = @course.assignments.create!(anonymous_grading: true)
        anonymous.post_submissions
        anonymized = @course.assignments.create!(anonymous_grading: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "anonymized")
        end.to change { [anonymous.unsupported_in_speedgrader_2?, anonymized.unsupported_in_speedgrader_2?] }.from([false, false]).to([false, true])
      end

      it "allows dynamically dropping support for new quizzes" do
        a = @course.assignments.build(submission_types: "external_tool")
        tool = @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
        a.external_tool_tag_attributes = { content: tool }
        a.save!

        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "new_quiz")
        end.to change { a.unsupported_in_speedgrader_2? }.from(false).to(true)
      end

      it "allows dynamically dropping support for assignments with rubrics attached" do
        rubric = rubric_model({
                                context: @course,
                                title: "Test Rubric",
                                data: [{
                                  description: "Some criterion",
                                  points: 10,
                                  id: "crit1",
                                  ignore_for_scoring: true,
                                  ratings: [
                                    { description: "Good", points: 10, id: "rat1", criterion_id: "crit1" }
                                  ]
                                }]
                              })
        a = @course.assignments.create!(submission_types: "online_text_entry")
        rubric.associate_with(a, @course, purpose: "grading")
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "rubric")
        end.to change { a.unsupported_in_speedgrader_2? }.from(false).to(true)
      end

      it "supports multiple features" do
        group_category = @course.group_categories.create!(name: "My Group Category")
        group = @course.assignments.create!(group_category:)
        anonymous = @course.assignments.create!(anonymous_grading: true)
        peer = @course.assignments.create!(peer_reviews: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "group,peer")
        end.to change { [group.unsupported_in_speedgrader_2?, anonymous.unsupported_in_speedgrader_2?, peer.unsupported_in_speedgrader_2?] }.from([false, false, false]).to([true, false, true])
      end

      it "ignores bogus values stored in the setting" do
        a = @course.assignments.create!(peer_reviews: true)
        expect do
          Setting.set("assignment_features_unsupported_in_sg2", "hackerman,peer,sql_injection_evil, ")
        end.to change { a.unsupported_in_speedgrader_2? }.from(false).to(true)
      end
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
    let(:developer_key) { lti_developer_key_model(account:) }
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

  describe "checkpoint due date validation" do
    before do
      course_with_teacher(active_all: true)
      @course.root_account.enable_feature!(:discussion_checkpoints)
      @course.root_account.enable_feature!(:new_sis_integrations)
      @course.enable_feature!(:post_grades)
      @course.root_account.settings[:sis_require_assignment_due_date] = { value: true }
      @course.root_account.settings[:sis_syncing] = { value: true }
      @course.root_account.save!
    end

    describe "#due_date_ok?" do
      context "when assignment is a checkpoints parent" do
        before do
          @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
          @assignment = @topic.assignment
          @assignment.update!(has_sub_assignments: true)
        end

        context "with sub_assignments present" do
          before do
            Checkpoints::DiscussionCheckpointCreatorService.call(
              discussion_topic: @topic,
              checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
              points_possible: 10,
              dates: [{ type: "everyone", due_at: 1.day.from_now }]
            )
          end

          it "validates normally when sub_assignments exist" do
            @assignment.assign_attributes(post_to_sis: true, due_at: nil)
            expect(@assignment.valid?).to be false
            expect(@assignment.errors[:due_at]).to include("cannot be blank when Post to Sis is checked")
          end

          it "allows nil due_at when not posting to sis" do
            @assignment.assign_attributes(post_to_sis: false, due_at: nil)
            expect(@assignment.valid?).to be true
          end
        end

        context "with empty sub_assignments and new record" do
          it "skips sis due date validation for new checkpoints parent" do
            new_assignment = Assignment.new(
              course: @course,
              title: "New Checkpoints Assignment",
              has_sub_assignments: true,
              post_to_sis: true,
              due_at: nil
            )
            allow(new_assignment).to receive_messages(checkpoints_parent?: true, sub_assignments: double(empty?: true))

            expect(new_assignment.valid?).to be true
          end

          it "validates normally for existing checkpoints parent with empty sub_assignments" do
            @assignment.save!
            @assignment.assign_attributes(post_to_sis: true, due_at: nil)
            expect(@assignment.valid?).to be false
            expect(@assignment.errors[:due_at]).to include("cannot be blank when Post to Sis is checked")
          end
        end
      end

      context "when assignment is not a checkpoints parent" do
        before do
          @assignment = @course.assignments.create!(title: "Regular Assignment")
        end

        it "validates due_at normally" do
          @assignment.assign_attributes(post_to_sis: true, due_at: nil)
          expect(@assignment.valid?).to be false
          expect(@assignment.errors[:due_at]).to include("cannot be blank when Post to Sis is checked")
        end
      end

      context "with availability date constraints" do
        before do
          @assignment = @course.assignments.create!(title: "Assignment with dates")
        end

        it "validates due_at is between unlock_at and lock_at" do
          @assignment.unlock_at = 2.days.from_now
          @assignment.due_at = 1.day.from_now
          @assignment.lock_at = 3.days.from_now

          expect(@assignment.valid?).to be false
          expect(@assignment.errors[:due_at]).to include("must be between availability dates")
        end
      end
    end

    describe "#assignment_overrides_due_date_ok?" do
      before do
        @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @assignment = @topic.assignment
        @assignment.update!(has_sub_assignments: true, due_at: 3.days.from_now)
        @student = student_in_course(active_all: true).user
      end

      context "when assignment is a checkpoints parent" do
        before do
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            points_possible: 5,
            dates: [{ type: "everyone", due_at: 1.day.from_now }]
          )
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
            points_possible: 6,
            dates: [{ type: "everyone", due_at: 2.days.from_now }]
          )
        end

        it "uses sub_assignment_overrides for validation" do
          @assignment.assign_attributes(post_to_sis: true)
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: nil,
            due_at_overridden: true
          )
          override.assignment_override_students.create!(user: @student)

          expect(@assignment.send(:assignment_overrides_due_date_ok?)).to be false
          expect(@assignment.errors[:due_at]).to include("cannot be blank for any assignees when Post to Sis is checked")
        end

        it "passes validation when all sub_assignment overrides have due dates" do
          @assignment.assign_attributes(post_to_sis: true)
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: 3.days.from_now,
            due_at_overridden: true
          )
          override.assignment_override_students.create!(user: @student)

          expect(@assignment.send(:assignment_overrides_due_date_ok?)).to be true
        end

        it "ignores deleted overrides" do
          @assignment.assign_attributes(post_to_sis: true)
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: nil,
            due_at_overridden: true,
            workflow_state: "deleted"
          )
          override.assignment_override_students.create!(user: @student)

          expect(@assignment.send(:assignment_overrides_due_date_ok?)).to be true
        end

        it "validates with provided override data for checkpoints parent" do
          @assignment.assign_attributes(post_to_sis: true)
          # For checkpoints parent, the method ignores provided override data and uses sub_assignment_overrides
          # So we need to create a sub_assignment override with nil due_at to trigger the failure
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: nil,
            due_at_overridden: true
          )
          override.assignment_override_students.create!(user: @student)

          # Even though we pass override data, it should use sub_assignment_overrides
          override_data = [
            { due_at: 2.days.from_now, due_at_overridden: true, workflow_state: "active" }
          ]

          expect(@assignment.send(:assignment_overrides_due_date_ok?, override_data)).to be false
          expect(@assignment.errors[:due_at]).to include("cannot be blank for any assignees when Post to Sis is checked")
        end
      end

      context "when assignment is not a checkpoints parent" do
        before do
          @regular_assignment = @course.assignments.create!(title: "Regular Assignment", due_at: 3.days.from_now)
        end

        it "uses regular assignment_overrides for validation" do
          @regular_assignment.assign_attributes(post_to_sis: true)
          override = @regular_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            due_at: nil,
            due_at_overridden: true
          )
          override.assignment_override_students.create!(user: @student)

          expect(@regular_assignment.send(:assignment_overrides_due_date_ok?)).to be false
          expect(@regular_assignment.errors[:due_at]).to include("cannot be blank for any assignees when Post to Sis is checked")
        end
      end

      it "returns true when skip_sis_due_date_validation is set" do
        @assignment.instance_variable_set(:@skip_sis_due_date_validation, true)
        expect(@assignment.send(:assignment_overrides_due_date_ok?)).to be true
      end
    end

    describe "#gather_override_data" do
      before do
        @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @assignment = @topic.assignment
        @assignment.update!(has_sub_assignments: true, due_at: 3.days.from_now)
        @student = student_in_course(active_all: true).user
      end

      context "when assignment is a checkpoints parent" do
        before do
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            points_possible: 5,
            dates: [{ type: "everyone", due_at: 1.day.from_now }]
          )
        end

        it "merges sub_assignment_overrides with provided overrides" do
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          existing_override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: 1.day.from_now
          )
          existing_override.assignment_override_students.create!(user: @student)

          new_due_date = 2.days.from_now
          new_override_data = [
            { id: nil, due_at: new_due_date, due_at_overridden: true }
          ]

          result = @assignment.send(:gather_override_data, new_override_data)

          expect(result.size).to eq 2
          expect(result).to include(hash_including(due_at: new_due_date))
        end

        it "handles hash input with values" do
          due_date = 3.days.from_now
          override_hash = {
            "0" => { due_at: due_date, due_at_overridden: true },
            "1" => {}
          }

          result = @assignment.send(:gather_override_data, override_hash)
          expect(result.size).to eq 1
          expect(result.first[:due_at]).to eq due_date
        end

        it "adds due_at_overridden when missing" do
          override_data = [{ due_at: 2.days.from_now }]
          result = @assignment.send(:gather_override_data, override_data)

          expect(result.first[:due_at_overridden]).to be true
        end

        it "excludes existing overrides by id" do
          sub_assignment = @assignment.sub_assignments.first
          parent_override = @assignment.assignment_overrides.create!(set_type: "ADHOC")
          existing_override = sub_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            parent_override:,
            due_at: 1.day.from_now
          )

          new_due_date = 2.days.from_now
          override_data = [
            { id: existing_override.id, due_at: new_due_date, due_at_overridden: true }
          ]

          result = @assignment.send(:gather_override_data, override_data)
          expect(result.size).to eq 1
          expect(result.first[:due_at]).to eq new_due_date
        end
      end

      context "when assignment is not a checkpoints parent" do
        before do
          @regular_assignment = @course.assignments.create!(title: "Regular Assignment", due_at: 3.days.from_now)
        end

        it "merges assignment_overrides with provided overrides" do
          existing_override = @regular_assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            due_at: 1.day.from_now
          )
          existing_override.assignment_override_students.create!(user: @student)

          new_due_date = 2.days.from_now
          new_override_data = [
            { id: nil, due_at: new_due_date, due_at_overridden: true }
          ]

          result = @regular_assignment.send(:gather_override_data, new_override_data)

          expect(result.size).to eq 2
          expect(result).to include(hash_including(due_at: new_due_date))
        end
      end
    end
  end

  describe "peer review sub assignment sync" do
    before :once do
      @course = course_factory(active_all: true)
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @parent_assignment = @course.assignments.create!(
        title: "Parent Assignment",
        peer_reviews: true,
        anonymous_peer_reviews: false,
        automatic_peer_reviews: false
      )
      @peer_review_sub = PeerReviewSubAssignment.create!(
        parent_assignment: @parent_assignment,
        title: "Parent Assignment Peer Review"
      )
    end

    describe "#should_sync_peer_review_sub_assignment?" do
      it "returns false when feature flag is disabled" do
        @course.disable_feature!(:peer_review_allocation_and_grading)
        @parent_assignment.description = "New description"
        @parent_assignment.save!
        expect(@parent_assignment.send(:should_sync_peer_review_sub_assignment?)).to be false
      end

      it "returns false when peer_review_sub_assignment does not exist" do
        assignment = @course.assignments.create!(title: "No Peer Review")
        assignment.description = "New description"
        assignment.save!
        expect(assignment.send(:should_sync_peer_review_sub_assignment?)).to be false
      end

      it "returns false when no sync attributes changed" do
        @parent_assignment.points_possible = 100
        @parent_assignment.save!
        expect(@parent_assignment.send(:should_sync_peer_review_sub_assignment?)).to be false
      end

      it "returns true when sync attributes changed and conditions met" do
        @parent_assignment.description = "New description"
        @parent_assignment.save!
        expect(@parent_assignment.send(:should_sync_peer_review_sub_assignment?)).to be true
      end
    end

    describe "#sync_peer_review_sub_assignment" do
      it "syncs anonymous_peer_reviews when changed" do
        @parent_assignment.update!(anonymous_peer_reviews: true)
        expect(@peer_review_sub.reload.anonymous_peer_reviews).to be true
      end

      it "syncs automatic_peer_reviews when changed" do
        @parent_assignment.update!(automatic_peer_reviews: true)
        expect(@peer_review_sub.reload.automatic_peer_reviews).to be true
      end

      it "syncs description when changed" do
        @parent_assignment.update!(description: "New description")
        expect(@peer_review_sub.reload.description).to eq "New description"
      end

      it "syncs workflow_state when changed" do
        @parent_assignment.update!(workflow_state: "deleted")
        expect(@peer_review_sub.reload.workflow_state).to eq "deleted"
      end

      it "syncs peer_reviews_due_at when changed" do
        due_date = 3.days.from_now
        @parent_assignment.update!(peer_reviews_due_at: due_date)
        expect(@peer_review_sub.reload.peer_reviews_due_at).to be_within(1.second).of(due_date)
      end

      it "syncs assignment_group_id when changed" do
        new_group = @course.assignment_groups.create!(name: "New Group")
        @parent_assignment.update!(assignment_group_id: new_group.id)
        expect(@peer_review_sub.reload.assignment_group_id).to eq new_group.id
      end

      it "syncs group_category_id when changed" do
        group_category = @course.group_categories.create!(name: "Test Category")
        @parent_assignment.update!(group_category_id: group_category.id)
        expect(@peer_review_sub.reload.group_category_id).to eq group_category.id
      end

      it "syncs context_id and context_type when changed" do
        new_course = course_factory(active_all: true)
        new_course.enable_feature!(:peer_review_allocation_and_grading)
        @parent_assignment.update!(context: new_course)
        @peer_review_sub.reload
        expect(@peer_review_sub.context_id).to eq new_course.id
        expect(@peer_review_sub.context_type).to eq "Course"
      end

      it "syncs intra_group_peer_reviews when changed" do
        @parent_assignment.update!(intra_group_peer_reviews: true)
        expect(@peer_review_sub.reload.intra_group_peer_reviews).to be true
      end

      it "syncs peer_review_count when changed" do
        @parent_assignment.update!(peer_review_count: 5)
        expect(@peer_review_sub.reload.peer_review_count).to eq 5
      end

      it "syncs peer_reviews when changed" do
        @parent_assignment.update!(peer_reviews: false)
        expect(@peer_review_sub.reload.peer_reviews).to be false
      end

      it "syncs peer_reviews_assigned when changed" do
        @parent_assignment.update!(peer_reviews_assigned: true)
        expect(@peer_review_sub.reload.peer_reviews_assigned).to be true
      end

      it "syncs title when parent title changes" do
        @parent_assignment.update!(title: "Updated Assignment")
        @peer_review_sub.reload
        expect(@peer_review_sub.title).to eq "Updated Assignment Peer Review"
      end

      it "syncs multiple attributes at once" do
        @parent_assignment.update!(
          description: "New description",
          anonymous_peer_reviews: true,
          peer_review_count: 3
        )
        @peer_review_sub.reload
        expect(@peer_review_sub.description).to eq "New description"
        expect(@peer_review_sub.anonymous_peer_reviews).to be true
        expect(@peer_review_sub.peer_review_count).to eq 3
      end

      it "does not sync points_possible" do
        @peer_review_sub.update!(points_possible: 10)
        @parent_assignment.update!(points_possible: 100)
        expect(@peer_review_sub.reload.points_possible).to eq 10
      end

      it "does not sync grading_type" do
        @peer_review_sub.update!(grading_type: "not_graded")
        @parent_assignment.update!(grading_type: "letter_grade")
        expect(@peer_review_sub.reload.grading_type).to eq "not_graded"
      end

      it "does not sync due_at" do
        new_due = 5.days.from_now
        @parent_assignment.update!(due_at: new_due)
        expect(@peer_review_sub.reload.due_at).to be_nil
      end

      it "does not sync unlock_at" do
        new_unlock = 1.day.from_now
        @parent_assignment.update!(unlock_at: new_unlock)
        expect(@peer_review_sub.reload.unlock_at).to be_nil
      end

      it "does not sync lock_at" do
        new_lock = 10.days.from_now
        @parent_assignment.update!(lock_at: new_lock)
        expect(@peer_review_sub.reload.lock_at).to be_nil
      end

      it "does not sync when attributes have not actually changed" do
        expect(@peer_review_sub).not_to receive(:update_columns)
        @parent_assignment.update!(points_possible: 50)
      end

      it "handles multiple rapid updates correctly" do
        @parent_assignment.update!(description: "First update")
        @parent_assignment.update!(description: "Second update")
        @parent_assignment.update!(description: "Third update")
        expect(@peer_review_sub.reload.description).to eq "Third update"
      end

      it "works through any interface" do
        @parent_assignment.description = "Updated via attribute"
        @parent_assignment.save!
        expect(@peer_review_sub.reload.description).to eq "Updated via attribute"

        @parent_assignment.update_attribute(:anonymous_peer_reviews, true)
        expect(@peer_review_sub.reload.anonymous_peer_reviews).to be true
      end

      it "rolls back parent changes when peer review sync fails" do
        original_description = @parent_assignment.description
        allow(PeerReview::PeerReviewUpdaterService).to receive(:call).and_raise(StandardError.new("Sync failed"))

        expect do
          @parent_assignment.update!(description: "New description")
        end.to raise_error(StandardError, "Sync failed")

        expect(@parent_assignment.reload.description).to eq original_description
      end
    end
  end
end
