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
#
module Types
  class ContentTagContentType < Types::BaseUnion
    description 'Content of a Content Tag'
    possible_types Types::LearningOutcomeType
  end

  class ContentTagType < GraphQL::Types::Relay::BaseEdge
    node_type(Types::ContentTagContentType)

    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface
    implements Interfaces::TimestampInterface

    global_id_field :id

    def node
      Loaders::AssociationLoader.for(object.class, :content).load(object)
    end
  end

  class ContentTagConnection < GraphQL::Types::Relay::BaseConnection
    edge_type(Types::ContentTagType)

    def edges
      @object.edge_nodes
    end

    def nodes
      edges.map(&:content)
    end
  end
end
