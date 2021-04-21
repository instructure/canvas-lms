# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
        allow(tool).to receive(:opaque_identifier_for).and_return('this is opaque')
      end
    end

    let(:canvas_user) { user_factory(name: 'Shorty McLongishname') }
    let(:canvas_user2) { user_factory(name: 'Observer Dude') }
    let(:root_account) { Account.create! }
    let(:sis_pseudonym) { managed_pseudonym(canvas_user, account: root_account, username: 'login_id', sis_user_id: 'sis id!') }

    it 'converts a canvas user to an lti user' do
      canvas_user.email = 'user@email.com'

      sub_account = Account.new
      sub_account.root_account = root_account
      sub_account.save!
      sis_pseudonym

      allow(Time.zone.tzinfo).to receive(:name).and_return('my/zone')

      user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, sub_account)
      lti_user = user_factory.convert

      expect(lti_user.class).to eq LtiOutbound::LTIUser

      expect(lti_user.email).to eq 'user@email.com'
      expect(lti_user.first_name).to eq 'Shorty'
      expect(lti_user.last_name).to eq 'McLongishname'
      expect(lti_user.name).to eq 'Shorty McLongishname'
      expect(lti_user.sis_source_id).to eq 'sis id!'
      expect(lti_user.opaque_identifier).to eq 'this is opaque'

      expect(lti_user.avatar_url).to include 'http://localhost/images/messages/avatar-50.png'
      expect(lti_user.login_id).to eq 'login_id'
      expect(lti_user.id).to eq canvas_user.id
      expect(lti_user.timezone).to eq 'my/zone'
      expect(lti_user.current_observee_ids).to eq []
    end

    context 'the user does not have a pseudonym' do
      let(:user_creator) { Lti::LtiUserCreator.new(canvas_user, root_account, tool, root_account) }

      it 'does not have a login_id' do
        lti_user = user_creator.convert

        expect(lti_user.login_id).to eq nil
      end

      it 'does not have a sis_user_id' do
        lti_user = user_creator.convert

        expect(lti_user.sis_source_id).to eq nil
      end
    end

    context "enrollments" do
      let(:canvas_course) { course_factory(active_course: true) }
      let(:canvas_account) { root_account }
      let(:course_user_creator) { Lti::LtiUserCreator.new(canvas_user, canvas_account, tool, canvas_course) }
      let(:course_observer_creator) { Lti::LtiUserCreator.new(canvas_user2, canvas_account, tool, canvas_course) }
      let(:account_user_creator) { Lti::LtiUserCreator.new(canvas_user, canvas_account, tool, canvas_account) }

      def observer_in_course(options = {})
        associated_user = options.delete(:associated_user)
        user = options.delete(:user)
        enrollment = @course.enroll_user(user, 'ObserverEnrollment')
        enrollment.associated_user = associated_user
        enrollment.workflow_state = 'active'
        enrollment.save
        user
      end

      it "returns current_observee_ids" do
        canvas_user.lti_context_id = 'blah'
        canvas_user.save!
        observer_in_course(course: canvas_course, user: canvas_user2, associated_user: canvas_user)

        lti_user = course_observer_creator.convert
        expect(lti_user.current_observee_ids).to match_array [canvas_user.lti_context_id]
      end

      describe "#current_enrollments" do
        it "returns correct sis_user_id" do
          second_sis = managed_pseudonym(canvas_user, account: root_account, username: 'second_login_id', sis_user_id: 'wrong_sis')
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true, sis_pseudonym_id: sis_pseudonym.id)

          user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, canvas_course)
          lti_user = user_factory.convert
          expect(lti_user.sis_source_id).to eq 'sis id!'
          enrollment.update_attribute(:sis_pseudonym_id, second_sis.id)
          user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, canvas_course)
          lti_user = user_factory.convert
          expect(lti_user.sis_source_id).to eq 'wrong_sis'
        end

        it "doesn't return deleted sis_user_id" do
          second_sis = managed_pseudonym(canvas_user, account: root_account, username: 'second_login_id', sis_user_id: 'wrong_sis')
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true, sis_pseudonym_id: sis_pseudonym.id)
          enrollment.update_attribute(:sis_pseudonym_id, second_sis.id)
          second_sis.destroy
          user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, canvas_course)
          lti_user = user_factory.convert
          expect(lti_user.sis_source_id).to eq 'sis id!'
        end

        it "returns a sis_user_id when no sis_id tied to enrollment" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          sis_pseudonym
          user_factory = Lti::LtiUserCreator.new(canvas_user, root_account, tool, canvas_course)
          lti_user = user_factory.convert
          expect(lti_user.sis_source_id).to eq 'sis id!'
        end

        it "collects current active student enrollments" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "collects current active student view enrollments" do
          course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "collects current active teacher enrollments" do
          teacher_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::INSTRUCTOR]
        end

        it "collects current active ta enrollments" do
          course_with_ta(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::TEACHING_ASSISTANT]
        end

        it "collects current active course designer enrollments" do
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::CONTENT_DEVELOPER]
        end

        it "collects current active account user enrollments from an account" do
          account_admin_user(user: canvas_user, account: canvas_account)

          enrollments = account_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "collects current active account user enrollments from a course" do
          account_admin_user(user: canvas_user, account: canvas_course.root_account)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "collects current active account user enrollments for the root account of a course" do
          account_admin_user(user: canvas_user, account: canvas_course.account.root_account)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::Institution::ADMIN]
        end

        it "does not include enrollments from other courses" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          other_course = course_factory(active_course: true)
          teacher_in_course(user: canvas_user, course: other_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles
          expect(enrollments.size).to eq 1
        end

        it "does not include the same role multiple times" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          course_with_user('StudentViewEnrollment', user: canvas_user, course: canvas_course, active_enrollment: true)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments.size).to eq 1
        end

        it "collects all valid enrollments at once" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
          account_admin_user(user: canvas_user, account: canvas_course.account)

          enrollments = course_user_creator.convert.current_roles

          expect(enrollments.size).to eq 3
        end

        it "does not return any course enrollments when the context is an account" do
          allow(canvas_account).to receive(:id).and_return(canvas_course.id)
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          expect(account_user_creator.convert.current_roles).to eq ["urn:lti:sysrole:ims/lis/None"]
        end
      end

      describe "#currently_active_in_course" do
        it "returns true if the user has any currently active course enrollments" do
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)

          expect(course_user_creator.convert.currently_active_in_course).to eq true
        end

        it "returns false if the user has current enrollments that are all inactive" do
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true)
          enrollment.start_at = 4.days.ago
          enrollment.end_at = 2.days.ago
          enrollment.save

          expect(course_user_creator.convert.currently_active_in_course).to eq false
        end

        it "returns nil if the context is not a course" do
          account_admin_user(user: canvas_user, account: canvas_course.account)
          expect(account_user_creator.convert.currently_active_in_course).to eq nil
        end
      end

      describe "#concluded_enrollments" do
        it "correctly collects concluded student enrollments" do
          enrollment = student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
          course_with_designer(user: canvas_user, course: canvas_course, active_enrollment: true)
          account_admin_user(user: canvas_user, account: canvas_course.account)

          enrollments = course_user_creator.convert.concluded_roles

          expect(enrollments).to eq [LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER]
        end

        it "does not return any course enrollments when the context is an account" do
          allow(canvas_account).to receive(:id).and_return(canvas_course.id)
          student_in_course(user: canvas_user, course: canvas_course, active_enrollment: true).conclude
          expect(account_user_creator.convert.concluded_roles.size).to eq 0
        end
      end
    end

  end
end
