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

describe Checkpoints::DateOverrideCreatorService do
  describe ".call" do
    before(:once) do
      course = course_model
      course.root_account.enable_feature!(:discussion_checkpoints)
      topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
      topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint = topic.reply_to_topic_checkpoint
    end

    let(:service) { Checkpoints::DateOverrideCreatorService }

    it "raises a SetTypeRequiredError when a provided date is missing a set_type" do
      overrides = [{ type: "override", due_at: 2.days.from_now }]
      expect do
        service.call(checkpoint: @checkpoint, overrides:)
      end.to raise_error(Checkpoints::SetTypeRequiredError)
    end

    it "raises a SetTypeNotSupportedError when a provided date has an unsupported set_type" do
      overrides = [{ type: "override", set_type: "Potato", due_at: 2.days.from_now }]
      expect do
        service.call(checkpoint: @checkpoint, overrides:)
      end.to raise_error(Checkpoints::SetTypeNotSupportedError)
    end

    it "calls the SectionOverrideCreatorService to create a section override" do
      section = @checkpoint.course.default_section
      overrides = [{ type: "override", set_type: "CourseSection", set_id: section.id, due_at: 2.days.from_now }]
      expect(Checkpoints::SectionOverrideCreatorService).to receive(:call).once
      service.call(checkpoint: @checkpoint, overrides:)
    end

    it "calls the GroupOverrideCreatorService to create a group override" do
      group = @checkpoint.course.groups.create!
      @checkpoint.parent_assignment.discussion_topic.update!(group_category: group.group_category)
      overrides = [{ type: "override", set_type: "Group", set_id: group.id, due_at: 2.days.from_now }]
      expect(Checkpoints::GroupOverrideCreatorService).to receive(:call).once
      service.call(checkpoint: @checkpoint, overrides:)
    end

    it "calls the AdhocOverrideCreatorService to create an adhoc override" do
      student = student_in_course(course: @checkpoint.course, active_all: true).user
      overrides = [{ type: "override", set_type: "ADHOC", due_at: 2.days.from_now, student_ids: [student.id] }]
      expect(Checkpoints::AdhocOverrideCreatorService).to receive(:call).once
      service.call(checkpoint: @checkpoint, overrides:)
    end
  end
end
