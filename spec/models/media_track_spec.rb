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

describe MediaTrack do
  before :once do
    course_factory
    @media_object = media_object
  end

  it "requires unique locales by attachment_id" do
    attachment = @media_object.attachment
    attachment.media_tracks.create!(locale: "en", content: "en subs", attachment:, media_object: @media_object)
    expect do
      attachment.media_tracks.create!(locale: "en", content: "new subs", attachment:, media_object: @media_object)
    end.to raise_error "Validation failed: Locale has already been taken"
    expect do
      attachment.media_tracks.create!(locale: "es", content: "es subs", attachment:, media_object: @media_object)
    end.not_to raise_error
  end

  it "allows track creation for different attachments with the same media object" do
    a1 = @media_object.attachment
    a1.media_tracks.create!(locale: "en", content: "en subs", attachment: a1, media_object: @media_object)
    a2 = attachment_model(context: @course, media_entry_id: @media_object.media_id, content_type: "video")
    expect do
      a2.media_tracks.create!(locale: "en", content: "new subs", attachment: a1, media_object: @media_object)
    end.not_to raise_error
  end

  it "does not require unique locales if there are no attachment_ids" do
    quiz_with_submission
    media_object = media_object(context: @qsub)
    track = media_object.media_tracks.create!(locale: "en", content: "en subs")
    expect(track.attachment_id).to be_nil
    expect do
      media_object.media_tracks.create!(locale: "en", content: "new subs")
    end.not_to raise_error
  end

  it "allows creation of tracks for other media objects" do
    mo = media_object
    mo.media_tracks.create!(locale: "en", content: "en subs")
    expect do
      @media_object.media_tracks.create!(locale: "en", content: "new subs")
    end.not_to raise_error
  end

  it "allows creation of tracks for media objects that have previous tracks without attachment ids" do
    attachment = @media_object.attachment
    @media_object.media_tracks.create!(locale: "en", content: "en subs").update_columns(attachment_id: nil)
    expect do
      attachment.media_tracks.create!(locale: "es", content: "es subs", media_object: @media_object)
    end.not_to raise_error
  end

  it "does not allow non-word locales" do
    quiz_with_submission
    media_object = media_object(context: @qsub)
    expect do
      media_object.media_tracks.create!(locale: "5", content: "en subs")
    end.to raise_error "Validation failed: Locale is invalid"
  end
end
