# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::BackfillAttachmentIdsOnMediaTracks do
  before(:once) do
    @mo1 = MediaObject.create!(attachment_id: 50, media_id: "m-dummy3iT1WiTVYNhJ1sZTSaFx5R3yHn1")
    @mo2 = MediaObject.create!(attachment_id: 51, media_id: "m-dummy3iT1WiTVYNhJ1sZTSaFx5R3yHn2")
    @mo3 = MediaObject.create!(attachment_id: 52, media_id: "m-dummy3iT1WiTVYNhJ1sZTSaFx5R3yHn3")

    @mt1 = MediaTrack.create!(content: "x", media_object_id: @mo1.id)
    @mt2 = MediaTrack.create!(content: "y", media_object_id: @mo2.id)
    @mt3 = MediaTrack.create!(content: "z", media_object_id: @mo3.id)

    @mt1.update_column(:attachment_id, nil)
    @mt2.update_column(:attachment_id, nil)

    # we do this and don't clear out the attachment_id on mt3
    # so that we can check if non-nil attachment_ids are skipped
    @mo3.update_column(:attachment_id, 100)
  end

  it "updates the MediaTrack attachment_ids when present on the linked MediaObject" do
    described_class.run(@mt1.id, @mt2.id)

    expect(@mt1.reload.attachment_id).to be 50
    expect(@mt2.reload.attachment_id).to be 51
  end

  it "does not perform updates when MediaTrack attachment_id is not nil" do
    described_class.run(@mt3.id, @mt3.id)

    expect(@mt3.reload.attachment_id).to be 52
  end

  it "does not update a MediaTrack when it would violate the uniqueness constraint, dupe not in same batch" do
    @mt3.update_column(:attachment_id, nil)
    @mt4 = MediaTrack.create!(content: "1", media_object_id: @mo3.id)

    described_class.run(@mt3.id, @mt3.id)

    expect(@mt3.reload.attachment_id).to be_nil
  end

  it "does not update a MediaTrack when it would violate the uniqueness constraint, dupe in same batch" do
    @mt3.update_column(:attachment_id, nil)
    @mt4 = MediaTrack.create!(content: "2", media_object_id: @mo3.id)

    described_class.run(@mt3.id, @mt4.id)

    expect(@mt3.reload.attachment_id).to be_nil
  end

  it "only updates the most recent MediaTrack if multiple need update and would violate uniqueness constraint" do
    @mt3.update_column(:attachment_id, nil)
    @mt4 = MediaTrack.create!(content: "3", media_object_id: @mo3.id)
    @mt4.update_column(:attachment_id, nil)

    described_class.run(@mt3.id, @mt4.id)

    expect(@mt3.reload.attachment_id).to be_nil
    expect(@mt4.reload.attachment_id).to be 100
  end
end
