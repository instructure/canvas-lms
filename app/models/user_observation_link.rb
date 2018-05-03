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

# if the observer and observee are on different shards, the "primary" record belongs
# on the same shard as the observee, but a duplicate record is also created on the
# other shard

class UserObservationLink < ActiveRecord::Base
  self.table_name = "user_observers"

  belongs_to :student, :class_name => 'User', inverse_of: :as_student_observation_links, :foreign_key => :user_id
  belongs_to :observer, :class_name => 'User', inverse_of: :as_observer_observation_links
  belongs_to :root_account, :class_name => 'Account'

  has_many :observer_alert_thresholds, :inverse_of => :user_observation_link
  has_many :observer_alerts, :inverse_of => :user_observation_link

  after_create :create_linked_enrollments

  validate :not_same_user, :if => lambda { |uo| uo.changed? }

  scope :active, -> { where.not(workflow_state: 'deleted') }

  scope :for_root_accounts, lambda {|root_accounts|
    root_accounts = Array(root_accounts)
    root_accounts << nil # TODO: remove after root_account_id is populated and is not-nulled
    where(:root_account_id => root_accounts)
  }

  attr_accessor :skip_destroy_other_record

  MISSING_ROOT_ACCOUNT_ID = -1

  # shadow_record param is private
  def self.create_or_restore(student: , observer: , root_account: , shadow_record: false)
    raise ArgumentError, 'student, observer and root_account are required' unless student && observer && root_account
    shard = shadow_record ? observer.shard : student.shard
    result = shard.activate do
      self.unique_constraint_retry do
        if (uo = self.where(student: student, observer: observer).for_root_accounts(root_account).take)
          if uo.workflow_state == 'deleted'
            uo.workflow_state = 'active'
            uo.sis_batch_id = nil
            uo.save!
          end
        else
          uo = create!(student: student, observer: observer, root_account: root_account)
        end
        uo
      end
    end

    if result.primary_record?
      # create the shadow record
      create_or_restore(student: student, observer: observer, root_account: root_account, shadow_record: true) if result.cross_shard?

      result.create_linked_enrollments
      result.student.touch
    end

    result
  end

  def user
    student
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    if !self.skip_destroy_other_record && (other = other_record)
      other.skip_destroy_other_record = false
      other.destroy
    end
    self.workflow_state = 'deleted'
    self.save!
    remove_linked_enrollments if primary_record?
  end

  def not_same_user
    self.errors.add(:observer_id, "Cannot observe yourself") if self.user_id == self.observer_id
  end

  def create_linked_enrollments
    self.class.connection.after_transaction_commit do
      User.skip_updating_account_associations do
        scope = student.student_enrollments.all_active_or_pending.order("course_id")
        if self.root_account
          scope = scope.shard(self.root_account).where(:root_account_id => self.root_account)
        else
          scope = scope.shard(student) # TODO: can remove when all root accounts are populated
        end

        scope.each do |enrollment|
          next unless enrollment.valid?
          enrollment.create_linked_enrollment_for(observer)
        end

        observer.update_account_associations
      end
    end
  end

  def remove_linked_enrollments
    scope = observer.observer_enrollments.where(associated_user_id: student)
    if self.root_account
      scope = scope.shard(self.root_account).where(:root_account_id => self.root_account)
    else
      scope = scope.shard(observer) # TODO: can remove when all root accounts are populated
    end

    scope.find_each do |enrollment|
      enrollment.workflow_state = 'deleted'
      enrollment.save!
    end
    observer.update_account_associations
    observer.touch
  end

  def cross_shard?
    Shard.shard_for(user_id) != Shard.shard_for(observer_id)
  end

  def primary_record?
    shard == Shard.shard_for(user_id)
  end

  private

  def other_record
    if cross_shard?
      primary_record? ? shadow_record : primary_record
    end
  end

  def primary_record
    if cross_shard? && !primary_record?
      Shard.shard_for(user_id).activate do
        self.class.where(user_id: user_id, observer_id: observer_id).take!
      end
    else
      self
    end
  end

  def shadow_record
    if !cross_shard? || !primary_record?
      self
    else
      Shard.shard_for(observer_id).activate do
        self.class.where(user_id: user_id, observer_id: observer_id).take!
      end
    end
  end
end

require_dependency 'user_observer'
