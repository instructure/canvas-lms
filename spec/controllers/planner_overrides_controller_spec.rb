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
#

require_relative '../sharding_spec_helper'

describe PlannerOverridesController do
  include PlannerHelper

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

      post :create, params: {:plannable_type => "assignment",
                     :plannable_id => @assignment.id,
                     :marked_complete => false}
      assert_unauthorized
    end
  end

  context "as student" do
    before :each do
      user_session(@student)
      @course.root_account.enable_feature!(:student_planner)
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET #show" do
      it "returns http success" do
        get :show, params: {id: @planner_override.id}
        expect(response).to have_http_status(:success)
      end
    end

    describe "PUT #update" do
      it "returns http success" do
        expect(@planner_override.marked_complete).to be_falsey
        put :update, params: {id: @planner_override.id, marked_complete: true, dismissed: true}
        expect(response).to have_http_status(:success)
        expect(@planner_override.reload.marked_complete).to be_truthy
        expect(@planner_override.dismissed).to be_truthy
      end

      it "invalidates the planner cache" do
        @current_user = @student
        expect(Rails.cache).to receive(:delete).with(planner_meta_cache_key)
        put :update, params: {id: @planner_override.id, marked_complete: true, dismissed: true}
      end
    end

    describe "POST #create" do
      it "returns http success" do
        post :create, params: {plannable_type: "assignment", plannable_id: @assignment2.id, marked_complete: true}
        expect(response).to have_http_status(:created)
        expect(PlannerOverride.where(user_id: @student.id).count).to be 2
      end

      it "invalidates the planner cache" do
        @current_user = @student
        expect(Rails.cache).to receive(:delete).with(planner_meta_cache_key)
        post :create, params: {plannable_type: "assignment", plannable_id: @assignment2.id, marked_complete: true}
      end

      it "should save announcement overrides with a plannable_type of discussion_topic" do
        announcement_model(context: @course)
        post :create, params: {plannable_type: 'announcement', plannable_id: @a.id, user_id: @student.id, marked_complete: true}
        json = json_parse(response.body)
        expect(json["plannable_type"]).to eq 'discussion_topic'
      end
    end

    describe "DELETE #destroy" do
      it "returns http success" do
        delete :destroy, params: {id: @planner_override.id}
        expect(response).to have_http_status(:success)
        expect(@planner_override.reload).to be_deleted
      end

      it "invalidates the planner cache" do
        @current_user = @student
        expect(Rails.cache).to receive(:delete).with(planner_meta_cache_key)
        delete :destroy, params: {id: @planner_override.id}
      end
    end
  end
end
