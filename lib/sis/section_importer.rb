#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  class SectionImporter < BaseImporter

    def process
      start = Time.now
      importer = Work.new(@batch_id, @root_account, @logger)
      Course.skip_updating_account_associations do
        CourseSection.process_as_sis(@sis_options) do
          yield importer
        end
      end
      Course.update_account_associations(importer.course_ids_to_update_associations.to_a) unless importer.course_ids_to_update_associations.empty?
      importer.sections_to_update_sis_batch_ids.in_groups_of(1000, false) do |batch|
        CourseSection.where(:id => batch).update_all(:sis_batch_id => @batch_id)
      end if @batch_id
      @logger.debug("Sections took #{Time.now - start} seconds")
      return importer.success_count
    end

  private
    class Work
      attr_accessor :success_count, :sections_to_update_sis_batch_ids, :course_ids_to_update_associations

      def initialize(batch_id, root_account, logger)
        @batch_id = batch_id
        @root_account = root_account
        @logger = logger
        @success_count = 0
        @sections_to_update_sis_batch_ids = []
        @course_ids_to_update_associations = [].to_set
      end

      def add_section(section_id, course_id, name, status, start_date=nil, end_date=nil)
        @logger.debug("Processing Section #{[section_id, course_id, name, status, start_date, end_date].inspect}")

        raise ImportError, "No section_id given for a section in course #{course_id}" if section_id.blank?
        raise ImportError, "No course_id given for a section #{section_id}" if course_id.blank?
        raise ImportError, "No name given for section #{section_id} in course #{course_id}" if name.blank?
        raise ImportError, "Improper status \"#{status}\" for section #{section_id} in course #{course_id}" unless status =~ /\Aactive|\Adeleted/i

        course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, course_id)
        raise ImportError, "Section #{section_id} references course #{course_id} which doesn't exist" unless course

        section = CourseSection.find_by_root_account_id_and_sis_source_id(@root_account.id, section_id)
        section ||= course.course_sections.find_by_sis_source_id(section_id)
        section ||= course.course_sections.new
        section.root_account = @root_account
        # this is an easy way to load up the cache with data we already have
        section.course = course if course.id == section.course_id

        # only update the name on new records, and ones that haven't been changed since the last sis import
        section.name = name if section.new_record? || !section.stuck_sis_fields.include?(:name)

        # update the course id if necessary
        if section.course_id != course.id && !section.stuck_sis_fields.include?(:course_id)
          if section.nonxlist_course_id
            # this section is crosslisted
            if section.nonxlist_course_id != course.id
              # but the course id we were given didn't match the crosslist info
              # we have, so, uncrosslist and move
              @course_ids_to_update_associations.merge [course.id, section.course_id, section.nonxlist_course_id]
              section.uncrosslist(:run_jobs_immediately)
              section.move_to_course(course, :run_jobs_immediately)
            end
          else
            # this section isn't crosslisted and lives on the wrong course. move
            @course_ids_to_update_associations.merge [section.course_id, course.id]
            section.move_to_course(course, :run_jobs_immediately)
          end
        end
        if section.course_id_changed?
          @course_ids_to_update_associations.merge [section.course_id, section.course_id_was].compact
        end

        section.sis_source_id = section_id
        if status =~ /active/i
          section.workflow_state = 'active'
        elsif status =~ /deleted/i
          section.workflow_state = 'deleted'
        end

        if (section.stuck_sis_fields & [:start_at, :end_at]).empty?
          section.start_at = start_date
          section.end_at = end_date
        end
        section.restrict_enrollments_to_section_dates = (section.start_at.present? || section.end_at.present?) unless section.stuck_sis_fields.include?(:restrict_enrollments_to_section_dates)

        if section.changed?
          section.sis_batch_id = @batch_id if @batch_id
          if section.valid?
            section.save
          else
            msg = "A section did not pass validation "
            msg += "(" + "section: #{section_id} / #{name}, course: #{course_id}, error: "
            msg += section.errors.full_messages.join(", ") + ")"
            raise ImportError, msg
          end
        elsif @batch_id
          @sections_to_update_sis_batch_ids << section.id
        end

        @success_count += 1
      end
    end
  end
end
