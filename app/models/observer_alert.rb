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

class ObserverAlert < ActiveRecord::Base
  belongs_to :user_observation_link, :inverse_of => :observer_alerts
  belongs_to :observer_alert_threshold, :inverse_of => :observer_alerts
  belongs_to :context, polymorphic: [:discussion_topic, :assignment, :course, :account_notification]

  ALERT_TYPES = %w(
    assignment_missing
    assignment_grade_high
    assignment_grade_low
    course_grade_high
    course_grade_low
    course_announcement
    institution_announcement
  ).freeze
  validates :alert_type, inclusion: { in: ALERT_TYPES }
  validates :user_observation_link_id, :observer_alert_threshold_id, :alert_type, :action_date, :title, presence: true

  scope :active, -> { where.not(workflow_state: ['dismissed', 'deleted']) }
  scope :unread, -> { where(workflow_state: 'unread')}

  def self.clean_up_old_alerts
    ObserverAlert.where('created_at < ?', 6.months.ago).delete_all
  end
end