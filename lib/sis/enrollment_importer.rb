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
  class EnrollmentImporter < SisImporter

    def self.is_enrollment_csv?(row)
      row.header?('course_id') and row.header?('user_id')
    end

    def verify(csv, verify)
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        add_error(csv, "No course_id or section_id given for an enrollment") if row['course_id'].blank? && row['section_id'].blank?
        add_error(csv, "No user_id given for an enrollment") if row['user_id'].blank?
        add_error(csv, "Improper role \"#{row['role']}\" for an enrollment") unless row['role'] =~ /\Astudent|\Ateacher|\Ata|\Aobserver|\Adesigner/i
        add_error(csv, "Improper status \"#{row['status']}\" for an enrollment") unless row['status'] =~ /\Aactive|\Adeleted|\Acompleted|\Ainactive/i
      end
    end

    # expected columns
    # course_id,user_id,role,section_id,status
    def process(csv)
      start = Time.now
      update_account_association_user_ids = Set.new
      incrementally_update_account_associations_user_ids = Set.new
      users_to_touch_ids = Set.new
      courses_to_touch_ids = Set.new
      enrollments_to_update_sis_batch_ids = []
      account_chain_cache = {}
      course = section = nil

      Enrollment.skip_callback(:belongs_to_touch_after_save_or_destroy_for_course) do
        User.skip_updating_user_account_associations do
          FasterCSV.open(csv[:fullpath], "rb", :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |csv_object|
            row = csv_object.shift
            count = 0

            until row.nil?
              update_progress(count)
              count = 0
              # this transaction assumes that all these pseudonyms, courses, enrollments and
              # course_sections are all in the same database
              Enrollment.transaction do
                remaining_in_transaction = @sis.updates_every
                tx_end_time = Time.now + Setting.get('sis_transaction_seconds', '1').to_i.seconds

                begin
                  logger.debug("Processing Enrollment #{row.inspect}")
                  count += 1
                  remaining_in_transaction -= 1

                  last_section = section
                  # reset the cached course/section if they don't match this row
                  if course && row['course_id'].present? && course.sis_source_id != row['course_id']
                    course = nil
                    section = nil
                  end
                  if section && row['section_id'].present? && section.sis_source_id != row['section_id']
                    section = nil
                  end

                  pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, row['user_id'])
                  user = pseudo.user rescue nil
                  course ||= Course.find_by_root_account_id_and_sis_source_id(@root_account.id, row['course_id']) unless row['course_id'].blank?
                  section ||= CourseSection.find_by_root_account_id_and_sis_source_id(@root_account.id, row['section_id']) unless row['section_id'].blank?
                  unless user && (course || section)
                    add_warning csv, "Neither course #{row['course_id']} nor section #{row['section_id']} existed for user enrollment" unless (course || section)
                    add_warning csv, "User #{row['user_id']} didn't exist for user enrollment" unless user
                    next
                  end

                  if row['section_id'] && !section
                    add_warning csv, "An enrollment referenced a non-existent section #{row['section_id']}"
                    next
                  end

                  if row['course_id'] && !course
                    add_warning csv, "An enrollment referenced a non-existent course #{row['course_id']}"
                    next
                  end

                  # reset cached/inferred course and section if they don't match with the opposite piece that was
                  # explicitly provided
                  section = course.default_section if section.nil? || row['section_id'].blank? && !section.default_section
                  course = section.course if course.nil? || (row['course_id'].blank? && course.id != section.course_id) ||
                    (course.id != section.course_id && section.nonxlist_course_id == course.id)

                  if course.id != section.course_id
                    add_warning csv, "An enrollment listed a section and a course that are unrelated"
                    next
                  end
                  # preload the course object to avoid later queries for it
                  section.course = course

                  # commit pending incremental account associations
                  if section != last_section and !incrementally_update_account_associations_user_ids.empty?
                    if incrementally_update_account_associations_user_ids.length < 10
                      update_account_association_user_ids.merge(incrementally_update_account_associations_user_ids)
                    else
                      User.update_account_associations(incrementally_update_account_associations_user_ids.to_a,
                          :incremental => true,
                          :precalculated_associations => User.calculate_account_associations_from_accounts(
                              [course.account_id, section.nonxlist_course.try(:account_id)].compact.uniq,
                              account_chain_cache
                          ))
                    end
                    incrementally_update_account_associations_user_ids = Set.new
                  end

                  enrollment = section.enrollments.find_by_user_id(user.id)
                  unless enrollment
                    enrollment = Enrollment.new
                    enrollment.root_account = @root_account
                  end
                  enrollment.user = user
                  enrollment.sis_source_id = [row['course_id'], row['user_id'], row['role'], section.name].compact.join(":")

                  enrollment.course = course
                  enrollment.course_section = section
                  if row['role'] =~ /\Ateacher\z/i
                    enrollment.type = 'TeacherEnrollment'
                  elsif row['role'] =~ /student/i
                    enrollment.type = 'StudentEnrollment'
                  elsif row['role'] =~ /\Ata\z|assistant/i
                    enrollment.type = 'TaEnrollment'
                  elsif row['role'] =~ /\Aobserver\z/i
                    enrollment.type = 'ObserverEnrollment'
                    if row['associated_user_id']
                      pseudo = Pseudonym.find_by_account_id_and_sis_user_id(@root_account.id, row['associated_user_id'])
                      associated_enrollment = pseudo && course.student_enrollments.find_by_user_id(pseudo.user_id)
                      enrollment.associated_user_id = associated_enrollment && associated_enrollment.user_id
                    end
                  elsif row['role'] =~ /\Adesigner\z/i
                    enrollment.type = 'DesignerEnrollment'
                  end

                  # "active" really means "active if otherwise available"
                  if row['status']=~ /\Aactive/i
                    row['status'] = course.enrollment_state_based_on_date(enrollment)
                  end

                  if row['status']=~ /\Aactive/i
                    if user.workflow_state != 'deleted'
                      enrollment.workflow_state = 'active'
                    else
                      enrollment.workflow_state = 'deleted'
                      add_warning csv, "Attempted enrolling of deleted user #{row['user_id']} in course #{row['course_id']}"
                    end
                  elsif  row['status']=~ /\Adeleted/i
                    enrollment.workflow_state = 'deleted'
                  elsif  row['status']=~ /\Acompleted/i
                    enrollment.workflow_state = 'completed'
                  elsif  row['status']=~ /\Ainactive/i
                    enrollment.workflow_state = 'inactive'
                  end

                  courses_to_touch_ids.add(enrollment.course)
                  if enrollment.should_update_user_account_association?
                    if enrollment.new_record? && !update_account_association_user_ids.include?(user.id)
                      incrementally_update_account_associations_user_ids.add(user.id)
                    else
                      update_account_association_user_ids.add(user.id)
                    end
                  end
                  if enrollment.changed?
                    users_to_touch_ids.add(user.id)
                    enrollment.sis_batch_id = @batch.id if @batch
                    enrollment.save_without_broadcasting
                  elsif @batch
                    enrollments_to_update_sis_batch_ids << enrollment.id
                  end

                  @sis.counts[:enrollments] += 1
                end while !(row = csv_object.shift).nil? && remaining_in_transaction > 0 && tx_end_time > Time.now
              end
            end
          end
        end
      end
      logger.debug("Raw enrollments took #{Time.now - start} seconds")
      Enrollment.update_all({:sis_batch_id => @batch.id}, {:id => enrollments_to_update_sis_batch_ids}) if @batch && !enrollments_to_update_sis_batch_ids.empty?
      # We batch these up at the end because we don't want to keep touching the same course over and over,
      # and to avoid hitting other callbacks for the course (especially broadcast_policy)
      Course.update_all({:updated_at => Time.now}, {:id => courses_to_touch_ids.to_a}) unless courses_to_touch_ids.empty?
      # We batch these up at the end because normally a user would get several enrollments, and there's no reason
      # to update their account associations on each one.
      if incrementally_update_account_associations_user_ids.length < 10
        update_account_association_user_ids.merge(incrementally_update_account_associations_user_ids)
      else
        User.update_account_associations(incrementally_update_account_associations_user_ids.to_a,
            :incremental,
            :precalculated_associations => User.calculate_account_associations_from_accounts(
                [course.account_id, section.nonxlist_course.try(:account_id)].compact.uniq,
                account_chain_cache
            ))
      end
      User.update_account_associations(update_account_association_user_ids.to_a,
                                       :account_chain_cache => account_chain_cache)
      User.update_all({:updated_at => Time.now}, {:id => users_to_touch_ids.to_a}) unless users_to_touch_ids.empty?

      logger.debug("Enrollments with batch operations took #{Time.now - start} seconds")
    end
  end
end
