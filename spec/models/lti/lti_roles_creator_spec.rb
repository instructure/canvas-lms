#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiRolesCreator do
  let(:canvas_user) { user(name: 'Shorty McLongishname') }
  let(:canvas_course) { course(active_course: true) }
  let(:canvas_account) { Account.create! }
  let(:course_enrollments_creator) { Lti::LtiRolesCreator.new(canvas_user, canvas_course) }
  let(:account_enrollments_creator) { Lti::LtiRolesCreator.new(canvas_user, canvas_account) }

  describe "#current_enrollments" do
    it "collects current active student enrollments" do
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::LEARNER]
    end

    it "collects current active student view enrollments" do
      course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::LEARNER]
    end

    it "collects current active teacher enrollments" do
      teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::INSTRUCTOR]
    end

    it "collects current active ta enrollments" do
      course_with_ta(user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::TEACHING_ASSISTANT]
    end

    it "collects current active course designer enrollments" do
      course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::CONTENT_DEVELOPER]
    end

    it "collects current active account user enrollments from an account" do
      account_admin_user(user: canvas_user, account: canvas_account)

      enrollments = account_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::ADMIN]
    end

    it "collects current active account user enrollments from a course" do
      account_admin_user(user: canvas_user, account: canvas_course.root_account)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::ADMIN]
    end

    it "collects current active account user enrollments for the root account of a course" do
      root_account = Account.create!
      canvas_course.account.root_account = root_account
      account_admin_user(user: canvas_user, account: root_account)

      enrollments = course_enrollments_creator.current_roles

      enrollments.should == [LtiOutbound::LTIRole::ADMIN]
    end

    it "does not include enrollments from other courses" do
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

      other_course = course(active_course: true)
      teacher_in_course(user: canvas_user, course: other_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles
      enrollments.size.should == 1
    end

    it "does not include the same role multiple times" do
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
      course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

      enrollments = course_enrollments_creator.current_roles

      enrollments.size.should == 1
    end

    it "collects all valid enrollments at once" do
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
      course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
      account_admin_user(user: canvas_user, account: canvas_course.account)

      enrollments = course_enrollments_creator.current_roles

      enrollments.size.should == 3
    end

    it "does not return any course enrollments when the context is an account" do
      canvas_account.stubs(:id).returns(canvas_course.id)
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
      account_enrollments_creator.current_roles.size.should == 0
    end
  end

  describe "#currently_active_in_course" do
    it "returns true if the user has any currently active course enrollments" do
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

      course_enrollments_creator.currently_active_in_course?.should == true
    end

    it "returns false if the user has current enrollments that are all inactive" do
      enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
      enrollment.start_at = 4.days.ago
      enrollment.end_at = 2.days.ago
      enrollment.save

      course_enrollments_creator.currently_active_in_course?.should == false
    end
  end

  describe "#concluded_enrollments" do
    it "correctly collects concluded student enrollments" do
      enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
      course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
      account_admin_user(user: canvas_user, account: canvas_course.account)

      enrollments = course_enrollments_creator.concluded_roles

      enrollments.should == [LtiOutbound::LTIRole::LEARNER]
    end

    it "does not return any course enrollments when the context is an account" do
      canvas_account.stubs(:id).returns(canvas_course.id)
      student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
      account_enrollments_creator.concluded_roles.size.should == 0
    end
  end
end