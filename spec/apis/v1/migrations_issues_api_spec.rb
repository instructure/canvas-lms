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

describe MigrationIssuesController, type: :request do
  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @migration = @course.content_migrations.create!
    @issue_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/migration_issues"
    @params = { :controller => 'migration_issues', :format => 'json', :course_id => @course.id.to_param, :content_migration_id => @migration.id.to_param}
    @issue = @migration.add_warning("fail", :fix_issue_html_url => "https://example.com", :error_message => "secret error", :error_report_id => 0)
  end

  describe 'index' do
    before do
      @params = @params.merge( :action => 'index')
    end

    it "should return the list" do
      json = api_call(:get, @issue_url, @params)
      expect(json.length).to eq 1
      expect(json.first['id']).to eq @issue.id
    end

    it "should paginate" do
      issue = @migration.add_warning("hey")
      json = api_call(:get, @issue_url + "?per_page=1", @params.merge({:per_page=>'1'}))
      expect(json.length).to eq 1
      expect(json.first['id']).to eq @issue.id
      json = api_call(:get, @issue_url + "?per_page=1&page=2", @params.merge({:per_page => '1', :page => '2'}))
      expect(json.length).to eq 1
      expect(json.first['id']).to eq issue.id
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @issue_url, @params, {}, {}, :expected_status => 401)
    end
  end

  describe 'show' do
    before do
      @issue_url = @issue_url + "/#{@issue.id}"
      @params = @params.merge( :action => 'show', :id => @issue.id.to_param )
    end

    it "should return migration" do
      json = api_call(:get, @issue_url, @params)

      expect(json['id']).to eq @issue.id
      expect(json['description']).to eq "fail"
      expect(json["workflow_state"]).to eq "active"
      expect(json['fix_issue_html_url']).to eq "https://example.com"
      expect(json['issue_type']).to eq "warning"
      expect(json['error_message']).to be_nil
      expect(json['error_report_html_url']).to be_nil
      expect(json["content_migration_url"]).to eq "http://www.example.com/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}"
      expect(json['created_at']).not_to be_nil
      expect(json['updated_at']).not_to be_nil
    end

    it "should return error messages to site admins" do
      Account.site_admin.account_users.create!(user: @user)
      json = api_call(:get, @issue_url, @params)
      expect(json['error_message']).to eq 'secret error'
      expect(json['error_report_html_url']).to eq "http://www.example.com/error_reports/0"
    end

    it "should 404" do
      api_call(:get, @issue_url + "000", @params.merge({:id => @issue.id.to_param + "000"}), {}, {}, :expected_status => 404)
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @issue_url, @params, {}, {}, :expected_status => 401)
    end
  end

  describe 'update' do
    before do
      @issue_url = @issue_url + "/#{@issue.id}"
      @params = @params.merge( :action => 'update', :id => @issue.id.to_param )
      @body_params = {:workflow_state => 'resolved'}
    end

    it "should update state" do
      json = api_call(:put, @issue_url, @params, @body_params)
      expect(json['workflow_state']).to eq 'resolved'
      @issue.reload
      expect(@issue.workflow_state).to eq 'resolved'
    end

    it "should reject invalid state" do
      api_call(:put, @issue_url, @params, {:workflow_state => 'deleted'}, {}, :expected_status => 403)

      @issue.reload
      expect(@issue.workflow_state).to eq 'active'
    end

    it "should 404" do
      api_call(:put, @issue_url + "000", @params.merge({:id => @issue.id.to_param + "000"}), @body_params, {}, :expected_status => 404)
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:put, @issue_url, @params, @body_params, {}, :expected_status => 401)
      @issue.reload
      expect(@issue.workflow_state).to eq 'active'
    end
  end

end
