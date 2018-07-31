
#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe 'Submissions Comment API', type: :request do

  describe '#create_file' do
    before :once do
      teacher_in_course active_all: true
      student_in_course active_all: true
      @assignment = @course.assignments.create! name: "blah",
        submission_types: "online_upload"
    end

    include_examples "file uploads api"
    def has_query_exemption?; false; end

    def preflight(preflight_params)
      api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
      {controller: "submission_comments_api", action: "create_file",
       format: "json", course_id: @course.to_param,
       assignment_id: @assignment.to_param, user_id: @student.to_param},
       preflight_params
    end


    it "checks permissions" do
      orig_course = @course
      course_with_student active_all: true
      @course = orig_course
      raw_api_call :post,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/comments/files",
      {controller: "submission_comments_api", action: "create_file",
       format: "json", course_id: @course.to_param,
       assignment_id: @assignment.to_param, user_id: @student.to_param},
      name: "whatever"
      expect(response).not_to be_success
    end

    it "creates an attachment with the right the user_id" do
      preflight(name: "blah blah blah")
      expect(response).to be_successful
      a = @assignment.attachments.first
      expect(a).not_to be_nil
      expect(a.user_id).to eq @user.id
    end
  end

end
