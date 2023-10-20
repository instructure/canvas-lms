# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
#
# This file is part of Canvas.
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

module AccountReports
  class DeveloperKeyReports
    include ReportHelper

    attr_reader :account_report

    def initialize(account_report)
      @account_report = account_report
    end

    DEV_KEY_REPORT_HEADERS = [
      "Global ID",
      "Key Name",
      "Inherited from Parent Account",
      "Contact Info",
      "Key Type",
      "Placements",
      "Status",
      "Permitted API Endpoints"
    ].freeze

    def dev_key_report
      write_report DEV_KEY_REPORT_HEADERS do |csv|
        account_dev_keys.find_each do |key|
          write_key(csv, key)
        end
        visible_site_admin_keys.find_each do |key|
          write_key(csv, key)
        end
        consortia_parent_keys&.find_each do |key|
          write_key(csv, key)
        end
      end
    end

    private

    def write_key(csv, key)
      row = []
      row << key.global_id
      row << key.name
      row << (key.account != account)
      row << key.email
      row << (key.is_lti_key ? "LTI Key" : "API Key")
      row << (key.tool_configuration&.placements&.pluck("placement").presence || "None")
      row << (key.account_binding_for(account)&.workflow_state&.capitalize.presence || "Allow")
      row << (key.scopes.presence || "All")
      csv << row
    end

    def dev_key_scope
      DeveloperKey.nondeleted.eager_load(:tool_configuration)
    end

    def account
      @account ||= account_report.context
    end

    # Some older account keys within prod Canvas can be marked as not visible. However,
    # the API still shows these keys, as admins created them in the first place. The report should behave
    # the same as the API.
    def account_dev_keys
      dev_key_scope.where(account:)
    end

    def visible_site_admin_keys
      Account.site_admin.shard.activate do
        dev_key_scope.visible.site_admin
      end
    end

    def consortia_parent_keys
      return nil if account.primary_settings_root_account?

      federated_parent = account.account_chain(include_federated_parent: true).last
      dev_key_scope.visible.shard(federated_parent.shard).where(account: federated_parent)
    end
  end
end
