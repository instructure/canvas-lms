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

require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon

  context "as a student" do

    before(:each) do
      course_with_student_logged_in
    end

    it "should not allow access to page when marked as hide from student" do
      expected_error = "Unauthorized"
      title = "test_page"
      hfs = true
      edit_roles = "members"

      create_wiki_page(title, hfs, edit_roles)
      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f('.ui-state-error')).to include_text(expected_error)
    end

    it "should not allow students to edit if marked for only teachers can edit" do
      #vars for the create_wiki_page method which seeds the used page
      title = "test_page"
      hfs = false
      edit_roles = "teachers"

      create_wiki_page(title, hfs, edit_roles)
      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f("#content")).not_to contain_css('a.edit-wiki')
    end

    it "should allow students to edit wiki if any option but teachers is selected" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      create_wiki_page(title, hfs, edit_roles)

      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f('a.edit-wiki')).to be_displayed

      #vars for 2nd wiki page with different permissions
      title2 = "test_page2"
      edit_roles2 = "members"

      create_wiki_page(title2, hfs, edit_roles2)

      get "/courses/#{@course.id}/pages/#{title2}"
      wait_for_ajax_requests

      expect(f('a.edit-wiki')).to be_displayed
    end

    it "should allow students to create new pages if enabled" do
      @course.default_wiki_editing_roles = "teachers,students"
      @course.save!

      get "/courses/#{@course.id}/pages"
      wait_for_ajax_requests
      f('.new_page').click
      wait_for_tiny(f('#wiki_page_body'))
      f("#title").send_keys("new page")

      expect_new_page_load { f('form.edit-form button.submit').click }
      new_page = @course.wiki_pages.last
      expect(new_page).to be_published
    end

    it "should not allow students to add links to new pages unless they can create pages" do
      create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/test_page/edit"
      wait_for_ajax_requests

      expect(f("#content")).not_to contain_css('#new_page_link')

      @course.default_wiki_editing_roles = "teachers,students"
      @course.save!

      get "/courses/#{@course.id}/pages/somenewpage/edit" # page that doesn't exist
      wait_for_ajax_requests

      expect(f('#new_page_link')).to_not be_nil
      expect_new_page_load { f('form.edit-form button.submit').click }
      new_page = @course.wiki_pages.last
      expect(new_page).to be_published
    end
  end
end
