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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_feedback" do
  it "should render" do
    course_with_student
    assigns[:current_user] = @user
    assigns[:domain_root_account] = @course.root_account
    assigns[:domain_root_account].stubs(:custom_feedback_links).returns([])
    render :partial => "shared/feedback"
    response.should_not be_nil
    html = Nokogiri::HTML(response.body)
    html.css('li').length.should == 3
  end
  
  it "should render with custom links" do
    course_with_student
    assigns[:current_user] = @user
    assigns[:domain_root_account] = @course.root_account
    assigns[:domain_root_account].stubs(:custom_feedback_links).returns([
      {
        :url => "http://www.google.com",
        :title => "Google",
        :classes => "student google"
      },
      {
        :url => "http://www.bing.com",
        :title => "Bing",
        :classes => "teacher bing"
      }
    ])
    render :partial => "shared/feedback"
    response.should_not be_nil
    html = Nokogiri::HTML(response.body)
    html.css('li').length.should == 5
    html.css('li.google').length.should == 1
    html.css('li.bing').length.should == 1
  end
end

