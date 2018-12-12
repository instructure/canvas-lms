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
  class UserImporter < BaseImporter

    def process(messages)
      start = Time.zone.now
      importer = Work.new(@batch, @root_account, @logger, messages)
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
      importer.pseudos_to_set_sis_batch_ids.in_groups_of(1000, false) {|ids| Pseudonym.where(id: ids).update_all(sis_batch_id: @batch.id)}
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)
      @logger.debug("Users took #{Time.zone.now - start} seconds")
      importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :users_to_set_sis_batch_ids,
          :pseudos_to_set_sis_batch_ids, :users_to_add_account_associations,
          :users_to_update_account_associations, :roll_back_data

      def initialize(batch, root_account, logger, messages)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @batched_users = []
        @messages = messages
        @success_count = 0

        @roll_back_data = []
        @users_to_set_sis_batch_ids = []
        @pseudos_to_set_sis_batch_ids = []
        @users_to_add_account_associations = []
        @users_to_update_account_associations = []
        @authentication_providers = {}
      end

      # Pass a single instance of SIS::Models::User
      def add_user(user)
        @logger.debug("Processing User #{user.to_a.inspect}")

        raise ImportError, "No user_id given for a user" if user.user_id.blank?
        raise ImportError, "No login_id given for user #{user.user_id}" if user.login_id.blank?
        raise ImportError, "Improper status for user #{user.user_id}" unless user.status =~ /\A(active|deleted)/i
        return if @batch.skip_deletes? && user.status =~ /deleted/i

        @batched_users << user
        process_batch if @batched_users.size >= Setting.get("sis_user_batch_size", "100").to_i
      end

      def any_left_to_process?
        return @batched_users.size > 0
      end

      def infer_user_name(user_row, prior_name = nil)
        if user_row.full_name.present?
          user_row.full_name
        elsif user_row.first_name.present? || user_row.last_name.present?
          [user_row.first_name, user_row.last_name].join(' ')
        elsif prior_name.present?
          prior_name
        elsif user_row.sortable_name.present?
          user_row.sortable_name
        elsif user_row.short_name.present?
          user_row.short_name
        elsif user_row.login_id.present?
          user_row.login_id
        else
          raise ImportError, "No name given for user"
        end
      end

      def infer_sortable_name(user_row, prior_sortable_name = nil)
        if user_row.sortable_name.present?
          user_row.sortable_name
        elsif user_row.full_name.present?
          nil # force User model to infer sortable name from the full name
        elsif user_row.last_name.present? || user_row.first_name.present?
          [user_row.last_name, user_row.first_name].join(', ')
        else
          prior_sortable_name
        end
      end

      def process_batch
        return unless any_left_to_process?
        user_row = nil
        while !@batched_users.empty?
          user_row = @batched_users.shift
          @logger.debug("Processing User #{user_row.inspect}")

          pseudo = @root_account.pseudonyms.where(sis_user_id: user_row.user_id.to_s).take
          pseudo_by_login = @root_account.pseudonyms.active.by_unique_id(user_row.login_id).take
          pseudo ||= pseudo_by_login

          status_is_active = !(user_row.status =~ /\Adeleted/i)
          if pseudo
            if pseudo.sis_user_id && pseudo.sis_user_id != user_row.user_id
              message = I18n.t("An existing Canvas user with the SIS ID %{user_id} has already claimed %{other_user_id}'s user_id requested login information, skipping", user_id: pseudo.sis_user_id, other_user_id: user_row.user_id)
              @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
              next
            end
            if pseudo_by_login && (pseudo != pseudo_by_login && status_is_active ||
              !Pseudonym.where("LOWER(?)=LOWER(?)", pseudo.unique_id, user_row.login_id).exists?)
              id_message = pseudo_by_login.sis_user_id ? 'SIS ID' : 'Canvas ID'
              user_id = pseudo_by_login.sis_user_id || pseudo_by_login.user_id
              message = I18n.t("An existing Canvas user with the %{user_id} has already claimed %{other_user_id}'s user_id requested login information, skipping", user_id: "#{id_message} #{user_id.to_s}", other_user_id: user_row.user_id)
              @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
              next
            end

            user = pseudo.user
            unless user.stuck_sis_fields.include?(:name)
              user.name = infer_user_name(user_row, user.name)
            end
            unless user.stuck_sis_fields.include?(:sortable_name)
              user.sortable_name = infer_sortable_name(user_row, user.sortable_name)
            end
            unless user.stuck_sis_fields.include?(:short_name)
              user.short_name = user_row.short_name if user_row.short_name.present?
            end
          else
            user = User.new
            user.name = infer_user_name(user_row)
            user.sortable_name = infer_sortable_name(user_row)
            user.short_name = user_row.short_name if user_row.short_name.present?
          end

          # we just leave all users registered now
          # since we've deleted users though, we need to do this to be
          # backwards compatible with the data
          user.workflow_state = 'registered'

          should_add_account_associations = false
          should_update_account_associations = false

          if !status_is_active && !user.new_record?
            if user.id == @batch&.user_id
              message = "Can't remove yourself user_id '#{user_row.user_id}'"
              @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
              next
            end

            # if this user is deleted and there are no more active logins,
            # we're going to delete any enrollments for this root account and
            # delete this pseudonym.
            should_update_account_associations = remove_enrollments_if_last_login(user, user_row.user_id)
          end

          pseudo ||= Pseudonym.new
          pseudo.unique_id = user_row.login_id unless pseudo.stuck_sis_fields.include?(:unique_id)
          if user_row.authentication_provider_id.present?
            unless @authentication_providers.key?(user_row.authentication_provider_id)
              begin
                @authentication_providers[user_row.authentication_provider_id] =
                  @root_account.authentication_providers.active.find(user_row.authentication_provider_id)
              rescue ActiveRecord::RecordNotFound
                @authentication_providers[user_row.authentication_provider_id] = nil
              end
            end
            unless (pseudo.authentication_provider = @authentication_providers[user_row.authentication_provider_id])
              message = "unrecognized authentication provider #{user_row.authentication_provider_id} for #{user_row.user_id}, skipping"
              @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
              next
            end
          else
            pseudo.authentication_provider = nil
          end
          pseudo.sis_user_id = user_row.user_id
          pseudo_by_integration = nil
          pseudo_by_integration = @root_account.pseudonyms.where(integration_id: user_row.integration_id.to_s).take if user_row.integration_id.present?
          if pseudo_by_integration && status_is_active && pseudo_by_integration != pseudo
            id_message = pseudo_by_integration.sis_user_id ? 'SIS ID' : 'Canvas ID'
            user_id = pseudo_by_integration.sis_user_id || pseudo_by_integration.user_id
            message = I18n.t("An existing Canvas user with the %{user_id} has already claimed %{other_user_id}'s requested integration_id, skipping", user_id: "#{id_message} #{user_id.to_s}", other_user_id: user_row.user_id)
            @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
            next
          end
          pseudo.integration_id = user_row.integration_id if user_row.integration_id.present?
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
          if !user_row.password.blank? && (pseudo.new_record? || pseudo.password_auto_generated && !pseudo.valid_password?(user_row.password))
            pseudo.password = user_row.password
            pseudo.password_confirmation = user_row.password
            pseudo.password_auto_generated = true
          end
          pseudo.sis_ssha = user_row.ssha_password if !user_row.ssha_password.blank?
          pseudo.reset_persistence_token if pseudo.sis_ssha_changed? && pseudo.password_auto_generated
          user_touched = false

          begin
            User.transaction(:requires_new => true) do
              if user.changed?
                user_touched = true
                if !user.save && user.errors.size > 0
                  message = generate_user_warning(user.errors.first.join(" "), user_row.user_id, user_row.login_id)
                  raise ImportError, message
                end
              elsif @batch
                @users_to_set_sis_batch_ids << user.id
              end
              pseudo.user_id = user.id
              if pseudo.changed?
                pseudo.sis_batch_id = @batch.id if @batch
                if pseudo.save_without_broadcasting
                  p_data = SisBatchRollBackData.build_data(sis_batch: @batch, context: pseudo)
                  @roll_back_data << p_data if p_data
                elsif pseudo.errors.size > 0
                  message = generate_user_warning(pseudo.errors.first.join(" "), user_row.user_id, user_row.login_id)
                  raise ImportError, message
                end
              end
            end
          rescue ImportError
            @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
            next
          rescue => e
            # something broke
            error = Canvas::Errors.capture_exception(:sis_import, e)
            er = error[:error_report]
            message = generate_user_warning("Something broke with this user. Contact Support with ErrorReport id: #{er}", user_row.user_id, user_row.login_id)
            @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, backtrace: e.backtrace, row_info: user_row.row_info)
            next
          end

          @users_to_add_account_associations << user.id if should_add_account_associations
          @users_to_update_account_associations << user.id if should_update_account_associations

          if user_row.email.present? && EmailAddressValidator.valid?(user_row.email)
            # find all CCs for this user, and active conflicting CCs for all users
            # unless we're deleting this user, then only find CCs for this user
            if status_is_active
              cc_scope = CommunicationChannel.where("workflow_state='active' OR user_id=?", user)
            else
              cc_scope = user.communication_channels
            end
            cc_scope = cc_scope.email.by_path(user_row.email)
            limit = Setting.get("merge_candidate_search_limit", "100").to_i
            ccs = cc_scope.limit(limit + 1).to_a
            if ccs.count > limit
              ccs = cc_scope.where(:user_id => user).to_a # don't bother with merge candidates anymore
            end

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
            cc.path = user_row.email
            cc.bounce_count = 0 if cc.path_changed?
            cc.workflow_state = status_is_active ? 'active' : 'retired'
            newly_active = cc.path_changed? || (cc.active? && cc.workflow_state_changed?)
            if cc.changed?
              if cc.valid?
                cc.save_without_broadcasting
                cc_data = SisBatchRollBackData.build_data(sis_batch: @batch, context: cc)
                @roll_back_data << cc_data if cc_data
              else
                msg = "An email did not pass validation "
                msg += "(" + "#{user_row.email}, error: "
                msg += cc.errors.full_messages.join(", ") + ")"
                raise ImportError, msg
              end
              user.touch unless user_touched
              user.clear_email_cache!
            end
            pseudo.sis_communication_channel_id = pseudo.communication_channel_id = cc.id

            if newly_active
              user_ids = ccs.map(&:user_id)
              pseudo_scope = Pseudonym.active.where(user_id: user_ids).group(:user_id)
              active_pseudo_counts = pseudo_scope.count
              sis_pseudo_counts = pseudo_scope.where('account_id = ? AND sis_user_id IS NOT NULL', @root_account).count

              other_ccs = ccs.reject { |other_cc|
                cc_user_id = other_cc.user_id
                same_user = cc_user_id == user.id
                no_active_pseudos = active_pseudo_counts.fetch(cc_user_id, 0) == 0
                active_sis_pseudos = sis_pseudo_counts.fetch(cc_user_id, 0) != 0

                same_user || no_active_pseudos || active_sis_pseudos
              }
              unless other_ccs.empty?
                cc.send_merge_notification!
              end
            end
          elsif user_row.email.present? && EmailAddressValidator.valid?(user_row.email) == false
            message = "The email address associated with user '#{user_row.user_id}' is invalid (email: '#{user_row.email}')"
            @messages << SisBatch.build_error(user_row.csv, message, sis_batch: @batch, row: user_row.lineno, row_info: user_row.row_info)
            next
          end

          if pseudo.changed?
            pseudo.sis_batch_id = user_row.sis_batch_id if user_row.sis_batch_id
            pseudo.sis_batch_id = @batch.id if @batch
            if pseudo.valid?
              pseudo.save_without_broadcasting
            else
              msg = "A user did not pass validation "
              msg += "(" + "user: #{user_row.user_id}, error: "
              msg += pseudo.errors.full_messages.join(", ") + ")"
              raise ImportError, msg
            end
          elsif @batch && pseudo.sis_batch_id != @batch.id
            @pseudos_to_set_sis_batch_ids << pseudo.id
          end
          maybe_write_roll_back_data

          @success_count += 1
        end
      end

      def maybe_write_roll_back_data
        if @roll_back_data.count > 1000
          SisBatchRollBackData.bulk_insert_roll_back_data(@roll_back_data)
          @roll_back_data = []
        end
      end

      def remove_enrollments_if_last_login(user, user_id)
        return false if @root_account.pseudonyms.active.where(user_id: user).where("sis_user_id != ? OR sis_user_id IS NULL", user_id).exists?

        enrollments = @root_account.enrollments.active.where(user_id: user).
          where.not(workflow_state: 'deleted').select(:id, :workflow_state).to_a
        if enrollments.any?
          Enrollment.where(id: enrollments.map(&:id)).update_all(updated_at: Time.now.utc, workflow_state: 'deleted')
          EnrollmentState.where(enrollment_id: enrollments.map(&:id)).update_all(state: 'deleted', state_is_current: true)
          e_data = SisBatchRollBackData.build_dependent_data(sis_batch: @batch, contexts: enrollments, updated_state: 'deleted')
          @roll_back_data.push(*e_data) if e_data
        end
        gms = @root_account.all_group_memberships.active.where(user_id: user).select(:id, :workflow_state).to_a
        gm_data = SisBatchRollBackData.build_dependent_data(sis_batch: @batch, contexts: gms, updated_state: 'deleted')
        @roll_back_data.push(*gm_data) if gm_data

        admins = user.account_users.active.shard(@root_account).where(account_id: @root_account.all_accounts).select(:id, :workflow_state).to_a
        a_data = SisBatchRollBackData.build_dependent_data(sis_batch: @batch, contexts: admins, updated_state: 'deleted')
        @roll_back_data.push(*a_data) if a_data

        root_admins = user.account_users.active.shard(@root_account).where(account_id: @root_account).select(:id, :workflow_state).to_a
        r_data = SisBatchRollBackData.build_dependent_data(sis_batch: @batch, contexts: root_admins, updated_state: 'deleted')
        @roll_back_data.push(*r_data) if r_data

        d = enrollments.count
        d += @root_account.all_group_memberships.active.where(user_id: user).
          update_all(updated_at: Time.now.utc, workflow_state: 'deleted')
        d += user.account_users.active.shard(@root_account).where(account_id: @root_account.all_accounts).
          update_all(updated_at: Time.now.utc, workflow_state: 'deleted')
        d += user.account_users.active.shard(@root_account).where(account_id: @root_account).
          update_all(updated_at: Time.now.utc, workflow_state: 'deleted')
        if d > 0
          should_update_account_associations = true
        end
        should_update_account_associations
      end

      private

      def generate_user_warning(message, user_id, login_id)
        user_message = generate_readable_error_message(
          message: message,
          user_id: user_id,
          login_id: login_id
        )
        user_message
      end

      ERRORS_TO_REASONS = {
        'unique_id is invalid' => "Invalid login_id: '%{login_id}'",
      }.freeze
      DEFAULT_REASON = 'Unknown reason: %{message}'.freeze

      def generate_readable_error_message(options)
        response = ERRORS_TO_REASONS.fetch(options[:message]) { DEFAULT_REASON }
        reason = format(response, options)
        result = "Could not save the user with user_id: '#{options[:user_id]}'."
        result << " #{reason}"
        result
      end
    end
  end
end
