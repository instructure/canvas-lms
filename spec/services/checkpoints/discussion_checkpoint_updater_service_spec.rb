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
      course.account.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
    end

    let(:creator_service) { Checkpoints::DiscussionCheckpointCreatorService }

    let(:updater_service) { Checkpoints::DiscussionCheckpointUpdaterService }

    it "raises a FlagDisabledError when the checkpoints feature flag is disabled" do
      @topic.context.account.disable_feature!(:discussion_checkpoints)

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

    it "does not raise an error when points_possible is not provided for the updater service" do
      creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 6,
        replies_required: 3
      )

      expect do
        updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          replies_required: 6
        )
      end.not_to raise_error
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

    it "propagates unlock_at and lock_at changes to all checkpoints and the parent assignment" do
      now = Time.zone.now.change(usec: 0)
      initial_unlock_at = 1.day.from_now(now)
      initial_lock_at = 5.days.from_now(now)

      # Create the first checkpoint
      first_checkpoint = creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now(now), unlock_at: initial_unlock_at, lock_at: initial_lock_at }],
        points_possible: 5
      )

      # Create the second checkpoint
      second_checkpoint = creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 3.days.from_now(now), unlock_at: initial_unlock_at, lock_at: initial_lock_at }],
        points_possible: 5
      )

      # Update the first checkpoint with new unlock_at and lock_at times
      new_unlock_at = 2.days.from_now(now)
      new_lock_at = 6.days.from_now(now)
      updater_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now(now), unlock_at: new_unlock_at, lock_at: new_lock_at }],
        points_possible: 5
      )

      # Reload all assignments
      parent_assignment = first_checkpoint.parent_assignment.reload
      first_checkpoint.reload
      second_checkpoint.reload

      aggregate_failures do
        # Check that the parent assignment's unlock_at and lock_at are updated
        expect(parent_assignment.unlock_at).to eq new_unlock_at
        expect(parent_assignment.lock_at).to eq new_lock_at

        # Check that both checkpoints have the updated unlock_at and lock_at
        expect(first_checkpoint.unlock_at).to eq new_unlock_at
        expect(first_checkpoint.lock_at).to eq new_lock_at
        expect(second_checkpoint.unlock_at).to eq new_unlock_at
        expect(second_checkpoint.lock_at).to eq new_lock_at

        # Ensure that the due_at dates remain different
        expect(first_checkpoint.due_at).to be < second_checkpoint.due_at
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
        original_unlock_at = 0.days.from_now
        original_lock_at = 2.days.from_now

        original_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "ADHOC", student_ids: [students[0].id, students[1].id], due_at: original_due_at, unlock_at: original_unlock_at, lock_at: original_lock_at }],
          points_possible: 6
        )

        original_assignment_override = original_checkpoint.assignment_overrides.first
        original_student_ids = original_assignment_override.assignment_override_students.pluck(:user_id)

        expect(original_assignment_override.set_type).to eq "ADHOC"
        expect(original_assignment_override.due_at).to be_within(1.second).of(original_due_at)
        expect(original_assignment_override.unlock_at).to be_within(1.second).of(original_unlock_at)
        expect(original_assignment_override.lock_at).to be_within(1.second).of(original_lock_at)
        expect(original_student_ids).to match_array([students[0].id, students[1].id])
        expect(original_assignment_override.title).to eq "2 students"

        original_parent_override = original_assignment_override.parent_override

        # Make sure unlock_at and lock_at are aggregated into the parent override
        expect(original_parent_override.unlock_at).to be_within(1.second).of(original_unlock_at)
        expect(original_parent_override.lock_at).to be_within(1.second).of(original_lock_at)

        # Updates the ADHOC override removing student 0, adding 2-4, and updating the due_at

        updated_due_at = 3.days.from_now
        updated_unlock_at = 1.day.from_now
        updated_lock_at = 3.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[1].id, students[2].id, students[3].id, students[4].id], due_at: updated_due_at, unlock_at: updated_unlock_at, lock_at: updated_lock_at }],
          points_possible: 6
        )

        updated_assignment_override = updated_checkpoint.assignment_overrides.first
        updated_student_ids = updated_assignment_override.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override.set_type).to eq "ADHOC"
        expect(updated_assignment_override.due_at).to be_within(1.second).of(updated_due_at)
        expect(updated_assignment_override.unlock_at).to be_within(1.second).of(updated_unlock_at)
        expect(updated_assignment_override.lock_at).to be_within(1.second).of(updated_lock_at)
        expect(updated_student_ids).to match_array([students[1].id, students[2].id, students[3].id, students[4].id])

        updated_parent_override = updated_assignment_override.parent_override

        # Make sure unlock_at and lock_at are aggregated into the parent override
        expect(updated_parent_override.unlock_at).to be_within(1.second).of(updated_unlock_at)
        expect(updated_parent_override.lock_at).to be_within(1.second).of(updated_lock_at)

        # Calls the updater again, adding a new ADHOC override for student 5 and moving student 1 to it

        student_5_due_at = 4.days.from_now

        updated_checkpoint2 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[2].id, students[3].id, students[4].id], due_at: updated_due_at },
                  { type: "override", set_type: "ADHOC", student_ids: [students[1].id, students[5].id], due_at: student_5_due_at }],
          points_possible: 6
        )

        expect(updated_checkpoint2.assignment_overrides.count).to eq 2

        updated_assignment_override1 = updated_checkpoint2.assignment_overrides.first
        updated_student_ids1 = updated_assignment_override1.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override1.set_type).to eq "ADHOC"
        expect(updated_assignment_override1.due_at).to be_within(1.second).of(updated_due_at)
        expect(updated_student_ids1).to match_array([students[2].id, students[3].id, students[4].id])

        updated_assignment_override2 = updated_checkpoint2.assignment_overrides.last
        updated_student_ids2 = updated_assignment_override2.assignment_override_students.pluck(:user_id)

        expect(updated_assignment_override2.set_type).to eq "ADHOC"
        expect(updated_assignment_override2.due_at).to be_within(1.second).of(student_5_due_at)
        expect(updated_student_ids2).to match_array([students[1].id, students[5].id])

        updated_parent_override1 = updated_assignment_override1.parent_override
        updated_parent_student_ids1 = updated_parent_override1.assignment_override_students.pluck(:user_id)
        updated_parent_override2 = updated_assignment_override2.parent_override
        updated_parent_student_ids2 = updated_parent_override2.assignment_override_students.pluck(:user_id)

        expect(updated_parent_student_ids1).to match_array([students[2].id, students[3].id, students[4].id])
        expect(updated_parent_student_ids2).to match_array([students[1].id, students[5].id])

        # Calls the updater again, removing the ADHOC override for student 5
        updated_checkpoint3 = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: original_assignment_override.id, set_type: "ADHOC", student_ids: [students[1].id, students[2].id, students[3].id, students[4].id], due_at: updated_due_at }],
          points_possible: 6
        )

        assignment_overrides = updated_checkpoint3.assignment_overrides.active

        expect(assignment_overrides.count).to eq 1
        expect(assignment_overrides.first.title).to eq "4 students"
      end

      it "can create section overrides and update them" do
        section1 = @topic.course.course_sections.create!
        section2 = @topic.course.course_sections.create!

        due_at = 2.days.from_now
        unlock_at = 0.days.from_now
        lock_at = 2.days.from_now

        # Create checkpoint with section override for section 1

        checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "CourseSection", set_id: section1.id, due_at:, unlock_at:, lock_at: }],
          points_possible: 6
        )

        expect(checkpoint.assignment_overrides.count).to eq 1

        assignment_override = checkpoint.assignment_overrides.first
        expect(assignment_override.set_type).to eq "CourseSection"
        expect(assignment_override.set_id).to eq section1.id
        expect(assignment_override.due_at).to be_within(1.second).of(due_at)
        expect(assignment_override.unlock_at).to be_within(1.second).of(unlock_at)
        expect(assignment_override.lock_at).to be_within(1.second).of(lock_at)

        parent_override = assignment_override.parent_override
        expect(parent_override.unlock_at).to be_within(1.second).of(unlock_at)
        expect(parent_override.lock_at).to be_within(1.second).of(lock_at)

        # Updates checkpoint with section override to set a new due date for section 1.

        new_due_at = 5.days.from_now
        new_unlock_at = 3.days.from_now
        new_lock_at = 5.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "CourseSection", set_id: section1.id, due_at: new_due_at, unlock_at: new_unlock_at, lock_at: new_lock_at }],
          points_possible: 6
        )

        expect(updated_checkpoint.assignment_overrides.count).to eq 1

        updated_assignment_override = updated_checkpoint.assignment_overrides.first
        expect(updated_assignment_override.set_type).to eq "CourseSection"
        expect(updated_assignment_override.set_id).to eq section1.id
        expect(updated_assignment_override.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override.unlock_at).to be_within(1.second).of(new_unlock_at)
        expect(updated_assignment_override.lock_at).to be_within(1.second).of(new_lock_at)
        expect(updated_assignment_override.id).to eq assignment_override.id

        updated_parent_override = updated_assignment_override.parent_override

        # Make sure unlock_at and lock_at are aggregated into the parent override
        expect(updated_parent_override.unlock_at).to be_within(1.second).of(new_unlock_at)
        expect(updated_parent_override.lock_at).to be_within(1.second).of(new_lock_at)

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
        unlock_at = 0.days.from_now
        lock_at = 2.days.from_now

        @topic.update!(group_category: group1.group_category)

        # Create checkpoint with group override for group 1

        checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "Group", set_id: group1.id, due_at:, unlock_at:, lock_at: }],
          points_possible: 6
        )

        expect(checkpoint.assignment_overrides.count).to eq 1

        assignment_override = checkpoint.assignment_overrides.first

        expect(assignment_override.set_type).to eq "Group"
        expect(assignment_override.set_id).to eq group1.id
        expect(assignment_override.due_at).to be_within(1.second).of(due_at)
        expect(assignment_override.unlock_at).to be_within(1.second).of(unlock_at)
        expect(assignment_override.lock_at).to be_within(1.second).of(lock_at)

        parent_override = assignment_override.parent_override
        expect(parent_override.unlock_at).to be_within(1.second).of(unlock_at)
        expect(parent_override.lock_at).to be_within(1.second).of(lock_at)

        # Updates checkpoint with group override to set a new due date for group 1.

        new_due_at = 5.days.from_now
        new_unlock_at = 3.days.from_now
        new_lock_at = 5.days.from_now

        updated_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", id: assignment_override.id, set_type: "Group", set_id: group1.id, due_at: new_due_at, unlock_at: new_unlock_at, lock_at: new_lock_at }],
          points_possible: 6
        )

        expect(updated_checkpoint.assignment_overrides.count).to eq 1

        updated_assignment_override = updated_checkpoint.assignment_overrides.first

        expect(updated_assignment_override.set_type).to eq "Group"
        expect(updated_assignment_override.set_id).to eq group1.id
        expect(updated_assignment_override.due_at).to be_within(1.second).of(new_due_at)
        expect(updated_assignment_override.id).to eq assignment_override.id

        updated_parent_override = updated_assignment_override.parent_override

        # Make sure unlock_at and lock_at are aggregated into the parent override
        expect(updated_parent_override.unlock_at).to be_within(1.second).of(new_unlock_at)
        expect(updated_parent_override.lock_at).to be_within(1.second).of(new_lock_at)

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

      it "creates 2 checkpoints with 2 adhoc overrides each, and can update the correct sub_assignment assignment_overrides" do
        @students = create_users(2, return_type: :record)
        @students.each { |student| student_in_course(course: @topic.course, user: student, active_all: true) }
        now = Time.zone.now.change(usec: 0)
        original_due_at_1 = 3.days.from_now(now)
        original_due_at_2 = 4.days.from_now(now)
        original_unlock_at_1 = 1.day.from_now(now)
        original_unlock_at_2 = 2.days.from_now(now)
        original_lock_at_1 = 10.days.from_now(now)
        original_lock_at_2 = 10.days.from_now(now)

        # Create first checkpoint with two adhoc overrides
        first_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            { type: "override", set_type: "ADHOC", student_ids: [@students[0].id], due_at: original_due_at_1, unlock_at: original_unlock_at_1, lock_at: original_lock_at_1 },
            { type: "override", set_type: "ADHOC", student_ids: [@students[1].id], due_at: original_due_at_2, unlock_at: original_unlock_at_2, lock_at: original_lock_at_2 }
          ],
          points_possible: 4
        )

        # Create second checkpoint with two adhoc overrides
        second_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            { type: "override", set_type: "ADHOC", student_ids: [@students[0].id], due_at: original_due_at_1, unlock_at: original_unlock_at_1, lock_at: original_lock_at_1 },
            { type: "override", set_type: "ADHOC", student_ids: [@students[1].id], due_at: original_due_at_2, unlock_at: original_unlock_at_2, lock_at: original_lock_at_2 }
          ],
          points_possible: 5
        )

        # Update due_at and unlock_at for first checkpoint's adhoc overrides
        new_due_at_1 = 5.days.from_now(now)
        new_due_at_2 = 6.days.from_now(now)
        updated_first_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            { type: "override", id: first_checkpoint.assignment_overrides.first.id, due_at: new_due_at_1 },
            { type: "override", id: first_checkpoint.assignment_overrides.second.id, due_at: new_due_at_2 }
          ]
        )

        # Update due_at and unlock_at for second checkpoint's adhoc overrides
        updated_second_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [
            { type: "override", id: second_checkpoint.assignment_overrides.first.id, due_at: new_due_at_1 },
            { type: "override", id: second_checkpoint.assignment_overrides.second.id, due_at: new_due_at_2 }
          ]
        )

        # Verify updates for first checkpoint
        first_override_1 = updated_first_checkpoint.assignment_overrides.first
        first_override_2 = updated_first_checkpoint.assignment_overrides.second
        expect(updated_first_checkpoint.points_possible).to eq 4
        expect(first_override_1.set_type).to eq "ADHOC"
        expect(first_override_1.due_at).to be_within(1.second).of(new_due_at_1)
        expect(first_override_1.unlock_at).to be_within(1.second).of(original_unlock_at_1)
        expect(first_override_1.lock_at).to be_within(1.second).of(original_lock_at_1)
        expect(first_override_1.assignment_override_students.pluck(:user_id)).to match_array([@students[0].id])

        expect(first_override_2.set_type).to eq "ADHOC"
        expect(first_override_2.due_at).to be_within(1.second).of(new_due_at_2)
        expect(first_override_2.unlock_at).to be_within(1.second).of(original_unlock_at_2)
        expect(first_override_2.lock_at).to be_within(1.second).of(original_lock_at_2)
        expect(first_override_2.assignment_override_students.pluck(:user_id)).to match_array([@students[1].id])

        # Verify updates for second checkpoint
        second_override_1 = updated_second_checkpoint.assignment_overrides.first
        second_override_2 = updated_second_checkpoint.assignment_overrides.second
        expect(updated_second_checkpoint.points_possible).to eq 5
        expect(second_override_1.set_type).to eq "ADHOC"
        expect(second_override_1.due_at).to be_within(1.second).of(new_due_at_1)
        expect(second_override_1.unlock_at).to be_within(1.second).of(original_unlock_at_1)
        expect(second_override_1.lock_at).to be_within(1.second).of(original_lock_at_1)
        expect(second_override_1.assignment_override_students.pluck(:user_id)).to match_array([@students[0].id])

        expect(second_override_2.set_type).to eq "ADHOC"
        expect(second_override_2.due_at).to be_within(1.second).of(new_due_at_2)
        expect(second_override_2.unlock_at).to be_within(1.second).of(original_unlock_at_2)
        expect(second_override_2.lock_at).to be_within(1.second).of(original_lock_at_2)
        expect(second_override_2.assignment_override_students.pluck(:user_id)).to match_array([@students[1].id])
      end

      it "can create discussion with checkpoints with Everyone and then update them with student overrides and remove Everyone" do
        reply_to_topic_due_at = 7.days.from_now
        reply_to_entry_due_at = 14.days.from_now

        # Create checkpoints with Everyone due dates
        reply_to_topic_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: reply_to_topic_due_at }],
          points_possible: 5
        )

        reply_to_entry_checkpoint = creator_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: reply_to_entry_due_at }],
          points_possible: 15
        )

        expect(reply_to_topic_checkpoint.due_at).to be_within(1.second).of(reply_to_topic_due_at)
        expect(reply_to_entry_checkpoint.due_at).to be_within(1.second).of(reply_to_entry_due_at)
        expect(reply_to_topic_checkpoint.only_visible_to_overrides).to be_falsey
        expect(reply_to_entry_checkpoint.only_visible_to_overrides).to be_falsey

        # Update checkpoints with student overrides and not define Everyone dates
        students = create_users(2, return_type: :record)
        students.each { |student| student_in_course(course: @topic.course, user: student, active_all: true) }
        student_ids = students.map(&:id)

        reply_to_topic_due_at_2 = 14.days.from_now
        reply_to_entry_due_at_2 = 21.days.from_now

        updated_reply_to_topic_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "ADHOC", student_ids:, due_at: reply_to_topic_due_at_2 }],
          points_possible: 5
        )

        updated_reply_to_entry_checkpoint = updater_service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "override", set_type: "ADHOC", student_ids:, due_at: reply_to_entry_due_at_2 }],
          points_possible: 15
        )

        expect(updated_reply_to_topic_checkpoint.due_at).to be_nil
        expect(updated_reply_to_entry_checkpoint.due_at).to be_nil

        expect(updated_reply_to_topic_checkpoint.only_visible_to_overrides).to be_truthy
        expect(updated_reply_to_entry_checkpoint.only_visible_to_overrides).to be_truthy

        expect(updated_reply_to_topic_checkpoint.assignment_overrides.count).to eq 1
        expect(updated_reply_to_entry_checkpoint.assignment_overrides.count).to eq 1

        updated_reply_to_topic_checkpoint.assignment_overrides.each do |assignment_override|
          expect(assignment_override.set_type).to eq "ADHOC"
          expect(assignment_override.due_at).to be_within(1.second).of(reply_to_topic_due_at_2)
          expect(assignment_override.assignment_override_students.pluck(:user_id)).to match_array(student_ids)
        end

        updated_reply_to_entry_checkpoint.assignment_overrides.each do |assignment_override|
          expect(assignment_override.set_type).to eq "ADHOC"
          expect(assignment_override.due_at).to be_within(1.second).of(reply_to_entry_due_at_2)
          expect(assignment_override.assignment_override_students.pluck(:user_id)).to match_array(student_ids)
        end
      end

      context "differentiation tags" do
        before do
          account = @topic.course.account
          account.enable_feature!(:assign_to_differentiation_tags)
          account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: true }
            a.save!
          end

          @differentiation_tag_category = @topic.course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
          @diff_tag1 = @topic.course.groups.create!(name: "Diff Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
        end

        it "can create differentiation tag overrides and update them" do
          due_at = 2.days.from_now
          unlock_at = 0.days.from_now
          lock_at = 2.days.from_now

          # Create checkpoint with differentiation tag override for diff tag 1

          checkpoint = creator_service.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [{ type: "override", set_type: "Group", set_id: @diff_tag1.id, due_at:, unlock_at:, lock_at: }],
            points_possible: 6
          )

          expect(checkpoint.assignment_overrides.count).to eq 1

          assignment_override = checkpoint.assignment_overrides.first

          expect(assignment_override.set_type).to eq "Group"
          expect(assignment_override.set_id).to eq @diff_tag1.id
          expect(assignment_override.due_at).to be_within(1.second).of(due_at)
          expect(assignment_override.unlock_at).to be_within(1.second).of(unlock_at)
          expect(assignment_override.lock_at).to be_within(1.second).of(lock_at)

          parent_override = assignment_override.parent_override
          expect(parent_override.unlock_at).to be_within(1.second).of(unlock_at)
          expect(parent_override.lock_at).to be_within(1.second).of(lock_at)

          # Updates checkpoint with differentiation tag override to set a new due date for diff tag 1.

          new_due_at = 5.days.from_now
          new_unlock_at = 3.days.from_now
          new_lock_at = 5.days.from_now

          updated_checkpoint = updater_service.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [{ type: "override", id: assignment_override.id, set_type: "Group", set_id: @diff_tag1.id, due_at: new_due_at, unlock_at: new_unlock_at, lock_at: new_lock_at }],
            points_possible: 6
          )

          expect(updated_checkpoint.assignment_overrides.count).to eq 1

          updated_assignment_override = updated_checkpoint.assignment_overrides.first

          expect(updated_assignment_override.set_type).to eq "Group"
          expect(updated_assignment_override.set_id).to eq @diff_tag1.id
          expect(updated_assignment_override.due_at).to be_within(1.second).of(new_due_at)
          expect(updated_assignment_override.unlock_at).to be_within(1.second).of(new_unlock_at)
          expect(updated_assignment_override.lock_at).to be_within(1.second).of(new_lock_at)
        end
      end
    end
  end
end
