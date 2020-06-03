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

require_relative '../../conditional_release_spec_helper'
require_dependency "conditional_release/assignment_set_action"

module ConditionalRelease
  describe AssignmentSetAction, :type => :model do
    it_behaves_like 'a soft-deletable model'

    it "must have student_id and actor_id" do
      set = create :assignment_set
      [:student_id, :actor_id].each do |attr|
        action = build :assignment_set_action, assignment_set: set
        action.send("#{attr}=", nil)
        expect(action.valid?).to be false
        action.send("#{attr}=", '')
        expect(action.valid?).to be false
        action.send("#{attr}=", 'person')
        expect(action.valid?).to be true
      end
    end

    it "must have action" do
      set = create :assignment_set
      action = build :assignment_set_action, assignment_set: set
      action.action= nil
      expect(action.valid?).to be false
      action.action= ''
      expect(action.valid?).to be false
      action.action= 'assign'
      expect(action.valid?).to be true
    end

    it "must have source" do
      set = create :assignment_set
      action = build :assignment_set_action, assignment_set: set
      action.source= nil
      expect(action.valid?).to be false
      action.source= ''
      expect(action.valid?).to be false
      action.source= 'grade_change'
      expect(action.valid?).to be true
    end

    it "must have an assignment_set_id" do
      set = create :assignment_set
      action = build :assignment_set_action
      action.assignment_set_id = nil
      expect(action.valid?).to be false
      action.assignment_set_id = set.id
      expect(action.valid?).to be true
    end

    it "should be valid when assignment_set does not exist" do
      action = create :assignment_set_action
      set_id = action.assignment_set.id
      action.assignment_set.destroy!
      expect(action.reload.valid?).to be true
      expect(action.assignment_set_id).to eq set_id
    end

    describe "self.latest" do
      it "should select only the most recent Action for each Set and user_id" do
        actions = []
        actions << create(:assignment_set_action, student_id: 2, assignment_set: create(:assignment_set))
        set = create :assignment_set
        actions << create(:assignment_set_action, student_id: 1, assignment_set: set)
        actions.concat Array.new(2) { create :assignment_set_action, student_id: 2, assignment_set: set }
        actions.last.update_attribute(:created_at, 1.hour.ago)
        expect(AssignmentSetAction.latest).to eq actions[0..2]
      end
    end

    describe "self.current_assignments" do
      it "should select only actions that have not been unassigned" do
        set = create :assignment_set
        create(:assignment_set_action, action: 'assign', student_id: 'user', assignment_set: set, created_at: 1.hour.ago)
        create(:assignment_set_action, action: 'unassign', student_id: 'user', assignment_set: set)
        expect(AssignmentSetAction.current_assignments('user')).to eq []
        recent = create(:assignment_set_action, action: 'assign', student_id: 'user', assignment_set: set)
        expect(AssignmentSetAction.current_assignments('user')).to eq [recent]
      end

      it "should select only actions for the specified sets" do
        actions = Array.new(3) { create(:assignment_set_action, student_id: 'user') }
        selected_sets = actions[1..2].map(&:assignment_set)
        expect(AssignmentSetAction.current_assignments('user', selected_sets).order(:id)).to eq actions[1..2]
      end
    end

    describe "self.create_from_sets" do
      it 'should create records' do
        range = create :scoring_range_with_assignments, assignment_set_count: 4
        assigned = range.assignment_sets[0..1]
        unassigned = range.assignment_sets[2..3]
        audit_opts = { student_id: 'Will', actor_id: 'Sean', source: 'grade_change' }
        AssignmentSetAction.create_from_sets(assigned, unassigned, audit_opts)
        assigned.each do |s|
          set_action = AssignmentSetAction.find_by(audit_opts.merge(assignment_set_id: s.id, action: 'assign'))
          expect(set_action).to be_present
        end
        unassigned.each do |s|
          set_action = AssignmentSetAction.find_by(audit_opts.merge(assignment_set_id: s.id, action: 'unassign'))
          expect(set_action).to be_present
        end
      end
    end
  end
end
