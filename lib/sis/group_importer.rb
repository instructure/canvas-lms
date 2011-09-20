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
  # note these are account-level groups, not course groups
  class GroupImporter < SisImporter
    def self.is_group_csv?(row)
      row.header?('group_id') && row.header?('account_id')
    end

    def verify(csv, verify)
      group_ids = (verify[:group_ids] ||= {})
      csv_rows(csv) do |row|
        group_id = row['group_id']
        add_error(csv, "Duplicate group id #{group_id}") if group_ids[group_id]
        group_ids[group_id] = true
        add_error(csv, "No group_id given for a group") if row['group_id'].blank?
      end
    end

    # expected columns
    # group_id,account_id,name,status
    def process(csv)
      start = Time.now
      accounts_cache = {}

      csv_rows(csv) do |row|
        update_progress
        logger.debug("Processing Group #{row.inspect}")

        account = nil
        if row['account_id'].present?
          account = accounts_cache[row['account_id']]
          account ||= Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['account_id'])
          unless account
            add_warning(csv, "Parent account didn't exist for #{row['account_id']}")
            next
          end
          accounts_cache[account.sis_source_id] = account
        end
        account ||= @root_account

        group = Group.first(:conditions => {
          :root_account_id => @root_account,
          :sis_source_id => row['group_id'] })

        if group.nil?
          abort = false
          if row['name'].blank?
            add_warning(csv, "No name given for group #{row['group_id']}, skipping")
            abort = true
          end
          unless row['status'] =~ /\A(available|closed|completed|deleted)/i
            add_warning(csv, "Improper status \"#{row['status']}\" for group #{row['group_id']}, skipping")
            abort = true
          end
          next if abort
        end

        group ||= account.groups.new
        # only update the name on new records, and ones that haven't had their name changed since the last sis import
        if row['name'].present? && (group.new_record? || (group.sis_name && group.sis_name == group.name))
          group.name = group.sis_name = row['name']
        end

        # must set .context, not just .account, since these are account-level groups
        group.context = account
        group.sis_source_id = row['group_id']
        group.sis_batch_id = @batch.try(:id)

        case row['status']
        when /available/i
          group.workflow_state = 'available'
        when /closed/i
          group.workflow_state = 'closed'
        when /completed/i
          group.workflow_state = 'completed'
        when /deleted/i
          group.workflow_state = 'deleted'
        end

        group.save
        @sis.counts[:groups] += 1
      end

      logger.debug("Groups took #{Time.now - start} seconds")
    end
  end
end
