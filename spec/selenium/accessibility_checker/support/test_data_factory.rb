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

require_relative "fixture_loader"

module AccessibilityChecker
  module TestDataFactory
    include FixtureLoader

    @resource_counter = 0
    @expected_issue_counts = {}

    class << self
      attr_accessor :resource_counter, :expected_issue_counts
    end

    RESOURCE_CONFIGS = {
      page: {
        collection: :wiki_pages,
        html_attr: :body,
        defaults: { workflow_state: "active" }
      },
      assignment: {
        collection: :assignments,
        html_attr: :description,
        defaults: { submission_types: "online_text_entry" }
      }
    }.freeze

    def create_resource_with_fixture(course, resource_type, fixture_path, title: nil, **options)
      config = RESOURCE_CONFIGS[resource_type]
      raise ArgumentError, "Unknown resource type: #{resource_type}" unless config

      html_content = load_html_fixture(fixture_path)
      default_title = fixture_path.split("/").last.gsub(".html", "").titleize

      attributes = {
        :title => title || default_title,
        config[:html_attr] => html_content
      }.merge(config[:defaults]).merge(options)

      course.public_send(config[:collection]).create!(attributes)
    end

    FIXTURES = {
      missing_alt_text: { path: "single_issues/missing_alt_text.html", title: "Missing Alt Text", issue_count: 1 },
      table_no_headers: { path: "single_issues/table_no_headers.html", title: "Table No Headers", issue_count: 1 },
      multiple_issues: { path: "multiple_issues/incorrect_heading_hierarchy_and_missing_alt_text.html", title: "Multiple Issues", issue_count: 2 },
      valid_alt_text: { path: "valid/accessible_page_complete.html", title: "Accessible Page Complete", issue_count: 0 }
    }.freeze

    def create_page_from_fixture(course, fixture_path, title: nil, **)
      create_resource_with_fixture(course, :page, fixture_path, title:, **)
    end

    def create_assignment_from_fixture(course, fixture_path, title: nil, **)
      create_resource_with_fixture(course, :assignment, fixture_path, title:, **)
    end

    def create_page_with(course, fixture_key, title: nil, **)
      config = FIXTURES[fixture_key]
      raise ArgumentError, "Unknown fixture: #{fixture_key}" unless config

      if title.nil?
        TestDataFactory.resource_counter += 1
        title = "Resource #{TestDataFactory.resource_counter}"
      end

      page = create_page_from_fixture(course, config[:path], title:, **)

      TestDataFactory.expected_issue_counts[page.id] = config[:issue_count]

      page
    end

    def create_assignment_with(course, fixture_key, title: nil, **)
      config = FIXTURES[fixture_key]
      raise ArgumentError, "Unknown fixture: #{fixture_key}" unless config

      if title.nil?
        TestDataFactory.resource_counter += 1
        title = "Resource #{TestDataFactory.resource_counter}"
      end

      assignment = create_assignment_from_fixture(course, config[:path], title:, **)

      TestDataFactory.expected_issue_counts[assignment.id] = config[:issue_count]

      assignment
    end

    def expected_issue_count_for(resource)
      TestDataFactory.expected_issue_counts[resource.id] || 0
    end
  end
end
