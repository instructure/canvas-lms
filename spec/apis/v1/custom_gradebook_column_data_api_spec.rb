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

describe CustomGradebookColumnDataApiController, type: :request do
  include Api
  include Api::V1::CustomGradebookColumn

  before :once do
    course_with_teacher active_all: true
    s1, s2 = 2.times.map { |i|
      @course.course_sections.create! name: "section #{i}"
    }
    @student1, @student2 = 2.times.map { user_factory(active_all: true) }
    s1.enroll_user @student1, 'StudentEnrollment', 'active'
    s2.enroll_user @student2, 'StudentEnrollment', 'active'

    @ta = user_factory(active_all: true)
    @course.enroll_user @ta, 'TaEnrollment',
      workflow_state: 'active', section: s2,
      limit_privileges_to_course_section: true

    @user = @teacher

    @col = @course.custom_gradebook_columns.create! title: "Notes", position: 1
  end

  describe 'index' do
    before :once do
      [@student1, @student2].each_with_index { |s,i|
        @col.custom_gradebook_column_data.build(content: "Blah #{i}").tap { |d|
          d.user_id = s.id
          d.save!
        }
      }
    end

    it 'checks permissions' do
      @user = @student1
      raw_api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data",
        course_id: @course.to_param, id: @col.to_param, action: "index",
        controller: "custom_gradebook_column_data_api", format: "json"
      assert_status(401)
    end

    it 'only shows students you have permission for' do
      @user = @ta
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data",
        course_id: @course.to_param, id: @col.to_param, action: "index",
        controller: "custom_gradebook_column_data_api", format: "json"
      expect(response).to be_success
      d = @col.custom_gradebook_column_data.where(user_id: @student2.id).first
      expect(json).to eq [custom_gradebook_column_datum_json(d, @user, session)]
    end

    it 'includes students with inactive enrollments' do
      student = user_factory(active_all: true)
      @course.default_section.enroll_user(student, 'StudentEnrollment', 'inactive')
      @col.custom_gradebook_column_data.create!(user_id: student.id, content: "Example Note")
      @user = @teacher
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data",
        course_id: @course.to_param, id: @col.to_param, action: "index",
        controller: "custom_gradebook_column_data_api", format: "json"
      expect(response).to be_success
      expect(json.map {|datum| datum["user_id"]}).to include student.id
    end

    it 'includes students with concluded enrollments' do
      student = user_factory(active_all: true)
      @course.default_section.enroll_user(student, 'StudentEnrollment', 'completed')
      @col.custom_gradebook_column_data.create!(user_id: student.id, content: "Example Note")
      @user = @teacher
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data",
        course_id: @course.to_param, id: @col.to_param, action: "index",
        controller: "custom_gradebook_column_data_api", format: "json"
      expect(response).to be_success
      expect(json.map {|datum| datum["user_id"]}).to include student.id
    end

    it 'returns the column data' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data",
        course_id: @course.to_param, id: @col.to_param, action: "index",
        controller: "custom_gradebook_column_data_api", format: "json"
      expect(response).to be_success
      expect(json).to match_array @col.custom_gradebook_column_data.map { |d|
        custom_gradebook_column_datum_json(d, @user, session)
      }
    end

    it 'can paginate' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data?per_page=1",
        course_id: @course.to_param, id: @col.to_param, per_page: "1",
        action: "index", controller: "custom_gradebook_column_data_api",
        format: "json"
      expect(response).to be_success
      expect(json.size).to eq 1
    end
  end

  describe 'update' do
    def update(student, content)
      api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data/#{student.id}",
        {course_id: @course.to_param, id: @col.to_param,
         user_id: student.to_param, action: "update",
         controller: "custom_gradebook_column_data_api", format: "json"},
        "column_data[content]" => content
    end

    it 'checks permissions' do
      @user = @student1
      raw_api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data/#{@student1.id}",
        {course_id: @course.to_param, id: @col.to_param,
         user_id: @student1.to_param, action: "update",
         controller: "custom_gradebook_column_data_api", format: "json"},
        "column_data[content]" => "haha"

      assert_status(401)
    end

    it 'only lets you make notes for students you can see' do
      @user = @ta

      update(@student2, "asdf")
      expect(response).to be_success

      raw_api_call :put,
        "/api/v1/courses/#{@course.id}/custom_gradebook_columns/#{@col.id}/data/#{@student1.id}",
        {course_id: @course.to_param, id: @col.to_param,
         user_id: @student1.to_param, action: "update",
         controller: "custom_gradebook_column_data_api", format: "json"},
        "column_data[content]" => "jkl;"
      assert_status(404)
    end

    it 'works for students with inactive enrollments' do
      student = user_factory(active_all: true)
      @course.default_section.enroll_user(student, 'StudentEnrollment', 'inactive')
      @user = @teacher
      update(student, "Example Note")
      expect(response).to be_success
      datum = @col.custom_gradebook_column_data.find_by(user_id: student.id)
      expect(datum.content).to eq "Example Note"
    end

    it 'works for hidden custom columns' do
      @col.update!(workflow_state: 'hidden')

      @user = @teacher
      update(@student1, "Example Note")

      expect(response).to be_success
    end

    it 'works for students with concluded enrollments' do
      student = user_factory(active_all: true)
      @course.default_section.enroll_user(student, 'StudentEnrollment', 'completed')
      @user = @teacher
      update(student, "Example Note")
      expect(response).to be_success
      datum = @col.custom_gradebook_column_data.find_by(user_id: student.id)
      expect(datum.content).to eq "Example Note"
    end

    it 'works' do
      json = nil

      check = lambda { |content|
        expect(response).to be_success
        expect(json["content"]).to eq content
        expect(@col.custom_gradebook_column_data.where(user_id: @student1.id)
        .first.reload.content).to eq content
      }

      # create
      json = update(@student1, "blarg")
      check.("blarg")

      # update
      json = update(@student1, "shmarg")
      check.("shmarg")
    end
  end
end
