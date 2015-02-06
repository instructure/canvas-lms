#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "courses/_settings_sidebar.html.erb" do
  before do
    course_with_teacher(:active_all => true)
    @course.sis_source_id = "so_special_sis_id"
    @course.workflow_state = 'claimed'
    @course.save!
    assigns[:context] = @course
    assigns[:user_counts] = {}
    assigns[:all_roles] = Role.custom_roles_and_counts_for_course(@course, @user)
    assigns[:course_settings_sub_navigation_tools] = []
  end

  describe "End this course button" do
    it "should not display if the course or term end date has passed" do
      @course.stubs(:soft_concluded?).returns(true)
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      expect(response.body).not_to match(/Conclude this Course/)
    end

    it "should display if the course and its term haven't ended" do
      @course.stubs(:soft_concluded?).returns(false)
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      expect(response.body).to match(/Conclude this Course/)
    end
  end

  describe "Reset course content" do
    it "should not display the dialog contents under the button" do
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.at_css('#reset_course_content_dialog')['style']).to eq 'display:none;'
    end
  end

  describe "course settings sub navigation external tools" do
    def create_course_settings_sub_navigation_tool(options = {})
        @course.root_account.enable_feature!(:lor_for_account)
        defaults = {
          name: options[:name] || "external tool",
          consumer_key: 'test',
          shared_secret: 'asdf',
          url: 'http://example.com/ims/lti',
          course_settings_sub_navigation: { icon_url: '/images/delete.png' },
        }
        @course.context_external_tools.create!(defaults.merge(options))
    end

    before do
      view_context(@course, @user)
      assigns[:current_user] = @user
    end

    it "should display all configured tools" do
      num_tools = 3
      (1..num_tools).each do |n|
        create_course_settings_sub_navigation_tool(name: "tool #{n}")
      end
      assigns[:course_settings_sub_navigation_tools] = @course.context_external_tools.to_a
      render
      doc = Nokogiri::HTML.parse(response.body)
      expect(doc.css('.course-settings-sub-navigation-lti').size).to eq num_tools
    end

    it "should include the launch type parameter" do
      create_course_settings_sub_navigation_tool
      assigns[:course_settings_sub_navigation_tools] = @course.context_external_tools.to_a
      render
      doc = Nokogiri::HTML.parse(response.body)
      tool_link = doc.at_css('.course-settings-sub-navigation-lti')
      expect(tool_link['href']).to include("launch_type=course_settings_sub_navigation")
    end
  end

end
