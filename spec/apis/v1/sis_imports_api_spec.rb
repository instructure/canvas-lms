#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe SisImportsApiController, type: :request do
  before :once do
    @user = user_with_pseudonym :active_all => true
    @account = Account.default
    @account.allow_sis_import = true
    @account.save
    @account.account_users.create!(user: @user)
    Account.site_admin.account_users.create!(user: @user)

    @user_count = User.count
    @batch_count = SisBatch.count
  end

  def post_csv(*lines_or_opts)
    lines = lines_or_opts.reject{|thing| thing.is_a? Hash}
    opts = lines_or_opts.select{|thing| thing.is_a? Hash}.inject({}, :merge)

    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.flatten.join "\n" }

    json = api_call(:post,
        "/api/v1/accounts/#{@account.id}/sis_imports.json",
        { :controller => "sis_imports_api", :action => "create",
          :format => "json", :account_id => @account.id.to_s },
        opts.merge({ :import_type => "instructure_csv",
          :attachment => Rack::Test::UploadedFile.new(path)}))
    expect(json.has_key?("created_at")).to be_truthy
    json.delete("created_at")
    expect(json.has_key?("updated_at")).to be_truthy
    json.delete("updated_at")
    expect(json.has_key?("ended_at")).to be_truthy
    json.delete("ended_at")
    expect(json.has_key?("started_at")).to eq true
    json.delete("started_at")
    if opts[:batch_mode_term_id]
      expect(json["batch_mode_term_id"]).not_to be_nil
    end
    json.delete("batch_mode_term_id")
    json.delete("user")
    batch = SisBatch.last
    expect(json).to eq({
          "data" => { "import_type"=>"instructure_csv"},
          "progress" => 0,
          "id" => batch.id,
          "workflow_state"=>"created",
          "batch_mode" => opts[:batch_mode] ? true : nil,
          "override_sis_stickiness" => opts[:override_sis_stickiness] ? true : nil,
          "add_sis_stickiness" => opts[:add_sis_stickiness] ? true : nil,
          "clear_sis_stickiness" => opts[:clear_sis_stickiness] ? true : nil,
          "multi_term_batch_mode" => nil,
          "diffing_data_set_identifier" => nil,
          "diffed_against_import_id" => nil,
          "diffing_drop_status" => nil,
          "skip_deletes" => false,
          "change_threshold" => nil,
    })
    batch.process_without_send_later
    run_jobs
    return batch.reload
  end

  it 'should kick off a sis import via multipart attachment' do
    json = nil
    expect {
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv') })
    }.to change { Delayed::Job.strand_size("sis_batch:account:#{@account.id}") }.by(1)

    expect(json.has_key?("created_at")).to be_truthy
    json.delete("created_at")
    expect(json.has_key?("updated_at")).to be_truthy
    json.delete("updated_at")
    expect(json.has_key?("ended_at")).to be_truthy
    json.delete("ended_at")
    expect(json.has_key?("started_at")).to eq true
    json.delete("started_at")
    json.delete("user")
    json.delete("csv_attachments")
    json['data'].delete("downloadable_attachment_ids")
    batch = SisBatch.last
    expect(json).to eq({
          "data" => { "import_type"=>"instructure_csv"},
          "progress" => 0,
          "id" => batch.id,
          "workflow_state"=>"created",
          "batch_mode" => nil,
          "batch_mode_term_id" => nil,
          "multi_term_batch_mode" => nil,
          "override_sis_stickiness" => nil,
          "add_sis_stickiness" => nil,
          "clear_sis_stickiness" => nil,
          "diffing_data_set_identifier" => nil,
          "diffed_against_import_id" => nil,
          "diffing_drop_status" => nil,
          "skip_deletes" => false,
          "change_threshold" => nil,
    })

    expect(SisBatch.count).to eq @batch_count + 1
    expect(batch.batch_mode).to be_falsey
    run_jobs
    expect(User.count).to eq @user_count + 1
    expect(User.last.name).to eq "Jamie Kennedy"

    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}.json",
          { :controller => 'sis_imports_api', :action => 'show', :format => 'json',
            :account_id => @account.id.to_s, :id => batch.id.to_s })
    expect(json).to be_truthy
    expect(json.has_key?("created_at")).to be_truthy
    json.delete("created_at")
    expect(json.has_key?("updated_at")).to be_truthy
    json.delete("updated_at")
    expect(json.has_key?("ended_at")).to be_truthy
    json.delete("ended_at")
    expect(json.has_key?("started_at")).to eq true
    json.delete("started_at")
    json.delete("user")
    json.delete("csv_attachments")
    json["data"].delete("downloadable_attachment_ids")
    expected_data = {
          "data" => { "import_type" => "instructure_csv",
                      "completed_importers" => ["user"],
                      "running_immediately" => true,
                      "supplied_batches" => ["user"],
                      "counts" => { "change_sis_ids"=>0,
                                    "abstract_courses" => 0,
                                    "courses" => 0,
                                    "sections" => 0,
                                    "accounts" => 0,
                                    "enrollments" => 0,
                                    "admins" => 0,
                                    "grade_publishing_results" => 0,
                                    "users" => 1,
                                    "user_observers" => 0,
                                    "xlists" => 0,
                                    "group_categories" => 0,
                                    "groups" => 0,
                                    "group_memberships" => 0,
                                    "terms" => 0,
                                    "error_count"=>0,
                                    "warning_count"=>0 },
                      "statistics" => {"total_state_changes"=>2,
                                       "Account"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "EnrollmentTerm"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "AbstractCourse"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "Course"=>{"created"=>0, "concluded"=>0, "restored"=>0, "deleted"=>0},
                                       "CourseSection"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "GroupCategory"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "Group"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "Pseudonym"=>{"created"=>1, "restored"=>0, "deleted"=>0},
                                       "CommunicationChannel"=>{"created"=>1, "restored"=>0, "deleted"=>0},
                                       "Enrollment"=>{"created"=>0, "concluded"=>0, "deactivated"=>0, "restored"=>0, "deleted"=>0},
                                       "GroupMembership"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "UserObserver"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                       "AccountUser"=>{"created"=>0, "restored"=>0, "deleted"=>0}}},
          "progress" => 100,
          "id" => batch.id,
          "workflow_state"=>"imported",
          "batch_mode" => nil,
          "batch_mode_term_id" => nil,
          "multi_term_batch_mode" => nil,
          "override_sis_stickiness" => nil,
          "add_sis_stickiness" => nil,
          "clear_sis_stickiness" => nil,
          "diffing_data_set_identifier" => nil,
          "diffed_against_import_id" => nil,
          "skip_deletes" => false,
          "diffing_drop_status" => nil,
          "change_threshold" => nil
    }
    expect(json).to eq expected_data
  end

  it 'should restore batch on restore_states and return progress' do
    batch = @account.sis_batches.create
    json = api_call(:put, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}/restore_states",
                    {controller: 'sis_imports_api', action: 'restore_states', format: 'json',
                     account_id: @account.id.to_s, id: batch.id.to_s})
    run_jobs
    expect(batch.reload.workflow_state).to eq 'restored'

    params = {controller: 'progress', action: 'show', id: json['id'].to_param, format: 'json'}
    api_call(:get, "/api/v1/progress/#{json['id']}", params, {}, {}, expected_status: 200)
  end

  it 'should show current running sis import' do
    batch = @account.sis_batches.create!
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/importing",
                    {controller: 'sis_imports_api', action: 'importing', format: 'json',
                     account_id: @account.id.to_s})
    expect(json["sis_imports"]).to eq []
    batch.workflow_state = 'importing'
    batch.save!
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/importing",
                    {controller: 'sis_imports_api', action: 'importing', format: 'json',
                     account_id: @account.id.to_s})
    expect(json["sis_imports"].first['id']).to eq batch.id
  end

  it 'should abort batch on abort' do
    batch = @account.sis_batches.create
    api_call(:put, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}/abort",
             {controller: 'sis_imports_api', action: 'abort', format: 'json',
              account_id: @account.id.to_s, id: batch.id.to_s})
    expect(batch.reload.workflow_state).to eq 'aborted'
  end

  it 'should allow aborting an importing batch' do
    batch = @account.sis_batches.create
    SisBatch.where(id: batch).update_all(workflow_state: 'importing')
    api_call(:put, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}/abort",
             {controller: 'sis_imports_api', action: 'abort', format: 'json',
              account_id: @account.id.to_s, id: batch.id.to_s})
    expect(batch.reload.workflow_state).to eq 'aborted'
  end

  it 'should not explode if there is no batch' do
    batch = @account.sis_batches.create
    SisBatch.where(id: batch).update_all(workflow_state: 'imported')
    raw_api_call(:put,
                 "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}/abort",
                 {controller: 'sis_imports_api', action: 'abort', format: 'json',
                  account_id: @account.id.to_s, id: batch.id.to_s})
    assert_status(404)
    expect(batch.reload.workflow_state).to eq 'imported'
  end

  it 'should abort all pending batches on abort' do
    batch1 = @account.sis_batches.create
    SisBatch.where(id: batch1).update_all(workflow_state: 'imported')
    batch2 = @account.sis_batches.create
    SisBatch.where(id: batch2).update_all(workflow_state: 'importing')
    batch3 = @account.sis_batches.create
    SisBatch.where(id: batch3).update_all(workflow_state: 'created')
    batch4 = @account.sis_batches.create
    api_call(:put, "/api/v1/accounts/#{@account.id}/sis_imports/abort_all_pending",
             {controller: 'sis_imports_api', action: 'abort_all_pending',
              format: 'json', account_id: @account.id.to_s})
    expect(batch1.reload.workflow_state).to eq 'imported'
    expect(batch2.reload.workflow_state).to eq 'importing'
    expect(batch3.reload.workflow_state).to eq 'aborted'
    expect(batch4.reload.workflow_state).to eq 'aborted'
  end

  it "should skip the job for skip_sis_jobs_account_ids" do
    Setting.set('skip_sis_jobs_account_ids', "fake,#{@account.global_id}")
    expect {
      api_call(:post,
            "/api/v1/accounts/#{@account.id}/sis_imports.json",
            { :controller => 'sis_imports_api', :action => 'create',
              :format => 'json', :account_id => @account.id.to_s },
            { :import_type => 'instructure_csv',
              :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv') })
    }.to change { Delayed::Job.strand_size("sis_batch:account:#{@account.id}") }.by(0)
  end

  it "should enable batch mode and require selecting a valid term" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :batch_mode => '1',
            :batch_mode_term_id => @account.default_enrollment_term.id })
    batch = SisBatch.find(json["id"])
    expect(batch.batch_mode).to be_truthy
    expect(batch.batch_mode_term).to eq @account.default_enrollment_term
  end

  it "should use change threshold for batch mode" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { controller: 'sis_imports_api', action: 'create',
            format: 'json', account_id: @account.id.to_s },
          { import_type: 'instructure_csv',
            attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            batch_mode: '1',
            change_threshold: 7,
            batch_mode_term_id: @account.default_enrollment_term.id })
    batch = SisBatch.find(json["id"])
    expect(batch.change_threshold).to eq 7
  end

  it "should requre change threshold for multi_term_batch_mode" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { controller: 'sis_imports_api', action: 'create',
            format: 'json', account_id: @account.id.to_s },
          { import_type: 'instructure_csv',
            attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            multi_term_batch_mode: '1'})
    expect(json['message']).to eq 'change_threshold is required to use multi term_batch mode.'
  end

  it "should use multi_term_batch_mode" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { controller: 'sis_imports_api', action: 'create',
            format: 'json', account_id: @account.id.to_s },
          { import_type: 'instructure_csv',
            attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            batch_mode: '1',
            multi_term_batch_mode: '1',
            change_threshold: 7,})
    batch = SisBatch.find(json["id"])
    expect(json['multi_term_batch_mode']).to eq true
    expect(batch.options[:multi_term_batch_mode]).to be_truthy
  end

  it "should enable batch with sis stickyness" do
    json = api_call(:post,
      "/api/v1/accounts/#{@account.id}/sis_imports.json",
      { controller: 'sis_imports_api', action: 'create',
        format: 'json', account_id: @account.id.to_s },
      { import_type: 'instructure_csv',
        attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
        batch_mode: 'true',
        clear_sis_stickiness: 'true',
        override_sis_stickiness: 'true',
        batch_mode_term_id: @account.default_enrollment_term.id })
    batch = SisBatch.find(json["id"])
    expect(batch.batch_mode).to be_truthy
    expect(batch.options[:override_sis_stickiness]).to be_truthy
    expect(batch.options[:clear_sis_stickiness]).to be_truthy
    expect(batch.batch_mode_term).to eq @account.default_enrollment_term
  end

  it "should enable diffing mode" do
    json = api_call(:post,
      "/api/v1/accounts/#{@account.id}/sis_imports.json",
      { controller: 'sis_imports_api', action: 'create',
        format: 'json', account_id: @account.id.to_s },
      { import_type: 'instructure_csv',
        attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
        diffing_data_set_identifier: 'my-users-data',
        diffing_drop_status: 'inactive',
        change_threshold: 7,
      })
    batch = SisBatch.find(json["id"])
    expect(batch.batch_mode).to be_falsey
    expect(batch.change_threshold).to eq 7
    expect(batch.options[:diffing_drop_status]).to eq 'inactive'
    expect(json['change_threshold']).to eq 7
    expect(batch.diffing_data_set_identifier).to eq 'my-users-data'
  end

  it "should error for invalid diffing_drop_status" do
    json = api_call(:post,
      "/api/v1/accounts/#{@account.id}/sis_imports.json",
      { controller: 'sis_imports_api', action: 'create',
        format: 'json', account_id: @account.id.to_s },
      { import_type: 'instructure_csv',
        attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
        diffing_data_set_identifier: 'my-users-data',
        diffing_drop_status: 'invalid',
        change_threshold: 7,
      }, {}, expected_status: 400)
    expect(json['message']).to eq 'Invalid diffing_drop_status'
  end

  it "should error if batch mode and the term can't be found" do
    expect {
      json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :batch_mode => '1' }, {}, :expected_status => 400)
      expect(json['message']).to eq "Batch mode specified, but the given batch_mode_term_id cannot be found."
    }.to change(SisBatch, :count).by(0)
  end

  it "should enable sis stickiness options" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv')})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({skip_deletes: false})
    batch.destroy

    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :override_sis_stickiness => "1"})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({override_sis_stickiness: true, skip_deletes: false})
    batch.destroy

    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :override_sis_stickiness => "1",
            :add_sis_stickiness => "1"})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({override_sis_stickiness: true, add_sis_stickiness: true, skip_deletes: false})
    batch.destroy

    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :override_sis_stickiness => "1",
            :clear_sis_stickiness => "1"})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({override_sis_stickiness: true, clear_sis_stickiness: true, skip_deletes: false})
    batch.destroy

    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :add_sis_stickiness => "1"})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({skip_deletes: false})
    batch.destroy

    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s },
          { :import_type => 'instructure_csv',
            :attachment => fixture_file_upload("files/sis/test_user_1.csv", 'text/csv'),
            :clear_sis_stickiness => "1"})
    batch = SisBatch.find(json["id"])
    expect(batch.options).to eq({skip_deletes: false})
    batch.destroy
  end

  it 'should support sis stickiness overriding' do
    before_count = AbstractCourse.count
    post_csv(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    post_csv(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      {:override_sis_stickiness => "1"}
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
  end

  it 'should allow turning on stickiness' do
    before_count = AbstractCourse.count
    post_csv(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    post_csv(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Phys101,Physics,A001,T001,active",
      { :override_sis_stickiness => "1",
        :add_sis_stickiness => "1"}
    )
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
  end

  it 'should allow turning off stickiness' do
    before_count = AbstractCourse.count
    post_csv(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    post_csv(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      { :override_sis_stickiness => "1",
        :clear_sis_stickiness => "1" }
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
    post_csv(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "French"
      expect(c.short_name).to eq "Fren101"
    end
  end

  it "should allow raw post without content-type" do
    # In the current API docs, we specify that you need to send a content-type to make raw
    # post work. However, long ago we added code to make it work even without the header,
    # so we are going to maintain that behavior.
    post "/api/v1/accounts/#{@account.id}/sis_imports.json?import_type=instructure_csv", params: "\xffab=\xffcd", headers: { "HTTP_AUTHORIZATION" => "Bearer #{access_token_for_user(@user)}" }

    batch = SisBatch.last
    expect(batch.attachment.filename).to eq "sis_import.zip"
    expect(batch.attachment.content_type).to eq "application/x-www-form-urlencoded"
    expect(batch.attachment.size).to eq 7
  end

  it "should allow raw post without charset" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json?import_type=instructure_csv",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv', :attachment => 'blah' },
          {},
          { 'CONTENT_TYPE' => 'text/csv' })
    batch = SisBatch.last
    expect(batch.attachment.filename).to eq "sis_import.csv"
    expect(batch.attachment.content_type).to eq "text/csv"
  end

  it "should handle raw post content-types with attributes" do
    json = api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json?import_type=instructure_csv",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv', :attachment => 'blah' },
          {},
          { 'CONTENT_TYPE' => 'text/csv; charset=utf-8' })
    batch = SisBatch.last
    expect(batch.attachment.filename).to eq "sis_import.csv"
    expect(batch.attachment.content_type).to eq "text/csv"
  end

  it "should reject non-utf-8 encodings on content-type" do
    json = raw_api_call(:post,
          "/api/v1/accounts/#{@account.id}/sis_imports.json?import_type=instructure_csv",
          { :controller => 'sis_imports_api', :action => 'create',
            :format => 'json', :account_id => @account.id.to_s,
            :import_type => 'instructure_csv' },
          {},
          { 'CONTENT_TYPE' => 'text/csv; charset=ISO-8859-1-Windows-3.0-Latin-1' })
    assert_status(400)
    expect(SisBatch.count).to eq 0
  end

  it "should list sis imports for an account" do
    batch = post_csv(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )

    run_jobs
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => @account.id.to_s })

    json["sis_imports"].first.delete("created_at")
    json["sis_imports"].first.delete("updated_at")
    json["sis_imports"].first.delete("ended_at")
    json["sis_imports"].first.delete("started_at")
    json["sis_imports"].first.delete("user")
    json["sis_imports"].first.delete("csv_attachments")
    json["sis_imports"].first['data'].delete("downloadable_attachment_ids")

    expected_data = {"sis_imports"=>[{
                      "data" => { "import_type" => "instructure_csv",
                                  "completed_importers" => ["account"],
                                  "running_immediately" => true,
                                  "supplied_batches" => ["account"],
                                  "counts" => { "change_sis_ids"=>0,
                                                "abstract_courses" => 0,
                                                "courses" => 0,
                                                "sections" => 0,
                                                "accounts" => 1,
                                                "enrollments" => 0,
                                                "admins" => 0,
                                                "grade_publishing_results" => 0,
                                                "users" => 0,
                                                "user_observers" => 0,
                                                "xlists" => 0,
                                                "group_categories" => 0,
                                                "groups" => 0,
                                                "group_memberships" => 0,
                                                "terms" => 0,
                                                "error_count"=>0,
                                                "warning_count"=>0 },
                                  "statistics" => {"total_state_changes"=>1,
                                                   "Account"=>{"created"=>1, "restored"=>0, "deleted"=>0},
                                                   "EnrollmentTerm"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "AbstractCourse"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "Course"=>{"created"=>0, "concluded"=>0, "restored"=>0, "deleted"=>0},
                                                   "CourseSection"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "GroupCategory"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "Group"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "Pseudonym"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "CommunicationChannel"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "Enrollment"=>{"created"=>0, "concluded"=>0, "deactivated"=>0, "restored"=>0, "deleted"=>0},
                                                   "GroupMembership"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "UserObserver"=>{"created"=>0, "restored"=>0, "deleted"=>0},
                                                   "AccountUser"=>{"created"=>0, "restored"=>0, "deleted"=>0}}},
                      "progress" => 100,
                      "id" => batch.id,
                      "workflow_state"=>"imported",
          "batch_mode" => nil,
          "batch_mode_term_id" => nil,
          "multi_term_batch_mode" => nil,
          "override_sis_stickiness" => nil,
          "add_sis_stickiness" => nil,
          "clear_sis_stickiness" => nil,
          "diffing_data_set_identifier" => nil,
          "diffed_against_import_id" => nil,
          "skip_deletes" => false,
          "diffing_drop_status" => nil,
          "change_threshold" => nil,
      }]
    }
    expect(json).to eq expected_data

    links = Api.parse_pagination_links(response.headers['Link'])
    expect(links.first[:uri].path).to eq api_v1_account_sis_imports_path
  end

  it "should return downloadable attachments if available" do
    batch = post_csv(
      "user_id,password,login_id,status,ssha_password",
      "user_1,supersecurepwdude,user_1,active,hunter2"
    )

    run_jobs
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
      { :controller => 'sis_imports_api', :action => 'index',
        :format => 'json', :account_id => @account.id.to_s })

    atts_json = json["sis_imports"].first["csv_attachments"]
    expect(atts_json.count).to eq 1
    expect(atts_json.first["id"]).to eq batch.downloadable_attachments.last.id
    expect(atts_json.first["url"]).to be_present
  end

  it "should filter sis imports by date if requested" do
    batch = @account.sis_batches.create
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => @account.id.to_s, :created_since => 1.day.from_now.iso8601 })

    expect(json["sis_imports"].count).to eq 0

    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => @account.id.to_s, :created_since => 1.day.ago.iso8601 })

    expect(json["sis_imports"].count).to eq 1
  end

  it "should not fail when options are nil" do
    batch = @account.sis_batches.create
    expect(batch.options).to be_nil
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => @account.id.to_s })
    assert_status(200)
  end

  it "should error on non-root account" do
    subaccount = @account.sub_accounts.create!
    json = api_call(:get, "/api/v1/accounts/#{subaccount.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => subaccount.id.to_s },
                    {},
                    {},
                    expected_status: 400)
    expect(json['errors'].first).to eq "SIS imports can only be executed on root accounts"
  end

  it "should error on non-enabled root account" do
    @account.allow_sis_import = false
    @account.save
    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports.json",
                    { :controller => 'sis_imports_api', :action => 'index',
                      :format => 'json', :account_id => @account.id.to_s },
                    {},
                    {},
                    expected_status: 403)
    expect(json['errors'].first).to eq "SIS imports are not enabled for this account"
  end

  it "should error on user with no sis permissions" do
    account_admin_user_with_role_changes(account: @account, role_changes: {manage_sis: true, import_sis: false})
    api_call(:post,
             "/api/v1/accounts/#{@account.id}/sis_imports.json",
             {controller: 'sis_imports_api', action: 'create',
              format: 'json', account_id: @account.id.to_s},
             {import_type: 'instructure_csv',
              attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv')},
             {},
             expected_status: 401)
  end

  it "should work with import permissions" do
    account_admin_user_with_role_changes(user: @user, role_changes: {manage_sis: false, import_sis: true})
    api_call(:post,
             "/api/v1/accounts/#{@account.id}/sis_imports.json",
             {controller: 'sis_imports_api', action: 'create',
              format: 'json', account_id: @account.id.to_s},
             {import_type: 'instructure_csv',
              attachment: fixture_file_upload("files/sis/test_user_1.csv", 'text/csv')},
             {},
             expected_status: 200)
  end

  it "should include the errors_attachment when there are errors" do
    batch = @account.sis_batches.create!
    3.times do |i|
      batch.sis_batch_errors.create(root_account: @account, file: 'users.csv', message: "some error #{i}", row: i)
    end
    batch.finish(false)

    json = api_call(:get, "/api/v1/accounts/#{@account.id}/sis_imports/#{batch.id}.json",
                    { controller: 'sis_imports_api', action: 'show', format: 'json',
                      account_id: @account.id.to_s, id: batch.id.to_s })
    expect(json.key?('errors_attachment')).to be_truthy
    expect(json['errors_attachment']['id']).to eq batch.errors_attachment.id
  end
end
