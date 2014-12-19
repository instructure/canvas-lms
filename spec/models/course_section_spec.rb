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

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)

    cs.move_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).not_to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account2)
    expect(e.course).to eql(course2)

    cs.move_to_course(course3)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).not_to be_nil
    expect(e.root_account).to eql(account2)
    expect(e.course).to eql(course3)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)

    cs.move_to_course(course1)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(e.root_account).to eql(account1)
    expect(e.course).to eql(course1)
  end

  it "should associate a section with the course's account" do
    account = Account.default.manually_created_courses_account
    course = account.courses.create!
    section = course.default_section
    expect(section.course_account_associations.map(&:account_id).sort).to eq [Account.default.id, account.id].sort
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
    expect(cs.nonxlist_course_id).to be_nil
    u = User.create!
    u.register!
    e = course1.enroll_user(u, 'StudentEnrollment', :section => cs)
    u.update_account_associations

    expect(course1.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort

    cs.crosslist_to_course(course2)
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account2.id].sort

    cs.crosslist_to_course(course3)
    expect(cs.nonxlist_course_id).to eq course1.id
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id, sub_account3.id].sort

    cs.uncrosslist
    expect(cs.nonxlist_course_id).to be_nil
    expect(course1.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id].sort
    expect(course2.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account2.id].sort
    expect(course3.reload.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account3.id].sort
    u.reload
    expect(u.associated_accounts.map(&:id).sort).to eq [root_account.id, sub_account1.id]
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

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to be_nil
    expect(e.root_account).to eql(account1)
    expect(cs.crosslisted?).to be_falsey
    expect(course1.workflow_state).to eq 'created'
    expect(course2.workflow_state).to eq 'created'
    expect(course3.workflow_state).to eq 'created'

    cs.crosslist_to_course(course2)
    course1.reload
    course2.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).not_to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to eql(course1)
    expect(e.root_account).to eql(account2)
    expect(cs.crosslisted?).to be_truthy
    expect(course1.workflow_state).to eq 'created'
    expect(course2.workflow_state).to eq 'created'
    expect(course3.workflow_state).to eq 'created'

    cs.crosslist_to_course(course3)
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).not_to be_nil
    expect(cs.nonxlist_course).to eql(course1)
    expect(e.root_account).to eql(account3)
    expect(cs.crosslisted?).to be_truthy
    expect(course1.workflow_state).to eq 'created'
    expect(course2.workflow_state).to eq 'created'
    expect(course3.workflow_state).to eq 'created'

    cs.uncrosslist
    course1.reload
    course2.reload
    course3.reload
    cs.reload
    e.reload

    expect(course1.course_sections.where(id: cs).first).not_to be_nil
    expect(course2.course_sections.where(id: cs).first).to be_nil
    expect(course3.course_sections.where(id: cs).first).to be_nil
    expect(cs.nonxlist_course).to be_nil
    expect(e.root_account).to eql(account1)
    expect(cs.crosslisted?).to be_falsey
    expect(course1.workflow_state).to eq 'created'
    expect(course2.workflow_state).to eq 'created'
    expect(course3.workflow_state).to eq 'created'
  end

  it 'should update course account associations on save' do
    account1 = Account.create!(:name => "1")
    account2 = account1.sub_accounts.create!(:name => "2")
    course1 = account1.courses.create!
    course2 = account2.courses.create!
    cs1 = course1.course_sections.create!
    expect(CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    course1.account = account2
    course1.save
    expect(CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id].sort
    expect(CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    course1.account = nil
    course1.save
    expect(CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id]
    cs1.crosslist_to_course(course2)
    expect(CourseAccountAssociation.where(course_id: course1).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id]
    expect(CourseAccountAssociation.where(course_id: course2).uniq.order(:account_id).pluck(:account_id)).to eq [account1.id, account2.id].sort
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
      expect(lambda {@section.save!}).to raise_error("Validation failed: Sis source is too long (maximum is 255 characters), Name is too long (maximum is 255 characters)")
    end

    it "should validate the length of sis_source_id" do
      @section.sis_source_id = @long_string
      expect(lambda {@section.save!}).to raise_error("Validation failed: Sis source is too long (maximum is 255 characters)")
    end

    it "should validate the length of section name" do
      @section.name = @long_string
      expect(lambda {@section.save!}).to raise_error("Validation failed: Name is too long (maximum is 255 characters)")
    end
  end

  describe 'deletable?' do
    before :once do
      course_with_teacher
      @section = course.course_sections.create!
    end

    it 'should be deletable if empty' do
      expect(@section).to be_deletable
    end

    it 'should not be deletable if it has real enrollments' do
      student_in_course :section => @section
      expect(@section).not_to be_deletable
    end

    it 'should be deletable if it only has a student view enrollment' do
      @course.student_view_student
      expect(@section.enrollments.map(&:type)).to eql ['StudentViewEnrollment']
      expect(@section).to be_deletable
    end
  end

  context 'permissions' do
    context ':read and section_visibilities' do
      before :once do
        RoleOverride.create!({
          :context => Account.default,
          :permission => 'manage_students',
          :role => ta_role,
          :enabled => false
        })
        course_with_ta(:active_all => true)
        @other_section = @course.course_sections.create!(:name => "Other Section")
      end

      it "should work with section_limited true" do
        @ta.enrollments.update_all(:limit_privileges_to_course_section => true)
        @ta.reload

        # make sure other ways to get :read are false
        expect(@other_section.course.grants_right?(@ta, :manage_sections)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_students)).to be_falsey

        expect(@other_section.grants_right?(@ta, :read)).to be_falsey
      end

      it "should work with section_limited false" do
        # make sure other ways to get :read are false
        expect(@other_section.course.grants_right?(@ta, :manage_sections)).to be_falsey
        expect(@other_section.course.grants_right?(@ta, :manage_students)).to be_falsey

        expect(@other_section.grants_right?(@ta, :read)).to be_truthy
      end
    end
  end
end
