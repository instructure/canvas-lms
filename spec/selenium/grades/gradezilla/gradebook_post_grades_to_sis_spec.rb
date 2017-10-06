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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_page'
require_relative '../setup/gradebook_setup'

describe "Gradezilla - post grades to SIS" do
  include GradezillaCommon
  include GradebookSetup
  include_context "in-process server selenium tests"

  before(:once) do
    gradebook_data_setup
    create_sis_assignment
    show_sections_filter(@teacher)
  end

  before(:each) do
    Account.default.set_feature_flag!('new_gradebook', 'on')
    user_session(@teacher)
  end

  after(:each) do
    clear_local_storage
  end

  def create_sis_assignment
    @assignment.post_to_sis = true
    @assignment.workflow_state = 'published'
    @assignment.save
  end

  def export_plugin_setting
    plugin = Canvas::Plugin.find('grade_export')
    plugin_setting = PluginSetting.find_by(name: plugin.id)
    plugin_setting || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
  end

  describe "Plugin" do
    before(:once) { export_plugin_setting.update(disabled: false) }

    it "should not be visible by default", priority: "1", test_id: 244958 do
      Gradezilla.visit(@course)
      Gradezilla.open_action_menu

      expect(f('body')).not_to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it "should be visible when enabled on course with sis_source_id" do
      Account.default.set_feature_flag!('post_grades', 'on')
      @course.sis_source_id = 'xyz'
      @course.save

      Gradezilla.visit(@course)
      Gradezilla.open_action_menu

      expect(f('body')).to contain_css("[data-menu-id='post_grades_feature_tool']")
    end

    it 'does not show assignment errors when clicking the post grades button if all ' \
      'assignments have due dates for each section', priority: '1', test_id: 3036003 do
      Account.default.set_feature_flag!('post_grades', 'on')

      @course.update!(sis_source_id: 'xyz')
      @course.course_sections.each do |section|
        @attendance_assignment.assignment_overrides.create! do |override|
          override.set = section
          override.title = 'section override'
          override.due_at = Time.zone.now
          override.due_at_overridden = true
        end
      end
      Gradezilla.visit(@course)
      Gradezilla.open_action_menu
      Gradezilla.action_menu_item_selector('post_grades_feature_tool').click

      expect(f('.post-grades-dialog')).not_to contain_css('#assignment-errors')
    end
  end

  describe 'LTI' do
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

    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "should show when a post_grades lti tool is installed", priority: "1", test_id: 244960 do
      Gradezilla.visit(@course)
      Gradezilla.open_action_menu

      expect(Gradezilla.action_menu_item_selector(tool_name)).to be_displayed

      Gradezilla.action_menu_item_selector(tool_name).click

      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should show post grades lti button when only one section available" do
      course = Course.new(name: 'Math 201', account: @account, sis_source_id: 'xyz')
      course.save
      course.enroll_teacher(@user).accept!
      course.assignments.create!(name: 'Assignment1', post_to_sis: true)
      create_post_grades_tool(course: course)

      Gradezilla.visit(@course)
      Gradezilla.open_action_menu

      expect(Gradezilla.action_menu_item_selector(tool_name)).to be_displayed

      Gradezilla.action_menu_item_selector(tool_name).click

      expect(f('iframe.post-grades-frame')).to be_displayed
    end

    it "should not hide post grades lti button when section selected", priority: "1", test_id: 248027 do
      create_post_grades_tool

      Gradezilla.visit(@course)
      Gradezilla.open_action_menu

      expect(Gradezilla.action_menu_item_selector(tool_name)).to be_displayed

      switch_to_section('the other section')
      Gradezilla.open_action_menu

      expect(Gradezilla.action_menu_item_selector(tool_name)).to be_displayed
    end
  end
end
