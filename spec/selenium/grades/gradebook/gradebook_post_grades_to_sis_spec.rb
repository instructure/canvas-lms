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

require_relative '../../helpers/gradebook_common'
require_relative '../../../feature_flag_helper'

describe "gradebook - post grades to SIS" do
  include GradebookCommon
  include_context "in-process server selenium tests"
  include FeatureFlagHelper

  before(:once) do
    gradebook_data_setup
    create_sis_assignment
  end

  before(:each) do
    user_session(@teacher)
  end

  after(:each) do
    clear_local_storage
  end

  def create_sis_assignment
    @assignment.post_to_sis = true
    @assignment.save
  end

  it "should not be visible by default", priority: "1", test_id: 244958 do
    get "/courses/#{@course.id}/gradebook"
    expect(f("body")).not_to contain_css('.post-grades-placeholder')
  end

  it "should be visible when enabled on course with sis_source_id" do
    mock_feature_flag(:post_grades, true)
    @course.sis_source_id = 'xyz'
    @course.save
    get "/courses/#{@course.id}/gradebook"
    expect(ff('.post-grades-placeholder')).to have_size 1
  end

  it "should not be displayed if viewing outcome gradebook", priority: "1", test_id: 244959 do
    mock_feature_flag(:post_grades, true)
    Account.default.set_feature_flag!('outcome_gradebook', 'on')
    @course.sis_source_id = 'xyz'
    @course.save

    get "/courses/#{@course.id}/gradebook"

    f('a[data-id=outcome]').click
    expect(f('.post-grades-placeholder')).not_to be_displayed

    f('a[data-id=assignment]').click
    expect(f('.post-grades-placeholder')).to be_displayed
  end

  it "should display post grades button when powerschool is configured", priority: "1", test_id: 164219 do
    mock_feature_flag(:post_grades, true)
    @course.sis_source_id = 'xyz'
    @course.save
    get "/courses/#{@course.id}/gradebook"
    expect(f('.post-grades-placeholder > button')).to be_displayed
    f('.post-grades-placeholder > button').click
    expect(f('.post-grades-dialog')).to be_displayed
  end

  it 'does not show assignment errors when clicking the post grades button if all ' \
    'assignments have due dates for each section', priority: '1', test_id: 3036003 do
    mock_feature_flag(:post_grades, true)
    @course.update!(sis_source_id: 'xyz')
    @course.course_sections.each do |section|
      @attendance_assignment.assignment_overrides.create! do |override|
        override.set = section
        override.title = 'section override'
        override.due_at = Time.zone.now
        override.due_at_overridden = true
      end
    end
    get "/courses/#{@course.id}/gradebook"
    f('.post-grades-placeholder > button').click
    expect(f('.post-grades-dialog')).not_to contain_css('#assignment-errors')
  end

  context 'post grades button' do
    def create_post_grades_tool(opts={})
      course = opts[:course] || @course
      post_grades_tool = course.context_external_tools.create!(
        name: opts[:name] || 'test tool',
        domain: 'example.com',
        url: 'http://example.com/lti',
        consumer_key: 'key',
        shared_secret: 'secret',
        settings: {
          post_grades: {
            url: 'http://example.com/lti/post_grades'
          }
        }
      )
      post_grades_tool
    end

    it "should show when a post_grades lti tool is installed", priority: "1", test_id: 244960 do
      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook"
      expect(f('button.external-tools-dialog')).to be_displayed
      f('button.external-tools-dialog').click
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show post grades lti button when only one section available" do
      course = Course.new(name: 'Math 201', account: @account, sis_source_id: 'xyz')
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: 'Assignment1', post_to_sis: true)
      create_post_grades_tool(course: course)

      get "/courses/#{course.id}/gradebook"
      expect(f('button.external-tools-dialog')).to be_displayed

      # Click with javascript to avoid some page load errors in chrome
      driver.execute_script("$('button.external-tools-dialog').click()")
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti button when section selected", priority: "1", test_id: 248027 do
      create_post_grades_tool

      get "/courses/#{@course.id}/gradebook"
      expect(f('button.external-tools-dialog')).to be_displayed

      f('button.section-select-button').click
      fj('ul#section-to-show-menu li:nth(4)').click
      expect(f('button.external-tools-dialog')).to be_displayed
    end

    it "should show as drop down menu when multiple tools are installed", priority: "1", test_id: 244920 do
      (0...10).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(10)
      expect(f('#post_grades .icon-mini-arrow-down')).to be_displayed
      move_to_click('button#post_grades')
      f('li.external-tools-dialog > a').click
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti dropdown when section selected", priority: "1", test_id: 248027 do
      (0...10).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(10)

      f('button.section-select-button').click
      fj('ul#section-to-show-menu li:nth(4)').click
      expect(f('button#post_grades')).to be_displayed
    end

    it "should show as drop down menu with max number of items when too many " \
      "tools are installed", priority: "1", test_id: 244961 do
      (0...11).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(10)
    end
  end

  context "when new_sis_integrations is enabled" do
    before(:each) do
      Account.default.set_feature_flag!('new_sis_integrations', 'on')
    end

    def create_post_grades_tool(opts={})
      course = opts[:course] || @course
      post_grades_tool = course.context_external_tools.create!(
        name: opts[:name] || 'test tool',
        domain: 'example.com',
        url: 'http://example.com/lti',
        consumer_key: 'key',
        shared_secret: 'secret',
        settings: {
          post_grades: {
            url: 'http://example.com/lti/post_grades'
          }
        }
      )
      post_grades_tool
    end

    def element_present
      f('li.post-grades-placeholder > a').displayed?
      rescue Selenium::WebDriver::Error::NoSuchElementError
        false
    end

    it "should show post grades tools in exports dropdown" do
      (0...10).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(10)
      move_to_click('button#download_csv')
      f('li.external-tools-dialog > a').click
      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show max number of items when too many tools are installed" do
      (0...11).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(10)
    end

    it "should not include the powerschool option in max number of items " \
      "in exports dropdown" do
      (0...11).each do |i|
        create_post_grades_tool(name: "test tool #{i}")
      end

      mock_feature_flag(:post_grades, true)
      @course.sis_source_id = 'xyz'
      @course.save
      @assignment.post_to_sis = true
      @assignment.save

      get "/courses/#{@course.id}/gradebook"
      expect(ff('li.external-tools-dialog')).to have_size(9)
      expect(element_present).to be_falsey
    end

    it "should show powerschool option in exports dropdown" do
      mock_feature_flag(:post_grades, true)
      @course.sis_source_id = 'xyz'
      @course.save
      @assignment.post_to_sis = true
      @assignment.save

      get "/courses/#{@course.id}/gradebook"
      expect(f('li.post-grades-placeholder > a')).to be_present

      move_to_click('button#download_csv')
      f('li.post-grades-placeholder > a').click
      expect(f('.post-grades-dialog')).to be_displayed
    end
  end
end
