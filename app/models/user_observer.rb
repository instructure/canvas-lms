#
# Copyright (C) 2012 - 2015 Instructure, Inc.
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

class UserObserver < ActiveRecord::Base
  belongs_to :user, inverse_of: :user_observees
  belongs_to :observer, :class_name => 'User', inverse_of: :user_observers
  strong_params

  after_create :create_linked_enrollments

  validate :not_same_user, :if => lambda { |uo| uo.changed? }

  scope :active, -> { where.not(workflow_state: 'deleted') }

  def self.create_or_restore(attributes)
    UserObserver.unique_constraint_retry do
      if (user_observer = where(attributes).take)
        if user_observer.workflow_state == 'deleted'
          user_observer.workflow_state = 'active'
          user_observer.sis_batch_id = nil
          user_observer.save!
          user_observer.create_linked_enrollments
        end
      else
        user_observer = create!(attributes)
      end
      user_observer.user.touch
      user_observer
    end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save!
    remove_linked_enrollments
  end

  def not_same_user
    self.errors.add(:observer_id, "Cannot observe yourself") if self.user_id == self.observer_id
  end

  def create_linked_enrollments
    user.student_enrollments.active_or_pending.order("course_id").each do |enrollment|
      enrollment.create_linked_enrollment_for(observer)
    end
  end

  def remove_linked_enrollments
    observer.observer_enrollments.shard(observer).where(associated_user_id: user).find_each do |enrollment|
      enrollment.workflow_state = 'deleted'
      enrollment.save!
    end
    observer.update_account_associations
    observer.touch
  end
end
