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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

module Lti
  describe SubstitutionsHelper do
    subject { SubstitutionsHelper.new(course, root_account, user) }

    specs_require_sharding

    let(:course) {
      Course.new.tap do |c|
        c.root_account = root_account
        c.account = account
      end
    }
    let(:root_account) { Account.new }
    let(:account) {
      Account.new.tap do |a|
        a.root_account = root_account
      end
    }
    let(:user) { User.new }

    def set_up_persistance!
      @shard1.activate { user.save! }
      @shard2.activate do
        root_account.save!
        account.save!
        course.save!
      end
    end

    describe '#account' do
      it 'returns the context when it is an account' do
        helper = SubstitutionsHelper.new(account, root_account, user)
        helper.account.should == account
      end

      it 'returns the account when it is a course' do
        helper = SubstitutionsHelper.new(course, root_account, user)
        helper.account.should == account
      end

      it 'returns the root_account by default' do
        helper = SubstitutionsHelper.new(nil, root_account, user)
        helper.account.should == root_account
      end
    end

    describe '#enrollments_to_lis_roles' do
      it 'converts students' do
        subject.enrollments_to_lis_roles([StudentEnrollment.new]).first.should == 'Learner'
      end

      it 'converts teachers' do
        subject.enrollments_to_lis_roles([TeacherEnrollment.new]).first.should == 'Instructor'
      end

      it 'converts teacher assistants' do
        subject.enrollments_to_lis_roles([TaEnrollment.new]).first.should == 'urn:lti:role:ims/lis/TeachingAssistant'
      end

      it 'converts designers' do
        subject.enrollments_to_lis_roles([DesignerEnrollment.new]).first.should == 'ContentDeveloper'
      end

      it 'converts observers' do
        subject.enrollments_to_lis_roles([ObserverEnrollment.new]).first.should == 'urn:lti:instrole:ims/lis/Observer'
      end

      it 'converts admins' do
        subject.enrollments_to_lis_roles([AccountUser.new]).first.should == 'urn:lti:instrole:ims/lis/Administrator'
      end

      it 'converts fake students' do
        subject.enrollments_to_lis_roles([StudentViewEnrollment.new]).first.should == 'Learner'
      end

      it 'converts multiple roles' do
        lis_roles = subject.enrollments_to_lis_roles([StudentEnrollment.new, TeacherEnrollment.new])
        lis_roles.should include 'Learner'
        lis_roles.should include 'Instructor'
      end

      it 'sends at most one of each role' do
        subject.enrollments_to_lis_roles([StudentEnrollment.new, StudentViewEnrollment.new]).should == ['Learner']
      end
    end

    describe '#course_enrollments' do
      it 'returns an empty array if the context is not a course' do
        helper = SubstitutionsHelper.new(account, root_account, user)
        helper.course_enrollments.should == []
      end

      it 'returns the active enrollments in a course for a user' do
        set_up_persistance!

        student_enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        teacher_enrollment = teacher_in_course(user: user, course: course, active_enrollment: true)
        inactive_enrollment = course_with_observer(user: user, course: course)
        inactive_enrollment.update_attribute(:workflow_state, 'inactive')

        subject.course_enrollments.should include student_enrollment
        subject.course_enrollments.should include teacher_enrollment
        subject.course_enrollments.should_not include inactive_enrollment
      end
    end

    describe '#account_enrollments' do
      subject { SubstitutionsHelper.new(account, root_account, user) }
      it 'returns enrollments in an account for a user' do
        set_up_persistance!
        enrollment = account.account_users.create!(:user => user)

        subject.account_enrollments.should == [enrollment]
      end

      it 'returns enrollments in an account chain for a user' do
        set_up_persistance!
        enrollment = root_account.account_users.create!(:user => user)

        subject.account_enrollments.should == [enrollment]
      end
    end

    describe '#current_lis_roles' do
      it 'returns none if the user has no roles' do
        subject.current_lis_roles.should == 'urn:lti:sysrole:ims/lis/None'
      end

      it 'returns none if the user has no roles' do
        set_up_persistance!
        student_in_course(user: user, course: course, active_enrollment: true)
        account.account_users.create!(:user => user)
        lis_roles = subject.current_lis_roles

        lis_roles.should include 'Learner'
        lis_roles.should include 'urn:lti:instrole:ims/lis/Administrator'
      end
    end

    describe '#concluded_course_enrollments' do
      it 'returns an empty array if the context is not a course' do
        helper = SubstitutionsHelper.new(account, root_account, user)
        helper.concluded_course_enrollments.should == []
      end

      it 'returns the active enrollments in a course for a user' do
        set_up_persistance!

        student_enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        student_enrollment.conclude
        teacher_enrollment = teacher_in_course(user: user, course: course, active_enrollment: true)
        observer_enrollment = course_with_observer(user: user, course: course)
        observer_enrollment.conclude

        subject.concluded_course_enrollments.should include student_enrollment
        subject.concluded_course_enrollments.should_not include teacher_enrollment
        subject.concluded_course_enrollments.should include observer_enrollment
      end
    end

    describe '#concluded_lis_roles' do
      it 'returns none if the user has no roles' do
        subject.concluded_lis_roles.should == 'urn:lti:sysrole:ims/lis/None'
      end

      it 'returns none if the user has no roles' do
        set_up_persistance!
        student_in_course(user: user, course: course, active_enrollment: true).conclude
        subject.concluded_lis_roles.should == 'Learner'
      end
    end

    describe '#current_canvas_roles' do
      it 'returns readable names for canvas roles' do
        set_up_persistance!

        student_in_course(user: user, course: course, active_enrollment: true).conclude
        teacher_in_course(user: user, course: course, active_enrollment: true)
        course_with_designer(user: user, course: course, active_enrollment: true)
        account_admin_user(user: user, account: account)

        roles = subject.current_canvas_roles

        roles.should include 'TeacherEnrollment'
        roles.should include 'DesignerEnrollment'
        roles.should include 'Account Admin'
      end
    end

    describe '#enrollment_state' do
      it 'is active if there are any active enrollments' do
        set_up_persistance!
        enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        enrollment.start_at = 4.days.ago
        enrollment.end_at = 2.days.ago
        enrollment.save!

        teacher_in_course(user: user, course: course, active_enrollment: true)

        subject.enrollment_state.should == 'active'
      end

      it 'is inactive if there are no active enrollments' do
        set_up_persistance!
        enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        enrollment.start_at = 4.days.ago
        enrollment.end_at = 2.days.ago
        enrollment.save!

        subject.enrollment_state.should == 'inactive'
      end

      it 'is inactive if the course is concluded' do
        set_up_persistance!
        enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        course.complete

        subject.enrollment_state.should == 'inactive'
      end

      it 'is blank if there are no enrollments' do
        set_up_persistance!
        subject.enrollment_state.should == ''
      end
    end
  end
end