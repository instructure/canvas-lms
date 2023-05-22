# frozen_string_literal: true

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
require_relative "../common"
require_relative "../../spec_helper"
require_relative "page_objects/quizzes_index_page"

describe "quiz index menu tool placement" do
  include_context "in-process server selenium tests"
  include QuizzesIndexPage

  before do
    course_with_teacher_logged_in

    @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
    @tool.quiz_index_menu = { url: "http://www.example.com", text: "Import Stuff" }
    @tool.save!
  end

  it "is able to launch the index menu tool via the tray", custom_timeout: 60 do
    visit_quizzes_index_page(@course.id)
    quiz_index_settings_button.click
    expect(quiz_index_settings_menu_items).to include_text("Import Stuff")

    quiz_index_settings_menu_tool_link("Import Stuff").click
    wait_for_ajaximations
    expect(tool_dialog_header.text).to eq "Import Stuff"

    expect(tool_dialog_iframe["src"]).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")
    query_params = Rack::Utils.parse_nested_query(URI.parse(tool_dialog_iframe["src"]).query)
    expect(query_params["launch_type"]).to eq "quiz_index_menu"
    expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
    expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "quiz"
    expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["quiz"]
    expect(query_params["com_instructure_course_available_canvas_resources"]).to be_blank
  end
end
