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
#

class ModuleProgressionVisibleLoader < GraphQL::Batch::Loader
  def initialize(user)
    super()
    @user = user
  end

  def perform(contexts)
    GuardRail.activate(:secondary) do
      contexts.each do |context|
        # Use sequential_ids to ensure the modules are in the correct order
        sequential_ids = context.sequential_module_item_ids
        ids = sequential_ids & context.module_items_visible_to(@user).reorder(nil).pluck(:id)
        fulfill(context, ids)
      end
    end
  end
end

module Types
  class ModuleItemType < ApplicationObjectType
    graphql_name "ModuleItem"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    alias_method :content_tag, :object

    global_id_field :id

    field :module, Types::ModuleType, null: true, resolver_method: :module_resolver
    def module_resolver
      load_association(:context_module)
    end

    field :url, Types::UrlType, null: true
    def url
      GraphQLHelpers::UrlHelpers.course_context_modules_item_redirect_url(
        id: content_tag.id,
        course_id: content_tag.context_id,
        host: context[:request].host_with_port
      )
    end

    field :indent, Integer, null: true
    delegate :indent, to: :object

    field :title, String, null: true
    delegate :title, to: :object

    field :next, Types::ModuleItemType, null: true, resolver_method: :next_resolver
    def next_resolver
      Loaders::AssociationLoader.for(ContentTag, :context).load(content_tag).then do |context|
        ModuleProgressionVisibleLoader.for(current_user).load(context).then do |visible_tag_ids|
          index = visible_tag_ids.index(content_tag.id)
          next nil if index.nil?
          next nil if index == visible_tag_ids.size - 1

          next_id = visible_tag_ids[index + 1]
          Loaders::IDLoader.for(ContentTag).load(next_id)
        end
      end
    end

    field :next_items_connection,
          Types::ModuleItemType.connection_type,
          "Items are ordered based on distance to the current item, starting with the next item directly following it.",
          null: true
    def next_items_connection
      Loaders::AssociationLoader.for(ContentTag, :context).load(content_tag).then do |context|
        ModuleProgressionVisibleLoader.for(current_user).load(context).then do |visible_tag_ids|
          index = visible_tag_ids.index(content_tag.id)
          next nil if index.nil?
          next [] if index == visible_tag_ids.size - 1

          previous_ids = visible_tag_ids[(index + 1)..]
          previous_ids.map { |id| Loaders::IDLoader.for(ContentTag).load(id) }
        end
      end
    end

    field :previous, Types::ModuleItemType, null: true
    def previous
      Loaders::AssociationLoader.for(ContentTag, :context).load(content_tag).then do |context|
        ModuleProgressionVisibleLoader.for(current_user).load(context).then do |visible_tag_ids|
          index = visible_tag_ids.index(content_tag.id)
          next nil if index.nil?
          next nil if index == 0

          previous_id = visible_tag_ids[index - 1]
          Loaders::IDLoader.for(ContentTag).load(previous_id)
        end
      end
    end

    field :previous_items_connection,
          Types::ModuleItemType.connection_type,
          "Items are ordered based on distance to the current item, starting with the previous item directly preceding it.",
          null: true
    def previous_items_connection
      Loaders::AssociationLoader.for(ContentTag, :context).load(content_tag).then do |context|
        ModuleProgressionVisibleLoader.for(current_user).load(context).then do |visible_tag_ids|
          index = visible_tag_ids.index(content_tag.id)
          next nil if index.nil?
          next [] if index == 0

          previous_ids = visible_tag_ids[0...index].reverse
          previous_ids.map { |id| Loaders::IDLoader.for(ContentTag).load(id) }
        end
      end
    end

    field :position, Integer, null: true
    delegate :position, to: :object

    field :content, Interfaces::ModuleItemInterface, null: true
    def content
      # External Urls don't have a seperate content_id, and external tools don't
      # always have an external content id. In those cases we generate the content
      # directly from this content tag
      if content_tag.content_id == 0 || content_tag.content_id.nil?
        content_tag
      else
        Loaders::AssociationLoader.for(ContentTag, :content).load(content_tag)
      end
    end

    field :estimated_duration, GraphQL::Types::ISO8601Duration, null: true
    def estimated_duration
      Loaders::AssociationLoader.for(ContentTag, :estimated_duration).load(content_tag).then do |estimated_duration|
        estimated_duration&.duration&.iso8601
      end
    end

    field :master_course_restrictions, Types::ModuleItemMasterCourseRestrictionType, null: true, description: "Restrictions from master courses for this module item", camelize: true
    def master_course_restrictions
      Loaders::ModuleItemMasterCourseRestrictionsLoader.for(current_user).load(content_tag)
    end
  end
end
