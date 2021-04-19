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

    it "publishes a newly created item using keyboard" do
      @course.context_modules.create!(name: "Content Page")
      get "/courses/#{@course.id}/modules"
      add_new_module_item('#wiki_pages_select', 'Page', '[ New Page ]', 'New Page Title')

      tag = ContentTag.last
      item = f("#context_module_item_#{tag.id}")
      item.find_element(:css, ".publish-icon[role='button']").send_keys(:return)
      wait_for_ajax_requests

      expect(tag.reload).to be_published
    end

    it "should create a new module using enter key", priority: "2", test_id: 126705 do
      get "/courses/#{@course.id}/modules"
      add_form = new_module_form
      replace_content(add_form.find_element(:id, 'context_module_name'), "module 1")
      3.times do
        driver.action.send_keys(:tab).perform
        wait_for_ajaximations
      end
      driver.action.send_keys(:return).perform
      expect(f('.name')).to be_present
    end

    it "should focus close button on open edit modal" do
      get "/courses/#{@course.id}/modules"

      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(module_item) do
        divs = ff('.ui-dialog-titlebar.ui-widget-header.ui-corner-all.ui-helper-clearfix')
        close_button = nil

        divs.each do |div|
          title_span = div.find_element(:css, '.ui-dialog-title')
          if title_span.text == "Edit Item Details"
            close_button = div.find_element(:css, '.ui-dialog-titlebar-close.ui-corner-all')
          end
        end
        check_element_has_focus(close_button)
      end
    end

    it "retains focus when deleting prerequisites" do
      modules = create_modules(2)
      get "/courses/#{@course.id}/modules"
      mod1 = f("#context_module_#{modules[1].id}")
      f(".ig-header-admin .al-trigger", mod1).click
      f('.edit_module_link', mod1).click; wait_for_ajaximations
      add_button = f(".add_prerequisite_link")
      2.times { add_button.click; wait_for_animations }
      links = ff(".prerequisites_list .criteria_list .delete_criterion_link")
      expect(links.size).to eq 2
      links[1].click
      wait_for_animations
      check_element_has_focus(links[0])
      links[0].click
      wait_for_animations
      check_element_has_focus(add_button)
    end

    it "should add a title attribute to the text header" do
      text_header = 'This is a really long module text header that should be truncated to exactly 98 characters plus the ... part so 101 characters really'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: text_header, type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      locked_title = ff("#context_module_item_#{tag1.id} .locked_title[title]")

      expect(locked_title[0]).to have_attribute("title", text_header)
    end

    context "module item cog focus management", priority: "1" do

      before :once do
        create_modules(1)[0].add_item({id: @assignment.id, type: 'assignment'})
        @tag = ContentTag.last
      end

      before :each do
        get "/courses/#{@course.id}/modules"
        f("#context_module_item_#{@tag.id} .al-trigger").click
      end

      it "should return focus to the cog menu when closing the edit dialog for an item" do
        hover_and_click("#context_module_item_#{@tag.id} .edit_item_link")
        f('.cancel_button.ui-button').click
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when indenting" do
        hover_and_click("#context_module_item_#{@tag.id} .indent_item_link")
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when outdenting" do
        hover_and_click("#context_module_item_#{@tag.id} .indent_item_link")
        f("#context_module_item_#{@tag.id} .al-trigger").click
        hover_and_click("#context_module_item_#{@tag.id} .outdent_item_link")
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when cancelling a delete" do
        hover_and_click("#context_module_item_#{@tag.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.dismiss
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the previous module item link when deleting a module item." do
        add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
        @tag2 = ContentTag.last
        hover_and_click("#context_module_item_#{@tag2.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .item_link"))
      end

      it "should return focus to the parent module's cog when deleting the first module item." do
        first_tag = ContentTag.first
        hover_and_click("#context_module_item_#{first_tag.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations
        check_element_has_focus(f("#context_module_#{first_tag.context_module_id} .al-trigger"))
      end
    end

    context "Keyboard Accessibility", priority: "1" do
      before :once do
        modules = create_modules(2, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
        modules[0].add_item({:id => @assignment2.id, :type => 'assignment'})
        modules[1].add_item({:id => @assignment3.id, :type => 'assignment'})
      end

      before :each do
        skip_if_chrome('skipped - research find html')
        get "/courses/#{@course.id}/modules"

        # focus the first item
        f('html').send_keys("j")
      end

      let(:context_modules) { ff('.context_module .collapse_module_link') }
      let(:context_module_items) { ff('.context_module_item a.title') }

      # Test these shortcuts (access menu by pressing comma key):
      # Up : Previous Module/Item
      # Down : Next Module/Item
      # Space : Move Module/Item
      # k : Previous Module/Item
      # j : Next Module/Item
      # e : Edit Module/Item
      # d : Delete Current Module/Item
      # i : Increase Indent
      # o : Decrease Indent
      # n : New Module
      it "should navigate through modules and module items" do

        # Navigate through modules and module items
        check_element_has_focus(context_modules[0])

        send_keys(:arrow_down)
        check_element_has_focus(context_module_items[0])

        send_keys("j")
        check_element_has_focus(context_module_items[1])

        send_keys("k")
        check_element_has_focus(context_module_items[0])

        send_keys(:arrow_up)
        check_element_has_focus(context_modules[0])
      end

      it "should edit modules" do

        send_keys("e")
        expect(f('#add_context_module_form')).to be_displayed
      end

      it "should create a module" do

        send_keys("n")
        expect(f('#add_context_module_form')).to be_displayed
      end


      it "should indent / outdent" do

        send_keys(:arrow_down)
        check_element_has_focus(context_module_items[0])

        # Test Indent / Outdent
        expect(f('.context_module_item')).to have_class('indent_0')

        send_keys("i")
        wait_for_ajax_requests
        expect(f('.context_module_item')).to have_class('indent_1')

        send_keys("o")
        wait_for_ajax_requests
        expect(f('.context_module_item')).to have_class('indent_0')
      end

      it "should delete" do

        # Test Delete key
        send_keys("d")
        driver.switch_to.alert.accept
        expect(context_module_items).to have_size(2)
      end
    end
  end
end
