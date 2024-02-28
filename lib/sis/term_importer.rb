# frozen_string_literal: true

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
  class TermImporter < BaseImporter
    def process
      importer = Work.new(@batch, @root_account, @logger)
      EnrollmentTerm.process_as_sis(@sis_options) do
        EnrollmentDatesOverride.process_as_sis(@sis_options) do
          yield importer
        end
      end
      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)

      importer.success_count
    end

    class Work
      attr_accessor :success_count, :roll_back_data

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @roll_back_data = []
        @logger = logger
        @success_count = 0
      end

      def add_term(term_id, name, status, start_date = nil, end_date = nil, integration_id = nil, date_override_enrollment_type = nil)
        raise ImportError, "No term_id given for a term" if term_id.blank?
        raise ImportError, "Improper status \"#{status}\" for term #{term_id}" unless /\Aactive|\Adeleted/i.match?(status)
        return if @batch.skip_deletes? && status =~ /deleted/i

        term = @root_account.enrollment_terms.where(sis_source_id: term_id).first_or_initialize
        term.sis_batch_id = @batch.id

        if date_override_enrollment_type
          # only configure the date override if this row is present
          raise ImportError, "Cannot set date override on non-existent term" if term.new_record?
          unless %w[StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment].include?(date_override_enrollment_type)
            raise ImportError, "Invalid date_override_enrollment_type"
          end

          date_override = term.enrollment_dates_overrides.where(enrollment_type: date_override_enrollment_type).order(:id).first
          unless date_override&.stuck_sis_fields&.intersect?(%i[start_at end_at])
            case status
            when /active/i
              date_override ||= term.enrollment_dates_overrides.build(context: @root_account, enrollment_type: date_override_enrollment_type)
              date_override.update!(start_at: start_date, end_at: end_date)
            when /deleted/i
              term.enrollment_dates_overrides.where(enrollment_type: date_override_enrollment_type).destroy_all
            end
          end
        else
          raise ImportError, "No name given for term #{term_id}" if name.blank?

          # only update the name on new records, and ones that haven't been
          # changed since the last sis import
          if term.new_record? || !term.stuck_sis_fields.include?(:name)
            term.name = name
          end

          term.integration_id = integration_id

          case status
          when /active/i
            term.workflow_state = "active"
          when /deleted/i
            term.workflow_state = "deleted"
          end
          unless term.stuck_sis_fields.intersect?([:start_at, :end_at])
            term.start_at = start_date
            term.end_at = end_date
          end
        end

        if term.save
          data = SisBatchRollBackData.build_data(sis_batch: @batch, context: term)
          @roll_back_data << data if data
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
