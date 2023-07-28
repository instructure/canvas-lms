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

require_relative "../../conditional_release_spec_helper"
require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy with native conditional release data" do
    include_context "course copy"

    before :once do
      setup_course_with_native_conditional_release(course: @copy_from)
      @copy_to.conditional_release = true
      @copy_to.save!
    end

    def migrated_assignments(*original_assignments)
      original_assignments.map { |a| @copy_to.assignments.where(migration_id: mig_id(a)).take }
    end

    it "copies everything by default" do
      run_course_copy

      rule_to = @copy_to.conditional_release_rules.first
      expect(rule_to.trigger_assignment).to eq @copy_to.assignments.where(migration_id: mig_id(@trigger_assmt)).take
      expect(rule_to.scoring_ranges.count).to eq 3
      expect(rule_to.scoring_ranges.map(&:upper_bound)).to eq [1.0, 0.7, 0.4]
      expect(rule_to.scoring_ranges.map(&:lower_bound)).to eq [0.7, 0.4, 0.0]
      set1, set2, set3a, set3b = rule_to.scoring_ranges.map(&:assignment_sets).flatten
      expect(set1.assignment_set_associations.map(&:assignment)).to eq migrated_assignments(@set1_assmt1)
      expect(set2.assignment_set_associations.map(&:assignment)).to eq migrated_assignments(@set2_assmt1, @set2_assmt2)
      expect(set3a.assignment_set_associations.map(&:assignment)).to eq migrated_assignments(@set3a_assmt)
      expect(set3b.assignment_set_associations.map(&:assignment)).to eq migrated_assignments(@set3b_assmt)
    end

    it "is able to selectively copy rules via trigger assignments" do
      other_trigger = @copy_from.assignments.create!
      other_rule = @copy_from.conditional_release_rules.create!(trigger_assignment: other_trigger)
      range = other_rule.scoring_ranges.create!(lower_bound: 0.0, upper_bound: 0.5)
      sets = range.assignment_sets.create!
      sets.assignment_set_associations.create!(assignment_id: @set1_assmt1)

      @cm.copy_options = {
        assignments: { mig_id(other_trigger) => "1", mig_id(@set1_assmt1) => "1" } # only copy the trigger and released assignment
      }
      @cm.save!
      run_course_copy

      expect(@copy_to.conditional_release_rules.count).to eq 1
      rule_to = @copy_to.conditional_release_rules.first
      expect(rule_to.trigger_assignment.migration_id).to eq mig_id(other_trigger)
      expect(rule_to.assignment_set_associations.count).to eq 1
      expect(rule_to.assignment_set_associations.first.assignment.migration_id).to eq mig_id(@set1_assmt1)
    end

    it "wipes and rewrite existing rule data on re-copy (for now)" do
      run_course_copy

      rule_to = @copy_to.conditional_release_rules.first
      rule_to.scoring_ranges.first.assignment_sets.destroy_all # blow up the first set on copy side

      # add a new assignment to the first set on origin side
      new_set1_assmt = @copy_from.assignments.create!
      @rule.scoring_ranges.first.assignment_sets.first.assignment_set_associations.create!(assignment_id: new_set1_assmt)

      run_course_copy # copy again

      set1_to = rule_to.reload.scoring_ranges.first.assignment_sets.first
      expect(set1_to.assignment_set_associations.map(&:assignment)).to eq migrated_assignments(@set1_assmt1, new_set1_assmt)
    end

    it "handles an export from the old service format into a natively enabled course" do
      old_account = Account.create!
      @copy_from.update(account: old_account, root_account: old_account)

      allow(ConditionalRelease::Service).to receive(:service_configured?).and_return(true)

      old_format_data = {
        "rules" => [{
          "trigger_assignment" => { "$canvas_assignment_id" => @trigger_assmt.id },
          "scoring_ranges" =>
            [{
              "lower_bound" => 0.2,
              "upper_bound" => 0.6,
              "assignment_sets" =>
                [{ "assignments" => [{ "$canvas_assignment_id" => @set1_assmt1.id }] }]
            }]
        }]
      }

      allow(ConditionalRelease::MigrationService).to receive_messages(
        begin_export: { mock_data: true },
        export_completed?: true,
        retrieve_export: old_format_data
      )

      run_course_copy
      trigger_assmt_to = @copy_to.assignments.where(migration_id: mig_id(@trigger_assmt)).take
      rule_to = trigger_assmt_to.conditional_release_rules.first
      expect(rule_to.scoring_ranges.count).to eq 1
      range_to = rule_to.scoring_ranges.first
      expect(range_to.lower_bound).to eq 0.2
      expect(range_to.upper_bound).to eq 0.6
      released_to = @copy_to.assignments.where(migration_id: mig_id(@set1_assmt1)).take
      expect(range_to.assignment_sets.first.assignment_set_associations.first.assignment).to eq released_to
    end
  end
end
