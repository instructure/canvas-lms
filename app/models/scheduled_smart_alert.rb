# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class ScheduledSmartAlert < ApplicationRecord
  def self.queue_current_jobs
    ScheduledSmartAlert.distinct.pluck(:root_account_id).each do |root_account_id|
      account = Account.find(root_account_id)
      offset = account.settings["smart_alerts_threshold"] || 36

      ScheduledSmartAlert.runnable(offset, root_account_id).order(:due_at).find_each do |record|
        AssignmentUtil.delay.process_due_date_reminder(record.context_type, record.context_id) if account.feature_enabled?(:smart_alerts)
        record.destroy
      end
    end
  end

  def self.runnable(offset, root_account_id)
    where(["due_at < ? and root_account_id = ?", offset.hours.from_now, root_account_id])
  end

  def self.upsert(context_type:, context_id:, alert_type:, due_at:, root_account_id:)
    ScheduledSmartAlert.unique_constraint_retry do
      scheduled_job = ScheduledSmartAlert.where(context_type:,
                                                context_id:,
                                                alert_type:,
                                                root_account_id:).first_or_initialize

      scheduled_job.due_at = due_at
      scheduled_job.save!
    end
  end
end
