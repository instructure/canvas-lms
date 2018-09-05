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

require 'tmpdir'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

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
          data.each do |dat|
            z.get_output_stream("csv_#{i}.csv") { |f| f.puts(dat) }
            i += 1
          end
          z.get_output_stream("csv_#{i}.csv") {} if add_empty_file
        end
      end

      batch = File.open(path, 'rb') do |tmp|
        # arrrgh attachment.rb
        def tmp.original_filename; File.basename(path); end
        SisBatch.create_with_attachment(@account, 'instructure_csv', tmp, @user || user_factory)
      end
      yield batch if block_given?
      batch
    end
  end

  def process_csv_data(data, opts = {})
    create_csv_data(data) do |batch|
      batch.update_attributes(opts) if opts.present?
      batch.process_without_send_later
      run_jobs
      batch.reload
    end
  end

  it "should not add attachments to the list" do
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
  end

  it 'should make file per zip file member' do
    batch = create_csv_data([%{course_id,short_name,long_name,account_id,term_id,status},
                             %{course_id,user_id,role,status,section_id}], add_empty_file: true)
    batch.process_without_send_later
    # 1 zip file and 2 csv files
    atts = Attachment.where(context: batch)
    expect(atts.count).to eq 3
    expect(atts.pluck(:content_type)).to match_array %w(unknown/unknown text/csv text/csv)
  end

  it 'should make parallel importers' do
    @account.enable_feature!(:refactor_of_sis_imports)

    batch = process_csv_data([%{user_id,login_id,status
                                user_1,user_1,active},
                              %{course_id,short_name,long_name,term_id,status
                                course_1,course_1,course_1,term_1,active}])
    expect(batch.parallel_importers.count).to eq 2
    expect(batch.parallel_importers.pluck(:importer_type)).to match_array %w(course user)
    expect(batch.data[:use_parallel_imports]).to eq true
  end

  it "should keep the batch in initializing state during create_with_attachment" do
    batch = SisBatch.create_with_attachment(@account, 'instructure_csv', stub_file_data('test.csv', 'abc', 'text'), user_factory) do |batch|
      expect(batch.attachment).not_to be_new_record
      expect(batch.workflow_state).to eq 'initializing'
      batch.options = { :override_sis_stickiness => true }
    end

    expect(batch.workflow_state).to eq 'created'
    expect(batch).not_to be_new_record
    expect(batch.changed?).to be_falsey
    expect(batch.options[:override_sis_stickiness]).to eq true
  end

  describe "parallel imports" do
    it "should do cool stuff" do
      PluginSetting.create!(name: 'sis_import', settings: {parallelism: '12'})
      @account.enable_feature!(:refactor_of_sis_imports)
      batch = process_csv_data([
        %{user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active
          user_3,user_3,active},
        %{course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active
          course_3,course_3,course_3,term_1,active
          course_4,course_4,course_4,term_1,active}
      ])
      expect(Setting.get("sis_parallel_import/#{@account.global_id}_num_strands", "1")).to eq '12'
      expect(batch.reload).to be_imported
      expect(batch.parallel_importers.group(:importer_type).count).to eq({"course" => 1, "user" => 1})
      expect(batch.parallel_importers.order(:id).pluck(:importer_type, :rows_processed)).to eq [
        ['course', 4], ['user', 3]
      ]
      expect(Pseudonym.where(:sis_user_id => %w{user_1 user_2 user_3}).count).to eq 3
      expect(Course.where(:sis_source_id => %w{course_1 course_2 course_3 course_4}).count).to eq 4
      expect(batch.reload.data[:counts].slice(:users, :courses)).to eq({:users => 3, :courses => 4})
    end

    it 'should set rows_for_parallel' do
      expect(SisBatch.rows_for_parallel(10)).to eq 25
      expect(SisBatch.rows_for_parallel(4_001)).to eq 41
      expect(SisBatch.rows_for_parallel(400_000)).to eq 1_000
    end
  end

  describe ".process_all_for_account" do
    it "should process all non-processed batches for the account" do
      b1 = create_csv_data(['old_id'])
      b2 = create_csv_data(['old_id'])
      b3 = create_csv_data(['old_id'])
      b4 = create_csv_data(['old_id'])
      b2.update_attribute(:workflow_state, 'imported')
      @a1 = @account
      @a2 = account_model
      b5 = create_csv_data(['old_id'])
      expect_any_instantiation_of(b2).to receive(:process_without_send_later).never
      expect_any_instantiation_of(b5).to receive(:process_without_send_later).never
      SisBatch.process_all_for_account(@a1)
      run_jobs
      [b1, b2, b4].each { |batch| expect([:imported, :imported_with_messages]).to be_include(batch.reload.state) }
    end

    it 'should abort non processed sis_batches when aborted' do
      process_csv_data([%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
}])
      expect(@account.all_courses.where(sis_source_id: 'test_1').take.workflow_state).to eq 'claimed'
      batch = process_csv_data([%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,deleted
}], workflow_state: 'aborted')
      expect(batch.progress).to eq 100
      expect(batch.workflow_state).to eq 'aborted'
      expect(@account.all_courses.where(sis_source_id: 'test_1').take.workflow_state).to eq 'claimed'
    end

    describe "with parallel importers" do
      before :each do
        @account.enable_feature!(:refactor_of_sis_imports)
        @batch1 = create_csv_data(
          [%{user_id,login_id,status
          user_1,user_1,active
          user_2,user_2,active}])
        @batch2 = create_csv_data(
          [%{course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active
          course_2,course_2,course_2,term_1,active}])
      end

      it "should run all batches immediately if they are small enough" do
        SisBatch.process_all_for_account(@account)
        expect(@batch1.reload).to be_imported
        expect(@batch1.data[:running_immediately]).to be_truthy
        expect(@batch2.reload).to be_imported
        expect(@batch2.data[:running_immediately]).to be_truthy
      end

      it "should queue a new job after a successful parallelized import" do
        Setting.get('sis_batch_parallelism_count_threshold', '1') # force parallelism
        SisBatch.process_all_for_account(@account)
        expect(@batch1.reload).to be_importing
        expect(@batch2.reload).to be_created
        run_jobs # should queue up process_all_for_account again after @batch1 completes
        expect(@batch1.reload).to be_imported
        expect(@batch2.reload).to be_imported
      end
    end

    describe "with non-standard batches" do
      it "should only queue one 'process_all_for_account' job and run together" do
        begin
          @account.enable_feature!(:refactor_of_sis_imports)
          SisBatch.valid_import_types["silly_sis_batch"] = {
            :callback => lambda {|batch| batch.data[:silliness_complete] = true; batch.finish(true) }
          }
          enable_cache do
            batch1 = @account.sis_batches.create!(:workflow_state => "created", :data => {:import_type => "silly_sis_batch"})
            batch1.process
            batch2 = @account.sis_batches.create!(:workflow_state => "created", :data => {:import_type => "silly_sis_batch"})
            batch2.process
            expect(Delayed::Job.where(:tag => "SisBatch.process_all_for_account",
              :strand => SisBatch.strand_for_account(@account)).count).to eq 1
            SisBatch.process_all_for_account(@account)
            expect(batch1.reload.data[:silliness_complete]).to eq true
            expect(batch2.reload.data[:silliness_complete]).to eq true
          end
        ensure
          SisBatch.valid_import_types.delete("silly_sis_batch")
        end
      end
    end
  end

  it "should schedule in the future if configured" do
    track_jobs do
      create_csv_data(['abc']) do |batch|
        batch.process
      end
    end

    job = created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    expect(job).to be_present
    expect(job.run_at.to_i).to be <= Time.now.to_i

    job.destroy

    Setting.set('sis_batch_process_start_delay', '120')
    track_jobs do
      create_csv_data(['abc']) do |batch|
        batch.process
      end
    end

    job = created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    expect(job).to be_present
    expect(job.run_at.to_i).to be >= 100.seconds.from_now.to_i
    expect(job.run_at.to_i).to be <= 150.minutes.from_now.to_i
  end

  describe 'when the job dies' do
    let!(:batch) {
      batch = nil
      track_jobs do
        batch = create_csv_data(['abc'])
        batch.process
        batch.update_attribute(:workflow_state, 'importing')
        batch
      end
      batch
    }

    let!(:job) {
      created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    }

    before do
      track_jobs { job.reschedule }
    end

    it 'enqueue a job to clean up the account associations' do
      job = created_jobs.find{ |j| j.tag == 'Account#update_account_associations' }
      expect(job).to_not be_nil
    end

    it 'must fail itself' do
      expect(batch.reload).to be_failed
    end
  end

  shared_examples_for 'sis_import_feature' do
  describe "batch mode" do
    it "should not remove anything if no term is given" do
      @subacct = @account.sub_accounts.create(:name => 'sub1')
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, 'term1')
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = @account.sis_batches.create!
      @old_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@subacct.courses, :name => "delete me", :enrollment_term => @term1, :sis_batch_id => @previous_batch.id)
      @c1.offer!
      @c2 = factory_with_protected_attributes(@account.courses, :name => "don't delete me", :enrollment_term => @term1, :sis_source_id => 'my_course', :root_account => @account)
      @c2.offer!
      @c3 = factory_with_protected_attributes(@account.courses, :name => "delete me if terms", :enrollment_term => @term2, :sis_batch_id => @previous_batch.id)
      @c3.offer!

      # initial import of one course, to test courses that haven't changed at all between imports
      process_csv_data([
        "course_id,short_name,long_name,account_id,term_id,status\n" +
        "another_course,not-delete,not deleted not changed,,term1,active"
      ])
      @c4 = @account.courses.where(course_code: 'not-delete').first

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, :name => "don't delete me", :sis_source_id => 'my_section')
      @s3 = factory_with_protected_attributes(@c3.course_sections, :name => "delete me if terms", :sis_batch_id => @old_batch.id)
      @s4 = factory_with_protected_attributes(@c2.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this section should still be

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_factory, :type => 'StudentEnrollment')
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment') # c2 won't be deleted, but this enrollment should still be
      @e5 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_with_pseudonym, :sis_batch_id => @old_batch.id, :course_section => @s2, :type => 'StudentEnrollment') # c2 won't be deleted, and this enrollment sticks around because it's specified in the new csv
      @e5.user.pseudonym.update_attribute(:sis_user_id, 'my_user')
      @e5.user.pseudonym.update_attribute(:account_id, @account.id)

      @batch = process_csv_data(
        [
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
another_course,not-delete,not deleted not changed,,term1,active},
%{course_id,user_id,role,status,section_id
test_1,user_1,student,active,
my_course,user_2,student,active,
my_course,my_user,student,active,my_section},
%{section_id,course_id,name,status
s2,test_1,section2,active},
        ],
        :batch_mode => true)

      expect(@c1.reload).to be_available
      expect(@c2.reload).to be_available
      expect(@c3.reload).to be_available
      expect(@c4.reload).to be_claimed
      @cnew = @account.reload.courses.where(course_code: 'TC 101').first
      expect(@cnew).not_to be_nil
      expect(@cnew.sis_batch_id).to eq @batch.id
      expect(@cnew).to be_claimed

      expect(@s1.reload).to be_active
      expect(@s2.reload).to be_active
      expect(@s3.reload).to be_active
      expect(@s4.reload).to be_active
      @s5 = @cnew.course_sections.where(sis_source_id: 's2').first
      expect(@s5).not_to be_nil

      expect(@e1.reload).to be_active
      expect(@e2.reload).to be_active
      expect(@e3.reload).to be_active
      expect(@e4.reload).to be_active
      expect(@e5.reload).to be_active
    end

    def test_remove_specific_term
      @subacct = @account.sub_accounts.create(:name => 'sub1')
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, 'term1')
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = @account.sis_batches.create!
      @old_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@subacct.courses, name: "delete me", enrollment_term: @term1,
                                              sis_source_id: 'my_first_course', sis_batch_id: @previous_batch.id)
      @c1.offer!
      @c2 = factory_with_protected_attributes(@account.courses, name: "don't delete me", enrollment_term: @term1,
                                              sis_source_id: 'my_course', root_account: @account)
      @c2.offer!
      @c3 = factory_with_protected_attributes(@account.courses, name: "delete me if terms", enrollment_term: @term2,
                                              sis_source_id: 'my_third_course', sis_batch_id: @previous_batch.id)
      @c3.offer!
      @c5 = factory_with_protected_attributes(@account.courses, name: "don't delete me cause sis was removed",
                                              enrollment_term: @term1, sis_batch_id: @previous_batch.id, sis_source_id: nil)
      @c5.offer!

      # initial import of one course, to test courses that haven't changed at all between imports
      process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
