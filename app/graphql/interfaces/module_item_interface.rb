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
module Interfaces::ModuleItemInterface
  include GraphQL::Schema::Interface
  description "An item that can be in context modules"

  field :modules, [Types::ModuleType], null: true
  def modules
    Loaders::IDLoader.for(ContentTag).load_many(@object.context_module_tag_ids).then do |cts|
      Loaders::AssociationLoader.for(ContentTag, :context_module).load_many(cts).then do |modules|
        modules.sort_by(&:position)
      end
    end
  end
end
