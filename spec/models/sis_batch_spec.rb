#
# Copyright (C) 2011-2015 Instructure, Inc.
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

  def create_csv_data(data)
    i = 0
    Dir.mktmpdir("sis_rspec") do |tmpdir|
      path = "#{tmpdir}/sisfile.zip"
      Zip::File.open(path, Zip::File::CREATE) do |z|
        data.each do |dat|
          z.get_output_stream("csv_#{i}.csv") { |f| f.puts(dat) }
          i += 1
        end
      end

      old_job_count = sis_jobs.count
      batch = File.open(path, 'rb') do |tmp|
        # arrrgh attachment.rb
        def tmp.original_filename; File.basename(path); end
        SisBatch.create_with_attachment(@account, 'instructure_csv', tmp, @user || user)
      end
      # SisBatches shouldn't need any background processing
      expect(sis_jobs.count).to eq old_job_count
      yield batch if block_given?
      batch
    end
  end

  def process_csv_data(data, opts = {})
    create_csv_data(data) do |batch|
      batch.update_attributes(opts, without_protection: true) if opts.present?
      batch.process_without_send_later
      batch
    end
  end

  it "should not add attachments to the list" do
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
    create_csv_data(['abc']) { |batch| expect(batch.attachment.position).to be_nil}
  end

  it "should keep the batch in initializing state during create_with_attachment" do
    batch = SisBatch.create_with_attachment(@account, 'instructure_csv', stub_file_data('test.csv', 'abc', 'text'), user) do |batch|
      expect(batch.attachment).not_to be_new_record
      expect(batch.workflow_state).to eq 'initializing'
      batch.options = { :override_sis_stickiness => true }
    end

    expect(batch.workflow_state).to eq 'created'
    expect(batch).not_to be_new_record
    expect(batch.changed?).to be_falsey
    expect(batch.options[:override_sis_stickiness]).to eq true
  end

  describe ".process_all_for_account" do
    it "should process all non-processed batches for the account" do
      b1 = create_csv_data(['abc'])
      b2 = create_csv_data(['abc'])
      b3 = create_csv_data(['abc'])
      b4 = create_csv_data(['abc'])
      b2.update_attribute(:workflow_state, 'imported')
      @a1 = @account
      @a2 = account_model
      b5 = create_csv_data(['abc'])
      b2.any_instantiation.expects(:process_without_send_later).never
      b5.any_instantiation.expects(:process_without_send_later).never
      SisBatch.process_all_for_account(@a1)
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
      expect(@account).to respond_to(:update_account_associations)
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
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :type => 'StudentEnrollment')
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment') # c2 won't be deleted, but this enrollment should still be
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

      @c1 = factory_with_protected_attributes(@subacct.courses, :name => "delete me", :enrollment_term => @term1, :sis_batch_id => @previous_batch.id)
      @c1.offer!
      @c2 = factory_with_protected_attributes(@account.courses, :name => "don't delete me", :enrollment_term => @term1, :sis_source_id => 'my_course', :root_account => @account)
      @c2.offer!
      @c3 = factory_with_protected_attributes(@account.courses, :name => "delete me if terms", :enrollment_term => @term2, :sis_batch_id => @previous_batch.id)
      @c3.offer!

      # initial import of one course, to test courses that haven't changed at all between imports
      process_csv_data([
%{course_id,short_name,long_name,account_id,term_id,status
another_course,not-delete,not deleted not changed,,term1,active}
      ])
      @c4 = @account.courses.where(course_code: 'not-delete').first

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, :name => "don't delete me", :sis_source_id => 'my_section')
      @s3 = factory_with_protected_attributes(@c3.course_sections, :name => "delete me if terms", :sis_batch_id => @old_batch.id)
      @s4 = factory_with_protected_attributes(@c2.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this section should still be

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :type => 'StudentEnrollment')
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment')
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id, :type => 'StudentEnrollment') # c2 won't be deleted, but this enrollment should still be
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
      @cnew = @account.reload.courses.where(course_code: 'TC 101').first
      expect(@cnew).not_to be_nil
      expect(@cnew.sis_batch_id).to eq @batch.id
      expect(@cnew).to be_claimed

      expect(@s1.reload).to be_deleted
      expect(@s2.reload).to be_active
      expect(@s3.reload).to be_active
      expect(@s4.reload).to be_deleted
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

      Auditors::Course.expects(:record_deleted).once.with(@course, anything, anything)
      # only supply courses
      b = process_csv_data(
        [%{course_id,short_name,long_name,term_id}],
        :batch_mode => true, :batch_mode_term => @term)
      expect(b.data[:counts][:batch_courses_deleted]).to eq 1
      expect(@course.reload).to be_deleted
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

  it "should limit the # of warnings/errors" do
    Setting.set('sis_batch_max_messages', '3')
    batch = @account.sis_batches.create! # doesn't error when nil
    batch.processing_warnings = [ ['testfile.csv', 'test warning'] ] * 3
    batch.processing_errors = [ ['testfile.csv', 'test error'] ] * 3
    batch.save!
    batch.reload
    expect(batch.processing_warnings.size).to eq 3
    expect(batch.processing_warnings.last).to eq ['testfile.csv', 'test warning']
    expect(batch.processing_errors.size).to eq 3
    expect(batch.processing_errors.last).to eq ['testfile.csv', 'test error']
    batch.processing_warnings = [ ['testfile.csv', 'test warning'] ] * 5
    batch.processing_errors = [ ['testfile.csv', 'test error'] ] * 5
    batch.save!
    batch.reload
    expect(batch.processing_warnings.size).to eq 3
    expect(batch.processing_warnings.last).to eq ['', 'There were 3 more warnings']
    expect(batch.processing_errors.size).to eq 3
    expect(batch.processing_errors.last).to eq ['', 'There were 3 more errors']
  end

  context "csv diffing" do
    it "should skip diffing if previous diff not available" do
      SIS::CSV::DiffGenerator.any_instance.expects(:generate).never
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
  end
end