another_course,not-delete,not deleted not changed,,term1,active}
      ])
      @c4 = @account.courses.where(course_code: 'not-delete').first

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, name: "delete me",
                                              sis_source_id: 's1', sis_batch_id: @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, name: "don't delete me",
                                              sis_source_id: 'my_section')
      @s3 = factory_with_protected_attributes(@c3.course_sections, name: "delete me if terms",
                                              sis_source_id: 's3', sis_batch_id: @old_batch.id)
      # c2 won't be deleted, but this section should still be
      @s4 = factory_with_protected_attributes(@c2.course_sections, name: "delete me",
                                              sis_source_id: 's4', sis_batch_id: @old_batch.id)
      @sn = factory_with_protected_attributes(@c2.course_sections, name: "don't delete me, I've lost my sis",
                                              sis_source_id: nil, sis_batch_id: @old_batch.id)

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_factory, :type => 'StudentEnrollment')
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_factory, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment') # c2 won't be deleted, but this enrollment should still be
      @e5 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_with_pseudonym, :sis_batch_id => @old_batch.id, :course_section => @s2, :type => 'StudentEnrollment') # c2 won't be deleted, and this enrollment sticks around because it's specified in the new csv
      @e5.user.pseudonym.update_attribute(:sis_user_id, 'my_user')
      @e5.user.pseudonym.update_attribute(:account_id, @account.id)

      @batch = process_csv_data(
        [
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
another_course,not-delete,not deleted not changed,,term1,active},
%{course_id,user_id,role,status,section_id
test_1,user_1,student,active,s2
my_course,user_2,student,active,
my_course,my_user,student,active,my_section},
%{section_id,course_id,name,status
s2,test_1,section2,active},
        ],
        :batch_mode => true,
        :batch_mode_term => @term1)

      expect(@batch.data[:stack_trace]).to be_nil

      expect(@c1.reload).to be_deleted
      expect(@c1.stuck_sis_fields).not_to be_include(:workflow_state)
      expect(@c2.reload).to be_available
      expect(@c3.reload).to be_available
      expect(@c4.reload).to be_claimed
      expect(@c5.reload).to be_available
      @cnew = @account.reload.courses.where(course_code: 'TC 101').first
      expect(@cnew).not_to be_nil
      expect(@cnew.sis_batch_id).to eq @batch.id
      expect(@cnew).to be_claimed

      expect(@s1.reload).to be_deleted
      expect(@s2.reload).to be_active
      expect(@s3.reload).to be_active
      expect(@s4.reload).to be_deleted
      expect(@sn.reload).to be_active
      @s5 = @cnew.course_sections.where(sis_source_id: 's2').first
      expect(@s5).not_to be_nil

      expect(@e1.reload).to be_deleted
      expect(@e2.reload).to be_active
      expect(@e3.reload).to be_active
      expect(@e4.reload).to be_deleted
      expect(@e5.reload).to be_active

    end

    describe "with cursor based find_each" do
      it "should remove only from the specific term if it is given" do
        Course.transaction {
          test_remove_specific_term
        }
      end
    end

    describe "without cursor based find_each" do
      it "should remove only from the specific term if it is given" do
        test_remove_specific_term
      end
    end

    it "shouldn't do batch mode removals if not in batch mode" do
      @term1 = @account.enrollment_terms.first
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = @account.sis_batches.create!

      @c1 = factory_with_protected_attributes(@account.courses, :name => "delete me", :enrollment_term => @term1, :sis_batch_id => @previous_batch.id)
      @c1.offer!

      @batch = process_csv_data([
        %{course_id,short_name,long_name,account_id,term_id,status
          test_1,TC 101,Test Course 101,,,active}],
        :batch_mode => false)
      expect(@c1.reload).to be_available
    end

    it "shouldn't do batch mode when there is not batch data types" do
      @term = @account.enrollment_terms.first
      @term.update_attribute(:sis_source_id, 'term_1')
      @previous_batch = @account.sis_batches.create!

      batch = create_csv_data([%{user_id,login_id,status
                                 user_1,user_1,active}])
      batch.update_attributes(batch_mode: true, batch_mode_term: @term)
      expect_any_instantiation_of(batch).to receive(:remove_previous_imports).once
      expect_any_instantiation_of(batch).to receive(:non_batch_courses_scope).never
      batch.process_without_send_later
      run_jobs
    end

    it "should only do batch mode removals for supplied data types" do
      @term = @account.enrollment_terms.first
      @term.update_attribute(:sis_source_id, 'term_1')
      @previous_batch = @account.sis_batches.create!

      process_csv_data(
          [
          %{user_id,login_id,status
          user_1,user_1,active},
          %{course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active},
          %{section_id,course_id,name,status
          section_1,course_1,section_1,active},
          %{section_id,user_id,role,status
          section_1,user_1,student,active}
          ])

      @user = Pseudonym.where(sis_user_id: 'user_1').first.user
      @section = CourseSection.where(sis_source_id: 'section_1').first
      @course = @section.course
      @enrollment1 = @course.student_enrollments.where(user_id: @user).first

      expect(@user).to be_registered
      expect(@section).to be_active
      expect(@course).to be_claimed
      expect(@enrollment1).to be_active

      # only supply enrollments; course and section are left alone
      b = process_csv_data(
        [%{section_id,user_id,role,status
           section_1,user_1,teacher,active}],
        :batch_mode => true, :batch_mode_term => @term)

      expect(b.data[:counts][:batch_enrollments_deleted]).to eq 1
      expect(@user.reload).to be_registered
      expect(@section.reload).to be_active
      expect(@course.reload).to be_claimed
      expect(@enrollment1.reload).to be_deleted
      @enrollment2 = @course.teacher_enrollments.where(user_id: @user).first
      expect(@enrollment2).to be_active

      # only supply sections; course left alone
      b = process_csv_data(
        [%{section_id,course_id,name}],
        :batch_mode => true, :batch_mode_term => @term)
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
        [%{course_id,short_name,long_name,term_id}],
        :batch_mode => true, :batch_mode_term => @term)
      expect(b.data[:counts][:batch_courses_deleted]).to eq 1
      expect(@course.reload).to be_deleted
    end

    it "should skip deletes if skip_deletes is set" do
      process_csv_data(
        [
          %{user_id,login_id,status
          user_1,user_1,active},
          %{course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,active},
          %{section_id,course_id,name,status
          section_1,course_1,section_1,active},
          %{section_id,user_id,role,status
          section_1,user_1,student,active}
        ])
      batch = create_csv_data(
        [
          %{user_id,login_id,status
          user_1,user_1,deleted},
          %{course_id,short_name,long_name,term_id,status
          course_1,course_1,course_1,term_1,deleted},
          %{section_id,course_id,name,status
          section_1,course_1,section_1,deleted},
          %{section_id,user_id,role,status
          section_1,user_1,student,deleted}
        ]) do |batch|
        batch.options = {}
        batch.batch_mode = true
        batch.options[:skip_deletes] = true
        batch.save!
        batch.process_without_send_later
        run_jobs
      end
      expect(batch.reload.workflow_state).to eq 'imported'
      p = Pseudonym.where(sis_user_id: 'user_1').take
      expect(p.workflow_state).to eq 'active'
      expect(Course.where(sis_source_id: 'course_1').take.workflow_state).to eq 'claimed'
      expect(CourseSection.where(sis_source_id: 'section_1').take.workflow_state).to eq 'active'
      expect(Enrollment.where(user: p.user).take.workflow_state).to eq 'active'
    end

    it "should treat crosslisted sections as belonging to their original course" do
      @term1 = @account.enrollment_terms.first
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @term2.sis_source_id = 'term2'; @term2.save!
      @previous_batch = @account.sis_batches.create!

      @course1 = @account.courses.build
      @course1.sis_source_id = 'c1'
      @course1.save!
      @course2 = @account.courses.build
      @course2.sis_source_id = 'c2'
      @course2.enrollment_term = @term2
      @course2.save!
      @section1 = @course1.course_sections.build
      @section1.sis_source_id = 's1'
      @section1.sis_batch_id = @previous_batch.id
      @section1.save!
      @section2 = @course2.course_sections.build
      @section2.sis_source_id = 's2'
      @section2.sis_batch_id = @previous_batch.id
      @section2.save!
      @section2.crosslist_to_course(@course1)

      process_csv_data(
          ['section_id,course_id,name,status}'],
          :batch_mode => true, :batch_mode_term => @term1)
      expect(@section1.reload).to be_deleted
      expect(@section2.reload).not_to be_deleted
    end
  end
  end

  context 'sis_import_feature on' do
    include_examples 'sis_import_feature'
    before do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:refactor_of_sis_imports).and_return(true)
    end
  end

  context 'sis_import_feature off' do
    include_examples 'sis_import_feature'
    before do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_call_original
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:refactor_of_sis_imports).and_return(false)
    end
  end

  it "should write all warnings/errors to a file" do
    batch = @account.sis_batches.create!
    3.times do |i|
      batch.sis_batch_errors.create(root_account: @account, file: 'users.csv', message: "some error #{i}", row: i)
    end
    batch.finish(false)
    error_file = batch.reload.errors_attachment
    expect(error_file.display_name).to eq "sis_errors_attachment_#{batch.id}.csv"
    expect(CSV.parse(error_file.open).map.to_a.size).to eq 4 # header and 3 errors
  end

  it "should store error file in instfs if instfs is enabled" do
    # enable instfs
    allow(InstFS).to receive(:enabled?).and_return(true)
    uuid = "1234-abcd"
    allow(InstFS).to receive(:direct_upload).and_return(uuid)

    # generate some errors
    batch = @account.sis_batches.create!
    3.times do |i|
      batch.sis_batch_errors.create(root_account: @account, file: 'users.csv', message: "some error #{i}", row: i)
    end
    batch.finish(false)
    error_file = batch.reload.errors_attachment
    expect(error_file.instfs_uuid).to eq uuid
  end

  context "with csv diffing" do

    it 'should not fail for empty diff file' do
      batch0 = create_csv_data([%{user_id,login_id,status}], add_empty_file: true)
      batch0.update_attributes(diffing_data_set_identifier: 'default', options: {diffing_drop_status: 'completed'})
      batch0.process_without_send_later
      batch1 = create_csv_data([%{user_id,login_id,status}], add_empty_file: true)
      batch1.update_attributes(diffing_data_set_identifier: 'default', options: {diffing_drop_status: 'completed'})
      batch1.process_without_send_later

      zip = Zip::File.open(batch1.generated_diff.open.path)
      expect(zip.glob('*.csv').first.get_input_stream.read).to eq(%{user_id,login_id,status\n})
      expect(batch1.workflow_state).to eq 'imported'
    end

    it 'should not fail for completely empty files' do
      batch0 = create_csv_data([], add_empty_file: true)
      batch0.update_attributes(diffing_data_set_identifier: 'default', options: {diffing_drop_status: 'completed'})
      batch0.process_without_send_later
      batch1 = create_csv_data([], add_empty_file: true)
      batch1.update_attributes(diffing_data_set_identifier: 'default', options: {diffing_drop_status: 'completed'})
      batch1.process_without_send_later
      expect(batch1.reload).to be_imported
    end

    describe 'diffing_drop_status' do
      before :once do
        process_csv_data(
          [
            %{user_id,login_id,status
              user_1,user_1,active},
            %{course_id,short_name,long_name,term_id,status
              course_1,course_1,course_1,term_1,active},
            %{section_id,course_id,name,status
              section_1,course_1,section_1,active},
            %{section_id,user_id,role,status
              section_1,user_1,student,active}
          ], diffing_data_set_identifier: 'default')
      end

      it 'should use diffing_drop_status' do
        batch = process_csv_data([%{section_id,user_id,role,status}],
                                 diffing_data_set_identifier: 'default',
                                 options: {diffing_drop_status: 'completed'})
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob('*.csv')
        expect(csvs.first.get_input_stream.read).to eq(%{section_id,user_id,role,status\nsection_1,user_1,student,completed\n})
      end

      it 'should not use diffing_drop_status for non-enrollments' do
        batch = process_csv_data(
          [
            %{user_id,login_id,status}
          ], diffing_data_set_identifier: 'default', options: {diffing_drop_status: 'completed'})
        zip = Zip::File.open(batch.generated_diff.open.path)
        csvs = zip.glob('*.csv')
        expect(csvs.first.get_input_stream.read).to eq("user_id,login_id,status\nuser_1,user_1,deleted\n")
      end
    end

    it "should skip diffing if previous diff not available" do
      expect_any_instance_of(SIS::CSV::DiffGenerator).to receive(:generate).never
      batch = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
      }], diffing_data_set_identifier: 'default')
      # but still starts the chain
      expect(batch.diffing_data_set_identifier).to eq 'default'
    end

    it "joins the chain but doesn't apply the diff when baseline is set" do
      b1 = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
}], diffing_data_set_identifier: 'default')

      batch = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
