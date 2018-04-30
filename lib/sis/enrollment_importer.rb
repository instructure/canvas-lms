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

require "set"

module SIS
  class EnrollmentImporter < BaseImporter

    def process(messages)
      start = Time.now
      i = Work.new(@batch, @root_account, @logger, messages)

      Enrollment.skip_touch_callbacks(:course) do
        Enrollment.suspend_callbacks(:set_update_cached_due_dates, :add_to_favorites_later,
            :recache_course_grade_distribution, :update_user_account_associations_if_necessary) do
          User.skip_updating_account_associations do
            Enrollment.process_as_sis(@sis_options) do
              yield i
              while i.any_left_to_process?
                i.process_batch
              end
            end
          end
        end
      end
      @logger.debug("Raw enrollments took #{Time.now - start} seconds")
      i.enrollments_to_update_sis_batch_ids.in_groups_of(1000, false) do |batch|
        Enrollment.where(:id => batch).update_all(:sis_batch_id => @batch.id)
      end if @batch
      # We batch these up at the end because we don't want to keep touching the same course over and over,
      # and to avoid hitting other callbacks for the course (especially broadcast_policy)
      i.courses_to_touch_ids.to_a.in_groups_of(1000, false) do |batch|
        courses = Course.where(id: batch)
        courses.touch_all
        courses.each(&:recache_grade_distribution)
      end
      i.courses_to_recache_due_dates.to_a.in_groups_of(1000, false) do |batch|
        batch.each do |course_id, user_ids|
          DueDateCacher.recompute_users_for_course(user_ids.uniq, course_id, nil, update_grades: true)
        end
      end
      # We batch these up at the end because normally a user would get several enrollments, and there's no reason
      # to update their account associations on each one.
      i.incrementally_update_account_associations
      User.update_account_associations(i.update_account_association_user_ids.to_a, :account_chain_cache => i.account_chain_cache)
      i.users_to_touch_ids.to_a.in_groups_of(1000, false) do |batch|
        User.where(id: batch).touch_all
        User.where(id: UserObserver.where(user_id: batch).select(:observer_id)).touch_all
      end
      i.enrollments_to_add_to_favorites.map(&:id).compact.each_slice(1000) do |sliced_ids|
        Enrollment.send_later_enqueue_args(:batch_add_to_favorites,
          {:priority => Delayed::LOW_PRIORITY, :strand => "batch_add_to_favorites_#{@root_account.global_id}"},
          sliced_ids)
      end

      @logger.debug("Enrollments with batch operations took #{Time.now - start} seconds")
      return i.success_count
    end

  private
    class Work
      attr_accessor :enrollments_to_update_sis_batch_ids, :courses_to_touch_ids,
          :incrementally_update_account_associations_user_ids, :update_account_association_user_ids,
          :account_chain_cache, :users_to_touch_ids, :success_count, :courses_to_recache_due_dates,
          :enrollments_to_add_to_favorites

      def initialize(batch, root_account, logger, messages)
        @batch = batch
        @root_account = root_account
        @logger = logger
        @messages = messages

        @update_account_association_user_ids = Set.new
        @incrementally_update_account_associations_user_ids = Set.new
        @users_to_touch_ids = Set.new
        @courses_to_touch_ids = Set.new
        @courses_to_recache_due_dates = {}
        @enrollments_to_add_to_favorites = []
        @enrollments_to_update_sis_batch_ids = []
        @account_chain_cache = {}
        @course = @section = nil
        @course_roles_by_account_id = {}

        @enrollment_batch = []
        @success_count = 0
      end

      # Pass a single instance of SIS::Models::Enrollment
      def add_enrollment(enrollment)
        raise ImportError, "No course_id or section_id given for an enrollment" unless enrollment.valid_context?
        raise ImportError, "No user_id given for an enrollment" unless enrollment.valid_user?
        raise ImportError, "Improper status \"#{enrollment.status}\" for an enrollment" unless enrollment.valid_status?
        return if @batch.skip_deletes? && enrollment.status =~ /deleted/i

        @enrollment_batch << enrollment
        process_batch if @enrollment_batch.size >= Setting.get("sis_enrollment_batch_size", "100").to_i # no idea if this is a good number
      end

      def any_left_to_process?
        return @enrollment_batch.size > 0
      end

      def process_batch
        return unless any_left_to_process?

        transaction_timeout = Setting.get('sis_transaction_seconds', '1').to_i.seconds
        Enrollment.transaction do
          tx_end_time = Time.now + transaction_timeout
          enrollment_info = nil
          while !@enrollment_batch.empty? && tx_end_time > Time.now
            enrollment_info = @enrollment_batch.shift
            @logger.debug("Processing Enrollment #{enrollment_info.to_a.inspect}")

            @last_section = @section if @section
            @last_course = @course if @course
            # reset the cached course/section if they don't match this row
            if @course && enrollment_info.course_id.present? && @course.sis_source_id != enrollment_info.course_id
              @course = nil
              @section = nil
            end
            if @section && enrollment_info.section_id.present? && @section.sis_source_id != enrollment_info.section_id
              @section = nil
            end

            if enrollment_info.root_account_id.present?
              root_account = root_account_from_id(enrollment_info.root_account_id)
              next unless root_account
            else
              root_account = @root_account
            end

            if !enrollment_info.user_integration_id.blank?
              pseudo = root_account.pseudonyms.where(integration_id: enrollment_info.user_integration_id).take
            else
              pseudo = root_account.pseudonyms.where(sis_user_id: enrollment_info.user_id).take
            end

            unless pseudo
              err = "User not found for enrollment "
              err << "(User ID: #{enrollment_info.user_id}, Course ID: #{enrollment_info.course_id}, Section ID: #{enrollment_info.section_id})"
              @messages << SisBatch.build_error(enrollment_info.csv, err, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              next
            end

            user = pseudo.user
            if root_account != @root_account
              unless SisPseudonym.for(user, @root_account, type: :implicit, require_sis: false)
                err = "User #{enrollment_info.root_account_id}:#{enrollment_info.user_id} does not have a usable login for this account"
                @messages << SisBatch.build_error(enrollment_info.csv, err, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
                next
              end
            end

            @course ||= @root_account.all_courses.where(sis_source_id: enrollment_info.course_id).take unless enrollment_info.course_id.blank?
            @section ||= @root_account.course_sections.where(sis_source_id: enrollment_info.section_id).take unless enrollment_info.section_id.blank?
            if @course.nil? && @section.nil?
              message = "Neither course nor section existed for user enrollment "
              message << "(Course ID: #{enrollment_info.course_id}, Section ID: #{enrollment_info.section_id}, User ID: #{enrollment_info.user_id})"
              @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)

              next
            end

            if enrollment_info.section_id.present? && !@section
              @course = nil
              message = "An enrollment referenced a non-existent section #{enrollment_info.section_id}"
              @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              next
            end
            if enrollment_info.course_id.present? && !@course
              @section = nil
              message = "An enrollment referenced a non-existent course #{enrollment_info.course_id}"
              @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              next
            end

            # reset cached/inferred course and section if they don't match with the opposite piece that was
            # explicitly provided
            @section = @course.default_section(:include_xlists => true) if @section.nil? || enrollment_info.section_id.blank? && !@section.default_section
            @course = @section.course if @course.nil? || (enrollment_info.course_id.blank? && @course.id != @section.course_id) || (@course.id != @section.course_id && @section.nonxlist_course_id == @course.id)

            if @course.id != @section.course_id
              message = "An enrollment listed a section (#{enrollment_info.section_id}) "
              message << "and a course (#{enrollment_info.course_id}) that are unrelated "
              message << "for user (#{enrollment_info.user_id})"
              @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              next
            end

            # preload the course object to avoid later queries for it
            @section.course = @course


            # cache available course roles for this account
            @course_roles_by_account_id[@course.account_id] ||= @course.account.available_course_roles

            # commit pending incremental account associations
            incrementally_update_account_associations if @section != @last_section and !@incrementally_update_account_associations_user_ids.empty?

            associated_user_id = nil

            role = nil
            role = @course_roles_by_account_id[@course.account_id].detect{|r| r.global_id == Shard.global_id_for(enrollment_info.role_id, @course.shard)} if enrollment_info.role_id
            role ||= @course_roles_by_account_id[@course.account_id].detect{|r| r.name == enrollment_info.role}

            type = if role
              role.base_role_type
            else
              if enrollment_info.role =~ /\Ateacher\z/i
                'TeacherEnrollment'
              elsif enrollment_info.role =~ /\Astudent/i
                'StudentEnrollment'
              elsif enrollment_info.role =~ /\Ata\z/i
                'TaEnrollment'
              elsif enrollment_info.role =~ /\Aobserver\z/i
                'ObserverEnrollment'
              elsif enrollment_info.role =~ /\Adesigner\z/i
                'DesignerEnrollment'
              end
            end
            unless type
              message = "Improper role \"#{enrollment_info.role}\" for an enrollment"
              @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              next
            end

            role ||= Role.get_built_in_role(type)

            if enrollment_info.associated_user_id && type == 'ObserverEnrollment'
              a_pseudo = root_account.pseudonyms.where(sis_user_id: enrollment_info.associated_user_id).take
              if a_pseudo
                associated_user_id = a_pseudo.user_id
              else
                message = "An enrollment referenced a non-existent associated user #{enrollment_info.associated_user_id}"
                @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
                next
              end
            end

            enrollment = @section.all_enrollments.where(user_id: user,
                                                        type: type,
                                                        associated_user_id: associated_user_id,
                                                        role_id: role.id).take

            unless enrollment
              enrollment = Enrollment.typed_enrollment(type).new
            end
            enrollment.root_account = @root_account
            enrollment.user = user
            enrollment.type = type
            enrollment.associated_user_id = associated_user_id
            enrollment.role = role
            enrollment.course = @course
            enrollment.course_section = @section
            if enrollment_info.limit_section_privileges
              enrollment.limit_privileges_to_course_section = Canvas::Plugin.value_to_boolean(enrollment_info.limit_section_privileges)
            end

            if enrollment_info.status =~ /\Aactive/i
              if user.workflow_state != 'deleted' && pseudo.workflow_state != 'deleted'
                enrollment.workflow_state = 'active'
              else
                enrollment.workflow_state = 'deleted'
                message = "Attempted enrolling of deleted user #{enrollment_info.user_id} in course #{enrollment_info.course_id}"
                @messages << SisBatch.build_error(enrollment_info.csv, message, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
              end
            elsif enrollment_info.status =~ /\Adeleted/i
              enrollment.workflow_state = 'deleted'
            elsif enrollment_info.status =~ /\Acompleted/i
              enrollment.workflow_state = 'completed'
              enrollment.completed_at ||= Time.now
            elsif enrollment_info.status =~ /\Ainactive/i
              enrollment.workflow_state = 'inactive'
            end

            if (enrollment.stuck_sis_fields & [:start_at, :end_at]).empty?
              enrollment.start_at = enrollment_info.start_date
              enrollment.end_at = enrollment_info.end_date
            end

            @courses_to_touch_ids.add(enrollment.course_id)
            if enrollment.should_update_user_account_association? && !%w{creation_pending deleted}.include?(user.workflow_state)
              if enrollment.new_record? && !@update_account_association_user_ids.include?(user.id)
                @incrementally_update_account_associations_user_ids.add(user.id)
              else
                @update_account_association_user_ids.add(user.id)
              end
            end
            enrollment.sis_pseudonym_id = pseudo.id
            if enrollment.changed?
              @users_to_touch_ids.add(user.id)
              if enrollment.workflow_state_changed?
                if enrollment_needs_due_date_recaching?(enrollment)
                  courses_to_recache_due_dates[enrollment.course_id] ||=[]
                  courses_to_recache_due_dates[enrollment.course_id] << enrollment.user_id
                end
                if enrollment.workflow_state == 'active'
                  enrollments_to_add_to_favorites << enrollment
                end
              end
              enrollment.sis_batch_id = enrollment_info.sis_batch_id if enrollment_info.sis_batch_id
              enrollment.sis_batch_id = @batch.id if @batch
              enrollment.skip_touch_user = true
              begin
                enrollment.save_without_broadcasting!
              rescue ActiveRecord::RecordInvalid
                msg = "An enrollment did not pass validation "
                msg += "(" + "course: #{enrollment_info.course_id}, section: #{enrollment_info.section_id}, "
                msg += "user: #{enrollment_info.user_id}, role: #{enrollment_info.role}, error: " +
                msg += enrollment.errors.full_messages.join(",") + ")"
                @messages << SisBatch.build_error(enrollment_info.csv, msg, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
                next
              rescue ActiveRecord::RecordNotUnique
                if @retry == true
                  msg = "An enrollment failed to save "
                  msg += "(course: #{enrollment_info.course_id}, section: #{enrollment_info.section_id}, "
                  msg += "user: #{enrollment_info.user_id}, role: #{enrollment_info.role}, error: " +
                    msg += enrollment.errors.full_messages.join(",") + ")"
                  @messages << SisBatch.build_error(enrollment_info.csv, msg, sis_batch: @batch, row: enrollment_info.lineno, row_info: enrollment_info)
                  @retry = false
                else
                  @enrollment_batch.unshift(enrollment_info)
                  @retry = true
                end
                next
              end
            elsif @batch
              @enrollments_to_update_sis_batch_ids << enrollment.id
            end

            @success_count += 1
          end
        end
      end

      def root_account_from_id(root_account_sis_id)
        nil
      end

      def incrementally_update_account_associations
        if @incrementally_update_account_associations_user_ids.length < 10
          @update_account_association_user_ids.merge(@incrementally_update_account_associations_user_ids)
        else
          User.update_account_associations(@incrementally_update_account_associations_user_ids.to_a,
              :incremental => true,
              :precalculated_associations => User.calculate_account_associations_from_accounts(
                  [@last_course.account_id, @last_section.nonxlist_course.try(:account_id)].compact.uniq,
                          @account_chain_cache
                      ))
        end
        @incrementally_update_account_associations_user_ids = Set.new
      end

      private

      def enrollment_needs_due_date_recaching?(enrollment)
        unless %w(active inactive).include? enrollment.workflow_state_before_last_save
          return %w(active inactive).include? enrollment.workflow_state
        end
        false
      end
    end

  end
end
