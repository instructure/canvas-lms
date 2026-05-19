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

# NOTE: Depends on InstitutionalTagAssociation model (app/models/institutional_tag_association.rb)

class Types::InstitutionalTagAssociationType < Types::ApplicationObjectType
  implements GraphQL::Types::Relay::Node
  implements Interfaces::LegacyIDInterface
  implements Interfaces::TimestampInterface

  global_id_field :id

  field :tag, Types::InstitutionalTagType, null: false
  def tag
    load_association(:institutional_tag)
  end

  field :user, Types::UserType, null: true
  def user
    load_association(:user)
  end
end
