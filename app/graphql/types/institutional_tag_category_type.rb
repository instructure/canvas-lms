# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# NOTE: Depends on InstitutionalTagCategory model (app/models/institutional_tag_category.rb)

class Types::InstitutionalTagCategoryType < Types::ApplicationObjectType
  implements GraphQL::Types::Relay::Node
  implements Interfaces::LegacyIDInterface
  implements Interfaces::TimestampInterface

  connection_type_class Types::TotalCountConnection
  global_id_field :id
  field :associations_count, Integer, null: false
  field :description,        String,  null: true
  field :name,               String,  null: false
  field :workflow_state,     String,  null: false

  def associations_count
    Loaders::InstitutionalTagCategoryAssociationsCountLoader.load(object)
  end

  field :tags_connection, Types::InstitutionalTagType.connection_type, null: true
  def tags_connection
    load_association(:institutional_tags).then do |tags|
      tags.where(workflow_state: "active")
    end
  end
end
