# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
  class EportfolioReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      include_deleted_objects
    end

    EPORTFOLIO_REPORT_HEADERS = %w[
      eportfolio_name
      eportfolio_id
      author_name
      author_id
      author_sis_id
      author_login_id
      created_at
      updated_at
      is_public
      workflow_state
    ].freeze

    def eportfolio_report
      add_extra_text(I18n.t("Only users with no enrollments")) if only_users_with_no_enrollments?

      write_report EPORTFOLIO_REPORT_HEADERS do |csv|
        eportfolio_scope.select("eportfolios.*, users.name AS user_name, pseudonyms.sis_user_id, pseudonyms.unique_id").find_each do |e|
          csv <<
            [
              e.name,
              e.id,
              e.user_name,
              e.user_id,
              e.sis_user_id,
              e.unique_id,
              e.created_at.to_s,
              e.updated_at.to_s,
              e.public.to_s,
              e.workflow_state
            ]
        end
      end
    end

    private

    def only_users_with_no_enrollments?
      if @account_report.value_for_param "no_enrollments"
        return value_to_boolean(@account_report.parameters["no_enrollments"])
      end

      false
    end

    def no_enrollment_sql
      "NOT EXISTS (SELECT e.user_id
                   FROM #{Enrollment.quoted_table_name} e
                   WHERE e.user_id = eportfolios.user_id)"
    end

    def eportfolio_scope
      scope = Eportfolio.joins(user: :pseudonyms)
                        .where(pseudonyms: { account_id: root_account.id })
                        .where.not(users: { workflow_state: "deleted" })

      scope = @include_deleted ? scope.deleted : scope.active
      scope = scope.where(no_enrollment_sql) if only_users_with_no_enrollments?

      scope
    end
  end
end
