# frozen_string_literal: true

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
class ValidateMigrationIntegrity < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    initial_migration_version = "20101210192618"
    last_squashed_migration_version = "20231220155354"

    versions = if $canvas_rails == "7.1"
                 ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection).versions
               else
                 ActiveRecord::SchemaMigration.all_versions
               end
    initial_migration_has_run = versions.include?(initial_migration_version)
    last_squashed_migration_has_run = versions.include?(last_squashed_migration_version)

    if initial_migration_has_run && !last_squashed_migration_has_run
      msg = <<~TEXT
        You are trying to upgrade from a too-old version of Canvas. Please
        first upgrade to a version that includes database migration
        #{last_squashed_migration_version}.
      TEXT
      msg += "You can reset the test database with `RAILS_ENV=test bin/rake db:test:reset`" if Rails.env.test?
      raise msg
    end
  end
end
