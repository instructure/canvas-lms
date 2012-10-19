#
# Copyright (C) 2012 Instructure, Inc.
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

describe QuizzesApiController, :type => :integration do

  it "should return list of quizzes" do
    teacher_in_course(:active_all => true).user
    quizzes = (0..3).map{ |i| @course.quizzes.create! :title => "quiz_#{i}" }

    json = api_call(:get, "/api/v1/courses/#{@course.id}/quizzes",
                    :controller=>"quizzes_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}")
    
    json.should == quizzes.map do |quiz|
      {"title"=>quiz.title, "id"=>quiz.id, "html_url"=> url_for([@course, quiz])}
    end
  end

end
