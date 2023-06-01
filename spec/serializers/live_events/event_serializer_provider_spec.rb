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

RSpec.describe LiveEvents::EventSerializerProvider do
  describe "#serialize" do
    subject { LiveEvents::EventSerializerProvider.serialize(asset) }

    let(:course) { course_model }

    context "when asset is a ContextExternalTool" do
      let(:opts) { { domain: "test.com" } }
      let(:asset) { external_tool_model(context: course, opts:) }

      it "serializes the asset" do
        expect(subject).to include(
          domain: asset.domain,
          asset_name: asset.name,
          url: asset.url
        )
      end
    end

    context "when asset is an Attachment" do
      let(:asset) { attachment_model }

      it "serializes the asset" do
        expect(subject).to include(
          filename: asset.filename,
          display_name: asset.display_name
        )
      end
    end

    context "when asset class does not have a serializer" do
      let(:asset) { "'String' has no serializer" }

      it { is_expected.to eq({}) }
    end
  end
end
