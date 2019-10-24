#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "section tabs on the left side" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    it "should highlight which tab is active" do
      BrandableCSS.save_default!('css') # make sure variable css file is up to date
      course_with_teacher_logged_in
      %w{assignments quizzes settings}.each do |feature|
        get "/courses/#{@course.id}/#{feature}"
        element_that_is_not_left_side = f('#content')
        # make sure to mouse off the link so the :hover and :focus styles do not apply
        driver.action.move_to(element_that_is_not_left_side).perform
        menu_link = f("#section-tabs .#{feature}")
        expect(menu_link.css_value('border-left')).to eq('2px solid rgb(45, 59, 69)')
      end
    end
  end
end
