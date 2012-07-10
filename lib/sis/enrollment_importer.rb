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

require "set"
require "skip_callback"

module SIS
  class EnrollmentImporter < BaseImporter

    def process(messages, updates_every)
      start = Time.now
      i = Work.new(@batch_id, @root_account, @logger, updates_every, messages)
      Enrollment.skip_callback(:belongs_to_touch_after_save_or_destroy_for_course) do
        User.skip_updating_account_associations do
          Enrollment.process_as_sis(@sis_options) do
            yield i
            while i.any_left_to_process?
              i.process_batch
            end
          end
        end
      end
      @logger.debug("Raw enrollments took #{Time.now - start} seconds")
      Enrollment.update_all({:sis_batch_id => @batch_id}, {:id => i.enrollments_to_update_sis_batch_ids}) if @batch_id && !i.enrollments_to_update_sis_batch_ids.empty?
      # We batch these up at the end because we don't want to keep touching the same course over and over,
      # and to avoid hitting other callbacks for the course (especially broadcast_policy)
      Course.update_all({:updated_at => Time.now.utc}, {:id => i.courses_to_touch_ids.to_a}) unless i.courses_to_touch_ids.empty?
      # We batch these up at the end because normally a user would get several enrollments, and there's no reason
      # to update their account associations on each one.
      i.incrementally_update_account_associations
      User.update_account_associations(i.update_account_association_user_ids.to_a, :account_chain_cache => i.account_chain_cache)
      User.update_all({:updated_at => Time.now.utc}, {:id => i.users_to_touch_ids.to_a}) unless i.users_to_touch_ids.empty?
      @logger.debug("Enrollments with batch operations took #{Time.now - start} seconds")
      return i.success_count
    end

  private
    class Work
      attr_accessor :enrollments_to_update_sis_batch_ids, :courses_to_touch_ids,
          :incrementally_update_account_associations_user_ids, :update_account_association_user_ids,
          :account_chain_cache, :users_to_touch_ids, :success_count

      def initialize(batch_id, root_account, logger, updates_every, messages)
        @batch_id = batch_id
        @root_account = root_account
        @logger = logger
        @updates_every = updates_every
        @messages = messages

        @update_account_association_user_ids = Set.new
        @incrementally_update_account_associations_user_ids = Set.new
        @users_to_touch_ids = Set.new
        @courses_to_touch_ids = Set.new
        @enrollments_to_update_sis_batch_ids = []
        @account_chain_cache = {}
        @course = @section = nil

        @enrollment_batch = []
        @success_count = 0
      end

      def add_enrollment(course_id, section_id, user_id, role, status, start_date, end_date, associated_user_id=nil)
        raise ImportError, "No course_id or section_id given for an enrollment" if course_id.blank? && section_id.blank?
        raise ImportError, "No user_id given for an enrollment" if user_id.blank?
        raise ImportError, "Improper role \"#{role}\" for an enrollment" unless role =~ /\Astudent|\Ateacher|\Ata|\Aobserver|\Adesigner/i
        raise ImportError, "Improper status \"#{status}\" for an enrollment" unless status =~ /\Aactive|\Adeleted|\Acompleted|\Ainactive/i
        @enrollment_batch << [course_id, section_id, user_id, role, status, start_date, end_date, associated_user_id]
        process_batch if @enrollment_batch.size >= @updates_every
      end

      def any_left_to_process?
        return @enrollment_batch.size > 0
      end

      def process_batch
        return unless any_left_to_process?

        transaction_timeout = Setting.get('sis_transaction_seconds', '1').to_i.seconds
        Enrollment.transaction do
          tx_end_time = Time.now + transaction_timeout
          enrollment = nil
          while !@enrollment_batch.empty? && tx_end_time > Time.now
            enrollment = @enrollment_batch.shift
            @logger.debug("Processing Enrollment #{enrollment.inspect}")
            course_id, section_id, user_id, role, status, start_date, end_date, associated_user_id = enrollment

            last_section = @section
            # reset the cached course/section if they don't match this row
            if @course && course_id.present? && @course.sis_source_id != course_id
              @course = nil
              @section = nil
            end
            if @section && section_id.present? && @section.sis_source_id != section_id
              @section = nil
            end

            pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, user_id)
            user = pseudo.user rescue nil
            @course ||= Course.find_by_root_account_id_and_sis_source_id(@root_account.id, course_id) unless course_id.blank?
            @section ||= CourseSection.find_by_root_account_id_and_sis_source_id(@root_account.id, section_id) unless section_id.blank?
            unless (@course || @section)
              @messages << "Neither course #{course_id} nor section #{section_id} existed for user enrollment"
              next
            end
            unless user
              @messages << "User #{user_id} didn't exist for user enrollment"
              next
            end

            if section_id && !@section
              @messages << "An enrollment referenced a non-existent section #{section_id}"
              next
            end
            if course_id && !@course
              @messages << "An enrollment referenced a non-existent course #{course_id}"
              next
            end

            # reset cached/inferred course and section if they don't match with the opposite piece that was
            # explicitly provided
            @section = @course.default_section(:include_xlists => true) if @section.nil? || section_id.blank? && !@section.default_section
            @course = @section.course if @course.nil? || (course_id.blank? && @course.id != @section.course_id) || (@course.id != @section.course_id && @section.nonxlist_course_id == @course.id)

            if @course.id != @section.course_id
              @messages << "An enrollment listed a section and a course that are unrelated"
              next
            end

            # preload the course object to avoid later queries for it
            @section.course = @course

            # commit pending incremental account associations
            incrementally_update_account_associations if @section != last_section and !@incrementally_update_account_associations_user_ids.empty?

            type = if role =~ /\Ateacher\z/i
                'TeacherEnrollment'
              elsif role =~ /student/i
                'StudentEnrollment'
              elsif role =~ /\Ata\z|assistant/i
                'TaEnrollment'
              elsif role =~ /\Aobserver\z/i
                if associated_user_id
                  pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, associated_user_id)
                  associated_enrollment = pseudo && @course.student_enrollments.find_by_user_id(pseudo.user_id)
                end
                'ObserverEnrollment'
              elsif role =~ /\Adesigner\z/i
                'DesignerEnrollment'
              end

            enrollment = @section.all_enrollments.find(:first, :conditions => { :user_id => user.id, :type => type, :associated_user_id => associated_enrollment.try(:user_id) })
            unless enrollment
              enrollment = Enrollment.new
              enrollment.root_account = @root_account
            end
            enrollment.user = user
            enrollment.sis_source_id = [course_id, user_id, role, @section.name].compact.join(":")
            enrollment.type = type
            enrollment.associated_user_id = associated_enrollment.try(:user_id)

            enrollment.course = @course
            enrollment.course_section = @section

            if status =~ /\Aactive/i
              if user.workflow_state != 'deleted'
                enrollment.workflow_state = 'active'
              else
                enrollment.workflow_state = 'deleted'
                @messages << "Attempted enrolling of deleted user #{user_id} in course #{course_id}"
              end
            elsif status =~ /\Adeleted/i
              enrollment.workflow_state = 'deleted'
            elsif status =~ /\Acompleted/i
              enrollment.workflow_state = 'completed'
            elsif status =~ /\Ainactive/i
              enrollment.workflow_state = 'inactive'
            end

            if (enrollment.stuck_sis_fields & [:start_at, :end_at]).empty?
              enrollment.start_at = start_date
              enrollment.end_at = end_date
            end

            @courses_to_touch_ids.add(enrollment.course)
            if enrollment.should_update_user_account_association? && !%w{creation_pending deleted}.include?(user.workflow_state)
              if enrollment.new_record? && !@update_account_association_user_ids.include?(user.id)
                @incrementally_update_account_associations_user_ids.add(user.id)
              else
                @update_account_association_user_ids.add(user.id)
              end
            end
            if enrollment.changed?
              @users_to_touch_ids.add(user.id)
              enrollment.sis_batch_id = @batch_id if @batch_id
              enrollment.save_without_broadcasting
            elsif @batch_id
              @enrollments_to_update_sis_batch_ids << enrollment.id
            end

            @success_count += 1
          end
        end
      end

      def incrementally_update_account_associations
        if @incrementally_update_account_associations_user_ids.length < 10
          @update_account_association_user_ids.merge(@incrementally_update_account_associations_user_ids)
        else
          User.update_account_associations(@incrementally_update_account_associations_user_ids.to_a,
              :incremental => true,
              :precalculated_associations => User.calculate_account_associations_from_accounts(
                  [@course.account_id, @section.nonxlist_course.try(:account_id)].compact.uniq,
                          @account_chain_cache
                      ))
        end
        @incrementally_update_account_associations_user_ids = Set.new
      end

    end

  end
end
