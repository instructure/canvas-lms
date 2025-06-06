# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
  class StudentReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      @account_report.parameters ||= {}
      include_deleted_objects
    end

    def start_and_end_times
      # if there is not a supplied end_date, make it now
      # force the window of time to be limited to 2 weeks

      # if both dates are specified use them or change the start date if range is over 2 week
      if start_at && end_at && end_at - start_at > 2.weeks.to_i
        @start = end_at - 2.weeks
        @account_report.parameters["start_at"] = @start
      end

      # if no end date is specified, make one 2 weeks after the start date
      if start_at && !end_at
        @end = start_at + 2.weeks
        @account_report.parameters["end_at"] = @end
      end

      # if no start date is specified, make one 2 weeks before the end date
      if !start_at && end_at
        @start = end_at - 2.weeks
        @account_report.parameters["start_at"] = @start
      end

      # if not dates are supplied assume the past 2 weeks
      if !start_at && !end_at
        @start = 2.weeks.ago
        @account_report.parameters["start_at"] = @start
        @end = Time.zone.now
        @account_report.parameters["end_at"] = @end
      end
    end

    def include_enrollment_state
      if @account_report.value_for_param("include_enrollment_state")
        state = value_to_boolean(@account_report.parameters["include_enrollment_state"])
      end
      state
    end

    def enrollment_states
      if @account_report.value_for_param("enrollment_state")
        states = @account_report.parameters["enrollment_state"]
      end
      states = nil if Array(states).include?("all")
      states
    end

    def enrollment_states_string
      if enrollment_states
        Array(enrollment_states).join(" ")
      else
        "all"
      end
    end

    def students_with_no_submissions
      start_and_end_times
      report_extra_text

      time_span_join = Pseudonym.send(:sanitize_sql,
                                      [" AND s.submitted_at > ? AND s.submitted_at < ?", start_at, end_at])

      no_subs = root_account.all_courses.active
                            .select("p.user_id, p.sis_user_id, courses.id AS course_id,
                u.sortable_name, courses.name AS course_name,
                courses.sis_source_id AS course_sis_id, cs.id AS section_id,
                cs.sis_source_id AS section_sis_id, cs.name AS section_name,
                e.workflow_state AS enrollment_state")
                            .joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_id = courses.id
                 AND e.root_account_id = courses.root_account_id
                 AND e.type = 'StudentEnrollment'
               INNER JOIN #{CourseSection.quoted_table_name} cs ON cs.id = e.course_section_id
               INNER JOIN #{ordered_pseudonyms(Pseudonym.active)} p ON e.user_id = p.user_id
                 AND courses.root_account_id = p.account_id
               INNER JOIN #{User.quoted_table_name} u ON u.id = p.user_id")
                            .where("NOT EXISTS (SELECT s.user_id
                           FROM #{Submission.quoted_table_name} s
                           INNER JOIN #{Assignment.quoted_table_name} a ON s.assignment_id = a.id
                             AND a.context_type = 'Course'
                           WHERE s.user_id = p.user_id
                             AND a.context_id = courses.id
                             AND s.workflow_state <> 'deleted'
                           #{time_span_join})")

      no_subs = no_subs.where(e: { workflow_state: enrollment_states }) if enrollment_states
      no_subs = add_term_scope(no_subs)
      no_subs = add_course_enrollments_scope(no_subs, "e")
      no_subs = add_course_sub_account_scope(no_subs) unless course

      if include_enrollment_state
        add_extra_text(I18n.t("account_reports.student.enrollment_state",
                              "Include Enrollment State: true;"))
      end

      add_extra_text(I18n.t("account_reports.student.enrollment_states",
                            "Enrollment States: %{states};",
                            states: enrollment_states_string))

      headers = []
      headers << "user id"
      headers << "user sis id"
      headers << "user name"
      headers << "section id"
      headers << "section sis id"
      headers << "section name"
      headers << "course id"
      headers << "course sis id"
      headers << "course name"
      if include_enrollment_state
        headers << "enrollment state"
      end

      write_report headers do |csv|
        no_subs.find_each do |u|
          row = []
          row << u["user_id"]
          row << u["sis_user_id"]
          row << u["sortable_name"]
          row << u["section_id"]
          row << u["section_sis_id"]
          row << u["section_name"]
          row << u["course_id"]
          row << u["course_sis_id"]
          row << u["course_name"]
          row << u["enrollment_state"] if include_enrollment_state
          csv << row
        end
      end
    end

    def zero_activity
      report_extra_text

      data = root_account.enrollments.active
                         .select("c.id AS course_id, c.sis_source_id AS course_sis_id,
                c.name AS course_name, s.id AS section_id,
                s.sis_source_id AS section_sis_id, s.name AS section_name,
                p.user_id, p.sis_user_id, u.sortable_name")
                         .joins("INNER JOIN #{Course.quoted_table_name} c ON c.id = enrollments.course_id
                 AND c.workflow_state = 'available'
               INNER JOIN #{CourseSection.quoted_table_name} s ON s.id = enrollments.course_section_id
                 AND s.workflow_state = 'active'
               INNER JOIN #{ordered_pseudonyms(Pseudonym.active_only)} p ON p.user_id = enrollments.user_id
                 AND p.account_id = enrollments.root_account_id
               INNER JOIN #{User.quoted_table_name} u ON u.id = p.user_id")
                         .where("enrollments.type = 'StudentEnrollment'
               AND enrollments.workflow_state = 'active'")

      if start_at
        data = data.where("enrollments.last_activity_at < ? OR enrollments.last_activity_at IS NULL", start_at)
        # Only select enrollments that have zero activity across an entire course.
        # This makes it so that users that have enrollments in multiple sections
        # don't get pulled up unless they have zero activity across
        # all the sections they belong to.
        data = data.where(%{NOT EXISTS (
          SELECT 1 AS ONE
          FROM #{Enrollment.quoted_table_name} AS other_ens
          WHERE other_ens.id<>enrollments.id
            AND other_ens.user_id=enrollments.user_id
            AND other_ens.course_id=enrollments.course_id
            AND (
              other_ens.last_activity_at IS NOT NULL
              AND other_ens.last_activity_at > ?
            )
        )},
                          start_at)
      else
        data = data.where(enrollments: { last_activity_at: nil })
        data = data.where(%{NOT EXISTS (
          SELECT 1 AS ONE
          FROM #{Enrollment.quoted_table_name} AS other_ens
          WHERE other_ens.id<>enrollments.id
            AND other_ens.user_id=enrollments.user_id
            AND other_ens.course_id=enrollments.course_id
            AND other_ens.last_activity_at IS NOT NULL
        )})
      end

      data = data.where(enrollments: { course_id: course }) if course
      data = add_term_scope(data, "c")
      data = add_course_sub_account_scope(data, "c") unless course

      headers = []
      headers << "user id"
      headers << "user sis id"
      headers << "name"
      headers << "section id"
      headers << "section sis id"
      headers << "section name"
      headers << "course id"
      headers << "course sis id"
      headers << "course name"

      write_report headers do |csv|
        data.find_each do |u|
          row = []
          row << u["user_id"]
          row << u["sis_user_id"]
          row << u["sortable_name"]
          row << u["section_id"]
          row << u["section_sis_id"]
          row << u["section_name"]
          row << u["course_id"]
          row << u["course_sis_id"]
          row << u["course_name"]
          csv << row
        end
      end
    end

    def last_user_access
      report_extra_text

      students = root_account.pseudonyms.not_instructure_identity.joins(:user)
      students = add_user_sub_account_scope(students)

      courses = term.courses if term
      courses = course if course

      if course || term
        enrollments = root_account.enrollments.where(course_id: courses).distinct.select(:user_id)
        enrollments = enrollments.active unless @include_deleted
        students = students.where(user_id: enrollments)
      end

      students = students.active unless @include_deleted

      headers = []
      headers << "user id"
      headers << "user sis id"
      headers << "user name"
      headers << "last access at"
      headers << "last ip"

      @account_report.update(total_lines: students.count)

      students = students.select('pseudonyms.last_request_at, pseudonyms.user_id,
        pseudonyms.sis_user_id, users.sortable_name, pseudonyms.current_login_ip')

      write_report headers do |csv|
        students.find_each do |u|
          row = []
          row << u.user_id
          row << u.sis_user_id
          row << u.sortable_name
          row << default_timezone_format(u.last_request_at)
          row << u.current_login_ip
          csv << row
        end
      end
    end

    # shows last_activity_at on enrollments for users with
    # enrollments in this account

    # NOTE: activity on other root accounts' enrollments will not show
    def last_enrollment_activity
      report_extra_text

      headers = []
      headers << "user id"
      headers << "user name"
      headers << "last activity at"

      write_report headers do |csv|
        students = User.joins(:enrollments)
                       .select(["users.id", :last_activity_at, :sortable_name])
                       .order("users.id, sortable_name, last_activity_at DESC")
                       .distinct_on("users.id, sortable_name")

        students = add_user_sub_account_scope(students)

        potential_courses = Course.where(root_account_id: root_account)
        potential_courses = potential_courses.where(enrollment_term_id: term) if term
        potential_courses = potential_courses.where(id: course) if course
        potential_courses = add_course_sub_account_scope(potential_courses)

        students = students.where(enrollments: { course_id: potential_courses })
        students = students.where.not(enrollments: { last_activity_at: nil })

        students.find_each do |u|
          row = []
          row << u.id
          row << u.sortable_name
          row << default_timezone_format(u.last_activity_at)
          csv << row
        end
      end
    end

    def user_access_tokens
      headers = []
      headers << "user id"
      headers << "user name"
      headers << "token hint"
      headers << "expiration"
      headers << "last used"
      headers << "dev key id"
      headers << "dev key name"

      columns = []
      columns << "access_tokens.user_id"
      columns << "users.sortable_name"
      columns << "access_tokens.token_hint"
      columns << "access_tokens.permanent_expires_at"
      columns << "access_tokens.last_used_at"
      columns << "access_tokens.developer_key_id"

      user_tokens = root_account.pseudonyms
                                .select(columns)
                                .joins(user: :access_tokens).order("users.id, sortable_name, last_used_at DESC")
      user_tokens = user_tokens.where.not(pseudonyms: { workflow_state: "deleted" }) unless @include_deleted

      user_tokens = add_user_sub_account_scope(user_tokens)

      write_report headers do |csv|
        user_tokens.find_each do |token|
          dev_key = developer_key(token[:developer_key_id])

          row = []
          row << token[:user_id]
          row << token[:sortable_name]
          row << token[:token_hint]
          row << (token[:permanent_expires_at] ? default_timezone_format(token[:permanent_expires_at]) : "never")
          row << (token[:last_used_at] ? default_timezone_format(token[:last_used_at]) : "never")
          row << token[:developer_key_id]
          row << dev_key&.name
          csv << row
        end
      end
    end

    def developer_key(dev_key_id)
      @dev_keys ||= {}
      return @dev_keys[dev_key_id] if @dev_keys.include?(dev_key_id)

      @dev_keys[dev_key_id] = DeveloperKey.find_by(id: dev_key_id)
    end
  end
end
