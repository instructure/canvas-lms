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
        expect(f('#global_nav_profile_header')).to be_displayed
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
        expect(f('.ic-NavMenu__primary-content')).to be_displayed
      end

      it 'should populate the courses tray when using the keyboard to open it' do
        get "/"
        driver.execute_script('$("#global_nav_courses_link").focus()')
        f('#global_nav_courses_link').send_keys(:enter)
        wait_for_ajaximations
        links = ff('.ic-NavMenu__link-list li')
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
        links = ff('.ic-NavMenu__link-list li')
        expect(links.map(&:text)).to eq(['Z Current Group', 'All Groups'])
      end
    end

    describe 'LTI Tools' do
      let(:account) { Account.default }
      let(:external_tool) do
        ContextExternalTool.new(
          name: 'test_name',
          consumer_key: 'test_key',
          shared_secret: 'bob',
          domain: 'example.com',
          workflow_state: 'public',
          global_navigation: {url: 'http://www.example.com', text: 'Example URL'}
        )
      end

      it 'should include tools for current account' do
        @teacher.enable_feature! :lor_for_user
        external_tool.update_attributes!(context: account)
        get "/"
        expect(f("#context_external_tool_#{external_tool.id}_menu_item")).to be_displayed
      end

      it 'should include tools for all accounts in the account chain' do
        sub_account = Account.create!(parent_account: account, name: 'sub_account')
        @teacher.enable_feature! :lor_for_user
        sub_account.users << @teacher
        sub_account.save!
        tool_two = external_tool.dup
        tool_two.update_attributes!(context: sub_account)
        external_tool.update_attributes!(context: account)
        get "/accounts/#{sub_account.id}"
        expect(f("#context_external_tool_#{external_tool.id}_menu_item")).to be_displayed
        expect(f("#context_external_tool_#{tool_two.id}_menu_item")).to be_displayed
      end

      it 'should not include tools intalled in sub-accounts' do
        @teacher.enable_feature! :lor_for_user
        sub_account = Account.create!(parent_account: account, name: 'sub_account')
        tool_two = external_tool.dup
        tool_two.update_attributes!(context: sub_account)
        external_tool.update_attributes!(context: account)
        get "/"
        expect(f("#context_external_tool_#{external_tool.id}_menu_item")).to be_displayed
        expect { f("#context_external_tool_#{tool_two.id}_menu_item") }.to raise_error Selenium::WebDriver::Error::NoSuchElementError
      end

      it "should only return tools with the 'global_navigation' setting" do
        @teacher.enable_feature! :lor_for_user
        external_tool.update_attributes!(
          context: account,
          global_navigation: nil
        )
        get "/"
        expect { f("#context_external_tool_#{external_tool.id}_menu_item") }.to raise_error Selenium::WebDriver::Error::NoSuchElementError
      end

      it "should show tools when not in an account or course context" do
        @teacher.enable_feature! :lor_for_user
        sub_account = Account.create!(parent_account: account, name: 'sub_account')
        sub_account.users << @teacher
        sub_account.save!
        tool_two = external_tool.dup
        tool_two.update_attributes!(context: sub_account)
        external_tool.update_attributes!(context: account)
        get '/profile/settings'
        expect(f("#context_external_tool_#{external_tool.id}_menu_item")).to be_displayed
        expect(f("#context_external_tool_#{tool_two.id}_menu_item")).to be_displayed
      end

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
