#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/context_modules/_module_item_conditional_next" do
  let_once(:module_item) do
    course_factory
    assignment_model course: @course
    context_module = @course.context_modules.create!
    context_module.add_item type: 'assignment', id: @assignment.id
  end

  it "should show mastery path selection" do
    render partial: 'context_modules/module_item_conditional_next', locals: {
      module_item: module_item,
      item_data: { mastery_paths: { locked: true } }
    }
    expect(rendered).to match(/until .* is graded/)
  end

  it "should show mastery path locked" do
    render partial: 'context_modules/module_item_conditional_next', locals: {
      module_item: module_item,
      item_data: {
        mastery_paths: {
          awaiting_choice: true,
          assignment_sets: [[]]
        }
      }
    }
    expect(rendered).to match('Choose Assignment Group')
  end

  it "should show mastery path still processing" do
    render partial: 'context_modules/module_item_conditional_next', locals: {
      module_item: module_item,
      item_data: { mastery_paths: { still_processing: true } }
    }
    expect(rendered).to match('until mastery path is processed')
  end
end
