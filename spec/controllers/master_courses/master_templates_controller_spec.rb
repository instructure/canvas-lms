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

  describe "GET 'associated_courses'" do
    def get_associated_courses(params = {})
      get "associated_courses",
          params: {
            course_id: @course.id,
            template_id: "default",
            **params
          },
          format: "json"
    end

    it "requires authorization" do
      get_associated_courses
      assert_unauthorized
    end

    context "with authorization" do
      before do
        user_session(@teacher)
      end

      it "returns empty array when no associated courses" do
        json = parse_response(get_associated_courses)
        expect(json).to eq([])
      end

      context "with associated courses" do
        before do
          @teacher1 = User.create!(name: "Teacher One")
          @teacher2 = User.create!(name: "Teacher Two")

          @term = EnrollmentTerm.create!(name: "Fall 2023", root_account: @course.root_account)

          @child_course = Course.create!(
            name: "Child Course",
            course_code: "CHILD101",
            sis_source_id: "child_sis_123",
            enrollment_term: @term
          )
          @child_course.enroll_teacher(@teacher1, enrollment_state: "active")
          @child_course.enroll_teacher(@teacher2, enrollment_state: "active")

          @concluded_child_course = Course.create!(
            name: "Concluded Child Course",
            course_code: "CONCLUDED101",
            sis_source_id: "concluded_sis_456",
            enrollment_term: @term
          )
          @concluded_child_course.enroll_teacher(@teacher1, enrollment_state: "active")
          @concluded_child_course.soft_conclude!
          @concluded_child_course.save!

          @template.add_child_course!(@child_course)
          @template.add_child_course!(@concluded_child_course)
        end

        it "returns associated courses with all expected fields" do
          json = parse_response(get_associated_courses)
          expect(json.length).to eq(2)

          child_course_json = json.find { |c| c["id"] == @child_course.id }
          expect(child_course_json["name"]).to eq("Child Course")
          expect(child_course_json["course_code"]).to eq("CHILD101")
          expect(child_course_json["concluded"]).to be_falsey
          expect(child_course_json["term_name"]).to eq("Fall 2023")
          expect(child_course_json["teachers"].length).to eq(2)
          expect(child_course_json["teachers"].pluck("display_name")).to match_array(["Teacher One", "Teacher Two"])

          concluded_course_json = json.find { |c| c["id"] == @concluded_child_course.id }
          expect(concluded_course_json["name"]).to eq("Concluded Child Course")
          expect(concluded_course_json["course_code"]).to eq("CONCLUDED101")
          expect(concluded_course_json["concluded"]).to be_truthy
          expect(concluded_course_json["term_name"]).to eq("Fall 2023")
          expect(concluded_course_json["teachers"].length).to eq(1)
          expect(concluded_course_json["teachers"][0]["display_name"]).to eq("Teacher One")
        end
      end
    end
  end

  describe "PUT restrict_item" do
    subject do
      put "restrict_item", params:
    end

    let(:params) do
      {
        course_id: @course.id,
        template_id: "default",
        content_type:,
        content_id: content.id,
        restricted: true,
      }
    end

    before do
      user_session(@teacher)
    end

    context "discussion_topic as content" do
      let(:content) { DiscussionTopic.create_graded_topic!(course: @course, title: "Graded Discussion") }
      let(:content_type) { "discussion_topic" }

      it "updates master tag for discussion topic" do
        subject
        expect(MasterCourses::MasterContentTag.find_by(content:).restrictions).to match(hash_including(@template.default_restrictions))
      end

      context "when provided restrictions is invalid" do
        before do
          params[:restrictions] = { invalid: "restriction" }
        end

        it "returns bad request if tag is invalid" do
          subject
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "with sub assignments" do
        let!(:sub_assignment) { content.assignment.sub_assignments.create!(context: content.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC) }

        it "updates master tag for sub assignments" do
          subject
          expect(MasterCourses::MasterContentTag.find_by(content: sub_assignment).restrictions).to match(hash_including(@template.default_restrictions))
        end
      end
    end
  end
end
