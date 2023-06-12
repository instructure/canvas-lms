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
    { host: "example.com" }
  end

  describe "#attachment_json" do
    let(:course) { Course.create! }
    let(:attachment) { attachment_model(content_type: "application/pdf", context: student) }
    let(:student) { course_with_user("StudentEnrollment", course:, active_all: true).user }
    let(:teacher) { course_with_user("TeacherEnrollment", course:, active_all: true).user }

    before do
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

    it "links an svg's thumbnail to itself" do
      a =
        attachment_model(
          uploaded_data: stub_file_data("file.svg", "<svg></svg>", "image/svg+xml"),
          content_type: "image/svg+xml"
        )
      json = attachment_json(a, teacher, {}, {})
      expect(json.fetch("thumbnail_url")).to eq json.fetch("url")
    end
  end

  describe "#infer_upload_filename" do
    it { expect(infer_upload_filename(nil)).to be_nil }

    it { expect(infer_upload_filename({})).to be_nil }

    it "return the name when it is given" do
      params = ActionController::Parameters.new(
        name: "filename",
        filename: "filename.jpg"
      )

      expect(infer_upload_filename(params)).to eq "filename"
    end

    it "return the filename when it is given" do
      params = ActionController::Parameters.new(filename: "filename.png")

      expect(infer_upload_filename(params)).to eq "filename.png"
    end

    it "return the filename inferred from the url when it is given" do
      params = ActionController::Parameters.new(url: "http://www.example.com/foo/bar/filename.jpg")

      expect(infer_upload_filename(params)).to eq "filename.jpg"
    end
  end

  describe "#infer_filename_from_url" do
    it { expect(infer_filename_from_url(nil)).to be_nil }

    it { expect(infer_filename_from_url("")).to be_empty }

    it "return the filename with extension when it is given" do
      url = "http://www.example.com/foo/bar/filename.jpeg?foo=bar&timestamp=123"

      expect(infer_filename_from_url(url)).to eq "filename.jpeg"
    end

    it "return the last path when the URL does not have the filename in the path" do
      url = "http://www.example.com/foo"

      expect(infer_filename_from_url(url)).to eq "foo"

      url = "https://docs.google.com/spreadsheets/d/xpto/edit#gid=0"

      expect(infer_filename_from_url(url)).to eq "edit"

      url = "http://example.com/sites/download.xpto"

      expect(infer_filename_from_url(url)).to eq "download.xpto"

      url = "https://via.placeholder.com/150?text=thumbnail"

      expect(infer_filename_from_url(url)).to eq "150"
    end

    it "return empty when URL only have the domain" do
      url = "http://www.example.com"

      expect(infer_filename_from_url(url)).to be_empty
    end
  end

  describe "#infer_file_extension" do
    it "return the extension from name attribute when it is given" do
      params = ActionController::Parameters.new(name: "name.jpg")

      expect(infer_file_extension(params)).to eq "jpg"
    end

    context "when there is more than one extesion for the same mime type" do
      it "return `dat` extension from name parameter" do
        params = ActionController::Parameters.new(
          name: "name.dat",
          content_type: "text/plain"
        )

        expect(infer_file_extension(params)).to eq "dat"
      end

      it "return `html` extension from filename parameter" do
        params = ActionController::Parameters.new(
          filename: "name.html",
          content_type: "text/html"
        )

        expect(infer_file_extension(params)).to eq "html"
      end
    end

    it "return the extension from content_type attribute when it is given" do
      params = ActionController::Parameters.new(content_type: "application/x-zip-compressed")

      expect(infer_file_extension(params)).to eq "zip"
    end

    it "return the extension from url attribute even it is an unknown type" do
      params = ActionController::Parameters.new(
        name: "name",
        url: "https://dummyimage.com/300/09f/image.xpto"
      )

      expect(infer_file_extension(params)).to eq "xpto"
    end

    it "return the extension from filename attribute when it is given" do
      params = ActionController::Parameters.new(name: "name", filename: "filename.png")

      expect(infer_file_extension(params)).to eq "png"
    end

    it "return the extension from url attribute when it is given" do
      params = ActionController::Parameters.new(
        name: "name",
        filename: "filename",
        url: "http://www.example.com/foo/bar/filename.gif"
      )

      expect(infer_file_extension(params)).to eq "gif"
    end

    it "return `nil` when can not infer the extension" do
      params = ActionController::Parameters.new(
        name: "invalid",
        filename: "invalid",
        url: "invalid",
        content_type: "invalid"
      )

      expect(infer_file_extension(params)).to be_nil
    end
  end

  describe "#infer_upload_content_type" do
    it "return the content_type from content_type attribute when it is given" do
      params = ActionController::Parameters.new(content_type: "image/png")

      expect(infer_upload_content_type(params)).to eq "image/png"
    end

    it "return the content_type from name attribute when it is given" do
      params = ActionController::Parameters.new(name: "name.jpeg")

      expect(infer_upload_content_type(params)).to eq "image/jpeg"
    end

    it "return the content_type from filename attribute when it is given" do
      params = ActionController::Parameters.new(name: "name", filename: "filename.png")

      expect(infer_upload_content_type(params)).to eq "image/png"
    end

    it "return the content_type from url attribute when it is given" do
      params = ActionController::Parameters.new(
        name: "name",
        filename: "filename",
        url: "http://www.example.com/foo/bar/filename.pdf"
      )

      expect(infer_upload_content_type(params)).to eq "application/pdf"
    end

    it "return `nil` when can not infer the extension" do
      params = ActionController::Parameters.new

      expect(infer_upload_content_type(params)).to be_nil
    end

    it "return `unknown/unknown` when can not infer the extension and a default mime type is given" do
      params = ActionController::Parameters.new
      default_mimetype = "unknown/unknown"

      expect(infer_upload_content_type(params, default_mimetype)).to eq default_mimetype
    end
  end

  describe "#valid_mime_type?" do
    it { expect(valid_mime_type?(nil)).to be false }

    it { expect(valid_mime_type?("")).to be false }

    it { expect(valid_mime_type?("unknown/unknown")).to be false }

    it { expect(valid_mime_type?("application/pdf")).to be true }
  end

  describe "#api_attachment_preflight" do
    let_once(:context) { course_model }
    let(:request) { OpenStruct.new({ params: ActionController::Parameters.new(params) }) }
    let(:params) { { name: "name", filename: "filename.png" } }
    let(:opts) { {} }

    def logged_in_user; end

    def render(*); end

    context "with the category param set" do
      subject { Attachment.find_by(display_name: params[:name]) }

      before { api_attachment_preflight(context, request, opts) }

      let(:params) do
        super().merge(category: Attachment::ICON_MAKER_ICONS)
      end

      it "sets the category on the attachment" do
        expect(subject.category).to eq params[:category]
      end
    end

    context "with InstFS enabled" do
      let(:params) do
        super().merge(category: Attachment::ICON_MAKER_ICONS)
      end

      before do
        allow(InstFS).to receive(:enabled?).and_return(true)
      end

      it "sends the precreated_attachment_id as a string" do
        student = course_with_user("StudentEnrollment", course: context, active_all: true).user
        user_session(student)
        additional_opts = {
          precreate_attachment: true
        }
        expect(InstFS).to receive(:upload_preflight_json)
          .with hash_including(
            {
              additional_capture_params: include(
                {
                  precreated_attachment_id: String
                }
              )
            }
          )

        api_attachment_preflight(context, request, opts.merge(additional_opts))
      end

      context "with the category param set" do
        subject { Attachment.find_by(display_name: params[:name]) }

        it "sets the category on the attachment" do
          expect(InstFS).to receive(:upload_preflight_json).with(
            hash_including(
              additional_capture_params: { category: "icon_maker_icons" }
            )
          )
          api_attachment_preflight(context, request, opts)
        end
      end
    end
  end
end
