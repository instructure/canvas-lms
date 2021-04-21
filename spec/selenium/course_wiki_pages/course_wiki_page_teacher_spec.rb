# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative 'page_objects/wiki_index_page'
require_relative '../helpers/wiki_pages_shared_examples'

describe 'course wiki pages' do
  include_context 'in-process server selenium tests'
  include CourseWikiPage
  include CourseWikiIndexPage

  context 'As a teacher' do
    before do
      course_with_teacher_logged_in
      @page = @course.wiki_pages.create!(title: 'han')
    end

    it "should show the bulk delete button" do
      visit_course_wiki_index_page(@course.id)

      expect(bulk_delete_btn.attribute('disabled')).to eq('true')
      expect(bulk_delete_btn).to be_displayed
    end

    it "deletes selected page" do
      visit_course_wiki_index_page(@course.id)

      select_wiki_page_checkbox.click
      delete_selected_pages

      confirm_delete_pages
      expect(@course.wiki_pages.first.workflow_state).to eq('deleted')
    end

    it "should show immersive Reader button whether page is published or unpublished" do
      @course.root_account.enable_feature!(:immersive_reader_wiki_pages)
      visit_wiki_page_view(@course.id, @page.title)

      # verify unpublishing keeps the button on the page
      unpublish_wiki_page
      expect(immersive_reader_btn).to be_displayed

      # verify publishing keeps the button on the page
      publish_wiki_page
      expect(immersive_reader_btn).to be_displayed
    end

    context 'With granular permission on' do
      it_behaves_like "course_pages_granular_permissions"
    end
  end
end

