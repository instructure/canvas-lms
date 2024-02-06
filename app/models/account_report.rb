# frozen_string_literal: true

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
  include LocaleSelection
  include CaptureJobIds

  belongs_to :account, inverse_of: :account_reports
  belongs_to :user, inverse_of: :account_reports
  belongs_to :attachment, inverse_of: :account_report
  has_many :account_report_runners, inverse_of: :account_report, autosave: false
  has_many :account_report_rows, inverse_of: :account_report, autosave: false

  after_save :abort_incomplete_runners_if_needed

  validates :account_id, :user_id, :workflow_state, presence: true

  serialize :parameters, type: Hash

  attr_accessor :runners

  def initialize(*)
    @runners = []
    super
  end

  def add_report_runner(batch)
    @runners ||= []
    runners << account_report_runners.new(batch_items: batch, created_at: Time.zone.now, updated_at: Time.zone.now)
  end

  def write_report_runners
    return if runners.empty?

    self.class.bulk_insert_objects(runners)
    @runners = []
  end

  workflow do
    state :created
    state :running
    state :compiling
    state :complete
    state :error
    state :aborted
    state :deleted
  end

  scope :complete, -> { where(progress: 100) }
  scope :running, -> { where(workflow_state: "running") }
  scope :most_recent, -> { order(created_at: :desc).limit(1) }
  scope :active, -> { where.not(workflow_state: "deleted") }

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  def self.delete_old_rows_and_runners
    # There is a FK between rows and runners, so delete rows first
    AccountReportRow.where("created_at<?", 28.days.ago).in_batches(of: 10_000).delete_all

    # There is a FK between rows and runners.
    # Use subquery to ensure we don't remove any that
    # had rows created late enough that they're on different sides
    # of the date boundary.
    date_window_scope = AccountReportRunner.where("created_at<?", 28.days.ago)
    no_fk_scope = date_window_scope.where("NOT EXISTS (SELECT NULL
                    FROM #{AccountReportRow.quoted_table_name} arr
                    WHERE arr.account_report_runner_id = account_report_runners.id)")
    no_fk_scope.in_batches(of: 10_000).delete_all
  end

  def delete_account_report_rows
    account_report_rows.in_batches(of: 10_000).delete_all
  end

  def context
    account
  end

  delegate :root_account, to: :account

  def in_progress?
    created? || running?
  end

  def run_report(type = nil, attempt: 1)
    parameters["locale"] = infer_locale(user:, root_account: account)
    self.report_type ||= type
    if AccountReport.available_reports[self.report_type]
      begin
        AccountReports.generate_report(self, attempt:)
      rescue
        mark_as_errored
      end
    else
      mark_as_errored
    end
  end
  handle_asynchronously :run_report,
                        priority: Delayed::LOW_PRIORITY,
                        n_strand: proc { |ar| ["account_reports", ar.account.root_account.global_id] },
                        on_permanent_failure: :mark_as_errored

  def mark_as_errored
    self.workflow_state = :error
    save!
  end

  def has_parameter?(key)
    parameters.is_a?(Hash) && parameters[key].presence
  end

  def value_for_param(key)
    parameters.is_a?(Hash) && parameters[key].presence
  end

  def self.available_reports
    # check if there is a reports plugin for this account
    AccountReports.available_reports
  end

  def abort_incomplete_runners_if_needed
    if saved_change_to_workflow_state? && (deleted? || aborted? || error?)
      abort_incomplete_runners
      delay(priority: Delayed::LOWER_PRIORITY).delete_account_report_rows
    end
  end

  def abort_incomplete_runners
    account_report_runners.incomplete.in_batches.update_all(workflow_state: "aborted", updated_at: Time.now.utc)
  end
end
