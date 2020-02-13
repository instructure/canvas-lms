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
    @user = user
  end

  def perform(contexts)
    Shackles.activate(:slave) do
      contexts.each do |context|
        # Use sequential_ids to insure the modules are in the correct oreder
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

    alias content_tag object

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
  end
end
