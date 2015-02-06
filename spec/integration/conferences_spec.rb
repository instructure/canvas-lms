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

describe ConferencesController, type: :request do
  before do
    WebConference.stubs(:plugins).returns([web_conference_plugin_mock("wimba", {:domain => "wimba.test"})])
  end

  it "should notify participants" do
    notification_model(:name => "Web Conference Invitation")
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym)
    @teacher = @user
    @teacher.register!
    @student1 = student_in_course(:active_all => true, :user => user_with_pseudonym(:username => "student1@example.com")).user
    @student1.register!
    @student2 = student_in_course(:active_all => true, :user => user_with_pseudonym(:username => "student2@example.com")).user
    @student2.register!

    post "/courses/#{@course.id}/conferences", { :web_conference => {"duration"=>"60", "conference_type"=>"Wimba", "title"=>"let's chat", "description"=>""}, :user => { "all" => "1" } }
    expect(response).to be_redirect
    @conference = WebConference.first
    expect(Set.new(Message.all.map(&:user))).to eq Set.new([@teacher, @student1, @student2])

    @student3 = student_in_course(:active_all => true, :user => user_with_pseudonym(:username => "student3@example.com")).user
    @student3.register!
    put "/courses/#{@course.id}/conferences/#{@conference.id}", { :web_conference => { "title" => "moar" }, :user => { @student3.id => '1' } }
    expect(response).to be_redirect
    expect(Set.new(Message.all.map(&:user))).to eq Set.new([@teacher, @student1, @student2, @student3])
  end

  it "should find the correct conferences for group news feed" do
    course_with_student_logged_in(:active_all => true, :user => user_with_pseudonym)
    @group = @course.groups.create!(:name => "some group")
    @group.add_user(@user)

    course_conference = @course.web_conferences.create!(:conference_type => 'Wimba', :user => @user) { |c| c.start_at = Time.now }
    group_conference = @group.web_conferences.create!(:conference_type => 'Wimba', :user => @user) { |c| c.start_at = Time.now }
    course_conference.add_initiator(@user)
    group_conference.add_initiator(@user)

    get "/courses/#{@course.id}/groups/#{@group.id}"
    expect(response).to be_success
    expect(assigns['current_conferences'].map(&:id)).to eq [group_conference.id]
  end

  it "shouldn't show concluded users" do
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym(:username => "teacher@example.com"))
    @teacher = @user
    @teacher.register!
    @enroll1 = student_in_course(:active_all => true, :course => @course, :user => user_with_pseudonym(:username => "student1@example.com"))
    @student1 = @enroll1.user
    @student1.register!
    @enroll2 = student_in_course(:active_all => true, :course => @course, :user => user_with_pseudonym(:username => "student2@example.com"))
    @student2 = @enroll2.user
    @student2.register!

    expect(@enroll1.attributes['workflow_state']).to eq 'active'
    expect(@enroll2.attributes['workflow_state']).to eq 'active'
    @enroll2.update_attributes('workflow_state' => 'completed')
    expect(@enroll2.attributes['workflow_state']).to eq 'completed'

    get "/courses/#{@course.id}/conferences"
    expect(assigns['users'].member?(@teacher)).to be_falsey
    expect(assigns['users'].member?(@student1)).to be_truthy
    expect(assigns['users'].member?(@student2)).to be_falsey
  end
end
