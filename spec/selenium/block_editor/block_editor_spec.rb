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
# some if the specs in here include "ignore_js_errors: true". This is because
# console errors are emitted for things that aren't really errors, like react
# jsx attribute type warnings
#

# rubocop:disable Specs/NoNoSuchElementError, Specs/NoExecuteScript
require_relative "../common"
require_relative "pages/block_editor_page"

describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  def create_wiki_page_with_block_editor_content(page_title)
    @page = @course.wiki_pages.create!(title: page_title)
    @page.update!(
      title: "#{page_title}-2",
      block_editor_attributes: {
        time: Time.now.to_i,
        version: "1",
        blocks: [
          {
            data: '{"ROOT":{"type":{"resolvedName":"PageBlock"},"isCanvas":true,"props":{},"displayName":"Page","custom":{},"hidden":false,"nodes":["UO_WRGQgSQ"],"linkedNodes":{}},"UO_WRGQgSQ":{"type":{"resolvedName":"BlankSection"},"isCanvas":false,"props":{},"displayName":"Blank Section","custom":{"isSection":true},"parent":"ROOT","hidden":false,"nodes":[],"linkedNodes":{"blank-section_nosection1":"e33NpD3Ck3"}},"e33NpD3Ck3":{"type":{"resolvedName":"NoSections"},"isCanvas":true,"props":{"className":"blank-section__inner"},"displayName":"NoSections","custom":{"noToolbar":true},"parent":"UO_WRGQgSQ","hidden":false,"nodes":[],"linkedNodes":{}}}'
          }
        ]
      }
    )
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
  end

  def wait_for_block_editor
    keep_trying_until do
      disable_implicit_wait { f(".block-editor-editor") } # rubocop:disable Specs/NoDisableImplicitWait
    rescue => e
      puts e.inspect
      false
    end
  end

  def create_wiki_page(course)
    get "/courses/#{course.id}/pages"
    f("a.new_page").click
    wait_for_block_editor
  end

  context "Create new page" do
    before do
      create_wiki_page(@course)
    end

    context "Start from Scratch" do
      it "walks through the stepper" do
        expect(stepper_modal).to be_displayed
        stepper_start_from_scratch.click
        stepper_next_button.click
        expect(stepper_select_page_sections).to be_displayed
        stepper_hero_section_checkbox.click
        stepper_next_button.click
        expect(stepper_select_color_palette).to be_displayed
        stepper_next_button.click
        expect(stepper_select_font_pirings).to be_displayed
        stepper_start_creating_button.click
        expect(f("body")).not_to contain_css(stepper_modal_selector)
        expect(f(".hero-section")).to be_displayed
      end
    end

    context "Start from Template" do
      it "walks through the stepper" do
        expect(stepper_modal).to be_displayed
        stepper_start_from_template.click
        stepper_next_button.click
        f("#template-1").click
        stepper_start_editing_button.click
        expect(f("body")).not_to contain_css(stepper_modal_selector)
        expect(f(".hero-section")).to be_displayed
      end
    end
  end

  context "Edit a page" do
    before do
      create_wiki_page_with_block_editor_content("block editor test")
    end

    it "loads the editor" do
      get "/courses/#{@course.id}/pages/block-editor-test/edit"
      expect(f(".block-editor-editor")).to be_displayed
      block_toolbox_toggle.click
      expect(block_toolbox).to be_displayed
      drag_and_drop_element(f(".toolbox-item.item-button"), f(".blank-section__inner"))
      expect(fj(".blank-section a:contains('Click me')")).to be_displayed
    end
  end
end

# rubocop:enable Specs/NoNoSuchElementError, Specs/NoExecuteScript
