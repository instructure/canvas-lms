# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::SyncHasSubAssignmentsFlag do
  let(:course) { course_factory(active_course: true) }

  before do
    # No children & correctly flagged false
    @no_subs_correct = course.assignments.create!(
      has_sub_assignments: false,
      workflow_state: "published",
      grading_type: "points"
    )

    # No children but incorrectly flagged true
    @no_subs_incorrect = course.assignments.create!(
      has_sub_assignments: true,
      workflow_state: "published",
      grading_type: "points"
    )

    # Has children & correctly flagged true
    @with_subs_correct = course.assignments.create!(
      has_sub_assignments: true,
      workflow_state: "published",
      grading_type: "points"
    )
    @with_subs_correct.sub_assignments.create!(
      context: course,
      sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
    )

    # Has children but incorrectly flagged false
    @with_subs_missing = course.assignments.create!(
      has_sub_assignments: false,
      workflow_state: "published",
      grading_type: "points"
    )
    @with_subs_missing.sub_assignments.create!(
      context: course,
      sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC
    )
  end

  describe ".run" do
    it "corrects mismatched has_sub_assignments flags without errors" do
      expect { described_class.run }.not_to raise_error

      # unchanged correct ones
      expect(@no_subs_correct.reload.has_sub_assignments).to be_falsey
      expect(@with_subs_correct.reload.has_sub_assignments).to be_truthy

      # fixed mismatches
      expect(@no_subs_incorrect.reload.has_sub_assignments).to be_falsey
      expect(@with_subs_missing.reload.has_sub_assignments).to be_truthy
    end
  end
end
