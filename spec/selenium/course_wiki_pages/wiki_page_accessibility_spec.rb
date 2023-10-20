# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../helpers/public_courses_context"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "../helpers/files_common"
require_relative "page_objects/wiki_index_page"
require_relative "page_objects/wiki_page"

describe "Wiki Pages" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include WikiAndTinyCommon
  include CourseWikiIndexPage
  include CourseWikiPage

  context "Accessibility" do
    before :once do
      account_model
      course_with_teacher account: @account
      @course.wiki_pages.create!(title: "Foo")
      @course.wiki_pages.create!(title: "Bar")
      @course.wiki_pages.create!(title: "Baz")
    end

    before do
      user_session(@user)
    end

    it "returns focus to the header item clicked while sorting" do
      visit_course_wiki_index_page(@course.id)

      check_header_focus("title")
      check_header_focus("created_at")
      check_header_focus("updated_at")
    end

    context "Publish Cloud" do
      it "sets focus back to the publish cloud after unpublish" do
        visit_course_wiki_index_page(@course.id)
        f(".publish-icon").click
        wait_for_ajaximations
        check_element_has_focus(f(".publish-icon"))
      end

      it "sets focus back to the publish cloud after publish" do
        visit_course_wiki_index_page(@course.id)
        f(".publish-icon").click # unpublish it.
        wait_for_ajaximations
        f(".publish-icon").click # publish it.
        check_element_has_focus(f(".publish-icon"))
      end
    end

    context "Delete Page" do
      before do
        visit_course_wiki_index_page(@course.id)
      end

      it "returns focus back to the item cog if the item was not deleted" do
        f("tbody .al-trigger").click
        f(".delete-menu-item").click
        f(".ui-dialog-buttonset .btn").click
        wait_for_ajaximations
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "returns focus back to the item cog if escape was pressed" do
        f("tbody .al-trigger").click
        f(".delete-menu-item").click
        f(".ui-dialog-buttonset .btn").send_keys(:escape)
        wait_for_ajaximations
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "returns focus back to the item cog if the dialog close was pressed" do
        f("tbody .al-trigger").click
        f(".delete-menu-item").click
        f(".ui-dialog-titlebar-close").click
        wait_for_ajaximations
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "returns focus to the previous item title if it was deleted" do
        triggers = ff("tbody .al-trigger")
        titles = ff(".wiki-page-link")
        triggers.last.click
        ff(".delete-menu-item").last.click
        f(".ui-dialog-buttonset .btn-danger").click
        wait_for_ajaximations
        check_element_has_focus(titles[-2])
      end

      it "returns focus to the + Page button if there are no previous item cogs" do
        f("tbody .al-trigger").click
        f(".delete-menu-item").click
        f(".ui-dialog-buttonset .btn-danger").click
        wait_for_ajaximations
        check_element_has_focus(f(".new_page"))
      end
    end

    context "Use as Front Page Link" do
      before do
        visit_course_wiki_index_page(@course.id)
        f("tbody .al-trigger").click
      end

      it "sets focus back to the cog after setting" do
        f(".use-as-front-page-menu-item").click
        wait_for_ajaximations
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "sets focus to the next focusable item if you press Tab" do
        f(".use-as-front-page-menu-item").send_keys(:tab)
        check_element_has_focus(ff(".select-page-checkbox")[1])
      end
    end

    context "Cog menu" do
      before do
        visit_course_wiki_index_page(@course.id)
        f("tbody .al-trigger").click
        f(".edit-menu-item").click
      end

      it "sets focus back to the cog menu if you cancel the dialog" do
        f(".ui-dialog-buttonset .btn").click
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "sets focus back to the cog if you press escape" do
        f(".ui-dialog-buttonset .btn").send_keys(:escape)
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "sets focus back to the cog if you click the dialog close button" do
        f(".ui-dialog-titlebar-close").click
        check_element_has_focus(f("tbody .al-trigger"))
      end

      it "returns focus to the dialog if you cancel, then reopen the dialog" do
        f(".ui-dialog-titlebar-close").click
        check_element_has_focus(f("tbody .al-trigger"))
        f("tbody .al-trigger").click
        f(".edit-menu-item").click
        wait_for_ajaximations
        check_element_has_focus(ff(".page-edit-dialog .edit-control-text").last)
      end

      it "sets focus back to the cog menu if you edit the title and save" do
        f(".ui-dialog-buttonset .btn-primary").click
        wait_for_ajaximations
        check_element_has_focus(f("tbody .al-trigger"))
      end
    end

    context "Revisions Page" do
      before :once do
        account_model
        course_with_teacher account: @account, active_all: true
        @timestamps = %w[2015-01-01 2015-01-02 2015-01-03].map { |d| Time.zone.parse(d) }

        Timecop.freeze(@timestamps[0]) do      # rev 1
          @vpage = @course.wiki_pages.build title: "bar"
          @vpage.workflow_state = "unpublished"
          @vpage.body = "draft"
          @vpage.save!
        end

        Timecop.freeze(@timestamps[1]) do      # rev 2
          @vpage.workflow_state = "active"
          @vpage.body = "published by teacher"
          @vpage.user = @teacher
          @vpage.save!
        end

        Timecop.freeze(@timestamps[2]) do      # rev 3
          @vpage.body = "revised by teacher"
          @vpage.user = @teacher
          @vpage.save!
        end
        @user = @teacher
      end

      before do
        user_session(@user)
        get "/courses/#{@course.id}/pages/#{@vpage.url}/revisions"
      end

      it "focuses the revision buttons" do
        driver.execute_script("$('.close-button').focus();")
        f(".close-button").send_keys(:tab)
        all_revisions = ff(".revision-details")
        all_revisions.each do |revision|
          check_element_has_focus(revision)
          revision.send_keys(:tab)
        end
      end

      it "validates that revision restored is displayed", priority: "1" do
        get "/courses/#{@course.id}/pages/#{@vpage.url}"
        f(".al-trigger").click
        expect(f(".icon-clock")).to be_present
        f(".view_page_history").click
        wait_for_ajaximations
        ff(".revision-details")[1].click
        expect(f(".restore-link")).to be_present
        expect_new_page_load do
          f(".restore-link").click
          f('button[data-testid="confirm-button"]').click
        end
        f(".close-button").click
        wait_for_ajaximations
        f(".icon-edit").click
        expect_new_page_load { f(".btn-primary").click }
        expect(f(".show-content.user_content.clearfix.enhanced")).to include_text "published by teacher"
      end

      it "keeps focus on clicked revision button" do
        driver.execute_script("$('button.revision-details')[1].focus();")
        ff("button.revision-details")[1].click
        wait_for_ajaximations
        check_element_has_focus(ff("button.revision-details")[1])
      end
    end

    context "Edit Page", :ignore_js_errors do
      before do
        visit_wiki_edit_page(@course.id, "bar")
        wait_for_ajaximations
      end

      it "alerts user if navigating away from page with unsaved RCE changes", priority: "1" do
        add_text_to_tiny("derp")
        course_home_nav_menu.click
        expect(driver.switch_to.alert).to be_present
        driver.switch_to.alert.accept
      end

      it "alerts user if navigating away from page with unsaved html changes", priority: "1" do
        skip_if_safari(:alert)
        switch_editor_views
        wiki_page_body.send_keys("derp")
        fln("Home").click
        expect(driver.switch_to.alert).to be_present
        driver.switch_to.alert.accept
      end

      it "does not save changes when navigating away and not saving", priority: "1" do
        skip_if_safari(:alert)
        switch_editor_views
        wiki_page_body.send_keys("derp")
        fln("Home").click
        expect(driver.switch_to.alert).to be_present
        driver.switch_to.alert.accept
        get "/courses/#{@course.id}/pages/bar/edit"
        expect(f("textarea")).not_to include_text("derp")
      end

      it "alerts user if navigating away from page after title change", priority: "1" do
        skip_if_safari(:alert)
        switch_editor_views
        edit_page_title_input.clear
        edit_page_title_input.send_keys("derpy-title")
        fln("Home").click
        expect(driver.switch_to.alert).to be_present
        driver.switch_to.alert.accept
      end
    end
  end
end
