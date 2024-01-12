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
      course.root_account.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
    end

    let(:service) { Checkpoints::DiscussionCheckpointCreatorService }

    it "raises a FlagDisabledError when the checkpoints feature flag is disabled" do
      @topic.context.root_account.disable_feature!(:discussion_checkpoints)

      expect do
        service.call(
          discussion_topic: @topic,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 6
        )
      end.to raise_error(Checkpoints::FlagDisabledError)
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
        now = Time.now.change(usec: 0)
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
    end
  end
end
