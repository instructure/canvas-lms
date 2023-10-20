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

describe DiscussionTopicsApiController do
  describe "POST add_entry" do
    before :once do
      Setting.set("enable_page_views", "db")
      course_with_student active_all: true
      @topic = @course.discussion_topics.create!(title: "discussion")
    end

    before do
      user_session(@student)
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
      post "add_entry", params: { topic_id: @topic.id, course_id: @course.id, user_id: @user.id, message: "message", read_state: "read" }, format: "json"
    end

    it "creates a new discussion entry" do
      entry = assigns[:entry]
      expect(entry.discussion_topic).to eq @topic
      expect(entry.id).not_to be_nil
      expect(entry.message).to eq "message"
    end

    it "logs an asset access record for the discussion topic" do
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:code]).to eq @topic.asset_string
      expect(accessed_asset[:category]).to eq "topics"
      expect(accessed_asset[:level]).to eq "participate"
    end

    it "registers a page view" do
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq "post"
      expect(page_view.url).to match %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      expect(page_view.participated).to be_truthy
    end
  end

  context "add_entry file quota" do
    before do
      course_with_student active_all: true
      @course.allow_student_forum_attachments = true
      @course.save!
      @topic = @course.discussion_topics.create!(title: "discussion")
      user_session(@student)
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
    end

    it "uploads attachment to submissions folder if topic is graded" do
      assignment_model(course: @course)
      @topic.assignment = @assignment
      @topic.save
      Setting.set("user_default_quota", -1)
      expect(@student.attachments.count).to eq 0

      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to be_successful
      expect(@student.attachments.count).to eq 1
      expect(@student.attachments.first.folder.for_submissions?).to be_truthy
      expect(@student.attachments.pluck(:filename)).to include(default_uploaded_data.original_filename)
    end

    it "fails if attachment a file over student quota (not course)" do
      Setting.set("user_default_quota", -1)

      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to_not be_successful
      expect(response.body).to include("User storage quota exceeded")
    end

    it "succeeds otherwise" do
      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to be_successful
    end

    it "uses instfs to store attachment if instfs is enabled" do
      uuid = "1234-abcd"
      allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)
      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"
      expect(@student.attachments.first.instfs_uuid).to eq(uuid)
    end
  end

  context "cross-sharding" do
    specs_require_sharding

    before do
      course_with_student active_all: true
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
      @topic = @course.discussion_topics.create!(title: "student topic", message: "Hello", user: @student)
      @entry = @topic.discussion_entries.create!(message: "first message", user: @student)
      @entry2 = @topic.discussion_entries.create!(message: "second message", user: @student)
      @reply = @entry.discussion_subentries.create!(discussion_topic: @topic, message: "reply to first message", user: @student)
    end

    it "returns the entries across shards" do
      user_session(@student)
      @shard1.activate do
        post "entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id }, format: "json"
        expect(response.parsed_body.count).to eq(2)
      end

      @shard2.activate do
        post "entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id }, format: "json"
        expect(response.parsed_body.count).to eq(2)
      end
    end

    it "returns the entry replies across shards" do
      user_session(@student)
      @shard1.activate do
        post "replies", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id, entry_id: @entry.id }, format: "json"
        expect(response.parsed_body.count).to eq(1)
      end

      @shard2.activate do
        post "replies", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id, entry_id: @entry.id }, format: "json"
        expect(response.parsed_body.count).to eq(1)
      end
    end
  end
end
