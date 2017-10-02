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

describe PlannerNotesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course_1 = @course
    course_with_student(user: @student, active_all: true)
    @course_2 = @course
    @course_1.root_account.enable_feature!(:student_planner)
    @course_2.root_account.enable_feature!(:student_planner)
    @student_note = planner_note_model(user: @student, todo_date: (1.week.from_now))
    @teacher_note = planner_note_model(user: @teacher, todo_date: (1.week.from_now))
    @course_1_note = planner_note_model(user: @student, todo_date: (1.week.ago), course: @course_1)
    @course_2_note = planner_note_model(user: @student, todo_date: (3.weeks.ago), course: @course_2)
  end

  context "unauthenticated" do
    it "should return unauthorized" do
      get :index
      assert_unauthorized

      post :create, params: {:title => "thing",
                     :todo_date => 1.day.from_now}
      assert_unauthorized
    end
  end

  context "authenticated" do
    context "as student" do
      before :each do
        user_session(@student)
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to have_http_status(:success)
        end

        it "filters by context codes when specified" do
          get :index, params: {context_codes: ["course_#{@course_1.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 1
          expect(course_notes.first["id"]).to eq @course_1_note.id

          get :index, params: {context_codes: ["course_#{@course_2.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 1
          expect(course_notes.first["id"]).to eq @course_2_note.id
        end

        it "filters by start and end dates when specified" do
          get :index, params: {start_date: 2.weeks.ago.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 2
          expect(all_notes.pluck("id").sort).to eq [@student_note.id, @course_1_note.id].sort

          get :index, params: {end_date: 1.day.from_now.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 2
          expect(all_notes.pluck("id").sort).to eq [@course_1_note.id, @course_2_note.id].sort

          get :index, params: {start_date: 4.weeks.ago.to_date.to_s, end_date: 2.weeks.from_now.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 3
          expect(all_notes.pluck("id").sort).to eq [@student_note.id, @course_1_note.id, @course_2_note.id].sort
        end

        it 'should 400 for bad dates' do
          get :index, params: {start_date: '123-456-7890', end_date: '98765-43210'}
          expect(response.code).to eql '400'
          json = json_parse(response.body)
          expect(json['errors']['start_date']).to eq 'Invalid date or invalid datetime for start_date'
          expect(json['errors']['end_date']).to eq 'Invalid date or invalid datetime for end_date'
        end
      end

      describe "GET #show" do
        it "returns http success for accessing your notes" do
          get :show, params: {id: @student_note.id}
          expect(response).to have_http_status(:success)
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = planner_note_model(user: u, todo_date: 1.week.from_now)
          get :show, params: {id: u_note.id}
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, params: {id: @student_note.id, title: updated_title}
          expect(response).to have_http_status(:success)
          expect(@student_note.reload.title).to eq updated_title
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @student.id).count).to eq 4
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, params: {id: @student_note.id}
          expect(response).to have_http_status(:success)
          expect(@student_note.reload).to be_deleted
        end
      end
    end

    context "as teacher" do
      before :each do
        user_session(@teacher)
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #show" do
        it "returns http success" do
          get :show, params: {id: @teacher_note.id}
          expect(response).to have_http_status(:success)
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = u.planner_notes.create(
            :title => "Other User's Note",
            :details => "Other Details",
            :todo_date => 1.week.from_now
          )
          get :show, params: {id: u_note.id}
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, params: {id: @teacher_note.id, title: updated_title}
          expect(response).to have_http_status(:success)
          expect(@teacher_note.reload.title).to eq updated_title
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @teacher.id).count).to be 2
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, params: {id: @teacher_note.id}
          expect(response).to have_http_status(:success)
          expect(@teacher_note.reload).to be_deleted
        end
      end
    end
  end
end
