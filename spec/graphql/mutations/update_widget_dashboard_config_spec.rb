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

  def mutation_str
    <<~GQL
      mutation UpdateWidgetDashboardConfig($widgetId: String!, $filters: JSON!) {
        updateWidgetDashboardConfig(input: {
          widgetId: $widgetId
          filters: $filters
        }) {
          widgetId
          filters
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

  it "saves widget filter preferences" do
    filters = { "selectedCourse" => "all", "selectedDateFilter" => "next3days" }
    result = run_mutation(widgetId: "course-work-widget", filters:)

    expect(result["errors"]).to be_nil, "GraphQL errors: #{result["errors"].inspect}"
    expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("course-work-widget"), "Full result: #{result.inspect}"

    config = @student.get_preference(:widget_dashboard_config)
    expect(config["filters"]["course-work-widget"]).to eq(filters)
  end

  it "persists the preference across requests" do
    filters = { "filter" => "unread" }
    run_mutation(widgetId: "announcements-widget", filters:)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["filters"]["announcements-widget"]).to eq(filters)
  end

  it "updates an existing filter preference" do
    @student.set_preference(:widget_dashboard_config, { "filters" => { "course-work-widget" => { "selectedCourse" => "all" } } })

    filters = { "selectedCourse" => "course_123", "selectedDateFilter" => "next7days" }
    run_mutation(widgetId: "course-work-widget", filters:)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["filters"]["course-work-widget"]).to eq(filters)
  end

  it "allows different filters for different widgets" do
    filters1 = { "selectedCourse" => "course_123" }
    filters2 = { "filter" => "read" }

    run_mutation(widgetId: "course-work-widget", filters: filters1)
    run_mutation(widgetId: "announcements-widget", filters: filters2)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    expect(config["filters"]["course-work-widget"]).to eq(filters1)
    expect(config["filters"]["announcements-widget"]).to eq(filters2)
  end

  it "converts strong parameters to plain hash for storage" do
    filters = { "selectedCourse" => "all", "selectedDateFilter" => "next3days" }
    run_mutation(widgetId: "course-work-widget", filters:)

    @student.reload
    config = @student.get_preference(:widget_dashboard_config)
    stored_filters = config["filters"]["course-work-widget"]

    expect(stored_filters).to be_a(Hash)
    expect(stored_filters).not_to be_a(ActionController::Parameters)
    expect(stored_filters).to eq(filters)
  end

  it "rejects array filter values" do
    result = run_mutation(widgetId: "course-work-widget", filters: ["invalid"])

    expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
    expect(result["errors"]).not_to be_nil
    expect(result["errors"][0]["message"]).to include("filters must be an object")
  end

  it "rejects string filter values" do
    result = run_mutation(widgetId: "course-work-widget", filters: "invalid")

    expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
    expect(result["errors"]).not_to be_nil
    expect(result["errors"][0]["message"]).to include("filters must be an object")
  end

  it "rejects filters with empty string keys" do
    result = run_mutation(widgetId: "course-work-widget", filters: { "" => "value" })

    expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
    expect(result["errors"]).not_to be_nil
    expect(result["errors"][0]["message"]).to include("filter keys must be non-empty strings")
  end

  context "announcements widget validation" do
    it "accepts valid announcement filter values" do
      %w[unread read all].each do |filter_value|
        filters = { "filter" => filter_value }
        result = run_mutation(widgetId: "announcements-widget", filters:)

        expect(result["errors"]).to be_nil, "Expected no errors for filter value '#{filter_value}', got: #{result["errors"].inspect}"
        expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("announcements-widget")
      end
    end

    it "rejects invalid announcement filter values" do
      filters = { "filter" => "invalid" }
      result = run_mutation(widgetId: "announcements-widget", filters:)

      expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
      expect(result["errors"]).not_to be_nil
      expect(result["errors"][0]["message"]).to include("filter must be one of: unread, read, all")
    end

    it "rejects invalid keys for announcements widget" do
      filters = { "filter" => "unread", "invalidKey" => "value" }
      result = run_mutation(widgetId: "announcements-widget", filters:)

      expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
      expect(result["errors"]).not_to be_nil
      expect(result["errors"][0]["message"]).to include("invalid filter keys for announcements widget")
    end
  end

  context "course work widget validation" do
    it "accepts valid selectedCourse values" do
      %w[all course_123 course_456789].each do |course_value|
        filters = { "selectedCourse" => course_value, "selectedDateFilter" => "next7days" }
        result = run_mutation(widgetId: "course-work-widget", filters:)

        expect(result["errors"]).to be_nil, "Expected no errors for selectedCourse '#{course_value}', got: #{result["errors"].inspect}"
        expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("course-work-widget")
      end
    end

    it "rejects invalid selectedCourse values" do
      filters = { "selectedCourse" => "invalid_format" }
      result = run_mutation(widgetId: "course-work-widget", filters:)

      expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
      expect(result["errors"]).not_to be_nil
      expect(result["errors"][0]["message"]).to include("selectedCourse must be 'all' or 'course_{id}'")
    end

    it "accepts valid selectedDateFilter values" do
      %w[all missing next3days next7days next14days submitted].each do |date_filter|
        filters = { "selectedDateFilter" => date_filter }
        result = run_mutation(widgetId: "course-work-widget", filters:)

        expect(result["errors"]).to be_nil, "Expected no errors for selectedDateFilter '#{date_filter}', got: #{result["errors"].inspect}"
        expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("course-work-widget")
      end
    end

    it "rejects invalid selectedDateFilter values" do
      filters = { "selectedDateFilter" => "invalid" }
      result = run_mutation(widgetId: "course-work-widget", filters:)

      expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
      expect(result["errors"]).not_to be_nil
      expect(result["errors"][0]["message"]).to include("selectedDateFilter must be one of")
    end

    it "rejects invalid keys for course work widget" do
      filters = { "selectedCourse" => "all", "invalidKey" => "value" }
      result = run_mutation(widgetId: "course-work-widget", filters:)

      expect(result.dig("data", "updateWidgetDashboardConfig")).to be_nil
      expect(result["errors"]).not_to be_nil
      expect(result["errors"][0]["message"]).to include("invalid filter keys for course work widget")
    end

    it "works for course-work-combined-widget" do
      filters = { "selectedCourse" => "all", "selectedDateFilter" => "next3days" }
      result = run_mutation(widgetId: "course-work-combined-widget", filters:)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("course-work-combined-widget")
    end

    it "works for course-work-summary-widget" do
      filters = { "selectedCourse" => "course_789", "selectedDateFilter" => "missing" }
      result = run_mutation(widgetId: "course-work-summary-widget", filters:)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("course-work-summary-widget")
    end
  end

  context "unknown widget types" do
    it "accepts generic JSON structures for unknown widgets" do
      filters = {
        "stringValue" => "test",
        "numberValue" => 123,
        "booleanValue" => true,
        "nullValue" => nil,
        "arrayValue" => [1, 2, 3],
        "nestedObject" => { "key" => "value" }
      }
      result = run_mutation(widgetId: "unknown-widget-type", filters:)

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "updateWidgetDashboardConfig", "widgetId")).to eq("unknown-widget-type")

      @student.reload
      config = @student.get_preference(:widget_dashboard_config)
      expect(config["filters"]["unknown-widget-type"]).to eq(filters)
    end
  end
end
