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

describe GroupCategory do
  context "protected_name_for_context?" do
    it "should be false for 'Student Groups' in accounts" do
      account = Account.default
      GroupCategory.protected_name_for_context?('Student Groups', account).should be_false
    end

    it "should be true for 'Student Groups' in courses" do
      course = course_model
      GroupCategory.protected_name_for_context?('Student Groups', course).should be_true
    end

    it "should be true for 'Imported Groups' in both accounts and courses" do
      account = Account.default
      course = course_model
      GroupCategory.protected_name_for_context?('Imported Groups', account).should be_true
      GroupCategory.protected_name_for_context?('Imported Groups', course).should be_true
    end
  end

  context "student_organized_for" do
    it "should be nil in accounts" do
      account = Account.default
      GroupCategory.student_organized_for(account).should be_nil
    end

    it "should be a category belonging to the course with role 'student_organized' in courses" do
      course = course_model
      category = GroupCategory.student_organized_for(course)
      category.should_not be_nil
      category.role.should eql('student_organized')
      category.context.should eql(course)
    end

    it "should be the the same category every time for the same course" do
      course = course_model
      category1 = GroupCategory.student_organized_for(course)
      category2 = GroupCategory.student_organized_for(course)
      category1.id.should eql(category2.id)
    end
  end

  context "imported_for" do
    it "should be a category belonging to the account with role 'imported' in accounts" do
      account = Account.default
      category = GroupCategory.imported_for(account)
      category.should_not be_nil
      category.role.should eql('imported')
      category.context.should eql(account)
    end

    it "should be a category belonging to the course with role 'imported' in courses" do
      course = course_model
      category = GroupCategory.imported_for(course)
      category.should_not be_nil
      category.role.should eql('imported')
      category.context.should eql(course)
    end

    it "should be the the same category every time for the same context" do
      course = course_model
      category1 = GroupCategory.imported_for(course)
      category2 = GroupCategory.imported_for(course)
      category1.id.should eql(category2.id)
    end
  end

  context 'student_organized?' do
    it "should be true iff the role is 'student_organized', regardless of name" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).should be_student_organized
      account.group_categories.create(:name => 'Student Groups').should_not be_student_organized
      GroupCategory.imported_for(course).should_not be_student_organized
      GroupCategory.imported_for(course).should_not be_student_organized
      course.group_categories.create(:name => 'Random Category').should_not be_student_organized
    end
  end

  context 'protected?' do
    it "should be true iff the category has a role" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).should be_protected
      account.group_categories.create(:name => 'Student Groups').should_not be_protected
      GroupCategory.imported_for(course).should be_protected
      GroupCategory.imported_for(course).should be_protected
      course.group_categories.create(:name => 'Random Category').should_not be_protected
    end
  end

  context 'destroy' do
    it "should not remove the database row" do
      category = GroupCategory.create
      category.destroy
      lambda{ GroupCategory.find(category.id) }.should_not raise_error
    end

    it "should set deleted_at" do
      category = GroupCategory.create
      category.destroy
      category.reload
      category.deleted_at.should_not be_nil
    end

    it "should destroy dependent groups" do
      course = course_model
      category = course.group_categories.create
      group1 = category.groups.create(:context => course)
      group2 = category.groups.create(:context => course)
      course.reload
      course.groups.active.count.should == 2

      category.destroy
      course.reload
      course.groups.active.count.should == 0
      course.groups.count.should == 2
    end
  end
end
