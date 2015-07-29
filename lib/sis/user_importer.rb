#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  class UserImporter < BaseImporter

    def process(updates_every, messages)
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger, updates_every, messages)
      User.skip_updating_account_associations do
        User.process_as_sis(@sis_options) do
          Pseudonym.process_as_sis(@sis_options) do
            yield importer
            while importer.any_left_to_process?
              importer.process_batch
            end
          end
        end
      end
      User.update_account_associations(importer.users_to_add_account_associations, :incremental => true, :precalculated_associations => {@root_account.id => 0})
      User.update_account_associations(importer.users_to_update_account_associations)
      importer.pseudos_to_set_sis_batch_ids.in_groups_of(1000, false) do |batch|
        Pseudonym.where(:id => batch).update_all(:sis_batch_id => @batch)
      end if @batch
      @logger.debug("Users took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :users_to_set_sis_batch_ids,
          :pseudos_to_set_sis_batch_ids, :users_to_add_account_associations,
          :users_to_update_account_associations

      def initialize(batch, root_account, logger, updates_every, messages)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @updates_every = updates_every
        @batched_users = []
        @messages = messages
        @success_count = 0

        @users_to_set_sis_batch_ids = []
        @pseudos_to_set_sis_batch_ids = []
        @users_to_add_account_associations = []
        @users_to_update_account_associations = []
        @authentication_providers = {}
      end

      def add_user(user_id, login_id, status, first_name, last_name, email=nil, password=nil, ssha_password=nil, integration_id=nil, short_name=nil, full_name=nil, sortable_name=nil, authentication_provider_id=nil)
        @logger.debug("Processing User #{[user_id, login_id, status, first_name, last_name, email, password, ssha_password, integration_id, short_name, full_name, sortable_name].inspect}")

        raise ImportError, "No user_id given for a user" if user_id.blank?
        raise ImportError, "No login_id given for user #{user_id}" if login_id.blank?
        raise ImportError, "Improper status for user #{user_id}" unless status =~ /\A(active|deleted)/i

        @batched_users << [user_id.to_s, login_id, status, first_name, last_name, email, password, ssha_password, integration_id, short_name, full_name, sortable_name, authentication_provider_id]
        process_batch if @batched_users.size >= @updates_every
      end

      def any_left_to_process?
        return @batched_users.size > 0
      end

      def process_batch
        return unless any_left_to_process?
        transaction_timeout = Setting.get('sis_transaction_seconds', '1').to_i.seconds
        User.transaction do
          tx_end_time = Time.now + transaction_timeout
          user_row = nil
          while !@batched_users.empty? && tx_end_time > Time.now
            user_row = @batched_users.shift
            @logger.debug("Processing User #{user_row.inspect}")
            user_id, login_id, status, first_name, last_name, email, password, ssha_password, integration_id, short_name, full_name, sortable_name, authentication_provider_id = user_row

            pseudo = @root_account.pseudonyms.where(sis_user_id: user_id.to_s).first
            pseudo_by_login = @root_account.pseudonyms.active.by_unique_id(login_id).first
            pseudo ||= pseudo_by_login
            pseudo ||= @root_account.pseudonyms.active.by_unique_id(email).first if email.present?

            status_is_active = !(status =~ /\Adeleted/i)
            if pseudo
              if pseudo.sis_user_id && pseudo.sis_user_id != user_id
                @messages << "user #{pseudo.sis_user_id} has already claimed #{user_id}'s requested login information, skipping"
                next
              end
              if pseudo_by_login && (pseudo != pseudo_by_login && status_is_active ||
                !(ActiveRecord::Base.connection.select_value("SELECT 1 FROM pseudonyms WHERE #{Pseudonym.to_lower_column(Pseudonym.sanitize(pseudo.unique_id))}=#{Pseudonym.to_lower_column(Pseudonym.sanitize(login_id))} LIMIT 1")))
                @messages << "user #{pseudo_by_login.sis_user_id || pseudo_by_login.user_id} has already claimed #{user_id}'s requested login information, skipping"
                next
              end

              user = pseudo.user
              unless user.stuck_sis_fields.include?(:name)
                user.name = "#{first_name} #{last_name}"
                user.name = full_name if full_name.present?
              end
              unless user.stuck_sis_fields.include?(:sortable_name)
                user.sortable_name = last_name.present? && first_name.present? ? "#{last_name}, #{first_name}" : "#{first_name}#{last_name}"
                user.sortable_name = nil if full_name.present? # force User model to infer sortable name from the full name
                user.sortable_name = sortable_name if sortable_name.present?
              end
              unless user.stuck_sis_fields.include?(:short_name)
                user.short_name = short_name if short_name.present?
              end
            else
              user = User.new
              user.name = "#{first_name} #{last_name}"
              user.name = full_name if full_name.present?
              user.sortable_name = last_name.present? && first_name.present? ? "#{last_name}, #{first_name}" : "#{first_name}#{last_name}"
              user.sortable_name = nil if full_name.present? # force User model to infer sortable name from the full name
              user.sortable_name = sortable_name if sortable_name.present?
              user.short_name = short_name if short_name.present?
            end

            # we just leave all users registered now
            # since we've deleted users though, we need to do this to be
            # backwards compatible with the data
            user.workflow_state = 'registered'

            should_add_account_associations = false
            should_update_account_associations = false

            if !status_is_active && !user.new_record?
              # if this user is deleted, we're just going to make sure the user isn't enrolled in anything in this root account and
              # delete the pseudonym.
              if 0 < user.enrollments.where("root_account_id=? AND workflow_state<>?", @root_account, 'deleted').update_all(:workflow_state => 'deleted')
                should_update_account_associations = true
              end
            end

            pseudo ||= Pseudonym.new
            pseudo.unique_id = login_id unless pseudo.stuck_sis_fields.include?(:unique_id)
            if authentication_provider_id.present?
              unless @authentication_providers.key?(authentication_provider_id)
                begin
                  @authentication_providers[authentication_provider_id] =
                    @root_account.authentication_providers.active.find(authentication_provider_id)
                rescue ActiveRecord::RecordNotFound
                  @authentication_providers[authentication_provider_id] = nil
                end
              end
              unless (pseudo.authentication_provider = @authentication_providers[authentication_provider_id])
                @messages << "unrecognized authentication provider #{authentication_provider_id} for #{user_id}, skipping"
                next
              end
            else
              pseudo.authentication_provider = nil
            end
            pseudo.sis_user_id = user_id
            pseudo.integration_id = integration_id
            pseudo.account = @root_account
            pseudo.workflow_state = status_is_active ? 'active' : 'deleted'
            if pseudo.new_record? && status_is_active
              should_add_account_associations = true
            elsif pseudo.workflow_state_changed?
              if status_is_active
                should_add_account_associations = true
              else
                should_update_account_associations = true
              end
            end

            # if a password is provided, use it only if this is a new user, or the user hasn't changed the password in canvas *AND* the incoming password has changed
            # otherwise the persistence_token will change even though we're setting to the same password, logging the user out
            if !password.blank? && (pseudo.new_record? || pseudo.password_auto_generated && !pseudo.valid_password?(password))
              pseudo.password = password
              pseudo.password_confirmation = password
              pseudo.password_auto_generated = true
            end
            pseudo.sis_ssha = ssha_password if !ssha_password.blank?
            pseudo.reset_persistence_token if pseudo.sis_ssha_changed? && pseudo.password_auto_generated
            user_touched = false

            begin
              User.transaction(:requires_new => true) do
                if user.changed?
                  user_touched = true
                  raise ImportError, user.errors.first.join(" ") if !user.save && user.errors.size > 0
                elsif @batch
                  @users_to_set_sis_batch_ids << user.id
                end
                pseudo.user_id = user.id
                if pseudo.changed?
                  pseudo.sis_batch_id = @batch.id if @batch
                  raise ImportError, pseudo.errors.first.join(" ") if !pseudo.save_without_broadcasting && pseudo.errors.size > 0
                end
              end
            rescue => e
              @messages << "Failed saving user. Internal error: #{e}"
              next
            end

            @users_to_add_account_associations << user.id if should_add_account_associations
            @users_to_update_account_associations << user.id if should_update_account_associations

            if email.present?
              # find all CCs for this user, and active conflicting CCs for all users
              # unless we're deleting this user, then only find CCs for this user
              if status_is_active
                ccs = CommunicationChannel.where("workflow_state='active' OR user_id=?", user)
              else
                ccs = user.communication_channels
              end
              ccs = ccs.email.by_path(email).to_a

              # sis_cc could be set from the previous user, if we're not on a transaction boundary,
              # and the previous user had an sis communication channel, and this user doesn't have one
              # then it would have "stolen" to sis_cc from the previous user
              sis_cc = nil
              sis_cc = ccs.find { |cc| cc.id == pseudo.sis_communication_channel_id } if pseudo.sis_communication_channel_id
              # Have to explicitly load the old sis communication channel, in case it changed (should only happen if user_id got messed up)
              sis_cc ||= pseudo.sis_communication_channel
              # search for active/unconfirmed channels first, so we don't try to resurrect a conflicting cc
              other_cc = ccs.find { |cc| cc.user_id == user.id && cc.id != sis_cc.try(:id) && (cc.active? || cc.unconfirmed?)}
              other_cc ||= ccs.find { |cc| cc.user_id == user.id && cc.id != sis_cc.try(:id) }
              # Handle the case where the SIS CC changes to match an already existing CC
              if sis_cc && other_cc
                sis_cc.destroy
                sis_cc = nil
              end
              cc = sis_cc || other_cc || CommunicationChannel.new
              cc.user_id = user.id
              cc.pseudonym_id = pseudo.id
              cc.path = email
              cc.workflow_state = status_is_active ? 'active' : 'retired'
              newly_active = cc.path_changed? || (cc.active? && cc.workflow_state_changed?)
              if cc.changed?
                if cc.valid?
                  cc.save_without_broadcasting
                else
                  msg = "An email did not pass validation "
                  msg += "(" + "#{email}, error: "
                  msg += cc.errors.full_messages.join(", ") + ")"
                  raise ImportError, msg
                end
                user.touch unless user_touched
              end
              pseudo.sis_communication_channel_id = pseudo.communication_channel_id = cc.id

              if newly_active
                other_ccs = ccs.reject { |other_cc| other_cc.user_id == user.id || other_cc.user.nil? || other_cc.user.pseudonyms.active.count == 0 ||
                  !other_cc.user.pseudonyms.active.where("account_id=? AND sis_user_id IS NOT NULL", @root_account).empty? }
                unless other_ccs.empty?
                  cc.send_merge_notification!
                end
              end
            end

            if pseudo.changed?
              pseudo.sis_batch_id = @batch.id if @batch
              if pseudo.valid?
                pseudo.save_without_broadcasting
                @success_count += 1
              else
                msg = "A user did not pass validation "
                msg += "(" + "user: #{user_id}, error: "
                msg += pseudo.errors.full_messages.join(", ") + ")"
                raise ImportError, msg
              end
            elsif @batch && pseudo.sis_batch_id != @batch.id
              @pseudos_to_set_sis_batch_ids << pseudo.id
              @success_count += 1
            end

          end
        end
      end
    end
  end
end
