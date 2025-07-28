# frozen_string_literal: true

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

describe Schemas::Lti::AssetProcessor::UrlWithDimensions do
  describe "#validate" do
    subject { described_class.validation_errors(json) }

    context "with invalid configuration" do
      let(:json) { { url: 1234, width: "bad" } }

      it "returns errors" do
        expect(subject).not_to be_empty
      end
    end

    context "with valid configuration" do
      let(:json) { { url: "https://example.com/icon.png", width: 20 } }

      it "returns no errors" do
        expect(subject).to be_empty
      end
    end
  end
end
