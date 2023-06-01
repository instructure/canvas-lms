# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe UserContent::FilesHandler do
  let(:is_public) { false }
  let(:in_app) { false }
  let(:course) { course_factory(active_all: true) }
  let(:attachment) do
    attachment_with_context(course, { filename: "test.mp4", content_type: "video" })
  end
  let(:match_url) do
    [attachment.context_type.tableize, attachment.context_id, "files", attachment.id, match_part].join("/")
  end
  let(:match_part) { "download?wrap=1" }
  let(:uri_match) do
    UserContent::FilesHandler::UriMatch.new(
      OpenStruct.new(
        {
          url: match_url,
          type: "files",
          obj_class: Attachment,
          obj_id: attachment.id,
          rest: "/#{match_part}"
        }
      )
    )
  end

  describe UserContent::FilesHandler::ProcessedUrl do
    subject(:processed_url) do
      UserContent::FilesHandler::ProcessedUrl.new(
        match: uri_match, attachment:, is_public:, in_app:
      ).url
    end

    describe "#url" do
      it "includes context class" do
        expect(processed_url).to match(/#{attachment.context_type.tableize}/)
      end

      it "includes wrap=1" do
        query_string = processed_url.split("?")[1]
        expect(Rack::Utils.parse_nested_query(query_string)["wrap"]).to eq "1"
      end

      it "includes verifier query param" do
        query_string = processed_url.split("?")[1]
        expect(Rack::Utils.parse_nested_query(query_string)).to have_key("verifier")
      end

      context "is in_app" do
        let(:in_app) { true }

        it "does not include verifier" do
          query_string = processed_url.split("?")[1]
          expect(Rack::Utils.parse_nested_query(query_string)).not_to have_key("verifier")
        end
      end

      context "and match is a preview" do
        let(:match_part) { "preview" }

        it "is a preview url" do
          expect(processed_url).to match(%r{files/(\d)+/preview})
        end

        it "does not include wrap param" do
          query_string = processed_url.split("?")[1]
          expect(Rack::Utils.parse_nested_query(query_string)).not_to have_key("wrap")
        end
      end

      context "when download_frd=1" do
        let(:match_part) { "?download_frd=1" }

        it "includes /download in the url" do
          expect(processed_url).to match(%r{files/(\d)+/download})
        end
      end

      context "when no download_frd" do
        let(:match_part) { "?wrap=1" }

        it "omits /download in the url" do
          expect(processed_url).to match(%r{files/(\d)+(\?|$)})
        end
      end

      context "when attachment does not support relative paths" do
        let(:attachment) { attachment_with_context(submission_model) }

        it "does not include context name" do
          expect(processed_url).not_to match(/#{attachment.context_type.tableize}/)
        end
      end
    end
  end

  describe UserContent::FilesHandler do
    subject(:processed_url) do
      UserContent::FilesHandler.new(
        match: uri_match,
        context: attachment.context,
        user: current_user,
        preloaded_attachments:,
        is_public:,
        in_app:
      ).processed_url
    end

    let(:current_user) do
      student_in_course(active_all: true, course: attachment.context)
      @student
    end
    let(:preloaded_attachments) { {} }

    describe "#processed_url" do
      it "delegates to ProcessedUrl" do
        expect(processed_url).to match(/#{attachment.context_type.tableize}/)
      end

      context "user does not have download rights" do
        let(:current_user) { user_factory }

        it "returns match_url with preview=1" do
          expect(processed_url).to eq "/#{match_url}&no_preview=1"
        end

        context "but attachment is public" do
          let(:is_public) { true }

          it "delegates to ProcessedUrl" do
            expect(processed_url).to match(/#{attachment.context_type.tableize}/)
          end

          context "and file is locked" do
            let(:attachment) do
              attachment_with_context(course, { filename: "test.jpg", content_type: "image/jpeg" })
            end

            it "returns match_url with hidden=1" do
              attachment.locked = true
              attachment.save
              expect(processed_url).to eq "/#{match_url}&hidden=1"
            end

            it "returns match_url with hidden=1 if within a locked time window" do
              attachment.unlock_at = 1.hour.from_now
              attachment.save
              expect(processed_url).to eq "/#{match_url}&hidden=1"
            end
          end
        end
      end

      context "preloaded attachments" do
        it "attachment url will be returned" do
          current_user = user_factory
          preloaded_attachments = {}
          preloaded_attachments[attachment.id] = attachment

          processed_url = UserContent::FilesHandler.new(
            match: uri_match,
            context: course,
            user: current_user,
            preloaded_attachments:,
            is_public:,
            in_app:
          ).processed_url

          expect(processed_url).to include "/courses/#{course.id}/files/#{attachment.id}/"
        end

        it "when replaced the replacement attachment url will be returned" do
          current_user = user_factory
          replacement_attachment = attachment_with_context(course, { filename: "hello" })
          attachment.update!(replacement_attachment_id: replacement_attachment.id, file_state: "deleted", deleted_at: DateTime.now)
          preloaded_attachments = {}
          preloaded_attachments[attachment.id] = attachment

          processed_url = UserContent::FilesHandler.new(
            match: uri_match,
            context: course,
            user: current_user,
            preloaded_attachments:,
            is_public:,
            in_app:
          ).processed_url

          expect(processed_url).to include "/courses/#{course.id}/files/#{replacement_attachment.id}/"
        end
      end
    end

    context "user cannot access attachment" do
      let(:subject) do
        UserContent::FilesHandler.new(
          match: uri_match,
          context: attachment.context,
          user: current_user,
          preloaded_attachments:,
          is_public:,
          in_app:
        )
      end

      before { allow(subject).to receive(:user_can_access_attachment?).and_return false }

      context "url contains invalid uri" do
        # single quotes will make it valid uri, so keep this in double quotes
        let(:match_part) { "download?foo=505720\u00A0" }

        it "handles escape characters" do
          expect(subject.processed_url).to match(/#{attachment.context_type.tableize}/)
        end
      end
    end
  end
end
