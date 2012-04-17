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

describe ContentImportsController, :type => :integration do
  
  describe "show error report links" do
    before (:each) do
      course_with_teacher_logged_in(:active_all => true, :name => 'test', :user => @user)
      cm = ContentMigration.new
      cm.context = @course
      cm.add_warning("warning1")
      cm.add_warning("warning2", "second warning message")
      cm.add_warning("warning3", Exception.new("exceptionforwarning3"))
      @report = ErrorReport.last
      cm.migration_settings[:last_error] = "ErrorReport id: 0000"
      cm.workflow_state = 'imported'
      cm.save!
    end
    
    it "should not show links to error reports to non-site admin" do
      get "/courses/#{@course.id}/imports/list"
      response.body.should =~ /warning1/
      response.body.should =~ /warning2/
      response.body.should_not =~ /second warning message/
      response.body.should =~ /warning3/
      response.body.should_not =~ %r{/error_reports/#{@report.id}}
      response.body.should_not =~ %r{/error_reports/0000}
    end
    
    it "should show error report links to site admin" do
      site_admin_user
      user_session(@user)
  
      get "/courses/#{@course.id}/imports/list"
  
      response.body.should =~ /warning1/
      response.body.should =~ /warning2/
      response.body.should =~ /second warning message/
      response.body.should =~ /warning3/
      response.body.should =~ %r{/error_reports/#{@report.id}}
      response.body.should =~ %r{/error_reports/0000}
    end
  end
  
  describe "download import archive" do
    it "should download for local storage" do
      course_with_teacher_logged_in(:active_all => true, :name => 'test', :user => @user)
      cm = ContentMigration.create!(:context => @course)
      att = Attachment.create!(:filename => 'archive.zip', :display_name => "archive.zip", :uploaded_data => StringIO.new('fake zip!'), :context => cm)
      cm.attachment = att
      cm.workflow_state = 'imported'
      cm.save

      get "/courses/#{@course.id}/imports/#{cm.id}/download_archive"
      response.should be_success
    end
    
    it "should redirect for s3 storage" do
      Attachment.stubs(:s3_storage?).returns(true)
      Attachment.stubs(:local_storage?).returns(false)
      course_with_teacher_logged_in(:active_all => true, :name => 'test', :user => @user)
      cm = ContentMigration.create!(:context => @course)
      att = Attachment.create!(:filename => 'archive.zip', :display_name => "archive.zip", :uploaded_data => StringIO.new('fake zip!'), :context => cm)
      cm.attachment = att
      cm.workflow_state = 'imported'
      cm.save

      get "/courses/#{@course.id}/imports/#{cm.id}/download_archive"
      response.should be_redirect
      response['Location'].should =~ %r{content_migrations/\d*/files/\d*/download\?verifier=}
    end
    
    it "should return error if there is no attachment" do
      course_with_teacher_logged_in(:active_all => true, :name => 'test', :user => @user)
      cm = ContentMigration.create!(:context => @course)
      cm.workflow_state = 'imported'
      cm.save

      get "/courses/#{@course.id}/imports/#{cm.id}/download_archive"
      response.should_not be_success
      response.flash.should == {:notice=>"There is no archive for this content migration"}
    end
  end

end