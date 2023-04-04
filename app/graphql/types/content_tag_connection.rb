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
    description "Content of a Content Tag"
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

    field :can_unlink, Boolean, null: true
    def can_unlink
      if learning_outcome_link?
        can_manage = (object.context_type == "LearningOutcomeGroup") ? can_manage_global_outcomes : can_manage_context_outcomes
        can_manage && object.can_destroy?
      end
    end

    field :group, LearningOutcomeGroupType, null: true
    def group
      Loaders::AssociationLoader.for(object.class, :associated_asset).load(object) if learning_outcome_link?
    end

    private

    def learning_outcome_link?
      object.tag_type == "learning_outcome_association" &&
        object.associated_asset_type == "LearningOutcomeGroup" &&
        object.content_type == "LearningOutcome"
    end

    def can_manage_context_outcomes
      object.context.grants_right?(current_user, session, :manage_outcomes)
    end

    def can_manage_global_outcomes
      Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
    end

    def session
      context[:session]
    end

    def current_user
      context[:current_user]
    end
  end

  class ContentTagConnection < GraphQL::Types::Relay::BaseConnection
    edge_type(Types::ContentTagType)

    def edges
      @object.edge_nodes
    end

    def nodes
      Loaders::AssociationLoader.for(ContentTagContentType, :content).load_many(edges)
    end
  end
end
