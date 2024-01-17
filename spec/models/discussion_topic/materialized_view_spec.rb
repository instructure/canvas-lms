# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require "nokogiri"

describe DiscussionTopic::MaterializedView do
  def recursively_slice_with_replies(list, slice_targets)
    slice_targets.append("replies") unless slice_targets.include? "replies"
    list.map do |l|
      l = l.slice(*slice_targets)
      l["replies"] = recursively_slice_with_replies(l["replies"] || [], slice_targets)
      l
    end
  end

  before :once do
    topic_with_nested_replies
    @view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
  end

  describe ".materialized_view_for" do
    it "builds the intial empty view synchronously" do
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to eq ["[]", [], [], []]
    end

    it "returns nil and schedule a job if no view" do
      DiscussionTopic::MaterializedView.for(@topic).destroy
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to be_nil
      expect(Delayed::Job.where(singleton: "materialized_discussion:#{@topic.id}").count).to eq 1
    end

    it "returns the view if it exists but is out of date" do
      @view.update_materialized_view(synchronous: true)
      expect(DiscussionTopic::MaterializedView.materialized_view_for(@topic)).to be_present
      reply = @topic.reply_from(user: @user, text: "new message!")
      Delayed::Job.find_available(100).each(&:destroy)
      json, _participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      expect(json).to be_present
      expect(entries).not_to include(reply.id)
      # since the view was out of date, it's returned but a job is queued
      expect(Delayed::Job.where(singleton: "materialized_discussion:#{@topic.id}").count).to eq 1
      # after updating, the view should include the new entry
      @view.update_materialized_view(synchronous: true)
      json, _participants, entries = DiscussionTopic::MaterializedView.materialized_view_for(@topic)
      expect(json).to be_present
      expect(entries).to include(reply.id)
    end
  end

  it "requeues the job if replication times out" do
    view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
    view.update_materialized_view
    allow(DiscussionTopic::MaterializedView).to receive(:wait_for_replication).and_return(false)
    run_jobs
    job = Delayed::Job.where(singleton: "materialized_discussion:#{view.id}").first
    expect(job.run_at > 1.minute.from_now).to be_truthy
    expect(view.reload.entry_ids_array).to be_empty

    allow(DiscussionTopic::MaterializedView).to receive(:wait_for_replication).and_return(true)
    job.update_attribute(:run_at, 1.minute.ago)
    run_jobs
    expect(view.reload.entry_ids_array).to match_array(@topic.discussion_entries.map(&:id))
  end

  it "builds a materialized view of the structure, participants and entry ids" do
    view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
    view.update_materialized_view(synchronous: true)
    structure, participant_ids, entry_ids = @topic.materialized_view
    expect(view.materialized_view_json).to eq [structure, participant_ids, entry_ids, []]
    expect(participant_ids.sort).to eq [@student.id, @teacher.id].sort
    expect(entry_ids.sort).to eq @topic.discussion_entries.map(&:id).sort
    json = JSON.parse(structure)
    expect(json.size).to eq 2
    expect(json.pluck("id")).to eq [@root1.id.to_s, @root2.id.to_s]
    expect(json.pluck("parent_id")).to eq [nil, nil]
    deleted = json[0]["replies"][0]
    expect(deleted["deleted"]).to be true
    expect(deleted["user_id"]).to be_nil
    expect(deleted["message"]).to be_nil
    expect(json[0]["replies"][1]["replies"][0]["attachment"]["url"]).to eq "https://placeholder.invalid/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
    # verify the api_user_content functionality in a non-request context
    html_message = json[0]["replies"][1]["message"]
    html = Nokogiri::HTML5.fragment(html_message)
    expect(html.at_css("a")["href"]).to eq "https://placeholder.invalid/courses/#{@course.id}/files/#{@reply2_attachment.id}/download"
    expect(html.at_css("video")["src"]).to eq "https://placeholder.invalid/courses/#{@course.id}/media_download?entryId=0_abcde&media_type=video&redirect=1"

    # the deleted entry will be marked deleted and have no summary
    simple_json = recursively_slice_with_replies(json, ["id"])
    expect(simple_json).to eq [
      {
        "id" => @root1.id.to_s,
        "replies" => [
          { "id" => @reply1.id.to_s, "replies" => [{ "id" => @reply_reply2.id.to_s, "replies" => [] }], },
          { "id" => @reply2.id.to_s, "replies" => [{ "id" => @reply_reply1.id.to_s, "replies" => [] }], },
        ],
      },
      {
        "id" => @root2.id.to_s,
        "replies" => [
          { "id" => @reply3.id.to_s, "replies" => [], },
        ],
      },
    ]
  end

  it "works with media track tags" do
    obj = @course.media_objects.create! media_id: "0_deadbeef"
    track = obj.media_tracks.create! kind: "subtitles", locale: "tlh", content: "Hab SoSlI' Quch!"

    @topic.reply_from(user: @student, html: '<a id="media_comment_0_deadbeef" class="instructure_inline_media_comment video_comment"></a>')

    view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
    view.update_materialized_view(synchronous: true)
    structure, _participant_ids, _entry_ids = @topic.materialized_view
    entry_json = JSON.parse(structure).last
    html = Nokogiri::HTML5.fragment(entry_json["message"])
    expect(html.at_css("video track")["src"]).to eq "https://placeholder.invalid/media_objects/#{obj.id}/media_tracks/#{track.id}.json"
  end

  context "sharding" do
    specs_require_sharding

    it "users local ids when accessed from the same shard" do
      @view.update_materialized_view(synchronous: true)
      structure, participant_ids, entry_ids = @topic.materialized_view
      expect(participant_ids.sort).to eq [@student.local_id, @teacher.local_id].sort
      expect(entry_ids.sort).to eq @topic.discussion_entries.map(&:local_id).sort
      json = JSON.parse(structure)
      simple_json = recursively_slice_with_replies(json, ["id", "user_id"])
      expect(simple_json).to eq [
        {
          "id" => @root1.local_id.to_s,
          "user_id" => @student.local_id.to_s,
          "replies" => [
            {
              "id" => @reply1.local_id.to_s,
              "replies" => [{
                "id" => @reply_reply2.local_id.to_s,
                "user_id" => @student.local_id.to_s,
                "replies" => []
              }]
            },
            {
              "id" => @reply2.local_id.to_s,
              "user_id" => @teacher.local_id.to_s,
              "replies" => [{
                "id" => @reply_reply1.local_id.to_s,
                "user_id" => @student.local_id.to_s,
                "replies" => []
              }]
            },
          ],
        },
        {
          "id" => @root2.local_id.to_s,
          "user_id" => @student.local_id.to_s,
          "replies" => [{
            "id" => @reply3.local_id.to_s,
            "user_id" => @student.local_id.to_s,
            "replies" => []
          }],
        },
      ]
    end

    it "users global ids when accessed from a different shard" do
      @view.update_materialized_view(synchronous: true)
      @shard1.activate do
        structure, participant_ids, entry_ids = @topic.materialized_view
        expect(participant_ids.sort).to eq [@student.global_id, @teacher.global_id].sort
        expect(entry_ids.sort).to eq @topic.discussion_entries.map(&:global_id).sort
        json = JSON.parse(structure)
        simple_json = recursively_slice_with_replies(json, ["id", "user_id"])
        expect(simple_json).to eq [
          {
            "id" => @root1.global_id.to_s,
            "user_id" => @student.global_id.to_s,
            "replies" => [
              {
                "id" => @reply1.global_id.to_s,
                "replies" => [{
                  "id" => @reply_reply2.global_id.to_s,
                  "user_id" => @student.global_id.to_s,
                  "replies" => []
                }]
              },
              {
                "id" => @reply2.global_id.to_s,
                "user_id" => @teacher.global_id.to_s,
                "replies" => [{
                  "id" => @reply_reply1.global_id.to_s,
                  "user_id" => @student.global_id.to_s,
                  "replies" => []
                }]
              },
            ],
          },
          {
            "id" => @root2.global_id.to_s,
            "user_id" => @student.global_id.to_s,
            "replies" => [{
              "id" => @reply3.global_id.to_s,
              "user_id" => @student.global_id.to_s,
              "replies" => []
            }],
          },
        ]
      end
    end
  end
end
