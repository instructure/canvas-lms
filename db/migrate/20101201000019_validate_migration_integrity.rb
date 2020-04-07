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

# ---
# We have started the process to squash migration files down to speed up
# local development/testing. This migration will run first and check if the
# migrations being squashed have been either fully or not-at-all applied, in
# which case it is safe to proceed, and otherwise throws an error.
#
# To squash more migrations, update the `last_squashed_migration_version` and
# bump the version in the filename of this migration so it runs again.
class ValidateMigrationIntegrity < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    initial_migration_version = "20101210192618"
    last_squashed_migration_version = "20140530195059"

    initial_migration_has_run = ActiveRecord::SchemaMigration.where(version: initial_migration_version).exists?
    last_squashed_migration_has_run = ActiveRecord::SchemaMigration.where(version: last_squashed_migration_version).exists?

    if initial_migration_has_run && !last_squashed_migration_has_run
      raise <<-ERROR
        You are trying to upgrade from a too-old version of Canvas. Please
        first upgrade to a version that includes database migration
        #{last_squashed_migration_version}.
      ERROR
    end
  end

  def self.down
  end
end

