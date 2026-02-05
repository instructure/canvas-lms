# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../spec_helper"

RSpec.describe Lti::LtiAppsController, type: :controller do
  describe "GET #launch_definitions" do
    let(:course) { course_model }
    let(:teacher) { user_model }

    before do
      course.enroll_teacher(teacher, enrollment_state: "active")
      user_session(teacher)
    end

    context "when new quizzes feature is enabled" do
      let!(:quiz_tool) do
        course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch",
          course_navigation: {
            enabled: true,
            text: "Quizzes"
          }
        )
      end
      let!(:regular_tool) do
        course.context_external_tools.create!(
          name: "Regular Tool",
          consumer_key: "key",
          shared_secret: "secret",
          tool_id: "regular_tool",
          url: "http://regular.example.com/launch",
          course_navigation: {
            enabled: true,
            text: "Regular Tool"
          }
        )
      end

      before do
        course.root_account.settings[:provision] = { "lti" => "lti url" }
        course.root_account.save!
        course.enable_feature!(:quizzes_next)
        course.root_account.enable_feature!(:quizzes_next)
      end

      it "includes Quizzes 2 tool in launch definitions" do
        get :launch_definitions, params: {
          course_id: course.id,
          placements: ["course_navigation"],
          format: :json
        }

        expect(response).to be_successful
        json = json_parse(response.body)
        tool_ids = json.map { |tool| tool["definition_id"] }

        expect(tool_ids).to include(quiz_tool.id)
        expect(tool_ids).to include(regular_tool.id)
      end
    end

    context "when new quizzes feature is disabled" do
      let!(:quiz_tool) do
        course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch",
          course_navigation: {
            enabled: true,
            text: "Quizzes"
          }
        )
      end
      let!(:regular_tool) do
        course.context_external_tools.create!(
          name: "Regular Tool",
          consumer_key: "key",
          shared_secret: "secret",
          tool_id: "regular_tool",
          url: "http://regular.example.com/launch",
          course_navigation: {
            enabled: true,
            text: "Regular Tool"
          }
        )
      end

      before do
        course.disable_feature!(:quizzes_next) if course.feature_enabled?(:quizzes_next)
      end

      it "filters out Quizzes 2 tool from launch definitions" do
        get :launch_definitions, params: {
          course_id: course.id,
          placements: ["course_navigation"],
          format: :json
        }

        expect(response).to be_successful
        json = json_parse(response.body)
        tool_ids = json.map { |tool| tool["definition_id"] }

        expect(tool_ids).not_to include(quiz_tool.id)
        expect(tool_ids).to include(regular_tool.id)
      end

      it "only filters tools with tool_id 'Quizzes 2'" do
        # Create another tool that's not Quizzes 2
        other_tool = course.context_external_tools.create!(
          name: "Another Tool",
          consumer_key: "key2",
          shared_secret: "secret2",
          tool_id: "other_tool",
          url: "http://other.example.com/launch",
          course_navigation: {
            enabled: true,
            text: "Another Tool"
          }
        )

        get :launch_definitions, params: {
          course_id: course.id,
          placements: ["course_navigation"],
          format: :json
        }

        expect(response).to be_successful
        json = json_parse(response.body)
        tool_ids = json.map { |tool| tool["definition_id"] }

        expect(tool_ids).not_to include(quiz_tool.id)
        expect(tool_ids).to include(regular_tool.id)
        expect(tool_ids).to include(other_tool.id)
      end
    end
  end
end
