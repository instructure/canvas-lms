#
# Copyright (C) 2011 - 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe 'Moderated Grades API', type: :request do
  before :once do
    course_with_teacher_logged_in active_all: true
    @course.root_account.allow_feature! :moderated_grading
    @course.enable_feature! :moderated_grading
    @assignment = @course.assignments.create! name: "asdf"
    @assignment.update_attribute :moderated_grading, true
    @student1, @student2 = n_students_in_course(2)
    @user = @teacher
    @assignment.moderated_grading_selections.create! student: @student1
  end

  describe '#index' do
    it 'returns moderated_grading_selections' do
      json = api_call :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/moderated_students",
      {controller: 'moderation_set', action: 'index',
       format: 'json', course_id: @course.id, assignment_id: @assignment.id}
      expect(response).to be_success
      expect(json.size).to eq 1
      expect(json.first["id"]).to eq @student1.id
    end

    it 'requires moderate_grades permissions' do
      @user = @student1
      raw_api_call :get,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/moderated_students",
      {controller: 'moderation_set', action: 'index',
       format: 'json', course_id: @course.id, assignment_id: @assignment.id}
      expect(response.status).to eq 401
    end
  end

  describe 'POST create' do
    it "creates student selections" do
      json = api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/moderated_students",
        {controller: 'moderation_set', action: 'create',
         format: 'json', course_id: @course.id, assignment_id: @assignment.id},
        student_ids: [@student2.id]

      expect(response).to be_success
      expect(json.size).to eq 1
      expect(json.first["id"]).to eq @student2.id
    end

    it "doesn't make duplicate selections" do
      json = api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/moderated_students",
        {controller: 'moderation_set', action: 'create',
         format: 'json', course_id: @course.id, assignment_id: @assignment.id},
        student_ids: [@student1.id, @student2.id]

      expect(response).to be_success
      expect(json.size).to eq 1
      expect(json.first["id"]).to eq @student2.id
    end

    it 'requires moderate_grades permissions' do
      @user = @student1
      raw_api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/moderated_students",
        {controller: 'moderation_set', action: 'create',
         format: 'json', course_id: @course.id, assignment_id: @assignment.id},
        student_ids: [@student1.id, @student2.id]
      expect(response.status).to eq 401
    end
  end
end
