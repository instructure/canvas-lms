# frozen_string_literal: true

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
        @accounts_cache = {}
        @courses_cache = {}
      end

      def invalid_category?(sis_id, name, status, type_display)
        raise ImportError, "No sis_id given for a #{type_display}" if sis_id.blank?
        raise ImportError, "No name given for #{type_display} #{sis_id}" if name.blank?
        raise ImportError, "No status given for #{type_display} #{sis_id}" if status.blank?
        raise ImportError, "Improper status \"#{status}\" for #{type_display} #{sis_id}, skipping" unless /\A(active|deleted)/i.match?(status)
        return true if @batch.skip_deletes? && status =~ /deleted/i

        false
      end

      def find_context(account_id, course_id, sis_id, type_display)
        context = nil
        if account_id && course_id
          raise ImportError, "Only one context is allowed and both course_id and account_id where provided for #{type_display} #{sis_id}."
        end

        if account_id
          context = @accounts_cache[account_id]
          context ||= @root_account.all_accounts.active.find_by(sis_source_id: account_id)
          raise ImportError, "Account with id \"#{account_id}\" didn't exist for #{type_display} #{sis_id}" unless context

          @accounts_cache[context.sis_source_id] = context
        end

        if course_id
          context = @courses_cache[course_id]
          context ||= @root_account.all_courses.active.find_by(sis_source_id: course_id)
          raise ImportError, "Course with id \"#{course_id}\" didn't exist for #{type_display} #{sis_id}" unless context

          @courses_cache[context.sis_source_id] = context
        elsif course_id.nil? && type_display == "differentiation tag set"
          raise ImportError, "No course_id given for #{type_display} #{sis_id}"
        end

        context || @root_account
      end

      def check_context_movement(category, context, sis_id, type_display)
        if category && category.groups.active.exists? &&
           !(context.id == category.context_id && context.class.base_class.name == category.context_type)

          item_type = type_display.include?("tag") ? "tags" : "groups"

          raise ImportError, "Cannot move #{type_display} #{sis_id} because it has #{item_type} in it."
        end
      end

      def apply_status(category, status)
        case status
        when /active/i
          category.deleted_at = nil
        when /deleted/i
          category.deleted_at = Time.zone.now
        end
      end

      def save_category(category, sis_id, type_display)
        if category.save
          data = build_data(category)
          @roll_back_data << data if data
          @success_count += 1
          true
        else
          msg = "A #{type_display} did not pass validation (#{type_display}: #{sis_id}, error: "
          msg += category.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

      def add_group_category(sis_id, account_id, course_id, category_name, status)
        return if invalid_category?(sis_id, category_name, status, "group category")

        context = find_context(account_id, course_id, sis_id, "group category")
        gc = @root_account.all_group_categories.find_by(sis_source_id: sis_id)

        check_context_movement(gc, context, sis_id, "group category")

        gc ||= context.group_categories.new
        gc.name = category_name
        gc.context = context
        gc.root_account_id = @root_account.id
        gc.sis_source_id = sis_id
        gc.sis_batch_id = @batch.id

        apply_status(gc, status)
        save_category(gc, sis_id, "group category")
      end

      def add_differentiation_tag_set(sis_id, course_id, set_name, status)
        return if invalid_category?(sis_id, set_name, status, "differentiation tag set")

        context = find_context(nil, course_id, sis_id, "differentiation tag set")
        raise ImportError, "Differentiation Tags are not enabled for Account #{context.account.id}." unless context.account.allow_assign_to_differentiation_tags?

        tag_set = @root_account.all_differentiation_tag_categories.find_by(sis_source_id: sis_id)

        check_context_movement(tag_set, context, sis_id, "differentiation tag set")

        tag_set ||= context.differentiation_tag_categories.new
        tag_set.name = set_name
        tag_set.context = context
        tag_set.root_account_id = @root_account.id
        tag_set.sis_source_id = sis_id
        tag_set.non_collaborative = true
        tag_set.sis_batch_id = @batch.id

        apply_status(tag_set, status)
        save_category(tag_set, sis_id, "differentiation tag set")
      end

      def build_data(category)
        return unless should_build_roll_back_data?(category)

        @batch.roll_back_data.build(context: category,
                                    previous_workflow_state: old_status(category),
                                    updated_workflow_state: current_status(category),
                                    created_at: Time.zone.now,
                                    updated_at: Time.zone.now,
                                    batch_mode_delete: false,
                                    workflow_state: "active")
      end

      def should_build_roll_back_data?(category)
        return true if category.previously_new_record? || category.saved_change_to_deleted_at?

        false
      end

      def old_status(category)
        if category.previously_new_record?
          "non-existent"
        elsif category.deleted_at_before_last_save.nil?
          category.deleted_at.nil? ? nil : "active"
        elsif !category.deleted_at_before_last_save.nil?
          "deleted"
        end
      end

      def current_status(category)
        category.deleted_at.nil? ? "active" : "deleted"
      end
    end
  end
end
