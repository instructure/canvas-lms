# frozen_string_literal: true

#
# Copyright (C) 2011 Instructure, Inc.
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

describe CustomGradebookColumnsApiController, type: :request do
  include Api
  include Api::V1::CustomGradebookColumn

  before :once do
    course_with_teacher active_all: true
    student_in_course active_all: true
    @user = @teacher
  end

  describe "index" do
    before :once do
      @cols = Array.new(2) do |i|
        @course.custom_gradebook_columns.create! title: "Col #{i + 1}",
                                                 position: i
      end
      c = @course.custom_gradebook_columns.create! title: "deleted col",
                                                   position: 1
      @hidden = @course.custom_gradebook_columns.create! title: "hidden col",
                                                         position: 5,
                                                         hidden: true
      c.destroy
      @user = @teacher
    end

    it "checks permissions" do
      @user = @student
      raw_api_call :get,
                   "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
                   course_id: @course.to_param,
                   action: "index",
                   controller: "custom_gradebook_columns_api",
                   format: "json"
      assert_status(401)
    end

    it "returns the custom columns" do
      json = api_call :get,
                      "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
                      course_id: @course.to_param,
                      action: "index",
                      controller: "custom_gradebook_columns_api",
                      format: "json"
      expect(json).to eq(@cols.map do |c|
        custom_gradebook_column_json(c, @user, session)
      end)
    end

    it "paginates" do
      json = api_call :get,
                      "/api/v1/courses/#{@course.id}/custom_gradebook_columns?per_page=1",
                      course_id: @course.to_param,
                      per_page: "1",
                      action: "index",
                      controller: "custom_gradebook_columns_api",
                      format: "json"
      expect(json).to eq [custom_gradebook_column_json(@cols.first, @user, session)]
    end

    it "returns hidden columns if requested" do
      json = api_call :get,
                      "/api/v1/courses/#{@course.id}/custom_gradebook_columns?include_hidden=1",
                      course_id: @course.to_param,
                      include_hidden: "1",
                      action: "index",
                      controller: "custom_gradebook_columns_api",
                      format: "json"
      expect(json).to eq([*@cols, @hidden].map do |c|
        custom_gradebook_column_json(c, @user, session)
      end)
    end
  end

  describe "create" do
    it "checks permissions" do
      @user = @student
      raw_api_call :post,
                   "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
                   { course_id: @course.to_param,
                     action: "create",
                     controller: "custom_gradebook_columns_api",
                     format: "json" },
                   "column[title]" => "Blah blah blah"
      assert_status(401)
    end

    it "creates a column" do
      json = api_call :post,
                      "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
                      { course_id: @course.to_param,
                        action: "create",
                        controller: "custom_gradebook_columns_api",
                        format: "json" },
                      "column[title]" => "Blah blah blah",
                      "column[position]" => 1,
                      "column[read_only]" => true
      expect(response).to be_successful
      expect(CustomGradebookColumn.find(json["id"])).not_to be_nil
    end
  end

  describe "update" do
    before(:once) { @col = @course.custom_gradebook_columns.create! title: "Foo" }

    it "checks permissions" do
      @user = @student
      raw_api_call :put,
                   "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
                   { course_id: @course.to_param,
                     id: @col.to_param,
                     action: "update",
                     controller: "custom_gradebook_columns_api",
                     format: "json" },
                   "column[title]" => "Bar"
      assert_status(401)
      expect(@col.reload.title).to eq "Foo"
    end

    it "works" do
      json = api_call :put,
                      "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
                      { course_id: @course.to_param,
                        id: @col.to_param,
                        action: "update",
                        controller: "custom_gradebook_columns_api",
                        format: "json" },
                      "column[title]" => "Bar",
                      "column[read_only]" => true
      expect(response).to be_successful
      expect(json["title"]).to eq "Bar"
      expect(json["read_only"]).to be(true)
      expect(@col.reload.title).to eq "Bar"
    end
  end

  describe "delete" do
    before :once do
      @col = @course.custom_gradebook_columns.create! title: "Foo"
    end

    it "checks permissions" do
      @user = @student
      raw_api_call :delete,
                   "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
                   course_id: @course.to_param,
                   id: @col.to_param,
                   action: "destroy",
                   controller: "custom_gradebook_columns_api",
                   format: "json"
      assert_status(401)
    end

    it "works" do
      api_call :delete,
               "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
               course_id: @course.to_param,
               id: @col.to_param,
               action: "destroy",
               controller: "custom_gradebook_columns_api",
               format: "json"
      expect(response).to be_successful
      expect(@col.reload).to be_deleted
    end

    it "lets you toggle the hidden state" do
      api_call :put,
               "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
               { course_id: @course.to_param,
                 id: @col.to_param,
                 action: "update",
                 controller: "custom_gradebook_columns_api",
                 format: "json" },
               "column[hidden]" => "yes"
      expect(response).to be_successful
      expect(@col.reload).to be_hidden

      api_call :put,
               "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
               { course_id: @course.to_param,
                 id: @col.to_param,
                 action: "update",
                 controller: "custom_gradebook_columns_api",
                 format: "json" },
               "column[hidden]" => "no"
      expect(response).to be_successful
      expect(@col.reload).not_to be_hidden
    end
  end

  describe "reorder" do
    it "works" do
      names = %w[A B C]
      c1, c2, c3 = Array.new(3) do |i|
        c = @course.custom_gradebook_columns.build(title: names.shift)
        c.position = i
        c.save!
        c
      end
      expect(@course.custom_gradebook_columns).to eq [c1, c2, c3]

      api_call :post,
               "/api/v1/courses/#{@course.id}/custom_gradebook_columns/reorder",
               { course_id: @course.to_param,
                 action: "reorder",
                 controller: "custom_gradebook_columns_api",
                 format: "json" },
               order: [c3.id, c1.id, c2.id]
      expect(response).to be_successful

      expect(@course.custom_gradebook_columns.reload).to eq [c3, c1, c2]
    end
  end
end
