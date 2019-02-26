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

class AttachmentsLoader < GraphQL::Batch::Loader
  def initialize(assignment)
    @assignment = assignment
  end

  def perform(comments)
    assignment_attachment_ids = @assignment.attachment_ids.to_set
    comment_attachments = comments.each_with_object({}) do |comment, hash|
      comment_attachment_ids = comment.parse_attachment_ids.to_set
      hash[comment] = comment_attachment_ids & assignment_attachment_ids
    end

    ids = comment_attachments.values.reduce(:merge).to_a
    attachments = Attachment.where(id: ids)
    comment_attachments.each do |comment, attachment_ids|
      targets = attachments.select { |a|  attachment_ids.include?(a.id) }
      fulfill(comment, targets)
    end
  end
end

module Types
  class SubmissionCommentType < ApplicationObjectType
    graphql_name 'SubmissionComment'

    implements Interfaces::TimestampInterface

    field :_id, ID, 'legacy canvas id', null: true, method: :id
    field :comment, String, null: true

    field :author, Types::UserType, null: true
    def author
      # We are preloading submission and assignment here for the permission check.
      # Not ideal as that could be cached in redis, but in most cases the assignment
      # and submission will already be in the cache, as that's the graphql query
      # path to get to a submission comment, and thus costs us nothing to preload here.
      Loaders::AssociationLoader.for(SubmissionComment, [:author, {submission: :assignment}]).load(object).then do
        object.grants_right?(current_user, :read_author) ? object.author : nil
      end
    end

    field :attachments, [Types::FileType], null: true
    def attachments
      return [] if object.attachment_ids.blank?
      Loaders::AssociationLoader.for(SubmissionComment, {submission: :assignment}).load(object).then do
        AttachmentsLoader.for(object.submission.assignment).load(object)
      end
    end

    field :media_object, Types::MediaObjectType, null: true
    def media_object
      Loaders::MediaObjectLoader.load(object.media_comment_id)
    end
  end
end
