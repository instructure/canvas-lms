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
require_relative '../common'
require_relative '../../spec_helper'
require_relative 'page_objects/assignments_index_page'

describe 'assignments index menu tool placement' do
  include_context 'in-process server selenium tests'
  include AssignmentsIndexPage

  before do
    course_with_teacher_logged_in

    @tool1 = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
    # tool1 is on index and group menus
    @tool1.assignment_index_menu = {:url => "http://www.example.com", :text => "Import Stuff"}
    @tool1.assignment_group_menu = {:url => "http://www.example.com", :text => "Import Stuff Here"}
    @tool1.save!
    @tool2 = Account.default.context_external_tools.new(:name => "b", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
    # tool2 is on assignment menu
    @tool2.assignment_menu = {:url => "http://www.example.com", :text => "Second Tool"}
    @tool2.save!
    # assignments groups
    @agroup1 = @course.assignment_groups.create!(:name => "assignments group1")
    @course.assignments.create(name: "test assignment", assignment_group: @agroup1)
    @assignment1 = @course.assignments.first
    @agroup2 = @course.assignment_groups.create!(:name => "assignments group2")

    Account.default.enable_feature!(:commons_favorites)
    Account.default.enable_feature!(:direct_share)
  end

  it "should be able to launch the index menu tool via the tray", custom_timeout: 60 do
    get "/courses/#{@course.id}/assignments"

    gear = f("#course_assignment_settings_link")
    gear.click
    tool_link = ff("#settingsMountPoint li.ui-menu-item a").last
    expect(tool_link).to include_text("Import Stuff")

    tool_link.click
    wait_for_ajaximations
    tray = f("[role='dialog']")
    expect(tray['aria-label']).to eq "Import Stuff"
    iframe = tray.find_element(:css, "iframe")
    expect(iframe['src']).to include("/courses/#{@course.id}/external_tools/#{@tool1.id}")
    query_params = Rack::Utils.parse_nested_query(URI.parse(iframe['src']).query)
    expect(query_params["launch_type"]).to eq "assignment_index_menu"
    expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "true"
    expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "assignment"
    expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["assignment"]
    expect(query_params["com_instructure_course_available_canvas_resources"].values).to eq [
      {"course_id" => @course.id.to_s, "type" => "assignment_group"}] # will replace with the groups on the variable expansion
  end

  it "should be able to launch the group menu tool via the tray", custom_timeout: 60 do
    get "/courses/#{@course.id}/assignments"

    gear = f("#ag_#{@agroup2.id}_manage_link")
    gear.click
    tool_link = f("#assignment_group_#{@agroup2.id} li.ui-menu-item a.menu_tool_link")
    expect(tool_link).to include_text("Import Stuff Here")

    tool_link.click
    wait_for_ajaximations
    tray = f("[role='dialog']")
    expect(tray['aria-label']).to eq "Import Stuff Here"
    iframe = tray.find_element(:css, "iframe")
    expect(iframe['src']).to include("/courses/#{@course.id}/external_tools/#{@tool1.id}")
    query_params = Rack::Utils.parse_nested_query(URI.parse(iframe['src']).query)
    expect(query_params["launch_type"]).to eq "assignment_group_menu"
    expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
    expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "assignment"
    expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["assignment"]
    group_data = [@agroup2].map{|ag| {"id" => ag.id.to_s, "name" => ag.name}} # just the selected group
    expect(query_params["com_instructure_course_available_canvas_resources"].values).to match_array(group_data)
  end

  it "should handle having more than one tool in the menu" do
    user_session(@teacher)
    visit_assignments_index_page(@course.id)

    expect(assignment_row(@assignment1.id).text).not_to include 'Second Tool'

    manage_assignment_menu(@assignment1.id).click
    expect(assignment_settings_menu(@assignment1.id).text).to include 'Second Tool'
  end
end
