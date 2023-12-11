# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

#
# MicrosoftSync contains models used to sync course enrollments to Microsoft
# Teams via Microsoft's APIs. For customers using their new (in development as
# of 2021) Teams tool, Microsoft needs up-to-date Canvas course enrollment
# details.
#
# This model is the main model, and is created when a teacher turns on (in
# course settings) the option to sync enrollments to Microsoft Teams. It is
# then used to keep track of the syncing.
#
# See usages in StateMachineJob (workflow_state, job_state, last_error) and
# SyncerSteps (ms_group_id)
#
# Notable fields:
# * ms_group_id -- Microsoft's ID used in the their Graph API for the group
#
class MicrosoftSync::Group < ActiveRecord::Base
  extend RootAccountResolver
  include Workflow

  # States at which a manual sync is allowed
  COOLDOWN_NOT_REQUIRED_STATES = %i[
    pending
    errored
  ].freeze

  RUNNING_STATES = %i[
    running
    retrying
  ].freeze

  belongs_to :course
  belongs_to :last_error_report, class_name: "ErrorReport"
  validates :course, presence: true
  validates :course_id, uniqueness: true

  scope :not_deleted, -> { where.not(workflow_state: "deleted") }

  workflow do
    state :pending # Initial state, before first sync
    state :manually_scheduled
    state :scheduled
    state :running
    state :retrying
    state :errored
    state :completed
    state :deleted
  end

  serialize :job_state
  serialize :debug_info

  resolves_root_account through: :course

  def self.manual_sync_cooldown
    Setting.get("msft_sync.manual_sync_cooldown", 90.minutes.to_s).to_i
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    return true if deleted?

    self.workflow_state = "deleted"
    run_callbacks(:destroy) { save! }
  end

  def restore!
    return unless deleted?

    update!(
      workflow_state: "pending",
      job_state: { restored: true },
      last_error: nil
    )
  end

  # This should be used for most updates to the workflow_state, in case the
  # group is deleted (e.g. by disabling Microsoft Sync in account settings)
  # while the job is running.
  # NOTE: this does not run any AR callbacks/validations (uses update_all)
  # Whatever the result, this also updates workflow_state on the model passed
  # in to reflect the actual DB state.
  # Returns true if the record was updated (i.e. record exists and is not deleted).
  def update_unless_deleted(attrs = {})
    records_updated = self.class
                          .where(id:).where.not(workflow_state: "deleted").update_all(attrs)
    if records_updated == 0
      # It could actually be that the record was hard-deleted and not
      # workflow_state=deleted, but whatever
      self.workflow_state = "deleted"
      false
    else
      assign_attributes(attrs)
      true
    end
  end

  def syncer_job
    MicrosoftSync::StateMachineJob.new(self, MicrosoftSync::SyncerSteps.new(self))
  end

  def enqueue_future_sync
    return unless update_unless_deleted(workflow_state: :scheduled)

    syncer_job.delay(
      singleton: "#{self.class.name}:#{global_id}:enqueue_future_sync",
      run_at: Setting.get("microsoft_group_enrollments_syncing_debounce_minutes", "10")
              .to_i.minutes.from_now,
      on_conflict: :overwrite
    ).run_later
  end

  def enqueue_future_partial_sync(enrollment)
    return unless update_unless_deleted(workflow_state: :scheduled)

    MicrosoftSync::PartialSyncChange.upsert_for_enrollment(enrollment)

    syncer_job.delay(
      singleton: "#{self.class.name}:#{global_id}:enqueue_future_partial_sync",
      run_at: Setting.get("microsoft_group_enrollments_partial_syncing_debounce_minutes", "10")
              .to_f.minutes.from_now,
      on_conflict: :overwrite
    ).run_later(:partial)
  end
end
