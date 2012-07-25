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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SisBatch do
  before do
    account_model
  end

  def create_csv_data(data)
    i = 0
    tempfile = Tempfile.new("sis_rspec.zip")
    path = tempfile.path
    # we just want the path, and if we don't tell the tempfile to close,
    # it'll try to delete the file later during finalization, which is
    # not a convenient time for us.
    tempfile.close!
    Zip::ZipFile.open(path, true) do |z|
      data.each do |dat|
        z.get_output_stream("csv_#{i}.csv") { |f| f.puts(dat) }
        i += 1
      end
    end
    tmp = File.open(path, 'rb')

    # arrrgh attachment.rb
    def tmp.original_filename; File.basename(path); end
    old_job_count = Delayed::Job.count
    batch = SisBatch.create_with_attachment(@account, 'instructure_csv', tmp)
    # SisBatches shouldn't need any background processing
    Delayed::Job.count.should == old_job_count
    yield batch if block_given?
    batch
  ensure
    FileUtils.rm(path) if path and File.file?(path)
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
    batch = SisBatch.create_with_attachment(@account, 'instructure_csv', stub_file_data('test.csv', 'abc', 'text')) do |batch|
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
    create_csv_data(['abc']) do |batch|
      batch.process
      Delayed::Job.find_by_tag('SisBatch.process_all_for_account').run_at.to_i.should <= Time.now.to_i
    end

    Delayed::Job.delete_all

    Setting.set('sis_batch_process_start_delay', '120')
    create_csv_data(['abc']) do |batch|
      start_time = Time.now.to_i
      batch.process
      job = Delayed::Job.find_by_tag('SisBatch.process_all_for_account')
      job.run_at.to_i.should >= 100.seconds.from_now.to_i
      job.run_at.to_i.should <= 150.minutes.from_now.to_i
    end
  end

  describe "batch mode" do
    it "should not remove anything if no term is given" do
      @subacct = @account.sub_accounts.create(:name => 'sub1')
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, 'term1')
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = SisBatch.create!
      @old_batch = SisBatch.create!

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
      @c4 = @account.courses.find_by_course_code('not-delete')

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, :name => "don't delete me", :sis_source_id => 'my_section')
      @s3 = factory_with_protected_attributes(@c3.course_sections, :name => "delete me if terms", :sis_batch_id => @old_batch.id)
      @s4 = factory_with_protected_attributes(@c2.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this section should still be

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id)
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user)
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id)
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this enrollment should still be
      @e5 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user_with_pseudonym, :sis_batch_id => @old_batch.id, :course_section => @s2) # c2 won't be deleted, and this enrollment sticks around because it's specified in the new csv
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
      @cnew = @account.reload.courses.find_by_course_code('TC 101')
      @cnew.should_not be_nil
      @cnew.sis_batch_id.should == @batch.id
      @cnew.should be_claimed

      @s1.reload.should be_active
      @s2.reload.should be_active
      @s3.reload.should be_active
      @s4.reload.should be_active
      @s5 = @cnew.course_sections.find_by_sis_source_id('s2')
      @s5.should_not be_nil

      @e1.reload.should be_active
      @e2.reload.should be_active
      @e3.reload.should be_active
      @e4.reload.should be_active
      @e5.reload.should be_active
    end

    it "should remove only from the specific term if it is given" do
      @subacct = @account.sub_accounts.create(:name => 'sub1')
      @term1 = @account.enrollment_terms.first
      @term1.update_attribute(:sis_source_id, 'term1')
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = SisBatch.create!
      @old_batch = SisBatch.create!

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
      @c4 = @account.courses.find_by_course_code('not-delete')

      # sections are keyed off what term their course is in
      @s1 = factory_with_protected_attributes(@c1.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id)
      @s2 = factory_with_protected_attributes(@c2.course_sections, :name => "don't delete me", :sis_source_id => 'my_section')
      @s3 = factory_with_protected_attributes(@c3.course_sections, :name => "delete me if terms", :sis_batch_id => @old_batch.id)
      @s4 = factory_with_protected_attributes(@c2.course_sections, :name => "delete me", :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this section should still be

      # enrollments are keyed off what term their course is in
      @e1 = factory_with_protected_attributes(@c1.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id)
      @e2 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user)
      @e3 = factory_with_protected_attributes(@c3.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id)
      @e4 = factory_with_protected_attributes(@c2.enrollments, :workflow_state => 'active', :user => user, :sis_batch_id => @old_batch.id) # c2 won't be deleted, but this enrollment should still be
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

      @c1.reload.should be_deleted
      @c1.stuck_sis_fields.should_not be_include(:workflow_state)
      @c2.reload.should be_available
      @c3.reload.should be_available
      @c4.reload.should be_claimed
      @cnew = @account.reload.courses.find_by_course_code('TC 101')
      @cnew.should_not be_nil
      @cnew.sis_batch_id.should == @batch.id
      @cnew.should be_claimed

      @s1.reload.should be_deleted
      @s2.reload.should be_active
      @s3.reload.should be_active
      @s4.reload.should be_deleted
      @s5 = @cnew.course_sections.find_by_sis_source_id('s2')
      @s5.should_not be_nil

      @e1.reload.should be_deleted
      @e2.reload.should be_active
      @e3.reload.should be_active
      @e4.reload.should be_deleted
      @e5.reload.should be_active
    end

    it "shouldn't do batch mode removals if not in batch mode" do
      @term1 = @account.enrollment_terms.first
      @term2 = @account.enrollment_terms.create!(:name => 'term2')
      @previous_batch = SisBatch.create!

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
      @previous_batch = SisBatch.create!

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

      @user = Pseudonym.find_by_sis_user_id('user_1').user
      @section = CourseSection.find_by_sis_source_id('section_1')
      @course = @section.course
      @enrollment1 = @course.student_enrollments.find_by_user_id(@user.id)

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
      @enrollment2 = @course.teacher_enrollments.find_by_user_id(@user.id)
      @enrollment2.should be_active

      # only supply sections; course left alone
      process_csv_data(
          [%{section_id,course_id,name}],
          :batch_mode => true, :batch_mode_term => @term)
      @user.reload.should be_registered
      @section.reload.should be_deleted
      @course.reload.should be_claimed

      # only supply courses
      process_csv_data(
          [%{course_id,short_name,long_name,term_id}],
          :batch_mode => true, :batch_mode_term => @term)
      @course.reload.should be_deleted
    end
  end
end
