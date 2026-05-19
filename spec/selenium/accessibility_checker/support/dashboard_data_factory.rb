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
  module DashboardDataFactory
    STATISTIC_FIXTURES = {
      spring_course: { active_issue_count: 20, resolved_issue_count: 1 },
      other_spring_course: { active_issue_count: 0, resolved_issue_count: 0 },
      fall_course: { active_issue_count: 0, resolved_issue_count: 10 }
    }.freeze

    DASHBOARD_COURSE_FIXTURES = {
      spring_course: { name: "Spring Course" },
      other_spring_course: { name: "Other Spring Course" },
      fall_course: { name: "Fall Course", workflow_state: "claimed" }
    }.freeze

    TERM_FIXTURES = {
      spring_term: { name: "Spring 2026" },
      fall_term: { name: "Fall 2026" }
    }.freeze

    PAGINATION_COURSE_COUNT = 15

    def statistic_fixture_for(key)
      STATISTIC_FIXTURES[key]
    end

    def dashboard_course_name_for(key)
      DASHBOARD_COURSE_FIXTURES[key][:name]
    end

    def create_dashboard_course(account, fixture_key, term_id: nil)
      config = DASHBOARD_COURSE_FIXTURES[fixture_key]
      attrs = {
        name: config[:name],
        account:,
        workflow_state: config[:workflow_state] || "available"
      }
      attrs[:enrollment_term_id] = term_id if term_id
      course_model(**attrs)
    end

    def create_enrollment_term(account, fixture_key)
      EnrollmentTerm.create!(name: TERM_FIXTURES[fixture_key][:name], root_account: account)
    end

    def create_paginated_courses(account, count: PAGINATION_COURSE_COUNT)
      count.times do |i|
        course_model(
          name: "Pagination Course #{format("%02d", i + 1)}",
          account:,
          workflow_state: "available"
        )
      end
    end

    def create_course_with_statistic(account, fixture_key, term_id: nil)
      create_dashboard_course(account, fixture_key, term_id:)
      AccessibilityCourseStatistic.create!(
        course: @course,
        workflow_state: "active",
        **STATISTIC_FIXTURES[fixture_key]
      )
    end
  end
end
