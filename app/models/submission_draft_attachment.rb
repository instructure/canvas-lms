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

class SubmissionDraftAttachment < ActiveRecord::Base
  belongs_to :submission_draft, inverse_of: :submission_draft_attachments
  belongs_to :attachment, inverse_of: :submission_draft_attachments

  validates :submission_draft, presence: true
  validates :attachment, presence: true
  validates :submission_draft, uniqueness: { scope: :attachment }

  after_create :save_shadow_submission_draft_attachment, if: :cross_shard_attachment?
  before_destroy :destroy_shadow_submission_draft_attachment, if: :cross_shard_attachment?

  def attachment_shard
    @attachment_shard ||= Shard.shard_for(attachment_id)
  end

  private

  def cross_shard_attachment?
    attachment_id.present? && attachment_shard != shard
  end

  def save_shadow_submission_draft_attachment
    save_shadow_record(target_shard: attachment_shard)
  end

  def destroy_shadow_submission_draft_attachment
    destroy_shadow_records(target_shards: attachment_shard)
  end
end
