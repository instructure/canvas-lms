#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class GroupCategoryImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      yield importer
      @logger.debug("Group categories took #{Time.now - start} seconds")
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

      def add_group_category(sis_id, account_id, category_name, status)
        raise ImportError, "No sis_id given for a group category" if sis_id.blank?
        raise ImportError, "No name given for group category #{sis_id}" if category_name.blank?
        raise ImportError, "No status given for group category #{sis_id}" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for group category #{sis_id}, skipping" unless status =~ /\A(active|deleted)/i

        @logger.debug("Processing Group Category #{[sis_id, account_id, category_name, status].inspect}")

        account = nil
        if account_id.present?
          account = @accounts_cache[account_id]
          account ||= @root_account.all_accounts.where(sis_source_id: account_id).take
          raise ImportError, "Account with id \"#{account_id}\" didn't exist for group category #{sis_id}" unless account
          @accounts_cache[account.sis_source_id] = account
        end
        account ||= @root_account

        gc = @root_account.all_group_categories.where(sis_source_id: sis_id).take
        gc ||= account.group_categories.new
        gc.name = category_name
        gc.context = account
        gc.root_account_id = @root_account.id
        gc.sis_source_id = sis_id
        gc.sis_batch_id = @batch.id if @batch

        case status
        when /active/i
          gc.deleted_at = nil
        when /deleted/i
          gc.deleted_at = Time.zone.now
        end

        if gc.save
          @success_count += 1
        else
          msg = "A group category did not pass validation (group category: #{sis_id}, error: "
          msg += gc.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

    end

  end
end
