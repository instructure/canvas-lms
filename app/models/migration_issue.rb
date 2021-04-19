# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class MigrationIssue < ActiveRecord::Base
  include Workflow

  belongs_to :content_migration
  belongs_to :error_report

  validates_presence_of :issue_type, :content_migration_id, :workflow_state
  validates_inclusion_of :issue_type, :in => %w( todo warning error )

  workflow do
    state :active do
      event :resolve, :transitions_to => :resolved
    end

    state :resolved
  end

  scope :active, -> { where(:workflow_state => 'active') }
  scope :by_created_at, -> { order(:created_at) }

  set_policy do
    given { |user| Account.site_admin.grants_right?(user, :view_error_reports) }
    can :read_errors
  end

end
