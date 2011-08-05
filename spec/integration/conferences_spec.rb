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

describe ConferencesController do
    before(:all) do
    WebConference.instance_eval do
      def plugins
        [OpenObject.new(:id => "wimba", :settings => {:domain => "wimba.test"}, :valid_settings? => true, :enabled? => true)]
      end
    end
  end
  after(:all) do
    WebConference.instance_eval do
      def plugins; Canvas::Plugin.all_for_tag(:web_conferencing); end
    end
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
    response.should be_redirect
    @conference = WebConference.first
    Set.new(Message.all.map(&:user)).should == Set.new([@teacher, @student1, @student2])

    @student3 = student_in_course(:active_all => true, :user => user_with_pseudonym(:username => "student3@example.com")).user
    @student3.register!
    put "/courses/#{@course.id}/conferences/#{@conference.id}", { :web_conference => { "title" => "moar" }, :user => { @student3.id => '1' } }
    response.should be_redirect
    Set.new(Message.all.map(&:user)).should == Set.new([@teacher, @student1, @student2, @student3])
  end
end
