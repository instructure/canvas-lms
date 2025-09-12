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

require "spec_helper"

describe Thumbnail do
  describe "#local_storage_path" do
    let(:attachment) { attachment_model(context:, root_account:) }
    let(:root_account) { Account.default }
    let(:context) { user_model }
    let(:thumbnail) do
      Thumbnail.create!(attachment:, content_type: "image/png", filename: "thumbnail.png", size: 12_345)
    end

    before { allow(HostUrl).to receive(:context_host).with(context).and_return("http://host") }

    context "when the file_association_access feature is enabled" do
      before { root_account.enable_feature!(:file_association_access) }

      it "returns the path without uuid" do
        expect(thumbnail.local_storage_path).to eq("http://host/images/thumbnails/show/#{thumbnail.id}")
      end

      it "returns the path without uuid and with location when location is passed" do
        url = thumbnail.local_storage_path(location: "avatar_1")
        expect(url).to eq("http://host/images/thumbnails/show/#{thumbnail.id}?location=avatar_1")
      end
    end

    it "returns the path with uuid when file_association_access feature is disabled" do
      root_account.disable_feature!(:file_association_access)
      expect(thumbnail.local_storage_path).to eq("http://host/images/thumbnails/show/#{thumbnail.id}/#{thumbnail.uuid}")
    end
  end
end
