# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe SisBatch do
  before :once do
    account_model
    Delayed::Job.destroy_all
  end

  def sis_jobs
    Delayed::Job.where("tag ilike 'sis'")
  end

  def create_csv_data(data, add_empty_file: false)
    i = 0
    Dir.mktmpdir("sis_rspec") do |tmpdir|
      if data.length == 1
        path = "#{tmpdir}/csv_0.csv"
        File.write(path, data.first)
      else
        path = "#{tmpdir}/sisfile.zip"
        Zip::File.open(path, Zip::File::CREATE) do |z|
          Array(data).each do |dat|
            z.get_output_stream("csv_#{i}.csv") { |f| f.puts(dat) }
            i += 1
          end
          z.get_output_stream("csv_#{i}.csv") { nil } if add_empty_file
        end
      end

      batch = File.open(path, "rb") do |tmp|
        # arrrgh attachment.rb
        def tmp.original_filename
          File.basename(path)
        end
        SisBatch.create_with_attachment(@account, "instructure_csv", tmp, @user || user_factory)
      end
      yield batch if block_given?
      batch
    end
  end

  def process_csv_data(data, opts = {})
    create_csv_data(data) do |batch|
      batch.update(opts) if opts.present?
      batch.process_without_send_later
      run_jobs
      batch.reload
    end
  end

  it "sees pending imports as not completed" do
    batch = process_csv_data([%(user_id,login_id,status
                                user_1,user_1,active),
                              %(course_id,short_name,long_name,term_id,status
                                course_1,course_1,course_1,term_1,active)])
    ParallelImporter.where(sis_batch_id: batch).update_all(workflow_state: "pending")
    expect(batch.parallel_importers.not_completed.count).to eq 2
  end

  it "restores scores when restoring enrollments" do
    course = @account.courses.create!(name: "one", sis_source_id: "c1")
    user = user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
    enrollment = course.enroll_user(user, "StudentEnrollment", enrollment_state: "active")
    assignment = assignment_model(course:)
    submission = assignment.find_or_create_submission(user)
    submission.submission_type = "online_quiz"
    submission.save!
    batch = process_csv_data([%(course_id,user_id,role,status,section_id
                                c1,u1,student,deleted,)])
    expect(submission.reload.workflow_state).to eq "deleted"
    expect(enrollment.reload.workflow_state).to eq "deleted"
    expect(enrollment.scores.exists?).to be false
    batch.restore_states_for_batch
    expect(submission.reload.workflow_state).to eq "submitted"
    expect(enrollment.reload.workflow_state).to eq "active"
    expect(enrollment.scores.exists?).to be true
  end

  it "logs stats" do
    allow(InstStatsd::Statsd).to receive(:increment)
    process_csv_data([%(user_id,login_id,status
                        user_1,user_1,active)])
    expect(InstStatsd::Statsd).to have_received(:increment).with("sis_batch_completed", tags: { failed: false })
  end

  it "restores linked observers when restoring enrollments" do
    allow(InstStatsd::Statsd).to receive(:increment)
    course = @account.courses.create!(name: "one", sis_source_id: "c1", workflow_state: "available")
    user = user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
    observer = user_with_managed_pseudonym(account: @account)
    UserObservationLink.create_or_restore(observer:, student: user, root_account: @account)
    student_enrollment = course.enroll_user(user, "StudentEnrollment", enrollment_state: "active")
    observer_enrollment = course.observer_enrollments.where(user_id: observer).take

    batch = process_csv_data([%(course_id,user_id,role,status,section_id
                                c1,u1,student,deleted,)])
    expect(student_enrollment.reload.workflow_state).to eq "deleted"
    expect(observer_enrollment.reload.workflow_state).to eq "deleted"
    tags = { undelete_only: false, unconclude_only: false, batch_mode: false }
    batch.restore_states_for_batch
    run_jobs
    expect(student_enrollment.reload.workflow_state).to eq "active"
    expect(observer_enrollment.reload.workflow_state).to eq "active"
    expect(InstStatsd::Statsd).to have_received(:increment).with("sis_batch_restored", tags:)
  end

  it "creates new linked observer enrollments when restoring enrollments" do
    course = @account.courses.create!(name: "one", sis_source_id: "c1", workflow_state: "available")
    user = user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
    observer = user_with_managed_pseudonym(account: @account)
    student_enrollment = course.enroll_user(user, "StudentEnrollment", enrollment_state: "active")

    batch = process_csv_data([%(course_id,user_id,role,status,section_id
                                c1,u1,student,deleted,)])
    expect(student_enrollment.reload.workflow_state).to eq "deleted"
    UserObservationLink.create_or_restore(observer:, student: user, root_account: @account)
    expect(course.observer_enrollments.where(user_id: observer).take).to be_nil # doesn't make a new enrollment
    batch.restore_states_for_batch
    run_jobs
    expect(student_enrollment.reload.workflow_state).to eq "active"
    observer_enrollment = course.observer_enrollments.where(user_id: observer).take # until now
    expect(observer_enrollment.workflow_state).to eq "active"
  end

  it "does not add attachments to the list" do
    create_csv_data(["abc"]) { |batch| expect(batch.attachment.position).to be_nil }
    create_csv_data(["abc"]) { |batch| expect(batch.attachment.position).to be_nil }
    create_csv_data(["abc"]) { |batch| expect(batch.attachment.position).to be_nil }
  end

  it "makes file per zip file member" do
    batch = create_csv_data([%(course_id,short_name,long_name,account_id,term_id,status),
                             %(course_id,user_id,role,status,section_id)],
                            add_empty_file: true)
    batch.process_without_send_later
    # 1 zip file and 2 csv files
    atts = Attachment.where(context: batch)
    expect(atts.count).to eq 3
    expect(atts.pluck(:content_type)).to match_array %w[application/zip text/csv text/csv]
  end

  it "makes parallel importers" do
    batch = process_csv_data([%(user_id,login_id,status
                                user_1,user_1,active),
                              %(course_id,short_name,long_name,term_id,status
                                course_1,course_1,course_1,term_1,active)])
    expect(batch.parallel_importers.count).to eq 2
    expect(batch.parallel_importers.pluck(:importer_type)).to match_array %w[course user]
  end

  it "creates filtered versions of csvs with passwords" do
    batch = process_csv_data([%(user_id,password,login_id,status,ssha_password
                                user_1,supersecurepwdude,user_1,active,hunter2)])
    expect(batch).to be_imported
    atts = batch.downloadable_attachments
    expect(atts.count).to eq 1

    atts.first.open do |file|
      @row = CSV.new(file, headers: true).first.to_h
    end
    expect(@row).to eq({ "user_id" => "user_1", "login_id" => "user_1", "status" => "active" })
  end

  it "is able to preload downloadable attachments" do
    batch1 = process_csv_data([%(user_id,password,login_id,status,ssha_password
                                user_1,supersecurepwdude,user_1,active,hunter2),
                               %(course_id,short_name,long_name,term_id,status
                                course_1,course_1,course_1,term_1,active)])
    batch2 = @account.sis_batches.create!
    SisBatch.load_downloadable_attachments([batch1, batch2])

    expect(batch2.instance_variable_get(:@downloadable_attachments)).to eq []
    atts = batch1.instance_variable_get(:@downloadable_attachments)
    expect(atts.count).to eq 2
    expect(atts.map(&:id)).to match_array(batch1.data[:downloadable_attachment_ids])
  end

  it "keeps the batch in initializing state during create_with_attachment" do
    batch = SisBatch.create_with_attachment(@account, "instructure_csv", stub_file_data("test.csv", "abc", "text"), user_factory) do |b|
      expect(b.attachment).not_to be_new_record
      expect(b.workflow_state).to eq "initializing"
      b.options = { override_sis_stickiness: true }
    end

    expect(batch.workflow_state).to eq "created"
    expect(batch).not_to be_new_record
    expect(batch.changed?).to be_falsey
    expect(batch.options[:override_sis_stickiness]).to be true
  end

  describe "parallel imports" do
    it "does cool stuff" do
      PluginSetting.create!(name: "sis_import", settings: { parallelism: "12" })
      batch = process_csv_data([
                                 %(user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active
          user_3,user_3,active),
                                 %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active
          course_3,course_3,course_3,term_1,active
          course_4,course_4,course_4,term_1,active)
                               ])
      expect(Setting.get("sis_parallel_import/#{@account.global_id}_num_strands", "1")).to eq "12"
      expect(batch.reload).to be_imported
      expect(batch.parallel_importers.group(:importer_type).count).to eq({ "course" => 1, "user" => 1 })
      expect(batch.parallel_importers.order(:id).pluck(:importer_type, :rows_processed)).to eq [
        ["course", 4], ["user", 3]
      ]
      expect(Pseudonym.where(sis_user_id: %w[user_1 user_2 user_3]).count).to eq 3
      expect(Course.where(sis_source_id: %w[course_1 course_2 course_3 course_4]).count).to eq 4
      expect(batch.reload.data[:counts].slice(:users, :courses)).to eq({ users: 3, courses: 4 })
    end

    describe "intermittent failures" do
      before do
        # each importer calls this method twice when it does not have an error.
        response_values = [:raise, :raise, :raise, :raise, false, false, :raise, :raise, :raise, false, false]
        # typically an error would happen on the next method, but the next
        # method we want to call original so we can see that it imported. It
        # is much easier to fake a failure and success on a method that returns
        # a boolean.
        allow_any_instance_of(SIS::CSV::ImportRefactored).to receive(:should_stop_import?) do
          v = response_values.shift
          (v == :raise) ? raise("PC_LOAD_LETTER") : v
        end
      end

      it "retries importing data on failures" do
        batch = process_csv_data([
                                   %(user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active
          user_3,user_3,active),
                                   %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active
          course_3,course_3,course_3,term_1,active
          course_4,course_4,course_4,term_1,active)
                                 ])
        expect(batch.reload).to be_imported
        expect(batch.reload.data[:counts].slice(:users, :courses)).to eq({ users: 3, courses: 4 })
        expect(Pseudonym.where(sis_user_id: %w[user_1 user_2 user_3]).count).to eq 3
        expect(Course.where(sis_source_id: %w[course_1 course_2 course_3 course_4]).count).to eq 4
      end
    end

    describe "just failures" do
      before do
        allow_any_instance_of(SIS::CSV::ImportRefactored).to(receive(:should_stop_import?)) { raise("PC_LOAD_LETTER") }
      end

      it "retries importing data on failures" do
        batch = process_csv_data([
                                   %(user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active
          user_3,user_3,active),
                                   %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active
          course_3,course_3,course_3,term_1,active
          course_4,course_4,course_4,term_1,active)
                                 ])
        expect(batch.reload).to be_failed_with_messages
        expect(batch.reload.data[:counts].slice(:users, :courses)).to eq({ users: 0, courses: 0 })
        expect(Pseudonym.where(sis_user_id: %w[user_1 user_2 user_3]).count).to eq 0
        expect(Course.where(sis_source_id: %w[course_1 course_2 course_3 course_4]).count).to eq 0
      end
    end

    it "sets rows_for_parallel" do
      expect(SisBatch.rows_for_parallel(5150)).to eq 100

      Setting.set("sis_batch_rows_for_parallel", "99,25,1000")
      expect(SisBatch.rows_for_parallel(10)).to eq 25
      expect(SisBatch.rows_for_parallel(4_001)).to eq 41
      expect(SisBatch.rows_for_parallel(400_000)).to eq 1_000
    end
  end

  describe ".process_all_for_account" do
    it "processes all non-processed batches for the account" do
      b1 = create_csv_data(["old_id"])
      b2 = create_csv_data(["old_id"])
      create_csv_data(["old_id"])
      b4 = create_csv_data(["old_id"])
      b2.update_attribute(:workflow_state, "imported")
      @a1 = @account
      @a2 = account_model
      b5 = create_csv_data(["old_id"])
      expect_any_instantiation_of(b2).not_to receive(:process_without_send_later)
      expect_any_instantiation_of(b5).not_to receive(:process_without_send_later)
      SisBatch.process_all_for_account(@a1)
      run_jobs
      [b1, b2, b4].each { |batch| expect([:imported, :imported_with_messages]).to include(batch.reload.state) }
    end

    it "aborts non processed sis_batches when aborted" do
      process_csv_data([%(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
)])
      expect(@account.all_courses.where(sis_source_id: "test_1").take.workflow_state).to eq "claimed"
      batch = process_csv_data([%(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,deleted
)],
                               workflow_state: "aborted")
      expect(batch.progress).to eq 100
      expect(batch.workflow_state).to eq "aborted"
      expect(@account.all_courses.where(sis_source_id: "test_1").take.workflow_state).to eq "claimed"
    end

    describe "with parallel importers" do
      before do
        @batch1 = create_csv_data(
          [%(user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active)]
        ) do |sis_batch|
          sis_batch.update batch_mode: true
        end
        @batch2 = create_csv_data(
          [%(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active)]
        )
      end

      it "runs all batches immediately if they are small enough" do
        SisBatch.process_all_for_account(@account)
        expect(@batch1.reload).to be_imported
        expect(@batch1.data[:running_immediately]).to be_truthy
        expect(@batch2.reload).to be_imported
        expect(@batch2.data[:running_immediately]).to be_truthy
      end

      it "queues a new job after a successful parallelized import" do
        Setting.get("sis_batch_parallelism_count_threshold", "1") # force parallelism
        SisBatch.process_all_for_account(@account)
        expect(@batch1.reload).to be_importing
        expect(@batch2.reload).to be_created
        run_jobs # should queue up process_all_for_account again after @batch1 completes
        expect(@batch1.reload).to be_imported
        expect(@batch2.reload).to be_imported
      end
    end

    describe "with non-standard batches" do
      it "only queues one 'process_all_for_account' job and run together" do
        SisBatch.valid_import_types["silly_sis_batch"] = {
          callback: lambda do |batch|
                      batch.data[:silliness_complete] = true
                      batch.finish(true)
                    end
        }
        enable_cache do
          batch1 = @account.sis_batches.create!(workflow_state: "created", data: { import_type: "silly_sis_batch" })
          batch1.process
          batch2 = @account.sis_batches.create!(workflow_state: "created", data: { import_type: "silly_sis_batch" })
          batch2.process
          expect(Delayed::Job.where(tag: "SisBatch.process_all_for_account",
                                    singleton: SisBatch.strand_for_account(@account)).count).to eq 1
          SisBatch.process_all_for_account(@account)
          expect(batch1.reload.data[:silliness_complete]).to be true
          expect(batch2.reload.data[:silliness_complete]).to be true
        end
      ensure
        SisBatch.valid_import_types.delete("silly_sis_batch")
      end
    end
  end

  it "schedules in the future if configured" do
    track_jobs do
      create_csv_data(["abc"], &:process)
    end

    job = created_jobs.find { |j| j.tag == "SisBatch.process_all_for_account" }
    expect(job).to be_present
    expect(job.run_at.to_i).to be <= Time.now.to_i

    job.destroy

    Setting.set("sis_batch_process_start_delay", "120")
    track_jobs do
      create_csv_data(["abc"], &:process)
    end

    job = created_jobs.find { |j| j.tag == "SisBatch.process_all_for_account" }
    expect(job).to be_present
    expect(job.run_at.to_i).to be >= 100.seconds.from_now.to_i
    expect(job.run_at.to_i).to be <= 150.minutes.from_now.to_i
  end

  describe "when the job dies" do
    let!(:batch) do
      batch = nil
      track_jobs do
        batch = create_csv_data(["abc"])
        batch.process
        batch.update_attribute(:workflow_state, "importing")
        batch
      end
      batch
    end

    let!(:job) do
      created_jobs.find { |j| j.tag == "SisBatch.process_all_for_account" }
    end

    before do
      track_jobs { job.reschedule }
    end

    it "enqueue a job to clean up the account associations" do
      job = created_jobs.find { |j| j.tag == "Account#update_account_associations" }
      expect(job).to_not be_nil
    end

    it "must fail itself" do
      expect(batch.reload).to be_failed
    end
  end

  describe "batch mode" do
    it "does not remove anything if no term is given" do
      @subacct = @account.sub_accounts.create(name: "sub1")
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, "term1")
      @term2 = @account.enrollment_terms.create!(name: "term2")
      @previous_batch = @account.sis_batches.create!
      @old_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@subacct.courses, name: "delete me", enrollment_term: @term1, sis_batch_id: @previous_batch.id)
      @c1.offer!
      @c2 = factory_with_protected_attributes(@account.courses, name: "don't delete me", enrollment_term: @term1, sis_source_id: "my_course", root_account: @account)
      @c2.offer!
      @c3 = factory_with_protected_attributes(@account.courses, name: "delete me if terms", enrollment_term: @term2, sis_batch_id: @previous_batch.id)
      @c3.offer!

      # initial import of one course, to test courses that haven't changed at all between imports
      process_csv_data(<<~CSV)
        course_id,short_name,long_name,account_id,term_id,status
        another_course,not-delete,not deleted not changed,,term1,active
      CSV
      @c4 = @account.courses.where(course_code: "not-delete").first

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, name: "delete me", sis_batch_id: @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, name: "don't delete me", sis_source_id: "my_section")
      @s3 = factory_with_protected_attributes(@c3.course_sections, name: "delete me if terms", sis_batch_id: @old_batch.id)
      @s4 = factory_with_protected_attributes(@c2.course_sections, name: "delete me", sis_batch_id: @old_batch.id) # c2 won't be deleted, but this section should still be

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment")
      @e2 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_factory, type: "StudentEnrollment")
      @e3 = factory_with_protected_attributes(@c3.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment")
      @e4 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment") # c2 won't be deleted, but this enrollment should still be
      @e5 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_with_pseudonym, sis_batch_id: @old_batch.id, course_section: @s2, type: "StudentEnrollment") # c2 won't be deleted, and this enrollment sticks around because it's specified in the new csv
      @e5.user.pseudonym.update_attribute(:sis_user_id, "my_user")
      @e5.user.pseudonym.update_attribute(:account_id, @account.id)

      @batch = process_csv_data(
        [
          %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
another_course,not-delete,not deleted not changed,,term1,active),
          %(course_id,user_id,role,status,section_id
test_1,user_1,student,active,
my_course,user_2,student,active,
my_course,my_user,student,active,my_section),
          %(section_id,course_id,name,status
s2,test_1,section2,active),
        ],
        batch_mode: true
      )

      expect(@c1.reload).to be_available
      expect(@c2.reload).to be_available
      expect(@c3.reload).to be_available
      expect(@c4.reload).to be_claimed
      @cnew = @account.reload.courses.where(course_code: "TC 101").first
      expect(@cnew).not_to be_nil
      expect(@cnew.sis_batch_id).to eq @batch.id
      expect(@cnew).to be_claimed

      expect(@s1.reload).to be_active
      expect(@s2.reload).to be_active
      expect(@s3.reload).to be_active
      expect(@s4.reload).to be_active
      @s5 = @cnew.course_sections.where(sis_source_id: "s2").first
      expect(@s5).not_to be_nil

      expect(@e1.reload).to be_active
      expect(@e2.reload).to be_active
      expect(@e3.reload).to be_active
      expect(@e4.reload).to be_active
      expect(@e5.reload).to be_active
    end

    it "removes only from the specific term if it is given" do
      @subacct = @account.sub_accounts.create(name: "sub1")
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, "term1")
      @term2 = @account.enrollment_terms.create!(name: "term2")
      @previous_batch = @account.sis_batches.create!
      @old_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@subacct.courses,
                                              name: "delete me",
                                              enrollment_term: @term1,
                                              sis_source_id: "my_first_course",
                                              sis_batch_id: @previous_batch.id)
      @c1.offer!
      @c2 = factory_with_protected_attributes(@account.courses,
                                              name: "don't delete me",
                                              enrollment_term: @term1,
                                              sis_source_id: "my_course",
                                              root_account: @account)
      @c2.offer!
      @c3 = factory_with_protected_attributes(@account.courses,
                                              name: "delete me if terms",
                                              enrollment_term: @term2,
                                              sis_source_id: "my_third_course",
                                              sis_batch_id: @previous_batch.id)
      @c3.offer!
      @c5 = factory_with_protected_attributes(@account.courses,
                                              name: "don't delete me cause sis was removed",
                                              enrollment_term: @term1,
                                              sis_batch_id: @previous_batch.id,
                                              sis_source_id: nil)
      @c5.offer!

      # initial import of one course, to test courses that haven't changed at all between imports
      process_csv_data([
                         %(course_id,short_name,long_name,account_id,term_id,status
another_course,not-delete,not deleted not changed,,term1,active)
                       ])
      @c4 = @account.courses.where(course_code: "not-delete").first

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections,
                                              name: "delete me",
                                              sis_source_id: "s1",
                                              sis_batch_id: @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections,
                                              name: "don't delete me",
                                              sis_source_id: "my_section")
      @s3 = factory_with_protected_attributes(@c3.course_sections,
                                              name: "delete me if terms",
                                              sis_source_id: "s3",
                                              sis_batch_id: @old_batch.id)
      # c2 won't be deleted, but this section should still be
      @s4 = factory_with_protected_attributes(@c2.course_sections,
                                              name: "delete me",
                                              sis_source_id: "s4",
                                              sis_batch_id: @old_batch.id)
      @sn = factory_with_protected_attributes(@c2.course_sections,
                                              name: "don't delete me, I've lost my sis",
                                              sis_source_id: nil,
                                              sis_batch_id: @old_batch.id)

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment")
      @e2 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_factory, type: "StudentEnrollment")
      @e3 = factory_with_protected_attributes(@c3.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment")
      @e4 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_factory, sis_batch_id: @old_batch.id, type: "StudentEnrollment") # c2 won't be deleted, but this enrollment should still be
      @e5 = factory_with_protected_attributes(@c2.enrollments, workflow_state: "active", user: user_with_pseudonym, sis_batch_id: @old_batch.id, course_section: @s2, type: "StudentEnrollment") # c2 won't be deleted, and this enrollment sticks around because it's specified in the new csv
      @e5.user.pseudonym.update_attribute(:sis_user_id, "my_user")
      @e5.user.pseudonym.update_attribute(:account_id, @account.id)

      @batch = process_csv_data(
        [
          %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
another_course,not-delete,not deleted not changed,,term1,active),
          %(course_id,user_id,role,status,section_id
test_1,user_1,student,active,s2
my_course,user_2,student,active,
my_course,my_user,student,active,my_section),
          %(section_id,course_id,name,status
s2,test_1,section2,active),
        ],
        batch_mode: true,
        batch_mode_term: @term1
      )

      expect(@batch.data[:stack_trace]).to be_nil

      expect(@c1.reload).to be_deleted
      expect(@c1.stuck_sis_fields).not_to include(:workflow_state)
      expect(@c2.reload).to be_available
      expect(@c3.reload).to be_available
      expect(@c4.reload).to be_claimed
      expect(@c5.reload).to be_available
      @cnew = @account.reload.courses.where(course_code: "TC 101").first
      expect(@cnew).not_to be_nil
      expect(@cnew.sis_batch_id).to eq @batch.id
      expect(@cnew).to be_claimed

      expect(@s1.reload).to be_deleted
      expect(@s2.reload).to be_active
      expect(@s3.reload).to be_active
      expect(@s4.reload).to be_deleted
      expect(@sn.reload).to be_active
      @s5 = @cnew.course_sections.where(sis_source_id: "s2").first
      expect(@s5).not_to be_nil

      expect(@e1.reload).to be_deleted
      expect(@e2.reload).to be_active
      expect(@e3.reload).to be_active
      expect(@e4.reload).to be_deleted
      expect(@e5.reload).to be_active
    end

    it "does not do batch mode removals if not in batch mode" do
      @term1 = @account.enrollment_terms.first
      @term2 = @account.enrollment_terms.create!(name: "term2")
      @previous_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@account.courses, name: "delete me", enrollment_term: @term1, sis_batch_id: @previous_batch.id)
      @c1.offer!

      @batch = process_csv_data([
                                  %(course_id,short_name,long_name,account_id,term_id,status
          test_1,TC 101,Test Course 101,,,active)
                                ],
                                batch_mode: false)
      expect(@c1.reload).to be_available
    end

    it "does not do batch mode when there is not batch data types" do
      @term = @account.enrollment_terms.first
      @term.update_attribute(:sis_source_id, "term_1")
      @previous_batch = @account.sis_batches.create!

      batch = create_csv_data([%(user_id,login_id,status
                                 user_1,user_1,active)])
      batch.update(batch_mode: true, batch_mode_term: @term)
      expect_any_instantiation_of(batch).to receive(:remove_previous_imports).once
      expect_any_instantiation_of(batch).not_to receive(:non_batch_courses_scope)
      batch.process_without_send_later
      run_jobs
    end

    it "has correct counts for batch_mode" do
      @term = @account.enrollment_terms.first
      @term.update_attribute(:sis_source_id, "term_1")
      @previous_batch = @account.sis_batches.create!

      process_csv_data(
        [
          %(user_id,login_id,status
          user_1,user_1,active),
          %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active),
          %(section_id,course_id,name,status
          section_1,course_1,section_1,active),
          %(section_id,user_id,role,status
          section_1,user_1,student,active)
        ]
      )

      b = process_csv_data(
        [
          %(user_id,login_id,status),
          %(course_id,short_name,long_name,term_id,status),
          %(section_id,course_id,name,status),
          %(section_id,user_id,role,status)
        ],
        batch_mode: true,
        batch_mode_term: @term
      )
      expect(b.data[:counts][:batch_enrollments_deleted]).to eq 1
      expect(b.data[:counts][:batch_sections_deleted]).to eq 1
      expect(b.data[:counts][:batch_courses_deleted]).to eq 1
    end

    it "only does batch mode removals for supplied data types" do
      @term = @account.enrollment_terms.first
      @term.update_attribute(:sis_source_id, "term_1")
      @previous_batch = @account.sis_batches.create!

      process_csv_data(
        [
          %(user_id,login_id,status
          user_1,user_1,active),
          %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active),
          %(section_id,course_id,name,status
          section_1,course_1,section_1,active),
          %(section_id,user_id,role,status
          section_1,user_1,student,active)
        ]
      )

      @user = Pseudonym.where(sis_user_id: "user_1").first.user
      @section = CourseSection.where(sis_source_id: "section_1").first
      @course = @section.course
      @enrollment1 = @course.student_enrollments.where(user_id: @user).first

      expect(@user).to be_registered
      expect(@section).to be_active
      expect(@course).to be_claimed
      expect(@enrollment1).to be_active

      # only supply enrollments; course and section are left alone
      b = process_csv_data(
        [%(section_id,user_id,role,status
           section_1,user_1,teacher,active)],
        batch_mode: true,
        batch_mode_term: @term
      )

      expect(b.data[:counts][:batch_enrollments_deleted]).to eq 1
      expect(@user.reload).to be_registered
      expect(@section.reload).to be_active
      expect(@course.reload).to be_claimed
      expect(@enrollment1.reload).to be_deleted
      @enrollment2 = @course.teacher_enrollments.where(user_id: @user).first
      expect(@enrollment2).to be_active

      # only supply sections; course left alone
      b = process_csv_data(
        [%(section_id,course_id,name)],
        batch_mode: true,
        batch_mode_term: @term
      )
      expect(@user.reload).to be_registered
      expect(@section.reload).to be_deleted
      @section.enrollments.not_fake.each do |e|
        expect(e).to be_deleted
      end
      expect(@course.reload).to be_claimed
      expect(b.data[:counts][:batch_sections_deleted]).to eq 1

      expect(Auditors::Course).to receive(:record_deleted).once.with(@course, anything, anything)
      # only supply courses
      b = process_csv_data(
        [%(course_id,short_name,long_name,term_id)],
        batch_mode: true,
        batch_mode_term: @term
      )
      expect(b.data[:counts][:batch_courses_deleted]).to eq 1
      expect(@course.reload).to be_deleted
    end

    it "skips deletes if skip_deletes is set" do
      process_csv_data(
        [
          %(user_id,login_id,status
          user_1,user_1,active),
          %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active),
          %(section_id,course_id,name,status
          section_1,course_1,section_1,active),
          %(section_id,user_id,role,status
          section_1,user_1,student,active)
        ]
      )
      batch = create_csv_data(
        [
          %(user_id,login_id,status
          user_1,user_1,deleted),
          %(course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,deleted),
          %(section_id,course_id,name,status
          section_1,course_1,section_1,deleted),
          %(section_id,user_id,role,status
          section_1,user_1,student,deleted)
        ]
      ) do |b|
        b.options = {}
        b.batch_mode = true
        b.options[:skip_deletes] = true
        b.save!
        b.process_without_send_later
        run_jobs
      end
      expect(batch.reload.workflow_state).to eq "imported"
      p = Pseudonym.where(sis_user_id: "user_1").take
      expect(p.workflow_state).to eq "active"
      expect(Course.where(sis_source_id: "course_1").take.workflow_state).to eq "claimed"
      expect(CourseSection.where(sis_source_id: "section_1").take.workflow_state).to eq "active"
      expect(Enrollment.where(user: p.user).take.workflow_state).to eq "active"
    end

    it "treats crosslisted sections as belonging to their original course" do
      @term1 = @account.enrollment_terms.first
      @term2 = @account.enrollment_terms.create!(name: "term2")
      @term2.sis_source_id = "term2"
      @term2.save!
      @previous_batch = @account.sis_batches.create!

      @course1 = @account.courses.build
      @course1.sis_source_id = "c1"
      @course1.save!
      @course2 = @account.courses.build
      @course2.sis_source_id = "c2"
      @course2.enrollment_term = @term2
      @course2.save!
      @section1 = @course1.course_sections.build
      @section1.sis_source_id = "s1"
      @section1.sis_batch_id = @previous_batch.id
      @section1.save!
      @section2 = @course2.course_sections.build
      @section2.sis_source_id = "s2"
      @section2.sis_batch_id = @previous_batch.id
      @section2.save!
      @section2.crosslist_to_course(@course1)

      process_csv_data(
        ["section_id,course_id,name,status}"],
        batch_mode: true,
        batch_mode_term: @term1
      )
      expect(@section1.reload).to be_deleted
      expect(@section2.reload).not_to be_deleted
    end
  end

  it "writes all warnings/errors to a file" do
    batch = @account.sis_batches.create!
    3.times do |i|
      batch.sis_batch_errors.create(root_account: @account, file: "users.csv", message: "some error #{i}", row: i)
    end
    batch.finish(false)
    error_file = batch.reload.errors_attachment
    expect(error_file.display_name).to eq "sis_errors_attachment_#{batch.id}.csv"
    expect(CSV.parse(error_file.open).map.to_a.size).to eq 4 # header and 3 errors
  end

  it "stores error file in instfs if instfs is enabled" do
    # enable instfs
    uuid = "1234-abcd"
    allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)

    # generate some errors
    batch = @account.sis_batches.create!
    3.times do |i|
      batch.sis_batch_errors.create(root_account: @account, file: "users.csv", message: "some error #{i}", row: i)
    end
    batch.finish(false)
    error_file = batch.reload.errors_attachment
    expect(error_file.instfs_uuid).to eq uuid
  end

  context "with csv diffing" do
    it "does not fail for empty diff file" do
      batch0 = create_csv_data([%(user_id,login_id,status)], add_empty_file: true)
      batch0.update(diffing_data_set_identifier: "default", options: { diffing_drop_status: "completed" })
      batch0.process_without_send_later
      batch1 = create_csv_data([%(user_id,login_id,status)], add_empty_file: true)
      batch1.update(diffing_data_set_identifier: "default", options: { diffing_drop_status: "completed" })
      batch1.process_without_send_later

      zip = Zip::File.open(batch1.generated_diff.open.path)
      expect(zip.glob("*.csv").first.get_input_stream.read).to eq(%(user_id,login_id,status\n))
      expect(batch1.workflow_state).to eq "imported"
    end

    it "does not fail for completely empty files" do
      batch0 = create_csv_data([], add_empty_file: true)
      batch0.update(diffing_data_set_identifier: "default", options: { diffing_drop_status: "completed" })
      batch0.process_without_send_later
      batch1 = create_csv_data([], add_empty_file: true)
      batch1.update(diffing_data_set_identifier: "default", options: { diffing_drop_status: "completed" })
      batch1.process_without_send_later
      expect(batch1.reload).to be_imported
    end

    describe "diffing_drop_status" do
      before :once do
        process_csv_data(
          [
            %(user_id,login_id,status
              user_1,user_1,active),
            %(course_id,short_name,long_name,term_id,status
              course_1,course_1,course_1,term_1,active),
            %(section_id,course_id,name,status
              section_1,course_1,section_1,active),
            %(section_id,user_id,role,status
              section_1,user_1,student,active)
          ],
          diffing_data_set_identifier: "default"
        )
      end

      it "uses diffing_drop_status" do
        batch = process_csv_data([%(section_id,user_id,role,status)],
                                 diffing_data_set_identifier: "default",
                                 options: { diffing_drop_status: "completed" })
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob("*.csv")
        expect(csvs.first.get_input_stream.read).to eq(%(section_id,user_id,role,status\nsection_1,user_1,student,completed\n))
      end

      it "does not use diffing_drop_status for non-enrollments" do
        batch = process_csv_data(
          [
            %(user_id,login_id,status)
          ],
          diffing_data_set_identifier: "default",
          options: { diffing_drop_status: "completed" }
        )
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob("*.csv")
        expect(csvs.first.get_input_stream.read).to eq("user_id,login_id,status\nuser_1,user_1,deleted\n")
      end
    end

    describe "diffing_user_remove_status" do
      before :once do
        process_csv_data(
          [
            %(user_id,login_id,status
              user_1,user_1,active,
              user_2,user_2,active)
          ],
          diffing_data_set_identifier: "allotrope"
        )
      end

      it "deletes removed users by default" do
        batch = process_csv_data(
          [
            %(user_id,login_id,status,
              user_2,user_2,active)
          ],
          diffing_data_set_identifier: "allotrope"
        )
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob("*.csv")
        expect(csvs.first.get_input_stream.read).to eq("user_id,login_id,status\nuser_1,user_1,deleted\n")
      end

      it "suspends removed users by request" do
        batch = process_csv_data(
          [
            %(user_id,login_id,status,
              user_2,user_2,active)
          ],
          diffing_data_set_identifier: "allotrope",
          options: { diffing_user_remove_status: "suspended" }
        )
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob("*.csv")
        expect(csvs.first.get_input_stream.read).to eq("user_id,login_id,status\nuser_1,user_1,suspended\n")
      end
    end

    it "skips diffing if previous diff not available" do
      expect_any_instance_of(SIS::CSV::DiffGenerator).not_to receive(:generate)
      batch = process_csv_data([
                                 %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
      )
                               ],
                               diffing_data_set_identifier: "default")
      # but still starts the chain
      expect(batch.diffing_data_set_identifier).to eq "default"
    end

    it "joins the chain but doesn't apply the diff when baseline is set" do
      process_csv_data([
                         %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
)
                       ],
                       diffing_data_set_identifier: "default")

      batch = process_csv_data([
                                 %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
test_4,TC 104,Test Course 104,,term1,active
)
                               ],
                               diffing_data_set_identifier: "default",
                               diffing_remaster: true)
      expect(batch.diffing_data_set_identifier).to eq "default"
      expect(batch.data[:diffed_against_sis_batch_id]).to be_nil
      expect(batch.generated_diff).to be_nil
    end

    it "diffs against the most previous successful batch in the same chain" do
      b1 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
)
                            ],
                            diffing_data_set_identifier: "default")

      process_csv_data([
                         %(course_id,short_name,long_name,account_id,term_id,status
test_2,TC 102,Test Course 102,,term1,active
)
                       ],
                       diffing_data_set_identifier: "other")

      # doesn't diff against failed imports on the chain
      b3 = process_csv_data([
                              %(short_name,long_name,account_id,term_id,status
TC 103,Test Course 103,,term1,active
)
                            ],
                            diffing_data_set_identifier: "default")
      expect(b3.workflow_state).to eq "failed_with_messages"

      batch = process_csv_data([
                                 %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
test_4,TC 104,Test Course 104,,term1,active
)
                               ],
                               diffing_data_set_identifier: "default")

      expect(batch.data[:diffed_against_sis_batch_id]).to eq b1.id
      expect(batch.parallel_importers.count).to eq 1
      expect(batch.parallel_importers.completed.count).to eq 1
      # test_1 should not have been toched by this last batch, since it was diff'd out
      expect(@account.courses.find_by(sis_source_id: "test_1").sis_batch_id).to eq b1.id
      expect(@account.courses.find_by(sis_source_id: "test_4").sis_batch_id).to eq batch.id

      # check the generated csv file, inside the new attached zip
      zip = Zip::File.open(batch.generated_diff.open.path)
      csvs = zip.glob("*.csv")
      expect(csvs.size).to eq 1
      expect(csvs.first.get_input_stream.read).to eq(
        %(course_id,short_name,long_name,account_id,term_id,status
test_4,TC 104,Test Course 104,,term1,active
)
      )
    end

    it "does not diff outside of diff threshold" do
      b1 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104,,term1,active
      )
                            ],
                            diffing_data_set_identifier: "default",
                            change_threshold: 1)

      # small change, less than 1% difference
      b2 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104b,,term1,active
      )
                            ],
                            diffing_data_set_identifier: "default",
                            change_threshold: 1)
      expect(b2.diffing_threshold_exceeded).to be false

      # whoops left out the whole file, don't delete everything.
      b3 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
      )
                            ],
                            diffing_data_set_identifier: "default",
                            change_threshold: 1)
      expect(b3).to be_imported_with_messages
      expect(b3.processing_warnings.first.last).to include("Diffing not performed")
      expect(b3.diffing_threshold_exceeded).to be true

      # no change threshold, _should_ delete everything maybe?
      b4 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
      )
                            ],
                            diffing_data_set_identifier: "default")

      expect(b2.data[:diffed_against_sis_batch_id]).to eq b1.id
      expect(b2.generated_diff_id).not_to be_nil
      expect(b3.data[:diffed_against_sis_batch_id]).to be_nil
      expect(b3.generated_diff_id).to be_nil
      expect(b4.data[:diffed_against_sis_batch_id]).to eq b2.id
      expect(b4.generated_diff_id).to_not be_nil
    end

    it "does not diff outside of diff row count threshold" do
      b1 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104,,term1,active
      )
                            ],
                            diffing_data_set_identifier: "default")

      # only one row change
      b2 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104b,,term1,active
      )
                            ],
                            diffing_data_set_identifier: "default",
                            diff_row_count_threshold: 1)

      # whoops two row changes
      b2b = process_csv_data([
                               %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101b,,term1,active
        test_4,TC 104,Test Course 104c,,term1,active
      )
                             ],
                             diffing_data_set_identifier: "default",
                             diff_row_count_threshold: 1)
      expect(b2b).to be_imported_with_messages
      expect(b2b.processing_warnings.first.last).to include("Diffing not performed")

      # whoops left out the whole file, don't delete everything.
      b3 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
      )
                            ],
                            diffing_data_set_identifier: "default",
                            diff_row_count_threshold: 1)
      expect(b3).to be_imported_with_messages
      expect(b3.processing_warnings.first.last).to include("Diffing not performed")

      # no change threshold, _should_ delete everything maybe?
      b4 = process_csv_data([
                              %(course_id,short_name,long_name,account_id,term_id,status
      )
                            ],
                            diffing_data_set_identifier: "default")

      expect(b2.data[:diffed_against_sis_batch_id]).to eq b1.id
      expect(b2.generated_diff_id).not_to be_nil
      expect(b3.data[:diffed_against_sis_batch_id]).to be_nil
      expect(b3.generated_diff_id).to be_nil
      expect(b4.data[:diffed_against_sis_batch_id]).to eq b2.id
      expect(b4.generated_diff_id).to_not be_nil
    end

    it "marks files separately when created for diffing" do
      f1 = %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active)
      process_csv_data([f1], diffing_data_set_identifier: "default")

      f2 = %(course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104,,term1,active)
      b2 = process_csv_data([f2], diffing_data_set_identifier: "default")

      uploaded = b2.downloadable_attachments(:uploaded)
      expect(uploaded.count).to eq 1
      expect(uploaded.first.open.read).to match_ignoring_whitespace(f2)
      diffed = b2.downloadable_attachments(:diffed)
      expect(diffed.count).to eq 1
      expected_diff = %(course_id,short_name,long_name,account_id,term_id,status
        test_4,TC 104,Test Course 104,,term1,active)
      expect(diffed.first.open.read).to match_ignoring_whitespace(expected_diff)
    end

    it "compares files for diffing correctly" do
      expect(SisBatch.new.file_diff_percent(25, 100)).to eq 75
      expect(SisBatch.new.file_diff_percent(175, 100)).to eq 75
    end

    it "treats role_id as an identifying field for diffs" do
      course_model(account: @account, sis_source_id: "c1")
      user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
      role1 = @account.roles.create!(base_role_type: "TeacherEnrollment", name: "some role")
      role2 = @account.roles.create!(base_role_type: "TeacherEnrollment", name: "some other role")

      process_csv_data([%(course_id,user_id,role_id,status)], diffing_data_set_identifier: "default")
      process_csv_data(
        [%(course_id,user_id,role_id,status
        c1,u1,#{role1.id},active
        c1,u1,#{role2.id},active)],
        diffing_data_set_identifier: "default"
      )

      expect(@user.enrollments.active.pluck(:role_id)).to match_array([role1.id, role2.id])
    end

    it "sets batch_ids on change_sis_id" do
      course1 = @account.courses.build
      course1.sis_source_id = "test_1"
      course1.save!
      b1 = process_csv_data([
                              %(old_id,new_id,type
test_1,test_a,course
)
                            ])
      expect(course1.reload.sis_batch_id).to eq b1.id
      expect(b1.sis_batch_errors.exists?).to be false
    end

    it "retains group memberships when an enrollment role is changed" do
      custom_student_role("Padawan")
      Setting.set("sis_batch_rows_for_parallel", "99,2,1000")
      Setting.set("sis_batch_parallelism_count_threshold", "2")

      process_csv_data([
                         %(course_id,short_name,long_name,status
        A042,ART042,Life the Universe and Everything,active),
                         %(user_id,login_id,status
        U1,U1,active
        U2,U2,active
        U3,U3,active
        U4,U4,active)
                       ])

      process_csv_data([
                         %(course_id,user_id,role,status
                           A042,U1,Student,active
                           A042,U2,Student,active
                           A042,U3,Student,active
                           A042,U4,Student,active),
                         %(term_id,name,status)
                       ],
                       diffing_data_set_identifier: "default")

      course = @account.all_courses.where(sis_source_id: "A042").take
      group = course.groups.create!(name: "Group")
      4.times { |i| group.group_memberships.create!(user: Pseudonym.where(sis_user_id: "U#{i + 1}").take.user) }

      expect(course.enrollments.active.count).to eq 4
      expect(group.group_memberships.active.count).to eq 4

      create_csv_data([
                        %(course_id,user_id,role,status
                          A042,U1,Padawan,active
                          A042,U2,Padawan,active
                          A042,U3,Padawan,active
                          A042,U4,Padawan,active),
                        %(term_id,name,status)
                      ]) do |batch|
        batch.update(diffing_data_set_identifier: "default")
        batch.process_without_send_later

        ir = SIS::CSV::ImportRefactored.new(@account, batch:)
        ei = SIS::CSV::EnrollmentImporter.new(ir)

        pis = batch.parallel_importers

        # Simulate the condition where these are run in parallel and out of order.
        ir.try_importing_segment(nil, pis[3], ei, skip_progress: true)
        ir.try_importing_segment(nil, pis[0], ei, skip_progress: true)
        ir.try_importing_segment(nil, pis[2], ei, skip_progress: true)
        ir.try_importing_segment(nil, pis[1], ei, skip_progress: true)
        ir.finish
      end

      expect(course.enrollments.active.count).to eq 4
      expect(group.group_memberships.active.count).to eq 4
    end

    it "sets batch_ids on admins" do
      u1 = user_with_managed_pseudonym(account: @account, sis_user_id: "U001")
      a1 = @account.account_users.create!(user_id: u1.id)
      b1 = process_csv_data([
                              %(user_id,account_id,role,status
U001,,AccountAdmin,active
)
                            ])
      expect(a1.reload.sis_batch_id).to eq b1.id
      expect(b1.sis_batch_errors.exists?).to be false
    end

    it "does not allow removing import admin with sis import" do
      user_with_managed_pseudonym(account: @account, sis_user_id: "U001")
      b1 = process_csv_data([%(user_id,account_id,role,status
                               U001,,AccountAdmin,deleted)])
      expect(b1.sis_batch_errors.first.message).to eq "Can't remove yourself user_id 'U001'"
      expect(b1.sis_batch_errors.first.file).to eq "csv_0.csv"
    end

    it "does not allow removing import admin user with sis import" do
      p = user_with_managed_pseudonym(account: @account, sis_user_id: "U001").pseudonym
      b1 = process_csv_data([%(user_id,login_id,status
                               U001,#{p.unique_id},deleted)])
      expect(b1.sis_batch_errors.first.message).to eq "Can't remove yourself user_id 'U001'"
      expect(b1.sis_batch_errors.first.file).to eq "csv_0.csv"
    end

    describe "change_threshold in batch mode" do
      before :once do
        @term1 = @account.enrollment_terms.first
        @term1.update_attribute(:sis_source_id, "term1")
        @old_batch = @account.sis_batches.create!

        @c1 = factory_with_protected_attributes(@account.courses,
                                                name: "delete me maybe",
                                                enrollment_term: @term1,
                                                sis_source_id: "test_1",
                                                sis_batch_id: @old_batch.id)

        # enrollments are keyed off what term their course is in
        u1 = user_with_managed_pseudonym({ account: @account, sis_user_id: "u1", active_all: true })
        u2 = user_with_managed_pseudonym({ account: @account, sis_user_id: "u2", active_all: true })
        @e1 = factory_with_protected_attributes(@c1.enrollments,
                                                workflow_state: "active",
                                                user: u1,
                                                sis_batch_id: @old_batch.id,
                                                type: "StudentEnrollment")
        @e2 = factory_with_protected_attributes(@c1.enrollments,
                                                workflow_state: "active",
                                                user: u2,
                                                sis_batch_id: @old_batch.id,
                                                type: "StudentEnrollment")
      end

      it "does not delete batch mode above threshold" do
        batch = process_csv_data(
          [
            %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active),
            %(course_id,user_id,role,status,section_id
test_1,u1,student,active)
          ],
          batch_mode: true,
          batch_mode_term: @term1,
          change_threshold: 20
        )

        expect(batch.workflow_state).to eq "aborted"
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_active
        expect(batch.sis_batch_errors.first.message).to eq "1 enrollments would be deleted and exceeds the set threshold of 20%"
      end

      it "does not delete batch mode if skip_deletes is set" do
        batch = create_csv_data(
          [
            %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active),
            %(course_id,user_id,role,status,section_id
test_1,u1,student,active)
          ]
        ) do |b|
          b.options = {}
          b.batch_mode = true
          b.options[:skip_deletes] = true
          b.save!
          b.process_without_send_later
          run_jobs
        end

        expect(batch.reload.workflow_state).to eq "imported"
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_active
      end

      it "deletes batch mode below threshold" do
        batch = process_csv_data(
          [
            %(course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active),
            %(course_id,user_id,role,status,section_id
test_1,u1,student,active)
          ],
          batch_mode: true,
          batch_mode_term: @term1,
          change_threshold: 50
        )

        expect(batch.workflow_state).to eq "imported"
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_deleted
        expect(batch.processing_errors.size).to eq 0
      end

      it "does not abort batch if it is above the threshold" do
        b1 = process_csv_data([%(course_id,user_id,role,status
                                test_1,u2,student,active)],
                              batch_mode: true,
                              batch_mode_term: @term1,
                              change_threshold: 51)
        expect(b1.workflow_state).to eq "imported"
        expect(@e1.reload).to be_deleted
        expect(@e2.reload).to be_active
        expect(b1.processing_errors.size).to eq 0
      end

      describe "multi_term_batch_mode" do
        before :once do
          @term2 = @account.enrollment_terms.first
          @term2.update_attribute(:sis_source_id, "term2")

          @c2 = factory_with_protected_attributes(@account.courses,
                                                  name: "delete me",
                                                  enrollment_term: @term2,
                                                  sis_source_id: "test_2",
                                                  sis_batch_id: @old_batch.id)
        end

        it "uses multi_term_batch_mode" do
          batch = create_csv_data([
                                    %(term_id,name,status
                                      term1,term1,active
                                      term2,term2,active),
                                    %(course_id,short_name,long_name,account_id,term_id,status),
                                    %(course_id,user_id,role,status),
                                  ]) do |b|
            b.options = {}
            b.batch_mode = true
            b.options[:multi_term_batch_mode] = true
            b.save!
            b.process_without_send_later
            run_jobs
          end
          expect(@e1.reload).to be_deleted
          old_time = @e1.updated_at
          expect(@e2.reload).to be_deleted
          expect(@c1.reload).to be_deleted
          expect(@c2.reload).to be_deleted
          expect(batch.roll_back_data.where(previous_workflow_state: "created").count).to eq 2
          expect(batch.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 4
          expect(batch.reload.workflow_state).to eq "imported"
          # there will be no progress for this batch, but it should still work
          batch.restore_states_for_batch
          run_jobs
          expect(batch.reload).to be_restored
          expect(@e1.reload).to be_active
          expect(@e1.updated_at == old_time).to be false
          expect(@e2.reload).to be_active
          expect(@c1.reload).to be_created
          expect(@c2.reload).to be_created
        end

        it "sets enrollment workflow_state to completed" do
          @e3 = student_in_course(course: @c1, enrollment_state: "completed")
          @e3.update sis_batch_id: @old_batch.id
          batch = create_csv_data([
                                    %(term_id,name,status
                                      term1,term1,active
                                      term2,term2,active),
                                    %(course_id,short_name,long_name,account_id,term_id,status
                                      test_1,TC 101,Test Course 101,,term1,active),
                                    %(course_id,user_id,role,status),
                                  ]) do |item|
            item.options = {}
            item.batch_mode = true
            item.options[:multi_term_batch_mode] = true
            item.options[:batch_mode_enrollment_drop_status] = "completed"
            item.save!
            item.process_without_send_later
            run_jobs
          end
          expect(@e1.reload.workflow_state).to eq "completed"
          expect(@e2.reload.workflow_state).to eq "completed"
          expect(@e3.reload.sis_batch_id).to eq @old_batch.id
          old_time = @e1.updated_at
          expect(@c2.reload).to be_deleted
          expect(batch.roll_back_data.where(previous_workflow_state: "created").count).to eq 1
          expect(batch.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1
          expect(batch.reload.workflow_state).to eq "imported"
          # there will be no progress for this batch, but it should still work
          batch.restore_states_for_batch
          run_jobs
          expect(batch.reload).to be_restored
          expect(@e1.reload).to be_active
          expect(@e1.updated_at == old_time).to be false
          expect(@e2.reload).to be_active
          expect(@c1.reload).to be_created
          expect(@c2.reload).to be_created
        end

        it "sets enrollment workflow_state to inactive" do
          @e3 = student_in_course(course: @c1, enrollment_state: "inactive")
          @e3.update sis_batch_id: @old_batch.id
          batch = create_csv_data([
                                    %(term_id,name,status
                                      term1,term1,active
                                      term2,term2,active),
                                    %(course_id,short_name,long_name,account_id,term_id,status
                                      test_1,TC 101,Test Course 101,,term1,active),
                                    %(course_id,user_id,role,status),
                                  ]) do |item|
            item.options = {}
            item.batch_mode = true
            item.options[:multi_term_batch_mode] = true
            item.options[:batch_mode_enrollment_drop_status] = "inactive"
            item.save!
            item.process_without_send_later
            run_jobs
          end
          expect(@e1.reload.workflow_state).to eq "inactive"
          expect(@e2.reload.workflow_state).to eq "inactive"
          expect(@e3.reload.sis_batch_id).to eq @old_batch.id
          old_time = @e1.updated_at
          expect(@c2.reload).to be_deleted
          expect(batch.roll_back_data.where(previous_workflow_state: "created").count).to eq 1
          expect(batch.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1
          expect(batch.reload.workflow_state).to eq "imported"
          # there will be no progress for this batch, but it should still work
          batch.restore_states_for_batch
          run_jobs
          expect(batch.reload).to be_restored
          expect(@e1.reload).to be_active
          expect(@e1.updated_at == old_time).to be false
          expect(@e2.reload).to be_active
          expect(@c1.reload).to be_created
          expect(@c2.reload).to be_created
        end

        it "does not use multi_term_batch_mode if no terms are passed" do
          batch = create_csv_data([
                                    %(course_id,short_name,long_name,account_id,term_id,status),
                                    %(course_id,user_id,role,status),
                                  ]) do |b|
            b.options = {}
            b.batch_mode = true
            b.options[:multi_term_batch_mode] = true
            b.save!
            b.process_without_send_later
            run_jobs
          end
          expect(@e1.reload).to be_active
          expect(@e2.reload).to be_active
          expect(@c1.reload.workflow_state).to eq "created"
          expect(@c2.reload.workflow_state).to eq "created"
          expect(batch.reload.workflow_state).to eq "aborted"
        end
      end
    end

    it "restores linked observers included in previous batch imports" do
      course = @account.courses.create!(name: "one", sis_source_id: "c1", workflow_state: "available")
      term = @account.enrollment_terms.first
      student = user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
      observer = user_with_managed_pseudonym(account: @account, sis_user_id: "u2")
      UserObservationLink.create_or_restore(observer:, student:, root_account: @account)

      process_csv_data([%(section_id,user_id,role,status,course_id\n,u1,student,active,c1)], batch_mode: true, batch_mode_term: term)
      student_enrollment = course.enrollments.where(user: student).take
      observer_enrollment = course.observer_enrollments.where(user: observer).take
      expect(student_enrollment.workflow_state).to eq "active"
      expect(observer_enrollment.workflow_state).to eq "active"

      process_csv_data([%(section_id,user_id,role,status,course_id,associated_user_id\n,u1,student,deleted,c1,u1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "deleted"
      expect(observer_enrollment.reload.workflow_state).to eq "deleted"

      process_csv_data([%(section_id,user_id,role,status,course_id,associated_user_id\n,u2,observer,active,c1,u1\n,u1,student,active,c1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "active"
      expect(observer_enrollment.reload.workflow_state).to eq "active"

      process_csv_data([%(section_id,user_id,role,status,course_id\n,u1,student,deleted,c1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "deleted"
      expect(observer_enrollment.reload.workflow_state).to eq "deleted"

      process_csv_data([%(section_id,user_id,role,status,course_id\n,u1,student,active,c1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "active"
      expect(observer_enrollment.reload.workflow_state).to eq "active"
    end

    it "restores linked observers removed in previous batch imports" do
      course = @account.courses.create!(name: "one", sis_source_id: "c1", workflow_state: "available")
      term = @account.enrollment_terms.first
      student = user_with_managed_pseudonym(account: @account, sis_user_id: "u1")
      observer = user_with_managed_pseudonym(account: @account, sis_user_id: "u2")
      UserObservationLink.create_or_restore(observer:, student:, root_account: @account)

      process_csv_data([%(section_id,user_id,role,status,course_id\n,u1,student,active,c1)], batch_mode: true, batch_mode_term: term)
      student_enrollment = course.enrollments.where(user: student).take
      observer_enrollment = course.observer_enrollments.where(user: observer).take
      expect(student_enrollment.workflow_state).to eq "active"
      expect(observer_enrollment.workflow_state).to eq "active"

      process_csv_data([%(section_id,user_id,role,status,course_id,associated_user_id\n,u2,observer,active,c1,u1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "deleted"
      expect(observer_enrollment.reload.workflow_state).to eq "deleted"

      process_csv_data([%(section_id,user_id,role,status,course_id\n,u1,student,active,c1)], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload.workflow_state).to eq "active"
      expect(observer_enrollment.reload.workflow_state).to eq "active"
    end

    it "preserves observer enrollments linked to unchanged student enrollments" do
      term = @account.enrollment_terms.first
      course = @account.courses.create!(name: "c1", sis_source_id: "c1", workflow_state: "available", enrollment_term: term)
      course.course_sections.create!(name: "s1", sis_source_id: "s1")
      student = user_with_managed_pseudonym(account: @account, sis_user_id: "stu")
      observer = user_with_managed_pseudonym(account: @account, sis_user_id: "obs")
      UserObservationLink.create_or_restore(observer:, student:, root_account: @account)

      # set up some enrollments outside the batch term so we can verify they are untouched
      other_term = @account.enrollment_terms.create!
      @account.courses.create!(sis_source_id: "other_course", enrollment_term: other_term)
      other_student = user_with_managed_pseudonym(account: @account, sis_user_id: "other_student")
      other_observer = user_with_managed_pseudonym(account: @account, sis_user_id: "other_observer")
      process_csv_data([<<~CSV])
        course_id,user_id,role,associated_user_id,status
        other_course,other_student,student,,active
        other_course,other_observer,observer,other_student,active
      CSV
      other_sis_batch_id = other_observer.enrollments.take.sis_batch_id

      implicit_observer_csv = <<~CSV
        course_id,section_id,user_id,role,status
        c1,s1,stu,student,active
      CSV

      explicit_observer_csv = <<~CSV
        course_id,section_id,user_id,role,associated_user_id,status
        c1,s1,stu,student,,active
        c1,s1,obs,observer,stu,active
      CSV

      process_csv_data([implicit_observer_csv], batch_mode: true, batch_mode_term: term)
      student_enrollment = student.enrollments.take
      observer_enrollment = observer.enrollments.take
      expect(student_enrollment).to be_active
      expect(observer_enrollment).to be_active
      expect(observer_enrollment.sis_batch_id).to be_nil

      process_csv_data([explicit_observer_csv], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload).to be_active
      expect(observer_enrollment.reload).to be_active
      expect(observer_enrollment.sis_batch_id).not_to be_nil

      process_csv_data([implicit_observer_csv], batch_mode: true, batch_mode_term: term)
      expect(student_enrollment.reload).to be_active
      expect(observer_enrollment.reload).to be_active

      expect(other_student.enrollments.take.sis_batch_id).to eq other_sis_batch_id
      expect(other_observer.enrollments.take.sis_batch_id).to eq other_sis_batch_id
    end
  end

  describe "remove_previous_imports" do
    it "refuses to do anything if the batch is already failed" do
      term = Account.default.enrollment_terms.first
      batch = create_csv_data([
                                %(course_id,short_name,long_name,account_id,term_id,status),
                                %(course_id,user_id,role,status),
                              ]) do |b|
        b.options = {}
        b.batch_mode = true
        b.options[:multi_term_batch_mode] = true
        b.batch_mode_term = term
        b.save!
      end
      %w[failed failed_with_messages aborted].each do |status|
        batch.workflow_state = status
        batch.save!
        expect(batch.remove_previous_imports).to be_falsey
      end
    end
  end

  describe "live events" do
    def test_batch
      allow(LiveEvents).to receive(:post_event)
      SisBatch.create(account: @account, workflow_state: :initializing)
    end

    it "triggers live event when created" do
      expect(LiveEvents).to receive(:post_event).with(hash_including({
                                                                       event_name: "sis_batch_created",
                                                                       payload: hash_including({
                                                                                                 account_id: @account.id.to_s,
                                                                                                 workflow_state: "initializing"
                                                                                               }),
                                                                     }))
      test_batch
    end

    it "triggers live event when workflow state is updated" do
      batch = test_batch
      expect(LiveEvents).to receive(:post_event).with(hash_including({
                                                                       event_name: "sis_batch_updated",
                                                                       payload: hash_including({
                                                                                                 account_id: @account.id.to_s,
                                                                                                 workflow_state: "failed"
                                                                                               }),
                                                                     }))
      batch.workflow_state = :failed
      batch.save!
    end

    it "does not trigger live event when workflow state is unchanged" do
      batch = test_batch
      expect(LiveEvents).not_to receive(:post_event).with(hash_including({
                                                                           event_name: "sis_batch_updated"
                                                                         }))
      batch.progress = 1
      batch.save!
    end
  end
end
