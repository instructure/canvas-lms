#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'page_objects/course_modules_page'

describe 'Course Modules' do
  include_context 'in-process server selenium tests'
  include ModulesPage

  before(:each) do
    # create a course with a teacher
    course_with_teacher(active_all: true, course_name: 'Modules Course')

    # create two modules in course
    @module1 = @course.context_modules.create!(:name => "First Module")
    @module2 = @course.context_modules.create!(:name => "Second Module")

    # create module items(assignments)
    @assignment1 = @course.assignments.create!(:title => 'A1 in module1')
    @assignment2 = @course.assignments.create!(:title => 'A2 in module2')
    @assignment3 = @course.assignments.create!(:title => 'A3 in module1')
    @assignment4 = @course.assignments.create!(:title => 'A3 in module2')

    # add items to module
    @module1.add_item :type => 'assignment', :id => @assignment1.id
    @module2.add_item :type => 'assignment', :id => @assignment2.id
    @module1.add_item :type => 'assignment', :id => @assignment3.id
    @module2.add_item :type => 'assignment', :id => @assignment4.id
  end

  context 'with modules menu' do
    before(:each) do
      user_session(@teacher)
      visit_modules_page(@course.id)
    end

    it 'will open modules sidebar when move_module is selected' do
      open_move_module_menu(@module1.name)

      expect(move_module_sidebar.displayed?).to be true
    end

    it 'will open module sidebar when context item move_module is selected' do
      open_move_context_module_item_menu

      expect(move_context_module_item_sidebar.displayed?).to be true
    end
  end
end
