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

describe Checkpoint do
  describe "#as_json" do
    it "returns a hash with the correct keys" do
      course_with_teacher(active_all: true)

      parent_assignment = @course.assignments.create!

      sub_assignment = SubAssignment.new(
        name: "Assignment Name",
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        points_possible: 10,
        due_at: 3.days.from_now,
        only_visible_to_overrides: false,
        context: @course,
        parent_assignment:
      )

      sub_assignment.save!

      user = user_factory(active_all: true)
      @course.enroll_student(user).accept!
      students = [user]

      create_adhoc_override_for_assignment(sub_assignment, students, due_at: 2.days.from_now)

      checkpoint = Checkpoint.new(sub_assignment, @teacher)
      json = checkpoint.as_json

      expect(json[:name]).to eq(sub_assignment.name)
      expect(json[:tag]).to eq(sub_assignment.sub_assignment_tag)
      expect(json[:points_possible]).to eq(sub_assignment.points_possible)
      expect(json[:due_at]).to eq(sub_assignment.due_at)
      expect(json[:only_visible_to_overrides]).to eq(sub_assignment.only_visible_to_overrides)
      expect(json[:overrides].length).to eq(1)
      expect(json[:overrides].first[:assignment_id]).to eq(sub_assignment.id)
      expect(json[:overrides].first[:student_ids]).to match_array(students.map(&:id))
    end
  end
end
