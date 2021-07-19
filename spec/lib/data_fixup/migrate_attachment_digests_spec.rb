# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::MigrateAttachmentDigests do
  describe "run" do
    it "creates delayed jobs to update attachments" do
      attachment1 = attachment_model(uploaded_data: default_uploaded_data)
      expect(DataFixup::MigrateAttachmentDigests).to receive(:delay_if_production).at_least(:once).and_return(DataFixup::MigrateAttachmentDigests)
      DataFixup::MigrateAttachmentDigests.run
    end

    it "updates attachments with md5 digests" do
      attachment1 = attachment_model(uploaded_data: default_uploaded_data)
      attachment2 = attachment_model(uploaded_data: default_uploaded_data)
      attachment1.update(md5: 'eff033fad1e01d0b43a9caf8521ad576')
      attachment2.update(md5: 'eff033fad1e01d0b43a9caf8521ad576')
      DataFixup::MigrateAttachmentDigests.run
      attachment1.reload
      attachment2.reload
      expect(attachment1.md5.length).to eq(128)
      expect(attachment1.md5).to eq attachment2.md5
    end

    it "ignores inst-fs attachments" do
      attachment1 = attachment_model(instfs_uuid: 'uuid1',
                                     uploaded_data: default_uploaded_data)
      attachment1.update(md5: '01234567890123456789012345678901')
      DataFixup::MigrateAttachmentDigests.run
      expect(attachment1.md5).to eq '01234567890123456789012345678901'
    end

    it "ignores attachments with non-md5 digests" do
      attachment1 = attachment_model(uploaded_data: default_uploaded_data)
      attachment1.update(md5: '0123456789')
      DataFixup::MigrateAttachmentDigests.run
      expect(attachment1.md5).to eq '0123456789'
    end

    it "raises error for s3 storage" do
      allow(Attachment).to receive(:s3_storage?).and_return(true)
      expect { DataFixup::MigrateAttachmentDigests.run }.to raise_exception(RuntimeError)
    end
  end

  describe "run_for_attachment_range" do
    it "only processes attachments inside the range" do
      attachment1 = attachment_model(uploaded_data: default_uploaded_data)
      attachment1.update(md5: '1'*32)
      attachment2 = attachment_model(uploaded_data: default_uploaded_data)
      expect(DataFixup::MigrateAttachmentDigests).to receive(:recompute_attachment_digest).exactly(:once)
      DataFixup::MigrateAttachmentDigests.run_for_attachment_range(attachment1.id, attachment1.id)
    end

    it "processes all attachments inside the range" do
      attachment1 = attachment_model(uploaded_data: default_uploaded_data)
      attachment1.update(md5: '1'*32)
      attachment2 = attachment_model(uploaded_data: default_uploaded_data)
      expect(DataFixup::MigrateAttachmentDigests).to receive(:recompute_attachment_digest).exactly(:twice)
      DataFixup::MigrateAttachmentDigests.run_for_attachment_range(attachment1.id, attachment2.id)
    end
  end

  describe "recompute_attachment_digest" do
    ConfigFile.stub('file_store', { 'use_sha512_digests' => false })
    let(:file_contents) { 'file contents' }
    let(:attachment) { attachment_model(uploaded_data: default_uploaded_data) }

    it "calculates the sha512 hash correctly" do
      DataFixup::MigrateAttachmentDigests.recompute_attachment_digest(attachment)
      expect(attachment.reload.md5).
        to eq 'bfaaf6564b32aa18aaab9b3448d2a12a3e011e4897f0266b71fb12879786ecee10928cf9386a6b59924551bbf3bfd51b8ca50942bdb13f81e5dfadaaa80ca938'
    end

    it "preserves the contents unmodified" do
      file_contents = attachment.open.read
      DataFixup::MigrateAttachmentDigests.recompute_attachment_digest(attachment)
      expect(attachment.open.read).to eql(file_contents)
    end
  end
end
