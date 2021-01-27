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
#

require "spec_helper"

describe Api::V1::Attachment do
  include Api::V1::Attachment
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: 'example.com' }
  end

  describe "#attachment_json" do
    let(:course) { Course.create! }
    let(:attachment) { attachment_model(content_type: "application/pdf", context: student) }
    let(:student) { course_with_user("StudentEnrollment", course: course, active_all: true).user }
    let(:teacher) { course_with_user("TeacherEnrollment", course: course, active_all: true).user }

    before(:each) do
      allow(Canvadocs).to receive(:enabled?).and_return(true)
      Canvadoc.create!(document_id: "abc123#{attachment.id}", attachment_id: attachment.id)
    end

    it "includes the submission id in the url_opts when preview_url is included" do
      params = {
        include: ["preview_url"],
        submission_id: 2345
      }
      json = attachment_json(attachment, teacher, {}, params)
      expect(json.fetch("preview_url")).to include("%22submission_id%22:2345")
    end

    it "should link an svg's thumbnail to itself" do
      a =
        attachment_model(
          uploaded_data: stub_file_data('file.svg', '<svg></svg>', 'image/svg+xml'),
          content_type: 'image/svg+xml'
        )
      json = attachment_json(a, teacher, {}, {})
      expect(json.fetch('thumbnail_url')).to eq json.fetch('url')
    end
  end

  describe '#infer_upload_filename' do
    it { expect(infer_upload_filename(nil)).to be_nil }

    it { expect(infer_upload_filename({})).to be_nil }

    it 'return the name when it is given' do
      params = { name: 'filename', filename: 'filename.jpg' }

      expect(infer_upload_filename(params)).to eq 'filename'
    end

    it 'return the filename when it is given' do
      params = { filename: 'filename.png' }

      expect(infer_upload_filename(params)).to eq 'filename.png'
    end

    it 'return the filename inferred from the url when it is given' do
      params = { url: 'http://www.example.com/foo/bar/filename.jpg' }

      expect(infer_upload_filename(params)).to eq 'filename.jpg'
    end
  end

  describe '#infer_filename_from_url' do
    it { expect(infer_filename_from_url(nil)).to be_nil }

    it { expect(infer_filename_from_url('')).to be_empty }

    it 'return the filename with extension when it is given' do
      url = 'http://www.example.com/foo/bar/filename.jpeg?foo=bar&timestamp=123'

      expect(infer_filename_from_url(url)).to eq 'filename.jpeg'
    end

    it 'return the last path when the URL does not have the filename in the path' do
      url = 'http://www.example.com/foo'

      expect(infer_filename_from_url(url)).to eq 'foo'

      url = 'https://docs.google.com/spreadsheets/d/xpto/edit#gid=0'

      expect(infer_filename_from_url(url)).to eq 'edit'

      url = 'http://example.com/sites/download.xpto'

      expect(infer_filename_from_url(url)).to eq 'download.xpto'

      url = 'https://via.placeholder.com/150?text=thumbnail'

      expect(infer_filename_from_url(url)).to eq '150'
    end

    it 'return empty when URL only have the domain' do
      url = 'http://www.example.com'

      expect(infer_filename_from_url(url)).to be_empty
    end
  end
end
