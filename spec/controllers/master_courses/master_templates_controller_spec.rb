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

describe MasterCourses::MasterTemplatesController do
  # ActiveRecord::Base.logger = Logger.new(STDOUT)
  before :once do
    course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
  end

  def parse_response(response)
    JSON.parse(response.body)
  end

  describe "GET 'unsynced_changes'" do
    def get_unsynced_changes(params)
      get "unsynced_changes",
          params: {
            course_id: @course.id,
            template_id: @template.id,
            **params
          },
          format: "json"
    end

    it "requires authorization" do
      get_unsynced_changes({})
      assert_unauthorized
    end

    context "returns changes" do
      before do
        user_session(@teacher)
      end

      it "for initial sync" do
        json = parse_response(get_unsynced_changes({}))[0]
        expect(json["asset_name"]).to eq("Unnamed Course")
        expect(json["change_type"]).to eq("initial_sync")
      end

      context "after initial sync" do
        before do
          @template.add_child_course!(Course.create!)
          time = 2.days.ago
          @template.master_migrations.create!(exports_started_at: time, workflow_state: "completed")
          MasterCourses::MasterTemplate.preload_index_data([@template])
        end

        it "when an account level outcome is deleted" do
          out = LearningOutcome.create!(title: "account level outcome", context: @course.account)
          @template.create_content_tag_for!(out)
          out_content_tag = ContentTag.create!(content: out, context: @course)
          out_content_tag.workflow_state = "deleted"
          out_content_tag.save!

          json = parse_response(get_unsynced_changes({}))[0]
          expect(json["asset_id"]).to eq(out.id)
          expect(json["asset_name"]).to eq(out.title)
          expect(json["asset_type"]).to eq("learning_outcome")
          expect(json["change_type"]).to eq("deleted")
        end

        it "works with media tracks" do
          expect(Account.site_admin).to receive(:feature_enabled?).with(:media_links_use_attachment_id).and_return(true)
          media = media_object
          attachment = media.attachment
          mt = attachment.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", media_object: media)
          @template.create_content_tag_for!(mt)

          json = parse_response(get_unsynced_changes({})).find { |j| j["asset_type"] == "media_track" }
          expect(json["asset_id"]).to eq(mt.id)
          expect(json["asset_name"]).to eq(attachment.filename)
          expect(json["asset_type"]).to eq("media_track")
          expect(json["change_type"]).to eq("created")
        end
      end
    end
  end
end
