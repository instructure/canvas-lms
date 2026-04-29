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
  subject(:service) do
    lambda do
      VideoCaptionService.new(media_object).call
      run_jobs
    end
  end

  let(:media_object) { media_object_model }
  let(:kaltura_client) { instance_double(CanvasKaltura::ClientV3) }

  before do
    allow(kaltura_client).to receive_messages(
      # when_loaded: kaltura_client,
      startSession: nil,
      mediaGet: { status: "2" },
      create_caption_asset: { id: "c-123" },
      caption_asset: { status: "2", languageCode: "en" },
      caption_asset_contents: "Caption Body"
    )

    allow(CanvasKaltura::ClientV3).to receive_messages(new: kaltura_client)
    stub_const("VideoCaptionService::MAX_RETRY_ATTEMPTS", 1)
  end

  describe "#call" do
    context "when media type is nil" do
      it "handles the request gracefully and sets status to failed_initial_validation" do
        media_object.update!(media_type: nil)

        expect { service.call }.to change {
          media_object.reload.auto_caption_status
        }.from(nil).to("failed_initial_validation")
      end
    end

    context "when media type is video and media id is present" do
      it "creates a media track with captions" do
        expect { service.call }.to change { MediaTrack.count }.by(1)
      end

      it "does not create an additional media track on subsequent calls" do
        expect { service.call }.to change { MediaTrack.count }.by(1)
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to complete" do
        expect { service.call }.to change { media_object.reload.auto_caption_status }.from(nil).to("complete")
      end

      it "sets auto_caption_media_id" do
        expect { service.call }.to change { media_object.reload.auto_caption_media_id }.from(nil).to("1234")
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
        expect(media_object.reload.auto_caption_status).to eq("failed_initial_validation")
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

    context "when caption request fails" do
      before do
        allow(kaltura_client).to receive_messages(
          create_caption_asset: nil
        )
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_request" do
        expect { service.call }.to change { media_object.reload.auto_caption_status }.to("failed_request")
      end
    end

    context "when captions are not ready" do
      before do
        allow(kaltura_client).to receive_messages(
          caption_asset: { status: "0", languageCode: "" }
        )
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_captions" do
        expect { service.call }.to change { media_object.reload.auto_caption_status }.to("failed_captions")
      end
    end

    context "when captions cannot be pulled" do
      before do
        allow(kaltura_client).to receive_messages(
          caption_asset_contents: nil
        )
      end

      it "does not create a media track" do
        expect { service.call }.not_to change { MediaTrack.count }
      end

      it "sets auto_caption_status to failed_to_pull" do
        expect { service.call }.to change { media_object.reload.auto_caption_status }.to("failed_to_pull")
      end
    end
  end
end
