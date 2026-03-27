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
#

module SIS
  class InstitutionalTagCategoryImporter < BaseImporter
    def process
      importer = Work.new(@batch, @root_account, @logger)
      yield importer
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)
      importer.success_count
    end

    class Work
      attr_accessor :success_count, :roll_back_data

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0
        @roll_back_data = []
      end

      def add_institutional_tag_category(sis_id, name, description, status)
        raise ImportError, "Institutional tags are not enabled for this account" unless @root_account.feature_enabled?(:institutional_tags)

        raise ImportError, "No category_id given for an institutional tag category" if sis_id.blank?
        raise ImportError, "No name given for institutional tag category #{sis_id}" if name.blank?
        raise ImportError, "No status given for institutional tag category #{sis_id}" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for institutional tag category #{sis_id}" unless /\A(active|deleted)/i.match?(status)
        return if @batch.skip_deletes? && /deleted/i.match?(status)

        category = InstitutionalTagCategory.find_by(root_account_id: @root_account.id, sis_source_id: sis_id)
        category ||= InstitutionalTagCategory.new(account: @root_account,
                                                  root_account: @root_account,
                                                  sis_source_id: sis_id)

        category.name = name
        category.description = description
        category.sis_batch_id = @batch.id
        category.workflow_state = /deleted/i.match?(status) ? "deleted" : "active"

        if category.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: category)
          @roll_back_data << data if data
          @success_count += 1
          maybe_write_roll_back_data
        else
          msg = "An institutional tag category did not pass validation " \
                "(category: #{sis_id}, error: #{category.errors.full_messages.join(",")})"
          raise ImportError, msg
        end
      end

      private

      def maybe_write_roll_back_data
        return if @roll_back_data.count <= 1000

        SisBatchRollBackData.bulk_insert_roll_back_data(@roll_back_data)
        @roll_back_data = []
      end
    end
  end
end
