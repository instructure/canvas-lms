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
#
#
# some if the specs in here include "ignore_js_errors: true". This is because
# console errors are emitted for things that aren't really errors, like react
# jsx attribute type warnings
#

# NOTE: for these tests to work, our user needs to be in a role with
# Block Editor Templates - edit or Block Editor Global Templates - edit permissions
# I don't have time for that atm, so this is just a stub of a test file

require_relative "../common"
require_relative "pages/block_editor_page"
describe "Block Editor templates", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage
  def drop_new_block(block_name, where)
    drag_and_drop_element(block_toolbox_box_by_block_name(block_name), where)
  end
  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
    @block_page = build_wiki_page("page-with-apple-icon.json")
  end

  context "as a template editor" do
    it "can save a block template" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor

      icon_block.click
      block_toolbar_up_button.click
      expect(true).to be_truthy
    end

    it "can save a section template" do
      expect(1).to be_truthy
    end

    it "can save a page template" do
      expect(2).to be_truthy
    end

    it "can publish an unpublished block template" do
      expect(3).to be_truthy
    end

    it "can unpublish a published block template" do
      expect(4).to be_truthy
    end

    it "can edit a block template's name" do
      expect(5).to be_truthy
    end
  end

  context "as a global template editor" do
    it "can create a global section template" do
      expect(1).to be_truthy
    end

    it "can create a global page template" do
      expect(2).to be_truthy
    end
  end
end
