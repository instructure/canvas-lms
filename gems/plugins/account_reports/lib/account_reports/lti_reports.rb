#
# Copyright (C) 2013 - 2016 Instructure, Inc.
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

require 'account_reports/report_helper'

module AccountReports

  class LtiReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      @account_report.parameters ||= {}
    end

    def lti_report
      headers = ['context_type', 'context_id', 'account_name', 'course_name', 'tool_type_name',
                 'tool_type_id', 'tool_created_at', 'privacy_level', 'launch_url', 'custom_fields']

      write_report headers do |csv|
        courses = add_course_sub_account_scope(root_account.all_courses.active)
        courses = courses.joins(:account).where.not(accounts: {workflow_state: 'deleted'}).select(:id)

        tools = ContextExternalTool.active.
          where("context_type = 'Account' OR context_type = 'Course'").
          joins("LEFT OUTER JOIN #{Course.quoted_table_name} ON context_id=courses.id
                                                             AND context_type='Course'
                                                             AND courses.workflow_state<>'deleted'",
                "LEFT OUTER JOIN #{Account.quoted_table_name} ON context_id=accounts.id
                                                              AND context_type='Account'
                                                              AND accounts.workflow_state<>'deleted'").
          select("context_external_tools.*, courses.name AS course_name, accounts.name AS account_name")
        if account.root_account?
          tools.where!("courses.id IN (:courses) OR
                        accounts.root_account_id = :root OR accounts.id = :root", {root: root_account, courses: courses})
        else
          tools.where!("accounts.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})
                        OR accounts.id=?
                        OR courses.id IN (?)", account, courses)
        end

        tools.find_each do |t|
          row = []
          row << t.context_type
          row << t.context_id
          row << t.account_name
          row << t.course_name
          row << t.name
          row << t.tool_id
          row << t.created_at
          row << t.privacy_level
          row << t.url
          row << t.custom_fields
          csv << row
        end
      end
    end
  end
end
