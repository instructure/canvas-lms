#
# Copyright (C) 2020 - present Instructure, Inc.
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
module Auditors::ActiveRecord
  # This model is intended to be temporary.
  # We'll use it for bookkeeping which chunks of data have
  # been backfilled from cassandra to postgres.
  # Once the backfill is complete we can drop the table
  # and remove the model from the codebase.
  #
  # For now, each row represents the attempt to migrate
  # auditors data for one table type, in one account, on one day.
  class MigrationCell < ActiveRecord::Base
    self.table_name = 'auditor_migration_cells'
  end
end