#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'

describe "RCS sidebar tests" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it "should add and remove links using RCS sidebar", ignore_js_errors: true do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      visit_front_page(@course)
      wait_for_tiny(edit_wiki_css)

      click_pages_accordion
      click_new_page_link
      expect(new_page_name_input).to be_displayed
      new_page_name_input.send_keys(title)
      click_new_page_submit

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include title
      end
    end

    it "should click on sidebar wiki page to create link in body" do
      title = "wiki-page-1"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)
      visit_front_page(@course)
      click_pages_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include title
      end
    end

    it "should click on sidebar assignment page to create link in body" do
      title = "Assignment-Title"
      @assignment = @course.assignments.create!(:name => title)

      visit_front_page(@course)
      click_assignments_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/assignments/#{@assignment.id}"
      end
    end

    it "should click on sidebar quizzes page to create link in body" do
      title = "Quiz-Title"
      @quiz = @course.quizzes.create!(:workflow_state => "available", :title => title)

      visit_front_page(@course)
      click_quizzes_accordion
      click_sidebar_link(title)

      in_frame wiki_page_body_ifr_id do
        expect(wiki_body_anchor.attribute('href')).to include "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      end
    end
  end
end
