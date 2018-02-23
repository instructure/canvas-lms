#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe OutcomeImportsApiController, type: :request do
  before :once do
    @user = user_with_pseudonym :active_all => true
    @account = Account.default
    @account.account_users.create!(user: @user)

    @outcome_count = LearningOutcome.count
    @group_count = LearningOutcomeGroup.count
    @import_count = OutcomeImport.count
  end

  def expect_keys(json, keys)
    keys.each do |key|
      expect(json).to be_key key
      json.delete(key)
    end
  end

  it 'should kick off an outcome import via multipart attachment' do
    # TODO: Once OUT-1997 is merged, we can uncomment this out?
    # json = nil
    # expect {
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/outcome_imports",
          { :controller => 'outcome_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/outcomes/test_outcomes_1.csv", 'text/csv') })
    # }.to change { Delayed::Job.strand_size("sis_batch:account:#{@account.id}") }.by(1)
    expect_keys(json, %w[created_at updated_at ended_at user])
    import = OutcomeImport.last
    expect(json).to eq({
          "data" => { "import_type"=>"instructure_csv"},
          "progress" => 0,
          "id" => import.id,
          "processing_errors" => [],
          "workflow_state"=>"created"
    })

    expect(OutcomeImport.count).to eq @import_count + 1
    run_jobs
    # TODO: Once OUT-1997 is merged, we can uncomment this out
    # expect(LearningOutcome.count).to eq @outcome_count + 1
    # expect(LearningOutcomeGroup.count).to eq @group_count + 2
    # expect(Outcome.last.title).to eq "REPLACE ME"

    json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_imports/#{import.id}",
          { :controller => 'outcome_imports_api', :action => 'show', :format => 'json',
            :account_id => @account.id.to_s, :id => import.id.to_s })
    expect(json).to be_truthy
    expect_keys(json, %w[created_at updated_at ended_at user])
    # TODO: Once OUT-1997 is merged, we can uncomment this out
    # expect(json).to eq({
    #       "data" => { "import_type" => "instructure_csv" },
    #       "progress" => 100,
    #       "id" => import.id,
    #       "workflow_state"=>"imported"
    # })
  end

  it "should allow raw post without content-type" do
    # In the current API docs, we specify that you need to send a content-type to make raw
    # post work. However, long ago we added code to make it work even without the header,
    # so we are going to maintain that behavior.
    post "/api/v1/accounts/#{@account.id}/outcome_imports?import_type=instructure_csv",
      params: "\xffab=\xffcd", headers: { "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" }
    import = OutcomeImport.last
    expect(import.attachment.filename).to eq "outcome_import.csv"
    expect(import.attachment.content_type).to eq "application/x-www-form-urlencoded"
    expect(import.attachment.size).to eq 7
  end

  it "should allow raw post without charset" do
    api_call(:post,
          "/api/v1/accounts/#{@account.id}/outcome_imports?import_type=instructure_csv",
          { :controller => 'outcome_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv', :attachment => 'blah' },
          {},
          { 'CONTENT_TYPE' => 'text/csv' })
    import = OutcomeImport.last
    expect(import.attachment.filename).to eq "outcome_import.csv"
    expect(import.attachment.content_type).to eq "text/csv"
  end

  it "should handle raw post content-types with attributes" do
    api_call(:post,
          "/api/v1/accounts/#{@account.id}/outcome_imports?import_type=instructure_csv",
          { :controller => 'outcome_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv', :attachment => 'blah' },
          {},
          { 'CONTENT_TYPE' => 'text/csv; charset=utf-8' })
    import = OutcomeImport.last
    expect(import.attachment.filename).to eq "outcome_import.csv"
    expect(import.attachment.content_type).to eq "text/csv"
  end

  it "should reject non-utf-8 encodings on content-type" do
    raw_api_call(:post,
          "/api/v1/accounts/#{@account.id}/outcome_imports?import_type=instructure_csv",
          { :controller => 'outcome_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv' },
          {},
          { 'CONTENT_TYPE' => 'text/csv; charset=ISO-8859-1-Windows-3.0-Latin-1' })
    assert_status(400)
    expect(OutcomeImport.count).to eq 0
  end

  it "should error on user with no outcomes permissions" do
    account_admin_user_with_role_changes(account: @account, role_changes: {manage_outcomes: true, import_outcomes: false})
    api_call(:post,
             "/api/v1/accounts/#{@account.id}/outcome_imports",
             {controller: 'outcome_imports_api', action: 'create',
              format: 'json', account_id: @account.id.to_s},
             {import_type: 'instructure_csv',
              attachment: fixture_file_upload("files/outcomes/test_outcomes_1.csv", 'text/csv')},
             {},
             expected_status: 401)
  end

  it "should work with import permissions" do
    account_admin_user_with_role_changes(user: @user, role_changes: {manage_outcomes: false, import_outcomes: true})
    api_call(:post,
             "/api/v1/accounts/#{@account.id}/outcome_imports",
             {controller: 'outcome_imports_api', action: 'create',
              format: 'json', account_id: @account.id.to_s},
             {import_type: 'instructure_csv',
              attachment: fixture_file_upload("files/outcomes/test_outcomes_1.csv", 'text/csv')},
             {},
             expected_status: 200)
  end

  it "should include processing_errors when there are errors" do
    import = @account.outcome_imports.create!
    3.times do |i|
      import.outcome_import_errors.create(message: "some error #{i}")
    end

    json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_imports/#{import.id}",
                    { controller: 'outcome_imports_api', action: 'show', format: 'json',
                      account_id: @account.id.to_s, id: import.id.to_s })
    expect(json).to be_key 'processing_errors'
  end
end
