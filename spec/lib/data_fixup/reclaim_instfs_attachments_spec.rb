# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe DataFixup::ReclaimInstfsAttachments do
  describe "reclaim_attachment" do
    let(:file_contents) { "file contents" }
    let(:instfs_uuid) { "uuid" }
    let(:instfs_body) { StringIO.new(file_contents) }
    let(:attachment) { attachment_model(instfs_uuid:) }

    before do
      # this method is only called during the `instfs_hosted?` branch of
      # attachment.open, so it'll be stubbed out when fetching the contents
      # from inst-fs, but note when checking the contents in s3 after reclaim
      allow(attachment).to receive(:create_tempfile).and_return(instfs_body)
    end

    it "produces a working attachment served by non-instfs storage" do
      DataFixup::ReclaimInstfsAttachments.reclaim_attachment(attachment)
      expect(attachment).not_to be_instfs_hosted
      expect(attachment.open.read).to be_present
    end

    it "preserves the contents unmodified" do
      DataFixup::ReclaimInstfsAttachments.reclaim_attachment(attachment)
      expect(attachment.open.read).to eql(file_contents)
    end
  end
end
