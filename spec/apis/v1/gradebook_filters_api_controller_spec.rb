# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe GradebookFiltersApiController, type: :request do
  include Api

  context "when fetching all records" do
    before :once do
      @course = course_model
      @course.enable_feature!(:enhanced_gradebook_filters)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })

      @path = "/api/v1/courses/#{@course.id}/gradebook_filters"
      @params = { course_id: @course.id, controller: "gradebook_filters_api", action: "index", format: "json" }
    end

    it "returns correct attributes" do
      json = api_call_as_user(@teacher, :get, @path, @params)
      first = json.first["gradebook_filter"]

      expect(first["id"]).to eq(@gradebook_filter.id)
      expect(first["user_id"]).to eq @teacher.id
      expect(first["course_id"]).to eq @course.id
      expect(first["name"]).to eq @gradebook_filter.name
      expect(first["payload"]).to eq @gradebook_filter.payload
    end

    it "returns all gradebook filters for teacher" do
      json = api_call_as_user(@teacher, :get, @path, @params)
      expect(json.length).to eq @course.gradebook_filters.count

      expect(json.map { |e| e["gradebook_filter"]["id"] }).to eq @course.gradebook_filters.map(&:id)
    end

    it "doesnt return gradebook filters for other users" do
      teacher_2 = user_model
      GradebookFilter.create!(user: teacher_2, course: @course, name: "Second filter", payload: { foo: :bar })
      json = api_call_as_user(@teacher, :get, @path, @params)
      teacher_ids = json.map { |e| e["gradebook_filter"]["user_id"] }.uniq
      expect(teacher_ids.count).to eq 1
      expect(teacher_ids[0]).to eq @teacher.id
    end
  end

  context "when creating a new record" do
    before do
      @course = course_model
      @course.enable_feature!(:enhanced_gradebook_filters)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })

      @path = "/api/v1/courses/#{@course.id}/gradebook_filters"
      @params = { course_id: @course.id,
                  controller: "gradebook_filters_api",
                  action: "create",
                  format: "json" }
    end

    it "creates sucessfully a new gradebook filter with given params" do
      params = @params.merge(gradebook_filter: { name: "new name", payload: { foo: "bar" } })
      json = api_call_as_user(@teacher, :post, @path, params)

      gradebook_filter = GradebookFilter.find json["gradebook_filter"]["id"]
      expect(gradebook_filter.name).to eq "new name"
      expect(gradebook_filter.payload).to eq({ "foo" => "bar" })
      expect(gradebook_filter.user_id).to eq @teacher.id
    end

    it "doesnt let create the gradebook filter when name is null" do
      params = @params.merge(gradebook_filter: { payload: { foo: "bar" } })
      api_call_as_user(@teacher, :post, @path, params)
      expect(response).to have_http_status :bad_request
      expect(response.body).to match(/blank/)
    end

    it "doesnt let create the gradebook filter when payload is null" do
      params = @params.merge(gradebook_filter: { name: "new name", payload: {} })
      api_call_as_user(@teacher, :post, @path, params)
      expect(response).to have_http_status :bad_request
      expect(response.body).to match(/blank/)
    end
  end

  context "when updating a record" do
    before do
      @course = course_model
      @course.enable_feature!(:enhanced_gradebook_filters)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })

      @path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{@gradebook_filter.id}"
      @params = { id: @gradebook_filter.id,
                  course_id: @course.id,
                  controller: "gradebook_filters_api",
                  action: "update",
                  format: "json" }
    end

    it "updates the name" do
      params = @params.merge(gradebook_filter: { name: "new name" })
      json = api_call_as_user(@teacher, :put, @path, params)
      expect(json["gradebook_filter"]["name"]).to eq "new name"
    end

    it "updates the payload" do
      params = @params.merge(gradebook_filter: { payload: { bar: "foo" } })
      json = api_call_as_user(@teacher, :put, @path, params)
      expect(json["gradebook_filter"]["payload"]).to eq({ "bar" => "foo" })
    end

    it "doesnt let update any gradebook filter for other user" do
      teacher_2 = user_model
      gradebook_filter_2 = GradebookFilter.create!(user: teacher_2, course: @course, name: "Second filter", payload: { foo: :bar })
      @course.gradebook_filters << @gradebook_filter
      @course.save

      path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{gradebook_filter_2.id}"
      params = @params.merge(id: gradebook_filter_2.id, gradebook_filter: { name: "new name" })
      api_call_as_user(@teacher, :put, path, params)

      expect(response).to have_http_status :not_found
      expect(response.body).to match(/The specified resource does not exist/)
    end
  end

  context "when getting the details of a record" do
    before do
      @course = course_model
      @course.enable_feature!(:enhanced_gradebook_filters)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })

      @path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{@gradebook_filter.id}"
      @params = { id: @gradebook_filter.id,
                  course_id: @course.id,
                  controller: "gradebook_filters_api",
                  action: "show",
                  format: "json" }
    end

    it "returns correct attributes" do
      json = api_call_as_user(@teacher, :get, @path, @params)

      expect(json["gradebook_filter"]["id"]).to eq(@gradebook_filter.id)
      expect(json["gradebook_filter"]["user_id"]).to eq @teacher.id
      expect(json["gradebook_filter"]["course_id"]).to eq @course.id
      expect(json["gradebook_filter"]["name"]).to eq @gradebook_filter.name
      expect(json["gradebook_filter"]["payload"]).to eq @gradebook_filter.payload
    end

    it "doesnt let show any gradebook filter for other user" do
      teacher_2 = user_model
      gradebook_filter_2 = GradebookFilter.create!(user: teacher_2, course: @course, name: "Second filter", payload: { foo: :bar })
      @course.gradebook_filters << @gradebook_filter
      @course.save

      path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{gradebook_filter_2.id}"
      params = @params.merge(id: gradebook_filter_2.id)
      api_call_as_user(@teacher, :get, path, params)
      expect(response).to have_http_status :not_found
      expect(response.body).to match(/The specified resource does not exist/)
    end
  end

  context "when destroying a record" do
    before do
      @course = course_model
      @course.enable_feature!(:enhanced_gradebook_filters)
      @gradebook_filter = @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })

      @path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{@gradebook_filter.id}"
      @params = { id: @gradebook_filter.id,
                  course_id: @course.id,
                  controller: "gradebook_filters_api",
                  action: "destroy",
                  format: "json" }
    end

    it "deletes an gradebook_filter successfully" do
      api_call_as_user(@teacher, :delete, @path, @params)
      expect(response).to have_http_status :ok
      expect(@course.gradebook_filters.where(user: @teacher).count).to eq 0
    end

    it "doesnt let delete any gradebook filter for other user" do
      teacher_2 = user_model
      gradebook_filter_2 = GradebookFilter.create!(user: teacher_2, course: @course, name: "Second filter", payload: { foo: :bar })
      @course.gradebook_filters << @gradebook_filter
      @course.save

      path = "/api/v1/courses/#{@course.id}/gradebook_filters/#{gradebook_filter_2.id}"
      params = @params.merge(id: gradebook_filter_2.id)
      api_call_as_user(@teacher, :delete, path, params)
      expect(response).to have_http_status :not_found
      expect(response.body).to match(/The specified resource does not exist/)
    end
  end
end
