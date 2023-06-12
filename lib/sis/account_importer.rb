# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
      importer = Work.new(@batch, @root_account, @logger)
      Account.suspend_callbacks(:update_account_associations_if_changed) do
        Account.process_as_sis(@sis_options) do
          yield importer
        end
      end
      importer.accounts_to_set_sis_batch_ids.to_a.in_groups_of(1000, false) do |batch|
        Account.where(id: batch).update_all(sis_batch_id: @batch.id)
      end
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)

      importer.success_count
    end

    class Work
      attr_reader :success_count, :accounts_to_set_sis_batch_ids, :roll_back_data

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @accounts_cache = {}
        @roll_back_data = []
        @logger = logger
        @success_count = 0
        @accounts_to_set_sis_batch_ids = Set.new
      end

      def add_account(account_id, parent_account_id, status, name, integration_id)
        raise ImportError, "No account_id given for an account" if account_id.blank?
        return if @batch.skip_deletes? && status =~ /deleted/i

        parent = nil
        unless parent_account_id.blank?
          parent = @accounts_cache[parent_account_id]
          parent ||= @root_account.all_accounts.where(sis_source_id: parent_account_id).take
          raise ImportError, "Parent account didn't exist for #{account_id}" unless parent
          raise ImportError, "Cannot restore sub_account with ID: #{account_id} because parent_account with ID: #{parent_account_id} has been deleted." if parent.workflow_state == "deleted"

          @accounts_cache[parent.sis_source_id] = parent
        end

        account = @accounts_cache[account_id]
        account ||= @root_account.all_accounts.where(sis_source_id: account_id).take
        if account.nil?
          raise ImportError, "No name given for account #{account_id}, skipping" if name.blank?
          raise ImportError, "Improper status \"#{status}\" for account #{account_id}, skipping" unless /\A(active|deleted)/i.match?(status)
        end

        account ||= @root_account.sub_accounts.new

        account.root_account = @root_account
        if account.new_record? || !account.stuck_sis_fields.include?(:parent_account_id) || Account.sis_stickiness_options[:add_sis_stickiness]
          account.parent_account = parent || @root_account
        end

        # only update the name on new records, and ones that haven't been changed since the last sis import
        account.name = name if name.present? && (account.new_record? || !account.stuck_sis_fields.include?(:name))

        account.integration_id = integration_id
        account.sis_source_id = account_id

        if status.present?
          case status
          when /active/i
            account.workflow_state = "active"
          when /deleted/i
            raise ImportError, "Cannot delete the sub_account with ID: #{account_id} because it has active sub accounts." if account.sub_accounts.active.exists?
            raise ImportError, "Cannot delete the sub_account with ID: #{account_id} because it has active courses." if account.courses.active.exists?

            account.workflow_state = "deleted"
          end
        end

        @accounts_cache[account.sis_source_id] = account

        unless account.changed?
          @success_count += 1
          accounts_to_set_sis_batch_ids << account.id unless account.sis_batch_id == @batch.try(:id)
          return
        end

        account.sis_batch_id = @batch.id

        update_account_associations = account.root_account_id_changed? || account.parent_account_id_changed?
        if account.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: account)
          @roll_back_data << data if data
          if update_account_associations
            account.update_account_associations
            account.clear_downstream_caches(:account_chain)
          end

          @success_count += 1
        else
          raise ImportError, account.errors.first.last
        end
      end
    end
  end
end
