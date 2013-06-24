#
# Copyright (C) 2013 Instructure, Inc.
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

module Canvas::AccountReports

  class StudentReports
    include Api
    include Canvas::AccountReports::ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
    end

    def students_with_no_submissions()
      file = Canvas::AccountReports.generate_file(@account_report)
      CSV.open(file, "w") do |csv|

        condition = [""]
        if start_at
          condition.first << " AND submitted_at > ?"
          condition << start_at
          @account_report.parameters["extra_text"] << " Start At: #{start_at};"
        end

        if end_at
          condition.first << " AND submitted_at < ?"
          condition << end_at
          @account_report.parameters["extra_text"] << " End At: #{end_at};"
        end

        time_span_join = Pseudonym.send(:sanitize_sql, condition)

        no_subs = root_account.all_courses.active.
          select("p.user_id, p.sis_user_id, courses.id AS course_id,
                  u.sortable_name, courses.name AS course_name,
                  courses.sis_source_id AS course_sis_id, cs.id AS section_id,
                  cs.sis_source_id AS section_sis_id, cs.name AS section_name").
          joins("INNER JOIN enrollments e ON e.course_id = courses.id
                   AND e.root_account_id = courses.root_account_id
                   AND e.type = 'StudentEnrollment'
                 INNER JOIN course_sections cs ON cs.id = e.course_section_id
                 INNER JOIN pseudonyms p ON e.user_id = p.user_id
                   AND courses.root_account_id = p.account_id
                 INNER JOIN users u ON u.id = p.user_id").
          where("NOT EXISTS (SELECT user_id
                             FROM submissions s
                             INNER JOIN assignments a ON s.assignment_id = a.id
                             INNER JOIN courses c ON a.context_id = c.id
                               AND a.context_type = 'Course'
                             WHERE s.user_id = p.user_id
                             AND c.id = courses.id
                             #{time_span_join})")

        no_subs = add_term_scope(no_subs)
        no_subs = add_course_enrollments_scope(no_subs, 'e')
        no_subs = add_course_sub_account_scope(no_subs)

        csv << ['user id','user sis id','user name','section id',
                'section sis id', 'section name','course id',
                'course sis id', 'course name']

        no_subs.find_each_with_temp_table do |u|
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
      send_report(file)
    end

  end
end
