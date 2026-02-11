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

module AccessibilityChecker
  module FixtureLoader
    def load_html_fixture(filename)
      fixture_path = Rails.root.join("spec/selenium/accessibility_checker/html", filename)
      File.read(fixture_path)
    end

    def create_page_from_fixture(course, fixture_path, title: nil, **options)
      html_content = load_html_fixture(fixture_path)
      default_title = fixture_path.split("/").last.gsub(".html", "").titleize

      course.wiki_pages.create!(
        title: title || default_title,
        body: html_content,
        workflow_state: options[:workflow_state] || "active"
      )
    end
  end
end
