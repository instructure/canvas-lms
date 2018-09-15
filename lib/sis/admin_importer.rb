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
  class AdminImporter < BaseImporter

    def process
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger)

      AccountUser.skip_touch_callbacks(:user) do
        User.skip_updating_account_associations do
          yield importer
        end
      end

      User.update_account_associations(importer.account_users_to_update_associations.to_a)
      importer.account_users_to_set_batch_id.to_a.in_groups_of(1000, false) do |admins|
        AccountUser.where(id: admins).update_all(sis_batch_id: @batch.id, updated_at: Time.now.utc)
      end
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)
      @logger.debug("admin imported in #{Time.zone.now - start} seconds")
      importer.success_count
    end

    class Work
      attr_accessor :success_count, :roll_back_data,
                    :account_users_to_update_associations,
                    :account_users_to_set_batch_id

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @account = root_account
        @logger = logger
        @success_count = 0
        @roll_back_data = []
        @account_users_to_update_associations = Set.new
        @account_users_to_set_batch_id = Set.new
        @account_roles_by_account_id = {}
      end

      def process_admin(user_id: nil, account_id: nil, role_id: nil, role: nil, status: nil, root_account: nil)
        @logger.debug("Processing admin #{[user_id, account_id, role_id, role, status, root_account].inspect}")

        raise ImportError, "No user_id given for admin" if user_id.blank?
        raise ImportError, "No status given for admin" if status.blank?
        raise ImportError, "No role_id or role given for admin" if role.blank? && role_id.blank?

        state = status.downcase.strip
        raise ImportError, "Invalid status #{status} for admin" unless %w(active deleted).include? state
        return if @batch.skip_deletes? && state == 'deleted'

        get_account(account_id)
        raise ImportError, "Invalid account_id given for admin" unless @account

        get_role(role_id, role)
        raise ImportError, "Invalid role '#{role}' for admin" if role.present? && !@role
        raise ImportError, "Invalid role_id '#{role_id}' for admin" if role_id.present? && !@role

        the_root_account = root_account_from_id(root_account) if root_account
        raise ImportError, "Invalid or unknown user_id '#{user_id}' for admin" if root_account && !the_root_account
        the_root_account ||= @root_account

        user = get_user(user_id, the_root_account)
        raise ImportError, "Invalid or unknown user_id '#{user_id}' for admin" unless user

        if state == 'deleted' && user.id == @batch&.user_id && @account == @root_account
          raise ImportError, "Can't remove yourself user_id '#{user_id}'"
        end

        create_or_find_admin(user, state)
        @success_count += 1
      end

      def create_or_find_admin(user, state)

        if state == 'active'
          admin = @account.account_users.where(user: user, role: @role).first_or_initialize
          admin.workflow_state = state
        elsif state == 'deleted'
          admin = @account.account_users.where(user: user, role: @role).where.not(sis_batch_id: nil).take
          return unless admin
          admin.workflow_state = state
        end

        if admin.new_record? || admin.workflow_state_changed?
          @account_users_to_update_associations.add(user.id)
          admin.save!
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: admin)
          @roll_back_data << data if data
        end
        @account_users_to_set_batch_id.add(admin.id)
      end

      def get_account(account_id)
        @account = nil unless @account&.sis_source_id == account_id
        @account ||= @root_account.all_accounts.active.where(sis_source_id: account_id).take if account_id.present?
        @account ||= @root_account if account_id.blank?
      end

      def get_user(user_id, root_account)
        pseudonym = root_account.pseudonyms.active.where(sis_user_id: user_id).take
        user = pseudonym.user if pseudonym
        user
      end

      def root_account_from_id(root_account_sis_id)
        nil
      end

      def get_role(role_id, role)
        # cache available account roles for this account
        @account_roles_by_account_id[@account.id] ||= @account.available_account_roles

        @role = nil
        @role = @account_roles_by_account_id[@account.id].detect {|r| r.id.to_s == role_id} if role_id
        @role ||= @account_roles_by_account_id[@account.id].detect {|r| r.name == role}
      end
    end
  end
end
