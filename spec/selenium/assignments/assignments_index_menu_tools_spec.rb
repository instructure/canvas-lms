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

describe 'assignments index menu tool placement' do
  include_context 'in-process server selenium tests'

  before do
    course_with_teacher_logged_in

    @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool.assignment_index_menu = {:url => "http://www.example.com", :text => "Import Stuff"}
    @tool.save!
    @agroup1 = @course.assignment_groups.create!(:name => "assignments group1")
    @agroup2 = @course.assignment_groups.create!(:name => "assignments group2")

    Account.default.enable_feature!(:commons_favorites)
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
    expect(iframe['src']).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")
    query_params = Rack::Utils.parse_nested_query(URI.parse(iframe['src']).query)
    expect(query_params["launch_type"]).to eq "assignment_index_menu"
    expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "true"
    expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "assignment"
    expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["assignment"]
    group_data = [@agroup1, @agroup2].map{|ag| {"id" => ag.id.to_s, "name" => ag.name}}
    expect(query_params["com_instructure_course_available_canvas_resources"].values).to match_array(group_data)
  end
end
