# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::RemoveInvalidCoursePaceModuleItems do
  it "removes invalid course pace module items" do
    course_pace = course_pace_model
    assignment = @course.assignments.create!
    context_module = @course.context_modules.create!
    context_module_tag = assignment.context_module_tags.create!(context_module:, context: @course, tag_type: "context_module")
    course_pace.course_pace_module_items.create!(module_item: context_module_tag)
    learning_outcome_tag = assignment.context_module_tags.create!(context_module:, context: @course, tag_type: "learning_outcome")
    learning_outcome_module_item = course_pace.course_pace_module_items.new(module_item: learning_outcome_tag)
    learning_outcome_module_item.save(validate: false)
    nil_assignment_tag = context_module.add_item(type: "context_module_sub_header", title: "not an assignment")
    nil_assignment_module_item = course_pace.course_pace_module_items.new(module_item: nil_assignment_tag)
    nil_assignment_module_item.save(validate: false)

    expect(@course_pace.course_pace_module_items.count).to eq(3)
    DataFixup::RemoveInvalidCoursePaceModuleItems.run
    expect(@course_pace.course_pace_module_items.count).to eq(1)
  end
end