test_4,TC 104,Test Course 104,,term1,active
}], diffing_data_set_identifier: 'default', diffing_remaster: true)
      expect(batch.diffing_data_set_identifier).to eq 'default'
      expect(batch.data[:diffed_against_sis_batch_id]).to eq nil
      expect(batch.generated_diff).to eq nil
    end

    it "should diff against the most previous successful batch in the same chain" do
      b1 = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
}], diffing_data_set_identifier: 'default')

      b2 = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_2,TC 102,Test Course 102,,term1,active
}], diffing_data_set_identifier: 'other')

      # doesn't diff against failed imports on the chain
      b3 = process_csv_data([
%{short_name,long_name,account_id,term_id,status
TC 103,Test Course 103,,term1,active
}], diffing_data_set_identifier: 'default')
      expect(b3.workflow_state).to eq 'failed_with_messages'

      batch = process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active
test_4,TC 104,Test Course 104,,term1,active
}], diffing_data_set_identifier: 'default')

      expect(batch.data[:diffed_against_sis_batch_id]).to eq b1.id
      # test_1 should not have been toched by this last batch, since it was diff'd out
      expect(@account.courses.find_by_sis_source_id('test_1').sis_batch_id).to eq b1.id
      expect(@account.courses.find_by_sis_source_id('test_4').sis_batch_id).to eq batch.id

      # check the generated csv file, inside the new attached zip
      zip = Zip::File.open(batch.generated_diff.open.path)
      csvs = zip.glob('*.csv')
      expect(csvs.size).to eq 1
      expect(csvs.first.get_input_stream.read).to eq(
%{course_id,short_name,long_name,account_id,term_id,status
test_4,TC 104,Test Course 104,,term1,active
})
    end

    it 'should not diff outside of diff threshold' do
      b1 = process_csv_data([
        %{course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104,,term1,active
      }], diffing_data_set_identifier: 'default', change_threshold: 1)

      # small change, less than 1% difference
      b2 = process_csv_data([
        %{course_id,short_name,long_name,account_id,term_id,status
        test_1,TC 101,Test Course 101,,term1,active
        test_4,TC 104,Test Course 104b,,term1,active
      }], diffing_data_set_identifier: 'default', change_threshold: 1)

      # whoops left out the whole file, don't delete everything.
      b3 = process_csv_data([
        %{course_id,short_name,long_name,account_id,term_id,status
      }], diffing_data_set_identifier: 'default', change_threshold: 1)
      expect(b3).to be_imported_with_messages
      expect(b3.processing_warnings.first.last).to include("Diffing not performed")

      # no change threshold, _should_ delete everything maybe?
      b4 = process_csv_data([
        %{course_id,short_name,long_name,account_id,term_id,status
      }], diffing_data_set_identifier: 'default')

      expect(b2.data[:diffed_against_sis_batch_id]).to eq b1.id
      expect(b2.generated_diff_id).not_to be_nil
      expect(b3.data[:diffed_against_sis_batch_id]).to be_nil
      expect(b3.generated_diff_id).to be_nil
      expect(b4.data[:diffed_against_sis_batch_id]).to eq b2.id
      expect(b4.generated_diff_id).to_not be_nil
    end

    it 'should set batch_ids on change_sis_id' do
      course1 = @account.courses.build
      course1.sis_source_id = 'test_1'
      course1.save!
      b1 = process_csv_data([
%{old_id,new_id,type
test_1,test_a,course
}])
      expect(course1.reload.sis_batch_id).to eq b1.id
      expect(b1.sis_batch_errors.exists?).to eq false
    end

    it 'should set batch_ids on admins' do
      u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
      a1 = @account.account_users.create!(user_id: u1.id)
      b1 = process_csv_data([
%{user_id,account_id,role,status
U001,,AccountAdmin,active
}])
      expect(a1.reload.sis_batch_id).to eq b1.id
      expect(b1.sis_batch_errors.exists?).to eq false
    end

    it 'should not allow removing import admin with sis import' do
      user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
      b1 = process_csv_data([%{user_id,account_id,role,status
                               U001,,AccountAdmin,deleted}])
      expect(b1.sis_batch_errors.first.message).to eq "Can't remove yourself user_id 'U001'"
      expect(b1.sis_batch_errors.first.file).to eq "csv_0.csv"
    end

    it 'should not allow removing import admin user with sis import' do
      p = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001').pseudonym
      b1 = process_csv_data([%{user_id,login_id,status
                               U001,#{p.unique_id},deleted}])
      expect(b1.sis_batch_errors.first.message).to eq "Can't remove yourself user_id 'U001'"
      expect(b1.sis_batch_errors.first.file).to eq "csv_0.csv"
    end

    describe 'change_threshold in batch mode' do
      before :once do
        @term1 = @account.enrollment_terms.first
        @term1.update_attribute(:sis_source_id, 'term1')
        @old_batch = @account.sis_batches.create!

        @c1 = factory_with_protected_attributes(@account.courses, name: "delete me maybe", enrollment_term: @term1,
                                                sis_source_id: 'test_1', sis_batch_id: @old_batch.id)

        # enrollments are keyed off what term their course is in
        u1 = user_with_managed_pseudonym({account: @account, sis_user_id: 'u1', active_all: true})
        u2 = user_with_managed_pseudonym({account: @account, sis_user_id: 'u2', active_all: true})
        @e1 = factory_with_protected_attributes(@c1.enrollments, workflow_state: 'active',
                                                user: u1, sis_batch_id: @old_batch.id, type: 'StudentEnrollment')
        @e2 = factory_with_protected_attributes(@c1.enrollments, workflow_state: 'active',
                                                user: u2, sis_batch_id: @old_batch.id, type: 'StudentEnrollment')
      end

      it 'should not delete batch mode above threshold' do
        batch = process_csv_data(
          [
            %{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active},
            %{course_id,user_id,role,status,section_id
test_1,u1,student,active}
          ],
          batch_mode: true,
          batch_mode_term: @term1,
          change_threshold: 20)

        expect(batch.workflow_state).to eq 'aborted'
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_active
        expect(batch.sis_batch_errors.first.message).to eq "1 enrollments would be deleted and exceeds the set threshold of 20%"
      end

      it 'should not delete batch mode if skip_deletes is set' do
        batch = create_csv_data(
          [
            %{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active},
            %{course_id,user_id,role,status,section_id
test_1,u1,student,active}
          ]) do |batch|
          batch.options = {}
          batch.batch_mode = true
          batch.options[:skip_deletes] = true
          batch.save!
          batch.process_without_send_later
          run_jobs
        end

        expect(batch.workflow_state).to eq 'imported'
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_active
      end

      it 'should delete batch mode below threshold' do
        batch = process_csv_data(
          [
            %{course_id,short_name,long_name,account_id,term_id,status
test_1,TC 101,Test Course 101,,term1,active},
            %{course_id,user_id,role,status,section_id
test_1,u1,student,active}
          ],
          batch_mode: true,
          batch_mode_term: @term1,
          change_threshold: 50)

        expect(batch.workflow_state).to eq 'imported'
        expect(@e1.reload).to be_active
        expect(@e2.reload).to be_deleted
        expect(batch.processing_errors.size).to eq 0
      end

      it 'should not abort batch if it is above the threshold' do
        b1 = process_csv_data([%{course_id,user_id,role,status
                                test_1,u2,student,active}],
                              batch_mode: true,
                              batch_mode_term: @term1,
                              change_threshold: 51)
        expect(b1.workflow_state).to eq 'imported'
        expect(@e1.reload).to be_deleted
        expect(@e2.reload).to be_active
        expect(b1.processing_errors.size).to eq 0
      end

      describe 'multi_term_batch_mode' do
        before :once do
          @term2 = @account.enrollment_terms.first
          @term2.update_attribute(:sis_source_id, 'term2')

          @c2 = factory_with_protected_attributes(@account.courses, name: "delete me", enrollment_term: @term2,
                                                  sis_source_id: 'test_2', sis_batch_id: @old_batch.id)
        end

        it 'should use multi_term_batch_mode' do
          @account.enable_feature!(:refactor_of_sis_imports)
          batch = create_csv_data([
                                    %{term_id,name,status
                                      term1,term1,active
                                      term2,term2,active},
                                    %{course_id,short_name,long_name,account_id,term_id,status},
                                    %{course_id,user_id,role,status},
                                  ]) do |batch|
            batch.options = {}
            batch.batch_mode = true
            batch.options[:multi_term_batch_mode] = true
            batch.save!
            batch.process_without_send_later
            run_jobs
          end
          expect(@e1.reload).to be_deleted
          expect(@e2.reload).to be_deleted
          expect(@c1.reload).to be_deleted
          expect(@c2.reload).to be_deleted
          expect(batch.roll_back_data.where(previous_workflow_state: 'created').count).to eq 2
          expect(batch.roll_back_data.where(updated_workflow_state: 'deleted').count).to eq 6
          expect(batch.reload.workflow_state).to eq 'imported'
          # there will be no progress for this batch, but it should still work
          batch.restore_states_for_batch
          run_jobs
          expect(batch.reload).to be_restored
          expect(@e1.reload).to be_active
          expect(@e2.reload).to be_active
          expect(@c1.reload).to be_created
          expect(@c2.reload).to be_created
        end

        it 'should not use multi_term_batch_mode if no terms are passed' do
          batch = create_csv_data([
                                    %{course_id,short_name,long_name,account_id,term_id,status},
                                    %{course_id,user_id,role,status},
                                  ]) do |batch|
            batch.options = {}
            batch.batch_mode = true
            batch.options[:multi_term_batch_mode] = true
            batch.save!
            batch.process_without_send_later
            run_jobs
          end
          expect(@e1.reload).to be_active
          expect(@e2.reload).to be_active
          expect(@c1.reload.workflow_state).to eq 'created'
          expect(@c2.reload.workflow_state).to eq 'created'
          expect(batch.workflow_state).to eq 'aborted'
        end
      end

    end
  end
end
