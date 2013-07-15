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

  class CourseReports
    include Api
    include Canvas::AccountReports::ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
    end

    def recently_deleted
      courses = root_account.all_courses.
        select([:id, :sis_source_id, :name, :course_code, :start_at,
                :conclude_at, :restrict_enrollments_to_course_dates]).
        where("workflow_state = 'deleted' AND updated_at > ?", 30.days.ago)
      csv(courses)
    end

    def unpublished_courses
      courses = root_account.all_courses.
        select([:id, :sis_source_id, :name, :course_code, :start_at,
                :conclude_at, :restrict_enrollments_to_course_dates]).
        where(:workflow_state => ['claimed', 'created'])
      csv(courses)
    end

    def csv(courses)
      courses = add_course_sub_account_scope(courses)
      courses = add_term_scope(courses)

      total = courses.count
      i = 0

      filename = Canvas::AccountReports.generate_file(@account_report)
      CSV.open(filename, "w") do |csv|
        csv << ['id', 'sis id', 'short name', 'name', 'start date', 'end date']

        courses.find_each do |c|
          row = []
          row << c.id
          row << c.sis_source_id
          row << c.course_code
          row << c.name

          if c.restrict_enrollments_to_course_dates
            row << default_timezone_format(c.start_at)
            row << default_timezone_format(c.conclude_at)
          else
            row << nil
            row << nil
          end

          csv << row
          i += 1

          if i % 5 == 0
            @account_report.update_attribute(:progress, (i.to_f/total)*100)
          end

        end
      end
      send_report(filename)

    end
  end

end
