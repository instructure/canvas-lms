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

describe CollaborationsController, :type => :integration do

  it 'should properly link to the user who posted the collaboration' do
    PluginSetting.create!(:name => 'etherpad', :settings => {})
    course_with_teacher_logged_in :active_all => true, :name => "teacher 1"
    get "/courses/#{@course.id}/collaborations/"
    response.should be_success

    post "/courses/#{@course.id}/collaborations/", { :collaboration => { :collaboration_type => "EtherPad", :title => "My Collab" } }
    response.should be_redirect

    get "/courses/#{@course.id}/collaborations/"
    response.should be_success

    html = Nokogiri::HTML(response.body)
    links = html.css("div.collaboration_#{Collaboration.last.id} a.collaborator_link")
    links.count.should == 1
    link = links.first
    link.attr("href").should == "/courses/#{@course.id}/users/#{@teacher.id}"
    link.text.should == "teacher 1"
  end

  it "shouldn't show concluded users" do
    PluginSetting.create!(:name => 'etherpad', :settings => {})
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym(:username => "teacher@example.com"))
    @teacher = @user
    @teacher.register!
    @enroll1 = student_in_course(:active_all => true, :course => @course, :user => user_with_pseudonym(:username => "student1@example.com"))
    @student1 = @enroll1.user
    @student1.register!
    @enroll2 = student_in_course(:active_all => true, :course => @course, :user => user_with_pseudonym(:username => "student2@example.com"))
    @student2 = @enroll2.user
    @student2.register!

    @enroll1.attributes['workflow_state'].should == 'active'
    @enroll2.attributes['workflow_state'].should == 'active'
    @enroll2.update_attributes('workflow_state' => 'completed')
    @enroll2.attributes['workflow_state'].should == 'completed'

    get "/courses/#{@course.id}/collaborations"
    assigns['users'].member?(@teacher).should be_false
    assigns['users'].member?(@student1).should be_true
    assigns['users'].member?(@student2).should be_false
  end
end
