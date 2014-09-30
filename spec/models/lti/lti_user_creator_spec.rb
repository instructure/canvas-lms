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

describe Lti::LtiUserCreator do
  describe '#convert' do
    let(:tool) do
      ContextExternalTool.new.tap do |tool|
        tool.stubs(:opaque_identifier_for).returns('this is opaque')
      end
    end

    let(:canvas_user) { user(name: 'Shorty McLongishname') }
    let(:root_account) { Account.create! }

    it 'converts a canvas user to an lti user' do
      canvas_user.email = 'user@email.com'

      sub_account = Account.create!
      sub_account.root_account = root_account
      sub_account.save!
      pseudonym = pseudonym(canvas_user, account: sub_account, username: 'login_id')

      pseudonym.sis_user_id = 'sis id!'
      pseudonym.save!

      Time.zone.tzinfo.stubs(:name).returns('my/zone')

      user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, sub_account)
      lti_user = user_factory.convert

      lti_user.class.should == LtiOutbound::LTIUser

      lti_user.email.should == 'user@email.com'
      lti_user.first_name.should == 'Shorty'
      lti_user.last_name.should == 'McLongishname'
      lti_user.name.should == 'Shorty McLongishname'
      lti_user.sis_source_id.should == 'sis id!'
      lti_user.opaque_identifier.should == 'this is opaque'

      lti_user.avatar_url.should include 'https://secure.gravatar.com/avatar/'
      lti_user.login_id.should == 'login_id'
      lti_user.id.should == canvas_user.id
      lti_user.timezone.should == 'my/zone'
    end

    context 'the user does not have a pseudonym' do
      let(:user_creator) { Lti::LtiUserCreator.new(canvas_user, root_account, tool, root_account) }

      it 'does not have a login_id' do
        lti_user = user_creator.convert

        lti_user.login_id.should == nil
      end

      it 'does not have a sis_user_id' do
        lti_user = user_creator.convert

        lti_user.sis_source_id.should == nil
      end
    end

    context "enrollments" do
      let(:canvas_course) { course(active_course: true) }
      let(:canvas_account) { root_account }
      let(:course_user_creator) { Lti::LtiUserCreator.new(canvas_user, canvas_account, tool, canvas_course) }
      let(:account_user_creator) { Lti::LtiUserCreator.new(canvas_user, canvas_account, tool, canvas_account) }

      describe "#current_enrollments" do
        it "collects current active student enrollments" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "collects current active student view enrollments" do
          course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "collects current active teacher enrollments" do
          teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::INSTRUCTOR]
        end

        it "collects current active ta enrollments" do
          course_with_ta(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::TEACHING_ASSISTANT]
        end

        it "collects current active course designer enrollments" do
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::CONTENT_DEVELOPER]
        end

        it "collects current active account user enrollments from an account" do
          account_admin_user(user: canvas_user, account: canvas_account)

          enrollments = account_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "collects current active account user enrollments from a course" do
          account_admin_user(user: canvas_user, account: canvas_course.root_account)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "collects current active account user enrollments for the root account of a course" do
          root_account = Account.create!
          canvas_course.account.root_account = root_account
          account_admin_user(user: canvas_user, account: root_account)

          enrollments = course_user_creator.convert.current_roles

          enrollments.should == [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "does not include enrollments from other courses" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          other_course = course(active_course: true)
          teacher_in_course(user: canvas_user, course: other_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles
          enrollments.size.should == 1
        end

        it "does not include the same role multiple times" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          enrollments.size.should == 1
        end

        it "collects all valid enrollments at once" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
          account_admin_user(user: canvas_user, account: canvas_course.account)

          enrollments = course_user_creator.convert.current_roles

          enrollments.size.should == 3
        end

        it "does not return any course enrollments when the context is an account" do
          canvas_account.stubs(:id).returns(canvas_course.id)
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          account_user_creator.convert.current_roles.size.should == 0
        end
      end

      describe "#currently_active_in_course" do
        it "returns true if the user has any currently active course enrollments" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          course_user_creator.convert.currently_active_in_course.should == true
        end

        it "returns false if the user has current enrollments that are all inactive" do
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          enrollment.start_at = 4.days.ago
          enrollment.end_at = 2.days.ago
          enrollment.save

          course_user_creator.convert.currently_active_in_course.should == false
        end

        it "returns nil if the context is not a course" do
          account_admin_user(user: canvas_user, account: canvas_course.account)
          account_user_creator.convert.currently_active_in_course.should == nil
        end
      end

      describe "#concluded_enrollments" do
        it "correctly collects concluded student enrollments" do
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
          account_admin_user(user: canvas_user, account: canvas_course.account)

          enrollments = course_user_creator.convert.concluded_roles

          enrollments.should == [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "does not return any course enrollments when the context is an account" do
          canvas_account.stubs(:id).returns(canvas_course.id)
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
          account_user_creator.convert.concluded_roles.size.should == 0
        end
      end
    end

    describe "variable substitution" do
      let(:canvas_course) { course(active_course: true) }
      let(:variable_substitutor) { LtiOutbound::VariableSubstitutor.new }
      let(:course_user_creator) { Lti::LtiUserCreator.new(canvas_user, root_account, tool, canvas_course, variable_substitutor) }

      it "adds user id" do
        canvas_user.stubs(:id).returns(12345)
        course_user_creator.convert

        hash = {variable: '$Canvas.user.id'}
        variable_substitutor.substitute!(hash)

        hash[:variable].should == 12345
      end

      it "adds sis source id" do
        pseudonym = pseudonym(canvas_user, account: root_account, username: 'login_id')

        pseudonym.sis_user_id = 'sis id!'
        pseudonym.save!
        course_user_creator.convert

        hash = {variable: '$Canvas.user.sisSourceId'}
        variable_substitutor.substitute!(hash)

        hash[:variable].should == 'sis id!'
      end

      it "adds login id" do
        pseudonym = pseudonym(canvas_user, account: root_account, username: 'login_id')
        course_user_creator.convert

        hash = {variable: '$Canvas.user.loginId'}
        variable_substitutor.substitute!(hash)

        hash[:variable].should == 'login_id'
      end

      it "adds enrollment state" do
        student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
        course_user_creator.convert

        hash = {variable: '$Canvas.enrollment.enrollmentState'}
        variable_substitutor.substitute!(hash)

        hash[:variable].should == LtiOutbound::LTIUser::ACTIVE_STATE
      end

      it "adds concluded roles" do
        student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
        teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
        course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
        account_admin_user(user: canvas_user, account: canvas_course.account)

        course_user_creator.convert

        hash = {variable: '$Canvas.membership.concludedRoles'}
        variable_substitutor.substitute!(hash)
        hash[:variable].should == [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER,LtiOutbound::LTIRoles::ContextNotNamespaced::INSTRUCTOR].join(',')
      end

      it "adds roles" do
        student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
        teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
        course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
        account_admin_user(user: canvas_user, account: canvas_course.account)

        course_user_creator.convert

        hash = {variable: '$Canvas.membership.roles'}
        variable_substitutor.substitute!(hash)
        hash[:variable].should == "TeacherEnrollment,DesignerEnrollment,Account Admin"
      end
    end
  end
end
