#
# Copyright (C) 2018 - present Instructure, Inc.
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
class SisBatchRollBackData < ActiveRecord::Base
  belongs_to :sis_batch, inverse_of: :roll_back_data
  belongs_to :context, polymorphic: %i{abstract_course account account_user
                                       communication_channel course
                                       course_section enrollment enrollment_term
                                       group group_category group_membership
                                       pseudonym user_observer}

  scope :expired_data, -> {where('created_at < ?', 30.days.ago)}
  scope :active, -> {where(workflow_state: 'active')}
  scope :restored, -> {where(workflow_state: 'restored')}

  RESTORE_ORDER = %w{Account EnrollmentTerm AbstractCourse Course CourseSection
                     GroupCategory Group Pseudonym CommunicationChannel
                     Enrollment GroupMembership UserObserver AccountUser}

  def self.cleanup_expired_data
    return unless expired_data.exists?
    until expired_data.limit(10_000).delete_all < 10_000
    end
  end

  def self.build_data(sis_batch:, context:, batch_mode_delete: false)
    return unless SisBatchRollBackData.should_create_roll_back?(context, sis_batch)
    old_state = (context.id_before_last_save.nil? ? 'non-existent' : context.workflow_state_before_last_save)
    sis_batch.roll_back_data.build(context: context,
                                   previous_workflow_state: old_state,
                                   updated_workflow_state: context.workflow_state,
                                   created_at: Time.zone.now,
                                   updated_at: Time.zone.now,
                                   batch_mode_delete: batch_mode_delete,
                                   workflow_state: 'active')
  end

  def self.build_dependent_data(sis_batch:, contexts:, updated_state:, batch_mode_delete: false)
    return unless sis_batch
    data = []
    contexts.each do |context|
      data << sis_batch.roll_back_data.build(context: context,
                                             previous_workflow_state: context.workflow_state,
                                             updated_workflow_state: updated_state,
                                             created_at: Time.zone.now,
                                             updated_at: Time.zone.now,
                                             batch_mode_delete: batch_mode_delete,
                                             workflow_state: 'active')
    end
    data
  end

  def self.should_create_roll_back?(object, sis_batch)
    return false unless sis_batch
    object.id_before_last_save.nil? || object.workflow_state_before_last_save != object.workflow_state
  end

  def self.bulk_insert_roll_back_data(datum)
    datum.each_slice(1000) do |batch|
      data_hash = batch.map {|data| data.attributes.except('id')}
      SisBatchRollBackData.bulk_insert(data_hash)
    end
  end

  def restore_to_state
    case context_type
    when 'CommunicationChannel'
      (previous_workflow_state == 'non-existent') ? 'retired' : previous_workflow_state
    when 'GroupCategory'
      (previous_workflow_state == 'active') ? nil : Time.zone.now
    else
      (previous_workflow_state == 'non-existent') ? 'deleted' : previous_workflow_state
    end
  end

  def to_restore_array
    [context_id, restore_to_state]
  end

end
