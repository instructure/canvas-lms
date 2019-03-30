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
  class ExternalToolType < ApplicationObjectType
    graphql_name "ExternalTool"

    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface

    field :_id, ID, "legacy canvas id", null: false, method: :id

    # TODO: This is currently just a placeholder so that it can be used in
    #       ModuleItemType. Once we start exporting actual fields for this,
    #       we will need to figure out Relay::Node, read permission, differnt
    #       types (:assignment_menu, :quiz_menu, et al), and whatever else.

    def modules
      load_association(:content_tags).then do |tags|
        Loaders::AssociationLoader.for(ContentTag, :context_module).load_many(tags).then do |modules|
          modules.uniq
        end
      end
    end
  end
end
