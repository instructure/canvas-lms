# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../helpers/quizzes_common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "pages/rce_next_page"
require_relative "pages/rcs_sidebar_page"

# rubocop:disable Specs/NoNoSuchElementError, Specs/NoExecuteScript

describe "RCE next tests" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include WikiAndTinyCommon
  include RCSSidebarPage
  include RCENextPage

  context "RCE Variant" do
    def create_wiki_page(course, rce_variant)
      get "/courses/#{course.id}/pages"
      driver.execute_script("window.RCE_VARIANT='#{rce_variant}'")
      f("a.new_page").click
      wait_for_tiny(f("#wiki_page_body"))
    end

    def menu_bar_button(title)
      element_exists?("//*[contains(concat(\" \",normalize-space(@class),\" \"),\" tox-menubar \")]//*[contains(text(), '#{title}')]", true)
    end

    def toolbar_selector(title)
      "[role=\"toolbar\"][title=\"#{title}\"]"
    end

    def toolbar(title)
      element_exists?(toolbar_selector(title))
    end

    def toolbar_button(toolbar_title, button_title)
      element_exists?("//*[@title='#{toolbar_title}']//*[@aria-label='#{button_title}']", true)
    end

    def status_bar
      f('[data-testid="RCEStatusBar"]')
    end

    def status_bar_button(title)
      element_exists?("[data-testid=\"RCEStatusBar\"] [title=\"#{title}\"]")
    end

    before do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    context "Full RCE" do
      it "has all the UI" do
        create_wiki_page(@course, "full")

        # the menus
        expect(f(".tox-menubar")).to be_displayed
        expect(menu_bar_button("Edit")).to be_truthy
        expect(menu_bar_button("View")).to be_truthy
        expect(menu_bar_button("Insert")).to be_truthy
        expect(menu_bar_button("Format")).to be_truthy
        expect(menu_bar_button("Tools")).to be_truthy
        expect(menu_bar_button("Table")).to be_truthy

        # the toolbar (some might be hidden behind the "more" button)
        expect(toolbar("Styles")).to be_truthy
        expect(toolbar_button("Styles", "Font sizes")).to be_truthy
        expect(toolbar_button("Styles", "Blocks")).to be_truthy

        expect(toolbar("Formatting")).to be_truthy
        expect(toolbar_button("Formatting", "Bold")).to be_truthy
        expect(toolbar_button("Formatting", "Italic")).to be_truthy
        expect(toolbar_button("Formatting", "Underline")).to be_truthy
        expect(toolbar_button("Formatting", "Text color")).to be_truthy
        expect(toolbar_button("Formatting", "Background color")).to be_truthy
        expect(toolbar_button("Formatting", "Superscript and Subscript")).to be_truthy

        expect(toolbar("Content")).to be_truthy
        expect(toolbar_button("Content", "Links")).to be_truthy
        expect(toolbar_button("Content", "Images")).to be_truthy
        expect(toolbar_button("Content", "Record/Upload Media")).to be_truthy
        expect(toolbar_button("Content", "Documents")).to be_truthy
        expect(toolbar_button("Content", "Icon Maker Icons")).to be_truthy

        # no external tools in this spec
        # expect(possible_hidden_toolbar("External Tools")).to be_truthy
        expect(toolbar("Alignment and Lists")).to be_truthy
        expect(toolbar_button("Alignment and Lists", "Align")).to be_truthy
        expect(toolbar_button("Alignment and Lists", "Ordered and Unordered Lists")).to be_truthy
        expect(toolbar_button("Alignment and Lists", "Increase Indent")).to be_truthy

        expect(toolbar("Miscellaneous")).to be_truthy
        expect(toolbar_button("Miscellaneous", "Clear formatting")).to be_truthy
        expect(toolbar_button("Miscellaneous", "Table")).to be_truthy
        expect(toolbar_button("Miscellaneous", "Insert Math Equation")).to be_truthy
        expect(toolbar_button("Miscellaneous", "Embed")).to be_truthy

        expect(f('[data-testid="RCEStatusBar"]')).to be_truthy
        expect(status_bar_button("View keyboard shortcuts")).to be_truthy
        expect(status_bar_button("Accessibility Checker")).to be_truthy
        expect(status_bar_button("View word and character counts")).to be_truthy
        expect(status_bar_button("Click or shift-click for the html editor.")).to be_truthy
        expect(status_bar_button("Fullscreen")).to be_truthy
        expect(status_bar_button("Resize")).to be_truthy
      end
    end

    context "lite RCE" do
      it "has less UI" do
        create_wiki_page(@course, "lite")

        # no menus
        expect(f("body")).not_to contain_css(".tox-menubar>*")

        # expect(f(".tox-toolbar-overlord")).not_to contain_css(toolbar_selector("Styles"))
        expect(toolbar("Styles")).to be_truthy
        expect(toolbar_button("Styles", "Font sizes")).to be_falsey
        expect(toolbar_button("Styles", "Blocks")).to be_truthy

        expect(toolbar("Formatting")).to be_truthy
        expect(toolbar_button("Formatting", "Bold")).to be_truthy
        expect(toolbar_button("Formatting", "Italic")).to be_truthy
        expect(toolbar_button("Formatting", "Underline")).to be_truthy
        expect(toolbar_button("Formatting", "Text color")).to be_truthy
        expect(toolbar_button("Formatting", "Background color")).to be_falsey
        expect(toolbar_button("Formatting", "Superscript and Subscript")).to be_falsey

        expect(toolbar("Content")).to be_truthy
        expect(toolbar_button("Content", "Links")).to be_truthy
        expect(toolbar_button("Content", "Images")).to be_truthy
        expect(toolbar_button("Content", "Record/Upload Media")).to be_falsey
        expect(toolbar_button("Content", "Documents")).to be_falsey
        expect(toolbar_button("Content", "Icon Maker Icons")).to be_falsey

        # Alignment and Lists is renamed for lite
        expect(toolbar("Lists")).to be_truthy
        expect(toolbar_button("Lists", "Align")).to be_falsey
        expect(toolbar_button("Lists", "Ordered and Unordered Lists")).to be_truthy
        expect(toolbar_button("Lists", "Increase Indent")).to be_falsey

        expect(toolbar("Miscellaneous")).to be_truthy
        expect(toolbar_button("Miscellaneous", "Insert Math Equation")).to be_truthy

        expect(element_exists?('[data-testid="RCEStatusBar"]')).to be true
        expect(status_bar_button("View keyboard shortcuts")).to be_truthy
        expect(status_bar_button("Accessibility Checker")).to be_truthy
        expect(status_bar_button("View word and character counts")).to be_truthy
        expect(status_bar_button("Click or shift-click for the html editor.")).to be_falsey
        expect(status_bar_button("Fullscreen")).to be_falsey
        expect(status_bar_button("Resize")).to be_falsey
      end
    end

    context "text-only RCE" do
      it "has even less UI" do
        create_wiki_page(@course, "text-only")

        # no menus
        expect(f("body")).not_to contain_css(".tox-menubar>*")

        # expect(f(".tox-toolbar-overlord")).not_to contain_css(toolbar_selector("Styles"))
        expect(toolbar("Styles")).to be_falsey
        expect(toolbar_button("Styles", "Font sizes")).to be_falsey
        expect(toolbar_button("Styles", "Blocks")).to be_falsey

        expect(toolbar("Formatting")).to be_truthy
        expect(toolbar_button("Formatting", "Bold")).to be_truthy
        expect(toolbar_button("Formatting", "Italic")).to be_truthy
        expect(toolbar_button("Formatting", "Underline")).to be_truthy
        expect(toolbar_button("Formatting", "Text color")).to be_falsey
        expect(toolbar_button("Formatting", "Background color")).to be_falsey
        expect(toolbar_button("Formatting", "Superscript and Subscript")).to be_falsey

        expect(toolbar("Content")).to be_truthy
        expect(toolbar_button("Content", "Links")).to be_truthy
        expect(toolbar_button("Content", "Images")).to be_falsey
        expect(toolbar_button("Content", "Record/Upload Media")).to be_falsey
        expect(toolbar_button("Content", "Documents")).to be_falsey
        expect(toolbar_button("Content", "Icon Maker Icons")).to be_falsey

        # Alignment and Lists is renamed Lists for lite, but it doesn't exist in text-only at all
        expect(toolbar("Lists")).to be_falsey
        expect(toolbar("Alignment and Lists")).to be_falsey

        expect(toolbar("Miscellaneous")).to be_falsey

        expect(element_exists?('[data-testid="RCEStatusBar"]')).to be true
        expect(status_bar_button("View keyboard shortcuts")).to be_truthy
        expect(status_bar_button("Accessibility Checker")).to be_truthy
        expect(status_bar_button("View word and character counts")).to be_truthy
        expect(status_bar_button("Click or shift-click for the html editor.")).to be_falsey
        expect(status_bar_button("Fullscreen")).to be_falsey
        expect(status_bar_button("Resize")).to be_falsey
      end
    end
  end

  # there is an rce variant 'no-controls', but I don't think it's useful and will probably be removed
end

# rubocop:enable Specs/NoNoSuchElementError, Specs/NoExecuteScript
