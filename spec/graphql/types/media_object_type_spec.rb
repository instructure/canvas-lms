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

require_relative "../graphql_spec_helper"

describe Types::MediaObjectType do
  before(:once) do
    teacher_in_course(active_all: true)

    @media_object = media_object(
      user: @teacher
    )
  end

  let(:media_object_type) { GraphQLTypeTester.new(@media_object, current_user: @teacher) }

  context "with a valid media object" do
    def resolve_media_object_field(field, current_user: @teacher)
      media_object_type.resolve(
        field,
        current_user:
      )
    end

    [
      ["canAddCaptions", true],
      ["mediaType", "video"],
      ["title", "media_title"],
    ].each do |key, value|
      it "returns the correct #{key} for the media object" do
        expect(resolve_media_object_field(key)).to eq(value)
      end
    end

    it "returns the correct media sources for the media object" do
      random_url = SecureRandom.hex
      random_url2 = SecureRandom.hex
      allow(CanvasKaltura::ClientV3).to receive(:new) {
        instance_double(
          CanvasKaltura::ClientV3,
          media_sources: [
            { url: random_url },
            { url: random_url2 },
          ]
        )
      }

      expect(resolve_media_object_field(
               'mediaSources {
          url
        }'
             )).to eq([
                        random_url,
                        random_url2
                      ])
    end

    it "returns the correct media tracks for the media object" do
      @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
      expect(resolve_media_object_field("mediaTracks { content }")).to eq(["blah"])
    end

    it "returns an empty list if there are no media tracks" do
      expect(resolve_media_object_field("mediaTracks { content }")).to eq([])
    end

    it "returns nil when presented with an unrecognized media type" do
      @media_object.media_type = "fakemediatype"
      @media_object.save!

      expect(resolve_media_object_field("mediaType")).to be_nil
    end

    it "returns an empty list if there are no media sources" do
      allow(CanvasKaltura::ClientV3).to receive(:new) {
        instance_double(
          CanvasKaltura::ClientV3,
          media_sources: []
        )
      }

      expect(resolve_media_object_field(
               'mediaSources {
          url
        }'
             )).to eq([])
    end

    it "checks permissions on canAddCaptions" do
      expect(resolve_media_object_field("canAddCaptions", current_user: User.new)).to be(false)
    end

    it "returns media download url" do
      opts = {
        download: "1",
        download_frd: "1",
        only_path: true
      }
      expected_url = GraphQLHelpers::UrlHelpers.file_download_url(@media_object, opts)
      expect(expected_url.end_with?("/download?download_frd=1")).to be_truthy
    end
  end
end
