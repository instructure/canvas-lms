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
require_relative "../common"
require_relative "pages/block_content_editor_page"

describe "Block Content Editor" do
  include_context "in-process server selenium tests"
  include BlockContentEditorPage

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_content_editor)
    @context = @course
  end

  context "Create a new page" do
    it "displays Block Content Editor" do
      create_wiki_page_with_block_content_editor(@course)

      expect(bce_container).to be_displayed
      expect(editor_area).to be_displayed
      expect(toolbar_area).to be_displayed
    end
  end

  context "Add a block" do
    before do
      create_wiki_page_with_block_content_editor(@course)
    end

    it "displays the add block modal" do
      add_block_button.click
      wait_for_ajaximations

      expect(add_block_modal).to be_displayed
      expect(block_groups).to be_displayed
      expect(block_items).to be_displayed
    end

    it "adds a new block" do
      add_block_button.click
      wait_for_ajaximations

      expect(selected_block_group.text).to include("Text")
      expect(selected_block_item.text).to include("Text column")

      add_to_page_button.click
      wait_for_ajaximations

      expect(element_exists?(add_block_modal_selector)).to be false
      expect(block_layout).to be_displayed
      expect(add_block_button).to be_displayed
    end
  end
end
