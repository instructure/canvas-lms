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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')
require_dependency "lti/substitutions_helper"

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
    let(:root_account) { Account.create! }
    let(:account) {
      Account.create!(root_account: root_account)
    }
    let(:user) { User.create! }

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
        expect(helper.account).to eq account
      end

      it 'returns the account when it is a course' do
        helper = SubstitutionsHelper.new(course, root_account, user)
        expect(helper.account).to eq account
      end

      it 'returns the root_account by default' do
        helper = SubstitutionsHelper.new(nil, root_account, user)
        expect(helper.account).to eq root_account
      end
    end

    describe '#enrollments_to_lis_roles' do
      it 'converts students' do
        expect(subject.enrollments_to_lis_roles([StudentEnrollment.new]).first).to eq 'Learner'
      end

      it 'converts teachers' do
        expect(subject.enrollments_to_lis_roles([TeacherEnrollment.new]).first).to eq 'Instructor'
      end

      it 'converts teacher assistants' do
        expect(subject.enrollments_to_lis_roles([TaEnrollment.new]).first).to eq 'urn:lti:role:ims/lis/TeachingAssistant'
      end

      it 'converts designers' do
        expect(subject.enrollments_to_lis_roles([DesignerEnrollment.new]).first).to eq 'ContentDeveloper'
      end

      it 'converts observers' do
        expect(subject.enrollments_to_lis_roles([ObserverEnrollment.new]).first).to eq 'urn:lti:instrole:ims/lis/Observer,urn:lti:role:ims/lis/Mentor'
      end

      it 'converts admins' do
        expect(subject.enrollments_to_lis_roles([AccountUser.new]).first).to eq 'urn:lti:instrole:ims/lis/Administrator'
      end

      it 'converts fake students' do
        expect(subject.enrollments_to_lis_roles([StudentViewEnrollment.new]).first).to eq 'Learner'
      end

      it 'converts multiple roles' do
        lis_roles = subject.enrollments_to_lis_roles([StudentEnrollment.new, TeacherEnrollment.new])
        expect(lis_roles).to include 'Learner'
        expect(lis_roles).to include 'Instructor'
      end

      it 'sends at most one of each role' do
        expect(subject.enrollments_to_lis_roles([StudentEnrollment.new, StudentViewEnrollment.new])).to eq ['Learner']
      end
    end

    describe '#all_roles' do

      it 'converts multiple roles' do
        allow(subject).to receive(:course_enrollments).and_return([StudentEnrollment.new, TeacherEnrollment.new, DesignerEnrollment.new, ObserverEnrollment.new, TaEnrollment.new, AccountUser.new])
        allow(user).to receive(:roles).and_return(['user', 'student', 'teacher', 'admin'])
        roles = subject.all_roles
        expect(roles).to include LtiOutbound::LTIRoles::System::USER
        expect(roles).to include LtiOutbound::LTIRoles::Institution::STUDENT
        expect(roles).to include LtiOutbound::LTIRoles::Institution::INSTRUCTOR
        expect(roles).to include LtiOutbound::LTIRoles::Institution::ADMIN
        expect(roles).to include LtiOutbound::LTIRoles::Context::LEARNER
        expect(roles).to include LtiOutbound::LTIRoles::Context::INSTRUCTOR
        expect(roles).to include LtiOutbound::LTIRoles::Context::CONTENT_DEVELOPER
        expect(roles).to include LtiOutbound::LTIRoles::Context::OBSERVER
        expect(roles).to include LtiOutbound::LTIRoles::Context::TEACHING_ASSISTANT
      end

      it "returns none if no user" do
        helper = SubstitutionsHelper.new(course, root_account, nil)
        expect(helper.all_roles).to eq LtiOutbound::LTIRoles::System::NONE
      end

      it 'converts multiple roles for lis 2' do
        allow(subject).to receive(:course_enrollments).and_return([StudentEnrollment.new, TeacherEnrollment.new, DesignerEnrollment.new, ObserverEnrollment.new, TaEnrollment.new, AccountUser.new])
        allow(user).to receive(:roles).and_return(['user', 'student', 'teacher', 'admin'])
        roles = subject.all_roles('lis2')
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/system/person#User'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor'
        expect(roles).to include 'http://purl.imsglobal.org/vocab/lis/v2/membership/instructor#TeachingAssistant'
      end

      it "returns none if no user for lis 2" do
        helper = SubstitutionsHelper.new(course, root_account, nil)
        expect(helper.all_roles('lis2')).to eq 'http://purl.imsglobal.org/vocab/lis/v2/person#None'
      end

      it "includes main and subrole for TeachingAssistant" do
        allow(subject).to receive(:course_enrollments).and_return([TaEnrollment.new])
        roles = subject.all_roles('lis2')
        expected_roles = ["http://purl.imsglobal.org/vocab/lis/v2/membership/instructor#TeachingAssistant",
                          "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
                          "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"]
        expect(roles.split(',')).to match_array expected_roles
      end

      it 'does not include admin role if user has a sub-account admin user record in deleted account' do
        sub_account = account.sub_accounts.create!
        sub_account.account_users.create!(user: user, role: admin_role)
        sub_account.destroy!
        roles = subject.all_roles
        expect(roles).not_to include 'urn:lti:instrole:ims/lis/Administrator'
      end
    end

    describe '#course_enrollments' do
      it 'returns an empty array if the context is not a course' do
        helper = SubstitutionsHelper.new(account, root_account, user)
        expect(helper.course_enrollments).to eq []
      end

      it 'returns an empty array if the user is nil' do
        helper = SubstitutionsHelper.new(course, root_account, nil)
        expect(helper.course_enrollments).to eq []
      end

      it 'returns the active enrollments in a course for a user' do
        set_up_persistance!

        student_enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        teacher_enrollment = teacher_in_course(user: user, course: course, active_enrollment: true)
        inactive_enrollment = course_with_observer(user: user, course: course)
        inactive_enrollment.update_attribute(:workflow_state, 'inactive')

        expect(subject.course_enrollments).to include student_enrollment
        expect(subject.course_enrollments).to include teacher_enrollment
        expect(subject.course_enrollments).not_to include inactive_enrollment
      end

      it 'returns an empty array if there is no user' do
        helper = SubstitutionsHelper.new(account, root_account, nil)
        expect(helper.course_enrollments).to eq []
      end
    end

    describe '#account_enrollments' do
      subject { SubstitutionsHelper.new(account, root_account, user) }
      it 'returns enrollments in an account for a user' do
        set_up_persistance!
        enrollment = account.account_users.create!(:user => user)

        expect(subject.account_enrollments).to eq [enrollment]
      end

      it 'does not return deleted account enrollments' do
        set_up_persistance!
        enrollment = account.account_users.create!(:user => user)
        enrollment.destroy

        expect(subject.account_enrollments).to eq []
      end

      it 'returns enrollments in an account chain for a user' do
        set_up_persistance!
        enrollment = root_account.account_users.create!(:user => user)

        expect(subject.account_enrollments).to eq [enrollment]
      end

      it 'returns an empty array if there is no user' do
        helper = SubstitutionsHelper.new(account, root_account, nil)
        expect(helper.account_enrollments).to eq []
      end
    end

    describe '#current_lis_roles' do
      it 'returns none if the user has no roles' do
        expect(subject.current_lis_roles).to eq 'urn:lti:sysrole:ims/lis/None'
      end

      it "returns the user's roles" do
        set_up_persistance!
        student_in_course(user: user, course: course, active_enrollment: true)
        account.account_users.create!(:user => user)
        lis_roles = subject.current_lis_roles

        expect(lis_roles).to include 'Learner'
        expect(lis_roles).to include 'urn:lti:instrole:ims/lis/Administrator'
      end
    end

    describe '#concluded_course_enrollments' do
      it 'returns an empty array if the context is not a course' do
        helper = SubstitutionsHelper.new(account, root_account, user)
        expect(helper.concluded_course_enrollments).to eq []
      end

      it 'returns an empty array if the user is not set' do
        helper = SubstitutionsHelper.new(course, root_account, nil)
        expect(helper.concluded_course_enrollments).to eq []
      end

      it 'returns the active enrollments in a course for a user' do
        set_up_persistance!

        student_enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        student_enrollment.conclude
        teacher_enrollment = teacher_in_course(user: user, course: course, active_enrollment: true)
        observer_enrollment = course_with_observer(user: user, course: course)
        observer_enrollment.conclude

        expect(subject.concluded_course_enrollments).to include student_enrollment
        expect(subject.concluded_course_enrollments).not_to include teacher_enrollment
        expect(subject.concluded_course_enrollments).to include observer_enrollment
      end
    end

    describe '#concluded_lis_roles' do
      it 'returns none if the user has no roles' do
        expect(subject.concluded_lis_roles).to eq 'urn:lti:sysrole:ims/lis/None'
      end

      it "returns the user's roles" do
        set_up_persistance!
        student_in_course(user: user, course: course, active_enrollment: true).conclude
        expect(subject.concluded_lis_roles).to eq 'Learner'
      end
    end

    describe '#current_canvas_roles_lis_v2' do
      it 'returns the LIS V2 role names' do
        set_up_persistance!

        teacher_in_course(user: user, course: course, active_enrollment: true)
        course_with_designer(user: user, course: course, active_enrollment: true)
        account_admin_user(user: user, account: account)
        roles = subject.current_canvas_roles_lis_v2

        expect(roles.split(',')).to match_array [
          "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
          "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
          "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator"
        ]
      end

      it 'does not include concluded roles' do
        set_up_persistance!
        student_in_course(user: user, course: course, active_enrollment: true).conclude
        teacher_in_course(user: user, course: course, active_enrollment: true)
        roles = subject.current_canvas_roles_lis_v2

        expect(roles).to eq 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'
      end

      it 'does not include roles from other contexts' do
        set_up_persistance!
        course_two = course_model
        student_in_course(user: user, course: course, active_enrollment: true)
        teacher_in_course(user: user, course: course_two, active_enrollment: true)
        roles = subject.current_canvas_roles_lis_v2

        expect(roles).to eq 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
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

        expect(roles).to include 'TeacherEnrollment'
        expect(roles).to include 'DesignerEnrollment'
        expect(roles).to include 'Account Admin'
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

        expect(subject.enrollment_state).to eq 'active'
      end

      it 'is inactive if there are no active enrollments' do
        set_up_persistance!
        enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        enrollment.start_at = 4.days.ago
        enrollment.end_at = 2.days.ago
        enrollment.save!

        expect(subject.enrollment_state).to eq 'inactive'
      end

      it 'is inactive if the course is concluded' do
        set_up_persistance!
        enrollment = student_in_course(user: user, course: course, active_enrollment: true)
        course.complete

        expect(subject.enrollment_state).to eq 'inactive'
      end

      it 'is blank if there are no enrollments' do
        set_up_persistance!
        expect(subject.enrollment_state).to eq ''
      end
    end

    describe '#previous_course_ids_and_context_ids' do
      before do
        course.save!
        @c1 = Course.create!
        @c1.root_account = root_account
        @c1.account = account
        @c1.lti_context_id = 'abc'
        @c1.save

        course.content_migrations.create!.tap do |cm|
          cm.context = course
          cm.workflow_state = 'imported'
          cm.source_course = @c1
          cm.save!
        end

        @c2 = Course.create!
        @c2.root_account = root_account
        @c2.account = account
        @c2.lti_context_id = 'def'
        @c2.save!

        course.content_migrations.create!.tap do |cm|
          cm.context = course
          cm.workflow_state = 'imported'
          cm.source_course = @c2
          cm.save!
        end

        @c3 = Course.create!
        @c3.root_account = root_account
        @c3.account = account
        @c3.lti_context_id = 'hij'
        @c3.save!

        @c1.content_migrations.create!.tap do |cm|
          cm.context = @c1
          cm.workflow_state = 'imported'
          cm.source_course = @c3
          cm.save!
        end
      end

      it "should return previous canvas course ids" do
        expect(subject.previous_course_ids).to eq [@c1.id, @c2.id].sort.join(',')
      end

      it "should return previous lti context_ids" do
        expect(subject.previous_lti_context_ids.split(",")).to match_array %w{abc def}
      end
    end

    describe '#recursively_fetch_previous_course_ids_and_context_ids' do
      before do
        course.save!
        @c1 = Course.create!
        @c1.root_account = root_account
        @c1.account = account
        @c1.lti_context_id = 'abc'
        @c1.save

        course.content_migrations.create!.tap do |cm|
          cm.context = course
          cm.workflow_state = 'imported'
          cm.source_course = @c1
          cm.save!
        end

        @c2 = Course.create!
        @c2.root_account = root_account
        @c2.account = account
        @c2.lti_context_id = 'def'
        @c2.save!

        course.content_migrations.create!.tap do |cm|
          cm.context = course
          cm.workflow_state = 'imported'
          cm.source_course = @c2
          cm.save!
        end

        @c3 = Course.create!
        @c3.root_account = root_account
        @c3.account = account
        @c3.lti_context_id = 'ghi'
        @c3.save!

        @c1.content_migrations.create!.tap do |cm|
          cm.context = @c1
          cm.workflow_state = 'imported'
          cm.source_course = @c3
          cm.save!
        end
      end

      it "should return previous lti context_ids" do
        expect(subject.recursively_fetch_previous_lti_context_ids.split(",")).to match_array %w{abc def ghi}
      end
    end

    describe "section substitutions" do
      before do
        course.save!
        @sec1 = course.course_sections.create(:name => 'sec1')
        @sec1.sis_source_id = 'def'
        @sec1.save!
        @sec2 = course.course_sections.create!(:name => 'sec2')
        @sec2.sis_source_id = 'abc'
        @sec2.save!
        # course.reload

        user.save!
        multiple_student_enrollment(user, @sec1, course: course)
        multiple_student_enrollment(user, @sec2, course: course)
      end

      it "should return all canvas section ids" do
        expect(subject.section_ids).to eq [@sec1.id, @sec2.id].sort.join(',')
      end

      it "should return all canvas section sis ids" do
        expect(subject.section_sis_ids).to eq [@sec1.sis_source_id, @sec2.sis_source_id].sort.join(',')
      end
    end

    context "email" do
      let(:course) { Course.create!(root_account: root_account, account: account) }

      let(:tool) do
        ContextExternalTool.create!(
          name: 'test tool',
          context: course,
          consumer_key: 'key',
          shared_secret: 'secret',
          url: 'http://exmaple.com/launch'
        )
      end

      let(:substitution_helper) { SubstitutionsHelper.new(course, root_account, user, tool) }

      let(:user) do
        user = User.create!
        user.email ='test@foo.com'
        user.save!
        user
      end

      describe "#email" do
        it "returns the users email" do
          expect(substitution_helper.email).to eq user.email
        end

        let(:sis_email) {'sis@example.com'}

        let(:sis_pseudonym) do
          cc = user.communication_channels.email.create!(path: sis_email)
          cc.user = user
          cc.save!
          pseudonym = cc.user.pseudonyms.build(:unique_id => cc.path, :account => Account.default)
          pseudonym.sis_communication_channel_id=cc.id
          pseudonym.communication_channel_id=cc.id
          pseudonym.sis_user_id="some_sis_id"
          pseudonym.save
          pseudonym
        end

        it "returns the sis email if it's an LTI2 tool" do
          tool = class_double("Lti::ToolProxy")
          sub_helper = SubstitutionsHelper.new(course, root_account, user, tool)
          sis_pseudonym
          expect(sub_helper.email).to eq sis_email
        end

        context "prefer_sis_email" do
          before(:each) do
            tool.settings[:prefer_sis_email] = "true"
            tool.save!
          end

          it "returns the sis_email" do
            sis_pseudonym
            expect(substitution_helper.email).to eq sis_email
          end

          it "returns the sis_email when set via tool_configuration" do
            tool.settings[:prefer_sis_email] = nil
            tool.settings[:tool_configuration] = { prefer_sis_email: 'true' }
            tool.save!
            sis_pseudonym
            expect(substitution_helper.email).to eq sis_email
          end

          it "returns the users email if there isn't a sis email" do
            expect(substitution_helper.email).to eq user.email
          end

        end
      end

      describe "#sis_email" do

        it "returns the sis email" do
          sis_email = 'sis@example.com'
          cc = user.communication_channels.email.create!(path: sis_email)
          cc.user = user
          cc.save!
          pseudonym = cc.user.pseudonyms.build(:unique_id => cc.path, :account => Account.default)
          pseudonym.sis_communication_channel_id=cc.id
          pseudonym.communication_channel_id=cc.id
          pseudonym.sis_user_id="some_sis_id"
          pseudonym.save
          expect(substitution_helper.sis_email).to eq sis_email
        end

        it "returns nil if there isn't an sis email" do
          expect(substitution_helper.sis_email).to eq nil
        end

      end
    end
  end
end
