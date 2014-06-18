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
  class GradePublishingResultsImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      yield importer
      @logger.debug("Grade publishing results took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0
      end

      def add_grade_publishing_result(enrollment_id, grade_publishing_status, message=nil)
        @logger.debug("Processing grade publishing result #{[enrollment_id, grade_publishing_status].inspect}")

        raise ImportError, "No enrollment_id given" if enrollment_id.blank?
        raise ImportError, "No grade_publishing_status given for enrollment #{enrollment_id}" if grade_publishing_status.blank?
        raise ImportError, "Improper grade_publishing_status \"#{grade_publishing_status}\" for enrollment #{enrollment_id}" unless %w{ published error }.include?(grade_publishing_status.downcase)

        if (Enrollment.where(:id => enrollment_id, :root_account_id => @root_account).
            update_all(:grade_publishing_status => grade_publishing_status.downcase,
                               :grade_publishing_message => message.to_s,
                               :updated_at => Time.now.utc) != 1)
          raise ImportError, "Enrollment #{enrollment_id} doesn't exist"
        end

        @success_count += 1
      end

    end

  end
end
