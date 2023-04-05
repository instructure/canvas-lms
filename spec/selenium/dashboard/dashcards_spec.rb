# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../helpers/files_common"
require_relative "../helpers/announcements_common"
require_relative "../helpers/color_common"

describe "dashcards" do
  include_context "in-process server selenium tests"
  include Factories
  include AnnouncementsCommon
  include ColorCommon
  include FilesCommon

  context "as a student" do
    before do
      @course = course_factory(active_all: true)
      course_with_student_logged_in(active_all: true)
    end

    it "shows the trigger button for dashboard options menu in new UI", priority: "1" do
      get "/"
      # verify features of new UI
      expect(f("#application.ic-app")).to be_present
      expect(f(".ic-app-header__main-navigation")).to be_present
      # verify the trigger button for the menu is present
      expect(f("#DashboardOptionsMenu_Container button")).to be_present
    end

    it "toggles dashboard based on the selected menu view", priority: "1" do
      get "/"
      # verify dashboard card view and trigger button for menu
      expect(f(".ic-DashboardCard__link")).to be_displayed
      expect(f("#DashboardOptionsMenu_Container button")).to be_present
      # open dashboard options menu and select recent activity view
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      # verify recent activity view
      expect(f("#dashboard-activity")).to include_text("Recent Activity")
    end

    it "redirects to announcements index", priority: "1" do
      # Icon will not display unless there is an announcement.
      create_announcement
      get "/"

      f("a.announcements").click
      expect(driver.current_url).to include("/courses/#{@course.id}/announcements")
    end

    it "redirects to assignments index", priority: "1" do
      # Icon will not display unless there is an assignment.
      @course.assignments.create!(title: "assignment 1", name: "assignment 1")
      get "/"

      f("a.assignments").click
      expect(driver.current_url).to include("/courses/#{@course.id}/assignments")
    end

    it "redirects to discussions index", priority: "1" do
      # Icon will not display unless there is a discussion.
      @course.discussion_topics.create!(title: "discussion 1", message: "This is a message.")
      get "/"

      f("a.discussions").click
      expect(driver.current_url).to include("/courses/#{@course.id}/discussion_topics")
    end

    it "redirects to files index", priority: "1" do
      # Icon will not display unless there is a file.
      add_file(fixture_file_upload("example.pdf", "application/pdf"), @course, "example.pdf")
      get "/"

      f("a.files").click
      expect(driver.current_url).to include("/courses/#{@course.id}/files")
    end

    it "displays color picker", priority: "1" do
      get "/"
      f(".ic-DashboardCard__header-button").click
      expect(f(".ColorPicker__Container")).to be_displayed
    end

    it "displays dashcard icons for course contents", priority: "1" do
      # create discussion, announcement, discussion and files as these 4 icons need to be displayed
      @course.discussion_topics.create!(title: "discussion 1", message: "This is a message.")
      @course.assignments.create!(title: "assignment 1", name: "assignment 1")
      create_announcement
      add_file(fixture_file_upload("example.pdf", "application/pdf"), @course, "example.pdf")
      get "/"

      expect(f("a.announcements")).to be_present
      expect(f("a.assignments")).to be_present
      expect(f("a.discussions")).to be_present
      expect(f("a.files")).to be_present
    end

    it "shows announcement created notifications in dashcard", priority: "1" do
      create_announcement("New Announcement")
      get "/"
      expect(f("a.announcements .unread_count").text).to include("1")
    end

    it "does not show hidden tab icons on dashcard", priority: "1" do
      # setup
      @course.tab_configuration = [{ "id" => Course::TAB_DISCUSSIONS, "hidden" => true }]
      @course.save!
      get "/"
      # need not check for announcements, assignments and files as we have not created any
      expect(f("#content")).not_to contain_css(".ic-DashboardCard__action-container .discussions")
    end

    it "does not show unread notification in dashcard after reading announcements", priority: "1" do
      # Create and have the announcement read by the user.
      topic = create_announcement("New Announcement")
      topic.change_read_state("read", @user)

      # The unread notifications should go away since the user has read the announcement
      get "/"
      expect(f("#content")).not_to contain_css("a.announcements .unread_count")
    end

    it "shows discussions created notifications in dashcard", priority: "1" do
      @course.discussion_topics.create!(title: "discussion 1", message: "This is a message.")
      get "/"
      expect(f("a.discussions .unread_count").text).to include("1")
    end

    it "does not show unread notification in dashcard after reading discussions", priority: "1" do
      # Create and have the discussion read by the user.
      topic = @course.discussion_topics.create!(title: "discussion 1", message: "This is a message.")
      topic.change_read_state("read", @user)

      # The unread notifications should go away since the user has read the announcement
      get "/"
      expect(f("#content")).not_to contain_css("a.discussions .unread_count")
    end

    # These tests are currently marked as 'ignore'
    # it 'should show assignments created notifications in dashcard', priority: "1"
    #
    # it 'should show files created notifications in dashcard', priority: "1"

    context "course name and code display" do
      before do
        @course1 = course_model
        @course1.offer!
        @course1.save!
        enrollment = student_in_course(course: @course1, user: @student)
        enrollment.accept!
      end

      it "displays special characters in a course title", priority: "1" do
        @course1.name = '(/*-+_@&$#%)"Course 1"æøåñó?äçíì[{c}]<strong>stuff</strong> )'
        @course1.save!
        get "/"
        expect(f(".ic-DashboardCard__header-title").text).to eq(@course1.name)
      end

      it "displays special characters in course code", priority: "1" do
        # code is not displayed if the course name is too long
        @course1.name = "test"
        @course1.course_code = '(/*-+_@&$#%)"Course 1"[{c}]<strong>stuff</strong> )'
        @course1.save!
        get "/"
        # as course codes are always displayed in upper case
        expect(f(".ic-DashboardCard__header-subtitle").text).to eq(@course1.course_code)
      end
    end

    context "dashcard custom color calendar" do
      before do
        # create another course to ensure the color matches to the right course
        @course1 = course_factory(
          course_name: "Second Course",
          active_course: true
        )
        enrollment = student_in_course(course: @course1, user: @student)
        enrollment.accept!
      end

      it "initially matches color to the dashcard", priority: "1" do
        get "/calendar"
        calendar_color = f(".context-list-toggle-box.group_course_#{@course1.id}").style("background-color")
        get "/"
        hero = f("div[aria-label='#{@course1.name}'] .ic-DashboardCard__header_hero").style("background-color")
        expect(hero).to eq(calendar_color)
      end

      it "customizes color by selecting from color palette on the calendar page", priority: "1" do
        select_color_palette_from_calendar_page

        # pick a random color from the default 15 colors
        new_color = ff(".ColorPicker__ColorContainer button.ColorPicker__ColorBlock")[rand(0...15)]
        # anything to make chrome happy
        driver.action.move_to(new_color).click.perform
        new_color_code = f("#ColorPickerCustomInput-course_#{@course1.id}").attribute(:value)
        f("#ColorPicker__Apply").click
        wait_for_ajaximations

        new_displayed_color = f("[role='checkbox'].group_course_#{@course1.id}").style("color")

        expect("#" + rgba_to_hex(new_displayed_color)).to eq(new_color_code)
        expect(f("#group_course_#{@course1.id}_checkbox_label")).to include_text(@course1.name)
      end
    end

    context "dashcard color picker" do
      before do
        get "/"
        f(".ic-DashboardCard__header-button").click
        wait_for_ajaximations
      end

      it "customizes dashcard color by selecting from color palette", priority: "1" do
        # Gets the default background color
        old_color = @user.reload.custom_colors.fetch("course_#{@course.id}")

        # Picks a new color
        f(".ColorPicker__Container .ColorPicker__ColorBlock:nth-of-type(7)").click
        wait_for_ajaximations
        new_color = f(".ColorPicker__CustomInputContainer .ColorPicker__ColorPreview").attribute(:title)

        # make sure that we choose a new color for background
        if old_color == new_color
          f(".ColorPicker__Container .ColorPicker__ColorBlock:nth-of-type(8)").click
          wait_for_ajaximations
          new_color = f(".ColorPicker__CustomInputContainer .ColorPicker__ColorPreview").attribute(:title)
        end

        # Apply new color and verify it sticks
        f(".ColorPicker__Container #ColorPicker__Apply").click
        rgb = convert_hex_to_rgb_color(new_color)
        expect(old_color).not_to eq new_color
        expect(f(".ic-DashboardCard__header_hero")).to have_attribute("style", rgb)

        keep_trying_until do
          expect(@user.reload.custom_colors.fetch("course_#{@course.id}")).to eq new_color
        end
      end

      it "customizes dashcard color", priority: "1" do
        hex = random_hex_color
        expect(f(".ColorPicker__Container")).to be_displayed
        replace_content(f("#ColorPickerCustomInput-#{@course.asset_string}"), hex)
        f(".ColorPicker__Container #ColorPicker__Apply").click
        hero = f(".ic-DashboardCard__header_hero")
        if hero.attribute(:style).include?("rgb")
          rgb = convert_hex_to_rgb_color(hex)
          expect(hero).to have_attribute("style", rgb)
        else
          expect(hero).to have_attribute("style", hex)
        end
      end

      it "sets course nickname" do
        replace_content(f("#NicknameInput"), "course nickname!")
        f(".ColorPicker__Container #ColorPicker__Apply").click
        wait_for_ajaximations
        expect(f(".ic-DashboardCard__header-title").text).to include "course nickname!"
        expect(@student.reload.course_nickname(@course)).to eq "course nickname!"
      end

      it "sets course nickname when enter is pressed" do
        replace_content(f("#NicknameInput"), "course nickname too!")
        f("#NicknameInput").send_keys(:enter)
        wait_for_ajaximations
        expect(f(".ic-DashboardCard__header-title").text).to include "course nickname too!"
        expect(@student.reload.course_nickname(@course)).to eq "course nickname too!"
      end

      it "sets dashcard color and course nickname at once" do
        replace_content(f("#NicknameInput"), "course nickname frd!")
        replace_content(f("#ColorPickerCustomInput-#{@course.asset_string}"), "#000000")
        f(".ColorPicker__Container #ColorPicker__Apply").click
        wait_for_ajaximations
        expect(@student.reload.course_nickname(@course)).to eq "course nickname frd!"
        expect(@student.custom_colors[@course.asset_string]).to eq "#000000"
      end
    end
  end

  def select_color_palette_from_calendar_page
    get "/calendar"
    raise "Not the right course" unless f("#calendars-context-list li:nth-of-type(2)").text.include? @course1.name

    f("#calendars-context-list li:nth-of-type(2) .ContextList__MoreBtn").click
    wait_for_ajaximations
    expect(f(".ColorPicker__Container")).to be_displayed
  end
end
