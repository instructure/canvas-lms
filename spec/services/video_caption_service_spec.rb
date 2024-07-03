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

RSpec.describe VideoCaptionService, type: :service do
  let(:media_object) { media_object_model }
  let(:service) { VideoCaptionService.new(media_object, skip_polling: true) }

  describe "#call" do
    context "when media type is video and media id is present" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: { "media" => { "id" => "1234" } },
          request_caption: double("Response", code: 200),
          media: { "media" => { "captions" => [{ "language" => "en", "status" => "succeeded" }] } },
          grab_captions: "Captions for the video",
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
      end

      it "creates a media track with captions" do
        expect { service.call }.to change { MediaTrack.count }.by(1)
      end

      it "does not create an additional media track on subsequent calls" do
        expect { service.call }.to change { MediaTrack.count }.by(1)
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to complete" do
        service.call
        expect(media_object.auto_caption_status).to eq("complete")
      end
    end

    context "when media type is not video" do
      before do
        allow(media_object).to receive(:media_type).and_return("image/jpeg")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_initial_validation" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_initial_validation")
      end
    end

    context "when media id is not present" do
      before do
        allow(media_object).to receive(:media_id).and_return(nil)
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_initial_validation" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_initial_validation")
      end
    end

    context "when URL is not available" do
      before do
        allow(service).to receive(:url).and_return(nil)
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_initial_validation" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_initial_validation")
      end
    end

    context "when handoff request fails" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: nil,
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
        allow(media_object).to receive_messages(media_type: "video", media_id: "valid_media_id")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_handoff" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_handoff")
      end
    end

    context "when caption request fails" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: { "media" => { "id" => "1234" } },
          request_caption: double("Response", code: 500),
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
        allow(media_object).to receive_messages(media_type: "video", media_id: "valid_media_id")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_request" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_request")
      end
    end

    context "when captions are not ready" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: { "media" => { "id" => "1234" } },
          request_caption: double("Response", code: 200),
          media: { "media" => { "captions" => [{ "status" => "in_progress" }] } },
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
        allow(media_object).to receive_messages(media_type: "video", media_id: "valid_media_id")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_captions" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_captions")
      end
    end

    context "when non-English language is detected" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: { "media" => { "id" => "1234" } },
          request_caption: double("Response", code: 200),
          media: { "media" => { "captions" => [{ "language" => "es", "status" => "succeeded" }] } },
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
        allow(media_object).to receive_messages(media_type: "video", media_id: "valid_media_id")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to non_english_captions" do
        service.call
        expect(media_object.auto_caption_status).to eq("non_english_captions")
      end
    end

    context "when captions cannot be pulled" do
      before do
        allow(service).to receive_messages(
          url: "https://example.com/video.mp4",
          request_handoff: { "media" => { "id" => "1234" } },
          request_caption: double("Response", code: 200),
          media: { "media" => { "captions" => [{ "language" => "en", "status" => "succeeded" }] } },
          grab_captions: nil,
          config: { "app-host" => "https://example.com" },
          auth_token: "token"
        )
        allow(media_object).to receive_messages(media_type: "video", media_id: "valid_media_id")
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_to_pull" do
        service.call
        expect(media_object.auto_caption_status).to eq("failed_to_pull")
      end
    end
  end
end
