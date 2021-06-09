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

require 'account_reports/report_helper'

module AccountReports
  class EportfolioReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      include_deleted_objects
    end

    EPORTFOLIO_REPORT_HEADERS = [
      I18n.t('eportfolio_name'),
      I18n.t('eportfolio_id'),
      I18n.t('author_name'),
      I18n.t('author_id'),
      I18n.t('author_sis_id'),
      I18n.t('author_login_id'),
      I18n.t('created_at'),
      I18n.t('updated_at'),
      I18n.t('is_public'),
      I18n.t('workflow_state')
    ].freeze

    def eportfolio_report
      if include_users_with_no_enrollments?
        add_extra_text(I18n.t('Include users with no enrollments'))
      end

      write_report EPORTFOLIO_REPORT_HEADERS do |csv|
        eportfolio_scope.find_in_batches do |batch|
          users = batch.map {|e| User.new(id: e.user_id)}.compact
          users.uniq!
          users_by_id = users.index_by(&:id)
          pseudonyms = preload_logins_for_users(users, include_deleted: @include_deleted)

          batch.each do |e|
            pseudonym = loaded_pseudonym(pseudonyms,
                                         users_by_id[e.user_id],
                                         include_deleted: @include_deleted)
            csv <<
              [
                e.name,
                e.id,
                e.user.name,
                e.user_id,
                pseudonym.sis_user_id,
                pseudonym.unique_id,
                e.created_at.to_s,
                e.updated_at.to_s,
                e.public.to_s,
                e.workflow_state
              ]
          end
        end
      end
    end

    private

    def include_users_with_no_enrollments?
      if @account_report.value_for_param 'no_enrollments'
        return value_to_boolean(@account_report.parameters['no_enrollments'])
      end

      false
    end

    def no_enrollment_scope
      User.joins(:pseudonyms).joins(
        "LEFT JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id = users.id"
      )
        .select('DISTINCT(users.id)')
        .where('enrollments.id IS NULL')
        .where("users.workflow_state != 'deleted'")
        .where('pseudonyms.account_id = ?', root_account.id)
    end

    def all_user_scope
      User.joins(:pseudonyms).select('DISTINCT(users.id)').where(
        "users.workflow_state != 'deleted'"
      )
        .where('pseudonyms.account_id = ?', root_account.id)
    end

    def eportfolio_scope
      # default active scope
      scope = Eportfolio.active.where(user_id: all_user_scope)
      # default deleted scope
      scope = Eportfolio.deleted.where(user_id: all_user_scope) if @include_deleted
      if include_users_with_no_enrollments? && @include_deleted
        # use deleted scope
        scope = scope.where(user_id: no_enrollment_scope)
      elsif include_users_with_no_enrollments?
        # use active scope
        scope = scope.where(user_id: no_enrollment_scope)
      end

      scope
    end
  end
end
