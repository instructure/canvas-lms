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

require_relative "../common"
require_relative "pages/block_editor_page"

describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  # a default page that's had an apple icon block added
  let(:block_page_content) do
    file = File.open(File.expand_path(File.dirname(__FILE__) + "/../../fixtures/block-editor/page-with-apple-icon.json"))
    file.read
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
    @block_page = @course.wiki_pages.create!(title: "Block Page")

    @block_page.update!(
      block_editor_attributes: {
        time: Time.now.to_i,
        version: "0.2",
        blocks: block_page_content
      }
    )
  end

  describe "Columns Section" do
    it "can add and remove columns from the toolbar" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(columns_section).to be_displayed
      expect(columns_section.attribute("class")).to include("columns-1")
      expect(ff(".group-block").count).to eq 1

      columns_section.click # shows the group toolbar
      block_toolbar_up_button.click # now the columns-section toolbar

      columns_input_increment.click
      expect(ff(".group-block").count).to eq 2
      expect(columns_section.attribute("class")).to include("columns-2")

      # deletes the column, but not the blocks
      columns_section.click
      columns_input_decrement.click
      expect(ff(".group-block").count).to eq 2
      expect(columns_section.attribute("class")).to include("columns-1")
    end

    it "can remove all but the last group" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(columns_section).to be_displayed
      expect(columns_section.attribute("class")).to include("columns-1")
      expect(ff(".group-block").count).to eq 1
      columns_section.click # shows the column toolbar
      block_toolbar_up_button.click # shows the section toolbar

      columns_input_increment.click
      expect(ff(".group-block").count).to eq 2
      expect(columns_section.attribute("class")).to include("columns-2")

      columns_input_decrement.click
      expect(ff(".group-block").count).to eq 2 # there are still 2 column blocks

      f(".group-block").click
      expect(block_toolbar_delete_button).to be_displayed
      block_toolbar_delete_button.click
      expect(ff(".group-block").count).to eq 1

      f(".group-block").click
      expect(block_toolbar).to be_displayed
      expect(find_all_with_jquery(block_toolbar_delete_button_selector).present?).to be false
    end
  end
end
