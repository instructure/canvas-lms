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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe 'Global Navigation' do
  include_context 'in-process server selenium tests'

  context 'As a Teacher' do
    before do
      course_with_teacher_logged_in
    end

    describe 'Profile Link' do
      it 'should show the profile tray upon clicking' do
        get "/"
        f('#global_nav_profile_link').click
        expect(f('[aria-label="Profile tray"] [aria-label="User profile picture"]')).to be_displayed
      end

      # Profile links are hardcoded, so check that something is appearing for
      # the display_name in the tray header
      it 'should populate the profile tray with the current user display_name' do
        get "/"
        expect(displayed_username).to eq(@user.name)
      end
    end

    describe 'Courses Link' do
      it 'should show the courses tray upon clicking' do
        get "/"
        f('#global_nav_courses_link').click
        wait_for_ajaximations
        expect(f("[aria-label='Courses tray']")).to be_displayed
      end

      it 'should populate the courses tray when using the keyboard to open it' do
        get "/"
        driver.execute_script('$("#global_nav_courses_link").focus()')
        f('#global_nav_courses_link').send_keys(:enter)
        wait_for_ajaximations
        links = ff('[aria-label="Courses tray"] li a')
        expect(links.count).to eql 2
      end
    end

    describe 'Groups Link' do
      it 'filters concluded groups and loads additional pages if necessary' do
        Setting.set('api_per_page', 2)

        student = user_factory
        2.times do |x|
          course = course_with_student(:user => student, :active_all => true).course
          group_with_user(:user => student, :group_context => course, :name => "A Old Group #{x}")
          course.complete!
        end

        course = course_with_student(:user => student, :active_all => true).course
        group_with_user(:user => student, :group_context => course, :name => "Z Current Group")

        user_session(student)
        get "/"
        f('#global_nav_groups_link').click
        wait_for_ajaximations
        links = ff('[aria-label="Groups tray"] li a')
        expect(links.map(&:text)).to eq(['Z Current Group', 'All Groups'])
      end
    end

    describe 'LTI Tools' do
      it 'should show a custom logo/link for LTI tools' do
        Account.default.enable_feature! :lor_for_account
        @teacher.enable_feature! :lor_for_user
        @tool = Account.default.context_external_tools.new({
          :name => "Commons",
          :domain => "canvaslms.com",
          :consumer_key => '12345',
          :shared_secret => 'secret'
        })
        @tool.set_extension_setting(:global_navigation, {
          :url => "canvaslms.com",
          :visibility => "admins",
          :display_type => "full_width",
          :text => "Commons",
          :icon_svg_path_64 => 'M100,37L70.1,10.5v17.6H38.6c-4.9,0-8.8,3.9-8.8,8.8s3.9,8.8,8.8,8.8h31.5v17.6L100,37z'
        })
        @tool.save!
        get "/"
        expect(f('.ic-icon-svg--lti')).to be_displayed
      end
    end
    describe 'Navigation Expand/Collapse Link' do
      it 'should collapse and expand the navigation when clicked' do
        get "/"
        f('#primaryNavToggle').click
        wait_for_ajaximations
        expect(f('body')).not_to have_class("primary-nav-expanded")
        f('#primaryNavToggle').click
        wait_for_ajaximations
        expect(f('body')).to have_class("primary-nav-expanded")
      end
    end
  end
end
