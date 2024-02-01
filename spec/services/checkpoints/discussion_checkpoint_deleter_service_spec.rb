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

describe Checkpoints::DiscussionCheckpointDeleterService do
  describe ".call" do
    before(:once) do
      course = course_model
      course.root_account.enable_feature!(:discussion_checkpoints)
      @topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
    end

    let(:creator_service) { Checkpoints::DiscussionCheckpointCreatorService }

    let(:deleter_service) { Checkpoints::DiscussionCheckpointDeleterService }

    it "raises a FlagDisabledError when the checkpoints feature flag is disabled" do
      @topic.context.root_account.disable_feature!(:discussion_checkpoints)

      expect do
        deleter_service.call(
          discussion_topic: @topic
        )
      end.to raise_error(Checkpoints::FlagDisabledError)
    end

    it "raises a CheckpointNotFoundError when the checkpoint does not exist" do
      expect do
        deleter_service.call(
          discussion_topic: @topic
        )
      end.to raise_error(Checkpoints::NoCheckpointsFoundError)
    end

    it "deletes a simple checkpoint" do
      creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now }],
        points_possible: 6
      )

      expect do
        deleter_service.call(
          discussion_topic: @topic
        )
      end.to change { SubAssignment.active.count }.by(-1)
    end

    it "deletes a checkpoint with overrides" do
      students = []
      6.times do
        students << student_in_course(course: @topic.course, active_all: true).user
      end

      student_ids = students.map(&:id)

      section = @topic.course.course_sections.create!

      group = @topic.course.groups.create!
      @topic.update!(group_category: group.group_category)

      checkpoint = creator_service.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 2.days.from_now },
                { type: "override", set_type: AssignmentOverride::SET_TYPE_ADHOC, student_ids:, due_at: 3.days.from_now },
                { type: "override", set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION, set_id: section.id, due_at: 5.days.from_now },
                { type: "override", set_type: AssignmentOverride::SET_TYPE_GROUP, set_id: group.id, due_at: 7.days.from_now }],
        points_possible: 6
      )
      sub_assignment_id = checkpoint.id

      sub_assignments = SubAssignment.where(id: sub_assignment_id).active
      overrides = checkpoint.assignment_overrides
      adhoc_override = overrides.find_by(set_type: AssignmentOverride::SET_TYPE_ADHOC)

      expect(sub_assignments.count).to eq 1
      expect(overrides.active.count).to eq 3
      expect(adhoc_override.assignment_override_students.active.count).to eq 6

      deleter_service.call(
        discussion_topic: @topic.reload
      )

      @topic.reload
      sub_assignments.reload
      overrides.reload
      adhoc_override.reload

      expect(sub_assignments.active.count).to eq 0
      expect(overrides.active.count).to eq 0
      expect(@topic.assignment_overrides.active.count).to eq 0
      expect(adhoc_override.assignment_override_students.active.count).to eq 0
    end
  end
end
