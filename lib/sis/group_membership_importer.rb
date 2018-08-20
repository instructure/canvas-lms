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
  class GroupMembershipImporter < BaseImporter

    def process
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger)
      yield importer
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data) if @batch.using_parallel_importers?
      @logger.debug("Group Users took #{Time.zone.now - start} seconds")
      importer.success_count
    end

    private
    class Work
      attr_accessor :success_count, :roll_back_data

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0
        @groups_cache = {}
        @roll_back_data = []
      end

      def add_group_membership(user_id, group_id, status)
        user_id = user_id.to_s
        group_id = group_id.to_s
        @logger.debug("Processing Group User #{[user_id, group_id, status].inspect}")
        raise ImportError, "No group_id given for a group user" if group_id.blank?
        raise ImportError, "No user_id given for a group user" if user_id.blank?
        raise ImportError, "Improper status \"#{status}\" for a group user" unless status =~ /\A(accepted|deleted)/i
        return if @batch.skip_deletes? && status =~ /deleted/i

        pseudo = @root_account.pseudonyms.where(sis_user_id: user_id).take
        user = pseudo&.user

        group = @groups_cache[group_id]
        group ||= @root_account.all_groups.where(sis_source_id: group_id).preload(:context).take
        @groups_cache[group.sis_source_id] = group if group

        raise ImportError, "User #{user_id} didn't exist for group user" unless user
        raise ImportError, "Group #{group_id} didn't exist for group user" unless group

        if group.context.is_a?(Course) && !group.context.all_real_users.where(id: user.id).exists?
          raise ImportError, "User #{user_id} doesn't have an enrollment in the course of group #{group_id}."
        end

        # can't query group.group_memberships, since that excludes deleted memberships
        group_membership = GroupMembership.where(group_id: group, user_id: user).
          order(Arel.sql("CASE WHEN workflow_state = 'accepted' THEN 0 ELSE 1 END")).take
        group_membership ||= group.group_memberships.build(:user => user)

        group_membership.sis_batch_id = @batch.id

        case status
        when /accepted/i
          group_membership.workflow_state = 'accepted'
        when /deleted/i
          group_membership.workflow_state = 'deleted'
        end

        if group_membership.valid?
          group_membership.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: group_membership)
          @roll_back_data << data if data
        else
          msg = "A group user did not pass validation "
          msg += "(" + "user: #{user_id}, group: #{group_id}, error: "
          msg += group_membership.errors.full_messages.join(", ") + ")"
          raise ImportError, msg
        end
        @success_count += 1
      end

    end
  end
end
