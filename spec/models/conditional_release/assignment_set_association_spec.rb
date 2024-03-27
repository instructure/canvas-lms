# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../conditional_release_spec_helper"

module ConditionalRelease
  describe AssignmentSetAssociation do
    it_behaves_like "a soft-deletable model"

    it "must have an assignment_id" do
      assignment = build(:assignment_set_association)
      assignment.assignment_id = nil
      expect(assignment.valid?).to be false
    end

    it "enforces unique assignment_id in assignment_set" do
      asg = create(:assignment_set_association)
      dup = build(:assignment_set_association, assignment_id: asg.assignment_id)
      asg.assignment_set.assignment_set_associations << dup
      expect(dup.valid?).to be false
      expect(dup.errors["assignment_id"].to_s).to match(/taken/)
      expect(asg.assignment_set.valid?).to be false
      expect(asg.assignment_set.errors["assignment_set_associations.assignment_id"].to_s).to match(/taken/)
    end

    it "enforces not having the same assigment_id as the trigger_assignment of its rule" do
      asg = create(:assignment_set_association)
      asg.assignment_id = asg.rule.trigger_assignment_id
      expect(asg.valid?).to be false
      expect(asg.errors["assignment_id"].to_s).to match(/trigger/)
    end
  end
end
