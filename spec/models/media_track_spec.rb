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

  describe "#asr?" do
    it "returns true when kind is subtitles and external_id is present" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", content: "blah", external_id: "ext123")
      expect(track.asr?).to be true
    end

    it "returns false when kind is not subtitles" do
      track = @media_object.media_tracks.build(kind: "captions", locale: "en", content: "blah", external_id: "ext123")
      expect(track.asr?).to be false
    end

    it "returns false when external_id is blank" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", content: "blah")
      expect(track.asr?).to be false
    end
  end

  describe "workflow_state" do
    it "defaults to ready" do
      track = @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "blah")
      expect(track.workflow_state).to eq("ready")
    end

    it "accepts processing, ready, and failed" do
      %w[processing ready failed].each do |workflow_state|
        track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", content: "blah", workflow_state:)
        expect(track).to be_valid
      end
    end
  end

  describe "content validation" do
    it "requires content for regular tracks" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en")
      expect(track).not_to be_valid
      expect(track.errors[:content]).to be_present
    end

    it "allows empty content for ASR tracks with processing workflow_state" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", external_id: "ext123", workflow_state: "processing")
      expect(track).to be_valid
    end

    it "allows empty content for ASR tracks with failed workflow_state" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", external_id: "ext123", workflow_state: "failed")
      expect(track).to be_valid
    end

    it "requires content for ASR tracks with ready workflow_state" do
      track = @media_object.media_tracks.build(kind: "subtitles", locale: "en", external_id: "ext123", workflow_state: "ready")
      expect(track).not_to be_valid
      expect(track.errors[:content]).to be_present
    end
  end

  describe "#sync_asr_subtitles_later" do
    let(:track) do
      @media_object.media_tracks.create!(
        kind: "subtitles",
        locale: "en",
        content: "",
        external_id: "ext123",
        workflow_state: "processing"
      )
    end

    it "enqueues a delayed job using the default 60-minute interval" do
      Timecop.freeze do
        expect(track).to receive(:delay).with(run_at: 60.minutes.from_now, strand: "asr_subtitle_sync:#{track.global_id}").and_return(track)
        expect(track).to receive(:sync_asr_subtitles).with(attempt: 1)
        track.sync_asr_subtitles_later
      end
    end

    it "uses the asr_subtitles_sync_poll_interval_minutes setting when present" do
      Setting.set("asr_subtitles_sync_poll_interval_minutes", "5")
      Timecop.freeze do
        expect(track).to receive(:delay).with(run_at: 5.minutes.from_now, strand: "asr_subtitle_sync:#{track.global_id}").and_return(track)
        expect(track).to receive(:sync_asr_subtitles).with(attempt: 1)
        track.sync_asr_subtitles_later
      end
    ensure
      Setting.remove("asr_subtitles_sync_poll_interval_minutes")
    end
  end

  describe "after_create callback" do
    it "enqueues sync job when creating an ASR track in processing state" do
      expect do
        @media_object.media_tracks.create!(
          kind: "subtitles",
          locale: "en",
          content: "",
          external_id: "ext123",
          workflow_state: "processing"
        )
      end.to change { Delayed::Job.where(tag: "MediaTrack#sync_asr_subtitles").count }.by(1)
    end

    it "does not enqueue sync job for a non-ASR track" do
      expect do
        @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "sub content")
      end.not_to change { Delayed::Job.where(tag: "MediaTrack#sync_asr_subtitles").count }
    end

    it "does not enqueue sync job for an ASR track already in ready state" do
      expect do
        @media_object.media_tracks.create!(
          kind: "subtitles",
          locale: "en",
          content: "1\n00:00:01.000 --> 00:00:02.000\nHello",
          external_id: "ext123",
          workflow_state: "ready"
        )
      end.not_to change { Delayed::Job.where(tag: "MediaTrack#sync_asr_subtitles").count }
    end
  end

  describe "#sync_asr_subtitles" do
    let(:kaltura_client) { instance_double(CanvasKaltura::ClientV3) }
    let(:track) do
      @media_object.media_tracks.create!(
        kind: "subtitles",
        locale: "en",
        content: "",
        external_id: "ext123",
        workflow_state: "processing"
      )
    end

    before do
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kaltura_client)
      allow(kaltura_client).to receive(:startSession)
    end

    it "marks failed when attempt exceeds max" do
      track.sync_asr_subtitles(attempt: MediaTrack::ASR_SUBTITLES_SYNC_MAX_ATTEMPTS + 1)
      expect(track.reload.workflow_state).to eq("failed")
    end

    it "marks ready with content when Kaltura status is 2 and SRT present" do
      allow(kaltura_client).to receive(:caption_asset).with("ext123").and_return({ status: "2" })
      allow(kaltura_client).to receive(:caption_asset_contents).with("ext123").and_return("1\n00:00:01.000 --> 00:00:02.000\nHello")
      track.sync_asr_subtitles(attempt: 1)
      track.reload
      expect(track.workflow_state).to eq("ready")
      expect(track.content).to include("Hello")
    end

    it "marks failed when Kaltura status is -1" do
      allow(kaltura_client).to receive(:caption_asset).with("ext123").and_return({ status: "-1" })
      track.sync_asr_subtitles(attempt: 1)
      expect(track.reload.workflow_state).to eq("failed")
    end

    it "re-enqueues a job when still processing" do
      allow(kaltura_client).to receive(:caption_asset).with("ext123").and_return({ status: "0" })
      Timecop.freeze do
        expect(track).to receive(:delay).with(run_at: 60.minutes.from_now, strand: "asr_subtitle_sync:#{track.global_id}").and_return(track)
        expect(track).to receive(:sync_asr_subtitles).ordered.with(attempt: 1).and_call_original
        expect(track).to receive(:sync_asr_subtitles).ordered.with(attempt: 2)
        track.sync_asr_subtitles(attempt: 1)
      end
    end
  end
end
