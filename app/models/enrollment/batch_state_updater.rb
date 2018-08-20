#
# Copyright (C) 2016 - present Instructure, Inc.
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

class Enrollment::BatchStateUpdater
  # destroy_batch needs to account for all the callbacks in Enrollment
  #
  # destroy - handled in mark_enrollments_as_deleted
  # before_save :assign_uuid - not needed for state updates
  # before_validation :assert_section - not needed for state updates
  # after_save :recalculate_enrollment_state - handled in destroy_all
  # after_save :update_user_account_associations_if_necessary - not needed for destroy
  # before_save :audit_groups_for_deleted_enrollments - handled in remove_group_memberships
  # before_validation :ensure_role_id - not needed for state updates
  # after_save :copy_scores_from_existing_enrollment, if: :need_to_copy_scores? - not needed for destroy
  # after_save :restore_submissions_and_scores - not needed for destroy
  # after_save :clear_email_caches - handled in clear_email_caches
  # after_save :cancel_future_appointments - handled in cancel_future_appointments
  # after_save :update_linked_enrollments - handled in update_linked_enrollments
  # after_save :set_update_cached_due_dates - handled in update_cached_due_dates
  # after_save :touch_graders_if_needed - handled in touch_all_graders_if_needed
  # after_save :reset_notifications_cache - handled in reset_notifications_cache
  # after_save :dispatch_invitations_later - not needed for destroy
  # after_save :add_to_favorites_later - not needed for destroy
  # after_commit :update_cached_due_dates - handled in update_cached_due_dates
  # after_save :update_assignment_overrides_if_needed - handled in update_assignment_overrides
  # after_save :needs_grading_count_updated -handled in needs_grading_count_updated
  def self.destroy_batch(batch, sis_batch: nil, batch_mode: false)
    raise ArgumentError, 'Cannot call with more than 1000 enrollments' if batch.count > 1000
    Enrollment.transaction do
      # cache some data before the destroy that is needed after the destroy
      invited_user_ids = Enrollment.where(id: batch, workflow_state: 'invited').distinct.pluck(:user_id)
      students = Enrollment.of_student_type.where(id: batch).preload(user: :linked_observers).to_a
      students.each{|e| e.workflow_state = 'deleted'; e.readonly!}
      user_course_tuples = Enrollment.where(id: batch).active.select(%i(user_id course_id)).distinct.to_a
      user_ids = Enrollment.where(id: batch).distinct.pluck(:user_id)
      courses = Course.where(id: Enrollment.where(id: batch).select(:course_id).distinct).to_a
      root_account = courses.first.root_account
      data = mark_enrollments_as_deleted(batch, sis_batch: sis_batch, batch_mode: batch_mode)
      gms = remove_group_memberships(batch, courses, user_ids, sis_batch: sis_batch, batch_mode: batch_mode)
      data&.push(*gms) if gms
      # touch users after removing group_memberships to invalidate the cache.
      touch_and_update_associations(user_ids)
      clear_email_caches(invited_user_ids) unless invited_user_ids.empty?
      cancel_future_appointments(courses, user_ids)
      disassociate_cross_shard_users(user_ids)
      update_linked_enrollments(students)
      touch_all_graders_if_needed(students)
      reset_notifications_cache(user_course_tuples)
      update_assignment_overrides(batch, courses, user_ids)
      needs_grading_count_updated(courses)
      recache_all_course_grade_distribution(courses)
      update_cached_due_dates(students, root_account)
      return data if sis_batch
      batch.count
    end
  end

  # bulk version of Enrollment.destroy
  def self.mark_enrollments_as_deleted(batch, sis_batch: nil, batch_mode: false)
    data = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch, contexts: batch, updated_state: 'deleted', batch_mode_delete: batch_mode)
    updates = {workflow_state: 'deleted', updated_at: Time.now.utc}
    updates[sis_batch_id: sis_batch.id] if sis_batch
    Enrollment.where(id: batch).update_all(updates)
    EnrollmentState.where(enrollment_id: batch).update_all(state: 'deleted', state_valid_until: nil)
    Score.where(enrollment_id: batch).update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
    data
  end

  def self.touch_and_update_associations(user_ids)
    User.where(id: user_ids).touch_all
    User.update_account_associations(user_ids)
  end

  def self.remove_group_memberships(batch, courses, user_ids, sis_batch: nil, batch_mode: false)
    data = []
    courses.each do |c|
      gms = GroupMembership.active.joins(:group).
        where(groups: {context_type: 'Course', context_id: c},
              user_id: user_ids).where.not(user_id: c.enrollments.where.not(id: batch).pluck(:user_id))
      next unless gms.exists?
      rollback = SisBatchRollBackData.build_dependent_data(sis_batch: sis_batch, contexts: gms, updated_state: 'deleted', batch_mode_delete: batch_mode)
      data.push(*rollback)
      GroupMembership.where(id: gms).update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
      leader_change_groups = Group.joins(:group_memberships).where(group_memberships: {id: gms}, leader_id: user_ids)
      leader_change_groups.update_all(leader_id: nil, updated_at: Time.zone.now)
      leader_change_groups.each(&:auto_reassign_leader)
      Group.joins(:group_memberships).where(group_memberships: {id: gms}).touch_all
    end
    data
  end

  def self.clear_email_caches(invited_user_ids)
    Shard.partition_by_shard(invited_user_ids) do |shard_invited_users|
      emails = CommunicationChannel.email.unretired.where(user_id: shard_invited_users).distinct.pluck(:path)
      if Enrollment.cross_shard_invitations?
        Shard.birth.activate do
          emails.each {|path| Rails.cache.delete([path, 'all_invited_enrollments2'].cache_key)}
        end
      else
        emails.each {|path| Rails.cache.delete([path, 'invited_enrollments2'].cache_key)}
      end
    end
  end

  def self.cancel_future_appointments(courses, user_ids)
    courses.each do |c|
      user_ids -= c.all_enrollments.active.where(user_id: user_ids).pluck(:user_id)
      next if user_ids.empty?
      c.appointment_participants.active.current.
        where(context_id: user_ids, context_type: 'User').
        update_all(workflow_state: 'deleted', updated_at: Time.zone.now)
    end
  end

  def self.disassociate_cross_shard_users(user_ids); end

  def self.update_linked_enrollments(students)
    students.each(&:update_linked_enrollments)
  end

  def self.touch_all_graders_if_needed(students)
    courses_to_touch_admins = students.map(&:course_id).uniq
    Enrollment.connection.after_transaction_commit do
      User.where(id: Enrollment.where(course_id: courses_to_touch_admins,
                                      type: ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment']).
        active.select(:user_id)).touch_all
    end
  end

  def self.reset_notifications_cache(user_course_tuples)
    user_course_tuples.each do |enrollment|
      StreamItemCache.invalidate_recent_stream_items(enrollment.user_id, "Course", enrollment.course_id)
    end
  end

  def self.update_assignment_overrides(batch, courses, user_ids)
    courses.each do |c|
      assignment_ids = Assignment.where(context_id: c, context_type: 'Course').pluck(:id)
      next unless assignment_ids
      # this is handled in :update_cached_due_dates
      AssignmentOverrideStudent.suspend_callbacks(:update_cached_due_dates) do
        AssignmentOverrideStudent.
          where(user_id: user_ids, assignment_id: assignment_ids).
          where.not(user_id: c.enrollments.where(user_id: user_ids).
          where.not(id: batch).select(:user_id)).each(&:destroy)
      end
    end
  end

  def self.needs_grading_count_updated(courses)
    Assignment.where(context_id: courses).find_ids_in_batches(batch_size: 10_000) do |assignment_ids|
      Assignment.where(id: assignment_ids).touch_all
    end
  end

  def self.recache_all_course_grade_distribution(courses)
    courses.each do |c|
      c.recache_grade_distribution if c.respond_to?(:recache_grade_distribution)
    end
  end

  def self.update_cached_due_dates(students, root_account)
    students.group_by(&:course_id).each do |course, studs|
      DueDateCacher.recompute_users_for_course(studs.map(&:user_id), course, nil,
                                               singleton: ('EnrollmentBatchStateUpdater_' +
                                                 root_account.global_id.to_s))
    end
  end

  # this is to be used for enrollments that just changed workflow_states but are
  # not deleted. This also skips notifying users.
  def self.run_call_backs_for(batch)
    raise ArgumentError, 'Cannot call with more than 1000 enrollments' if batch.count > 1_000
    Enrollment.transaction do
      EnrollmentState.send_later_if_production(:force_recalculation, batch)
      students = Enrollment.of_student_type.where(id: batch).preload(user: :linked_observers).to_a
      user_ids = Enrollment.where(id: batch).distinct.pluck(:user_id)
      courses = Course.where(id: Enrollment.where(id: batch).select(:course_id).distinct).to_a
      root_account = courses.first.root_account
      touch_and_update_associations(user_ids)
      update_linked_enrollments(students)
      needs_grading_count_updated(courses)
      recache_all_course_grade_distribution(courses)
      update_cached_due_dates(students, root_account)
      touch_all_graders_if_needed(students)
    end
  end
end
