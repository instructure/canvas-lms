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
  class GroupImporter < BaseImporter
    def process
      importer = Work.new(@batch, @root_account, @logger)
      Group.process_as_sis(@sis_options) do
        yield importer
      end
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

      private

      def type_display_name(type)
        type.tr("_", " ")
      end

      def invalid_import_item?(id, name, status, type)
        raise ImportError, "No #{(type == "group") ? type : "tag"}_id given for a #{type_display_name(type)}." unless id
        raise ImportError, "No name given for #{type_display_name(type)} #{id}." if name.blank?
        raise ImportError, "Improper status \"#{status}\" for #{type_display_name(type)} #{id}." unless /\A(available|closed|completed|deleted)/i.match?(status)
        return true if @batch.skip_deletes? && status =~ /deleted/i

        false
      end

      def find_context(id, id_type, type, item_id)
        context = nil
        cache = (id_type == :course_id) ? @courses_cache : @accounts_cache

        if id
          context = cache[id]
          context ||= if id_type == :course_id
                        @root_account.all_courses.active.find_by(sis_source_id: id)
                      else
                        @root_account.all_accounts.active.find_by(sis_source_id: id)
                      end

          unless context
            raise ImportError, "#{id_type.to_s.sub("_id", "").titleize} with sis id #{id} didn't exist for #{type_display_name(type)} #{item_id}."
          end

          cache[context.sis_source_id] = context if context
        end

        context
      end

      def find_category(category_id, context, category_type, item_type, item_id)
        return nil unless category_id.present?

        category_display_name = if category_type.to_s == "differentiation_tag_category"
                                  "Differentiation Tag Set"
                                else
                                  "Group Category"
                                end

        category = nil
        if context
          category = context.send(category_type.to_s.pluralize).find_by(sis_source_id: category_id)
          unless category
            context_name = context.class.name.downcase
            raise ImportError, "#{category_display_name} #{category_id} didn't exist in #{context_name} #{context.sis_source_id} for #{type_display_name(item_type)} #{item_id}."
          end
        else
          method_name = "all_#{category_type.to_s.pluralize}"
          category = @root_account.send(method_name).find_by(deleted_at: nil, sis_source_id: category_id)
          unless category
            raise ImportError, "#{category_display_name} #{category_id} didn't exist for #{type_display_name(item_type)} #{item_id}."
          end
        end

        category
      end

      def save_and_process_memberships(item, item_type, status)
        if item.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: item)
          @roll_back_data << data if data

          if status == "deleted"
            gms = SisBatchRollBackData.build_dependent_data(
              sis_batch: @batch,
              contexts: item.group_memberships,
              updated_state: "deleted"
            )
            @roll_back_data.push(*gms) if gms
          end

          @success_count += 1
          true
        else
          msg = "A #{type_display_name(item_type)} did not pass validation "
          msg += "(" + "#{item_type}: #{item.sis_source_id}, error: "
          msg += item.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

      def can_change_context?(item, new_context, item_type, item_id)
        if item_type == "differentiation_tag"
          raise ImportError, "Differentiation Tags are not enabled for Account #{context.account.id}." unless new_context.account.allow_assign_to_differentiation_tags?
        end

        return true unless item&.group_memberships&.exists?

        same_context = new_context.id == item.context_id &&
                       new_context.class.base_class.name == item.context_type

        # For groups, we only block moves between courses, but allow other context changes
        if !same_context &&
           ((item.context.is_a?(Course) || new_context.is_a?(Course)) || item_type == "differentiation_tag")
          raise ImportError, "Cannot move #{type_display_name(item_type)} #{item_id} because it has #{item_type}_memberships."
        end

        true
      end

      public

      def add_group(group_id, group_category_id, account_id, course_id, name, status)
        return if invalid_import_item?(group_id, name, status, "group")

        if course_id && account_id
          raise ImportError, "Only one context is allowed and both course_id and account_id where provided for group #{group_id}."
        end

        context = find_context(account_id, :account_id, "group", group_id) if account_id
        context ||= find_context(course_id, :course_id, "group", group_id) if course_id

        group_category = nil
        if group_category_id.present?
          group_category = find_category(group_category_id, context, :group_category, "group", group_id)
        end

        group = @root_account.all_groups.find_by(sis_source_id: group_id)

        if group_category
          context = group_category.context
          if group
            group.group_category = group_category
          else
            group = group_category.groups.new(name:, sis_source_id: group_id)
          end
        end

        context ||= group&.context || @root_account

        can_change_context?(group, context, "group", group_id)

        group ||= context.groups.new(name:, sis_source_id: group_id)
        group.name = name if name.present? && !group.stuck_sis_fields.include?(:name)
        group.context = context
        group.sis_batch_id = @batch.id
        group.workflow_state = (status == "deleted") ? "deleted" : "available"

        # Ensure group category context matches group context
        if group&.group_category &&
           group.group_category.context_id != context.id &&
           group.group_category.context_type == context.class_name
          group.group_category.update!(context_id: context.id)
        end

        save_and_process_memberships(group, "group", status)
      end

      def add_tag(tag_id, tag_set_id, course_id, name, status)
        return if invalid_import_item?(tag_id, name, status, "differentiation_tag")

        context = find_context(course_id, :course_id, "differentiation_tag", tag_id) if course_id
        if context
          raise ImportError, "Differentiation Tags are not enabled for Account #{context.account.id}." unless context.account.allow_assign_to_differentiation_tags?
        end

        tag_set = nil
        if tag_set_id.present?
          tag_set = find_category(tag_set_id, context, :differentiation_tag_category, "differentiation_tag", tag_id)
        end

        tag = @root_account.all_differentiation_tags.find_by(sis_source_id: tag_id)

        if tag_set
          context = tag_set.context
          raise ImportError, "Differentiation Tags are not enabled for Account #{context.account.id}." unless context.account.allow_assign_to_differentiation_tags?

          if tag
            tag.group_category = tag_set
          else
            tag = tag_set.groups.non_collaborative.new(name:, sis_source_id: tag_id)
          end
        end

        context ||= tag&.context
        raise ImportError, "No tag_set_id or course_id given for differentiation tag #{tag_id}. At least one is required for new tags." unless context

        can_change_context?(tag, context, "differentiation_tag", tag_id)

        tag ||= context.groups.new(name:, non_collaborative: true, sis_source_id: tag_id)
        tag.name = name if name.present? && !tag.stuck_sis_fields.include?(:name)
        tag.context = context
        tag.sis_batch_id = @batch.id
        tag.workflow_state = (status == "deleted") ? "deleted" : "available"

        # Ensure tag category context matches tag context
        if tag&.group_category &&
           tag.group_category.context_id != context.id &&
           tag.group_category.context_type == context.class_name
          tag.group_category.update!(context_id: context.id)
        else
          tag_set ||= context.differentiation_tag_categories.create!(name:, non_collaborative: true)
          # If adding as a single tag, have the tag set match the single tag status
          tag_set.destroy if status == "deleted"
          tag.group_category = tag_set
        end

        save_and_process_memberships(tag, "differentiation_tag", status)
      end
    end
  end
end
