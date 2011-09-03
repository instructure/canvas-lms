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
  class UserImporter < SisImporter

    def self.is_user_csv?(row)
      row.header?('user_id') && row.header?('login_id')
    end

    def verify(csv, verify)
      user_ids = (verify[:user_ids] ||= {})
      identical_row_checker = (verify[:user_rows] ||= {})
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        user_id = row['user_id']
        if user_ids[user_id]
          if identical_row_checker[user_id] != row
            add_error(csv, "Non-identical duplicate user rows for #{user_id}")
          else
            add_warning(csv, "Duplicate user id #{user_id}")
          end
        else
          identical_row_checker[user_id] = row
        end
        user_ids[user_id] = true
        add_error(csv, "No user_id given for a user") if row['user_id'].blank?
        add_error(csv, "No login_id given for user #{user_id}") if row['login_id'].blank?
#        add_error(csv, "No email given for user #{user_id}") if row['email'].blank?
        add_error(csv, "Improper status for user #{user_id}") unless row['status'] =~ /active|deleted/i
      end
    end

    # expected columns:
    # user_id,login_id,first_name,last_name,email,status
    def process(csv)
      start = Time.now
      users_to_set_sis_batch_ids = []
      pseudos_to_set_sis_batch_ids = []

      User.skip_updating_account_associations do
        FasterCSV.open(csv[:fullpath], "rb", :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |csv_object|
          row = csv_object.shift
          count = 0
          until row.nil?
            update_progress(count)
            count = 0
            # this transaction assumes that the users and pseudonyms are in the same database
            User.transaction do
              remaining_in_transaction = @sis.updates_every
              tx_end_time = Time.now + Setting.get('sis_transaction_seconds', '1').to_i.seconds

              begin
                logger.debug("Processing User #{row.inspect}")

                count += 1
                remaining_in_transaction -= 1

                update_account_association = false

                pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, row['user_id'])
                pseudo_by_login = Pseudonym.find_by_unique_id_and_account_id(row['login_id'], @root_account.id)
                pseudo ||= pseudo_by_login
                pseudo ||= Pseudonym.find_by_unique_id_and_account_id(row['email'], @root_account.id) if row['email'].present?

                if pseudo
                  if pseudo.sis_user_id.present? && pseudo.sis_user_id != row['user_id']
                    add_warning(csv, "user #{pseudo.sis_user_id} has already claimed #{row['user_id']}'s requested login information, skipping")
                    @sis.counts[:users] += 1
                    next
                  end
                  if !pseudo_by_login.nil? && pseudo.unique_id != row['login_id']
                    add_warning(csv, "user #{pseudo_by_login.sis_user_id} has already claimed #{row['user_id']}'s requested login information, skipping")
                    @sis.counts[:users] += 1
                    next
                  end

                  user = pseudo.user
                  user.name = user.sis_name = "#{row['first_name']} #{row['last_name']}" if user.sis_name && user.sis_name == user.name
                  update_account_association = (pseudo.account_id != @root_account.id)

                else
                  user = User.new
                  user.name = user.sis_name = "#{row['first_name']} #{row['last_name']}"
                  update_account_association = true
                end

                if row['status']=~ /active/i
                  user.workflow_state = 'registered'
                elsif row['status']=~ /deleted/i
                  user.workflow_state = 'deleted'
                  enrolls = user.enrollments.find_all_by_root_account_id(@root_account.id).map(&:id)
                  Enrollment.update_all({:workflow_state => 'deleted'}, :id => enrolls)
                end

                pseudo ||= Pseudonym.new
                pseudo.unique_id = row['login_id']
                pseudo.sis_source_id = row['login_id']
                pseudo.sis_user_id = row['user_id']
                pseudo.account = @root_account
                pseudo.workflow_state = row['status']=~ /active/i ? 'active' : 'deleted'
                if !row['password'].blank? && (pseudo.new_record? || pseudo.password_auto_generated)
                  pseudo.password = row['password']
                  pseudo.password_confirmation = row['password']
                  pseudo.password_auto_generated = true
                end
                pseudo.sis_ssha = row['ssha_password'] if !row['ssha_password'].blank?

                begin
                  User.transaction(:requires_new => true) do
                    if user.changed?
                      user.creation_sis_batch_id = @batch.id if @batch
                      raise user.errors.first.join(" ") if !user.save_without_broadcasting && user.errors.size > 0
                    elsif @batch
                      users_to_set_sis_batch_ids << user.id
                    end
                    pseudo.user_id = user.id
                    if pseudo.changed?
                      pseudo.sis_batch_id = @batch.id if @batch
                      raise pseudo.errors.first.join(" ") if !pseudo.save_without_broadcasting && pseudo.errors.size > 0
                    # we do the elsif @batch thing later
                    end
                  end
                rescue => e
                  add_warning(csv, "Failed saving user. Internal error: #{e}")
                  next
                end

                if row['email'].present?
                  comm = CommunicationChannel.find_by_path_and_workflow_state_and_path_type(row['email'], 'active', 'email')
                  if !comm and row['status']=~ /active/i
                    begin
                      comm = pseudo.sis_communication_channel || CommunicationChannel.new
                      if comm.new_record?
                        comm.user_id = user.id
                        comm.pseudonym_id = pseudo.id
                        pseudo.sis_communication_channel = comm
                      end
                      comm.path = row['email']
                      comm.workflow_state = 'active'
                      comm.do_delayed_jobs_immediately = true
                      comm.save_without_broadcasting if comm.changed?
                      pseudo.communication_channel_id = comm.id
                    rescue => e
                      add_warning(csv, "Failed adding communication channel #{row['email']} to user #{row['login_id']}")
                    end
                  end
                end

                if pseudo.changed?
                  pseudo.sis_batch_id = @batch.id if @batch
                  pseudo.save_without_broadcasting
                elsif @batch && pseudo.sis_batch_id != @batch.id
                  pseudos_to_set_sis_batch_ids << pseudo.id
                end

                user.update_account_associations if update_account_association

                @sis.counts[:users] += 1
              end while !(row = csv_object.shift).nil? && remaining_in_transaction > 0 && tx_end_time > Time.now
            end
          end
          User.update_all({:creation_sis_batch_id => @batch.id}, {:id => users_to_set_sis_batch_ids}) if @batch && !users_to_set_sis_batch_ids.empty?
          Pseudonym.update_all({:sis_batch_id => @batch.id}, {:id => pseudos_to_set_sis_batch_ids}) if @batch && !pseudos_to_set_sis_batch_ids.empty?
          logger.debug("Users took #{Time.now - start} seconds")
        end
      end
    end
  end
end
