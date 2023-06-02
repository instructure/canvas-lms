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
    @mo = factory_with_protected_attributes(MediaObject, media_id: "0_abcdefgh", old_media_id: "1_01234567", context: @course)
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
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "validates :kind" do
        post "create", params: { media_object_id: @mo.media_id, kind: "unkind", locale: "en", content: "1" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "validates :locale" do
        post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: '<img src="lolcats.gif">', content: "1" }
        expect(response).to have_http_status(:unprocessable_entity)
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
        expect(response).to have_http_status(:unprocessable_entity)
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
        mo2 = factory_with_protected_attributes(MediaObject, media_id: "0_abcdefghi", old_media_id: "1_012345678", context: @course)

        track = mo2.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
        get "show", params: { media_object_id: @mo.media_id, id: track.id }
        expect(response).to have_http_status(:not_found)
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
        expect(response).to be_unauthorized
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
