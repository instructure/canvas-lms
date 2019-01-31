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

class AccountReport < ActiveRecord::Base
  include Workflow

  belongs_to :account
  belongs_to :user
  belongs_to :attachment
  has_many :account_report_runners, inverse_of: :account_report, autosave: false
  has_many :account_report_rows, inverse_of: :account_report, autosave: false

  validates :account_id, :user_id, :workflow_state, presence: true

  serialize :parameters

  workflow do
    state :created
    state :running
    state :compiling
    state :complete
    state :error
    state :aborted
    state :deleted
  end

  scope :complete, -> {where(progress: 100)}
  scope :most_recent, -> {order(updated_at: :desc).limit(1)}
  scope :active, -> {where.not(workflow_state: 'deleted')}

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def self.delete_old_rows_and_runners
    cleanup = AccountReportRow.where("created_at<?", 30.days.ago).limit(10_000)
    until cleanup.delete_all < 10_000; end
    # There is a FK between rows and runners, skipping 2 days to avoid conflicts
    # for a long running report or a big backlog of queued reports.
    # This avoids the join to check for rows so that it can run faster in a
    # periodic job.
    cleanup = AccountReportRunner.where("created_at<?", 28.days.ago).limit(10_000)
    until cleanup.delete_all < 10_000; end
  end

  def delete_account_report_rows
    cleanup = self.account_report_rows.limit(10_000)
    until cleanup.delete_all < 10_000; end
  end

  def context
    self.account
  end

  def root_account
    self.account.root_account
  end

  def in_progress?
    self.created? || self.running?
  end

  def run_report(type = nil)
    self.report_type ||= type
    if AccountReport.available_reports[self.report_type]
      begin
        AccountReports.generate_report(self)
      rescue
        self.workflow_state = :error
        self.save
      end
    else
      self.workflow_state = :error
      self.save
    end
  end
  handle_asynchronously :run_report, priority: Delayed::LOW_PRIORITY, max_attempts: 1,
                        n_strand: proc {|ar| ['account_reports', ar.account.root_account.global_id]}

  def has_parameter?(key)
    self.parameters.is_a?(Hash) && self.parameters[key].presence
  end

  def self.available_reports
    # check if there is a reports plugin for this account
    AccountReports.available_reports
  end

end
