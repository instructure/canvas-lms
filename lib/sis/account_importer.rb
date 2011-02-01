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
  class AccountImporter < SisImporter
    
    def self.is_account_csv?(row)
      row.header?('account_id') && row.header?('parent_account_id')
    end
    
    def verify(csv, verify)
      account_ids = (verify[:account_ids] ||= {})
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        account_id = row['account_id']
        add_error(csv, "Duplicate account id #{account_id}") if account_ids[account_id]
        account_ids[account_id] = true
        add_error(csv, "No account_id given for an account") if row['account_id'].blank?
        add_error(csv, "No name given for account #{account_id}") if row['name'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for account #{account_id}") unless row['status'] =~ /\Aactive|\Adeleted/i
        if !row['parent_account_id'].blank? && !account_ids[row['parent_account_id']]
          # todo: if it's a batch import we can just give a warning 
          # (because the parent account may already exist in the system)
          add_error(csv, "Non-listed parent account referenced in csv for account #{account_id}")
        end
      end
    end
    
    # expected columns
    # account_id,parent_account_id,name,status
    def process(csv)
      start = Time.now
      accounts_cache = {}
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        update_progress
        logger.debug("Processing Account #{row.inspect}")
        
        parent = nil
        if !row['parent_account_id'].blank?
          parent = accounts_cache[row['parent_account_id']]
          parent ||= Account.find_by_parent_account_id_and_sis_source_id(@root_account.id, row['parent_account_id'])
          unless parent
            logger.warn "Parent account didn't exist for #{row['account_id']}"
            #todo: need to let submitter know somehow...
            next
          end
        end
        
        account = nil
        account = Account.find_by_root_account_id_and_sis_source_id(@root_account.id, row['account_id'])
        account ||= @root_account.sub_accounts.new
        account.root_account_id = @root_account.id
        account.parent_account_id = parent ? parent.id : @root_account.id
        
        # only update the name on new records, and ones that haven't been changed since the last sis import
        if account.new_record? || (account.sis_name && account.sis_name == account.name)
          account.name = account.sis_name = row['name']
        end
        
        account.sis_source_id = row['account_id']
        account.sis_batch_id = @batch.id if @batch
        if row['status'] =~ /active/i
          account.workflow_state = 'active'
        elsif  row['status'] =~ /deleted/i
          account.workflow_state = 'deleted'
        end
        
        account.save
        @sis.counts[:accounts] += 1
        accounts_cache[account.sis_source_id] = account
      end
      logger.debug("Accounts took #{Time.now - start} seconds")
    end
  end
end
