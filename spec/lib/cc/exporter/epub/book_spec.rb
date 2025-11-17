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

require_relative "../../cc_spec_helper"

describe CC::Exporter::Epub::Book do
  subject(:book) { described_class.new(exporter) }

  let(:source_file) { file_fixture("test_image.jpg") }
  let(:file_data) do
    {
      identifier: "gb64dec5c67842af5bf760141d0f08cc8",
      local_path: "media/test.jpeg",
      file_name: "test.jpeg",
      path_to_file: source_file.to_s,
      media_type: "image/jpeg",
      exists: true
    }
  end
  let(:templates) { { title: "Sample Export Title", files: [file_data] } }
  let(:filename_prefix) { "sample_export_#{SecureRandom.hex(6)}" }
  let(:exporter) { double("exporter", templates:, filename_prefix:) }

  describe "#add_files" do
    it "adds file items using keyword arguments" do
      book.add_files
      item = book.epub.items[file_data[:identifier]]
      expect(item).not_to be_nil
      expect(item.href).to eq("media/test.jpeg")
      expect(item.media_type).to eq("image/jpeg")
    end

    it "does not raise ArgumentError for add_item call" do
      expect { book.add_files }.not_to raise_error
    end
  end

  describe "#create" do
    let!(:generated_path) { book.create }

    after do
      FileUtils.rm_f(generated_path)
    end

    it "generates a valid epub file including the added item" do
      expect(File).to exist(generated_path)
      expect(File.size(generated_path)).to be_positive

      item = book.epub.items[file_data[:identifier]]
      expect(item).not_to be_nil
      expect(item.href).to eq("media/test.jpeg")
      expect(item.media_type).to eq("image/jpeg")

      entry_names = []
      Zip::File.open(generated_path) do |zip|
        zip.each { |e| entry_names << e.name }
      end
      expect(entry_names.any? { |n| n.end_with?("media/test.jpeg") }).to be true
    end
  end
end
