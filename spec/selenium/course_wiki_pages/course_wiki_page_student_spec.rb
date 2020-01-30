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

require_relative '../common'
require_relative 'page_objects/wiki_page'

describe 'course wiki pages' do
  include_context 'in-process server selenium tests'
  include CourseWikiPage

  context "Index Page as a student" do
    before(:each) do
      @course = Course.create!(:name => "First Course1")
      @student = User.create!(:name => "First Student")
      @student.accept_terms
      @student.register!
      @course.enroll_student(@student, :enrollment_state => 'active')

      @page = @course.wiki_pages.create!(title: 'delete_deux')
      # sets the workflow_state = deleted to act as a deleted page
      @page.workflow_state = 'deleted'
      @page.save!

      user_session(@student)
    end

    it "should display a warning alert to a student when accessing a deleted page", priority: "1", test_id: 126839 do
      visit_wiki_page_view(@course.id, @page.title)
      expect_flash_message :warning
    end

    it "should display a warning alert when accessing a non-existant page", priority: "1", test_id: 126841 do
      visit_wiki_page_view(@course.id, "non-existant")
      expect_flash_message :warning
    end
  end
end