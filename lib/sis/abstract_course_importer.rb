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
  class AbstractCourseImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      AbstractCourse.process_as_sis(@sis_options) do
        yield importer
      end
      importer.abstract_courses_to_update_sis_batch_id.in_groups_of(1000, false) do |batch|
        AbstractCourse.where(:id => batch).update_all(:sis_batch_id => @batch.id)
      end if @batch
      @logger.debug("AbstractCourses took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :abstract_courses_to_update_sis_batch_id

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @abstract_courses_to_update_sis_batch_id = []
        @logger = logger
        @success_count = 0
      end

      def add_abstract_course(abstract_course_id, short_name, long_name, status, term_id=nil, account_id=nil, fallback_account_id=nil)
        @logger.debug("Processing AbstractCourse #{[abstract_course_id, short_name, long_name, status, term_id, account_id, fallback_account_id].inspect}")

        raise ImportError, "No abstract_course_id given for an abstract course" if abstract_course_id.blank?
        raise ImportError, "No short_name given for abstract course #{abstract_course_id}" if short_name.blank?
        raise ImportError, "No long_name given for abstract course #{abstract_course_id}" if long_name.blank?
        raise ImportError, "Improper status \"#{status}\" for abstract course #{abstract_course_id}" unless status =~ /\Aactive|\Adeleted/i
        return if @batch.skip_deletes? && status =~ /deleted/i

        course = AbstractCourse.where(root_account_id: @root_account, sis_source_id: abstract_course_id).take
        course ||= AbstractCourse.new
        if !course.stuck_sis_fields.include?(:enrollment_term_id)
          course.enrollment_term = @root_account.enrollment_terms.where(sis_source_id: term_id).take || @root_account.default_enrollment_term
        end
        course.root_account = @root_account

        account = nil
        account = @root_account.all_accounts.where(sis_source_id: account_id).take if account_id.present?
        account ||= @root_account.all_accounts.where(sis_source_id: fallback_account_id).take if fallback_account_id.present?
        course.account = account if account
        course.account ||= @root_account

        # only update the name/short_name on new records, and ones that haven't been changed
        # since the last sis import
        course.name = long_name if long_name.present? && (course.new_record? || (!course.stuck_sis_fields.include?(:name)))
        course.short_name = short_name if short_name.present? && (course.new_record? || (!course.stuck_sis_fields.include?(:short_name)))

        course.sis_source_id = abstract_course_id
        if status =~ /active/i
          course.workflow_state = 'active'
        elsif status =~ /deleted/i
          course.workflow_state = 'deleted'
        end

        if course.changed?
          course.sis_batch_id = @batch.id if @batch
          course.save!
        elsif @batch
          @abstract_courses_to_update_sis_batch_id << course.id
        end
        @success_count += 1
      end

    end

  end
end
