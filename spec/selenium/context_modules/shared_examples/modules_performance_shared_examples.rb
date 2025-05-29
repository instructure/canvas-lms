# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../helpers/context_modules_common"
require_relative "../../helpers/public_courses_context"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"

shared_examples_for "module performance with module items" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  context "pagination" do
    it "loads 11 module items with pagination" do
      uncollapse_all_modules(@mod_course, @user)
      get @mod_url
      expect(pagination_exists?(@module_list[0].id)).to be_truthy
    end

    it "loads <10 module items with pagination" do
      uncollapse_all_modules(@mod_course, @user)
      get @mod_url
      expect(pagination_exists?(@module_list[2].id)).to be_falsey
    end

    it "loads 10 module items with pagination" do
      uncollapse_all_modules(@mod_course, @user)
      get @mod_url
      expect(pagination_exists?(@module_list[1].id)).to be_falsey
    end

    it "navigates to the next page" do
      get @mod_url
      scroll_to(module_item_page_button(@module_list[0].id, "Next"))
      click_module_item_page_button(@module_list[0].id, "Next")
      wait_for_ajaximations

      keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
        expect(module_item_exists?(@course.id, 10)).to be_truthy
      end
    end

    it "navigates back to the previous page" do
      get @mod_url
      scroll_to(module_item_page_button(@module_list[0].id, "Next"))
      click_module_item_page_button(@module_list[0].id, "Next")
      wait_for_ajaximations

      keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
        puts "Previous Trying..."
        expect(module_item_page_button_selector(@module_list[0].id, "Previous")).to be_truthy
      end

      scroll_to(module_item_page_button(@module_list[0].id, "Previous"))
      click_module_item_page_button(@module_list[0].id, "Previous")
      wait_for_ajaximations

      keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
        expect(module_item_exists?(@course.id, 0)).to be_truthy
      end
    end

    it "navigates to the second page" do
      get @mod_url
      scroll_to(module_item_page_button(@module_list[0].id, "2"))
      click_module_item_page_button(@module_list[0].id, "2")
      wait_for_ajaximations

      keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
        expect(module_item_exists?(@course.id, 10)).to be_truthy
      end
    end
  end
end

shared_examples_for "module show all or less" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  context "show all or less button" do
    it "has a working Show More/Show Less buttons on a paginated module" do
      get @mod_url
      wait_for_dom_ready
      expect(context_module(@module.id)).to be_displayed
      expect(ff(module_items_selector(@module.id)).size).to eq(10)
      expect(show_all_button(@module)).to be_displayed
      show_all_button(@module).click
      expect(show_less_button(@module)).to be_displayed
      expect(ff(module_items_selector(@module.id)).size).to eq(11)
      show_less_button(@module).click
      expect(show_all_button(@module)).to be_displayed
      expect(ff(module_items_selector(@module.id)).size).to eq(10)
    end

    it "has neither button on a collapsed module" do
      get @mod_url
      wait_for_dom_ready
      collapse_module_link(@module.id).click
      expect(context_module(@module.id)).not_to contain_css(show_all_or_less_button_selector)
    end

    it "shows the number of items in the module" do
      get @mod_url
      wait_for_dom_ready
      expect(show_all_button(@module).text).to include("(11)")
    end

    it "is removed on clicking Collapse All" do
      get @mod_url
      wait_for_dom_ready
      expand_collapse_all_button.click
      expect(context_module(@module.id)).not_to contain_css(show_all_or_less_button_selector)
    end

    context "with one less item" do
      before do
        @module.content_tags.last.destroy
      end

      it "has neither button on a collapsed module" do
        get @mod_url
        wait_for_dom_ready
        expect(context_module(@module.id)).not_to contain_css(show_all_or_less_button_selector)
      end
    end
  end
end

