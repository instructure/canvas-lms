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
module Interfaces::ModuleItemInterface
  include Interfaces::BaseInterface

  description "An item that can be in context modules"

  field :modules, [Types::ModuleType], null: true
  def modules
    Loaders::IDLoader.for(ContentTag).load_many(@object.context_module_tag_ids).then do |cts|
      Loaders::AssociationLoader.for(ContentTag, :context_module).load_many(cts).then do |modules|
        modules.sort_by(&:position)
      end
    end
  end

  field :title, String, null: true
  delegate :title, to: :@object

  field :type, String, null: true
  def type
    @object.class.name
  end

  field :points_possible, Float, null: true
  def points_possible
    @object.try(:points_possible)
  end

  field :published, Boolean, null: true do
    description "Whether the module item is published"
  end
  def published
    # Handle different content types
    case object
    when ContentTag
      object.content.published?
    when Assignment, DiscussionTopic, WikiPage, Quizzes::Quiz, Attachment
      object.published?
    else
      # Default fallback
      true
    end
  end

  field :can_unpublish, Boolean, null: true do
    description "Whether the module item can be unpublished"
  end
  def can_unpublish
    # Handle different content types
    case object
    when ContentTag
      object.content.can_unpublish?
    when Assignment, DiscussionTopic, WikiPage, Quizzes::Quiz, Attachment
      object.can_unpublish?
    else
      # Default fallback
      true
    end
  end
end
