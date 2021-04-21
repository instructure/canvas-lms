# frozen_string_literal: true

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

module Types
  # This is a little funky. External tools can either be backed by a `ContextExternalTool`
  # in the database, or directly by data in a `ContentTag`. Because there could
  # be conflicting legacy id for these, we are seperating them into two concrete
  # types in graphql. ModuleExternalToolType is the one backed by `ContentTag`,
  # and `ExternalToolType` is backed by `ContextExternalTool`.
  class ModuleExternalToolType < ApplicationObjectType
    graphql_name "ModuleExternalTool"

    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    field :url, String, null: true

    def modules
      load_association(:context_module).then { |mod| [mod] }
    end
  end
end
