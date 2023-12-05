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
      assignment = Assignment.new(
        name: "Assignment Name",
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        points_possible: 10,
        due_at: 3.days.from_now,
        only_visible_to_overrides: false
      )

      checkpoint = Checkpoint.new(assignment)
      expect(checkpoint.as_json).to eq({
                                         name: assignment.name,
                                         tag: assignment.sub_assignment_tag,
                                         points_possible: assignment.points_possible,
                                         due_at: assignment.due_at,
                                         only_visible_to_overrides: assignment.only_visible_to_overrides
                                       })
    end
  end
end