shared_examples_for "add module items to list" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "expands module list when item is added" do
    get @mod_url
    wait_for_dom_ready

    # add new item
    add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
    wait_for_ajaximations
    item = ContentTag.last

    expect(ff(module_items_selector(@module.id)).size).to eq(12)
    expect(pagination_exists?(@module.id)).to be_falsey
    expect(show_less_button(@module)).to be_displayed
    expect(ff(module_items_selector(@module.id)).last.text).to include(item.title)

    show_less_button(@module).click
    expect(show_all_button(@module).text).to include("(12)")
  end

  it "stays paginated when an item is deleted" do
    get @mod_url
    wait_for_dom_ready

    item = ContentTag.first
    manage_module_item_button(item).click
    delete_module_item_button(item).click
    expect(driver.switch_to.alert).not_to be_nil
    driver.switch_to.alert.accept
    expect(ff(module_items_selector(@module.id)).size).to eq(9)
    expect(pagination_exists?(@module.id)).to be_truthy
    expect(show_all_button(@module).text).to include("(10)")

    refresh_page
    wait_for_dom_ready

    expect(pagination_exists?(@module.id)).to be_falsey
  end

  it "shows correct items after delete in expanded module list" do
    get @mod_url
    wait_for_dom_ready
    show_all_button(@module).click

    item = ContentTag.first
    manage_module_item_button(item).click
    delete_module_item_button(item).click
    expect(driver.switch_to.alert).not_to be_nil
    driver.switch_to.alert.accept
    expect(ff(module_items_selector(@module.id)).size).to eq(10)

    refresh_page
    wait_for_dom_ready

    expect(pagination_exists?(@module.id)).to be_falsey
  end

  context "with one less item" do
    before do
      @module.content_tags.last.destroy
    end

    it "paginated list created after refresh when item is added to initiate pagination" do
      skip "not a valid test now that we save the show all/less state"
      get @mod_url
      wait_for_dom_ready

      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      wait_for_ajaximations
      ContentTag.last

      expect(ff(module_items_selector(@module.id)).size).to eq(11)
      expect(pagination_exists?(@module.id)).to be_falsey

      refresh_page
      wait_for_dom_ready

      expect(pagination_exists?(@module.id)).to be_truthy

      expect(show_all_button(@module)).to be_displayed
      expect(show_all_button(@module).text).to include("(11)")
    end
  end
end

