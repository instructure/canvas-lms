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

require_relative '../spec_helper'

describe PlannerOverridesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @group = @course.assignment_groups.create(:name => "some group")
    @assignment = course_assignment
    @assignment2 = course_assignment
    @planner_override = PlannerOverride.create!(plannable_id: @assignment.id,
                                                plannable_type: "Assignment",
                                                marked_complete: false,
                                                user_id: @student.id)
  end

  def course_assignment
    assignment = @course.assignments.create(
      :title => "some assignment #{@course.assignments.count}",
      :assignment_group => @group,
      :due_at => Time.zone.now + 1.week
    )
    assignment
  end

  context "unauthenticated" do
    it "should return unauthorized" do
      get :index
      assert_unauthorized

      post :create, :plannable_type => "assignment",
                     :plannable_id => @assignment.id,
                     :marked_complete => false
      assert_unauthorized
    end
  end

  context "authenticated" do
    context "as student" do
      before :each do
        user_session(@student)
        @course.root_account.enable_feature!(:student_planner)
      end

      describe "GET #items_index" do
        it "returns http success" do
          get :items_index
          expect(response).to have_http_status(:success)
        end

        it "should show wiki pages with todo dates" do
          wiki_page_model(course: @course)
          @page.todo_date = 1.day.from_now
          @page.save!
          get :items_index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 3
          page = response_json.detect { |i| i["plannable_id"] == @page.id }
          expect(page["plannable_type"]).to eq 'wiki_page'
        end

        it "should show planner notes for the user" do
          planner_note_model(course: @course)
          get :items_index
          response_json = json_parse(response.body)
          note = response_json.detect { |i| i["plannable_type"] == 'planner_note' }
          expect(response_json.length).to eq 3
          expect(note["plannable"]["title"]).to eq @planner_note.title
        end

        context "new activity filter" do
          it "should return newly created & unseen items" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: Time.zone.now)
            dt.change_all_read_state("unread", @student)
            get :items_index, filter: "new_activity"
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.map { |i| i["plannable"]["id"].to_s }).to be_include(dt.id.to_s)
          end

          it "should return newly graded items" do
            @assignment.grade_student @student, grade: 10, grader: @teacher
            get :items_index, filter: "new_activity"
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @assignment.id
          end

          it "should return items with new submission comments" do
            @sub = @assignment2.submit_homework(@student)
            @sub.submission_comments.create!(comment: "hello", author: @teacher)
            get :items_index, filter: "new_activity"
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @assignment2.id
          end

          context "date range" do
            it "should not return items before the specified start_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.ago)
              dt.change_all_read_state("unread", @student)
              get :items_index, filter: "new_activity", start_date: 1.week.from_now.to_date.to_s
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 0
            end

            it "should not return items after the specified end_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.from_now)
              dt.change_all_read_state("unread", @student)
              get :items_index, filter: "new_activity", end_date: 1.week.ago.to_date.to_s
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 0
            end

            it "should return items within the start_date and end_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @student, todo_date: Time.zone.now)
              dt.change_all_read_state("unread", @student)
              get :items_index, filter: "new_activity",
                                start_date: 1.week.ago.to_date.to_s,
                                end_date: 1.week.from_now.to_date.to_s
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.map { |i| i["plannable_id"] }).to be_include dt.id
            end
          end

          context "discussion topic read/unread states" do
            before :once do
              discussion_topic_model context: @course
              @topic.todo_date = Time.zone.now
              @topic.save!
            end

            it "should return new discussion topics" do
              get :items_index, filter: "new_activity"
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.first["plannable"]["id"]).to eq @topic.id
            end

            it "should not return read discussion topics" do
              @topic.change_read_state("read", @student)
              get :items_index, filter: "new_activity"
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 0
            end

            it "should return discussion topics with unread replies" do
              expect(@topic.unread_count(@student)).to eq 0
              @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @student)
              @reply = @entry.reply_from(:user => @teacher, :text => "ohai!")
              @topic.reload
              expect(@topic.unread?(@student)).to eq true
              expect(@topic.unread_count(@student)).to eq 1

              get :items_index, filter: "new_activity"
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.first["plannable"]["id"]).to eq @topic.id
            end
          end
        end
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #show" do
        it "returns http success" do
          get :show, id: @planner_override.id
          expect(response).to have_http_status(:success)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          expect(@planner_override.marked_complete).to be_falsey
          put :update, id: @planner_override.id, marked_complete: true
          expect(response).to have_http_status(:success)
          expect(@planner_override.reload.marked_complete).to be_truthy
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, plannable_type: "assignment", plannable_id: @assignment2.id, marked_complete: true
          expect(response).to have_http_status(:created)
          expect(PlannerOverride.where(user_id: @student.id).count).to be 2
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, id: @planner_override.id
          expect(response).to have_http_status(:success)
          expect(@planner_override.reload).to be_deleted
        end
      end
    end
  end
end
