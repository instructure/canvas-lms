# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Importers::MediaTrackImporter do
  before :once do
    course_factory
    user_factory
    @cm = ContentMigration.create!(
      context: @course,
      user: @user,
      source_course: @course,
      copy_options: { everything: "1" }
    )
  end

  describe "import_from_migration" do
    it "doesn't crash when media tracks error on import" do
      attachment_model(display_name: "media_with_captions.mp4", uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4"))
      track = { "content" => "hi", "kind" => nil, "locale" => "en" }
      expect { Importers::MediaTrackImporter.import_from_migration(@attachment, @attachment.media_object_by_media_id, track, @cm) }.not_to raise_error
      expect(@cm.warnings).to include("Subtitles (en) could not be imported for media_with_captions.mp4")
    end
  end

  describe "process_migration" do
    it "doesn't crash when the attachment for the media track isn't found" do
      attachment_model(display_name: "media_with_captions", uploaded_data: stub_file_data("media_with_captions", "asdf", "unknown/unknown"), migration_id: "hi")
      data = { "media_tracks" => { "hi" => [{ "migration_id" => "hi", "kind" => "subtitles", "locale" => "en", "content" => "WEBVTT\n00:00.001 --> 00:00.900\n- Hi!" }] } }
      expect { Importers::MediaTrackImporter.process_migration(data, @cm) }.not_to raise_error
    end
  end
end
