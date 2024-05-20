# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Checkpoints::DiscussionCheckpointUpdaterService do
  describe ".call" do
    before(:once) do
      course = course_model
      course.root_account.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
    end

    let(:creator_service) { Checkpoints::DiscussionCheckpointCreatorService }

    let(:updater_service) { Checkpoints::DiscussionCheckpointUpdaterService }

    it "raises a FlagDisabledError when the checkpoints feature flag is disabled" do
      @topic.context.root_account.disable_feature!(:discussion_checkpoints)

      expect do
        updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to raise_error(Checkpoints::FlagDisabledError)
    end

    it "raises a DateTypeRequiredError when a type is not specified on a date" do
      expect do
        updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to raise_error(Checkpoints::DateTypeRequiredError)
    end

    it "updates the reply_to_entry_required_count on the topic when creating a reply to entry checkpoint and then updates it" do
      expect do
        creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6,
          replies_required: 3
        )
      end.to change { @topic.reload.reply_to_entry_required_count }.from(0).to(3)

      expect do
        updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6,
          replies_required: 6
        )
      end.to change { @topic.reload.reply_to_entry_required_count }.from(3).to(6)
    end

    it "creates a checkpoint with the specified label, points_possible, and dates and then updates it" do
      due_at = 2.days.from_now
      creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: }],
        points_possible: 6
      )

      new_due_at = 3.days.from_now
      updated_checkpoint = updater_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: new_due_at }],
        points_possible: 9
      )

      aggregate_failures do
        expect(updated_checkpoint.sub_assignment_tag).to eq CheckpointLabels::REPLY_TO_TOPIC
        expect(updated_checkpoint.points_possible).to eq 9
        expect(updated_checkpoint.due_at).to eq new_due_at
      end
    end

    describe "assignment overrides" do
      it "can create adhoc overrides and update them" do
        students = []
        6.times do
          students << student_in_course(course: @topic.course, active_all: true).user
        end

        # Create original checkpoint with an ADHOC override for students 0 and 1

        original_due_at = 2.days.from_now

        original_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "ADHOC", student_ids: [students[0].id, students[1].id], due_at: original_due_at }],
          points_possible: 6
        )

        original_assignment_override = original_checkpoint.assignment_overrides.first
        original_student_ids = original_assignment_override.assignment_override_students.pluck(:user_id)

        expect(original_assignment_override.set_type).to eq "ADHOC"
        expect(original_assignment_override.due_at).to be_within(1.second).of(original_due_at)
        expect(original_student_ids).to match_array([students[0].id, students[1].id])

        # Updates the ADHOC override removing student 0, adding 2-4, and updating the due_at

        updated_due_at = 3.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[1].id, students[2].id, students[3].id, students[4].id], due_at: updated_due_at }],
          points_possible: 6
        )

        updated_assignment_override = updated_checkpoint.assignment_overrides.first
        updated_student_ids = updated_assignment_override.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override.set_type).to eq "ADHOC"
        expect(updated_assignment_override.due_at).to be_within(1.second).of(updated_due_at)
        expect(updated_student_ids).to match_array([students[1].id, students[2].id, students[3].id, students[4].id])

        # Calls the updater again, adding a new ADHOC override for student 5

        student_5_due_at = 4.days.from_now

        updated_checkpoint2 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[1].id, students[2].id, students[3].id, students[4].id], due_at: updated_due_at },
                  { type: "override", set_type: "ADHOC", student_ids: [students[5].id], due_at: student_5_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint2.assignment_overrides.count).to eq 2

        updated_assignment_override1 = updated_checkpoint2.assignment_overrides.first
        updated_student_ids1 = updated_assignment_override1.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override1.set_type).to eq "ADHOC"
        expect(updated_assignment_override1.due_at).to be_within(1.second).of(updated_due_at)
        expect(updated_student_ids1).to match_array([students[1].id, students[2].id, students[3].id, students[4].id])

        updated_assignment_override2 = updated_checkpoint2.assignment_overrides.last
        updated_student_ids2 = updated_assignment_override2.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override2.set_type).to eq "ADHOC"
        expect(updated_assignment_override2.due_at).to be_within(1.second).of(student_5_due_at)
        expect(updated_student_ids2).to match_array([students[5].id])

        # Calls the updater again, removing the ADHOC override for student 5
        updated_checkpoint3 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[1].id, students[2].id, students[3].id, students[4].id], due_at: updated_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint3.assignment_overrides.active.count).to eq 1
      end

      it "can create section overrides and update them" do
        section1 = @topic.course.course_sections.create!
        section2 = @topic.course.course_sections.create!

        due_at = 2.days.from_now

        # Create checkpoint with section override for section 1

        checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "CourseSection", set_id: section1.id, due_at: }],
          points_possible: 6
        )

        expect(checkpoint.assignment_overrides.count).to eq 1

        assignment_override = checkpoint.assignment_overrides.first
        expect(assignment_override.set_type).to eq "CourseSection"
        expect(assignment_override.set_id).to eq section1.id
        expect(assignment_override.due_at).to be_within(1.second).of(due_at)

        # Updates checkpoint with section override to set a new due date for section 1.

        new_due_at = 5.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "CourseSection", set_id: section1.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint.assignment_overrides.count).to eq 1

        updated_assignment_override = updated_checkpoint.assignment_overrides.first
        expect(updated_assignment_override.set_type).to eq "CourseSection"
        expect(updated_assignment_override.set_id).to eq section1.id
        expect(updated_assignment_override.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override.id).to eq assignment_override.id

        # Updates checkpoint with section override to add a new section override for section 2.

        updated_checkpoint2 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "CourseSection", set_id: section1.id, due_at: new_due_at },
                  { type: "override", set_type: "CourseSection", set_id: section2.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint2.assignment_overrides.count).to eq 2

        updated_assignment_override1 = updated_checkpoint2.assignment_overrides.first
        expect(updated_assignment_override1.set_type).to eq "CourseSection"
        expect(updated_assignment_override1.set_id).to eq section1.id
        expect(updated_assignment_override1.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override1.id).to eq assignment_override.id

        updated_assignment_override2 = updated_checkpoint2.assignment_overrides.last
        expect(updated_assignment_override2.set_type).to eq "CourseSection"
        expect(updated_assignment_override2.set_id).to eq section2.id
        expect(updated_assignment_override2.due_at).to be_within(1.second).of(new_due_at)

        # Updates checkpoint with section override to remove the section override for section 1 and keep section 2.

        updated_checkpoint3 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: updated_assignment_override2.id, set_type: "CourseSection", set_id: section2.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint3.assignment_overrides.count).to eq 2
        expect(updated_checkpoint3.assignment_overrides.active.count).to eq 1

        updated_assignment_override3 = updated_checkpoint3.assignment_overrides.active.first
        expect(updated_assignment_override3.set_type).to eq "CourseSection"
        expect(updated_assignment_override3.set_id).to eq section2.id
        expect(updated_assignment_override3.due_at).to be_within(1.second).of(new_due_at)
      end

      it "can create group overrides and update them" do
        group1 = @topic.course.groups.create!
        group2 = @topic.course.groups.create!

        due_at = 2.days.from_now

        @topic.update!(group_category: group1.group_category)

        # Create checkpoint with group override for group 1

        checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "Group", set_id: group1.id, due_at: }],
          points_possible: 6
        )

        expect(checkpoint.assignment_overrides.count).to eq 1

        assignment_override = checkpoint.assignment_overrides.first

        expect(assignment_override.set_type).to eq "Group"
        expect(assignment_override.set_id).to eq group1.id
        expect(assignment_override.due_at).to be_within(1.second).of(due_at)

        # Updates checkpoint with group override to set a new due date for group 1.

        new_due_at = 5.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "Group", set_id: group1.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint.assignment_overrides.count).to eq 1

        updated_assignment_override = updated_checkpoint.assignment_overrides.first

        expect(updated_assignment_override.set_type).to eq "Group"
        expect(updated_assignment_override.set_id).to eq group1.id
        expect(updated_assignment_override.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override.id).to eq assignment_override.id

        # Updates checkpoint with group override to add a new group override for group 2.

        updated_checkpoint2 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "Group", set_id: group1.id, due_at: new_due_at },
                  { type: "override", set_type: "Group", set_id: group2.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint2.assignment_overrides.count).to eq 2

        updated_assignment_override1 = updated_checkpoint2.assignment_overrides.first
        expect(updated_assignment_override1.set_type).to eq "Group"
        expect(updated_assignment_override1.set_id).to eq group1.id
        expect(updated_assignment_override1.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override1.id).to eq assignment_override.id

        updated_assignment_override2 = updated_checkpoint2.assignment_overrides.last
        expect(updated_assignment_override2.set_type).to eq "Group"
        expect(updated_assignment_override2.set_id).to eq group2.id
        expect(updated_assignment_override2.due_at).to be_within(1.second).of(new_due_at)

        # Updates checkpoint with group override to remove the group override for group 1 and keep group 2.

        updated_checkpoint3 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: updated_assignment_override2.id, set_type: "Group", set_id: group2.id, due_at: new_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint3.assignment_overrides.count).to eq 2
        expect(updated_checkpoint3.assignment_overrides.active.count).to eq 1

        updated_assignment_override3 = updated_checkpoint3.assignment_overrides.active.first
        expect(updated_assignment_override3.set_type).to eq "Group"
        expect(updated_assignment_override3.set_id).to eq group2.id
        expect(updated_assignment_override3.due_at).to be_within(1.second).of(new_due_at)
      end
    end
  end
end
