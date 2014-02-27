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
require File.expand_path(File.dirname(__FILE__) + '/../../../models/quizzes/quiz_statistics/item_analysis/common')

describe Quizzes::QuizReportsController, type: :request do
  describe "POST /courses/:course_id/quizzes/:quiz_id/reports" do
    before do
      teacher_in_course(:active_all => true)
      @me = @user
      simple_quiz_with_submissions %w{T T T}, %w{T T T}, %w{T F F}, %w{T F T}, :user => @user, :course => @course
      @user = @me
    end

    it "should create a new report" do
      Quizzes::QuizStatistics.count.should == 0
      json = api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reports",
                      {:controller => "quizzes/quiz_reports", :action => "create", :format => "json", :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s},
                      :quiz_report => {:report_type => "item_analysis"})
      Quizzes::QuizStatistics.count.should == 1
      json['id'].should == Quizzes::QuizStatistics.first.id
    end

    it "should reuse an existing report" do
      @quiz.statistics_csv('item_analysis')
      Quizzes::QuizStatistics.count.should == 1
      json = api_call(:post, "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/reports",
                      {:controller => "quizzes/quiz_reports", :action => "create", :format => "json", :course_id => @course.id.to_s, :quiz_id => @quiz.id.to_s},
                      :quiz_report => {:report_type => "item_analysis"})
      Quizzes::QuizStatistics.count.should == 1
      json['id'].should == Quizzes::QuizStatistics.first.id
    end
  end
end
