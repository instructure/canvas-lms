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
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger)
      yield importer
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data) if @batch.using_parallel_importers?
      @logger.debug("Group categories took #{Time.zone.now - start} seconds")
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
        @accounts_cache = {}
      end

      def add_group_category(sis_id, account_id, course_id, category_name, status)
        raise ImportError, "No sis_id given for a group category" if sis_id.blank?
        raise ImportError, "No name given for group category #{sis_id}" if category_name.blank?
        raise ImportError, "No status given for group category #{sis_id}" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for group category #{sis_id}, skipping" unless status =~ /\A(active|deleted)/i
        return if @batch.skip_deletes? && status =~ /deleted/i

        if course_id && account_id
          raise ImportError, "Only one context is allowed and both course_id and account_id where provided for group category #{sis_id}."
        end

        @logger.debug("Processing Group Category #{[sis_id, account_id, course_id, category_name, status].inspect}")

        context = nil
        if account_id
          context = @accounts_cache[account_id]
          context ||= @root_account.all_accounts.active.where(sis_source_id: account_id).take
          raise ImportError, "Account with id \"#{account_id}\" didn't exist for group category #{sis_id}" unless context
          @accounts_cache[context.sis_source_id] = context
        end

        if course_id
          context = @root_account.all_courses.active.where(sis_source_id: course_id).take
          raise ImportError, "Course with id \"#{course_id}\" didn't exist for group category #{sis_id}" unless context
        end
        context ||= @root_account

        gc = @root_account.all_group_categories.where(sis_source_id: sis_id).take

        if gc && gc.groups.active.exists?
          raise ImportError, "Cannot move group category #{sis_id} because it has groups in it." unless context.id == gc.context_id && context.class.base_class.name == gc.context_type
        end

        gc ||= context.group_categories.new
        gc.name = category_name
        gc.context = context
        gc.root_account_id = @root_account.id
        gc.sis_source_id = sis_id
        gc.sis_batch_id = @batch.id

        case status
        when /active/i
          gc.deleted_at = nil
        when /deleted/i
          gc.deleted_at = Time.zone.now
        end

        if gc.save
          data = build_data(gc)
          @roll_back_data << data if data
          @success_count += 1
        else
          msg = "A group category did not pass validation (group category: #{sis_id}, error: "
          msg += gc.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

      def build_data(group_category)
        return unless should_build_roll_back_data?(group_category)
        @batch.roll_back_data.build(context: group_category,
                                    previous_workflow_state: old_status(group_category),
                                    updated_workflow_state: current_status(group_category),
                                    created_at: Time.zone.now,
                                    updated_at: Time.zone.now,
                                    batch_mode_delete: false,
                                    workflow_state: 'active')
      end

      def should_build_roll_back_data?(group_category)
        return false unless @batch.using_parallel_importers?
        return true if group_category.id_before_last_save.nil?
        return true if group_category.saved_change_to_deleted_at?
        false
      end

      def old_status(group_category)
        if group_category.id_before_last_save.nil?
          'non-existent'
        elsif group_category.deleted_at_before_last_save.nil?
          group_category.deleted_at.nil? ? nil : 'active'
        elsif !group_category.deleted_at_before_last_save.nil?
          'deleted'
        end
      end

      def current_status(group_category)
        group_category.deleted_at.nil? ? 'active' : 'deleted'
      end

    end

  end
end
