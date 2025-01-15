# frozen_string_literal: true

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

RSpec.describe CC::Importer::Canvas::Converter do
  let(:unzipped_file_path) { "path" }
  let(:mock_package_root) { instance_double(PackageRoot) }

  before do
    allow(PackageRoot).to receive(:new).with(unzipped_file_path).and_return(mock_package_root)
  end

  describe "#initialize" do
    context "when discussion_checkpoints ff setting is enabled" do
      subject { described_class.new(settings) }

      let(:settings) { { is_discussion_checkpoints_enabled: true, unzipped_file_path: } }

      it "sets @is_discussion_checkpoints_enabled to true" do
        expect(subject.instance_variable_get(:@is_discussion_checkpoints_enabled)).to be true
      end
    end

    context "when discussion_checkpoints ff setting is disabled" do
      subject { described_class.new(settings) }

      let(:settings) { { is_discussion_checkpoints_enabled: false, unzipped_file_path: } }

      it "sets @is_discussion_checkpoints_enabled to true" do
        expect(subject.instance_variable_get(:@is_discussion_checkpoints_enabled)).to be false
      end
    end

    context "when discussion_checkpoints ff setting is missing" do
      subject { described_class.new(settings) }

      let(:settings) { { unzipped_file_path: } }

      it "sets @is_discussion_checkpoints_enabled to true" do
        expect(subject.instance_variable_get(:@is_discussion_checkpoints_enabled)).to be false
      end
    end
  end
end
