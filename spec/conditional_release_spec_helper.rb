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

require_relative "factory_bot_spec_helper"

RSpec.shared_examples "a soft-deletable model" do
  it { is_expected.to have_db_column(:deleted_at) }

  it "adds a deleted_at where clause when requested" do
    expect(described_class.active.all.where_clause.ast.to_sql).to include('"deleted_at" IS NULL')
  end

  it "skips adding the deleted_at where clause normally" do
    # sorry - no default scopes
    expect(described_class.all.where_clause.ast.to_sql).not_to include("deleted_at")
  end

  it "soft deletes" do
    instance = create(described_class.name.underscore.sub("conditional_release/", "").to_sym)
    instance.destroy!
    expect(described_class.exists?(instance.id)).to be true
    expect(described_class.active.exists?(instance.id)).to be false
  end

  it "allows duplicates on unique attributes when one instance is soft deleted" do
    instance = create(described_class.name.underscore.sub("conditional_release/", "").to_sym)
    copy = instance.clone
    instance.destroy!
    expect { copy.save! }.to_not raise_error
  end
end

module ConditionalRelease
  module SpecHelper
    def setup_course_with_native_conditional_release(course: nil)
      # set up a trigger assignment with rules and whatnot
      course ||= course_with_student(active_all: true) && @course
      @trigger_assmt = course.assignments.create!(points_possible: 10, submission_types: "online_text_entry")
      @sub = @trigger_assmt.submit_homework(@student, body: "hi") if @student

      @set1_assmt1 = course.assignments.create!(only_visible_to_overrides: true) # one in one set
      @set2_assmt1 = course.assignments.create!(only_visible_to_overrides: true)
      @set2_assmt2 = course.assignments.create!(only_visible_to_overrides: true) # two in one set
      @set3a_assmt = course.assignments.create!(only_visible_to_overrides: true) # two sets in one range - will have to choose
      @set3b_assmt = course.assignments.create!(only_visible_to_overrides: true)

      ranges = [
        ScoringRange.new(lower_bound: 0.7, upper_bound: 1.0, assignment_sets: [
                           AssignmentSet.new(assignment_set_associations: [AssignmentSetAssociation.new(assignment_id: @set1_assmt1.id)])
                         ]),
        ScoringRange.new(lower_bound: 0.4, upper_bound: 0.7, assignment_sets: [
                           AssignmentSet.new(assignment_set_associations: [
                                               AssignmentSetAssociation.new(assignment_id: @set2_assmt1.id),
                                               AssignmentSetAssociation.new(assignment_id: @set2_assmt2.id)
                                             ])
                         ]),
        ScoringRange.new(lower_bound: 0, upper_bound: 0.4, assignment_sets: [
                           AssignmentSet.new(assignment_set_associations: [AssignmentSetAssociation.new(assignment_id: @set3a_assmt.id)]),
                           AssignmentSet.new(assignment_set_associations: [AssignmentSetAssociation.new(assignment_id: @set3b_assmt.id)])
                         ])
      ]
      @rule = course.conditional_release_rules.create!(trigger_assignment: @trigger_assmt, scoring_ranges: ranges)

      course.conditional_release = true
      course.save!
    end
  end
end
RSpec.configure do |config|
  config.include ConditionalRelease::SpecHelper
end
