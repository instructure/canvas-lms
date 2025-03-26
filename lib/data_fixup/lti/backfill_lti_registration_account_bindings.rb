# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::Lti::BackfillLtiRegistrationAccountBindings
  def self.run
    DeveloperKeyAccountBinding.joins(developer_key: :lti_registration)
                              .where.missing(:lti_registration_account_binding)
                              .find_each do |account_binding|
      next unless account_binding.account.root_account?

      Lti::RegistrationAccountBinding.create!(
        account: account_binding.account,
        registration: account_binding.developer_key.lti_registration,
        developer_key_account_binding: account_binding,
        workflow_state: account_binding.workflow_state
      )
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(developer_key_account_binding_id: account_binding.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("DataFixup#backfill_lti_registration_account_bindings", level: :warning)
      end
    end
  end
end
