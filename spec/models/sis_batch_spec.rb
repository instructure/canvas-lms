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

require 'tmpdir'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SisBatch do
  before :once do
    account_model
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

      old_job_count = Delayed::Job.count
      batch = File.open(path, 'rb') do |tmp|
        # arrrgh attachment.rb
        def tmp.original_filename; File.basename(path); end
        SisBatch.create_with_attachment(@account, 'instructure_csv', tmp, @user || user)
      end
      # SisBatches shouldn't need any background processing
      Delayed::Job.count.should == old_job_count
      yield batch if block_given?
      batch
    end
  end

  def process_csv_data(data, opts = {})
    create_csv_data(data) do |batch|
      batch.update_attributes(opts) if opts.present?
      batch.process_without_send_later
      batch
    end
  end

  it "should not add attachments to the list" do
    create_csv_data(['abc']) { |batch| batch.attachment.position.should be_nil}
    create_csv_data(['abc']) { |batch| batch.attachment.position.should be_nil}
    create_csv_data(['abc']) { |batch| batch.attachment.position.should be_nil}
  end

  it "should keep the batch in initializing state during create_with_attachment" do
    batch = SisBatch.create_with_attachment(@account, 'instructure_csv', stub_file_data('test.csv', 'abc', 'text'), user) do |batch|
      batch.attachment.should_not be_new_record
      batch.workflow_state.should == 'initializing'
      batch.options = { :override_sis_stickiness => true }
    end

    batch.workflow_state.should == 'created'
    batch.should_not be_new_record
    batch.changed?.should be_false
    batch.options[:override_sis_stickiness].should == true
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
      [b1, b2, b4].each { |batch| [:imported, :imported_with_messages].should be_include(batch.reload.state) }
    end
  end

  it "should schedule in the future if configured" do
    track_jobs do
      create_csv_data(['abc']) do |batch|
        batch.process
      end
    end

    job = created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    job.should be_present
    job.run_at.to_i.should <= Time.now.to_i

    job.destroy

    Setting.set('sis_batch_process_start_delay', '120')
    track_jobs do
      create_csv_data(['abc']) do |batch|
        batch.process
      end
    end

    job = created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    job.should be_present
    job.run_at.to_i.should >= 100.seconds.from_now.to_i
    job.run_at.to_i.should <= 150.minutes.from_now.to_i
  end

  it "should fail itself if the jobs dies" do
    batch = nil
    track_jobs do
      batch = create_csv_data(['abc'])
      batch.process
      batch.update_attribute(:workflow_state, 'importing')
      batch
    end

    job = created_jobs.find { |j| j.tag == 'SisBatch.process_all_for_account' }
    job.reschedule
    batch.reload.should be_failed
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

      @c1.reload.should be_available
      @c2.reload.should be_available
      @c3.reload.should be_available
      @c4.reload.should be_claimed
      @cnew = @account.reload.courses.where(course_code: 'TC 101').first
      @cnew.should_not be_nil
      @cnew.sis_batch_id.should == @batch.id
      @cnew.should be_claimed

      @s1.reload.should be_active
      @s2.reload.should be_active
      @s3.reload.should be_active
      @s4.reload.should be_active
      @s5 = @cnew.course_sections.where(sis_source_id: 's2').first
      @s5.should_not be_nil

      @e1.reload.should be_active
      @e2.reload.should be_active
      @e3.reload.should be_active
      @e4.reload.should be_active
      @e5.reload.should be_active
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

      @batch.data[:stack_trace].should be_nil

      @c1.reload.should be_deleted
      @c1.stuck_sis_fields.should_not be_include(:workflow_state)
      @c2.reload.should be_available
      @c3.reload.should be_available
      @c4.reload.should be_claimed
      @cnew = @account.reload.courses.where(course_code: 'TC 101').first
      @cnew.should_not be_nil
      @cnew.sis_batch_id.should == @batch.id
      @cnew.should be_claimed

      @s1.reload.should be_deleted
      @s2.reload.should be_active
      @s3.reload.should be_active
      @s4.reload.should be_deleted
      @s5 = @cnew.course_sections.where(sis_source_id: 's2').first
      @s5.should_not be_nil

      @e1.reload.should be_deleted
      @e2.reload.should be_active
      @e3.reload.should be_active
      @e4.reload.should be_deleted
      @e5.reload.should be_active

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
      @c1.reload.should be_available
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

      @user.should be_registered
      @section.should be_active
      @course.should be_claimed
      @enrollment1.should be_active

      # only supply enrollments; course and section are left alone
      process_csv_data(
          [%{section_id,user_id,role,status
          section_1,user_1,teacher,active}],
          :batch_mode => true, :batch_mode_term => @term)

      @user.reload.should be_registered
      @section.reload.should be_active
      @course.reload.should be_claimed
      @enrollment1.reload.should be_deleted
      @enrollment2 = @course.teacher_enrollments.where(user_id: @user).first
      @enrollment2.should be_active

      # only supply sections; course left alone
      process_csv_data(
          [%{section_id,course_id,name}],
          :batch_mode => true, :batch_mode_term => @term)
      @user.reload.should be_registered
      @section.reload.should be_deleted
      @section.enrollments.not_fake.each do |e|
        e.should be_deleted
      end
      @course.reload.should be_claimed

      # only supply courses
      process_csv_data(
          [%{course_id,short_name,long_name,term_id}],
          :batch_mode => true, :batch_mode_term => @term)
      @course.reload.should be_deleted
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
      @section1.reload.should be_deleted
      @section2.reload.should_not be_deleted
    end
  end

  it "should limit the # of warnings/errors" do
    Setting.set('sis_batch_max_messages', '3')
    batch = @account.sis_batches.create! # doesn't error when nil
    batch.processing_warnings = [ ['testfile.csv', 'test warning'] ] * 3
    batch.processing_errors = [ ['testfile.csv', 'test error'] ] * 3
    batch.save!
    batch.reload
    batch.processing_warnings.size.should == 3
    batch.processing_warnings.last.should == ['testfile.csv', 'test warning']
    batch.processing_errors.size.should == 3
    batch.processing_errors.last.should == ['testfile.csv', 'test error']
    batch.processing_warnings = [ ['testfile.csv', 'test warning'] ] * 5
    batch.processing_errors = [ ['testfile.csv', 'test error'] ] * 5
    batch.save!
    batch.reload
    batch.processing_warnings.size.should == 3
    batch.processing_warnings.last.should == ['', 'There were 3 more warnings']
    batch.processing_errors.size.should == 3
    batch.processing_errors.last.should == ['', 'There were 3 more errors']
  end
end
