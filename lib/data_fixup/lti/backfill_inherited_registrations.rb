# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module DataFixup
  class Lti::BackfillInheritedRegistrations < CanvasOperations::DataFixup
    self.mode              = :individual_record
    self.progress_tracking = false
    self.record_changes    = true

    scope do
      unless Account.site_admin_exists?
        log_message("Site admin account does not exist, nothing can be backfilled")
        next Account.none
      end

      reg_table     = ::Lti::Registration.quoted_table_name
      binding_table = ::Lti::RegistrationAccountBinding.quoted_table_name

      not_exists_sql = <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM #{reg_table} local_copy
          WHERE local_copy.template_registration_id = #{binding_table}.registration_id
            AND local_copy.account_id = #{binding_table}.account_id
            AND local_copy.workflow_state != 'deleted'
        )
      SQL

      base = ::Lti::RegistrationAccountBinding
             .where(workflow_state: :on)
             .where(not_exists_sql)
             .preload(:account, registration: [:ims_registration, :manual_configuration])

      if Shard.current == Account.site_admin.shard
        # Same-shard topology (OSS / site admin on default shard):
        # join directly on account_id to find site admin registrations
        # and exclude bindings for the site admin account itself.
        site_admin_id = Account.site_admin.local_id.to_i
        base
          .where.not(account_id: site_admin_id)
          .joins(<<~SQL.squish)
            INNER JOIN #{reg_table} r
              ON r.id = #{binding_table}.registration_id
              AND r.account_id = #{site_admin_id}
              AND r.workflow_state != 'deleted'
          SQL
      else
        # Cross-shard topology (production): site admin registrations have
        # global IDs whose shard component encodes the site admin shard.
        sa_shard_id = Account.site_admin.shard.id
        min_id      = sa_shard_id * Shard::IDS_PER_SHARD
        max_id      = ((sa_shard_id + 1) * Shard::IDS_PER_SHARD) - 1
        base.where(registration_id: min_id..max_id)
      end
    end

    def process_record(binding)
      return if binding.registration.dynamic_registration?
      return unless binding.registration.active?

      ::Lti::InstallTemplateRegistrationService.call(
        template: binding.registration,
        account: binding.account,
        create_tool: false
      ) => { local_copy: }

      [local_copy.global_id, binding.registration.global_id, binding.account.global_id]
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(binding_id: binding.global_id,
                       registration_id: binding.registration&.global_id)
        Sentry.capture_exception(e)
      end
    end
  end
end
