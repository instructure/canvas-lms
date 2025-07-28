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
require_relative "../../helpers/k5_common"

describe "New SideNav Navigation" do
  include_context "in-process server selenium tests"
  include K5Common

  context "As a Teacher" do
    before do
      course_with_teacher_logged_in
      @course.root_account.enable_feature!(:instui_nav)
    end

    def toggle_side_nav
      primary_nav_toggle = f("#sidenav-toggle")
      primary_nav_toggle.click
      wait_for_ajaximations
    end

    context "when side nav is collapsed" do
      before do
        get "/"
        toggle_side_nav
      end

      it "collapses the side nav" do
        expect(f("body")).not_to have_class("primary-nav-expanded")
      end

      it "handles tray navigation correctly" do
        get "/"
        tray_ids = %w[profile-tray courses-tray history-tray help-tray]
        tray_ids.each do |tray_id|
          tray = f("##{tray_id}")
          tray.click
          wait_for_ajaximations
          expect(tray["data-selected"]).to eq("true")
        end
      end

      it "shows custom LTI tool logo/link" do
        @tool = Account.default.context_external_tools.new({
                                                             name: "Commons",
                                                             domain: "canvaslms.com",
                                                             consumer_key: "12345",
                                                             shared_secret: "secret"
                                                           })
        @tool.set_extension_setting(:global_navigation, {
                                      url: "canvaslms.com",
                                      visibility: "admins",
                                      display_type: "full_width",
                                      text: "Commons",
                                      icon_svg_path_64: "M100,37L70.1,10.5v17.6H38.6c-4.9,0-8.8,3.9-8.8,8.8s3.9,8.8,8.8,8.8h31.5v17.6L100,37z"
                                    })
        @tool.save!
        get "/"
        expect(f("#commons-external-tool-tray")).to be_displayed
      end

      it "displays dynamic elements correctly" do
        avatar = f("#user-avatar")
        expect(avatar[:src]).to match(%r{/images/messages/avatar-50\.png$})
      end

      it "shows recent history tray" do
        Setting.set("enable_page_views", "db")
        @assignment = @course.assignments.create(name: "another assessment")
        @quiz = Quizzes::Quiz.create!(title: "quiz1", context: @course)
        page_view_for url: app_url + "/courses/#{@course.id}/assignments/#{@assignment.id}",
                      context: @course,
                      created_at: 5.minutes.ago,
                      asset_category: "assignments",
                      asset_code: @assignment.asset_string
        page_view_for url: app_url + "/courses/#{@course.id}/quizzes/#{@quiz.id}",
                      context: @course,
                      created_at: 1.minute.ago,
                      asset_category: "quizzes",
                      asset_code: @quiz.asset_string

        get "/"
        wait_for_ajaximations
        expect(f("#history-tray")).to be_displayed
      end
    end

    context "when side nav is expanded" do
      before do
        get "/"
        toggle_side_nav
        toggle_side_nav
      end

      it "expands the side nav" do
        expect(f("body")).to have_class("primary-nav-expanded")
      end

      it "handles tray navigation correctly" do
        get "/"
        tray_ids = %w[profile-tray courses-tray history-tray help-tray]
        tray_ids.each do |tray_id|
          tray = f("##{tray_id}")
          tray.click
          wait_for_ajaximations
          expect(tray["data-selected"]).to eq("true")
        end
      end

      it "shows custom LTI tool logo/link" do
        @tool = Account.default.context_external_tools.new({
                                                             name: "Commons",
                                                             domain: "canvaslms.com",
                                                             consumer_key: "12345",
                                                             shared_secret: "secret"
                                                           })
        @tool.set_extension_setting(:global_navigation, {
                                      url: "canvaslms.com",
                                      visibility: "admins",
                                      display_type: "full_width",
                                      text: "Commons",
                                      icon_svg_path_64: "M100,37L70.1,10.5v17.6H38.6c-4.9,0-8.8,3.9-8.8,8.8s3.9,8.8,8.8,8.8h31.5v17.6L100,37z"
                                    })
        @tool.save!
        get "/"
        expect(f("#commons-external-tool-tray")).to be_displayed
      end

      it "displays dynamic elements correctly" do
        avatar = f("#user-avatar")
        expect(avatar[:src]).to match(%r{/images/messages/avatar-50\.png$})
      end

      it "shows recent history tray" do
        Setting.set("enable_page_views", "db")
        @assignment = @course.assignments.create(name: "another assessment")
        @quiz = Quizzes::Quiz.create!(title: "quiz1", context: @course)
        page_view_for url: app_url + "/courses/#{@course.id}/assignments/#{@assignment.id}",
                      context: @course,
                      created_at: 5.minutes.ago,
                      asset_category: "assignments",
                      asset_code: @assignment.asset_string
        page_view_for url: app_url + "/courses/#{@course.id}/quizzes/#{@quiz.id}",
                      context: @course,
                      created_at: 1.minute.ago,
                      asset_category: "quizzes",
                      asset_code: @quiz.asset_string

        get "/"
        wait_for_ajaximations
        expect(f("#history-tray")).to be_displayed
      end
    end
  end
end
