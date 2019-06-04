#
# Copyright (C) 2019 - present Instructure, Inc.
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

class CreateMutationAuditLog < ActiveRecord::Migration[5.1]
  tag :predeploy

  include Canvas::DynamoDB::Migration

  category :auditors

  def self.up
    create_table table_name: :graphql_mutations,
      ttl_attribute: "expires",
      attribute_definitions: [
        {attribute_name: "object_id", attribute_type: "S"},
        {attribute_name: "mutation_id", attribute_type: "S"},
      ],
      key_schema: [
        {attribute_name: "object_id", key_type: "HASH"},
        {attribute_name: "mutation_id", key_type: "RANGE"},
      ]
  end

  def self.down
    delete_table table_name: :graphql_mutations
  end
end
