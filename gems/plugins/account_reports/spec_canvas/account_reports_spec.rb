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

describe AccountReports do
  describe ".report_attachments" do
    subject(:report_attachment) { described_class.report_attachment(account_report, data: "test data", filename: "test.csv") }

    let(:account) { account_model }
    let(:admin) { user_model }
    let(:account_report) { AccountReport.create!(account_id: account.id, user_id: admin.id) }

    before do
      allow(Canvas::UploadedFile).to receive(:new).and_return(double(Canvas::UploadedFile, size: 10))
      expect(Zip::File).to receive(:open)
      allow(InstFS).to receive(:enabled?).and_return(true)
      allow(InstFS).to receive(:direct_upload)
    end

    it "skips touching the account when saving the attachment" do
      expect { report_attachment }.not_to change { account.updated_at }
    end

    it "only skips callbacks on the Attachment class" do
      expect(Attachment).to receive(:skip_touch_context)

      report_attachment
    end

    it { is_expected.to be_a(Attachment) }
  end
end
