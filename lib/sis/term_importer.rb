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
  class TermImporter < SisImporter
    
    EXPECTED_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
    
    def self.is_term_csv?(row)
      #This matcher works because a course has long_name/short_name
      row.header?('term_id') && row.header?('name')
    end
    
    def verify(csv, verify)
      term_ids = (verify[:terms_id] ||= {})
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        term_id = row['term_id']
        add_error(csv, "Duplicate term id #{term_id}") if term_ids[term_id]
        term_ids[term_id] = true
        add_error(csv, "No term_id given for a term") if row['term_id'].blank?
        add_error(csv, "No name given for term #{term_id}") if row['name'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for term #{term_id}") unless row['status'] =~ /\Aactive|\Adeleted/i
      end
    end
    
    # expected columns
    # account_id,parent_account_id,name,status
    def process(csv)
      start = Time.now
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        update_progress
        logger.debug("Processing Term #{row.inspect}")
        
        term = nil
        term = @root_account.enrollment_terms.find_by_sis_source_id(row['term_id'])
        term ||= @root_account.enrollment_terms.new
        
        # only update the name on new records, and ones that haven't been changed since the last sis import
        if term.new_record? || (term.sis_name && term.sis_name == term.name)
          term.name = term.sis_name = row['name']
        end
        
        term.sis_source_id = row['term_id']
        term.sis_batch_id = @batch.id if @batch
        if row['status'] =~ /active/i
          term.workflow_state = 'active'
        elsif  row['status'] =~ /deleted/i
          term.workflow_state = 'deleted'
        end
        
        begin
          unless row['start_date'].blank?
            term.start_at = DateTime.parse(row['start_date'])
          end
          unless row['end_date'].blank?
            term.end_at = DateTime.parse(row['end_date'])
          end
        rescue
          add_warning(csv, "Bad date format for term #{row['term_id']}")
        end
        
        term.save
        @sis.counts[:terms] += 1
      end
      logger.debug("Terms took #{Time.now - start} seconds")
    end
  end
end
