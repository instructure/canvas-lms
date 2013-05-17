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
  class TermImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch_id, @root_account, @logger)
      EnrollmentTerm.process_as_sis(@sis_options) do
        yield importer
      end
      @logger.debug("Terms took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count

      def initialize(batch_id, root_account, logger)
        @batch_id = batch_id
        @root_account = root_account
        @logger = logger
        @success_count = 0
      end

      def add_term(term_id, name, status, start_date=nil, end_date=nil)
        @logger.debug("Processing Term #{[term_id, name, status, start_date, end_date].inspect}")

        raise ImportError, "No term_id given for a term" if term_id.blank?
        raise ImportError, "No name given for term #{term_id}" if name.blank?
        raise ImportError, "Improper status \"#{status}\" for term #{term_id}" unless status =~ /\Aactive|\Adeleted/i

        term = @root_account.enrollment_terms.find_by_sis_source_id(term_id)
        term ||= @root_account.enrollment_terms.new

        # only update the name on new records, and ones that haven't been
        # changed since the last sis import
        if term.new_record? || !term.stuck_sis_fields.include?(:name)
          term.name = name
        end

        term.sis_source_id = term_id
        term.sis_batch_id = @batch_id if @batch_id
        if status =~ /active/i
          term.workflow_state = 'active'
        elsif status =~ /deleted/i
          term.workflow_state = 'deleted'
        end

        if (term.stuck_sis_fields & [:start_at, :end_at]).empty?
          term.start_at = start_date
          term.end_at = end_date
        end

        if term.save
          @success_count += 1
        else
          msg = "A term did not pass validation "
          msg += "(" + "term: #{term_id} / #{name}, error: "
          msg += term.errors.full_messages.join(", ") + ")"
          raise ImportError, msg
        end
      end

    end
  end
end
