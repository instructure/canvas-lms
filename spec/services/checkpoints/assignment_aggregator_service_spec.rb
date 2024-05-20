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

describe Checkpoints::AssignmentAggregatorService do
  describe ".call" do
    before(:once) do
      @course = course_model
      @course.root_account.enable_feature!(:discussion_checkpoints)
      @student = student_in_course(course: @course, active_all: true).user
      Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
        @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded topic")
      end

      @topic.create_checkpoints(reply_to_topic_points: 1, reply_to_entry_points: 2)
    end

    let(:service) { Checkpoints::AssignmentAggregatorService }
    let(:service_call) { service.call(assignment: @topic.assignment) }

    describe "invalid states" do
      it "returns false when called with an assignment that does not have sub assignments" do
        assignment = @course.assignments.create!
        expect(service.call(assignment:)).to be false
      end

      it "returns false when called with a 'child' (checkpoint) assignment" do
        assignment = @topic.sub_assignments.first
        expect(service.call(assignment:)).to be false
      end

      it "returns false when called with a soft-deleted assignment" do
        @topic.assignment.destroy
        expect(service_call).to be false
      end

      it "returns false when checkpoint discussions are disabled" do
        @course.root_account.disable_feature!(:discussion_checkpoints)
        expect(service_call).to be false
      end
    end

    describe "points_possible" do
      it "saves the sum of checkpoint assignments' points possible on the parent assignment" do
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          @topic.reply_to_topic_checkpoint.update!(points_possible: 3)
          @topic.reply_to_entry_checkpoint.update!(points_possible: 7)
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.points_possible).to eq 10
      end

      it "handles all checkpoints having no points possible" do
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          @topic.reply_to_topic_checkpoint.update!(points_possible: nil)
          @topic.reply_to_entry_checkpoint.update!(points_possible: nil)
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.points_possible).to be_nil
      end

      it "handles all checkpoints having zero points possible" do
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          @topic.reply_to_topic_checkpoint.update!(points_possible: 0)
          @topic.reply_to_entry_checkpoint.update!(points_possible: 0)
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.points_possible).to eq 0
      end

      it "handles some checkpoints having no points possible" do
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          @topic.reply_to_topic_checkpoint.update!(points_possible: nil)
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.points_possible).to eq 2
      end

      it "ignores soft-deleted checkpoints" do
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          @topic.reply_to_topic_checkpoint.destroy
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.points_possible).to eq 2
      end
    end

    describe "updated_at" do
      it "saves the most recent updated_at between the parent and its checkpoints" do
        now = Time.zone.now
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          Timecop.freeze(1.minute.from_now(now)) do
            @topic.reply_to_topic_checkpoint.update!(points_possible: 3)
          end

          Timecop.freeze(2.minutes.from_now(now)) do
            @topic.reply_to_entry_checkpoint.update!(points_possible: 7)
          end
        end

        expect { Timecop.freeze(3.minutes.from_now(now)) { @topic.assignment.touch } }.to change {
          success = service.call(assignment: @topic.reload.assignment)
          [success, @topic.reload.assignment.updated_at]
        }.from([true, 2.minutes.from_now(now)]).to([true, 3.minutes.from_now(now)])
      end

      it "handles all assignments not having an updated_at" do
        @topic.assignment.update_columns(updated_at: nil)
        @topic.sub_assignments.update_all(updated_at: nil)
        success = service_call
        expect(success).to be true
        expect(@topic.assignment.updated_at).to be_nil
      end

      it "handles some checkpoints not having an updated_at" do
        now = Time.zone.now
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          Timecop.freeze(1.minute.from_now(now)) do
            @topic.reply_to_topic_checkpoint.update!(points_possible: 3)
          end
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.updated_at).to eq 1.minute.from_now(now)
      end

      it "ignores soft-deleted checkpoints" do
        now = Time.zone.now
        Assignment.suspend_callbacks(:aggregate_checkpoint_assignments) do
          Timecop.freeze(1.minute.from_now(now)) do
            @topic.reply_to_topic_checkpoint.update!(points_possible: 3)
          end

          Timecop.freeze(2.minutes.from_now(now)) do
            @topic.reply_to_entry_checkpoint.update!(points_possible: 7)
            @topic.reply_to_entry_checkpoint.destroy
          end
        end

        success = service_call
        expect(success).to be true
        expect(@topic.assignment.updated_at).to eq 1.minute.from_now(now)
      end
    end
  end
end
