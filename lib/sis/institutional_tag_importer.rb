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
  class InstitutionalTagImporter < BaseImporter
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
        @categories_cache = {}
      end

      def add_institutional_tag(tag_id, category_id, name, description, status)
        raise ImportError, "Institutional tags are not enabled for this account" unless @root_account.feature_enabled?(:institutional_tags)

        raise ImportError, "No institutional_tag_id given for an institutional tag" if tag_id.blank?
        raise ImportError, "No category_id given for institutional tag #{tag_id}" if category_id.blank?
        raise ImportError, "No name given for institutional tag #{tag_id}" if name.blank?
        raise ImportError, "No description given for institutional tag #{tag_id}" if description.blank?
        raise ImportError, "No status given for institutional tag #{tag_id}" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for institutional tag #{tag_id}" unless /\A(active|deleted)/i.match?(status)
        return if @batch.skip_deletes? && /deleted/i.match?(status)

        category = @categories_cache[category_id]
        category ||= InstitutionalTagCategory.find_by(root_account_id: @root_account.id, sis_source_id: category_id)
        raise ImportError, "Category with id \"#{category_id}\" didn't exist for institutional tag #{tag_id}" unless category

        @categories_cache[category_id] = category

        tag = InstitutionalTag.find_by(root_account_id: @root_account.id, sis_source_id: tag_id)
        tag ||= InstitutionalTag.new(category:,
                                     root_account: @root_account,
                                     sis_source_id: tag_id)

        tag.name = name
        tag.description = description
        tag.sis_batch_id = @batch.id
        tag.workflow_state = /deleted/i.match?(status) ? "deleted" : "active"

        if tag.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: tag)
          @roll_back_data << data if data
          @success_count += 1
          maybe_write_roll_back_data
        else
          msg = "An institutional tag did not pass validation " \
                "(tag: #{tag_id}, error: #{tag.errors.full_messages.join(",")})"
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
