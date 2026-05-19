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
  let(:no_verifiers) { false }
  let(:course) { course_factory(active_all: true) }
  let(:attachment) do
    attachment_with_context(course, { filename: "test.mp4", content_type: "video" })
  end
  let(:match_url) do
    [attachment.context_type.tableize, attachment.context_id, "files", attachment.id, match_part].join("/").prepend("/")
  end
  let(:match_part) { "download?wrap=1" }
  let(:uri_match) do
    UserContent::HtmlRewriter::UriMatch.new(
      match_url,
      "files",
      Attachment,
      attachment.id,
      "/#{match_part}"
    )
  end

  describe UserContent::FilesHandler do
    subject(:processed_url) do
      UserContent::FilesHandler.new(
        match: uri_match,
        context: attachment.context,
        user: current_user,
        preloaded_attachments:,
        is_public:,
        in_app:,
        no_verifiers:
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
          expect(processed_url).to eq "/courses/#{course.id}/files/#{attachment.id}/download?no_preview=1&wrap=1"
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
              expect(processed_url).to eq "/courses/#{course.id}/files/#{attachment.id}/download?hidden=1&wrap=1"
            end

            it "returns match_url with hidden=1 if within a locked time window" do
              attachment.unlock_at = 1.hour.from_now
              attachment.save
              expect(processed_url).to eq "/courses/#{course.id}/files/#{attachment.id}/download?hidden=1&wrap=1"
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
          attachment.update!(replacement_attachment_id: replacement_attachment.id, file_state: "deleted", deleted_at: Time.zone.now)
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

      context "with location parameter" do
        let(:location) { "wiki_page_123" }

        it "does not error if the attachment doesn't have a valid context" do
          attachment.update!(context_id: 0)

          processed_url = UserContent::FilesHandler.new(
            match: uri_match,
            context: course,
            user: current_user,
            preloaded_attachments: {},
            is_public:,
            in_app:,
            location:
          ).processed_url

          expect(processed_url).to include "/courses/0/files/#{attachment.id}/"
        end

        it "follows replacement chain when attachment is replaced" do
          replacement_attachment = attachment_with_context(course, { filename: "replacement.mp4", content_type: "video" })
          attachment.update!(replacement_attachment_id: replacement_attachment.id, file_state: "deleted", deleted_at: Time.zone.now)

          handler = UserContent::FilesHandler.new(
            match: uri_match,
            context: course,
            user: current_user,
            preloaded_attachments: {},
            is_public:,
            in_app:,
            location:
          )

          expect(handler.processed_url).to include "/courses/#{course.id}/files/#{replacement_attachment.id}/"
          result_attachment = handler.send(:attachment)
          expect(result_attachment).to eq replacement_attachment
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
