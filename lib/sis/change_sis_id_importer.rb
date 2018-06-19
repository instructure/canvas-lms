#
# Copyright (C) 2017 - present Instructure, Inc.
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
  class ChangeSisIdImporter < BaseImporter

    def process
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger)

      yield importer

      if @batch
        types = {
          'user' => {scope: @root_account.pseudonyms},
          'course' => {scope: @root_account.all_courses},
          'section' => {scope: @root_account.course_sections},
          'term' => {scope: @root_account.enrollment_terms},
          'account' => {scope: @root_account.all_accounts},
          'group' => {scope: @root_account.all_groups},
          'group_category' => {scope: @root_account.all_group_categories},
        }

        importer.things_to_update_batch_ids.each do |key, value|
          value.to_a.in_groups_of(1000, false) do |batch|
            touch_and_update_batch_ids types[key][:scope].where(id: batch)
          end
        end

        @logger.debug("change sis id #{Time.zone.now - start} seconds")

      end
      importer.success_count
    end

    def touch_and_update_batch_ids(scope)
      scope.update_all(sis_batch_id: @batch.id, updated_at: Time.now.utc)
    end

    class Work
      attr_accessor :success_count,
                    :things_to_update_batch_ids

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0
        @things_to_update_batch_ids = {}
      end

      def process_change_sis_id(data_change)
        @logger.debug("Processing change_sis_id #{data_change.to_a.inspect}")

        raise ImportError, "No type given for change_sis_id" if data_change.type.blank?
        raise ImportError, "No old_id or old_integration_id given for change_sis_id" if data_change.old_id.blank? && data_change.old_integration_id.blank?
        raise ImportError, "No new_id or new_integration_id given for change_sis_id" if data_change.new_id.blank? && data_change.new_integration_id.blank?

        type = data_change.type.downcase.strip
        things_to_update_batch_ids[type] ||= Set.new

        types = {
          'user' => {scope: @root_account.pseudonyms, column: :sis_user_id},
          'course' => {scope: @root_account.all_courses},
          'section' => {scope: @root_account.course_sections},
          'term' => {scope: @root_account.enrollment_terms},
          'account' => {scope: @root_account.all_accounts},
          'group' => {scope: @root_account.all_groups},
          'group_category' => {scope: @root_account.all_group_categories},
        }

        details = types[type]
        raise ImportError, "Invalid type '#{type}' for change_sis_id" unless details
        column = details[:column] || :sis_source_id
        check_for_conflicting_ids(column, details, type, data_change)
        old_item = find_item_to_update(column, details, type, data_change)
        updates = ids_to_change(column, data_change)
        details[:scope].where(id: old_item.id).update_all(updates)
        @things_to_update_batch_ids[type] << old_item.id
        @success_count += 1
      end

      def ids_to_change(column, data_change)
        updates = {}
        if data_change.new_id.present?
          updates[column] = data_change.new_id
        end
        if data_change.new_integration_id.present?
          updates['integration_id'] = data_change.new_integration_id
          if data_change.new_integration_id == '<delete>'
            updates['integration_id'] = nil
          end
        end
        updates
      end

      def check_for_conflicting_ids(column, details, type, data_change)
        if type == 'group_category' && (data_change.old_integration_id || data_change.new_integration_id)
          raise ImportError, "Group categories should not have integration IDs."
        end
        check_new = details[:scope].where(column => data_change.new_id).exists? if data_change.new_id.present?
        raise ImportError, "A new_id, '#{data_change.new_id}', referenced an existing #{type} and the #{type} with #{column} '#{data_change.old_id}' was not updated" if check_new
        check_int = details[:scope].where(integration_id: data_change.new_integration_id).exists? if data_change.new_integration_id.present?
        raise ImportError, "A new_integration_id, '#{data_change.new_integration_id}', referenced an existing #{type} and the #{type} with integration_id '#{data_change.old_integration_id}' was not updated" if check_int
      end

      def find_item_to_update(column, details, type, data_change)
        if data_change.old_id.present?
          old_item = details[:scope].where(column => data_change.old_id).take
        end
        if data_change.old_integration_id.present?
          old_int_item = details[:scope].where(integration_id: data_change.old_integration_id).take if data_change.old_integration_id.present?
        end
        if data_change.old_id.present? && data_change.old_integration_id.present?
          raise ImportError, "An old_id, '#{data_change.old_id}', referenced a different #{type} than the old_integration_id, '#{data_change.old_integration_id}'" unless old_item == old_int_item
          return old_item
        end
        if data_change.old_id.present? && data_change.old_integration_id.blank?
          raise ImportError, "An old_id, '#{data_change.old_id}', referenced a non-existent #{type} and was not changed." unless old_item
          return old_item
        end
        if data_change.old_id.blank? && data_change.old_integration_id.present?
          raise ImportError, "An old_integration_id, '#{data_change.old_integration_id}', referenced a non-existent #{type} and was not changed." unless old_int_item
          return old_int_item
        end
      end

    end
  end
end
