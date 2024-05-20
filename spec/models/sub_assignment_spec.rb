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
#

describe SubAssignment do
  before do
    @course = course_factory(active_course: true)
    @parent_assignment = @course.assignments.create!
  end

  describe "validations" do
    before do
      @sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
    end

    let(:validation_messages) do
      @sub_assignment.validate
      @sub_assignment.errors.full_messages
    end

    describe "has_sub_assignments" do
      it "must have has_sub_assignments set to false" do
        @sub_assignment.has_sub_assignments = true
        expect(validation_messages).to include "Has sub assignments cannot be true for sub assignments"
      end
    end

    describe "parent_assignment_id" do
      it "must have a parent_assignment_id" do
        @sub_assignment.parent_assignment_id = nil
        expect(validation_messages).to include "Parent assignment can't be blank"
      end

      it "must have a parent_assignment_id that is not self-referencing" do
        @sub_assignment.parent_assignment_id = @sub_assignment.id
        expect(validation_messages).to include "Parent assignment cannot reference self"
      end

      it "does not include a validation message about self-referencing parent_assignment_id when it is blank" do
        @sub_assignment = SubAssignment.new
        expect(validation_messages).not_to include "Parent assignment cannot reference self"
      end
    end

    describe "sub_assignment_tag" do
      it "must be present" do
        @sub_assignment.sub_assignment_tag = nil
        expect(validation_messages).to include "Sub assignment tag is not included in the list"
      end

      it "must be one of the predefined checkpoint labels" do
        @sub_assignment.sub_assignment_tag = "potato"
        expect(validation_messages).to include "Sub assignment tag is not included in the list"
      end
    end
  end

  describe "asset strings" do
    it "can be found via asset string" do
      sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      expect(ActiveRecord::Base.find_by_asset_string(sub_assignment.asset_string)).to eq sub_assignment
    end
  end

  describe "serialization" do
    before do
      @sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
    end

    it "uses sub_assignment as the root key for as_json" do
      expect(@sub_assignment.as_json).to have_key "sub_assignment"
    end

    it "uses sub_assignment as the root key for to_json" do
      expect(JSON.parse(@sub_assignment.to_json)).to have_key "sub_assignment"
    end
  end

  describe "discussion checkpoints" do
    before do
      @parent_assignment.root_account.enable_feature!(:discussion_checkpoints)
      @parent_assignment.update!(title: "graded topic", submission_types: "discussion_topic")
      @topic = @parent_assignment.discussion_topic
      @topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint = @topic.reply_to_topic_checkpoint
    end

    it "updates the parent assignment when tracked attrs change on a checkpoint assignment" do
      expect { @checkpoint.update!(points_possible: 4) }.to change {
        @topic.assignment.reload.points_possible
      }.from(10).to(11)
    end

    it "does not update the parent assignment when attrs that changed are not tracked" do
      expect { @checkpoint.update!(title: "potato") }.not_to change {
        @topic.assignment.reload.updated_at
      }
    end

    it "does not update the parent assignment when the checkpoints flag is disabled" do
      @topic.root_account.disable_feature!(:discussion_checkpoints)
      expect { @checkpoint.update!(points_possible: 4) }.not_to change {
        @topic.assignment.reload.points_possible
      }
    end
  end
end
