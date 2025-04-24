# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Checkpoints::DiscussionCheckpointCreatorService do
  describe ".call" do
    before(:once) do
      course = course_model
      course.account.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
    end

    let(:service) { Checkpoints::DiscussionCheckpointCreatorService }

    it "raises a FlagDisabledError when the checkpoints feature flag is disabled" do
      @topic.context.account.disable_feature!(:discussion_checkpoints)

      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to raise_error(Checkpoints::FlagDisabledError)
    end

    it "raises an error when points_possible is not provided" do
      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }]
        )
      end.to raise_error(ArgumentError, /missing keyword: :points_possible/)
    end

    it "raises a DateTypeRequiredError when a type is not specified on a date" do
      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to raise_error(Checkpoints::DateTypeRequiredError)
    end

    it "updates the reply_to_entry_required_count on the topic when creating a reply to entry checkpoint" do
      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6,
          replies_required: 3
        )
      end.to change { @topic.reload.reply_to_entry_required_count }.from(0).to(3)
    end

    it "creates a checkpoint with the specified label, points_possible, and dates" do
      due_at = 2.days.from_now
      checkpoint = service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: }],
        points_possible: 6
      )

      aggregate_failures do
        expect(checkpoint.sub_assignment_tag).to eq CheckpointLabels::REPLY_TO_TOPIC
        expect(checkpoint.points_possible).to eq 6
        expect(checkpoint.due_at).to eq due_at
      end
    end

    it "suspends calls to the SubmissionLifecycleManger while creating checkpoints and associated overrides, calling once at the end" do
      expect_any_instance_of(SubmissionLifecycleManager).to receive(:recompute).once
      service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [
          { type: "everyone", due_at: 2.days.from_now },
          { type: "override", set_type: "CourseSection", set_id: @topic.course.default_section.id, due_at: 3.days.from_now }
        ],
        points_possible: 6
      )
    end

    it "updates the parent assignment with has_sub_assignments: true" do
      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to change { @topic.assignment.reload.has_sub_assignments }.from(false).to(true)
    end

    it "sets only_visible_to_overrides to false on the parent assignment when an 'everyone' date exists" do
      checkpoint = service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 6
      )
      expect(checkpoint.parent_assignment.only_visible_to_overrides).to be false
    end

    it "syncs unlock_at and lock_at fields to the latest created checkpoint" do
      now = Time.zone.now.change(usec: 0)
      first_unlock_at = 1.day.from_now(now)
      first_lock_at = 3.days.from_now(now)
      second_unlock_at = 2.days.from_now(now)
      second_lock_at = 4.days.from_now(now)

      # Create the first checkpoint
      first_checkpoint = service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now(now), unlock_at: first_unlock_at, lock_at: first_lock_at }],
        points_possible: 5
      )

      # Create the second checkpoint
      second_checkpoint = service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 3.days.from_now(now), unlock_at: second_unlock_at, lock_at: second_lock_at }],
        points_possible: 5
      )

      # Reload the parent assignment and checkpoints
      parent_assignment = first_checkpoint.parent_assignment.reload
      first_checkpoint.reload
      second_checkpoint.reload

      aggregate_failures do
        # Check that the parent assignment's unlock_at and lock_at are synced to the latest checkpoint
        expect(parent_assignment.unlock_at).to eq second_unlock_at
        expect(parent_assignment.lock_at).to eq second_lock_at

        # Check that both checkpoints have the same unlock_at and lock_at as the parent
        expect(first_checkpoint.unlock_at).to eq second_unlock_at
        expect(first_checkpoint.lock_at).to eq second_lock_at
        expect(second_checkpoint.unlock_at).to eq second_unlock_at
        expect(second_checkpoint.lock_at).to eq second_lock_at

        # Ensure that the due_at dates remain different
        expect(first_checkpoint.due_at).to be < second_checkpoint.due_at
      end
    end

    it "creates submission objects for the parent assignment and for the checkpoints" do
      student = student_in_course(course: @topic.course, active_all: true).user
      checkpoint = service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 6
      )

      aggregate_failures do
        expect(checkpoint.submissions.find_by(user: student)).to be_present
        expect(checkpoint.parent_assignment.submissions.find_by(user: student)).to be_present
      end
    end

    describe "assignment overrides" do
      it "can create section overrides" do
        new_section = @topic.course.course_sections.create!
        old_section_student = student_in_course(course: @topic.course, active_all: true, section: @topic.course.default_section).user
        new_section_student = student_in_course(course: @topic.course, active_all: true, section: new_section).user
        checkpoint = service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "CourseSection", set_id: new_section.id, due_at: 2.days.from_now }],
          points_possible: 6
        )

        aggregate_failures do
          expect(checkpoint.submissions.find_by(user: old_section_student)).not_to be_present
          expect(checkpoint.submissions.find_by(user: new_section_student)).to be_present

          expect(checkpoint.parent_assignment.only_visible_to_overrides).to be true
          expect(checkpoint.parent_assignment.submissions.find_by(user: old_section_student)).not_to be_present
          expect(checkpoint.parent_assignment.submissions.find_by(user: new_section_student)).to be_present
        end
      end

      it "can create group overrides" do
        group = @topic.course.groups.create!
        @topic.update!(group_category: group.group_category)
        student_in_group = student_in_course(course: @topic.course, active_all: true).user
        group.group_memberships.create!(user: student_in_group)
        student_not_in_group = student_in_course(course: @topic.course, active_all: true).user
        checkpoint = service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "Group", set_id: group.id, due_at: 2.days.from_now }],
          points_possible: 6
        )

        aggregate_failures do
          expect(checkpoint.submissions.find_by(user: student_not_in_group)).not_to be_present
          expect(checkpoint.submissions.find_by(user: student_in_group)).to be_present

          expect(checkpoint.parent_assignment.only_visible_to_overrides).to be true
          expect(checkpoint.parent_assignment.submissions.find_by(user: student_not_in_group)).not_to be_present
          expect(checkpoint.parent_assignment.submissions.find_by(user: student_in_group)).to be_present
        end
      end

      it "can create adhoc overrides" do
        student1 = student_in_course(course: @topic.course, active_all: true).user
        student2 = student_in_course(course: @topic.course, active_all: true).user
        checkpoint = service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "override", set_type: "ADHOC", student_ids: [student1.id], due_at: 2.days.from_now }],
          points_possible: 6
        )

        aggregate_failures do
          expect(checkpoint.submissions.find_by(user: student2)).not_to be_present
          expect(checkpoint.submissions.find_by(user: student1)).to be_present

          expect(checkpoint.parent_assignment.only_visible_to_overrides).to be true
          expect(checkpoint.parent_assignment.submissions.find_by(user: student2)).not_to be_present
          expect(checkpoint.parent_assignment.submissions.find_by(user: student1)).to be_present
        end
      end

      it "can create a combination of overrides and 'everyone' dates" do
        now = Time.zone.now.change(usec: 0)
        new_section = @topic.course.course_sections.create!
        student1 = student_in_course(course: @topic.course, active_all: true).user
        student2 = student_in_course(course: @topic.course, active_all: true, section: new_section).user
        checkpoint = service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [
            { type: "everyone", due_at: 1.day.from_now(now) },
            { type: "override", set_type: "CourseSection", set_id: new_section.id, due_at: 2.days.from_now(now) }
          ],
          points_possible: 6
        )

        aggregate_failures do
          expect(checkpoint.submissions.find_by(user: student1).cached_due_date).to eq 1.day.from_now(now)
          expect(checkpoint.submissions.find_by(user: student2).cached_due_date).to eq 2.days.from_now(now)

          expect(checkpoint.parent_assignment.only_visible_to_overrides).to be false
          # submissions for parent assignments do not store the student's actual due dates. the actual due dates
          # are stored on the checkpoint submissions.
          expect(checkpoint.parent_assignment.submissions.find_by(user: student1).cached_due_date).to be_nil
          expect(checkpoint.parent_assignment.submissions.find_by(user: student2).cached_due_date).to be_nil
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

        it "can create differentiation tag overrides" do
          checkpoint = service.call(
            discussion_topic: @topic,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [{ type: "override", set_type: "Group", set_id: @diff_tag1.id, due_at: 2.days.from_now }],
            points_possible: 6
          )

          aggregate_failures do
            expect(checkpoint.assignment_overrides.count).to eq 1
            expect(checkpoint.assignment_overrides.first[:set_type]).to eq "Group"
            expect(checkpoint.assignment_overrides.first[:set_id]).to eq @diff_tag1.id
            expect(checkpoint.parent_assignment.only_visible_to_overrides).to be true
          end
        end

        it "cannot create differentiation tag overrides when the account setting is disabled" do
          account = @topic.course.account
          account.update!(settings: { allow_assign_to_differentiation_tags: false })

          expect do
            service.call(
              discussion_topic: @topic,
              checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
              dates: [{ type: "override", set_type: "Group", set_id: @diff_tag1.id, due_at: 2.days.from_now }],
              points_possible: 6
            )
          end.to raise_error(Checkpoints::GroupAssignmentRequiredError)
        end
      end

      context "multiple checkpoints creates multiple parent assignment_overrides" do
        let(:unlock_at_time_1) { 2.days.ago }
        let(:lock_at_time_1) { 4.days.from_now }
        let(:unlock_at_time_2) { 3.days.ago }
        let(:lock_at_time_2) { 5.days.from_now }

        def create_checkpoint(label, overrides)
          options = {
            discussion_topic: @topic,
            checkpoint_label: label,
            dates: overrides,
            points_possible: 6
          }
          options[:replies_required] = 3 if label == CheckpointLabels::REPLY_TO_ENTRY
          service.call(**options)
        end

        def create_overrides(set_type, set_ids)
          [
            { type: "override", set_type:, set_id: set_ids[0], due_at: 2.days.from_now, unlock_at: unlock_at_time_1, lock_at: lock_at_time_1 },
            { type: "override", set_type:, set_id: set_ids[1], due_at: 2.days.from_now, unlock_at: unlock_at_time_2, lock_at: lock_at_time_2 }
          ]
        end

        it "creates correct overrides when given separate section overrides" do
          new_section = @topic.course.course_sections.create!
          student_in_course(course: @topic.course, active_all: true, section: @topic.course.default_section).user
          student_in_course(course: @topic.course, active_all: true, section: new_section).user

          set_ids = [@topic.course.default_section.id, new_section.id]
          sets = [@topic.course.default_section, new_section]
          overrides = create_overrides("CourseSection", set_ids)

          checkpoint_1 = create_checkpoint(CheckpointLabels::REPLY_TO_TOPIC, overrides)
          checkpoint_2 = create_checkpoint(CheckpointLabels::REPLY_TO_ENTRY, overrides)
          checkpoint_parent = checkpoint_1.parent_assignment

          aggregate_failures do
            expect(checkpoint_parent.only_visible_to_overrides).to be true
            expect(checkpoint_parent.assignment_overrides.count).to be 2

            checkpoint_parent.assignment_overrides.each do |override|
              expect(override.due_at).to be_nil
            end

            parent_override_1, parent_override_2 = checkpoint_parent.assignment_overrides.order(:id)

            expect(parent_override_1.unlock_at.to_i).to be unlock_at_time_1.to_i
            expect(parent_override_2.unlock_at.to_i).to be unlock_at_time_2.to_i
            expect(parent_override_1.lock_at.to_i).to be lock_at_time_1.to_i
            expect(parent_override_2.lock_at.to_i).to be lock_at_time_2.to_i

            sets.each do |set|
              parent_override = checkpoint_parent.assignment_overrides.find_by(set:)
              checkpoint_1_override = checkpoint_1.assignment_overrides.find_by(set:)
              checkpoint_2_override = checkpoint_2.assignment_overrides.find_by(set:)

              expect(parent_override.set).to eq checkpoint_1_override.set
              expect(parent_override.set).to eq checkpoint_2_override.set
            end
          end
        end

        it "creates correct overrides when given separate group overrides" do
          group_category = @topic.course.group_categories.create!(name: "Test Group Set")
          @topic.update!(group_category:)

          group1 = @topic.course.groups.create!(group_category:)
          group2 = @topic.course.groups.create!(group_category:)

          student_1 = student_in_course(course: @topic.course, active_all: true).user
          group1.group_memberships.create!(user: student_1)
          student_2 = student_in_course(course: @topic.course, active_all: true).user
          group2.group_memberships.create!(user: student_2)

          set_ids = [group1.id, group2.id]
          sets = [group1, group2]
          overrides = create_overrides("Group", set_ids)

          checkpoint_1 = create_checkpoint(CheckpointLabels::REPLY_TO_TOPIC, overrides)
          checkpoint_2 = create_checkpoint(CheckpointLabels::REPLY_TO_ENTRY, overrides)
          checkpoint_parent = checkpoint_1.parent_assignment

          aggregate_failures do
            expect(checkpoint_parent.only_visible_to_overrides).to be true
            expect(checkpoint_parent.assignment_overrides.count).to be 2

            checkpoint_parent.assignment_overrides.each do |override|
              expect(override.due_at).to be_nil
            end

            parent_override_1, parent_override_2 = checkpoint_parent.assignment_overrides.order(:id)

            expect(parent_override_1.unlock_at.to_i).to be unlock_at_time_1.to_i
            expect(parent_override_2.unlock_at.to_i).to be unlock_at_time_2.to_i
            expect(parent_override_1.lock_at.to_i).to be lock_at_time_1.to_i
            expect(parent_override_2.lock_at.to_i).to be lock_at_time_2.to_i

            sets.each do |set|
              parent_override = checkpoint_parent.assignment_overrides.find_by(set:)
              checkpoint_1_override = checkpoint_1.assignment_overrides.find_by(set:)
              checkpoint_2_override = checkpoint_2.assignment_overrides.find_by(set:)

              expect(parent_override.set).to eq checkpoint_1_override.set
              expect(parent_override.set).to eq checkpoint_2_override.set
            end
          end
        end

        it "creates correct overrides when given separate adhoc overrides" do
          student1 = student_in_course(course: @topic.course, active_all: true).user
          student2 = student_in_course(course: @topic.course, active_all: true).user

          student_ids = [student1.id, student2.id]
          overrides = [
            { type: "override", set_type: "ADHOC", student_ids: [student_ids[0]], due_at: 2.days.from_now, unlock_at: unlock_at_time_1, lock_at: lock_at_time_1 },
            { type: "override", set_type: "ADHOC", student_ids: [student_ids[1]], due_at: 2.days.from_now, unlock_at: unlock_at_time_2, lock_at: lock_at_time_2 }
          ]

          checkpoint_1 = create_checkpoint(CheckpointLabels::REPLY_TO_TOPIC, overrides)
          checkpoint_2 = create_checkpoint(CheckpointLabels::REPLY_TO_ENTRY, overrides)

          checkpoint_parent = checkpoint_1.parent_assignment

          checkpoint_parent_override_1 = checkpoint_parent.assignment_overrides.first
          checkpoint_1_override_1 = checkpoint_1.assignment_overrides.first
          checkpoint_2_override_1 = checkpoint_2.assignment_overrides.first

          checkpoint_parent_override_2 = checkpoint_parent.assignment_overrides.second
          checkpoint_1_override_2 = checkpoint_1.assignment_overrides.second
          checkpoint_2_override_2 = checkpoint_2.assignment_overrides.second

          aggregate_failures do
            expect(checkpoint_parent.only_visible_to_overrides).to be true
            expect(checkpoint_parent.assignment_overrides.count).to be 2

            # due_at information should not be stored on parent override
            expect(checkpoint_parent_override_1.due_at).to be_nil
            expect(checkpoint_parent_override_2.due_at).to be_nil

            # Lock_at and unlock_at should be the same
            expect(checkpoint_parent_override_1.unlock_at.to_i).to be unlock_at_time_1.to_i
            expect(checkpoint_parent_override_2.unlock_at.to_i).to be unlock_at_time_2.to_i
            expect(checkpoint_parent_override_1.lock_at.to_i).to be lock_at_time_1.to_i
            expect(checkpoint_parent_override_2.lock_at.to_i).to be lock_at_time_2.to_i

            # Verify set
            expect(checkpoint_parent_override_1.set).to eq checkpoint_1_override_1.set
            expect(checkpoint_parent_override_1.set).to eq checkpoint_2_override_1.set

            expect(checkpoint_parent_override_2.set).to eq checkpoint_1_override_2.set
            expect(checkpoint_parent_override_2.set).to eq checkpoint_2_override_2.set
          end
        end
      end
    end
  end
end
