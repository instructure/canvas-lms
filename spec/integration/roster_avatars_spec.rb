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
require File.expand_path(File.dirname(__FILE__) + '/../apis/api_spec_helper')

describe ContextController, :type => :integration do
  it "should not include user avatars if avatars are not enabled" do
    course_with_student_logged_in(:active_all => true)
    get "/courses/#{@course.id}/users"
    response.should be_success
    page = Nokogiri::HTML(response.body)
    page.css(".roster .user").length.should == 2
    page.css(".roster .user .avatar").length.should == 0
  end
  it "should include user avatars if avatars are enabled" do
    course_with_student_logged_in(:active_all => true)
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    @account.service_enabled?(:avatars).should be_true
    get "/courses/#{@course.id}/users"
    response.should be_success

    page = Nokogiri::HTML(response.body)
    page.css(".roster .user").length.should == 2
    page.css(".roster .user div.avatar").length.should == 2
    page.css(".roster .user div.avatar img")[0]['src'].should match(/\/images\/users\/#{@user.id}/)
    page.css(".roster .user div.avatar img")[1]['src'].should match(/\/images\/users\/#{@teacher.id}/)
    
    @group = @course.groups.create!(:name => "sub-group")
    @group.add_user(@user)
    get "/groups/#{@group.id}/users"
    response.should be_success

    page = Nokogiri::HTML(response.body)
    page.css(".roster .user").length.should == 2
    page.css(".roster .user div.avatar").length.should == 2
    page.css(".roster .user div.avatar img")[0]['src'].should match(/\/images\/users\/#{@user.id}/)
    page.css(".roster .user div.avatar img")[1]['src'].should match(/\/images\/users\/#{@teacher.id}/)
  end
end
