# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module AccountReports
  module Default
    # when adding new reports to this file make sure to add a migration to
    # enable the new report for all accounts with DataFixup::AddNewDefaultReport

    def self.student_assignment_outcome_map_csv(account_report)
      OutcomeReports.new(account_report).student_assignment_outcome_map
    end

    def self.outcome_results_csv(account_report)
      OutcomeReports.new(account_report).outcome_results
    end

    def self.outcome_export_csv(account_report)
      OutcomeExport.new(account_report).outcome_export
    end

    def self.grade_export_csv(account_report)
      GradeReports.new(account_report).grade_export
    end

    def self.parallel_grade_export_csv(account_report, runner)
      GradeReports.new(account_report, runner).grade_export_runner(runner)
    end

    def self.mgp_grade_export_csv(account_report)
      GradeReports.new(account_report).mgp_grade_export
    end

    def self.parallel_mgp_grade_export_csv(account_report, runner)
      GradeReports.new(account_report, runner).mgp_grade_export_runner(runner)
    end

    def self.sis_export_csv(account_report)
      SisExporter.new(account_report, { sis_format: true }).csv
    end

    def self.provisioning_csv(account_report)
      SisExporter.new(account_report, { sis_format: false }).csv
    end

    def self.unpublished_courses_csv(account_report)
      CourseReports.new(account_report).unpublished_courses
    end

    def self.public_courses_csv(account_report)
      CourseReports.new(account_report).public_courses
    end

    def self.course_storage_csv(account_report)
      CourseReports.new(account_report).course_storage
    end

    def self.unused_courses_csv(account_report)
      CourseReports.new(account_report).unused_courses
    end

    def self.recently_deleted_courses_csv(account_report)
      CourseReports.new(account_report).recently_deleted
    end

    def self.students_with_no_submissions_csv(account_report)
      StudentReports.new(account_report).students_with_no_submissions
    end

    def self.zero_activity_csv(account_report)
      StudentReports.new(account_report).zero_activity
    end

    def self.last_user_access_csv(account_report)
      StudentReports.new(account_report).last_user_access
    end

    def self.last_enrollment_activity_csv(account_report)
      StudentReports.new(account_report).last_enrollment_activity
    end

    def self.user_access_tokens_csv(account_report)
      StudentReports.new(account_report).user_access_tokens
    end

    def self.lti_report_csv(account_report)
      LtiReports.new(account_report).lti_report
    end

    def self.eportfolio_report_csv(account_report)
      EportfolioReports.new(account_report).eportfolio_report
    end

    def self.developer_key_report_csv(account_report)
      DeveloperKeyReports.new(account_report).dev_key_report
    end
  end
end
