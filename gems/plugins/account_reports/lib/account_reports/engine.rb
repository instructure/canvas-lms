# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  class Engine < ::Rails::Engine
    config.paths["lib"].eager_load!
    initializer "account_reports.canvas_plugin" do
      Rails.configuration.to_prepare do
        AccountReports.configure_account_report "Default", {
          "eportfolio_report_csv" => {
            title: proc { I18n.t("Eportfolio Report") },
            description_partial: true,
            parameters_partial: true,
            parameters: {
              no_enrollments: {
                required: false,
                description: "Only include ePortfolios from users with no enrollments"
              },
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "grade_export_csv" => {
            title: proc { I18n.t(:grade_export_title, "Grade Export") },
            description_partial: true,
            parameters_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get grades from"
              },
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "mgp_grade_export_csv" => {
            title: proc { I18n.t("Multiple Grading Periods Grade Export") },
            description_partial: true,
            parameters_partial: true,
            parameters: {
              enrollment_term_id: {
                required: true,
                description: "The canvas id of the term to get grades from"
              },
            },
          },
          "last_user_access_csv" => {
            title: proc { I18n.t(:last_user_access_title, "Last User Access") },
            description_partial: true,
            parameters_partial: "grade_export_csv_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get grades from"
              },
              course_id: {
                required: false,
                description: "The course to report on"
              },
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "last_enrollment_activity_csv" => {
            title: proc { I18n.t("Last Enrollment Activity") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term's courses to get activity from"
              },
              course_id: {
                required: false,
                description: "The course's enrollments to report on"
              }
            }
          },
          "outcome_export_csv" => {
            title: proc { I18n.t("Outcome Export") },
            parameters_partial: false,
            description_partial: true,
            parameters: {}
          },
          "outcome_results_csv" => {
            title: proc { I18n.t(:outcome_results_title, "Outcome Results") },
            parameters_partial: true,
            description_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term of courses to report on"
              },
              order: {
                required: false,
                description: "The sort order for the csv, Options: 'users', 'courses', 'outcomes'",
              },
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "provisioning_csv" => {
            title: proc { I18n.t(:provisioning_title, "Provisioning") },
            parameters_partial: "provisioning_csv_parameters",
            description_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term of courses to report on"
              },
              users: {
                description: "Get the Provisioning file for users"
              },
              accounts: {
                description: "Get the Provisioning file for accounts"
              },
              terms: {
                description: "Get the Provisioning file for terms"
              },
              courses: {
                description: "Get the Provisioning file for courses"
              },
              sections: {
                description: "Get the Provisioning file for sections"
              },
              enrollments: {
                description: "Get the Provisioning file for enrollments"
              },
              groups: {
                description: "Get the Provisioning file for groups"
              },
              group_categories: {
                description: "Get the Provisioning file for group_categories"
              },
              group_membership: {
                description: "Get the Provisioning file for group_membership"
              },
              xlist: {
                description: "Get the Provisioning file for cross listed courses"
              },
              user_observers: {
                description: "Get the Provisioning file for user_observers"
              },
              admins: {
                description: "Get the Provisioning file for admins"
              },
              created_by_sis: {
                description: "Only include objects that were created by sis"
              },
              include_deleted: {
                description: "Include deleted objects"
              },
              enrollment_filter: {
                description: "Include objects from the specified role types. Accepted values are #{Enrollment.valid_types.to_sentence}",
                required: false
              },
              enrollment_states: {
                description: "Include objects from the specified states.",
                required: false
              }
            }
          },
          "recently_deleted_courses_csv" => {
            title: proc { I18n.t(:recently_deleted_courses_title, "Recently Deleted Courses") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get grades from"
              }
            }
          },
          "sis_export_csv" => {
            title: proc { I18n.t(:sis_export_title, "SIS Export") },
            parameters_partial: true,
            description_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term of courses to report on"
              },
              users: {
                description: "Get the SIS file for users"
              },
              accounts: {
                description: "Get the SIS file for accounts"
              },
              terms: {
                description: "Get the SIS file for terms"
              },
              courses: {
                description: "Get the SIS file for courses"
              },
              sections: {
                description: "Get the SIS file for sections"
              },
              enrollments: {
                description: "Get the SIS file for enrollments"
              },
              groups: {
                description: "Get the SIS file for groups"
              },
              group_categories: {
                description: "Get the SIS file for group_categories"
              },
              group_membership: {
                description: "Get the SIS file for group_membership"
              },
              xlist: {
                description: "Get the SIS file for cross listed courses"
              },
              user_observers: {
                description: "Get the SIS file for user_observers"
              },
              admins: {
                description: "Get the SIS file for admins"
              },
              created_by_sis: {
                description: "Only include objects that were created by sis"
              },
              include_deleted: {
                description: "Include deleted objects"
              }
            }
          },
          "student_assignment_outcome_map_csv" => {
            title: proc { I18n.t(:student_assignment_outcome_map_title, "Student Competency") },
            parameters_partial: "grade_export_csv_parameters",
            description_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term of courses to report on"
              },
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "students_with_no_submissions_csv" => {
            title: proc { I18n.t(:students_with_no_submissions_title, "Students with no submissions") },
            description_partial: true,
            parameters_partial: true,
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The term to report on"
              },
              course_id: {
                required: false,
                description: "The course to report on"
              },
              start_at: {
                required: true,
                description: "The beginning date for submissions. Max time range is 2 weeks."
              },
              end_at: {
                required: true,
                description: "The end date for submissions. Max time range is 2 weeks."
              },
              include_enrollment_state: {
                required: false,
                description: "Include enrollment state."
              },
              enrollment_state: {
                required: false,
                description: "Enrollment states to include, defaults to 'all', Options 'active'|'invited'|'creation_pending'|'deleted'|'rejected'|'completed'|'inactive'"
              }
            }
          },
          "unpublished_courses_csv" => {
            title: proc { I18n.t(:unpublished_courses_title, "Unpublished Courses") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get unpublished courses from"
              }
            }
          },
          "public_courses_csv" => {
            title: proc { I18n.t(:public_courses_title, "Public Courses") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get public courses from"
              }
            }
          },
          "course_storage_csv" => {
            title: proc { I18n.t("Course Storage") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get courses from for storage report"
              }
            }
          },
          "unused_courses_csv" => {
            title: proc { I18n.t(:unused_courses_title, "Unused Courses") },
            description_partial: true,
            parameters_partial: "term_selector_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get courses from"
              }
            }
          },
          "zero_activity_csv" => {
            title: proc { I18n.t(:zero_activity_title, "Zero Activity") },
            description_partial: true,
            parameters_partial: "term_and_date_picker_parameters",
            parameters: {
              enrollment_term_id: {
                required: false,
                description: "The canvas id of the term to get grades from"
              },
              start_at: {
                required: false,
                description: "The first date in the date range, the second date is the time the report is run."
              },
              course_id: {
                required: false,
                description: "The course to report on"
              }
            }
          },
          "user_access_tokens_csv" => {
            title: proc { I18n.t(:user_access_tokens_title, "User Access Tokens") },
            description_partial: true,
            parameters_partial: "include_only_deleted_parameter",
            parameters: {
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "lti_report_csv" => {
            title: proc { I18n.t("LTI Report") },
            description_partial: true,
            parameters_partial: "include_only_deleted_parameter",
            parameters: {
              include_deleted: {
                required: false,
                description: "Include deleted objects"
              }
            }
          },
          "developer_key_report_csv" => {
            title: proc { I18n.t("Developer Keys Report") },
            parameters_partial: false,
            description_partial: true,
            parameters: {}
          }
        }
      end
    end
  end
end
