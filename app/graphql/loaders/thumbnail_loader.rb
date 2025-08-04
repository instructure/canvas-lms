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

##
# Batch-loads thumbnail associations for attachments to prevent N+1 queries
# when GraphQL resolvers access thumbnail data.
#
# This loader preloads all thumbnails for a batch of attachments in a single
# query, then caches the results for efficient access.
#
# Example:
#
#     Loaders::ThumbnailLoader.for.load(attachment).then do |preloaded_attachment|
#       # preloaded_attachment.thumbnails are pre-loaded
#       # preloaded_attachment.thumbnail uses cached data
#     end

class Loaders::ThumbnailLoader < GraphQL::Batch::Loader
  def perform(attachments)
    # Preload thumbnails association for all attachments
    ActiveRecord::Associations.preload(attachments, :thumbnails)

    # Also preload the parent attachment for each thumbnail to prevent N+1 when
    # thumbnails access attachment.context or attachment.root_account
    all_thumbnails = attachments.flat_map(&:thumbnails)
    ActiveRecord::Associations.preload(all_thumbnails, :attachment) if all_thumbnails.any?

    # Fulfill each attachment with itself (now with preloaded thumbnails)
    attachments.each { |attachment| fulfill(attachment, attachment) }
  end
end
