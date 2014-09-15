#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../file_uploads_spec_helper')

describe Quizzes::QuizSubmissionFilesController, type: :request do
  context "quiz submissions file uploads" do
    before :once do
      course_with_student :active_all => true
      @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
      @quiz.did_edit!
      @quiz.offer!

      s = @quiz.generate_submission(@student)
    end

    include_examples "file uploads api"

    def preflight(preflight_params)
      json = api_call :post,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/self/files",
        {
          :controller => "quizzes/quiz_submission_files",
          :action => "create",
          :format => "json",
          :course_id => @course.to_param,
          :quiz_id => @quiz.to_param
        },
        preflight_params
      # account for JSON API style return
      json['attachments'] ? json['attachments'][0] : json
    end

    def has_query_exemption?
      false
    end
  end

end
