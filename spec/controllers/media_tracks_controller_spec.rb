# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe MediaTracksController do
  before :once do
    course_with_teacher(active_all: true)
    @mo = MediaObject.create!(media_id: "0_abcdefgh", old_media_id: "1_01234567", context: @course)
  end

  before do
    user_session(@teacher)
  end

  let :example_ttml_susceptible_to_xss do
    %{
      <tt xml>
        <img
          src="x"
          onerror="alert(document.domain);
          alert('Cookie must be empty: ' + document.cookie);"
        />
    }
  end

  context "media_objects" do
    describe "#create" do
      before do
        allow(CanvasKaltura::ClientV3).to receive(:config).and_return({})
      end

      it "creates a track" do
        expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
        content = "one track mind"
        post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: "en", content: }
        expect(response).to be_successful
        expect(json_parse(response.body)["media_id"]).to eq @mo.media_id
        track = @mo.media_tracks.last
        expect(track.content).to eq content
      end

      it "disallows TTML" do
        post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: "en", content: example_ttml_susceptible_to_xss }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "validates :kind" do
        post "create", params: { media_object_id: @mo.media_id, kind: "unkind", locale: "en", content: "1" }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "validates :locale" do
        post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: '<img src="lolcats.gif">', content: "1" }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "respects the exclude[] option" do
        expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
        content = "one track mind"
        post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: "en", content:, exclude: ["tracks"] }
        expect(response).to be_successful
        rbody = json_parse(response.body)
        expect(rbody["media_id"]).to eq @mo.media_id
        expect(rbody["media_tracks"]).to be_nil
      end
    end

    describe "#create_asr" do
      let(:kaltura_client) { instance_double(CanvasKaltura::ClientV3) }
      let(:caption_asset_response) { { id: "caption_asset_123", languageCode: "en", status: "2" } }

      before do
        allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kaltura_client)
        allow(kaltura_client).to receive_messages(
          startSession: nil,
          create_caption_asset: caption_asset_response,
          caption_asset_contents: "1\n00:00:01,000 --> 00:00:02,000\nHello"
        )
      end

      context "feature flag" do
        it "returns 404 when feature flag is disabled" do
          @course.root_account.disable_feature!(:rce_asr_captioning_improvements)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to have_http_status(:not_found)
        end

        it "proceeds when feature flag is enabled" do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to be_successful
        end
      end

      context "authorization" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "requires proper permissions" do
          student_in_course(active_all: true)
          user_session(@student)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to be_unauthorized
        end

        it "allows authorized users to create ASR captions" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to be_successful
        end
      end

      context "locale validation" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "accepts valid locales" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil).exactly(3).times
          %w[en es fr-CA].each do |locale|
            post "create_asr", params: { media_object_id: @mo.media_id, locale: }
            expect(response).to be_successful
          end
        end

        it "rejects empty locale" do
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "" }
          expect(response).to have_http_status(:bad_request)
          expect(json_parse(response.body)["error"]).to include("Invalid or missing locale")
        end

        it "rejects locale with special characters" do
          post "create_asr", params: { media_object_id: @mo.media_id, locale: '<img src="x">' }
          expect(response).to have_http_status(:bad_request)
          expect(json_parse(response.body)["error"]).to include("Invalid or missing locale")
        end

        it "rejects missing locale parameter" do
          post "create_asr", params: { media_object_id: @mo.media_id }
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "Kaltura integration" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "successfully creates caption asset" do
          expect(kaltura_client).to receive(:startSession).with(CanvasKaltura::SessionType::ADMIN)
          expect(kaltura_client).to receive(:create_caption_asset).with(@mo.media_id, "en")
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)

          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to be_successful
        end

        it "handles Kaltura API failures gracefully" do
          allow(kaltura_client).to receive(:create_caption_asset).and_return(nil)

          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(json_parse(response.body)["error"]).to include("Failed to create caption asset")
        end

        it "does not create a new Kaltura asset when a processing track already exists" do
          existing_track = @mo.media_tracks.create!(
            kind: "subtitles",
            locale: "en",
            content: "",
            external_id: "existing_asset_id",
            workflow_state: "processing",
            user: @teacher
          )
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)

          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          expect(kaltura_client).not_to have_received(:create_caption_asset)
          expect(response).to be_successful
          expect(existing_track.reload.external_id).to eq("existing_asset_id")
        end
      end

      context "MediaTrack creation" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "creates track with correct external_id" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          track = @mo.media_tracks.last
          expect(track.external_id).to eq("caption_asset_123")
        end

        it "sets workflow_state to ready when caption asset is ready and SRT is available" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          track = @mo.media_tracks.last
          expect(track.workflow_state).to eq("ready")
          expect(track.content).to eq("1\n00:00:01,000 --> 00:00:02,000\nHello")
        end

        it "sets workflow_state to processing when caption asset is not yet ready" do
          allow(kaltura_client).to receive(:create_caption_asset)
            .and_return({ id: "caption_asset_123", languageCode: "en", status: "1" })
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          track = @mo.media_tracks.last
          expect(track.workflow_state).to eq("processing")
          expect(track.content).to eq("")
        end

        it "sets kind to subtitles" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          track = @mo.media_tracks.last
          expect(track.kind).to eq("subtitles")
        end

        it "associates with correct user" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          track = @mo.media_tracks.last
          expect(track.user_id).to eq(@teacher.id)
        end

        it "associates with correct locale" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "es" }

          track = @mo.media_tracks.last
          expect(track.locale).to eq("es")
        end
      end

      context "response format" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "returns media_object_api_json for media_object context" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en" }

          expect(response).to be_successful
          response_body = json_parse(response.body)
          expect(response_body["media_id"]).to eq(@mo.media_id)
          expect(response_body["media_tracks"]).to be_present
        end

        it "respects the exclude[] option" do
          expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
          post "create_asr", params: { media_object_id: @mo.media_id, locale: "en", exclude: ["tracks"] }

          expect(response).to be_successful
          response_body = json_parse(response.body)
          expect(response_body["media_id"]).to eq(@mo.media_id)
          expect(response_body["media_tracks"]).to be_nil
        end
      end
    end

    describe "#show" do
      it "shows a track that belongs to the default attachment" do
        track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs 2", media_object: @mo)
        get "show", params: { media_object_id: @mo.media_id, id: track.id }
        expect(response).to be_successful
        expect(response.body).to eq "WEBVTT\n\nsubs"
        expect(@mo.media_tracks.count).to be(1)
        expect(@mo.media_tracks.first.content).to eq "subs"
      end

      it "doesn't show a track that belongs to the non-default attachment" do
        @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs 2", media_object: @mo)
        get "show", params: { media_object_id: @mo.media_id, id: track.id }
        expect(response).to have_http_status(:not_found)
        expect(@mo.media_tracks.count).to be(1)
        expect(@mo.media_tracks.first.content).to eq "subs"
      end

      it "does not show tracks that are in TTML format because it is vulnerable to xss" do
        track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
        track.update_attribute(:content, example_ttml_susceptible_to_xss)
        get "show", params: { media_object_id: @mo.media_id, id: track.id }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "#destroy" do
      it "destroys a track" do
        expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
        track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
        delete "destroy", params: { media_object_id: @mo.media_id, id: track.id }
        expect(MediaTrack.where(id: track.id).first).to be_nil
      end

      it "destroys a track from a MediaObject's default attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        track1 = attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        # @mo.attachment_id != attachment2.id
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
        delete "destroy", params: { media_object_id: @mo.media_id, id: track1.id }
        expect(MediaTrack.where(id: track1.id).first).to be_nil
        expect(attachment1.media_tracks.count).to be(0)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(0)
      end

      it "doesn't destroy a track from a MediaObject's non-default attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track2 = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        # @mo.attachment_id == attachment1.id
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
        delete "destroy", params: { media_object_id: @mo.media_id, id: track2.id }
        expect(MediaTrack.where(id: track2.id).first).not_to be_nil
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
      end
    end

    describe "#index" do
      it "lists tracks" do
        tracks = {}
        tracks["en"] = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id)
        tracks["af"] = @mo.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id)
        get "index", params: { media_object_id: @mo.media_id, include: ["content"] }
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(2)
        parsed.each do |t|
          expect(t["content"]).to eql tracks[t["locale"]]["content"]
          expect(t["id"]).to eql tracks[t["locale"]]["id"]
          expect(t["locale"]).to eql tracks[t["locale"]]["locale"]
          expect(t["kind"]).to eql tracks[t["locale"]]["kind"]
          expect(t["media_object_id"]).to eql tracks[t["locale"]]["media_object_id"]
          expect(t["user_id"]).to eql tracks[t["locale"]]["user_id"]
        end
      end

      it "includes workflow_state and asr in listed tracks" do
        @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id)
        get "index", params: { media_object_id: @mo.media_id }
        expect(response).to be_successful
        track = response.parsed_body.first
        expect(track["workflow_state"]).to eq("ready")
        expect(track["asr"]).to be false
      end

      it "does not list tracks that belong to an attachment other than the one media object belongs to" do
        tracks = {}
        tracks["en"] = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id)
        tracks["af"] = @mo.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id)

        attachment_model(media_entry_id: @mo.media_id)
        @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "new en subs", user_id: @teacher.id, media_object: @mo)

        get "index", params: { media_object_id: @mo.media_id, include: ["content"] }
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.pluck("content")).to match_array ["en subs", "af subs"]
      end
    end

    describe "#update" do
      it "updates tracks" do
        tracks = {}
        tracks["en"] = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id)
        tracks["af"] = @mo.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id)
        tracks["br"] = @mo.media_tracks.create!(kind: "subtitles", locale: "br", content: "br subs", user_id: @teacher.id)
        put "update",
            params: {
              media_object_id: @mo.media_id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "es subs" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(3)
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be true
        expect(parsed.any? { |t| t["locale"] == "br" && t["content"] == "br subs" }).to be true
      end

      it "updates tracks from a MediaObject's default attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user: @user, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 1", user: @user, media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 2", user: @user, media_object: @mo)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "br", content: "br subs", user: @user, media_object: @mo)
        # @mo.attachment_id == attachment1.id
        expect(attachment1.media_tracks.count).to be(2)
        # @mo.attachment_id != attachment2.id
        expect(attachment2.media_tracks.count).to be(2)
        expect(@mo.media_tracks.count).to be(2)
        put "update",
            params: {
              media_object_id: @mo.media_id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "es subs" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(2)
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be true
        expect(attachment1.media_tracks.count).to be(2)
        expect(attachment1.media_tracks.where(locale: "en").first["content"]).to eq("new en")
        expect(attachment1.media_tracks.where(locale: "es").first["content"]).to eq("es subs")
        expect(attachment2.media_tracks.count).to be(2)
        expect(attachment2.media_tracks.where(locale: "af").first["content"]).to eq("af subs 2")
        expect(attachment2.media_tracks.where(locale: "br").first["content"]).to eq("br subs")
        expect(@mo.media_tracks.pluck(:locale)).to match_array(%w[en es])
      end

      it "updates tracks from its media object" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", user: @user)
        expect(@mo.media_tracks.count).to be(1)
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(0)
        put "update",
            params: {
              media_object_id: @mo.media_id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "es subs" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(2)
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be true
        expect(@mo.media_tracks.count).to be(2)
        expect(attachment1.media_tracks.count).to be(2)
        expect(attachment2.media_tracks.count).to be(0)
        expect(@mo.media_tracks.where(locale: "en").first["content"]).to eq("new en")
        expect(@mo.media_tracks.where(locale: "es").first["content"]).to eq("es subs")
      end
    end
  end

  context "media_attachments" do
    before :once do
      attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
    end

    describe "#create" do
      it "gives an error if you don't have permission to change the attachment" do
        expect(Attachment).to receive(:find_by).with(id: @attachment.id.to_s).and_return(@attachment)
        expect(@attachment).to receive(:editing_restricted?).with(:content).and_return(true)

        post "create", params: { attachment_id: @attachment.id, kind: "subtitles", locale: "en", content: "one track mind" }
        expect(response).to be_unauthorized
      end

      it "checks the attachment for permissions over media object" do
        other_course = course_model
        other_course.media_objects.create!(media_id: "m-unicorns", title: "video1.mp3", media_type: "video/*")
        @attachment.update! media_entry_id: "m-unicorns"
        post "create", params: { attachment_id: @attachment.id, kind: "subtitles", locale: "en", content: "one track mind" }
        expect(response).to be_successful
      end

      it "creates a track" do
        content = "one track mind"
        post "create", params: { attachment_id: @attachment.id, kind: "subtitles", locale: "en", content: }
        expect(response).to be_successful
        expect(json_parse(response.body)["media_object_id"]).to eq @mo.id
        track = @attachment.media_tracks.last
        expect(track.content).to eq content
      end

      it "returns track considering MediaObject's attachments" do
        content = "one track mind"
        @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs 1", user_id: @teacher.id)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        track2 = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs 2", media_object: @mo)
        post "create", params: { attachment_id: @attachment.id, kind: "subtitles", locale: "en", content: }
        expect(response).to be_successful
        expect(json_parse(response.body)["id"]).to eq track2.id
        track = @attachment.media_tracks.last
        expect(track.content).to eq content
        expect(track.attachment_id).to eq @attachment.id
        expect(@mo.media_tracks.count).to be(1)
      end

      it "creates a track even if other attachment with same locale exists" do
        old_content = "first en subs"
        new_content = "second en subs"
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: old_content, media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        post "create", params: { attachment_id: attachment2.id, kind: "subtitles", locale: "en", content: new_content }
        expect(response).to be_successful

        track1 = attachment1.media_tracks.last
        expect(track1.content).to eq old_content
        expect(attachment1.media_tracks.count).to be(1)

        track2 = attachment2.media_tracks.last
        expect(track2.content).to eq new_content
        expect(attachment2.media_tracks.count).to be(1)
      end
    end

    describe "#create_asr" do
      let(:kaltura_client) { instance_double(CanvasKaltura::ClientV3) }
      let(:caption_asset_response) { { id: "caption_asset_456", languageCode: "en", status: "2" } }

      before do
        allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kaltura_client)
        allow(kaltura_client).to receive_messages(
          startSession: nil,
          create_caption_asset: caption_asset_response,
          caption_asset_contents: "1\n00:00:01,000 --> 00:00:02,000\nHello"
        )
      end

      context "feature flag" do
        it "returns 404 when feature flag is disabled" do
          @course.root_account.disable_feature!(:rce_asr_captioning_improvements)
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to have_http_status(:not_found)
        end

        it "proceeds when feature flag is enabled" do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to be_successful
        end
      end

      context "authorization" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "gives an error if you don't have permission to change the attachment" do
          expect(Attachment).to receive(:find_by).with(id: @attachment.id.to_s).and_return(@attachment)
          expect(@attachment).to receive(:editing_restricted?).with(:content).and_return(true)

          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to be_unauthorized
        end

        it "allows authorized users to create ASR captions" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to be_successful
        end

        it "returns error when attachment has 'maybe' as media_entry_id (pending media object creation)" do
          # Create an attachment with media_entry_id="maybe" - a placeholder for pending media processing
          pending_attachment = attachment_model(
            context: @course,
            filename: "video.mp4",
            content_type: "video/mp4",
            media_entry_id: "maybe"
          )

          post "create_asr", params: { attachment_id: pending_attachment.id, locale: "en" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(json_parse(response.body)["error"]).to eq("Media object not found or not yet processed")
        end
      end

      context "locale validation" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "accepts valid locales" do
          %w[en es fr-CA].each do |locale|
            post "create_asr", params: { attachment_id: @attachment.id, locale: }
            expect(response).to be_successful
          end
        end

        it "rejects empty locale" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "" }
          expect(response).to have_http_status(:bad_request)
          expect(json_parse(response.body)["error"]).to include("Invalid or missing locale")
        end

        it "rejects locale with special characters" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: '<img src="x">' }
          expect(response).to have_http_status(:bad_request)
          expect(json_parse(response.body)["error"]).to include("Invalid or missing locale")
        end
      end

      context "Kaltura integration" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "successfully creates caption asset" do
          expect(kaltura_client).to receive(:startSession).with(CanvasKaltura::SessionType::ADMIN)
          expect(kaltura_client).to receive(:create_caption_asset).with(@mo.media_id, "en")

          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to be_successful
        end

        it "handles Kaltura API failures gracefully" do
          allow(kaltura_client).to receive(:create_caption_asset).and_return(nil)

          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(json_parse(response.body)["error"]).to include("Failed to create caption asset")
        end

        it "does not create a new Kaltura asset when a processing track already exists" do
          existing_track = @attachment.media_tracks.create!(
            kind: "subtitles",
            locale: "en",
            content: "",
            external_id: "existing_asset_id",
            workflow_state: "processing",
            user: @teacher,
            media_object: @mo
          )

          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          expect(kaltura_client).not_to have_received(:create_caption_asset)
          expect(response).to be_successful
          expect(existing_track.reload.external_id).to eq("existing_asset_id")
        end
      end

      context "MediaTrack creation" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "creates track with correct external_id" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.external_id).to eq("caption_asset_456")
        end

        it "sets workflow_state to ready when caption asset is ready and SRT is available" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.workflow_state).to eq("ready")
          expect(track.content).to eq("1\n00:00:01,000 --> 00:00:02,000\nHello")
        end

        it "sets workflow_state to processing when caption asset is not yet ready" do
          allow(kaltura_client).to receive(:create_caption_asset)
            .and_return({ id: "caption_asset_456", languageCode: "en", status: "1" })
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.workflow_state).to eq("processing")
          expect(track.content).to eq("")
        end

        it "sets workflow_state to processing when caption asset generation fails" do
          allow(kaltura_client).to receive(:create_caption_asset)
            .and_return({ id: "caption_asset_456", languageCode: "en", status: "-1" })
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.workflow_state).to eq("failed")
          expect(track.content).to eq("")
        end

        it "sets kind to subtitles" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.kind).to eq("subtitles")
        end

        it "associates with attachment" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          track = @attachment.media_tracks.last
          expect(track.attachment_id).to eq(@attachment.id)
        end
      end

      context "response format" do
        before do
          @course.root_account.enable_feature!(:rce_asr_captioning_improvements)
        end

        it "returns media_track_api_json for attachment context" do
          post "create_asr", params: { attachment_id: @attachment.id, locale: "en" }

          expect(response).to be_successful
          response_body = json_parse(response.body)
          expect(response_body["media_object_id"]).to eq(@mo.id)
          expect(response_body["locale"]).to eq("en")
          expect(response_body["workflow_state"]).to eq("ready")
          expect(response_body["asr"]).to be true
        end
      end
    end

    describe "#show" do
      it "shows a track that belongs to default attachment" do
        track = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        get "show", params: { attachment_id: @attachment.id, id: track.id }
        expect(response).to be_successful
        expect(response.body).to eq "WEBVTT\n\nsubs"
      end

      it "shows a track that belongs to a non-default attachment" do
        @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs 2", media_object: @mo)
        get "show", params: { attachment_id: attachment2.id, id: track.id }
        expect(response).to be_successful
        expect(response.body).to eq "WEBVTT\n\nsubs 2"
      end

      it "shows a track that belongs to non-default attachment using default attachment id" do
        @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs 2", media_object: @mo)
        get "show", params: { attachment_id: @attachment.id, id: track.id }
        expect(response).to be_successful
        expect(response.body).to eq "WEBVTT\n\nsubs 2"
      end

      it "doesn't show a track that doesn not belong to its attachment" do
        track = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs 2", media_object: @mo)
        get "show", params: { attachment_id: attachment2.id, id: track.id }
        expect(response).to have_http_status(:not_found)
      end

      it "does not show tracks that belong to a different media object" do
        mo2 = MediaObject.create!(media_id: "0_abcdefghi", old_media_id: "1_012345678", context: @course)

        track = mo2.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
        get "show", params: { media_object_id: @mo.media_id, id: track.id }
        expect(response).to have_http_status(:not_found)
      end

      context "location-based access for unauthenticated users" do
        before do
          @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          @course.root_account.enable_feature!(:file_association_access)
          html = "<p><iframe src='/media_attachments_iframe/#{@attachment.id}'></iframe></p>"
          @course.syllabus_body = html
          @course.public_syllabus = true
          @course.updating_user = @teacher
          @course.save!
          remove_user_session
        end

        it "allows unauthenticated access with valid course_syllabus location parameter" do
          track = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "public subs", media_object: @mo)
          get "show", params: { attachment_id: @attachment.id, id: track.id, location: "course_syllabus_#{@course.id}" }
          expect(response).to be_successful
          expect(response.body).to eq "WEBVTT\n\npublic subs"
        end
      end
    end

    describe "#destroy" do
      it "gives an error if you don't have permission to change the attachment" do
        expect(Attachment).to receive(:find_by).with(id: @attachment.id.to_s).and_return(@attachment)
        expect(@attachment).to receive(:editing_restricted?).with(:content).and_return(true)

        track = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        delete "destroy", params: { attachment_id: @attachment.id, id: track.id }
        expect(response).to be_unauthorized
      end

      it "destroys a track from a MediaObject's default attachment" do
        attachment1 = @attachment
        track1 = attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        # @mo.attachment_id != attachment2.id
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
        delete "destroy", params: { attachment_id: attachment1.id, id: track1.id }
        expect(MediaTrack.where(id: track1.id).first).to be_nil
        expect(attachment1.media_tracks.count).to be(0)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(0)
      end

      it "destroys a track from a MediaObject's non-default attachment" do
        attachment1 = @attachment
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track2 = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        # @mo.attachment_id == attachment1.id
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
        delete "destroy", params: { attachment_id: attachment2.id, id: track2.id }
        expect(MediaTrack.where(id: track2.id).first).to be_nil
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(0)
        expect(@mo.media_tracks.count).to be(1)
      end

      it "doesn't destroy tracks that don't belong to the attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        track2 = attachment2.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs", media_object: @mo)
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
        delete "destroy", params: { attachment_id: attachment1.id, id: track2.id }
        expect(MediaTrack.where(id: track2.id).first).not_to be_nil
        expect(attachment1.media_tracks.count).to be(1)
        expect(attachment2.media_tracks.count).to be(1)
        expect(@mo.media_tracks.count).to be(1)
      end
    end

    describe "#index" do
      it "lists tracks" do
        tracks = {}
        tracks["en"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id, media_object: @mo)
        tracks["af"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id, media_object: @mo)
        get "index", params: { attachment_id: @attachment.id, include: ["content"] }
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(2)
        parsed.each do |t|
          expect(t["content"]).to eql tracks[t["locale"]]["content"]
          expect(t["id"]).to eql tracks[t["locale"]]["id"]
          expect(t["locale"]).to eql tracks[t["locale"]]["locale"]
          expect(t["kind"]).to eql tracks[t["locale"]]["kind"]
          expect(t["media_object_id"]).to eql tracks[t["locale"]]["media_object_id"]
          expect(t["user_id"]).to eql tracks[t["locale"]]["user_id"]
        end
      end

      it "includes workflow_state and asr in listed tracks" do
        @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id, media_object: @mo)
        get "index", params: { attachment_id: @attachment.id }
        expect(response).to be_successful
        track = response.parsed_body.first
        expect(track["workflow_state"]).to eq("ready")
        expect(track["asr"]).to be false
      end

      it "lists tracks considering other MediaObject's attachments" do
        tracks = {}
        tracks["en"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id, media_object: @mo)
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        tracks["af"] = attachment1.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id, media_object: @mo)
        get "index", params: { attachment_id: @attachment.id, include: ["content"] }
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(1)
        parsed.each do |t|
          expect(t["content"]).to eql tracks[t["locale"]]["content"]
          expect(t["id"]).to eql tracks[t["locale"]]["id"]
          expect(t["locale"]).to eql tracks[t["locale"]]["locale"]
          expect(t["kind"]).to eql tracks[t["locale"]]["kind"]
          expect(t["media_object_id"]).to eql tracks[t["locale"]]["media_object_id"]
          expect(t["user_id"]).to eql tracks[t["locale"]]["user_id"]
        end
      end
    end

    describe "#update" do
      it "gives an error if you don't have permission to change the attachment" do
        expect(Attachment).to receive(:find_by).with(id: @attachment.id.to_s).and_return(@attachment)
        expect(@attachment).to receive(:editing_restricted?).with(:content).and_return(true)

        tracks = {}
        tracks["en"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id)
        tracks["af"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id)
        put "update",
            params: {
              attachment_id: @attachment.id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "new es" }, { locale: "br" }]),
            format: :json
        expect(response).to be_forbidden
      end

      it "updates tracks" do
        tracks = {}
        tracks["en"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher.id, media_object: @mo)
        tracks["af"] = @attachment.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs", user_id: @teacher.id, media_object: @mo)
        tracks["br"] = @mo.media_tracks.create!(kind: "subtitles", locale: "br", content: "br subs", user_id: @teacher.id)
        put "update",
            params: {
              attachment_id: @attachment.id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "new es" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(3)
        expect(@attachment.media_tracks.count).to be(3)
        expect(@mo.media_tracks.count).to be(3)
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "new es" }).to be true
        expect(parsed.any? { |t| t["locale"] == "br" && t["content"] == "br subs" }).to be true
      end

      it "updates tracks from a MediaObject's default attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user: @user, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 1", user: @user, media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 2", user: @user, media_object: @mo)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "br", content: "br subs", user: @user, media_object: @mo)
        # @mo.attachment_id == attachment1.id
        expect(attachment1.media_tracks.count).to be(2)
        expect(@mo.media_tracks.count).to be(2)
        put "update",
            params: {
              attachment_id: attachment1.id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "es subs" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(2)
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be true
        expect(attachment1.media_tracks.count).to be(2)
        expect(attachment1.media_tracks.where(locale: "en").first["content"]).to eq("new en")
        expect(attachment1.media_tracks.where(locale: "es").first["content"]).to eq("es subs")
        expect(attachment2.media_tracks.count).to be(2)
        expect(attachment2.media_tracks.where(locale: "af").first["content"]).to eq("af subs 2")
        expect(attachment2.media_tracks.where(locale: "br").first["content"]).to eq("br subs")
        expect(@mo.media_tracks.pluck(:locale)).to match_array(%w[en es])
      end

      it "updates tracks from a MediaObject's non-default attachment" do
        attachment1 = attachment_model(context: @user, media_entry_id: @mo.media_id, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user: @user, media_object: @mo)
        attachment1.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 1", user: @user, media_object: @mo)
        attachment2 = attachment_model(context: @user, media_entry_id: @mo.media_id)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "af", content: "af subs 2", user: @user, media_object: @mo)
        attachment2.media_tracks.create!(kind: "subtitles", locale: "br", content: "br subs", user: @user, media_object: @mo)
        # @mo.attachment_id != attachment2.id
        expect(attachment2.media_tracks.count).to be(2)
        expect(@mo.media_tracks.count).to be(2)
        put "update",
            params: {
              attachment_id: attachment2.id,
              include: ["content"]
            },
            body: JSON.generate([{ locale: "en", content: "new en" }, { locale: "es", content: "es subs" }, { locale: "br" }]),
            format: :json
        expect(response).to be_successful
        parsed = response.parsed_body
        expect(parsed.length).to be(4)
        expect(parsed.any? { |t| t["locale"] == "br" && t["content"] == "br subs" }).to be true
        expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be true
        expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be true
        expect(attachment1.media_tracks.count).to be(2)
        expect(attachment1.media_tracks.where(locale: "en").first["content"]).to eq("en subs")
        expect(attachment1.media_tracks.where(locale: "af").first["content"]).to eq("af subs 1")
        expect(attachment2.media_tracks.count).to be(3)
        expect(attachment2.media_tracks.where(locale: "br").first["content"]).to eq("br subs")
        expect(attachment2.media_tracks.where(locale: "en").first["content"]).to eq("new en")
        expect(attachment2.media_tracks.where(locale: "es").first["content"]).to eq("es subs")
        expect(@mo.media_tracks.pluck(:locale)).to match_array(%w[af en])
      end
    end
  end
end
