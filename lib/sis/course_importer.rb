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
  class CourseImporter < BaseImporter

    def process(messages)
      start = Time.now
      courses_to_update_sis_batch_id = []
      course_ids_to_update_associations = [].to_set

      importer = Work.new(@batch, @root_account, @logger, courses_to_update_sis_batch_id, course_ids_to_update_associations, messages, @batch_user)
      Course.suspend_callbacks(:update_enrollments_later) do
        Course.process_as_sis(@sis_options) do
          Course.skip_updating_account_associations do
            yield importer
          end
        end
      end

      Course.update_account_associations(course_ids_to_update_associations.to_a) unless course_ids_to_update_associations.empty?
      courses_to_update_sis_batch_id.in_groups_of(1000, false) do |batch|
        Course.where(:id => batch).update_all(:sis_batch_id => @batch)
      end if @batch
      @logger.debug("Courses took #{Time.now - start} seconds")
      return importer.success_count
    end

  private

    class Work
      attr_accessor :success_count

      def initialize(batch, root_account, logger, a1, a2, m, batch_user)
        @batch = batch
        @batch_user = batch_user
        @root_account = root_account
        @courses_to_update_sis_batch_id = a1
        @course_ids_to_update_associations = a2
        @messages = m
        @logger = logger
        @success_count = 0
      end

      def add_course(course_id, term_id, account_id, fallback_account_id, status, start_date, end_date, abstract_course_id, short_name, long_name, integration_id)
        state_changes = []
        @logger.debug("Processing Course #{[course_id, term_id, account_id, fallback_account_id, status, start_date, end_date, abstract_course_id, short_name, long_name].inspect}")

        raise ImportError, "No course_id given for a course" if course_id.blank?
        raise ImportError, "No short_name given for course #{course_id}" if short_name.blank? && abstract_course_id.blank?
        raise ImportError, "No long_name given for course #{course_id}" if long_name.blank? && abstract_course_id.blank?
        raise ImportError, "Improper status \"#{status}\" for course #{course_id}" unless status =~ /\A(active|deleted|completed)/i

        course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, course_id)
        if course.nil?
          course = Course.new
          state_changes << :created
        else
          state_changes << :updated
        end
        course_enrollment_term_id_stuck = course.stuck_sis_fields.include?(:enrollment_term_id)
        if !course_enrollment_term_id_stuck && term_id
          term = @root_account.enrollment_terms.active.find_by_sis_source_id(term_id)
        end
        course.enrollment_term = term if term
        course.root_account = @root_account

        account = nil
        account = Account.find_by_root_account_id_and_sis_source_id(@root_account.id, account_id) if account_id.present?
        account ||= Account.find_by_root_account_id_and_sis_source_id(@root_account.id, fallback_account_id) if fallback_account_id.present?
        course.account = account if account
        course.account ||= @root_account

        update_account_associations = course.account_id_changed? || course.root_account_id_changed?

        course.integration_id = integration_id
        course.sis_source_id = course_id
        if !course.stuck_sis_fields.include?(:workflow_state)
          if status =~ /active/i
            if course.workflow_state == 'completed'
              course.workflow_state = 'available'
              state_changes << :unconcluded
            elsif course.workflow_state != 'available'
              course.workflow_state = 'claimed'
              state_changes << :published
            end
          elsif status =~ /deleted/i
            course.workflow_state = 'deleted'
            state_changes << :deleted
          elsif status =~ /completed/i
            course.workflow_state = 'completed'
            state_changes << :concluded
          end
        end

        course_dates_stuck = !(course.stuck_sis_fields & [:start_at, :conclude_at, :restrict_enrollments_to_course_dates]).empty?
        if !course_dates_stuck
          course.start_at = start_date
          course.conclude_at = end_date
          course.restrict_enrollments_to_course_dates = (course.start_at.present? || course.conclude_at.present?)
        end

        abstract_course = nil
        if abstract_course_id.present?
          abstract_course = AbstractCourse.find_by_root_account_id_and_sis_source_id(@root_account.id, abstract_course_id)
          @messages << "unknown abstract course id #{abstract_course_id}, ignoring abstract course reference" unless abstract_course
        end

        if abstract_course
          if term_id.blank? && course.enrollment_term_id != abstract_course.enrollment_term && !course_enrollment_term_id_stuck
            course.send(:association_instance_set, :enrollment_term, nil)
            course.enrollment_term_id = abstract_course.enrollment_term_id
          end
          if account_id.blank? && course.account_id != abstract_course.account_id
            course.send(:association_instance_set, :account, nil)
            course.account_id = abstract_course.account_id
          end
        end
        course.abstract_course = abstract_course

        # only update the name/short_name on new records, and ones that haven't been changed
        # since the last sis import
        course_course_code_stuck = course.stuck_sis_fields.include?(:course_code)
        if course.course_code.blank? || !course_course_code_stuck
          if short_name.present?
            course.course_code = short_name
          elsif abstract_course && course.course_code.blank?
            course.course_code = abstract_course.short_name
          end
        end
        course_name_stuck = course.stuck_sis_fields.include?(:name)
        if course.name.blank? || !course_name_stuck
          if long_name.present?
            course.name = long_name
          elsif abstract_course && course.name.blank?
            course.name = abstract_course.name
          end
        end

        update_enrollments = !course.new_record? && !(course.changes.keys & ['workflow_state', 'name', 'course_code']).empty?

        if course.changed?
          course.templated_courses.each do |templated_course|
            templated_course.root_account = @root_account
            templated_course.account = course.account
            templated_course.name = course.name if !templated_course.stuck_sis_fields.include?(:name) && !course_name_stuck
            templated_course.course_code = course.course_code if !templated_course.stuck_sis_fields.include?(:course_code) && !course_course_code_stuck
            templated_course.enrollment_term = course.enrollment_term if !templated_course.stuck_sis_fields.include?(:enrollment_term_id) && !course_enrollment_term_id_stuck
            if (templated_course.stuck_sis_fields & [:start_at, :conclude_at, :restrict_enrollments_to_course_dates]).empty? && !course_dates_stuck
              templated_course.start_at = course.start_at
              templated_course.conclude_at = course.conclude_at
              templated_course.restrict_enrollments_to_course_dates = course.restrict_enrollments_to_course_dates
            end
            templated_course.sis_batch_id = @batch.id if @batch
            @course_ids_to_update_associations.add(templated_course.id) if templated_course.account_id_changed? || templated_course.root_account_id_changed?
            if templated_course.valid?
              changes = templated_course.changes
              templated_course.save_without_broadcasting!
              Auditors::Course.record_updated(templated_course, @batch_user, changes, source: :sis, sis_batch_id: @batch_id)
            else
              msg = "A (templated) course did not pass validation "
              msg += "(" + "course: #{course_id} / #{short_name}, error: " +
              msg += templated_course.errors.full_messages.join(",") + ")"
              raise ImportError, msg
            end
          end
          course.sis_batch_id = @batch.id if @batch
          if course.valid?
            course_changes = course.changes
            course.save_without_broadcasting!
            auditor_state_changes(course, state_changes, course_changes)
          else
            msg = "A course did not pass validation "
            msg += "(" + "course: #{course_id} / #{short_name}, error: " +
            msg += course.errors.full_messages.join(",") + ")"
            raise ImportError, msg
          end
          @course_ids_to_update_associations.add(course.id) if update_account_associations
        elsif @batch
          @courses_to_update_sis_batch_id << course.id
        end

        course.update_enrolled_users if update_enrollments
        @success_count += 1
      end

      def auditor_state_changes(course, state_changes, changes = {})
        options = {
          source: :sis,
          sis_batch: @batch
        }

        state_changes.each do |state_change|
          case state_change
            when :created
              Auditors::Course.record_created(course, @batch_user, changes, options)
            when :updated
              Auditors::Course.record_updated(course, @batch_user, changes, options)
            when :concluded
              Auditors::Course.record_concluded(course, @batch_user, options)
            when :unconcluded
              Auditors::Course.record_unconcluded(course, @batch_user, options)
            when :published
              Auditors::Course.record_published(course, @batch_user, options)
            when :deleted
              Auditors::Course.record_deleted(course, @batch_user, options)
            when :restored
              Auditors::Course.record_restored(course, @batch_user, options)
          end
        end
      end
    end
  end
end