shared_examples_for "module moving items" do |context|
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  context "move items with the move tray" do
    before do
      @module2 = @course.context_modules.create!(name: "module 2")
      2.times do |i|
        @module2.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment 2-#{i}").id)
      end
      @course.reload
    end

    it "moves item from one module to the bottom of first module" do
      get @mod_url
      wait_for_dom_ready
      expand_module_link(@module2.id).click
      item = @module2.content_tags.first
      scroll_to(manage_module_item_button(item))
      manage_module_item_button(item).click
      click_module_item_move(item)
      wait_for_ajaximations

      select_module_item_move_tray_module(@module.name)
      select_module_item_move_tray_location("At the Bottom")
      click_module_item_move_tray_move_button
      expect(ff(module_items_selector(@module.id)).last.text).to include(item.title)
      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module)).to be_displayed
      show_less_button(@module).click
      expect(show_all_button(@module).text).to include("(12)")
    end

    it "moves item from one module to the top of first module" do
      get @mod_url
      wait_for_dom_ready
      expand_module_link(@module2.id).click
      item = @module2.content_tags.first
      scroll_to(manage_module_item_button(item))
      wait_for_ajaximations
      manage_module_item_button(item).click
      click_module_item_move(item)
      wait_for_ajaximations

      select_module_item_move_tray_module(@module.name)
      select_module_item_move_tray_location("At the Top")
      click_module_item_move_tray_move_button

      expect(ff(module_items_selector(@module.id)).first.text).to include(item.title)
      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module)).to be_displayed
      show_less_button(@module).click
      expect(show_all_button(@module).text).to include("(12)")
    end

    it "moves item from one module after assignment in first module" do
      get @mod_url
      wait_for_dom_ready
      expand_module_link(@module2.id).click
      wait_for_ajaximations

      item = @module2.content_tags.first
      scroll_to(manage_module_item_button(item))
      manage_module_item_button(item).click
      click_module_item_move(item)
      wait_for_ajaximations

      after_module_item = ff(module_items_selector(@module.id))[2]
      select_module_item_move_tray_module(@module.name)
      select_module_item_move_tray_location("After..")
      select_module_item_move_tray_sibling(after_module_item.text.split("\n")[1])
      click_module_item_move_tray_move_button

      expect(ff(module_items_selector(@module.id))[3].text).to include(item.title)
      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module)).to be_displayed
      show_less_button(@module).click
      expect(show_all_button(@module).text).to include("(12)")
    end

    it "moves item from one module before assignment in first module" do
      get @mod_url
      wait_for_dom_ready

      scroll_to(module_item_page_button(@module.id, "2"))
      click_module_item_page_button(@module.id, "2")
      wait_for_ajaximations

      before_module_item = ff(module_items_selector(@module.id))[0]

      expand_module_link(@module2.id).click
      item = @module2.content_tags.first
      manage_module_item_button(item).click
      click_module_item_move(item)
      wait_for_ajaximations
      select_module_item_move_tray_module(@module.name)
      select_module_item_move_tray_location("Before..")
      select_module_item_move_tray_sibling(before_module_item.text.split("\n")[1])
      click_module_item_move_tray_move_button

      expect(ff(module_items_selector(@module.id))[10].text).to include(item.title)
      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module)).to be_displayed
      show_less_button(@module).click
      expect(show_all_button(@module).text).to include("(12)")
    end

    it "moves item to different page in same module" do
      get @mod_url
      wait_for_dom_ready

      before_module_item_name = ff(module_items_selector(@module.id))[2].text.split("\n")[1]

      scroll_to(module_item_page_button(@module.id, "2"))
      click_module_item_page_button(@module.id, "2")
      wait_for_ajaximations

      item = @module.content_tags.last
      manage_module_item_button(item).click
      click_module_item_move(item)
      wait_for_ajaximations

      select_module_item_move_tray_module(@module.name)
      select_module_item_move_tray_location("Before..")
      select_module_item_move_tray_sibling(before_module_item_name)
      click_module_item_move_tray_move_button

      expect(ff(module_items_selector(@module.id))[2].text).to include(item.title)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module)).to be_displayed
      show_less_button(@module).click
      expect(show_all_button(@module).text).to include("(11)")
    end
  end

  context "move module contents with the move contents tray" do
    before do
      @module2 = @course.context_modules.create!(name: "module 2")
      2.times do |i|
        @module2.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment 2-#{i}").id)
      end
      @course.reload
    end

    it "moves content from one module to another module with first module open/paginated and second module collapsed" do
      last_tag_title = @module.content_tags.last.title

      get @mod_url
      wait_for_dom_ready

      click_manage_module_button(@module)
      click_module_move_contents(@module.id)
      wait_for_ajaximations

      select_module_move_contents_tray_module(@module2.name)
      select_module_move_contents_tray_place("At the Bottom")
      click_module_item_move_tray_move_button
      wait_for_ajaximations

      expect(ff(module_items_selector(@module2.id)).last.text).to include(last_tag_title)
      expect(any_module_items?(@module.id)).to be_falsey
      expect(ff(module_items_selector(@module2.id)).size).to eq(13)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module2)).to be_displayed
      show_less_button(@module2).click
      expect(show_all_button(@module2).text).to include("(13)")
    end

    it "moves content from one module to another module with first module open/all and second module collapsed" do
      first_tag_title = @module.content_tags.first.title

      get @mod_url
      wait_for_dom_ready

      show_all_button(@module).click

      click_manage_module_button(@module)
      click_module_move_contents(@module.id)
      wait_for_ajaximations

      select_module_move_contents_tray_module(@module2.name)
      select_module_move_contents_tray_place("At the Top")
      click_module_item_move_tray_move_button
      wait_for_ajaximations

      expect(ff(module_items_selector(@module2.id)).first.text).to include(first_tag_title)
      expect(any_module_items?(@module.id)).to be_falsey
      expect(ff(module_items_selector(@module2.id)).size).to eq(13)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module2)).to be_displayed
      show_less_button(@module2).click
      expect(show_all_button(@module2).text).to include("(13)")
    end

    it "moves content from one module to another module with first module open and second module expanded/paginated" do
      first_tag_title = @module.content_tags.first.title

      get @mod_url
      wait_for_dom_ready

      expand_module_link(@module2.id).click

      click_manage_module_button(@module)
      click_module_move_contents(@module.id)
      wait_for_ajaximations

      select_module_move_contents_tray_module(@module2.name)
      select_module_move_contents_tray_place("After..")
      select_module_move_contents_tray_sibling(@module2.content_tags.first.title)
      click_module_item_move_tray_move_button
      wait_for_ajaximations

      expect(ff(module_items_selector(@module2.id))[1].text).to include(first_tag_title)
      expect(any_module_items?(@module.id)).to be_falsey
      expect(ff(module_items_selector(@module2.id)).size).to eq(13)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module2)).to be_displayed
      show_less_button(@module2).click
      expect(show_all_button(@module2).text).to include("(13)")
    end

    it "moves content from one module to another module with first module collapsed and second module collapsed" do
      first_tag_title = @module.content_tags.first.title

      get @mod_url
      wait_for_dom_ready
      collapse_module_link(@module.id).click

      click_manage_module_button(@module)
      click_module_move_contents(@module.id)
      wait_for_ajaximations

      select_module_move_contents_tray_module(@module2.name)
      select_module_move_contents_tray_place("Before..")
      select_module_move_contents_tray_sibling(@module2.content_tags.last.title)
      click_module_item_move_tray_move_button
      wait_for_ajaximations

      expect(ff(module_items_selector(@module2.id))[1].text).to include(first_tag_title)
      # LX-2731 will fix this expectation
      # expect(any_module_items?(@module.id)).to be_falsey
      expect(ff(module_items_selector(@module2.id)).size).to eq(13)
      driver.execute_script("window.scrollTo(0, 0)")
      expect(show_less_button(@module2)).to be_displayed
      show_less_button(@module2).click
      expect(show_all_button(@module2).text).to include("(13)")
    end
  end

  context "drag and drop module items" do
    before do
      @module2 = @course.context_modules.create!(name: "module 2")
      2.times do |i|
        @module2.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment 2-#{i}").id)
      end
      @course.reload
    end

    it "drag and drops item within a paginated module" do
      get @mod_url
      wait_for_dom_ready

      module_items_elements = ff(module_items_selector(@module.id))
      module_item_ids = module_items_elements.map { |item| item.attribute("id") }

      module_item_selector1 = module_item_drag_handle_selector(module_item_ids[5])
      module_item_selector2 = module_item_drag_handle_selector(module_item_ids[1])
      drag_and_drop_module_item(module_item_selector1, module_item_selector2)

      expect(show_all_button(@module)).to be_displayed
      module_items_elements_after = ff(module_items_selector(@module.id))
      module_item_ids_after = module_items_elements_after.map { |item| item.attribute("id") }
      expect(module_item_ids_after[1]).to eq(module_item_ids[5])
    end

    it "drag and drops item within a non-paginated module" do
      get @mod_url
      wait_for_dom_ready

      module_items_elements = ff(module_items_selector(@module.id))
      module_item_ids = module_items_elements.map { |item| item.attribute("id") }
      expect(show_all_button(@module)).to be_displayed
      show_all_button(@module).click
      expect(show_less_button(@module)).to be_displayed

      module_item_selector1 = module_item_drag_handle_selector(module_item_ids[5])
      module_item_selector2 = module_item_drag_handle_selector(module_item_ids[1])
      drag_and_drop_module_item(module_item_selector1, module_item_selector2)

      expect(show_less_button(@module)).to be_displayed
      module_items_elements_after = ff(module_items_selector(@module.id))
      module_item_ids_after = module_items_elements_after.map { |item| item.attribute("id") }
      expect(module_item_ids_after[1]).to eq(module_item_ids[5])
    end

    it "drag and drops item from a module to a paginated module" do
      get @mod_url
      wait_for_dom_ready

      module_items_elements = ff(module_items_selector(@module.id))
      module_item_ids = module_items_elements.map { |item| item.attribute("id") }

      expand_module_link(@module2.id).click
      wait_for_ajaximations
      module2_item_elements = ff(module_items_selector(@module2.id))
      module2_item_ids = module2_item_elements.map { |item| item.attribute("id") }

      module_item_selector1 = module_item_drag_handle_selector(module2_item_ids[1])
      module_item_selector2 = module_item_drag_handle_selector(module_item_ids[1])
      drag_and_drop_module_item(module_item_selector1, module_item_selector2)

      expect(show_all_button(@module)).to be_displayed

      module_items_elements_after = ff(module_items_selector(@module.id))
      module_item_ids_after = module_items_elements_after.map { |item| item.attribute("id") }

      expect(module_item_ids_after[2]).to eq(module2_item_ids[1])

      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
    end

    it "drag and drops item from a module to a non-paginated module" do
      get @mod_url
      wait_for_dom_ready

      show_all_button(@module).click

      module_items_elements = ff(module_items_selector(@module.id))
      module_item_ids = module_items_elements.map { |item| item.attribute("id") }

      expand_module_link(@module2.id).click
      wait_for_ajaximations
      module2_item_elements = ff(module_items_selector(@module2.id))
      module2_item_ids = module2_item_elements.map { |item| item.attribute("id") }

      module_item_selector1 = module_item_drag_handle_selector(module2_item_ids[1])
      module_item_selector2 = module_item_drag_handle_selector(module_item_ids[1])
      drag_and_drop_module_item(module_item_selector1, module_item_selector2)

      expect(show_less_button(@module)).to be_displayed

      module_items_elements_after = ff(module_items_selector(@module.id))
      module_item_ids_after = module_items_elements_after.map { |item| item.attribute("id") }

      expect(module_item_ids_after[2]).to eq(module2_item_ids[1])

      expect(ff(module_items_selector(@module2.id)).size).to eq(1)
    end
  end
end
