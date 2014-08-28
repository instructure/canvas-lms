#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

describe 'Account Reports API', type: :request do
  before :once do
    @admin = account_admin_user
    user_with_pseudonym(:user => @admin)
    @report = AccountReport.new
    @report.account = @admin.account
    @report.user = @admin
    @report.progress=rand(100)
    @report.start_at=DateTime.now
    @report.end_at=(Time.now + (rand(60*60*4))).to_datetime
    @report.report_type = "student_assignment_outcome_map_csv"
    @report.parameters = HashWithIndifferentAccess['param' => 'test', 'error'=>'failed']

    folder = Folder.assert_path("test", @admin.account)
    @report.attachment = Attachment.create!(:folder => folder, :context => @admin.account, :filename => "test.txt", :uploaded_data => StringIO.new("test file"))

    @report.save!
  end

  describe 'available_reports' do
    it 'should list all available reports' do

      json = api_call(:get, "/api/v1/accounts/#{@admin.account.id}/reports",
                      { :controller => 'account_reports', :action => 'available_reports', :format => 'json', :account_id => @admin.account.id.to_s })
      json.each do |report|
        report.key?('title').should be_true
        report.key?('parameters').should be_true
        report.key?('report').should be_true

        report[:parameters].each do |key, parameter|
          parameter.key?('required').should be_true
          parameter.key?('description').should be_true
        end unless report[:parameters].nil?
      end
    end
  end

  describe 'create' do
    it 'should create a student report' do
      report = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                        { :report=> @report.report_type, :controller => 'account_reports', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s })
      report.key?('id').should be_true
      report.key?('status').should be_true
      report.key?('progress').should be_true
      report.key?('file_url').should be_true
    end

    it 'should 404 for non existing reports' do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/reports/bad_report_csv",
                   { :report=> 'bad_report_csv', :controller => 'account_reports', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s })
      assert_status(404)
    end
  end

  describe 'index' do
    it 'should list all generated reports' do
      json = api_call(:get, "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}",
                      { :report=> @report.report_type, :controller => 'account_reports', :action => 'index', :format => 'json', :account_id => @admin.account.id.to_s })

      json.length.should >= 0
      json.length.should <= 50
      json.each do |report|
        report.key?('id').should be_true
        report.key?('status').should be_true
        report.key?('progress').should be_true
        report.key?('file_url').should be_true
      end
    end
  end

  describe 'show' do
    it 'should get all info about a report' do
      json = api_call(:get, "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}",
                      { :report=> @report.report_type, :controller => 'account_reports', :action => 'show', :format => 'json', :account_id => @admin.account.id.to_s, :id => @report.id.to_s })

      json['id'].should == @report.id
      json['status'].should == @report.workflow_state
      json['progress'].should == @report.progress
      json['file_url'].should == "https://#{HostUrl.context_host(@admin.account)}/accounts/#{@admin.account.id}/files/#{@report.attachment_id}/download"
      #test that attachment object is here, no need to test attachment json
      json['attachment']['id'].should == @report.attachment_id
      @report.parameters.each do |key, value|
        json['parameters'][key].should == value
      end
    end
  end

  describe 'destroy' do
    it 'delete a report' do
      json = api_call(:delete, "/api/v1/accounts/#{@admin.account.id}/reports/#{@report.report_type}/#{@report.id}",
                      { :report=> @report.report_type, :controller => 'account_reports', :action => 'destroy', :format => 'json', :account_id => @admin.account.id.to_s, :id => @report.id.to_s })

      json['id'].should == @report.id
      json['status'].should == @report.workflow_state
      json['progress'].should == @report.progress
      json['file_url'].should == "https://#{HostUrl.context_host(@admin.account)}/accounts/#{@admin.account.id}/files/#{@report.attachment.id}/download"
      @report.parameters.each do |key, value|
        json['parameters'][key].should == value
      end
      AccountReport.exists?(@report.id).should_not be_true
    end
  end
end

