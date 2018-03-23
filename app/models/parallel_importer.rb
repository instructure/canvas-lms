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
  has_many :sis_batch_errors, foreign_key: :parallel_importer_id, inverse_of: :parallel_importer

  scope :running, -> {where(workflow_state: 'running')}
  scope :completed, -> {where(workflow_state: 'completed')}

  include Workflow
  workflow do
    state :pending
    state :running
    state :retry
    state :failed
    state :aborted
    state :completed
  end

  def start
    if workflow_state == 'retry'
      self.update_attributes!(started_at: Time.now.utc)
    else
      self.update_attributes!(:workflow_state => "running", :started_at => Time.now.utc)
    end
  end

  def fail
    self.update_attributes!(:workflow_state => "failed", :ended_at => Time.now.utc)
  end

  def abort
    self.update_attributes!(:workflow_state => "aborted", :ended_at => Time.now.utc)
  end

  def complete(opts={})
    updates = {:workflow_state => "completed", :ended_at => Time.now.utc}.merge(opts)
    self.update_attributes!(updates)
  end
end

