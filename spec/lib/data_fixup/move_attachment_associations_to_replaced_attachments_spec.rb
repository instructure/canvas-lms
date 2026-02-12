# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::MoveAttachmentAssociationsToReplacedAttachments do
  before(:once) do
    course_model
    @discussion_topic = @course.discussion_topics.create!(title: "Test Topic")
  end

  describe ".run" do
    it "moves attachment_associations from replaced attachments to their replacements" do
      original_attachment = attachment_with_context(@course, display_name: "original.pdf")
      association1 = original_attachment.attachment_associations.create!(context: @discussion_topic)
      association2 = original_attachment.attachment_associations.create!(context: @discussion_topic)

      replacement_attachment = attachment_with_context(@course, display_name: "replacement.pdf")

      original_attachment.update!(
        replacement_attachment_id: replacement_attachment.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      DataFixup::MoveAttachmentAssociationsToReplacedAttachments.run

      association1.reload
      association2.reload
      expect(association1.attachment_id).to eq replacement_attachment.id
      expect(association2.attachment_id).to eq replacement_attachment.id
    end

    it "handles multiple replaced attachments with different replacements" do
      original1 = attachment_with_context(@course, display_name: "original1.pdf")
      replacement1 = attachment_with_context(@course, display_name: "replacement1.pdf")
      assoc1 = original1.attachment_associations.create!(context: @discussion_topic)

      original1.update!(
        replacement_attachment_id: replacement1.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      original2 = attachment_with_context(@course, display_name: "original2.pdf")
      replacement2 = attachment_with_context(@course, display_name: "replacement2.pdf")
      assoc2 = original2.attachment_associations.create!(context: @discussion_topic)

      original2.update!(
        replacement_attachment_id: replacement2.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      DataFixup::MoveAttachmentAssociationsToReplacedAttachments.run

      assoc1.reload
      assoc2.reload
      expect(assoc1.attachment_id).to eq replacement1.id
      expect(assoc2.attachment_id).to eq replacement2.id
    end

    it "does not affect associations already on replacement attachments" do
      original = attachment_with_context(@course, display_name: "original.pdf")
      replacement = attachment_with_context(@course, display_name: "replacement.pdf")

      existing_assoc = replacement.attachment_associations.create!(context: @discussion_topic)

      original.update!(
        replacement_attachment_id: replacement.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      DataFixup::MoveAttachmentAssociationsToReplacedAttachments.run

      existing_assoc.reload
      expect(existing_assoc.attachment_id).to eq replacement.id
    end

    it "handles attachments with no associations" do
      original = attachment_with_context(@course, display_name: "original.pdf")
      replacement = attachment_with_context(@course, display_name: "replacement.pdf")

      original.update!(
        replacement_attachment_id: replacement.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      expect { DataFixup::MoveAttachmentAssociationsToReplacedAttachments.run }.not_to raise_error
    end

    it "handles replacement chains (A replaced by B, but we only update A's associations)" do
      # chain: original -> replacement1 -> replacement2
      original = attachment_with_context(@course, display_name: "original.pdf")
      replacement1 = attachment_with_context(@course, display_name: "replacement1.pdf")
      replacement2 = attachment_with_context(@course, display_name: "replacement2.pdf")

      assoc = original.attachment_associations.create!(context: @discussion_topic)

      original.update!(
        replacement_attachment_id: replacement1.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      replacement1.update!(
        replacement_attachment_id: replacement2.id,
        file_state: "deleted",
        deleted_at: Time.zone.now
      )

      DataFixup::MoveAttachmentAssociationsToReplacedAttachments.run

      assoc.reload
      expect(assoc.attachment_id).to eq replacement2.id
    end
  end
end
