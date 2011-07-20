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

describe CoursesController, :type => :integration do
  before do
    course_with_teacher(:active_all => true)
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
  end
  
  it "should accept access_token" do
    @token = @user.access_tokens.create!(:purpose => "test")

    @token.last_used_at.should be_nil
    
    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=#{@token.token}",
            { :access_token => @token.token, :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 200
    json = JSON.parse(response.body)
    json.should_not be_is_a(Hash)
    json.length.should == 1
    json[0]['id'].should == @user.id
    @token.reload.last_used_at.should_not be_nil
  end
  
  it "should not accept an invalid access_token" do
    @token = @user.access_tokens.create!(:purpose => "test")

    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=1234",
            { :access_token => "1234", :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == "Invalid access token"
  end
  
  it "should not accept an expired access_token" do
    @token = @user.access_tokens.create!(:purpose => "test", :expires_at => 2.weeks.ago)

    raw_api_call(:get, "/api/v1/courses/#{@course2.id}/students.json?access_token=#{@token.token}",
            { :access_token => @token.token, :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == "Invalid access token"
  end
end
