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
  class ExternalToolStateType < Types::BaseEnum
    graphql_name 'ExternalToolState'
    description 'States that an External Tool can be in'
    value 'anonymous'
    value 'name_only'
    value 'email_only'
    value 'public'
  end

  # We can add additional placements to this filter as they are needed. Currently we
  # only need to filter to `homework_submission` as that is the only place that this
  # graphql type is being queried and used in.
  class ExternalToolPlacementType < Types::BaseEnum
    graphql_name 'ExternalToolPlacement'
    description 'Placements that an External Tool can have'
    value 'homework_submission'
  end

  class ExternalToolFilterInputType < Types::BaseInputObject
    graphql_name 'ExternalToolFilterInput'

    argument :state, ExternalToolStateType, required: false, default_value: nil

    argument :placement, ExternalToolPlacementType, required: false, default_value: nil
  end

  # This is a little funky. External tools can either be backed by a `ContextExternalTool`
  # in the database, or directly by data in a `ContentTag`. Because there could
  # be conflicting legacy id for these, we are seperating them into two concrete
  # types in graphql. ModuleExternalToolType is the one backed by `ContentTag`,
  # and `ExternalToolType` is backed by `ContextExternalTool`.
  class ExternalToolType < ApplicationObjectType
    graphql_name 'ExternalTool'

    implements Interfaces::TimestampInterface
    implements Interfaces::ModuleItemInterface
    implements Interfaces::LegacyIDInterface

    field :url, Types::UrlType, null: true
    def url
      object.login_or_launch_url()
    end

    field :name, String, null: true

    field :description, String, null: true

    field :settings, ExternalToolSettingsType, null: true

    field :state, ExternalToolStateType, method: :workflow_state, null: true

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
