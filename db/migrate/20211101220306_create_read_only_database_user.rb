# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class CreateReadOnlyDatabaseUser < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    # this user is *not* used in production! it's only used to simulate a read-only secondary database in dev/test
    return if ::Rails.env.production?

    # the user is cluster-wide ...
    unless readonly_user_exists?
      execute("CREATE USER canvas_readonly_user")
    end

    # ... but needs permissions on each shard's schema
    execute("GRANT USAGE ON SCHEMA #{quoted_schema} TO canvas_readonly_user")
    execute("GRANT SELECT ON ALL TABLES IN SCHEMA #{quoted_schema} TO canvas_readonly_user")
    execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{quoted_schema} GRANT SELECT ON TABLES TO canvas_readonly_user")
  end

  def down
    return if ::Rails.env.production?

    return unless readonly_user_exists?

    # the user's privileges must be revoked before it can be dropped
    execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{quoted_schema} REVOKE SELECT ON TABLES FROM canvas_readonly_user")
    execute("REVOKE SELECT ON ALL TABLES IN SCHEMA #{quoted_schema} FROM canvas_readonly_user")
    execute("REVOKE USAGE ON SCHEMA #{quoted_schema} FROM canvas_readonly_user")

    # attempt to drop the user. this will fail if another schema references it, but should succeed when this
    # migration runs on the last shard in the cluster
    begin
      connection.transaction(requires_new: true) do
        execute("DROP USER canvas_readonly_user")
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::DependentObjectsStillExist)
    end
  end

  def readonly_user_exists?
    !!connection.select_value("SELECT 1 AS one FROM pg_roles WHERE rolname='canvas_readonly_user'")
  end

  def quoted_schema
    @quoted_schema ||= connection.quote_local_table_name(Shard.current.name)
  end
end
