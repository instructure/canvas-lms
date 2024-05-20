# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
  class LtiReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      @account_report.parameters ||= {}
      include_deleted_objects
    end

    def lti_report
      headers = %w[context_type
                   context_id
                   account_name
                   course_name
                   tool_id
                   tool_type_name
                   tool_type_id
                   tool_created_at
                   privacy_level
                   launch_url
                   custom_fields]

      write_report headers do |csv|
        courses = add_course_sub_account_scope(root_account.all_courses).joins(:account).select(:id)

        if @include_deleted
          course_join_condition = account_join_condition = ""
        else
          courses = courses.active.where.not(accounts: { workflow_state: "deleted" })
          course_join_condition = "AND courses.workflow_state<>'deleted'"
          account_join_condition = "AND accounts.workflow_state<>'deleted'"
        end

        tools = ContextExternalTool
                .where("context_type = 'Account' OR context_type = 'Course'")
                .joins("LEFT OUTER JOIN #{Course.quoted_table_name} ON context_id=courses.id
                                                             AND context_type='Course'
                                                             #{course_join_condition}",
                       "LEFT OUTER JOIN #{Account.quoted_table_name} ON context_id=accounts.id
                                                              AND context_type='Account'
                                                              #{account_join_condition}")
                .select("context_external_tools.*, courses.name AS course_name, accounts.name AS account_name")
        tools = tools.active unless @include_deleted

        subquery = ContextExternalTool.where(courses: { id: courses })
        subquery = if account.root_account?
                     subquery
                       .or(ContextExternalTool.where(accounts: { root_account_id: root_account }))
                       .or(ContextExternalTool.where(accounts: { id: root_account }))
                   else
                     subquery
                       .or(ContextExternalTool.where("accounts.id IN (#{Account.sub_account_ids_recursive_sql(account.id)})"))
                       .or(ContextExternalTool.where(accounts: { id: account }))
                   end
        tools = tools.merge(subquery)

        tools.find_each do |t|
          row = []
          row << t.context_type
          row << t.context_id
          row << t.account_name
          row << t.course_name
          row << t.id
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
