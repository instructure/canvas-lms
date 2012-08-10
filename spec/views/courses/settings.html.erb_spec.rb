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

describe "courses/settings.html.erb" do
  describe "sis_source_id edit box" do
    before do
      course_with_teacher(:active_all => true)
      @course.sis_source_id = "so_special_sis_id"
      @course.workflow_state = 'claimed'
      @course.save
      assigns[:context] = @course
      assigns[:user_counts] = {}
    end

    it "should not show to teacher" do
      view_context(@course, @user)
      assigns[:current_user] = @user
      render
      response.should have_tag("span.sis_source_id", @course.sis_source_id)
      response.should_not have_tag("input#course_sis_source_id")
    end

    it "should show to sis admin" do
      admin = account_admin_user(:account => @course.root_account)
      view_context(@course, admin)
      assigns[:current_user] = admin
      render
      response.should have_tag("input#course_sis_source_id")
    end

    it "should not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(:account => @course.root_account, :role_changes => {'manage_sis' => false}, :membership_type => "NoSissy")
      view_context(@course, admin)
      assigns[:current_user] = admin
      render
      response.should_not have_tag("input#course_sis_source_id")
    end

    it "should show grade export when enabled" do
      admin = account_admin_user(:account => @course.root_account)
      @course.expects(:allows_grade_publishing_by).with(admin).returns(true)
      view_context(@course, admin)
      assigns[:current_user] = admin
      render
      response.body.should =~ /<a href="#tab-grade-publishing" id="tab-grade-publishing-link">/
      response.body.should =~ /<div id="tab-grade-publishing">/
    end

    it "should not show grade export when disabled" do
      admin = account_admin_user(:account => @course.root_account)
      @course.expects(:allows_grade_publishing_by).with(admin).returns(false)
      view_context(@course, admin)
      assigns[:current_user] = admin
      render
      response.body.should_not =~ /<a href="#tab-grade-publishing" id="tab-grade-publishing-link">/
      response.body.should_not =~ /<div id="tab-grade-publishing">/
    end

  end
end
