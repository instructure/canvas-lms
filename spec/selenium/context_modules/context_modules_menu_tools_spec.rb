# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../helpers/context_modules_common'
require_relative 'page_objects/modules_index_page'

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage

  context "module index tool placement" do
    before do
      course_with_teacher_logged_in

      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.module_index_menu = {:url => "http://www.example.com", :text => "Import Stuff"}
      @tool.module_group_menu = {:url => "http://www.example.com", :text => "Import Stuff Here"}
      @tool.save!
      @module1 = @course.context_modules.create!(:name => "module1")
      @module2 = @course.context_modules.create!(:name => "module2")

      Account.default.enable_feature!(:commons_favorites)
    end

    it "should be able to launch the index menu tool via the tray", custom_timeout: 30 do
      visit_modules_index_page(@course.id)
      modules_index_settings_button.click
      expect(module_index_settings_menu).to include_text("Import Stuff")

      module_index_menu_tool_link("Import Stuff").click
      wait_for_ajaximations
      expect(tool_dialog_header).to include_text("Import Stuff")
      expect(tool_dialog_iframe['src']).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")
      
      query_params = Rack::Utils.parse_nested_query(URI.parse(tool_dialog_iframe['src']).query)
      expect(query_params["launch_type"]).to eq "module_index_menu"
      expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "true"
      expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "module"
      expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to match_array([
        "assignment", "audio", "discussion_topic", "document", "image", "module", "quiz", "page", "video"
      ])
      expect(query_params["com_instructure_course_available_canvas_resources"].values).to eq [{
        "course_id" => @course.id.to_s, "type" => "module"
        }] # will replace with the modules on the variable expansion
    end

    it "should be able to launch the individual module menu tool via the tray", custom_timeout: 60 do
      visit_modules_index_page(@course.id)
      manage_module_button(@module2).click
      expect(module_settings_menu(@module2.id)).to include_text("Import Stuff Here")

      module_index_menu_tool_link("Import Stuff Here").click
      wait_for_ajaximations
      expect(tool_dialog_header).to include_text("Import Stuff Here")
      
      expect(tool_dialog_iframe['src']).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")
      
      query_params = Rack::Utils.parse_nested_query(URI.parse(tool_dialog_iframe['src']).query)
      expect(query_params["launch_type"]).to eq "module_group_menu"
      expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
      expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "module"
      expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to match_array([
        "assignment", "audio", "discussion_topic", "document", "image", "module", "quiz", "page", "video"
      ])
      module_data = [@module2].map{|m| {"id" => m.id.to_s, "name" => m.name}} # just @module2
      expect(query_params["com_instructure_course_available_canvas_resources"].values).to match_array(module_data)
    end
  end
end