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

describe TabsController, :type => :integration do
  describe 'index' do
    it 'should list navigation tabs for a course' do
      course_with_teacher_logged_in(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})
      json.should == [
        {
          "id" => "home",
          "html_url" => "/courses/#{@course.id}",
          "type" => "internal",
          "label" => "Home"
        },
        {
          "id" => "announcements",
          "label" => "Announcements",
          "html_url" => "/courses/#{@course.id}/announcements",
          "type" => "internal"
        },
        {
          "id" => "assignments",
          "html_url" => "/courses/#{@course.id}/assignments",
          "label" => "Assignments",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/courses/#{@course.id}/discussion_topics",
          "label" => "Discussions",
          "type" => "internal"
        },
        {
          "id" => "grades",
          "html_url" => "/courses/#{@course.id}/grades",
          "label" => "Grades",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/courses/#{@course.id}/users",
          "label" => "People",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/courses/#{@course.id}/wiki",
          "label" => "Pages",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/courses/#{@course.id}/files",
          "label" => "Files",
          "type" => "internal"
        },
        {
          "id" => "syllabus",
          "html_url" => "/courses/#{@course.id}/assignments/syllabus",
          "label" => "Syllabus",
          "type" => "internal"
        },
        {
          "id" => "outcomes",
          "html_url" => "/courses/#{@course.id}/outcomes",
          "label" => "Outcomes",
          "type" => "internal"
        },
        {
          "id" => "quizzes",
          "html_url" => "/courses/#{@course.id}/quizzes",
          "label" => "Quizzes",
          "type" => "internal"
        },
        {
          "id" => "modules",
          "html_url" => "/courses/#{@course.id}/modules",
          "label" => "Modules",
          "type" => "internal"
        },
        {
          "id" => "settings",
          "html_url" => "/courses/#{@course.id}/settings",
          "label" => "Settings",
          "type" => "internal"
        }
      ]
    end
    
    it 'should list navigation tabs for a course' do
      course_with_teacher_logged_in(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :course_id => @course.to_param, :format => 'json'},
                      { :include => ['external']})
      json.should == [
        {
          "id" => "home",
          "html_url" => "/courses/#{@course.id}",
          "type" => "internal",
          "label" => "Home"
        },
        {
          "id" => "announcements",
          "label" => "Announcements",
          "html_url" => "/courses/#{@course.id}/announcements",
          "type" => "internal"
        },
        {
          "id" => "assignments",
          "html_url" => "/courses/#{@course.id}/assignments",
          "label" => "Assignments",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/courses/#{@course.id}/discussion_topics",
          "label" => "Discussions",
          "type" => "internal"
        },
        {
          "id" => "grades",
          "html_url" => "/courses/#{@course.id}/grades",
          "label" => "Grades",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/courses/#{@course.id}/users",
          "label" => "People",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/courses/#{@course.id}/wiki",
          "label" => "Pages",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/courses/#{@course.id}/files",
          "label" => "Files",
          "type" => "internal"
        },
        {
          "id" => "syllabus",
          "html_url" => "/courses/#{@course.id}/assignments/syllabus",
          "label" => "Syllabus",
          "type" => "internal"
        },
        {
          "id" => "outcomes",
          "html_url" => "/courses/#{@course.id}/outcomes",
          "label" => "Outcomes",
          "type" => "internal"
        },
        {
          "id" => "quizzes",
          "html_url" => "/courses/#{@course.id}/quizzes",
          "label" => "Quizzes",
          "type" => "internal"
        },
        {
          "id" => "modules",
          "html_url" => "/courses/#{@course.id}/modules",
          "label" => "Modules",
          "type" => "internal"
        },
        {
          "id" => "settings",
          "html_url" => "/courses/#{@course.id}/settings",
          "label" => "Settings",
          "type" => "internal"
        }
      ]
    end

    it 'should list navigation tabs for a group' do
      group_with_user_logged_in(:active_all => true)
      json = api_call(:get, "/api/v1/groups/#{@group.id}/tabs",
                      { :controller => 'tabs', :action => 'index', :group_id => @group.to_param, :format => 'json'})
      json.should == [
        {
          "id" => "home",
          "html_url" => "/groups/#{@group.id}",
          "type" => "internal",
          "label" => "Home"
        },
        {
          "id" => "announcements",
          "label" => "Announcements",
          "html_url" => "/groups/#{@group.id}/announcements",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/groups/#{@group.id}/wiki",
          "label" => "Pages",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/groups/#{@group.id}/users",
          "label" => "People",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/groups/#{@group.id}/discussion_topics",
          "label" => "Discussions",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/groups/#{@group.id}/files",
          "label" => "Files",
          "type" => "internal"
        }
      ]
    end
  end
end
