# frozen_string_literal: true

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

class ParallelImporter < ActiveRecord::Base
  belongs_to :sis_batch
  belongs_to :attachment
  has_many :sis_batch_errors, inverse_of: :parallel_importer
  include CaptureJobIds

  scope :running, -> { where(workflow_state: "running") }
  scope :completed, -> { where(workflow_state: "completed") }
  scope :not_completed, -> { where(workflow_state: %w[pending queued running retry]) }

  include Workflow
  workflow do
    state :pending
    state :queued
    state :running
    state :retry
    state :failed
    state :aborted
    state :completed
  end

  def start
    capture_job_id
    if workflow_state == "retry"
      update!(started_at: Time.now.utc)
    else
      update!(workflow_state: "running", started_at: Time.now.utc)
    end
  end

  def fail
    update!(workflow_state: "failed", ended_at: Time.now.utc)
  end

  def abort
    update!(workflow_state: "aborted", ended_at: Time.now.utc)
  end

  def complete(opts = {})
    updates = { workflow_state: "completed", ended_at: Time.now.utc }.merge(opts)
    update!(updates)
  end
end
