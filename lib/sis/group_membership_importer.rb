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
  class GroupMembershipImporter < BaseImporter
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
        @groups_cache = {}
        @roll_back_data = []
      end

      def add_group_membership(user_id, group_id, status, is_tags: false)
        user_id = user_id.to_s
        group_id = group_id.to_s
        raise ImportError, "No #{is_tags ? "tag_id" : "group_id"} given for a #{is_tags ? "differentiation tag" : "group"} user" if group_id.blank?
        raise ImportError, "No user_id given for a #{is_tags ? "differentiation tag" : "group"} user" if user_id.blank?
        raise ImportError, "Improper status \"#{status}\" for a #{is_tags ? "differentiation tag" : "group"} user" unless /\A(accepted|deleted)/i.match?(status)
        return if @batch.skip_deletes? && status =~ /deleted/i

        pseudo = @root_account.pseudonyms.find_by(sis_user_id: user_id)
        user = pseudo&.user

        group = @groups_cache[group_id]
        scope = is_tags ? @root_account.all_differentiation_tags : @root_account.all_groups
        group ||= scope.where(sis_source_id: group_id).preload(:context).take
        @groups_cache[group.sis_source_id] = group if group

        raise ImportError, "User #{user_id} didn't exist for #{is_tags ? "differentiation tag" : "group"} user" unless user
        raise ImportError, "#{is_tags ? "Differentiation tag" : "Group"} #{group_id} didn't exist for #{is_tags ? "differentiation tag" : "group"} user" unless group

        if group.context.is_a?(Course) && !group.context.all_real_users.where(id: user.id).exists?
          raise ImportError, "User #{user_id} doesn't have an enrollment in the course of #{is_tags ? "differentiation tag" : "group"} #{group_id}."
        end

        if group && is_tags
          raise ImportError, "Differentiation Tags are not enabled for Account #{group.context.account.id}." unless group.context.account.allow_assign_to_differentiation_tags?
        end

        # can't query group.group_memberships, since that excludes deleted memberships
        group_membership = GroupMembership.where(group_id: group, user_id: user)
                                          .order(Arel.sql("CASE WHEN workflow_state = 'accepted' THEN 0 ELSE 1 END")).take
        group_membership ||= group.group_memberships.build(user:)

        group_membership.sis_batch_id = @batch.id

        case status
        when /accepted/i
          group_membership.workflow_state = "accepted"
        when /deleted/i
          group_membership.workflow_state = "deleted"
        end

        if group_membership.valid?
          group_membership.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: group_membership)
          @roll_back_data << data if data
        else
          msg = "A #{is_tags ? "differentiation tag" : "group"} user did not pass validation "
          msg += "(" + "user: #{user_id}, #{is_tags ? "differentiation tag" : "group"}: #{group_id}, error: "
          msg += group_membership.errors.full_messages.join(", ") + ")"
          raise ImportError, msg
        end
        @success_count += 1
      end
    end
  end
end
