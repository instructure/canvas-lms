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

require "pdf/reader"
require "docx"
require "zip"

class FileTextExtractionService
  Result = Struct.new(:text, :contains_images)

  def initialize(attachment:)
    @attachment = attachment
  end

  def call
    memory_limit = Setting.get("attachment_calculate_words_memory_limit", 4.gigabytes.to_s).to_i
    time_limit = Setting.get("attachment_calculate_words_time_limit", 3.minutes.to_s).to_f

    MemoryLimit.apply(memory_limit) do
      Timeout.timeout(time_limit) do
        case mimetype
        when "pdf"
          extract_pdf
        when "docx"
          extract_docx
        else
          Rails.logger.warn("[LocalTextExtractor] Unsupported MIME type: #{attachment.mime_type}")
          Result.new("", false)
        end
      end
    end
  rescue => e
    Rails.logger.error("[LocalTextExtractor] Failed for attachment #{attachment.id}: #{e.message}")
    Result.new("", false)
  end

  private

  attr_reader :attachment

  def mimetype
    return "pdf" if attachment.mimetype == "application/pdf"

    "docx" if %w[
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/x-docx
    ].include?(attachment.mimetype)
  end

  def extract_pdf
    reader = PDF::Reader.new(attachment.open)
    text = reader.pages.map(&:text).join("\n")
    has_images = reader.pages.any? do |page|
      page.xobjects&.any? { |_, stream| stream.hash[:Subtype] == :Image }
    end

    Result.new(text, has_images)
  end

  def extract_docx
    doc = Docx::Document.open(attachment.open)
    text = doc.text

    has_images = false
    Zip::File.open(attachment.full_filename) do |zip|
      has_images = zip.glob("word/media/*").any?
    end

    Result.new(text, has_images)
  end
end
