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

require_relative "messages_helper"

describe "checkpoints_created" do
  include TextHelper

  before :once do
    course_model
    @course.root_account.enable_feature!(:discussion_checkpoints)

    topic = graded_discussion_topic(context: @course)

    @reply_to_topic_due_date = 2.days.from_now
    @reply_to_entry_due_date = 5.days.from_now
    @replies_required = 3

    @reply_to_topic_checkpoint = Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: topic,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [{ type: "everyone", due_at: @reply_to_topic_due_date }],
      points_possible: 5
    )

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: topic,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: [{ type: "everyone", due_at: @reply_to_entry_due_date }],
      points_possible: 15,
      replies_required: @replies_required
    )
  end

  let(:asset) { @reply_to_topic_checkpoint }
  let(:notification_name) { :checkpoints_created }

  include_examples "a message"

  describe "email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to include "Assignment Created - #{asset.parent_assignment.discussion_topic.title}, #{@context.name}"

      expect(msg.body).to include "A new assignment has been created for your course, #{asset.context.name}"
      expect(msg.body).to include asset.parent_assignment.discussion_topic.title
      expect(msg.body).to include "due: reply to topic: #{datetime_string(@reply_to_topic_due_date)}"
      expect(msg.body).to include "additional replies (#{@replies_required}): #{datetime_string(@reply_to_entry_due_date)}"
    end

    it "renders No Due Date if due dates are nil" do
      parent_assignment = asset.parent_assignment

      reply_to_topic_checkpoint = parent_assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      reply_to_entry_checkpoint = parent_assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      reply_to_topic_checkpoint.update!(due_at: nil)
      reply_to_entry_checkpoint.update!(due_at: nil)

      msg = generate_message(notification_name, path_type, asset)

      expect(msg.body).to include "due: reply to topic: No Due Date"
      expect(msg.body).to include "additional replies (#{@replies_required}): No Due Date"
    end
  end
end
