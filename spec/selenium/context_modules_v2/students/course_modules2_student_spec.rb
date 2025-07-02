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
require_relative "../page_objects/modules2_index_page"
require_relative "../../helpers/items_assign_to_tray"

describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray

  before :once do
    modules2_student_setup
  end

  before do
    user_session(@student)
  end

  it "shows the modules index page" do
    go_to_modules
    expect(student_modules_container).to be_displayed
  end

  context "module expand and collapse" do
    it "shows all modules items when module expanded" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      expand_btn = module_header_expand_toggles[0]
      expect(expand_btn).to be_displayed
      expand_btn.click

      # module should be expanded
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[0].text).to eq(@module_item1.title)
      expect(module_item_titles.count).to eq(2)
    end

    it "can collapse module that has been expanded" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      module_header_expand_toggles[0].click

      # module should be expanded
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles.count).to eq(2)

      # collapse the module
      module_header_expand_toggles[0].click

      # module should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)
    end

    it "retains module expand status" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)
      expand_btn = module_header_expand_toggles[0]
      expect(expand_btn).to be_displayed
      expand_btn.click

      # first module should be expanded
      expect(module_item_titles.count).to eq(2)
      expect(module_item_titles[0]).to be_displayed

      # reload page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # first module should be expanded
      expect(module_item_titles.count).to eq(2)
      expect(module_item_titles[0]).to be_displayed
    end

    it "expands all modules" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      # all modules should be expanded
      expect(module_item_titles.count).to eq(4)
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[1]).to be_displayed
      expect(module_item_titles[2]).to be_displayed
      expect(module_item_titles[3]).to be_displayed
    end

    it "collapses all modules" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      # all modules should be expanded
      expect(module_item_titles.count).to eq(4)

      # collapse all modules
      collapse_all_modules_button.click

      # all modules should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)
    end

    it "expands all modules is retained on refresh" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      go_to_modules
      expect(student_modules_container).to be_displayed

      # all modules should be expanded
      expect(module_item_titles.count).to eq(4)
      expect(module_item_titles[0]).to be_displayed
      expect(module_item_titles[1]).to be_displayed
      expect(module_item_titles[2]).to be_displayed
      expect(module_item_titles[3]).to be_displayed
    end

    it "collapses all modules is retained on refresh" do
      # load page
      go_to_modules
      expect(student_modules_container).to be_displayed

      # module should default to collapsed
      expect(page_body).not_to contain_css(module_item_title_selector)

      # expand all modules
      expand_all_modules_button.click

      # all modules should be expanded
      expect(module_item_titles.count).to eq(4)

      # collapse all modules
      collapse_all_modules_button.click

      # all modules should be collapsed again
      expect(page_body).not_to contain_css(module_item_title_selector)

      go_to_modules
      expect(student_modules_container).to be_displayed
      expect(page_body).not_to contain_css(module_item_title_selector)
    end
  end

  context "course home page" do
    before do
      @course.default_view = "modules"
      @course.save

      @course.root_account.enable_feature!(:modules_page_rewrite_student_view)
    end

    it "shows the new modules" do
      visit_course(@course)
      wait_for_ajaximations

      expect(f('[data-testid="modules-rewrite-student-container"]')).to be_displayed
    end
  end
end
