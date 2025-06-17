# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe "context modules, performance update" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  before(:once) do
    course_factory(active_course: true)
    @page1 = @course.wiki_pages.create! title: "title1"
    @page2 = @course.wiki_pages.create! title: "title2"
    @context_module = @course.context_modules.create!(name: "Module X", position: 1)
    @item1 = @context_module.add_item({ type: "wiki_page", id: @page1.id }, nil, position: 2)
    @item2 = @context_module.add_item({ type: "wiki_page", id: @page2.id }, nil, position: 1)

    @page3 = @course.wiki_pages.create! title: "title3"
    @context_module2 = @course.context_modules.create!(name: "Module Y", position: 2)
    @item3 = @context_module2.add_item({ type: "wiki_page", id: @page3.id }, nil, position: 1)
  end

  before do
    Setting.set("module_perf_threshold", 0)
    @course.account.enable_feature!(:modules_perf)
    course_with_teacher_logged_in(course: @course, active_enrollment: true)
  end

  it "lazy loads module items" do
    go_to_modules
    wait_for_dom_ready
    wait_for_children("#context_module_#{@context_module.id}")
    expect(flash_alert).to be_displayed
    expect(flash_alert).to include_text('"Module X" items loaded')
    expect(f("#context_module_#{@context_module.id}")).to be_displayed
    expect(f("#context_module_item_#{@item1.id}")).to be_displayed
    expect(f("#context_module_item_#{@item2.id}")).to be_displayed
  end

  describe "expanded and collapsed modules" do
    it "expands just the first module if no modules are expanded or collapsed" do
      go_to_modules
      wait_for_dom_ready
      # expand the second module
      f(".collapsed_module .expand_module_link").click
      wait_for_ajax_requests
      go_to_modules
      wait_for_dom_ready
      modules = all_context_modules
      # now expect the first and second module to be expanded
      expect(modules).to have_size(2)
      expect(all_expanded_modules).to have_size(2)
    end

    it "remembers the first module was auto expanded" do
      go_to_modules
      wait_for_dom_ready
      wait_for_ajax_requests
      go_to_modules
      modules = all_context_modules
      expect(modules).to have_size(2)
      expect(all_collapsed_modules).to have_size(1)
      expect(collapsed_module(@context_module2.id)).to be_displayed
      expect(modules[1]).not_to contain_css("#context_module_item_#{@item1.id}")
      expect(modules[1]).not_to contain_css("#context_module_item_#{@item2.id}")
    end

    it "does not expand the first module if the user collapses it" do
      progression = @context_module.find_or_create_progression(@teacher)
      progression.collapse!

      go_to_modules
      wait_for_dom_ready

      modules = all_context_modules
      expect(modules).to have_size(2)
      expect(all_collapsed_modules).to have_size(2)
    end

    it "shows modules the user expands" do
      progression = @context_module.find_or_create_progression(@teacher)
      progression.collapse!
      progression = @context_module2.find_or_create_progression(@teacher)
      progression.uncollapse!

      go_to_modules
      wait_for_dom_ready

      modules = all_context_modules
      expect(modules).to have_size(2)
      expect(all_collapsed_modules).to have_size(1)
      expect(modules[0]).not_to contain_css(".context_module_item")
      expect(modules[1]).to contain_css(".context_module_item")
    end

    it "loads items when a collapsed module is expanded" do
      go_to_modules
      wait_for_dom_ready
      expect(flash_alert).to be_displayed
      flash_alert_close_button.click

      modules = all_context_modules
      expect(modules).to have_size(2)
      expect(all_collapsed_modules).to have_size(1)
      expect(modules[0]).to contain_css(".context_module_item")
      expect(modules[1]).not_to contain_css(".context_module_item")
      expand_module_link(@context_module2.id).click
      wait_for_ajaximations
      expect(flash_alert).to be_displayed
      expect(flash_alert).to include_text('"Module Y" items loaded')
      expect(modules[1]).to contain_css(".context_module_item")
    end
  end
end
