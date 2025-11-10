# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

RSpec.describe Mutations::UpdateWidgetDashboardConfig do
  before(:once) do
    student_in_course(active_all: true)
  end

  def mutation_str(config:)
    <<~GQL
      mutation {
        updateWidgetDashboardConfig(input: {
          config: #{config.to_json.to_json}
        }) {
          config
          errors {
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it "updates the widget dashboard config preference" do
    config = { "columns" => 2, "widgets" => [] }
    result = run_mutation(config:)
    expect(result.dig("data", "updateWidgetDashboardConfig", "config")).to eq(config.to_json)
    expect(@student.get_preference(:widget_dashboard_config)).to eq(config)
  end

  it "stores a complete widget configuration" do
    config = {
      "columns" => 2,
      "widgets" => [
        {
          "id" => "course-work-widget",
          "type" => "course_work",
          "position" => { "col" => 1, "row" => 1, "relative" => 1 },
          "title" => "Course work"
        }
      ]
    }
    result = run_mutation(config:)
    expect(result.dig("data", "updateWidgetDashboardConfig", "config")).to eq(config.to_json)
    @student.reload
    expect(@student.get_preference(:widget_dashboard_config)).to eq(config)
  end

  it "persists the preference across requests" do
    config = { "columns" => 3, "widgets" => [] }
    run_mutation(config:)
    @student.reload
    expect(@student.get_preference(:widget_dashboard_config)).to eq(config)
  end

  it "updates an existing preference" do
    old_config = { "columns" => 1, "widgets" => [] }
    @student.set_preference(:widget_dashboard_config, old_config)

    new_config = { "columns" => 2, "widgets" => [] }
    result = run_mutation(config: new_config)
    expect(result.dig("data", "updateWidgetDashboardConfig", "config")).to eq(new_config.to_json)
    @student.reload
    expect(@student.get_preference(:widget_dashboard_config)).to eq(new_config)
  end

  it "clears the preference when given an empty string" do
    old_config = { "columns" => 2, "widgets" => [] }
    @student.set_preference(:widget_dashboard_config, old_config)

    result = run_mutation(config: "")
    expect(result.dig("data", "updateWidgetDashboardConfig", "config")).to be_nil
    @student.reload
    expect(@student.get_preference(:widget_dashboard_config)).to be_nil
  end

  it "returns an error for invalid JSON" do
    result = CanvasSchema.execute(
      <<~GQL,
        mutation {
          updateWidgetDashboardConfig(input: {
            config: "not valid json"
          }) {
            config
            errors {
              message
            }
          }
        }
      GQL
      context: {
        current_user: @student,
        request: ActionDispatch::TestRequest.create
      }
    )
    result = result.to_h.with_indifferent_access
    expect(result.dig("data", "updateWidgetDashboardConfig", "errors")).not_to be_empty
  end
end
