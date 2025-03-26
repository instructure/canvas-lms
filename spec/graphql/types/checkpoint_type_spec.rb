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
#

require_relative "../graphql_spec_helper"

describe Types::AssignmentType do
  let_once(:course) { course_factory(active_all: true) }

  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:student) { student_in_course(course:, active_all: true).user }
  let_once(:admin_user) { account_admin_user_with_role_changes }

  let(:everyone_due_at) { 2.days.from_now }
  let(:student_due_at) { 3.days.from_now }
  let(:student_lock_at) { 4.days.from_now }
  let(:student_unlock_at) { 1.day.from_now }

  let(:topic) { DiscussionTopic.create_graded_topic!(course:, title: "Checkpointed Discussion") }

  let(:checkpoint_assignment) { topic.reload.assignment }
  let(:checkpoint) { topic.reload.assignment.sub_assignments.first }
  let(:checkpoint_assignment_type) { GraphQLTypeTester.new(checkpoint_assignment, current_user: student) }
  let(:teacher_checkpoint_assignment_type) { GraphQLTypeTester.new(checkpoint_assignment, current_user: teacher) }

  before do
    course.account.enable_feature!(:discussion_checkpoints)

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: topic,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [
        { type: "everyone", due_at: everyone_due_at },
        { type: "override", set_type: "ADHOC", student_ids: [student.id], due_at: student_due_at, lock_at: student_lock_at, unlock_at: student_unlock_at }
      ],
      points_possible: 10
    )

    topic.reload
  end

  it "works" do
    expect(checkpoint_assignment_type.resolve("hasSubAssignments")).to be_truthy
    expect(checkpoint_assignment_type.resolve("checkpoints {pointsPossible}")).to eq [10]
    expect(checkpoint_assignment_type.resolve("checkpoints {name}")).to eq [checkpoint.name]
    expect(checkpoint_assignment_type.resolve("checkpoints {tag}")).to eq [checkpoint.sub_assignment_tag]
    expect(checkpoint_assignment_type.resolve("checkpoints {onlyVisibleToOverrides}")).to eq [checkpoint.only_visible_to_overrides]
    expect(checkpoint_assignment_type.resolve("checkpoints {assignmentOverrides {nodes {dueAt}}}").count).to eq checkpoint.assignment_overrides.count
  end

  describe "overridden fields" do
    it "returns overridden date for student" do
      expect(checkpoint_assignment_type.resolve("checkpoints {dueAt}")).to eq [student_due_at.iso8601]
      expect(checkpoint_assignment_type.resolve("checkpoints {lockAt}")).to eq [student_lock_at.iso8601]
      expect(checkpoint_assignment_type.resolve("checkpoints {unlockAt}")).to eq [student_unlock_at.iso8601]

      # Since the student doesn't have GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS, their dates will be overridden even if they say false
      expect(checkpoint_assignment_type.resolve("checkpoints {dueAt(applyOverrides: false)}")).to eq [student_due_at.iso8601]
      expect(checkpoint_assignment_type.resolve("checkpoints {lockAt(applyOverrides: false)}")).to eq [student_lock_at.iso8601]
      expect(checkpoint_assignment_type.resolve("checkpoints {unlockAt(applyOverrides: false)}")).to eq [student_unlock_at.iso8601]
    end

    it "returns set everyone date for teacher" do
      # Due to how assigment overrides are caluclated for teachers/admins in self.overrides_for_assignment_and_user,
      # and since applyOverrides is true by default, teacher due dates are returned as the overriddend ue date from all
      # Overrides. in this case it is the one student override.

      # This matches how the Assignment date field on graphql currently works
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {dueAt}")).to eq [student_due_at.iso8601]
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {lockAt}")).to eq [student_lock_at.iso8601]
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {unlockAt}")).to eq [student_unlock_at.iso8601]

      # Since the teacher has GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS, their due date will be the assignments everyone due date
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {dueAt(applyOverrides: false)}")).to eq [everyone_due_at.iso8601]
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {lockAt(applyOverrides: false)}")).to eq [nil]
      expect(teacher_checkpoint_assignment_type.resolve("checkpoints {unlockAt(applyOverrides: false)}")).to eq [nil]
    end
  end
end
