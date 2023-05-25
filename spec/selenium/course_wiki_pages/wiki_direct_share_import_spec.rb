# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative "page_objects/wiki_index_page"
require_relative "../shared_components/copy_to_tray_page"
require_relative "../shared_components/commons_fav_tray"
require_relative "../shared_components/send_to_dialog_page"
require_relative "page_objects/wiki_page"

describe "course wiki pages" do
  include_context "in-process server selenium tests"
  include CourseWikiIndexPage
  include CourseWikiPage
  include CopyToTrayPage
  include CommonsFavoriteTray
  include SendToDialogPage

  context "with direct share FF ON" do
    before do
      course_with_teacher_logged_in
      @course.save!
      @module1 = @course.context_modules.create!(name: "module 1")
      @wiki_page1 = @course.wiki_pages.create!(title: "Here-is-the-first-wiki")
      @module1.add_item(id: @wiki_page1.id, type: "wiki_page")
      # a second course
      @course2 = Course.create!(name: "Second Course2")
      @course2.enroll_teacher(@teacher, enrollment_state: "active")
      @module2 = @course2.context_modules.create!(name: "module 2")
      user_session(@teacher)
    end

    it "displays direct share options in index page" do
      visit_course_wiki_index_page(@course.id)
      manage_wiki_page_item_button(@wiki_page1.title).click

      expect(wiki_page_item_settings_menu.text).to include("Send to...")
      expect(wiki_page_item_settings_menu.text).to include("Copy to...")
    end

    it "can open send-to dialog from individual wiki page menu" do
      visit_wiki_page_view(@course.id, @wiki_page1.title)
      wiki_page_settings_button.click

      wiki_page_send_to_menu.click
      expect(wiki_page_body).to contain_css(send_to_dialog_css_selector)
    end

    it "can open copy-to tray from individual wiki page menu" do
      visit_wiki_page_view(@course.id, @wiki_page1.title)
      wiki_page_settings_button.click

      wiki_page_copy_to_menu.click
      expect(wiki_page_body).to contain_css(copy_to_dialog_css_selector)
    end

    context "copy to" do
      before do
        visit_course_wiki_index_page(@course.id)
        manage_wiki_page_item_button(@wiki_page1.title).click
        copy_to_menu_item.click
      end

      it "copy tray lists modules in destination course" do
        skip("LA-384 gotta add something in jquery to wait for the course fetch to finish")
        course_search_dropdown.click
        course_dropdown_item(@course.name).click
        course_search_dropdown.send_keys(:tab)
        module_search_dropdown.click

        expect(module_dropdown_list.text).to include "module 1"
      end
    end
  end

  context "commons favorites" do
    before do
      @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.wiki_index_menu = { url: "http://www.example.com", text: "Commons Fav" }
      @tool.save!
      course_with_teacher_logged_in
      @course.save!
      user_session(@teacher)
      visit_course_wiki_index_page(@course.id)
    end

    it "is able to launch index menu tool via the tray" do
      page_index_menu_link.click
      wait_for_ajaximations
      page_index_menu_item_link("Commons Fav").click
      wait_for_ajaximations

      expect(commons_fav_tray.text).to include "Commons Fav"
      expect(tray_iframe["src"]).to include "/courses/#{@course.id}/external_tools/#{@tool.id}"

      placement_query_params = Rack::Utils.parse_nested_query(URI.parse(tray_iframe["src"]).query)
      expect(placement_query_params["launch_type"]).to eq "wiki_index_menu"
      expect(placement_query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
      expect(placement_query_params["com_instructure_course_canvas_resource_type"]).to eq "page"
      expect(placement_query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["page"]
    end
  end
end
