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
  class CourseImporter < BaseImporter
    def process(messages)
      courses_to_update_sis_batch_id = []
      course_ids_to_update_associations = [].to_set
      blueprint_associations = {}

      importer = Work.new(@batch, @root_account, @logger, courses_to_update_sis_batch_id, course_ids_to_update_associations, messages, @batch_user, blueprint_associations)
      Course.suspend_callbacks(:update_enrollments_later, :update_enrollment_states_if_necessary) do
        Course.process_as_sis(@sis_options) do
          Course.skip_updating_account_associations do
            yield importer
          end
        end
      end

      Course.update_account_associations(course_ids_to_update_associations.to_a) unless course_ids_to_update_associations.empty?
      courses_to_update_sis_batch_id.in_groups_of(1000, false) do |courses|
        Course.where(id: courses).update_all(sis_batch_id: @batch.id)
      end

      SisBatchRollBackData.bulk_insert_roll_back_data(importer.roll_back_data)
      MasterCourses::MasterTemplate.create_associations_from_sis(@root_account, blueprint_associations, messages, @batch_user)

      importer.success_count
    end

    class Work
      attr_accessor :success_count, :roll_back_data

      def initialize(batch, root_account, logger, a1, a2, m, batch_user, blueprint_associations)
        @batch = batch
        @batch_user = batch_user
        @root_account = root_account
        @courses_to_update_sis_batch_id = a1
        @course_ids_to_update_associations = a2
        @roll_back_data = []
        @blueprint_associations = blueprint_associations
        @messages = m
        @logger = logger
        @success_count = 0
      end

      def add_course(course_id, term_id, account_id, fallback_account_id, status, start_date, end_date, abstract_course_id, short_name, long_name, integration_id, course_format, blueprint_course_id, grade_passback_setting, homeroom_course, friendly_name)
        state_changes = []
        raise ImportError, "No course_id given for a course" if course_id.blank?
        raise ImportError, "No short_name given for course #{course_id}" if short_name.blank? && abstract_course_id.blank?
        raise ImportError, "No long_name given for course #{course_id}" if long_name.blank? && abstract_course_id.blank?
        raise ImportError, "Improper status \"#{status}\" for course #{course_id}" unless /\A(active|deleted|completed|unpublished|published)/i.match?(status)
        raise ImportError, "Invalid course_format \"#{course_format}\" for course #{course_id}" unless course_format.blank? || course_format =~ /\A(online|on_campus|blended|not_set)/i

        valid_grade_passback_settings = %w[nightly_sync disabled not_set]
        raise ImportError, "Invalid grade_passback_setting \"#{grade_passback_setting}\" for course #{course_id}" unless grade_passback_setting.blank? || valid_grade_passback_settings.include?(grade_passback_setting.downcase.strip)
        return if @batch.skip_deletes? && status =~ /deleted/i

        Course.unique_constraint_retry do
          course = @root_account.all_courses.where(sis_source_id: course_id).take
          if course.nil?
            course = Course.new
            state_changes << :created
          else
            state_changes << :updated
          end
          course.saved_by = :sis_import
          course_enrollment_term_id_stuck = course.stuck_sis_fields.include?(:enrollment_term_id)
          if !course_enrollment_term_id_stuck && term_id
            term = @root_account.enrollment_terms.active.where(sis_source_id: term_id).take
          end
          course.enrollment_term = term if term
          course.root_account = @root_account

          account = nil
          account = @root_account.all_accounts.where(sis_source_id: account_id).take if account_id.present?
          account ||= @root_account.all_accounts.where(sis_source_id: fallback_account_id).take if fallback_account_id.present?
          if account_id.present? && !account
            raise ImportError, "Account not found \"#{account_id}\" for course #{course_id}"
          end

          course_account_stuck = course.stuck_sis_fields.include?(:account_id)
          if !course_account_stuck && account&.active?
            course.account = account
          end

          if course.account&.deleted?
            raise ImportError, "Cannot restore course #{course_id} because the associated account #{course.account.sis_source_id} is deleted"
          end

          course.account ||= @root_account

          update_account_associations = course.account_id_changed? || course.root_account_id_changed?

          if account&.enable_as_k5_account? && friendly_name.present?
            course.friendly_name = friendly_name
          end

          course.integration_id = integration_id
          course.sis_source_id = course_id
          active_state = status.casecmp?("published") ? "available" : "claimed"
          unless course.stuck_sis_fields.include?(:workflow_state)
            if %w[active unpublished published].include?(status.downcase)
              case course.workflow_state
              when "completed"
                # not using active state here, because it has always been set to available
                # and customers have used this as a workaround to publishing courses. conclude, then restore.
                course.workflow_state = "available"
                state_changes << :unconcluded
              when "deleted"
                course.workflow_state = active_state
                state_changes << :restored
              when "created", "claimed", nil
                course.workflow_state = active_state
                state_changes << :published if active_state == "available"
              end
            elsif /deleted/i.match?(status)
              course.workflow_state = "deleted"
              state_changes << :deleted
            elsif /completed/i.match?(status)
              course.workflow_state = "completed"
              state_changes << :concluded
            end
          end

          course_dates_stuck = !!course.stuck_sis_fields.intersect?([:start_at, :conclude_at])
          unless course_dates_stuck
            if start_date == "<delete>" && end_date == "<delete>"
              course.restrict_enrollments_to_course_dates = false
            end
            course.start_at = start_date unless start_date == "not_present"
            course.start_at = nil if start_date == "<delete>"
            course.conclude_at = end_date unless end_date == "not_present"
            course.conclude_at = nil if end_date == "<delete>"
            if !course.stuck_sis_fields.include?(:restrict_enrollments_to_course_dates) && !(start_date == "not_present" && end_date == "not_present")
              course.restrict_enrollments_to_course_dates = (start_date.present? || end_date.present?)
            end
          end

          abstract_course = nil
          if abstract_course_id.present?
            abstract_course = @root_account.root_abstract_courses.where(sis_source_id: abstract_course_id).take
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

          update_enrollments = !course.new_record? && !!course.changes.keys.intersect?(%w[workflow_state name course_code])

          # republish course paces if necessary
          if !course.new_record? && course.account.feature_enabled?(:course_paces) && course.changes.keys.intersect?(%w[start_at conclude_at restrict_enrollments_to_course_dates])
            course.course_paces.find_each(&:create_publish_progress)
          end

          if course_format
            course_format = nil if course_format == "not_set"
            if course_format != course.course_format
              course.settings_will_change!
              course.course_format = course_format
            end
          end

          if grade_passback_setting
            grade_passback_setting_stuck = course.stuck_sis_fields.include?(:grade_passback_setting)
            unless grade_passback_setting_stuck
              grade_passback_setting = nil if grade_passback_setting == "not_set"
              course.grade_passback_setting = grade_passback_setting
            end
          end

          if homeroom_course
            course.homeroom_course = Canvas::Plugin.value_to_boolean(homeroom_course)
          end

          if course.changed?
            course.templated_courses.each do |templated_course|
              templated_course.root_account = @root_account
              templated_course.account = course.account if !templated_course.stuck_sis_fields.include?(:account_id) && !course_account_stuck
              templated_course.name = course.name if !templated_course.stuck_sis_fields.include?(:name) && !course_name_stuck
              templated_course.course_code = course.course_code if !templated_course.stuck_sis_fields.include?(:course_code) && !course_course_code_stuck
              templated_course.enrollment_term = course.enrollment_term if !templated_course.stuck_sis_fields.include?(:enrollment_term_id) && !course_enrollment_term_id_stuck
              if !templated_course.stuck_sis_fields.intersect?(%i[start_at conclude_at restrict_enrollments_to_course_dates]) && !course_dates_stuck
                templated_course.start_at = course.start_at
                templated_course.conclude_at = course.conclude_at
                templated_course.restrict_enrollments_to_course_dates = course.restrict_enrollments_to_course_dates
              end
              templated_course.sis_batch_id = @batch.id
              @course_ids_to_update_associations.add(templated_course.id) if templated_course.account_id_changed? || templated_course.root_account_id_changed?
              if templated_course.valid?
                changes = templated_course.changes
                templated_course.save_without_broadcasting!
                Auditors::Course.record_updated(templated_course, @batch_user, changes, source: :sis, sis_batch_id: @batch_id)
              else
                msg = "A (templated) course did not pass validation " \
                      "(course: #{course_id} / #{short_name}, error: " \
                      "#{templated_course.errors.full_messages.join(",")})"
                raise ImportError, msg
              end
            end
            course.sis_batch_id = @batch.id
            if course.valid?
              course_changes = course.changes
              course.save_without_broadcasting!
              auditor_state_changes(course, state_changes, course_changes)
              data = SisBatchRollBackData.build_data(sis_batch: @batch, context: course)
              @roll_back_data << data if data
            else
              msg = "A course did not pass validation " \
                    "(course: #{course_id} / #{short_name}, error: " \
                    "#{course.errors.full_messages.join(",")})"
              raise ImportError, msg
            end
            @course_ids_to_update_associations.add(course.id) if update_account_associations
          else
            @courses_to_update_sis_batch_id << course.id
          end

          if blueprint_course_id && !course.deleted?
            case blueprint_course_id
            when "dissociate"
              MasterCourses::ChildSubscription.active.where(child_course_id: course.id).take&.destroy
            else
              @blueprint_associations[blueprint_course_id] ||= []
              @blueprint_associations[blueprint_course_id] << course_id
            end
          end

          enrollment_data = course.update_enrolled_users(sis_batch: @batch) if update_enrollments
          course.update_enrollment_states_if_necessary
          @roll_back_data.push(*enrollment_data) if enrollment_data
          maybe_write_roll_back_data

          @success_count += 1
        end
      end

      def maybe_write_roll_back_data
        if @roll_back_data.count > 1000
          SisBatchRollBackData.bulk_insert_roll_back_data(@roll_back_data)
          @roll_back_data = []
        end
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
