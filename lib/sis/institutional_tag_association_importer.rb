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
  class InstitutionalTagAssociationImporter < BaseImporter
    BATCH_SIZE = 1000

    def process(messages)
      importer = Work.new(@batch, @root_account, @logger, messages)
      yield importer
      while importer.any_left_to_process?
        importer.process_batch
      end
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)
      importer.success_count
    end

    class Work
      attr_accessor :success_count, :roll_back_data

      def initialize(batch, root_account, logger, messages)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @messages = messages
        @success_count = 0
        @roll_back_data = []
        @tags_cache = {}
        @association_batch = []
      end

      def add_institutional_tag_association(tag_id, user_id, status, csv: nil, lineno: nil, row_info: nil)
        raise ImportError, "Institutional tags are not enabled for this account" unless @root_account.feature_enabled?(:institutional_tags)

        raise ImportError, "No institutional_tag_id given for an institutional tag association" if tag_id.blank?
        raise ImportError, "No user_id given for institutional tag association with tag #{tag_id}" if user_id.blank?
        raise ImportError, "No status given for institutional tag association (tag: #{tag_id}, user: #{user_id})" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for institutional tag association (tag: #{tag_id}, user: #{user_id})" unless /\A(active|deleted)/i.match?(status)
        return if @batch.skip_deletes? && /deleted/i.match?(status)

        @association_batch << { tag_id:, user_id:, status:, csv:, lineno:, row_info: }
        process_batch if @association_batch.size >= BATCH_SIZE
      end

      def any_left_to_process?
        @association_batch.any?
      end

      def process_batch
        return unless any_left_to_process?

        batch = @association_batch.shift(BATCH_SIZE)

        user_ids = batch.map { |r| r[:user_id] }.uniq # rubocop:disable Rails/Pluck
        pseudos_by_sis_id = @root_account.pseudonyms.where(sis_user_id: user_ids).preload(:user).index_by(&:sis_user_id)

        batch.each do |row|
          tag_id = row[:tag_id]
          user_id = row[:user_id]

          pseudo = pseudos_by_sis_id[user_id]
          unless pseudo
            @messages << SisBatch.build_error(row[:csv], "User with sis_user_id \"#{user_id}\" didn't exist for institutional tag association with tag #{tag_id}", sis_batch: @batch, row: row[:lineno], row_info: row[:row_info])
            next
          end

          user = pseudo.user

          tag = @tags_cache[tag_id]
          tag ||= InstitutionalTag.find_by(root_account_id: @root_account.id, sis_source_id: tag_id)
          unless tag
            @messages << SisBatch.build_error(row[:csv], "Institutional tag with id \"#{tag_id}\" didn't exist", sis_batch: @batch, row: row[:lineno], row_info: row[:row_info])
            next
          end

          @tags_cache[tag_id] = tag

          assoc = InstitutionalTagAssociation.find_or_initialize_by(institutional_tag: tag, context: user)
          assoc.sis_batch_id = @batch.id
          assoc.root_account_id = @root_account.id
          assoc.workflow_state = /deleted/i.match?(row[:status]) ? "deleted" : "active"

          if assoc.save
            data = SisBatchRollBackData.build_data(sis_batch: @batch, context: assoc)
            @roll_back_data << data if data
            @success_count += 1
          else
            msg = "An institutional tag association did not pass validation " \
                  "(tag: #{tag_id}, user: #{user_id}, error: #{assoc.errors.full_messages.join(",")})"
            @messages << SisBatch.build_error(row[:csv], msg, sis_batch: @batch, row: row[:lineno], row_info: row[:row_info])
          end
        end
        maybe_write_roll_back_data
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
