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

describe LatePolicyApplicator do
  context "discussion_checkpoints" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @course.root_account.enable_feature!(:discussion_checkpoints)
      @late_policy = late_policy_factory(course: @course, deduct: 10.0, every: :hour, missing: 80.0)
      @course.late_policy = @late_policy
      @course.save!
    end

    before do
      @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed topic")
      @c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 1.minute.ago }],
        points_possible: 5
      )
      @c2 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 1.minute.ago }],
        points_possible: 5,
        replies_required: 2
      )

      @c1_submission = @c1.submissions.first
      @c2_submission = @c2.submissions.first
    end

    context "for_assignment" do
      it "only applies late policy to sub-assignments" do
        LatePolicyApplicator.for_assignment(@c1)
        LatePolicyApplicator.for_assignment(@c2)

        # since the assignment is past due, and student has not submitted,
        # the late policy initially applies the missing policy component

        # 5 - 5(0.8) = 1
        expect(@c1_submission.reload.score).to eq 1
        expect(@c2_submission.reload.score).to eq 1

        # 1 + 1 = 2
        expect(@topic.assignment.submissions.first.reload.score).to eq 2

        # student submits, teacher grades, and the late policy is recalculated
        rtt = @topic.discussion_entries.create!(user: @student, message: "my reply to topic")
        2.times { |i| @topic.discussion_entries.create!(user: @student, message: "my reply to entry #{i}", parent_id: rtt.id) }

        # grade_student runs the late policy applicator
        @c1.grade_student(@student, grade: 5, grader: @teacher)
        @c2.grade_student(@student, grade: 5, grader: @teacher)

        #  5 - 5(0.1)
        expect(@c1_submission.reload.score).to eq 4.5
        expect(@c2_submission.reload.score).to eq 4.5

        # 4.5 + 4.5 = 9
        expect(@topic.assignment.submissions.first.reload.score).to eq 9
      end
    end

    context "for_course" do
      it "only applies late policy to sub-assignments in the course" do
        LatePolicyApplicator.for_course(@course)

        # since the assignment is past due, and student has not submitted,
        # the late policy initially applies the missing policy component

        # 5 - 5(0.8) = 1
        expect(@c1_submission.reload.score).to eq 1
        expect(@c2_submission.reload.score).to eq 1

        # 1 + 1 = 2
        expect(@topic.assignment.submissions.first.reload.score).to eq 2

        # student submits, teacher grades, and the late policy is recalculated
        rtt = @topic.discussion_entries.create!(user: @student, message: "my reply to topic")
        2.times { |i| @topic.discussion_entries.create!(user: @student, message: "my reply to entry #{i}", parent_id: rtt.id) }

        # grade_student runs the late policy applicator
        @c1.grade_student(@student, grade: 5, grader: @teacher)
        @c2.grade_student(@student, grade: 5, grader: @teacher)

        #  5 - 5(0.1)
        expect(@c1_submission.reload.score).to eq 4.5
        expect(@c2_submission.reload.score).to eq 4.5

        # 4.5 + 4.5 = 9
        expect(@topic.assignment.submissions.first.reload.score).to eq 9
      end
    end

    context "process (without calling for_course or for_assignment)" do
      it "processes only sub-assignments" do
        lpa = LatePolicyApplicator.new(@course, [@topic.assignment, @c1, @c2])
        lpa.process

        # student submits, teacher grades, and the late policy is calculated
        rtt = @topic.discussion_entries.create!(user: @student, message: "my reply to topic")
        2.times { |i| @topic.discussion_entries.create!(user: @student, message: "my reply to entry #{i}", parent_id: rtt.id) }

        # grade_student runs the late policy applicator
        @c1.grade_student(@student, grade: 5, grader: @teacher)
        @c2.grade_student(@student, grade: 5, grader: @teacher)

        #  5 - 5(0.1)
        expect(@c1_submission.reload.score).to eq 4.5
        expect(@c2_submission.reload.score).to eq 4.5

        # 4.5 + 4.5 = 9
        expect(@topic.assignment.submissions.first.reload.score).to eq 9
      end
    end
  end
end
