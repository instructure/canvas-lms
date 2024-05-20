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

class MasterCourses::MigrationResult < ActiveRecord::Base
  belongs_to :master_migration, class_name: "MasterCourses::MasterMigration"
  belongs_to :content_migration
  belongs_to :child_subscription, class_name: "MasterCourses::ChildSubscription"
  belongs_to :root_account, class_name: "Account"

  before_create :set_root_account_id

  serialize :results, type: Hash

  def skipped_items
    results[:skipped] || []
  end

  def set_root_account_id
    self.root_account_id ||= master_migration.root_account_id
  end
end
