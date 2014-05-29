#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  attr_accessible :user, :account, :report_type, :parameters
  belongs_to :account
  belongs_to :user
  belongs_to :attachment

  validates_presence_of :account_id, :user_id, :workflow_state

  serialize :parameters

  workflow do
    state :created
    state :running
    state :complete
    state :error
    state :deleted
  end

  scope :last_complete_of_type, lambda { |type, limit = 1|
    last_of_type(type, limit).where(:progress => '100')
  }

  scope :last_of_type, lambda { |type, limit = 1|
    where(:report_type => type).order("updated_at DESC").limit(limit)
  }

  def context
    self.account
  end

  def root_account
    self.account.root_account
  end

  def in_progress?
    self.created? || self.running?
  end

  def run_report(type=nil)
    self.report_type ||= type
    if AccountReport.available_reports[self.report_type]
      begin
        Canvas::AccountReports.generate_report(self)
      rescue
        self.workflow_state = :error
        self.save
      end
    else
      self.workflow_state = :error
      self.save
    end
  end
  handle_asynchronously :run_report, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1

  def has_parameter?(key)
    self.parameters.is_a?(Hash) && self.parameters[key].presence
  end

  def self.available_reports
    # check if there is a reports plugin for this account
    Canvas::AccountReports.available_reports
  end

end
