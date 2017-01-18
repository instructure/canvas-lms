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
  class GroupImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      Group.process_as_sis(@sis_options) do
        yield importer
      end
      @logger.debug("Groups took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0
        @accounts_cache = {}
      end

      def add_group(group_id, account_id, name, status)
        raise ImportError, "No group_id given for a group" unless group_id.present?

        @logger.debug("Processing Group #{[group_id, account_id, name, status].inspect}")

        account = nil
        if account_id.present?
          account = @accounts_cache[account_id]
          account ||= @root_account.all_accounts.where(sis_source_id: account_id).take
          raise ImportError, "Parent account didn't exist for #{account_id}" unless account
          @accounts_cache[account.sis_source_id] = account
        end
        account ||= @root_account

        group = @root_account.all_groups.where(sis_source_id: group_id).take
        unless group
          raise ImportError, "No name given for group #{group_id}, skipping" if name.blank?
          raise ImportError, "Improper status \"#{status}\" for group #{group_id}, skipping" unless status =~ /\A(available|closed|completed|deleted)/i
        end

        group ||= account.groups.new
        # only update the name on new records, and ones that haven't had their name changed since the last sis import
        group.name = name if name.present? && (group.new_record? || (!group.stuck_sis_fields.include?(:name)))

        # must set .context, not just .account, since these are account-level groups
        group.context = account
        group.sis_source_id = group_id
        group.sis_batch_id = @batch.id if @batch

        # closed and completed are no longer valid states. Leaving these for
        # backwards compatibility. It is not longer a documented status
        case status
        when /available/i
          group.workflow_state = 'available'
        when /closed/i
          group.workflow_state = 'available'
        when /completed/i
          group.workflow_state = 'available'
        when /deleted/i
          group.workflow_state = 'deleted'
        end

        if group.save
          @success_count += 1
        else
          msg = "A group did not pass validation "
          msg += "(" + "group: #{group_id}, error: " + 
          msg += group.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

    end

  end
end
