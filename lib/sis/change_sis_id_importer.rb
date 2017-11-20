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
          'user_integration_id' => {scope: @root_account.pseudonyms},
          'course' => {scope: @root_account.all_courses},
          'section' => {scope: @root_account.course_sections},
          'term' => {scope: @root_account.enrollment_terms},
          'account' => {scope: @root_account.all_accounts},
          'group' => {scope: @root_account.all_groups}
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

      def process_change_sis_id(old_id: nil, new_id: nil, type: nil)
        @logger.debug("Processing change_sis_id #{[type, old_id, new_id].inspect}")

        raise ImportError, "No type given for change_sis_id" if type.blank?
        raise ImportError, "No old_id given for change_sis_id" if old_id.blank?
        unless type == 'user_integration_id'
          raise ImportError, "No new_id given for change_sis_id" if new_id.blank?
        end

        type = type.downcase.strip
        things_to_update_batch_ids[type] ||= Set.new

        types = {
          'user' => {scope: @root_account.pseudonyms, column: :sis_user_id},
          'user_integration_id' => {scope: @root_account.pseudonyms, column: :integration_id},
          'course' => {scope: @root_account.all_courses},
          'section' => {scope: @root_account.course_sections},
          'term' => {scope: @root_account.enrollment_terms},
          'account' => {scope: @root_account.all_accounts},
          'group' => {scope: @root_account.all_groups}
        }

        details = types[type]
        raise ImportError, "Invalid type '#{type}' for change_sis_id" unless details
        column = details[:column] || :sis_source_id
        check_new = details[:scope].where(column => new_id).exists? if new_id.present?
        raise ImportError, "A new_id, '#{new_id}', referenced an existing #{type} and the #{type} with #{column} '#{old_id}' was not updated" if check_new
        old_pseudo = details[:scope].where(column => old_id).take
        raise ImportError, "An old_id, '#{old_id}', referenced a non-existent #{type} and was not changed to '#{new_id}'" unless old_pseudo
        details[:scope].where(id: old_pseudo.id).update_all(column => new_id)
        @things_to_update_batch_ids[type] << old_pseudo.id
        @success_count += 1
      end
    end
  end
end
