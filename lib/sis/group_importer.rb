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

      def add_group(group_id, group_category_id, account_id, course_id, name, status)
        @logger.debug("Processing Group #{[group_id, group_category_id, account_id, course_id, name, status].inspect}")
        raise ImportError, "No group_id given for a group." unless group_id
        raise ImportError, "No name given for group #{group_id}." if name.blank?
        # closed and completed are no longer valid states. Leaving these for
        # backwards compatibility. It is not longer a documented status
        raise ImportError, "Improper status \"#{status}\" for group #{group_id}." unless status =~ /\A(available|closed|completed|deleted)/i
        return if @batch.skip_deletes? && status =~ /deleted/i

        if course_id && account_id
          raise ImportError, "Only one context is allowed and both course_id and account_id where provided for group #{group_id}."
        end

        context = nil
        if account_id
          context = @accounts_cache[account_id]
          context ||= @root_account.all_accounts.active.where(sis_source_id: account_id).take
          raise ImportError, "Account with sis id #{account_id} didn't exist for group #{group_id}." unless context
          @accounts_cache[context.sis_source_id] = context
        end

        if course_id
          context = @root_account.all_courses.active.where(sis_source_id: course_id).take
          raise ImportError, "Course with sis id #{course_id} didn't exist for group #{group_id}." unless context
        end

        # if the account_id is present and didn't error then look for group_category in account
        if account_id && group_category_id
          group_category = context.group_categories.where(sis_source_id: group_category_id).take
          raise ImportError, "Group Category #{group_category_id} didn't exist in account #{account_id} for group #{group_id}." unless group_category
        elsif course_id && group_category_id
          group_category = context.group_categories.where(sis_source_id: group_category_id).take
          raise ImportError, "Group Category #{group_category_id} didn't exist in course #{course_id} for group #{group_id}." unless group_category
        # look for group_category, account and course don't exist
        elsif group_category_id.present?
          group_category = @root_account.all_group_categories.where(deleted_at: nil, sis_source_id: group_category_id).take
          raise ImportError, "Group Category #{group_category_id} didn't exist for group #{group_id}." unless group_category
        end

        group = @root_account.all_groups.where(sis_source_id: group_id).take

        # if the group_category exists it is in the correct context or the
        # context is blank, but it should be consistent with the
        # group_category's context, so assign context
        if group_category
          context = group_category.context
          group ? group.group_category = group_category : group = group_category.groups.new(name: name, sis_source_id: group_id)
        end
        # no account_id, course_id, or group_category, assign context to root_account
        context ||= @root_account

        if group && group.group_memberships.exists?
          unless context.id == group.context_id && context.class.base_class.name == group.context_type
            raise ImportError, "Cannot move group #{group_id} because it has group_memberships." if group.context.is_a?(Course) || context.is_a?(Course)
          end
        end

        group ||= context.groups.new(name: name, sis_source_id: group_id)
        # only update the name on groups that haven't had their name changed since the last sis import
        group.name = name if name.present? && !group.stuck_sis_fields.include?(:name)
        group.context = context
        group.sis_batch_id = @batch.id if @batch
        group.workflow_state = status == 'deleted' ? 'deleted' : 'available'

        if group.save
          @success_count += 1
        else
          msg = "A group did not pass validation "
          msg += "(" + "group: #{group_id}, error: "
          msg += group.errors.full_messages.join(",") + ")"
          raise ImportError, msg
        end
      end

    end

  end
end
