#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

  serialize :parameters

  workflow do
    state :created
    state :running
    state :complete
    state :error
    state :deleted
  end

  named_scope :last_complete_of_type, lambda{|type|
    { :conditions => [ "report_type = ? AND workflow_state = 'complete'", type],
      :order => "updated_at DESC",
      :limit => 1
    }
  }

  named_scope :last_of_type, lambda{|type|
    { :conditions => [ "report_type = ?", type ],
      :order => "updated_at DESC",
      :limit => 1
    }
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
    if AccountReport.available_reports(self.account)[self.report_type]
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
  handle_asynchronously :run_report

  def self.available_reports(account)
    # check if there is a reports plugin for this account
    Canvas::AccountReports.for_account(account.root_account.id)
  end

end
