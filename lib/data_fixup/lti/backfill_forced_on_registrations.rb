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
  class Lti::BackfillForcedOnRegistrations < CanvasOperations::DataFixup
    self.mode              = :individual_record
    self.progress_tracking = false
    self.record_changes    = true

    scope do
      unless Account.site_admin_exists?
        log_message("Site admin does not exist, skipping backfill", level: :warn)
        next Account.none
      end
      template_regs = forced_on_registrations
      if template_regs.empty?
        log_message("No forced-on registrations found, skipping backfill", level: :warn)
        next Account.none
      end

      copies_exist = ::Lti::Registration
                     .active
                     .where(
                       ::Lti::Registration.arel_table[:account_id]
                         .eq(Account.arel_table[:id])
                     )
                     .where(template_registration: template_regs)

      Account.root_accounts
             .active
             .non_shadow
             .where.not(copies_exist.arel.exists)
    end

    def process_record(account)
      return if account.site_admin?

      results = []

      forced_on_registrations.each do |registration|
        ::Lti::InstallTemplateRegistrationService.call(
          template: registration,
          account:,
          create_tool: false
        ) => { local_copy: }

        results << [local_copy.global_id, registration.global_id, account.global_id]
      rescue => e
        Sentry.with_scope do |scope|
          scope.set_tags(account_id: account.global_id,
                         registration_id: registration.global_id)
          Sentry.capture_exception(e)
        end
      end

      results
    end

    private

    # Returns all active site admin registrations whose binding at the site
    # admin account level has workflow_state = 'on' (forced on for everyone).
    # Memoized so the site admin shard is only activated once per fixup run.
    def forced_on_registrations
      @forced_on_registrations ||= GuardRail.activate(:secondary) do
        Account.site_admin.shard.activate do
          ::Lti::RegistrationAccountBinding
            .where(workflow_state: :on, account: Account.site_admin)
            .left_outer_joins(registration: :ims_registration)
            .where(lti_ims_registrations: { id: nil })
            .merge(::Lti::Registration.active)
            .preload(registration: [:ims_registration, :manual_configuration])
            .filter_map(&:registration)
        end
      end
    end
  end
end
