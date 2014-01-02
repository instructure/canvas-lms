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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe CustomGradebookColumnsApiController, :type => :integration do
  include Api
  include Api::V1::CustomGradebookColumn

  before do
    course_with_teacher active_all: true
    student_in_course active_all: true
    @user = @teacher
  end

  describe 'index' do
    before do
      @cols = 2.times.map { |i|
        @course.custom_gradebook_columns.create! title: "Col #{i+1}",
                                                 position: i
      }
      c = @course.custom_gradebook_columns.create! title: "deleted col",
                                                   position: 1
      @hidden = @course.custom_gradebook_columns.create! title: "hidden col",
                                                         position: 5,
                                                         hidden: true
      c.destroy
      @user = @teacher
    end

    it 'checks permissions' do
      @user = @student
      raw_api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
        course_id: @course.to_param, action: "index",
        controller: "custom_gradebook_columns_api", format: "json"
      response.status.should == "401 Unauthorized"
    end

    it 'should return the custom columns' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
        course_id: @course.to_param, action: "index",
        controller: "custom_gradebook_columns_api", format: "json"
      json.should == @cols.map { |c|
        custom_gradebook_column_json(c, @user, session)
      }
    end

    it 'should paginate' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns?per_page=1",
        course_id: @course.to_param, per_page: "1", action: "index",
        controller: "custom_gradebook_columns_api", format: "json"
      json.should == [custom_gradebook_column_json(@cols.first, @user, session)]
    end

    it 'returns hidden columns if requested' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns?include_hidden=1",
        course_id: @course.to_param, include_hidden: "1", action: "index",
          controller: "custom_gradebook_columns_api", format: "json"
      json.should == [*@cols, @hidden].map { |c|
        custom_gradebook_column_json(c, @user, session)
      }
    end
  end

  describe 'create' do
    it 'checks permissions' do
      @user = @student
      raw_api_call :post,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
        course_id: @course.to_param, action: "create",
        controller: "custom_gradebook_columns_api", format: "json"
      response.status.should == '401 Unauthorized'
    end

    it 'creates a column' do
      json = api_call :post,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns",
        {course_id: @course.to_param, action: "create",
         controller: "custom_gradebook_columns_api", format: "json"},
        "column[title]" => "Blah blah blah", "column[position]" => 1
      response.should be_success
      CustomGradebookColumn.find(json["id"]).should_not be_nil
    end
  end

  describe 'update' do
    before { @col = @course.custom_gradebook_columns.create! title: "Foo" }

    it 'checks permissions' do
      @user = @student
      raw_api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        {course_id: @course.to_param, id: @col.to_param, action: "update",
         controller: "custom_gradebook_columns_api", format: "json"},
        "column[title]" => "Bar"
      response.status.should == '401 Unauthorized'
      @col.reload.title.should == "Foo"
    end

    it 'works' do
      json = api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        {course_id: @course.to_param, id: @col.to_param, action: "update",
         controller: "custom_gradebook_columns_api", format: "json"},
        "column[title]" => "Bar"
      response.should be_success
      json["title"].should == "Bar"
      @col.reload.title.should == "Bar"
    end
  end

  describe 'delete' do
    before do
      @col = @course.custom_gradebook_columns.create! title: "Foo"
    end

    it 'checks permissions' do
      @user = @student
      raw_api_call :delete,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        course_id: @course.to_param, id: @col.to_param, action: "destroy",
        controller: "custom_gradebook_columns_api", format: "json"
      response.status.should == '401 Unauthorized'
    end

    it 'works' do
      api_call :delete,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        course_id: @course.to_param, id: @col.to_param, action: "destroy",
        controller: "custom_gradebook_columns_api", format: "json"
      response.should be_success
      @col.reload.should be_deleted
    end

    it 'lets you toggle the hidden state' do
      json = api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        {course_id: @course.to_param, id: @col.to_param, action: "update",
         controller: "custom_gradebook_columns_api", format: "json"},
        "column[hidden]" => "yes"
      response.should be_success
      @col.reload.should be_hidden

      json = api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}",
        {course_id: @course.to_param, id: @col.to_param, action: "update",
         controller: "custom_gradebook_columns_api", format: "json"},
        "column[hidden]" => "no"
      response.should be_success
      @col.reload.should_not be_hidden
    end
  end
end
