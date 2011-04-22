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
        add_error(csv, "No email given for user #{user_id}") if row['email'].blank?
        add_error(csv, "Improper status for user #{user_id}") unless row['status'] =~ /active|deleted/i
      end
    end

    # expected columns:
    # user_id,login_id,first_name,last_name,email,status
    def process(csv)
      start = Time.now
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        logger.debug("Processing User #{row.inspect}")

        update_account_association = false

        update_progress

        # First we look in the account for a user that already has this login id,
        # then we check globally for any user with the supplied email address.
        user = @root_account.find_user_by_unique_id(row['login_id']) ||
                User.find_by_email(row['email']) ||
                User.new

        update_account_association = user.new_record?

        # Only update their name if it's a new record or it's an old one and it hasn't
        # been changed since the last SIS update (meaning, the user hasn't changed it
        # themselves.)
        if user.new_record? || (user.sis_name && user.sis_name == user.name)
          user.name = user.sis_name = "#{row['first_name']} #{row['last_name']}"
        end

        if row['status']=~ /active/i
          user.workflow_state = 'registered'
        elsif  row['status']=~ /deleted/i
          user.workflow_state = 'deleted'
          enrolls = user.enrollments.find_all_by_root_account_id(@root_account.id).map(&:id)
          Enrollment.update_all({:workflow_state => 'deleted'}, :id => enrolls)
        end
        user.creation_sis_batch_id = @batch.id if @batch
        user.save_without_broadcasting

        pseudo = user.pseudonyms.find_by_unique_id(row['login_id'])
        pseudo ||= Pseudonym.new
        pseudo.user_id = user.id
        pseudo.unique_id = row['login_id']
        pseudo.sis_source_id = row['login_id']
        pseudo.sis_user_id = row['user_id']
        update_account_association = true if pseudo.account_id != @root_account.id
        pseudo.account_id = @root_account.id
        pseudo.workflow_state = row['status']=~ /active/i ? 'active' : 'deleted'
        pseudo.sis_batch_id = @batch.id if @batch
        if !row['password'].blank? && (pseudo.new_record? || pseudo.password_auto_generated) 
          pseudo.password = row['password']
          pseudo.password_confirmation = row['password']
        end
        pseudo.save_without_broadcasting

        comm = CommunicationChannel.find_by_path_and_workflow_state_and_path_type(row['email'], 'active', 'email')
        if !comm and row['status']=~ /active/i
          comm = CommunicationChannel.new
          comm.user_id = user.id
          comm.path = row['email']
          comm.pseudonym_id = pseudo.id
          comm.workflow_state = 'active'
          comm.do_delayed_jobs_immediately = true
          comm.save_without_broadcasting

          pseudo.communication_channel_id = comm.id
          pseudo.save_without_broadcasting
        end
        
        user.update_account_associations if update_account_association
        
        @sis.counts[:users] += 1
      end
      logger.debug("Users took #{Time.now - start} seconds")
    end
  end
end