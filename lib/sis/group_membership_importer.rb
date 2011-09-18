#
# Copyright (C) 2011 Instructure, Inc.
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
  class GroupMembershipImporter < SisImporter
    def self.is_group_membership_csv?(row)
      row.header?('group_id') && row.header?('user_id')
    end

    def verify(csv, verify)
      csv_rows(csv) do |row|
        add_error(csv, "No group_id given for a group user") if row['group_id'].blank?
        add_error(csv, "No user_id given for a group user") if row['user_id'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for a group user") unless row['status'] =~ /\A(accepted|deleted)/i
      end
    end

    # expected columns
    # group_id,user_id,status
    def process(csv)
      start = Time.now
      groups_cache = {}

      csv_rows(csv) do |row|
        update_progress
        logger.debug("Processing Group User #{row.inspect}")

        pseudo = Pseudonym.first(:conditions => {
          :account_id => @root_account,
          :sis_user_id => row['user_id'] })
        user = pseudo.try(:user)

        group = groups_cache[row['group_id']]
        group ||= Group.first(:conditions => {
          :root_account_id => @root_account,
          :sis_source_id => row['group_id'] })

        groups_cache[group.sis_source_id] = group if group

        unless user && group
          add_warning csv, "User #{row['user_id']} didn't exist for group user" unless user
          add_warning csv, "Group #{row['group_id']} didn't exist for group user" unless group
          next
        end

        # can't query group.group_memberships, since that excludes deleted memberships
        group_membership = GroupMembership.first(:conditions => {
          :group_id => group,
          :user_id => user })
        group_membership ||= group.group_memberships.build(:user => user)

        group_membership.sis_batch_id = @batch.try(:id)

        case row['status']
        when /accepted/i
          group_membership.workflow_state = 'accepted'
        when /deleted/i
          group_membership.workflow_state = 'deleted'
        end

        group_membership.save
        @sis.counts[:group_memberships] += 1
      end

      logger.debug("Group Users took #{Time.now - start} seconds")
    end
  end
end

