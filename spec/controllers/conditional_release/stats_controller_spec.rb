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

require_relative "../../conditional_release_spec_helper"

describe ConditionalRelease::StatsController do
  before do
    user_session(@teacher)
  end

  before :once do
    course_with_teacher(active_all: true)
    @students = n_students_in_course(4, course: @course)
    @rule = create(:rule, course: @course)
    @sr1 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: nil, lower_bound: 0.7, assignment_set_count: 2, assignment_count: 5)
    @sr2 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: 0.7, lower_bound: 0.4, assignment_set_count: 2, assignment_count: 5)
    @sr3 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: 0.4, lower_bound: nil, assignment_set_count: 2, assignment_count: 5)
    @as1 = @sr1.assignment_sets.first
    @as2 = @sr2.assignment_sets.first

    @trigger = @rule.trigger_assignment
    @a1, @a2, @a3, @a4, @a5 = @as1.assignment_set_associations.to_a.map(&:assignment)
    @b1, @b2, @b3, @b4, @b5 = @as2.assignment_set_associations.to_a.map(&:assignment)
  end

  def set_assignments(points_possible_per_id = nil)
    ids = [@trigger.id] + @rule.assignment_set_associations.pluck(:assignment_id)
    ids.each do |id|
      points_possible = 100
      points_possible = points_possible_per_id[id] if points_possible_per_id
      Assignment.where(id:).update_all(title: "assn #{id}", points_possible:)
    end
  end

  it "returns an error if you try to get student details for a student who is not assigned to the trigger assignment" do
    student1, student2 = @students.first(2)
    set_assignments
    @trigger.update!(only_visible_to_overrides: true)
    override = @trigger.assignment_overrides.create!(set_type: "ADHOC")
    override.assignment_override_students.create!(user: student1)

    get :student_details, params: { course_id: @course.id, trigger_assignment: @trigger.id, student_id: student2.id }
    expect(response).to be_bad_request
    expect(response.body).to eq(%({"message":"student not assigned to assignment"}))
  end
end
