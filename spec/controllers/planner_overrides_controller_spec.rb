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
                                                visible: true,
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

      post :create, :plannable_type => "Assignment",
                     :plannable_id => @assignment.id,
                     :visible => true
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
          page = response_json.first
          expect(page["plannable_type"]).to eq 'wiki_page'
          expect(page["type"]).to eq 'viewing'
        end

        it "should show planner notes for the user" do
          planner_note_model(course: @course)
          get :items_index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 3
          note = response_json.select { |i| i["plannable_type"] == 'planner_note' }.first
          expect(note["type"]).to eq 'viewing'
          expect(note["plannable"]["title"]).to eq @planner_note.title
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
          expect(@planner_override.visible).to be_truthy
          put :update, id: @planner_override.id, visible: false
          expect(response).to have_http_status(:success)
          expect(@planner_override.reload.visible).to be_falsey
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, plannable_type: "Assignment", plannable_id: @assignment2.id, visible: false
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
