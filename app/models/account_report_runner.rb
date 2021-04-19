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

class AccountReportRunner < ActiveRecord::Base
  include Workflow

  belongs_to :account_report, inverse_of: :account_report_runners
  has_many :account_report_rows, inverse_of: :account_report_runner, autosave: false

  workflow do
    state :created
    state :running
    state :completed
    state :error
    state :aborted
  end

  attr_accessor :rows

  def initialize(*)
    @rows = []
    super
  end

  def write_rows
    return unless rows
    return if rows.empty?
    GuardRail.activate(:primary) do
      self.class.bulk_insert_objects(rows)
      @rows = []
    end
  end

  def start
    @rows ||= []
    self.update!(workflow_state: 'running', started_at: Time.now.utc)
  end

  def complete
    write_rows
    self.update!(workflow_state: 'completed', ended_at: Time.now.utc)
  end

  def abort
    self.update!(workflow_state: 'aborted', ended_at: Time.now.utc)
  end

  def fail
    self.update!(workflow_state: 'error', ended_at: Time.now.utc)
  end

  scope :in_progress, -> {where(workflow_state: %w(running))}
  scope :completed, -> {where(workflow_state: %w(completed))}
  scope :incomplete, -> {where(workflow_state: %w(created running))}

  def delete_account_report_rows
    cleanup = self.account_report_rows.limit(10_000)
    until cleanup.delete_all < 10_000; end
  end
end
