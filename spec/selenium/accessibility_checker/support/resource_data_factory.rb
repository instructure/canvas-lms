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
  module ResourceDataFactory
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
      heading_too_long: { path: "single_issues/heading_too_long.html", title: "Heading Too Long", issue_count: 1, heading_text: "This is a very long heading that is intentionally written to exceed the one hundred and twenty character limit for headings", issue_heading_level: 2 },
      heading_starts_at_h2: { path: "single_issues/heading_starts_at_h2.html", title: "Heading Starts at H2", issue_count: 1, issue_heading_level: 1, corrected_heading_level: 2, heading_text: "Main Page Heading" },
      heading_sequence: { path: "single_issues/heading_sequence.html", title: "Heading Sequence", issue_count: 1, issue_heading_level: 4, corrected_heading_level: 3 },
      adjacent_links: { path: "single_issues/adjacent_links.html", title: "Adjacent Links", issue_count: 1 },
      misformatted_ordered_list: { path: "single_issues/misformatted_list.html", title: "Misformatted Ordered List", issue_count: 1, list_item_count: 3 },
      misformatted_unordered_list: { path: "single_issues/misformatted_unordered_list.html", title: "Misformatted Unordered List", issue_count: 1, list_item_count: 3 },
      alt_text_too_long: { path: "single_issues/alt_text_too_long.html", title: "Alt Text Too Long", issue_count: 1 },
      alt_text_is_filename: { path: "single_issues/alt_text_is_filename.html", title: "Alt Text Is Filename", issue_count: 1 },
      missing_table_caption: { path: "single_issues/missing_table_caption.html", title: "Missing Table Caption", issue_count: 1 },
      table_no_headers: { path: "single_issues/table_no_headers.html", title: "Table No Headers", issue_count: 1 },
      missing_table_header_scope: { path: "single_issues/missing_table_header_scope.html", title: "Missing Table Header Scope", issue_count: 1 },
      multiple_issues: { path: "multiple_issues/incorrect_heading_hierarchy_and_missing_alt_text.html", title: "Multiple Issues", issue_count: 2 },
      two_alt_text_issues: { path: "multiple_issues/two_alt_text_issues.html", title: "Two Alt Text Issues", issue_count: 2 },
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
        ResourceDataFactory.resource_counter += 1
        title = "Resource #{ResourceDataFactory.resource_counter}"
      end

      page = create_page_from_fixture(course, config[:path], title:, **)

      ResourceDataFactory.expected_issue_counts[page.id] = config[:issue_count]

      page
    end

    def create_assignment_with(course, fixture_key, title: nil, **)
      config = FIXTURES[fixture_key]
      raise ArgumentError, "Unknown fixture: #{fixture_key}" unless config

      if title.nil?
        ResourceDataFactory.resource_counter += 1
        title = "Resource #{ResourceDataFactory.resource_counter}"
      end

      assignment = create_assignment_from_fixture(course, config[:path], title:, **)

      ResourceDataFactory.expected_issue_counts[assignment.id] = config[:issue_count]

      assignment
    end

    def list_item_count_for(fixture_key)
      FIXTURES[fixture_key][:list_item_count] || 0
    end

    def heading_text_for(fixture_key)
      FIXTURES[fixture_key][:heading_text]
    end

    def issue_heading_level_for(fixture_key)
      FIXTURES[fixture_key][:issue_heading_level]
    end

    def corrected_heading_level_for(fixture_key)
      FIXTURES[fixture_key][:corrected_heading_level]
    end

    def expected_issue_count_for(resource)
      ResourceDataFactory.expected_issue_counts[resource.id] || 0
    end
  end
end
