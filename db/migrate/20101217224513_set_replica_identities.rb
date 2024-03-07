# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class SetReplicaIdentities < ActiveRecord::Migration[7.0]
  tag :predeploy

  def set_replica_identity(table, identity = "index_#{table}_replica_identity")
    super
  end

  def up
    return if connection.index_exists?(:content_tags, replica_identity: true)

    set_replica_identity :content_tags
    set_replica_identity :context_external_tools
    set_replica_identity :developer_key_account_bindings
    set_replica_identity :developer_keys
    set_replica_identity :lti_line_items
    set_replica_identity :lti_resource_links
    set_replica_identity :lti_results
    set_replica_identity :originality_reports
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
