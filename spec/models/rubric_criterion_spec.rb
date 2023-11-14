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
require_relative "../spec_helper"
describe RubricCriterion do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:rubric) { rubric_for_course }
  let_once(:teacher) { User.create! }

  it "allows creation of a valid rubric criterion" do
    root_account_id = @course.root_account.id
    rubric_criterion = RubricCriterion.create!(rubric: @rubric, description: "criterion", points: 10, order: 1, created_by: teacher, root_account_id:)
    expect(rubric_criterion.errors.full_messages).to be_empty
    expect(rubric_criterion.valid?).to be_truthy
    expect(rubric_criterion.active?).to be_truthy
    expect(rubric_criterion.rubric).to eq(rubric)
    expect(rubric_criterion.description).to eq("criterion")
  end
end
