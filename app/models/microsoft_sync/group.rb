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

# It seems like it sometimes gets confused and misses the table prefix without this...
require_dependency 'microsoft_sync'

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
# Notable fields:
# * ms_group_id -- Microsoft's ID used in the their Graph API for the group
#
class MicrosoftSync::Group < ActiveRecord::Base
  extend RootAccountResolver
  include Workflow

  belongs_to :course
  validates_presence_of :course
  validates_uniqueness_of :course_id

  scope :not_deleted, -> { where.not(workflow_state: 'deleted') }

  workflow do
    state :pending # Initial state, before first sync
    state :running
    state :errored
    state :completed
    state :deleted
  end

  resolves_root_account through: :course

  alias_method :destroy_permanently!, :destroy
  def destroy
    return true if deleted?

    self.workflow_state = 'deleted'
    run_callbacks(:destroy) { save! }
  end

  def restore!
    return unless self.deleted?

    update!(
      workflow_state: 'pending',
      job_state: nil,
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
  def update_workflow_state_unless_deleted(new_state, extra={})
    records_updated = self.class.where(id: id).where.not(workflow_state: 'deleted').
      update_all(extra.merge(workflow_state: new_state))
    if records_updated == 0
      # It could actually be that the record was hard-deleted and not
      # workflow_state=deleted, but whatever
      self.workflow_state = 'deleted'
      false
    else
      self.workflow_state = new_state
      assign_attributes(extra)
      true
    end
  end

  def sync!
    MicrosoftSync::Syncer.new(self).sync!
  end
end
