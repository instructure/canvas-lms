#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

describe ContentMigrationsController, :type => :integration do
  before do
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym)
    @migration_url = "/api/v1/courses/#{@course.id}/content_migrations"
    @params = { :controller => 'content_migrations', :format => 'json', :course_id => @course.id.to_param}

    @migration = @course.content_migrations.create
    @migration.user = @user
    @migration.started_at = 1.week.ago
    @migration.finished_at = 1.day.ago
    @migration.save!
  end

  describe 'index' do
    before do
      @params = @params.merge( :action => 'index')
    end

    it "should return list" do
      json = api_call(:get, @migration_url, @params)
      json.length.should == 1
      json.first['id'].should == @migration.id
    end

    it "should paginate" do
      migration = @course.content_migrations.create!
      json = api_call(:get, @migration_url + "?per_page=1", @params.merge({:per_page=>'1'}))
      json.length.should == 1
      json.first['id'].should == migration.id
      json = api_call(:get, @migration_url + "?per_page=1&page=2", @params.merge({:per_page => '1', :page => '2'}))
      json.length.should == 1
      json.first['id'].should == @migration.id
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @migration_url, @params, {}, {}, :expected_status => 401)
    end
  end

  describe 'show' do
    before do
      @migration_url = @migration_url + "/#{@migration.id}"
      @params = @params.merge( :action => 'show', :id => @migration.id.to_param )
    end

    it "should return migration" do
      @migration.attachment = Attachment.create!(:context => @migration, :filename => "test.txt", :uploaded_data => StringIO.new("test file"))
      @migration.save!
      json = api_call(:get, @migration_url, @params)

      json['id'].should == @migration.id
      json['finished_at'].should_not be_nil
      json['started_at'].should_not be_nil
      json['user_id'].should == @user.id
      json["workflow_state"].should == "created"
      json["migration_issues_url"].should == "http://www.example.com/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/migration_issues"
      json["migration_issues_count"].should == 0
      json["content_archive_download_url"].should == "http://www.example.com/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/download_archive"
    end

    it "should 404" do
      api_call(:get, @migration_url + "000", @params.merge({:id => @migration.id.to_param + "000"}), {}, {}, :expected_status => 404)
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @migration_url, @params, {}, {}, :expected_status => 401)
    end
  end

  describe 'download_archive' do
    before do
      @migration_url = @migration_url + "/#{@migration.id}/download_archive"
      @params = @params.merge({:action => 'download_archive', :id => @migration.id.to_param})
    end

    it "should send file" do
      @migration.attachment = Attachment.create!(:context => @migration, :filename => "test.txt", :uploaded_data => StringIO.new("test file"))
      @migration.save!
      raw_api_call :get, @migration_url, @params
      response.header['Content-Disposition'].should == 'attachment; filename="test.txt"'
    end

    it "should 404" do
      api_call(:get, @migration_url, @params, {}, {}, :expected_status => 404)
    end
  end

end
