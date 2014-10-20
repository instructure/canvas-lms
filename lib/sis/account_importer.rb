#
# Copyright (C) 2011 Instructure, Inc.
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

module SIS
  class AccountImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      Account.suspend_callbacks(:update_account_associations_if_changed) do
        Account.process_as_sis(@sis_options) do
          yield importer
        end
      end
      @logger.debug("Accounts took #{Time.now - start} seconds")
      return importer.success_count
    end

  private

    class Work
      attr_accessor :success_count

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @accounts_cache = {}
        @logger = logger
        @success_count = 0
      end

      def add_account(account_id, parent_account_id, status, name, integration_id)
        @logger.debug("Processing Account #{[account_id, parent_account_id, status, name].inspect}")

        raise ImportError, "No account_id given for an account" if account_id.blank?

        parent = nil
        if !parent_account_id.blank?
          parent = @accounts_cache[parent_account_id]
          parent ||= @root_account.all_accounts.where(sis_source_id: parent_account_id).first
          raise ImportError, "Parent account didn't exist for #{account_id}" unless parent
          @accounts_cache[parent.sis_source_id] = parent
        end

        account = @root_account.all_accounts.where(sis_source_id: account_id).first
        if account.nil?
          raise ImportError, "No name given for account #{account_id}, skipping" if name.blank?
          raise ImportError, "Improper status \"#{status}\" for account #{account_id}, skipping" unless status =~ /\A(active|deleted)/i
        end

        account ||= @root_account.sub_accounts.new

        account.root_account = @root_account
        account.parent_account = parent ? parent : @root_account

        # only update the name on new records, and ones that haven't been changed since the last sis import
        account.name = name if name.present? && (account.new_record? || (!account.stuck_sis_fields.include?(:name)))

        account.integration_id = integration_id
        account.sis_source_id = account_id
        account.sis_batch_id = @batch.id if @batch

        if status.present?
          if status =~ /active/i
            account.workflow_state = 'active'
          elsif status =~ /deleted/i
            account.workflow_state = 'deleted'
          end
        end

        update_account_associations = account.root_account_id_changed? || account.parent_account_id_changed?
        if account.save
          account.update_account_associations if update_account_associations
          @accounts_cache[account.sis_source_id] = account

          @success_count += 1
        else
          raise ImportError, account.errors.first.last
        end
      end
    end
  end
end
