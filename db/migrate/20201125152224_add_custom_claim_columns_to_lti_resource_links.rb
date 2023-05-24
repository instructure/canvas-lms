# frozen_string_literal: true

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
class AddCustomClaimColumnsToLtiResourceLinks < ActiveRecord::Migration[5.2]
  tag :predeploy

  disable_ddl_transaction!

  def change
    add_column :lti_resource_links, :context_id, :bigint, if_not_exists: true
    add_column :lti_resource_links, :context_type, :string, limit: 255, if_not_exists: true
    add_column :lti_resource_links, :custom, :jsonb, if_not_exists: true
    add_column :lti_resource_links, :lookup_id, :string, limit: 255, if_not_exists: true

    add_index :lti_resource_links,
              [:context_id, :context_type],
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_lti_resource_links_by_context_id_context_type"
    add_index :lti_resource_links,
              :lookup_id,
              algorithm: :concurrently,
              unique: true,
              if_not_exists: true
  end
end
