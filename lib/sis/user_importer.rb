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
  class UserImporter
    def initialize(batch_id, root_account, logger, override_sis_stickiness)
      @batch_id = batch_id
      @root_account = root_account
      @logger = logger
      @override_sis_stickiness = override_sis_stickiness
    end

    def process(updates_every, messages)
      start = Time.now
      importer = Work.new(@batch_id, @root_account, @logger, updates_every, messages)
      User.skip_updating_account_associations do
        User.process_as_sis(@override_sis_stickiness) do
          Pseudonym.process_as_sis(@override_sis_stickiness) do
            yield importer
            while importer.any_left_to_process?
              importer.process_batch
            end
          end
        end
      end
      User.update_account_associations(importer.users_to_add_account_associations, :incremental => true, :precalculated_associations => {@root_account.id => 0})
      User.update_account_associations(importer.users_to_update_account_associations)
      User.update_all({:creation_sis_batch_id => @batch_id}, {:id => importer.users_to_set_sis_batch_ids}) if @batch_id && !importer.users_to_set_sis_batch_ids.empty?
      Pseudonym.update_all({:sis_batch_id => @batch_id}, {:id => importer.pseudos_to_set_sis_batch_ids}) if @batch && !importer.pseudos_to_set_sis_batch_ids.empty?
      @logger.debug("Users took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :users_to_set_sis_batch_ids,
          :pseudos_to_set_sis_batch_ids, :users_to_add_account_associations,
          :users_to_update_account_associations

      def initialize(batch_id, root_account, logger, updates_every, messages)
        @batch_id = batch_id
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
      end

      def add_user(user_id, login_id, status, first_name, last_name, email=nil, password=nil, ssha_password=nil)
        @logger.debug("Processing User #{[user_id, login_id, status, first_name, last_name, email, password, ssha_password].inspect}")

        raise ImportError, "No user_id given for a user" if user_id.blank?
        raise ImportError, "No login_id given for user #{user_id}" if login_id.blank?
        raise ImportError, "Improper status for user #{user_id}" unless status =~ /\A(active|deleted)/i

        @batched_users << [user_id, login_id, status, first_name, last_name, email, password, ssha_password]
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
            user_id, login_id, status, first_name, last_name, email, password, ssha_password = user_row

            pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, user_id)
            pseudo_by_login = Pseudonym.find_by_unique_id_and_account_id(login_id, @root_account.id)
            pseudo ||= pseudo_by_login
            pseudo ||= Pseudonym.find_by_unique_id_and_account_id(email, @root_account.id) if email.present?

            if pseudo
              if pseudo.sis_user_id.present? && pseudo.sis_user_id != user_id
                @messages << "user #{pseudo.sis_user_id} has already claimed #{user_id}'s requested login information, skipping"
                next
              end
              if !pseudo_by_login.nil? && pseudo.unique_id != login_id
                @messages << "user #{pseudo_by_login.sis_user_id} has already claimed #{user_id}'s requested login information, skipping"
                next
              end

              user = pseudo.user
              user.name = "#{first_name} #{last_name}" unless user.stuck_sis_fields.include?(:name)

            else
              user = User.new
              user.name = "#{first_name} #{last_name}"
            end

            if status =~ /active/i
              user.workflow_state = 'registered'
            elsif status =~ /deleted/i
              user.workflow_state = 'deleted'
              user.enrollments.scoped(:conditions => {:root_account_id => @root_account.id }).update_all(:workflow_state => 'deleted')
              @users_to_update_account_associations << user.id unless user.new_record?
            end

            pseudo ||= Pseudonym.new
            pseudo.unique_id = login_id unless pseudo.stuck_sis_fields.include?(:unique_id)
            pseudo.sis_source_id = login_id
            pseudo.sis_user_id = user_id
            pseudo.account = @root_account
            pseudo.workflow_state = status =~ /active/i ? 'active' : 'deleted'
            # if a password is provided, use it only if this is a new user, or the user hasn't changed the password in canvas *AND* the incoming password has changed
            # otherwise the persistence_token will change even though we're setting to the same password, logging the user out
            if !password.blank? && (pseudo.new_record? || pseudo.password_auto_generated && !pseudo.valid_password?(password))
              pseudo.password = password
              pseudo.password_confirmation = password
              pseudo.password_auto_generated = true
            end
            pseudo.sis_ssha = ssha_password if !ssha_password.blank?
            pseudo.reset_persistence_token if pseudo.sis_ssha_changed? && pseudo.password_auto_generated

            begin
              User.transaction(:requires_new => true) do
                if user.changed?
                  user.creation_sis_batch_id = @batch_id if @batch_id
                  new_record = user.new_record?
                  raise user.errors.first.join(" ") if !user.save_without_broadcasting && user.errors.size > 0
                  @users_to_add_account_associations << user.id if new_record && user.workflow_state != 'deleted'
                elsif @batch_id
                  @users_to_set_sis_batch_ids << user.id
                end
                pseudo.user_id = user.id
                if pseudo.changed?
                  pseudo.sis_batch_id = @batch_id if @batch_id
                  raise pseudo.errors.first.join(" ") if !pseudo.save_without_broadcasting && pseudo.errors.size > 0
                end
              end
            rescue => e
              @messages << "Failed saving user. Internal error: #{e}"
              next
            end

            if email.present?
              comm = CommunicationChannel.find_by_path_and_workflow_state_and_path_type(email, 'active', 'email')
              if !comm and status =~ /active/i
                begin
                  comm = pseudo.sis_communication_channel || CommunicationChannel.new
                  if comm.new_record?
                    comm.user_id = user.id
                    comm.pseudonym_id = pseudo.id
                    pseudo.sis_communication_channel = comm
                  end
                  comm.path = email
                  comm.workflow_state = 'active'
                  comm.do_delayed_jobs_immediately = true
                  comm.save_without_broadcasting if comm.changed?
                  pseudo.communication_channel_id = comm.id
                rescue => e
                  @messages << "Failed adding communication channel #{email} to user #{login_id}"
                end
              elsif status =~ /active/i
                if comm.user_id != pseudo.user_id
                  @messages << "E-mail address #{email} for user #{login_id} is already claimed; ignoring"
                else
                  pseudo.sis_communication_channel.destroy if pseudo.sis_communication_channel != comm and !pseudo.sis_communication_channel.nil?
                  pseudo.sis_communication_channel = comm
                  pseudo.communication_channel_id = comm.id
                  comm.do_delayed_jobs_immediately = true
                  comm.save_without_broadcasting if comm.changed?
                end
              end
            end

            if pseudo.changed?
              pseudo.sis_batch_id = @batch_id if @batch_id
              pseudo.save_without_broadcasting
            elsif @batch_id && pseudo.sis_batch_id != @batch_id
              @pseudos_to_set_sis_batch_ids << pseudo.id
            end

            @success_count += 1
          end
        end
      end
    end
  end
end
