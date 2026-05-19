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

RSpec.describe Mutations::UpdateWidgetDashboardLayout do
  before(:once) do
    student_in_course(active_all: true)
  end

  def mutation_str
    <<~GQL
      mutation UpdateWidgetDashboardLayout($layout: String!) {
        updateWidgetDashboardLayout(input: {
          layout: $layout
        }) {
          layout
          errors {
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str,
      variables: opts,
      context: {
        current_user:,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  let(:valid_layout) do
    {
      "columns" => 2,
      "widgets" => [
        {
          "id" => "widget-1",
          "type" => "course_work",
          "position" => { "col" => 1, "row" => 1, "relative" => 1 },
          "title" => "Course Work"
        },
        {
          "id" => "widget-2",
          "type" => "announcements",
          "position" => { "col" => 2, "row" => 1, "relative" => 2 },
          "title" => "Announcements"
        }
      ]
    }
  end

  it "saves valid widget layout" do
    result = run_mutation(layout: valid_layout.to_json)

    expect(result["errors"]).to be_nil, "GraphQL errors: #{result["errors"].inspect}"
    expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to eq(valid_layout.to_json)

    config = @student.get_preference(:widget_dashboard_config)
    expect(config["layout"]).to eq(valid_layout)
  end

  it "persists the layout across requests" do
    run_mutation(layout: valid_layout.to_json)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["layout"]).to eq(valid_layout)
  end

  it "updates an existing layout" do
    initial_layout = {
      "columns" => 1,
      "widgets" => [
        {
          "id" => "widget-1",
          "type" => "course_work",
          "position" => { "col" => 1, "row" => 1, "relative" => 1 },
          "title" => "Course Work"
        }
      ]
    }
    @student.set_preference(:widget_dashboard_config, { "layout" => initial_layout })

    run_mutation(layout: valid_layout.to_json)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["layout"]).to eq(valid_layout)
  end

  it "preserves filter config when updating layout" do
    filters = { "filters" => { "course-work-widget" => { "selectedCourse" => "all" } } }
    @student.set_preference(:widget_dashboard_config, filters)

    run_mutation(layout: valid_layout.to_json)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["layout"]).to eq(valid_layout)
    expect(config["filters"]).to eq(filters["filters"])
  end

  it "accepts empty widgets array" do
    layout = { "columns" => 2, "widgets" => [] }
    result = run_mutation(layout: layout.to_json)

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to eq(layout.to_json)
  end

  it "rejects invalid JSON" do
    result = run_mutation(layout: "not valid json {")

    expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
    errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to include("Invalid JSON format")
  end

  it "rejects layout without columns field" do
    layout = { "widgets" => [] }
    result = run_mutation(layout: layout.to_json)

    expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
    errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to include("Layout configuration must include 'columns' field")
  end

  it "rejects layout without widgets field" do
    layout = { "columns" => 2 }
    result = run_mutation(layout: layout.to_json)

    expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
    errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
    expect(errors).not_to be_nil
    expect(errors[0]["message"]).to include("Layout configuration must include 'widgets' field")
  end

  context "column validation" do
    it "rejects non-integer columns" do
      layout = valid_layout.merge("columns" => "2")
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("'columns' must be an integer")
    end

    it "rejects zero columns" do
      layout = valid_layout.merge("columns" => 0)
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("'columns' must be a positive integer")
    end

    it "rejects negative columns" do
      layout = valid_layout.merge("columns" => -1)
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("'columns' must be a positive integer")
    end
  end

  context "widget validation" do
    it "rejects widget without id" do
      widget = valid_layout["widgets"][0].except("id")
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Widget at index 0 must have 'id' field")
    end

    it "rejects widget without type" do
      widget = valid_layout["widgets"][0].except("type")
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Widget at index 0 must have 'type' field")
    end

    it "rejects widget without position" do
      widget = valid_layout["widgets"][0].except("position")
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Widget at index 0 must have 'position' field")
    end

    it "rejects widget without title" do
      widget = valid_layout["widgets"][0].except("title")
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Widget at index 0 must have 'title' field")
    end
  end

  context "position validation" do
    it "rejects position without col field" do
      position = valid_layout["widgets"][0]["position"].except("col")
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Position for widget at index 0 must have 'col' field")
    end

    it "rejects position without row field" do
      position = valid_layout["widgets"][0]["position"].except("row")
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Position for widget at index 0 must have 'row' field")
    end

    it "rejects position without relative field" do
      position = valid_layout["widgets"][0]["position"].except("relative")
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Position for widget at index 0 must have 'relative' field")
    end

    it "rejects non-integer position values" do
      position = valid_layout["widgets"][0]["position"].merge("col" => "1")
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Position 'col' for widget at index 0 must be an integer")
    end

    it "rejects zero or negative position values" do
      position = valid_layout["widgets"][0]["position"].merge("col" => 0)
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Position 'col' for widget at index 0 must be a positive integer")
    end
  end

  context "column bounds validation" do
    it "rejects widget with col exceeding configured columns" do
      position = valid_layout["widgets"][0]["position"].merge("col" => 3)
      widget = valid_layout["widgets"][0].merge("position" => position)
      layout = valid_layout.merge("widgets" => [widget])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Widget at index 0 has column 3 which exceeds configured columns 2")
    end

    it "accepts widget with col equal to configured columns" do
      layout = valid_layout.dup
      layout["columns"] = 3
      position = layout["widgets"][0]["position"].merge("col" => 3)
      layout["widgets"][0]["position"] = position
      result = run_mutation(layout: layout.to_json)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to eq(layout.to_json)
    end
  end

  context "duplicate position validation" do
    it "rejects multiple widgets at the same position" do
      widget1 = valid_layout["widgets"][0]
      widget2 = valid_layout["widgets"][1].merge(
        "id" => "widget-3",
        "position" => { "col" => 1, "row" => 1, "relative" => 2 }
      )
      layout = valid_layout.merge("widgets" => [widget1, widget2])
      result = run_mutation(layout: layout.to_json)

      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to be_nil
      errors = result.dig("data", "updateWidgetDashboardLayout", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to include("Multiple widgets at position (col: 1, row: 1)")
    end

    it "accepts widgets in the same column but different rows" do
      widget2 = valid_layout["widgets"][1].merge(
        "position" => { "col" => 1, "row" => 2, "relative" => 2 }
      )
      layout = valid_layout.merge("widgets" => [valid_layout["widgets"][0], widget2])
      result = run_mutation(layout: layout.to_json)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to eq(layout.to_json)
    end
  end

  context "educator widget types" do
    let(:educator_layout) do
      {
        "columns" => 2,
        "widgets" => [
          {
            "id" => "educator-announcement-creation-widget",
            "type" => "educator_announcement_creation",
            "position" => { "col" => 1, "row" => 1, "relative" => 1 },
            "title" => "Announcement Creation"
          },
          {
            "id" => "educator-todo-list-widget",
            "type" => "educator_todo_list",
            "position" => { "col" => 2, "row" => 1, "relative" => 2 },
            "title" => "Todo List"
          },
          {
            "id" => "educator-content-quality-widget",
            "type" => "educator_content_quality",
            "position" => { "col" => 1, "row" => 2, "relative" => 3 },
            "title" => "Content Quality"
          }
        ]
      }
    end

    it "accepts educator widget types" do
      result = run_mutation(layout: educator_layout.to_json)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardLayout", "layout")).to eq(educator_layout.to_json)
    end
  end

  context "dashboard_type argument routing" do
    before(:once) do
      @user = user_factory(active_all: true)
      student_in_course(course: @course, user: @user, active_all: true)
      teacher_in_course(course: @course, user: @user, active_all: true)
    end

    def mutation_str_with_type
      <<~GQL
        mutation UpdateWidgetDashboardLayout($layout: String!, $dashboardType: WidgetDashboardType) {
          updateWidgetDashboardLayout(input: {
            layout: $layout
            dashboardType: $dashboardType
          }) {
            layout
            errors {
              message
            }
          }
        }
      GQL
    end

    def run_mutation_with_type(opts = {})
      CanvasSchema.execute(
        mutation_str_with_type,
        variables: opts,
        context: {
          current_user: @user,
          request: ActionDispatch::TestRequest.create
        }
      ).to_h.with_indifferent_access
    end

    it "writes to :educator_dashboard_config when dashboardType is educator" do
      run_mutation_with_type(layout: valid_layout.to_json, dashboardType: "educator")

      @user.reload
      expect(@user.get_preference(:educator_dashboard_config)["layout"]).to eq(valid_layout)
      expect(@user.get_preference(:widget_dashboard_config)).to be_nil
    end

    it "preserves existing data when updating educator config" do
      existing_filters = { "filters" => { "some-widget" => { "filter" => "all" } } }
      @user.set_preference(:educator_dashboard_config, existing_filters)

      run_mutation_with_type(layout: valid_layout.to_json, dashboardType: "educator")

      @user.reload
      config = @user.get_preference(:educator_dashboard_config)
      expect(config["layout"]).to eq(valid_layout)
      expect(config["filters"]).to eq(existing_filters["filters"])
    end

    it "writes to :widget_dashboard_config when dashboardType is student" do
      run_mutation_with_type(layout: valid_layout.to_json, dashboardType: "student")

      @user.reload
      expect(@user.get_preference(:widget_dashboard_config)["layout"]).to eq(valid_layout)
      expect(@user.get_preference(:educator_dashboard_config)).to be_nil
    end

    it "writes to :widget_dashboard_config when dashboardType is omitted" do
      run_mutation({ layout: valid_layout.to_json }, @user)

      @user.reload
      expect(@user.get_preference(:widget_dashboard_config)["layout"]).to eq(valid_layout)
      expect(@user.get_preference(:educator_dashboard_config)).to be_nil
    end
  end
end
