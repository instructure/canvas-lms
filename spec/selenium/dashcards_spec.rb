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

require_relative 'common'
require_relative 'helpers/files_common'
require_relative 'helpers/announcements_common'
require_relative 'helpers/color_common'

describe 'dashcards' do
  include_context 'in-process server selenium tests'
  include Factories
  include AnnouncementsCommon
  include ColorCommon
  include FilesCommon

  context 'as a student' do

    before do
      @course = course_factory(active_all: true)
      course_with_student_logged_in(active_all: true)
    end

    it 'should show the trigger button for dashboard options menu in new UI', priority: "1", test_id: 222506 do
      get '/'
      # verify features of new UI
      expect(f('#application.ic-app')).to be_present
      expect(f('.ic-app-header__main-navigation')).to be_present
      # verify the trigger button for the menu is present
      expect(f('#DashboardOptionsMenu_Container button')).to be_present
    end

    it 'should toggle dashboard based on the selected menu view', priority: "1", test_id: 222507 do
      get '/'
      # verify dashboard card view and trigger button for menu
      expect(f('.ic-DashboardCard__link')).to be_displayed
      expect(f('#DashboardOptionsMenu_Container button')).to be_present
      # open dashboard options menu and select recent activity view
      f('#DashboardOptionsMenu_Container button').click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      # verify recent activity view
      expect(f('#dashboard-activity').text).to include('Recent Activity')
    end

    it 'should redirect to announcements index', priority: "1", test_id: 222509 do
      # Icon will not display unless there is an announcement.
      create_announcement
      get '/'

      f('a.announcements').click
      expect(driver.current_url).to include("/courses/#{@course.id}/announcements")
    end

    it 'should redirect to assignments index', priority: "1", test_id: 238637 do
      # Icon will not display unless there is an assignment.
      @course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      get '/'

      f('a.assignments').click
      expect(driver.current_url).to include("/courses/#{@course.id}/assignments")
    end

    it 'should redirect to discussions index', priority: "1", test_id: 238638 do
      # Icon will not display unless there is a discussion.
      @course.discussion_topics.create!(title: 'discussion 1', message: 'This is a message.')
      get '/'

      f('a.discussions').click
      expect(driver.current_url).to include("/courses/#{@course.id}/discussion_topics")
    end

    it 'should redirect to files index', priority: "1", test_id: 238639 do
      # Icon will not display unless there is a file.
      add_file(fixture_file_upload('files/example.pdf', 'application/pdf'), @course, 'example.pdf')
      get '/'

      f('a.files').click
      expect(driver.current_url).to include("/courses/#{@course.id}/files")
    end

    it 'should display color picker', priority: "1", test_id: 249122 do
      get '/'
      f('.ic-DashboardCard__header-button').click
      expect(f('.ColorPicker__Container')).to be_displayed
    end

    it 'should display dashcard icons for course contents', priority: "1", test_id: 222508 do
      # create discussion, announcement, discussion and files as these 4 icons need to be displayed
      @course.discussion_topics.create!(title: 'discussion 1', message: 'This is a message.')
      @course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      create_announcement
      add_file(fixture_file_upload('files/example.pdf', 'application/pdf'), @course, 'example.pdf')
      get '/'

      expect(f('a.announcements')).to be_present
      expect(f('a.assignments')).to be_present
      expect(f('a.discussions')).to be_present
      expect(f('a.files')).to be_present
    end

    it 'should show announcement created notifications in dashcard', priority: "1", test_id: 238411 do
      create_announcement('New Announcement')
      get '/'
      expect(f('a.announcements .unread_count').text).to include('1')
      # The notifications should go away after visiting the show page of announcements
      expect_new_page_load{f('a.announcements').click}
      expect_new_page_load{f('.ic-announcement-row h3').click}
      get '/'
      expect(f("#content")).not_to contain_css('a.announcements .unread_count')
    end

    it 'should show discussions created notifications in dashcard', priority: "1", test_id: 240009 do
      @course.discussion_topics.create!(title: 'discussion 1', message: 'This is a message.')
      get '/'
      expect(f('a.discussions .unread_count').text).to include('1')
      # The notifications should go away after visiting the show page of discussions
      expect_new_page_load{f('a.discussions').click}
      expect_new_page_load{fln('discussion 1').click}
      get '/'
      expect(f("#content")).not_to contain_css('a.discussions .unread_count')
    end

    # These tests are currently marked as 'ignore'
    # it 'should show assignments created notifications in dashcard', priority: "1", test_id: 238413
    #
    # it 'should show files created notifications in dashcard', priority: "1", test_id: 238414

    context "course name and code display" do
      before :each do
        @course1 = course_model
        @course1.offer!
        @course1.save!
        enrollment = student_in_course(course: @course1, user: @student)
        enrollment.accept!
      end

      it 'should display special characters in a course title', priority: "1", test_id: 238192 do
        @course1.name = '(/*-+_@&$#%)"Course 1"æøåñó?äçíì[{c}]<strong>stuff</strong> )'
        @course1.save!
        get '/'
        expect(f('.ic-DashboardCard__header-title').text).to eq(@course1.name)
      end

      it 'should display special characters in course code', priority: "1", test_id: 240008 do
        # code is not displayed if the course name is too long
        @course1.name = 'test'
        @course1.course_code = '(/*-+_@&$#%)"Course 1"[{c}]<strong>stuff</strong> )'
        @course1.save!
        get '/'
        # as course codes are always displayed in upper case
        expect(f('.ic-DashboardCard__header-subtitle').text).to eq(@course1.course_code)
      end
    end

    context "dashcard custom color calendar" do
      before :each do
        # create another course to ensure the color matches to the right course
        @course1 = course_factory(
          course_name: 'Second Course',
          active_course: true
        )
        enrollment = student_in_course(course: @course1, user: @student)
        enrollment.accept!
      end

      it 'should initially match color to the dashcard', priority: "1", test_id: 268713 do
        get '/calendar'
        calendar_color = f(".context-list-toggle-box.group_course_#{@course1.id}").style('background-color')
        get '/'
        hero = f("div[aria-label='#{@course1.name}'] .ic-DashboardCard__header_hero").style('background-color')
        expect(hero).to eq(calendar_color)
      end

      it 'should customize color by selecting from color palette in the calendar page', priority: "1", test_id: 239994 do
        select_color_palette_from_calendar_page

        # pick a random color from the default 15 colors
        new_color = ff('.ColorPicker__ColorContainer button.ColorPicker__ColorBlock')[rand(0...15)]
        # anything to make chrome happy
        driver.mouse.move_to(new_color)
        driver.action.click.perform
        new_color_code = f("#ColorPickerCustomInput-course_#{@course1.id}").attribute(:value)
        f('#ColorPicker__Apply').click
        wait_for_ajaximations

        new_displayed_color = f("[role='checkbox'].group_course_#{@course1.id}").style('color')

        expect('#'+rgba_to_hex(new_displayed_color)).to eq(new_color_code)
        expect(f("#group_course_#{@course1.id}_checkbox_label")).to include_text(@course1.name)
      end

      it 'should customize color by using hex code in calendar page', priority: "1", test_id: 239993 do
        select_color_palette_from_calendar_page

        hex = random_hex_color
        replace_content(f("#ColorPickerCustomInput-#{@course1.asset_string}"), hex)
        f('.ColorPicker__Container #ColorPicker__Apply').click
        wait_for_ajaximations
        get '/'
        expect(f('.ic-DashboardCard__header-title')).to include_text(@course1.name)
        if f('.ic-DashboardCard__header_hero').attribute(:style).include?('rgb')
          rgb = convert_hex_to_rgb_color(hex)
          expect(f('.ic-DashboardCard__header_hero')).to have_attribute("style", rgb)
        else
          expect(f('.ic-DashboardCard__header_hero')).to have_attribute("style", hex)
        end
      end
    end

    context "dashcard color picker" do
      before :each do
        get '/'
        f('.ic-DashboardCard__header-button').click
        wait_for_ajaximations
      end

      it 'should customize dashcard color by selecting from color palet', priority: "1", test_id: 238196 do
        # gets the default background color
        old_color = f('.ColorPicker__CustomInputContainer .ColorPicker__ColorPreview').attribute(:title)

        expect(f('.ColorPicker__Container')).to be_displayed
        f('.ColorPicker__Container .ColorPicker__ColorBlock:nth-of-type(7)').click
        wait_for_ajaximations
        new_color =  f('.ColorPicker__CustomInputContainer .ColorPicker__ColorPreview').attribute(:title)

        # make sure that we choose a new color for background
        if old_color == new_color
          f('.ColorPicker__Container .ColorPicker__ColorBlock:nth-of-type(8)').click
          wait_for_ajaximations
        end

        f('.ColorPicker__Container #ColorPicker__Apply').click
        rgb = convert_hex_to_rgb_color(new_color)
        hero = f('.ic-DashboardCard__header_hero')
        expect(hero).to have_attribute("style", rgb)
        refresh_page
        expect(f('.ic-DashboardCard__header_hero')).to have_attribute("style", rgb)
      end

      it 'should initially focus the nickname input' do
        check_element_has_focus(f('#NicknameInput'))
      end

      it 'should customize dashcard color', priority: "1", test_id: 239991 do
        hex = random_hex_color
        expect(f('.ColorPicker__Container')).to be_displayed
        replace_content(f("#ColorPickerCustomInput-#{@course.asset_string}"), hex)
        f('.ColorPicker__Container #ColorPicker__Apply').click
        hero = f('.ic-DashboardCard__header_hero')
        if hero.attribute(:style).include?('rgb')
          rgb = convert_hex_to_rgb_color(hex)
          expect(hero).to have_attribute("style", rgb)
        else
          expect(hero).to have_attribute("style", hex)
        end
      end

      it 'sets course nickname' do
        replace_content(fj('#NicknameInput'), 'course nickname!')
        f('.ColorPicker__Container #ColorPicker__Apply').click
        wait_for_ajaximations
        expect(f('.ic-DashboardCard__header-title').text).to include 'course nickname!'
        expect(@student.reload.course_nickname(@course)).to eq 'course nickname!'
      end

      it 'sets course nickname when enter is pressed' do
        replace_content(fj('#NicknameInput'), 'course nickname too!')
        fj('#NicknameInput').send_keys(:enter)
        wait_for_ajaximations
        expect(f('.ic-DashboardCard__header-title').text).to include 'course nickname too!'
        expect(@student.reload.course_nickname(@course)).to eq 'course nickname too!'
      end

      it 'sets both dashcard color and course nickname at once' do
        replace_content(fj('#NicknameInput'), 'course nickname frd!')
        replace_content(fj("#ColorPickerCustomInput-#{@course.asset_string}"), '#000000')
        f('.ColorPicker__Container #ColorPicker__Apply').click
        wait_for_ajaximations
        expect(@student.reload.course_nickname(@course)).to eq 'course nickname frd!'
        expect(@student.custom_colors[@course.asset_string]).to eq '#000000'
      end
    end
  end

  context "as a teacher and student" do
    before :each do
      @course = course_factory(active_all: true)
      course_with_teacher_logged_in(active_all: true)
      @student = user_with_pseudonym(username: 'student@example.com', active_all: 1)
      enrollment = student_in_course(course: @course, user: @student)
      enrollment.accept!
    end

    it "should show/hide icons", priority: "1", test_id: 238416 do
      make_full_screen
      get '/'
      # check for discussion icon which will be visible by default in the dashcard
      # need not check for announcements, assignments and files as we have not created any
      expect(f(".ic-DashboardCard__action-container .discussions")).to be_present
      get "/courses/#{@course.id}/settings"
      f('#navigation_tab').click
      wait_for_ajaximations
      items_to_hide = ['announcements', 'assignments', 'discussions', 'files']
      4.times do |i|
        drag_and_drop_element(f("#nav_enabled_list .#{items_to_hide[i]}"), f('#nav_disabled_list'))
        expect(f("#nav_disabled_list .#{items_to_hide[i]}")).to be_present
      end
      submit_form('#nav_form')
      wait_for_ajaximations
      user_session(@student)
      get '/'
      # need not check for announcements, assignments and files as we have not created any
      expect(f("#content")).not_to contain_css(".ic-DashboardCard__action-container .discussions")
    end
  end

  def select_color_palette_from_calendar_page
    get '/calendar'
    fail 'Not the right course' unless f('#context-list li:nth-of-type(2)').text.include? @course1.name
    f('#context-list li:nth-of-type(2) .ContextList__MoreBtn').click
    wait_for_ajaximations
    expect(f('.ColorPicker__Container')).to be_displayed
  end
end
