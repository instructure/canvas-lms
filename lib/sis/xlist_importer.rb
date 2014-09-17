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
  class XlistImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch, @root_account, @logger)
      Course.suspend_callbacks(:update_enrollments_later) do
        Course.process_as_sis(@sis_options) do
          CourseSection.process_as_sis(@sis_options) do
            Course.skip_updating_account_associations do
              yield importer
            end
          end
        end
      end
      Course.update_account_associations(importer.course_ids_to_update_associations.to_a) unless importer.course_ids_to_update_associations.empty?
      @logger.debug("Crosslists took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :course_ids_to_update_associations

      def initialize(batch, root_account, logger)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @success_count = 0

        @course = nil
        @course_ids_to_update_associations = [].to_set
      end

      def add_crosslist(xlist_course_id, section_id, status)
        @logger.debug("Processing CrossListing #{[xlist_course_id, section_id, status].inspect}")

        raise ImportError, "No xlist_course_id given for a cross-listing" if xlist_course_id.blank?
        raise ImportError, "No section_id given for a cross-listing" if section_id.blank?
        raise ImportError, "Improper status \"#{status}\" for a cross-listing" unless status =~ /\A(active|deleted)\z/i

        section = @root_account.course_sections.where(sis_source_id: section_id).first
        raise ImportError, "A cross-listing referenced a non-existent section #{section_id}" unless section

        unless @course && @course.sis_source_id == xlist_course_id
          @course = @root_account.all_courses.where(sis_source_id: xlist_course_id).first
          if !@course && status =~ /\Aactive\z/i
            # no course with this crosslist id found, make a new course,
            # using the section's current course as a template
            @course = Course.new
            @course.root_account = @root_account
            @course.account_id = section.course.account_id
            @course.name = section.course.name
            @course.course_code = section.course.course_code
            @course.enrollment_term_id = section.course.enrollment_term_id
            @course.start_at = section.course.start_at
            @course.conclude_at = section.course.conclude_at
            @course.restrict_enrollments_to_course_dates = section.course.restrict_enrollments_to_course_dates
            @course.sis_source_id = xlist_course_id
            @course.sis_batch_id = @batch.id if @batch
            @course.workflow_state = 'claimed'
            @course.template_course = section.course
            @course.save_without_broadcasting!
            @course_ids_to_update_associations.add @course.id
          end
        end

        unless section.stuck_sis_fields.include?(:course_id)
          if status =~ /\Aactive\z/i

            if @course.deleted?
              @course.workflow_state = 'claimed'
              @course.save_without_broadcasting!
              @course.update_enrolled_users
              @course_ids_to_update_associations.add @course.id
            end

            if section.course_id == @course.id
              @success_count += 1
              return
            end

            begin
              @course_ids_to_update_associations.merge [@course.id, section.course_id, section.nonxlist_course_id].compact
              section.crosslist_to_course(@course, :run_jobs_immediately)
            rescue => e
              raise ImportError, "An active cross-listing failed: #{e}"
            end

          elsif status =~ /\Adeleted\z/i
            if @course && section.course_id != @course.id
              @success_count += 1
              return
            end

            begin
              @course_ids_to_update_associations.merge [section.course_id, section.nonxlist_course_id]
              section.uncrosslist(:run_jobs_immediately)
            rescue => e
              raise ImportError, "A deleted cross-listing failed: #{e}"
            end

          else
            raise ImportError, "Improper status #{status} for a cross-listing"
          end

          @success_count += 1
        end
      end
    end
  end
end
