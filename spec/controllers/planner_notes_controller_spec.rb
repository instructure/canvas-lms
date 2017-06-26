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
    @course.root_account.enable_feature!(:student_planner)
    @student_note = @student.planner_notes.create(
      :title => "This is a student note",
      :details => "stuff about stuff about my homeworks",
      :todo_date => Time.zone.now + 1.week
    )
    @teacher_note = @teacher.planner_notes.create(
      :title => "This is a teacher note",
      :details => "stuff about stuff about grading",
      :todo_date => Time.zone.now + 1.week
    )
  end

  context "unauthenticated" do
    it "should return unauthorized" do
      get :index
      assert_unauthorized

      post :create, :title => "thing",
                     :todo_date => Time.zone.now + 1.day
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
      end

      describe "GET #show" do
        it "returns http success for accessing your notes" do
          get :show, id: @student_note.id
          expect(response).to have_http_status(:success)
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = u.planner_notes.create(
            :title => "Other User's Note",
            :details => "Other Details",
            :todo_date => Time.zone.now + 1.week
          )
          get :show, id: u_note.id
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, id: @student_note.id, title: updated_title
          expect(response).to have_http_status(:success)
          expect(@student_note.reload.title).to eq updated_title
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, title: "A title about things", details: "Details about now", todo_date: Time.zone.now + 1.day
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @student.id).count).to be 2
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, id: @student_note.id
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
          get :show, id: @teacher_note.id
          expect(response).to have_http_status(:success)
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = u.planner_notes.create(
            :title => "Other User's Note",
            :details => "Other Details",
            :todo_date => Time.zone.now + 1.week
          )
          get :show, id: u_note.id
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, id: @teacher_note.id, title: updated_title
          expect(response).to have_http_status(:success)
          expect(@teacher_note.reload.title).to eq updated_title
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, title: "A title about things", details: "Details about now", todo_date: Time.zone.now + 1.day
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @teacher.id).count).to be 2
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, id: @teacher_note.id
          expect(response).to have_http_status(:success)
          expect(@teacher_note.reload).to be_deleted
        end
      end
    end
  end
end
