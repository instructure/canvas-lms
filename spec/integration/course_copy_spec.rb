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

describe ContentImportsController, :type => :integration do

  describe "post 'copy_course_content'" do
    it "should copy course" do
      course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
      @copy_from = @course
      group = @course.assignment_groups.create!(:name => 'group1')
      @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => group)
      @copy_from.discussion_topics.create!(:title => "Topic 1", :message => "<p>watup?</p>")

      course_with_teacher(:active_all => true, :name => 'whatever', :user => @user)
      @copy_to = @course

      post "/courses/#{@copy_to.id}/imports/copy", :source_course => @copy_from.id, :copy => {:all_assignments => 1}
      response.should be_success
      data = json_parse

      api_call(:get, data['status_url'], { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
      json_parse['workflow_state'].should == 'created'

      run_jobs

      api_call(:get, data['status_url'], { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
      json_parse['workflow_state'].should == 'completed'

      @copy_to.reload
      @copy_to.assignments.count.should == 1
      @copy_to.discussion_topics.count.should == 0
    end
  end

end
