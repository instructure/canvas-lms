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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoController do

  #Delete these examples and add some real ones
  it "should use InfoController" do
    controller.should be_an_instance_of(InfoController)
  end


  describe "POST 'record_error'" do
    it "should be successful" do
      post 'record_error'
      assert_recorded_error
      
      post 'record_error', :error => {:title => 'ugly', :message => 'bacon', :fried_ham => 'stupid'}
      assert_recorded_error
    end

    it "should be successful for teacher feedback too" do
      course_with_student_logged_in(:active_all => true)
      post 'record_error', "feedback_type"=>"teacher", "comments"=>"OHAI", "subject"=>"help me.", "course_id"=>@course.id, "error"=>{"comments"=>"OHAI", "subject"=>"help me.", "backtrace"=>"Posted as a _PROBLEM_", "email"=>""}, "email"=>""
      assert_recorded_error("Thanks for your feedback!  Your teacher has been notified.")
  end
    
  end
  
  def assert_recorded_error(msg = "Thanks for your help!  We'll get right on this")
    flash[:notice].should eql(msg)
    response.should be_redirect
    response.should redirect_to(root_url)
  end
end
