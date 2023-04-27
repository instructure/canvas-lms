# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe BlackoutDatesController do
  before :once do
    course_with_teacher(active_all: true)

    @course.enable_course_paces = true
    @course.save!
    @course.account.enable_feature!(:course_paces)

    @blackout_date = @course.blackout_dates.create!(start_date: "2022-02-14", end_date: "2022-02-18", event_title: "Test Week Off")
  end

  before do
    user_session(@teacher)
  end

  describe "GET #index" do
    it "loads all the blackout dates for the context" do
      get :index, params: { course_id: @course.id }

      expect(response).to be_successful
      expect(assigns[:blackout_dates]).to include(@blackout_date)
    end

    it "returns a json response if using the API" do
      get :index, format: :json, params: { course_id: @course.id }

      expect(response).to be_successful
      json_response = response.parsed_body
      expect(json_response).to eq([@blackout_date.as_json(include_root: false)].as_json)
    end
  end

  describe "GET #show" do
    it "loads the blackout date" do
      get :show, params: { course_id: @course.id, id: @blackout_date.id }

      expect(response).to be_successful
      expect(assigns[:blackout_date]).to eq(@blackout_date)
    end
  end

  describe "GET #new" do
    it "loads an unsaved blackout date" do
      get :new, params: { course_id: @course.id }

      expect(response).to be_successful
      blackout_date = assigns[:blackout_date]
      expect(blackout_date.id).to be_nil
      expect(blackout_date.context_id).to eq(@course.id)
      expect(blackout_date.context_type).to eq("Course")
    end
  end

  describe "POST #create" do
    it "creates a new blackout date" do
      post :create, params: { course_id: @course.id, blackout_date: { start_date: "2022-01-01", end_date: "2022-01-02", event_title: "Test" } }

      expect(response).to be_successful
      json_response = response.parsed_body
      blackout_date = json_response["blackout_date"]
      expect(blackout_date["id"]).not_to be_nil
      expect(blackout_date["context_id"]).to eq(@course.id)
      expect(blackout_date["context_type"]).to eq("Course")
      expect(blackout_date["start_date"]).to eq("2022-01-01")
      expect(blackout_date["end_date"]).to eq("2022-01-02")
      expect(blackout_date["event_title"]).to eq("Test")
    end

    it "doesn't allow end_date to be after start_date" do
      post :create, params: { course_id: @course.id, blackout_date: { start_date: "2022-02-01", end_date: "2022-01-01", event_title: "Test" } }

      expect(response).not_to be_successful
      json_response = response.parsed_body
      expect(json_response["errors"]).to eq(["End date can't be before start date"])
    end
  end

  describe "PUT #update" do
    it "updates a blackout date" do
      put :update, params: { course_id: @course.id, id: @blackout_date.id, blackout_date: { start_date: "2022-01-01", end_date: "2022-01-02", event_title: "Test" } }

      expect(response).to be_successful
      json_response = response.parsed_body
      blackout_date = json_response["blackout_date"]
      expect(blackout_date["id"]).to eq(@blackout_date.id)
      expect(blackout_date["context_id"]).to eq(@course.id)
      expect(blackout_date["context_type"]).to eq("Course")
      expect(blackout_date["start_date"]).to eq("2022-01-01")
      expect(blackout_date["end_date"]).to eq("2022-01-02")
      expect(blackout_date["event_title"]).to eq("Test")
    end

    it "doesn't allow end_date to be after start_date" do
      post :create, params: { course_id: @course.id, id: @blackout_date.id, blackout_date: { start_date: "2022-02-01", end_date: "2022-01-01", event_title: "Test" } }

      expect(response).not_to be_successful
      json_response = response.parsed_body
      expect(json_response["errors"]).to eq(["End date can't be before start date"])
    end
  end

  describe "DELETE #destroy" do
    it "deletes the blackout date" do
      get :destroy, params: { course_id: @course.id, id: @blackout_date.id }

      expect(response).to be_successful
      expect(BlackoutDate.find_by(id: @blackout_date.id)).to be_nil
    end
  end

  describe "PUT #bulk_update" do
    it "syncs the blackout dates with incoming data" do
      blackout_date2 = @course.blackout_dates.create!(start_date: "2022-11-11", end_date: "2022-11-11", event_title: "My birthday")
      put :bulk_update,
          params: {
            course_id: @course.id,
            blackout_dates: [
              { id: blackout_date2.id, start_date: blackout_date2.start_date.iso8601, end_date: blackout_date2.end_date.iso8601, event_title: "update me" },
              { start_date: "2022-05-31", end_date: "2022-09-01", event_title: "summer break" }
            ]
          }
      @course.reload
      blackout_dates = @course.blackout_dates
      expect(response).to be_successful
      # deleted
      expect(blackout_dates.find_by(id: @blackout_date.id)).to be_nil
      # updated
      expect(blackout_dates.find_by(id: blackout_date2.id).event_title).to eq("update me")
      # created
      expect(blackout_dates.find_by(event_title: "summer break")).to_not be_nil
    end
  end
end
