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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CourseSection, "moving to new course" do

  it "should transfer enrollments to the new root account" do
    account1 = Account.create!(:name => "1")
    account2 = Account.create!(:name => "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    course3 = account2.courses.create!
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course1.enroll_user(u, 'StudentEnrollment', :section => cs)
    e.workflow_state = 'active'
    e.save!
    course1.reload

    course1.course_sections.where(id: cs).first.should_not be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    e.root_account.should eql(account1)
    e.course.should eql(course1)

    cs.move_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should be_nil
    course2.course_sections.where(id: cs).first.should_not be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    e.root_account.should eql(account2)
    e.course.should eql(course2)

    cs.move_to_course(course3)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should_not be_nil
    e.root_account.should eql(account2)
    e.course.should eql(course3)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should_not be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    e.root_account.should eql(account1)
    e.course.should eql(course1)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should_not be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    e.root_account.should eql(account1)
    e.course.should eql(course1)
  end

  it "should associate a section with the course's account" do
    account = Account.default.manually_created_courses_account
    course = account.courses.create!
    section = course.default_section
    section.course_account_associations.map(&:account_id).sort.should == [Account.default.id, account.id].sort
  end

  it "should update user account associations for xlist between subaccounts" do
    root_account = Account.create!(:name => "root")
    sub_account1 = Account.create!(:parent_account => root_account, :name => "account1")
    sub_account2 = Account.create!(:parent_account => root_account, :name => "account2")
    sub_account3 = Account.create!(:parent_account => root_account, :name => "account3")
    course1 = sub_account1.courses.create!(:name => "course1")
    course2 = sub_account2.courses.create!(:name => "course2")
    course3 = sub_account3.courses.create!(:name => "course3")
    cs = course1.course_sections.create!
    cs.nonxlist_course_id.should be_nil
    u = User.create!
    u.register!
    e = course1.enroll_user(u, 'StudentEnrollment', :section => cs)
    u.update_account_associations

    course1.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id].sort
    course2.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account2.id].sort
    course3.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account3.id].sort
    u.reload
    u.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id].sort

    cs.crosslist_to_course(course2)
    course1.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id].sort
    course2.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id, sub_account2.id].sort
    course3.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account3.id].sort
    u.reload
    u.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id, sub_account2.id].sort

    cs.crosslist_to_course(course3)
    cs.nonxlist_course_id.should == course1.id
    course1.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id].sort
    course2.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account2.id].sort
    course3.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id, sub_account3.id].sort
    u.reload
    u.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id, sub_account3.id].sort

    cs.uncrosslist
    cs.nonxlist_course_id.should be_nil
    course1.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id].sort
    course2.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account2.id].sort
    course3.reload.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account3.id].sort
    u.reload
    u.associated_accounts.map(&:id).sort.should == [root_account.id, sub_account1.id]
  end

  it "should crosslist and uncrosslist" do
    account1 = Account.create!(:name => "1")
    account2 = Account.create!(:name => "2")
    account3 = Account.create!(:name => "3")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    course3 = account3.courses.create!
    course2.assert_section
    course3.assert_section
    cs = course1.course_sections.create!
    u = User.create!
    u.register!
    e = course2.enroll_user(u, 'StudentEnrollment')
    e.workflow_state = 'active'
    e.save!
    e = course1.enroll_user(u, 'StudentEnrollment', :section => cs)
    e.workflow_state = 'active'
    e.save!
    #should also move deleted enrollments
    e.destroy
    course1.reload
    course2.reload
    course3.workflow_state = 'active'
    course3.save
    e.reload

    course1.course_sections.where(id: cs).first.should_not be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    cs.nonxlist_course.should be_nil
    e.root_account.should eql(account1)
    cs.crosslisted?.should be_false
    course1.workflow_state.should == 'created'
    course2.workflow_state.should == 'created'
    course3.workflow_state.should == 'created'

    cs.crosslist_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should be_nil
    course2.course_sections.where(id: cs).first.should_not be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    cs.nonxlist_course.should eql(course1)
    e.root_account.should eql(account2)
    cs.crosslisted?.should be_true
    course1.workflow_state.should == 'created'
    course2.workflow_state.should == 'created'
    course3.workflow_state.should == 'created'

    cs.crosslist_to_course(course3)
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should_not be_nil
    cs.nonxlist_course.should eql(course1)
    e.root_account.should eql(account3)
    cs.crosslisted?.should be_true
    course1.workflow_state.should == 'created'
    course2.workflow_state.should == 'created'
    course3.workflow_state.should == 'created'

    cs.uncrosslist
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    course1.course_sections.where(id: cs).first.should_not be_nil
    course2.course_sections.where(id: cs).first.should be_nil
    course3.course_sections.where(id: cs).first.should be_nil
    cs.nonxlist_course.should be_nil
    e.root_account.should eql(account1)
    cs.crosslisted?.should be_false
    course1.workflow_state.should == 'created'
    course2.workflow_state.should == 'created'
    course3.workflow_state.should == 'created'
  end

  it 'should update course account associations on save' do
    account1 = Account.create!(:name => "1")
    account2 = account1.sub_accounts.create!(:name => "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    cs1 = course1.course_sections.create!
    CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id).should == [account1.id]
    CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id).should == [account1.id, account2.id]
    course1.account = account2
    course1.save
    CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id).should == [account1.id, account2.id].sort
    CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id).should == [account1.id, account2.id]
    course1.account = nil
    course1.save
    CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id).should == [account1.id]
    CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id).should == [account1.id, account2.id]
    cs1.crosslist_to_course(course2)
    CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id).should == [account1.id]
    CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id).should == [account1.id, account2.id].sort
  end

  describe 'validation' do
    before :once do
      course = Course.create_unique
      @section = CourseSection.create(course: course)
      @long_string = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'
    end

    it "should validate the length of attributes" do
      @section.name = @long_string
      @section.sis_source_id = @long_string
      (lambda {@section.save!}).should raise_error("Validation failed: Sis source is too long (maximum is 255 characters), Name is too long (maximum is 255 characters)")
    end

    it "should validate the length of sis_source_id" do
      @section.sis_source_id = @long_string
      (lambda {@section.save!}).should raise_error("Validation failed: Sis source is too long (maximum is 255 characters)")
    end

    it "should validate the length of section name" do
      @section.name = @long_string
      (lambda {@section.save!}).should raise_error("Validation failed: Name is too long (maximum is 255 characters)")
    end
  end

  describe 'deletable?' do
    before :once do
      course_with_teacher
      @section = course.course_sections.create!
    end

    it 'should be deletable if empty' do
      @section.should be_deletable
    end

    it 'should not be deletable if it has real enrollments' do
      student_in_course :section => @section
      @section.should_not be_deletable
    end

    it 'should be deletable if it only has a student view enrollment' do
      @course.student_view_student
      @section.enrollments.map(&:type).should eql ['StudentViewEnrollment']
      @section.should be_deletable
    end
  end

  context 'permissions' do
    context ':read and section_visibilities' do
      before :once do
        RoleOverride.create!({
          :context => Account.default,
          :permission => 'manage_students',
          :enrollment_type => "TaEnrollment",
          :enabled => false
        })
        course_with_ta(:active_all => true)
        @other_section = @course.course_sections.create!(:name => "Other Section")
      end

      it "should work with section_limited true" do
        @ta.enrollments.update_all(:limit_privileges_to_course_section => true)
        @ta.reload

        # make sure other ways to get :read are false
        @other_section.course.grants_right?(@ta, :manage_sections).should be_false
        @other_section.course.grants_right?(@ta, :manage_students).should be_false

        @other_section.grants_right?(@ta, :read).should be_false
      end

      it "should work with section_limited false" do
        # make sure other ways to get :read are false
        @other_section.course.grants_right?(@ta, :manage_sections).should be_false
        @other_section.course.grants_right?(@ta, :manage_students).should be_false

        @other_section.grants_right?(@ta, :read).should be_true
      end
    end
  end
end
