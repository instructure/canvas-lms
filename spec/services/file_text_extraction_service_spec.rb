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

require "spec_helper"
require_relative "../../app/services/file_text_extraction_service"

RSpec.describe FileTextExtractionService do
  let(:attachment) do
    instance_double(
      Attachment,
      id: 42,
      mimetype:,
      open: StringIO.new("dummy-io")
    )
  end

  before do
    allow(Setting).to receive(:get)
      .with("attachment_calculate_words_memory_limit", anything)
      .and_return(4.gigabytes.to_s)
    allow(Setting).to receive(:get)
      .with("attachment_calculate_words_time_limit", anything)
      .and_return(3.minutes.to_s)

    allow(MemoryLimit).to receive(:apply).and_yield
    allow(Timeout).to receive(:timeout).and_yield
  end

  describe "#call" do
    context "when attachment is a PDF" do
      let(:mimetype) { "application/pdf" }

      it "extracts text and detects images" do
        page1 = instance_double(
          PDF::Reader::Page,
          text: "Hello\x07World",
          xobjects: { "Im1" => instance_double(PDF::Reader::Stream, hash: { Subtype: :Image }) }
        )
        page2 = instance_double(
          PDF::Reader::Page,
          text: "Second page",
          xobjects: nil
        )
        reader = instance_double(PDF::Reader, pages: [page1, page2])

        expect(PDF::Reader).to receive(:new).with(instance_of(StringIO)).and_return(reader)

        result = described_class.new(attachment:).call

        expect(result).to be_a(FileTextExtractionService::Result)
        expect(result.text).to eq("HelloWorld\nSecond page")
        expect(result.contains_images).to be true
      end

      it "extracts text and reports no images when none present" do
        page = instance_double(PDF::Reader::Page, text: "Only text", xobjects: {})
        reader = instance_double(PDF::Reader, pages: [page])

        expect(PDF::Reader).to receive(:new).and_return(reader)

        result = described_class.new(attachment:).call

        expect(result.text).to eq("Only text")
        expect(result.contains_images).to be false
      end

      it "logs and returns empty result when the reader raises" do
        expect(PDF::Reader).to receive(:new).and_raise(StandardError, "boom")
        expect(Rails.logger).to receive(:error)
          .with(/\[LocalTextExtractor\] Failed for attachment 42: boom/)

        result = described_class.new(attachment:).call

        expect(result.text).to eq("")
        expect(result.contains_images).to be false
      end
    end

    context "when attachment is a DOCX" do
      let(:mimetype) { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }

      it "extracts text and detects images via zip glob" do
        doc = instance_double(Docx::Document, text: "Docx\x0CText")
        expect(Docx::Document).to receive(:open).with(instance_of(StringIO)).and_return(doc)

        zip_double = instance_double(Zip::File)
        expect(Zip::File).to receive(:open).with(instance_of(StringIO)).and_yield(zip_double)
        expect(zip_double).to receive(:glob).with("word/media/*").and_return(%w[word/media/image1.png])

        result = described_class.new(attachment:).call

        expect(result.text).to eq("DocxText")
        expect(result.contains_images).to be true
      end

      it "extracts text and reports no images when media folder is empty" do
        doc = instance_double(Docx::Document, text: "Plain text")
        expect(Docx::Document).to receive(:open).and_return(doc)

        zip_double = instance_double(Zip::File)
        expect(Zip::File).to receive(:open).and_yield(zip_double)
        expect(zip_double).to receive(:glob).with("word/media/*").and_return([])

        result = described_class.new(attachment:).call

        expect(result.text).to eq("Plain text")
        expect(result.contains_images).to be false
      end
    end

    context "when mimetype is unsupported" do
      let(:mimetype) { "text/plain" }
      let(:mime_type_for_log) { "text/plain" }

      it "warns and returns empty result" do
        expect(Rails.logger).to receive(:warn)
          .with("[LocalTextExtractor] Unsupported MIME type: text/plain")

        result = described_class.new(attachment:).call

        expect(result.text).to eq("")
        expect(result.contains_images).to be false
      end
    end

    context "sanitize guard clause" do
      let(:mimetype) { "application/pdf" }

      it "returns blank string as-is when text is empty" do
        page = instance_double(PDF::Reader::Page, text: "", xobjects: nil)
        reader = instance_double(PDF::Reader, pages: [page])

        expect(PDF::Reader).to receive(:new).and_return(reader)

        result = described_class.new(attachment:).call

        expect(result.text).to eq("")
        expect(result.contains_images).to be false
      end
    end
  end
end
