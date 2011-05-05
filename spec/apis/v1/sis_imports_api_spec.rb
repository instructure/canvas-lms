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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SisImportsApiController, :type => :integration do

  it 'should kick off a sis import via multipart attachment' do
    @user = user :active_all => true
    user_session @user
    @account = Account.create!(:name => UUIDSingleton.instance.generate)
    @account.allow_sis_import = true
    @account.save
    @account.add_user(@user, 'AccountAdmin')
    Account.site_admin.add_user(@user, 'AccountAdmin')
    
    @user_count = User.count
    @batch_count = SisBatch.count
  
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s }, 
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv') })

    json.has_key?("created_at").should be_true
    json.delete("created_at")
    json.has_key?("updated_at").should be_true
    json.delete("updated_at")
    json.has_key?("ended_at").should be_true
    json.delete("ended_at")
    batch = SisBatch.last
    json.should == {
          "data" => { "import_type"=>"instructure_csv"},
          "progress" => 0,
          "id" => batch.id,
          "workflow_state"=>"created" }

    SisBatch.count.should == @batch_count + 1
    batch.process_without_send_later
    User.count.should == @user_count + 1
    User.last.name.should == "Jamie Kennedy"
    
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}.json",
          { :controller => 'sis_imports_api', :action => 'show', :format => 'json',
            :account_id => @account.id.to_s, :id => batch.id.to_s })
    json.should be_true
    json.has_key?("created_at").should be_true
    json.delete("created_at")
    json.has_key?("updated_at").should be_true
    json.delete("updated_at")
    json.has_key?("ended_at").should be_true
    json.delete("ended_at")
    json.should == { 
          "data" => { "import_type" => "instructure_csv",
                      "counts" => { "courses" => 0,
                                    "sections" => 0,
                                    "accounts" => 0,
                                    "enrollments" => 0,
                                    "grade_publishing_results" => 0,
                                    "users" => 1,
                                    "xlists" => 0,
                                    "terms" => 0}},
          "progress" => 100,
          "id" => batch.id,
          "workflow_state"=>"imported" }
  end

end
