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
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        logger.debug("Processing User #{row.inspect}")

        update_progress

        User.skip_updating_user_account_associations do
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

          user.creation_sis_batch_id = @batch.id if @batch
          user.save_without_broadcasting

          pseudo ||= Pseudonym.new
          pseudo.user_id = user.id
          pseudo.unique_id = row['login_id']
          pseudo.sis_source_id = row['login_id']
          pseudo.sis_user_id = row['user_id']
          pseudo.account_id = @root_account.id
          pseudo.workflow_state = row['status']=~ /active/i ? 'active' : 'deleted'
          pseudo.sis_batch_id = @batch.id if @batch
          if !row['password'].blank? && (pseudo.new_record? || pseudo.password_auto_generated) 
            pseudo.password = row['password']
            pseudo.password_confirmation = row['password']
          end
          pseudo.save_without_broadcasting

          if row['email'].present?
            comm = CommunicationChannel.find_by_path_and_workflow_state_and_path_type(row['email'], 'active', 'email')
            if !comm and row['status']=~ /active/i
              begin
                comm = CommunicationChannel.new
                comm.user_id = user.id
                comm.path = row['email']
                comm.pseudonym_id = pseudo.id
                comm.workflow_state = 'active'
                comm.do_delayed_jobs_immediately = true
                comm.save_without_broadcasting

                pseudo.communication_channel_id = comm.id
                pseudo.save_without_broadcasting
              rescue => e
                add_warning(csv, "Failed adding communication channel #{row['email']} to user #{row['login_id']}")
              end
            end
          end

          user.update_account_associations if update_account_association
        end

        @sis.counts[:users] += 1
      end
      logger.debug("Users took #{Time.now - start} seconds")
    end
  end
end
