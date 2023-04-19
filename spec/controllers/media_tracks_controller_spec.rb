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

  describe "#create" do
    it "creates a track" do
      expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
      content = "one track mind"
      post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: "en", content: content }
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
      post "create", params: { media_object_id: @mo.media_id, kind: "subtitles", locale: "en", content: content, exclude: ["tracks"] }
      expect(response).to be_successful
      rbody = json_parse(response.body)
      expect(rbody["media_id"]).to eq @mo.media_id
      expect(rbody["media_tracks"]).to be_nil
    end
  end

  describe "#show" do
    it "shows a track" do
      track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
      get "show", params: { media_object_id: @mo.media_id, id: track.id }
      expect(response).to be_successful
      expect(response.body).to eq track.webvtt_content
    end

    it "does not show tracks that are in TTML format because it is vulnerable to xss" do
      track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
      track.update_attribute(:content, example_ttml_susceptible_to_xss)
      get "show", params: { media_object_id: @mo.media_id, id: track.id }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not show tracks that belong to a different media object" do
      mo2 = factory_with_protected_attributes(MediaObject, media_id: "0_abcdefghi", old_media_id: "1_012345678", context: @course)

      track = mo2.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
      get "show", params: { media_object_id: @mo.media_id, id: track.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "#destroy" do
    it "destroys a track" do
      expect_any_instantiation_of(@mo).to receive(:media_sources).and_return(nil)
      track = @mo.media_tracks.create!(kind: "subtitles", locale: "en", content: "subs")
      delete "destroy", params: { media_object_id: @mo.media_id, media_track_id: track.id }
      expect(MediaTrack.where(id: track.id).first).to be_nil
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
      expect(parsed.any? { |t| t["locale"] == "en" && t["content"] == "new en" }).to be
      expect(parsed.any? { |t| t["locale"] == "es" && t["content"] == "es subs" }).to be
      expect(parsed.any? { |t| t["locale"] == "br" && t["content"] == "br subs" }).to be
    end
  end
end
