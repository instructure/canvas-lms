# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)
      # have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(:title => 'quiz assignment', :submission_types => 'online_quiz')
      @assignment = @course.assignments.create!(:title => 'assignment 1', :submission_types => 'online_text_entry')
      @assignment2 = @course.assignments.create!(:title => 'assignment 2',
        :submission_types => 'online_text_entry',
        :due_at => 2.days.from_now,
        :points_possible => 10)
      @assignment3 = @course.assignments.create!(:title => 'assignment 3', :submission_types => 'online_text_entry')

      @ag1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(:name => "Assignment Group 2")
      @course.reload
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should not create a duplicate page if you publish after renaming" do
      mod = @course.context_modules.create! name: 'TestModule'
      page = @course.wiki_pages.create title: 'A Page'
      page.workflow_state = 'unpublished'
      page.save!
      page_count = @course.wiki_pages.count
      tag = mod.add_item({:id => page.id, :type => 'wiki_page'})

      get "/courses/#{@course.id}/modules"

      item = f("#context_module_item_#{tag.id}")
      edit_module_item(item) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item = f("#context_module_item_#{tag.id}")
      item.find_element(:css, '.publish-icon').click
      wait_for_ajax_requests

      expect(@course.wiki_pages.count).to eq page_count
      expect(page.reload).to be_published
    end

    it "should not rename every text header when you rename one" do
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: 'First text header', type: 'sub_header')
      tag2 = mod.add_item(title: 'Second text header', type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      item2 = f("#context_module_item_#{tag2.id}")
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item1 = f("#context_module_item_#{tag1.id}")
      expect(item1).not_to include_text('Renamed!')
    end

    it "should not rename every external tool link when you rename one" do
      tool = @course.context_external_tools.create! name: 'WHAT', consumer_key: 'what', shared_secret: 'what', url: 'http://what.example.org'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: 'A', type: 'external_tool', id: tool.id, url: 'http://what.example.org/A')
      tag2 = mod.add_item(title: 'B', type: 'external_tool', id: tool.id, url: 'http://what.example.org/B')

      get "/courses/#{@course.id}/modules"
      item2 = f("#context_module_item_#{tag2.id}")
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item1 = f("#context_module_item_#{tag1.id}")
      expect(item1).not_to include_text('Renamed!')
    end

    it "should preserve completion criteria after indent change" do
      mod = @course.context_modules.create! name: 'Test Module'
      tag = mod.add_item(type: 'assignment', id: @assignment2.id)
      mod.completion_requirements = {tag.id => {type: 'must_submit'}}
      mod.save!

      get "/courses/#{@course.id}/modules"

      # indent the item
      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.indent_item_link').click

      # make sure the completion criterion was preserved
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item).to have_class 'must_submit_requirement'
      expect(f('.criterion', module_item)).to have_class 'defined'
      expect(driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()")).to eq "must_submit"
    end
  end
end
