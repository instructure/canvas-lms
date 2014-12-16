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

module Lti
  class DummyClass
    include MessageHelper

    def logged_in_user
      @current_user
    end

    attr_accessor :domain_root_account, :context, :current_user
  end

  describe MessageHelper do
    subject { DummyClass.new }
    let(:root_account) { Account.new }
    let(:account) { Account.new(root_account: root_account) }
    let(:course) { Course.new(account: account) }
    let(:user) { User.new }
    let(:substitution_helper) { stub_everything }

    before(:each) {
      subject.domain_root_account = root_account
      subject.context = account
    }

    describe "#common_variable_substitutions" do
      before(:each) do
        substitution_helper.stubs(:account).returns(account)
      end

      it 'has substitution for $Canvas.api.domain' do
        subject.stubs(:request).returns(mock(host: '/my/url'))
        expect(subject.common_variable_substitutions['$Canvas.api.domain'].call).to eq 'localhost'
      end

      it 'has substitution for $Canvas.api.baseUrl' do
        subject.stubs(:request).returns(mock(host: 'localhost', scheme: 'https'))
        expect(subject.common_variable_substitutions['$Canvas.api.baseUrl'].call).to eq 'https://localhost'
      end

      it 'has substitution for $Canvas.account.id' do
        account.stubs(:id).returns(12345)
        expect(subject.common_variable_substitutions['$Canvas.account.id']).to eq 12345
      end

      it 'has substitution for $Canvas.account.name' do
        account.name = 'Some Account'
        expect(subject.common_variable_substitutions['$Canvas.account.name']).to eq 'Some Account'
      end

      it 'has substitution for $Canvas.account.sisSourceId' do
        account.sis_source_id = 'ab23'
        expect(subject.common_variable_substitutions['$Canvas.account.sisSourceId']).to eq 'ab23'
      end

      it 'has substitution for $Canvas.rootAccount.id' do
        root_account.stubs(:id).returns(54321)
        expect(subject.common_variable_substitutions['$Canvas.rootAccount.id']).to eq 54321
      end

      it 'has substitution for $Canvas.rootAccount.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        expect(subject.common_variable_substitutions['$Canvas.rootAccount.sisSourceId']).to eq 'cd45'
      end

      it 'has substitution for $Canvas.root_account.id' do
        root_account.stubs(:id).returns(54321)
        expect(subject.common_variable_substitutions['$Canvas.root_account.id']).to eq 54321
      end

      it 'has substitution for $Canvas.root_account.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        expect(subject.common_variable_substitutions['$Canvas.root_account.sisSourceId']).to eq 'cd45'
      end

      context 'context is a course' do
        before(:each) {
          subject.domain_root_account = root_account
          subject.context = course
        }

        it 'has substitution for $Canvas.course.id' do
          course.stubs(:id).returns(123)
          expect(subject.common_variable_substitutions['$Canvas.course.id']).to eq 123
        end

        it 'has substitution for $CourseSection.sourcedId' do
          course.sis_source_id = 'course1'
          expect(subject.common_variable_substitutions['$CourseSection.sourcedId']).to eq 'course1'
        end

        it 'has substitution for $Canvas.course.sisSourceId' do
          course.sis_source_id = 'course1'
          expect(subject.common_variable_substitutions['$Canvas.course.sisSourceId']).to eq 'course1'
        end

        it 'has substitution for $Canvas.enrollment.enrollmentState' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:enrollment_state).returns('active')
          expect(subject.common_variable_substitutions['$Canvas.enrollment.enrollmentState'].call).to eq 'active'
        end

        it 'has substitution for $Canvas.membership.roles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:current_canvas_roles).returns('teacher,student')
          expect(subject.common_variable_substitutions['$Canvas.membership.roles'].call).to eq 'teacher,student'
        end

        it 'has substitution for $Canvas.membership.concludedRoles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:concluded_lis_roles).returns('learner')
          expect(subject.common_variable_substitutions['$Canvas.membership.concludedRoles'].call).to eq 'learner'
        end

        it 'has substitution for $Canvas.course.previousContextIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:previous_lti_context_ids).returns('abc,xyz')
          expect(subject.common_variable_substitutions['$Canvas.course.previousContextIds'].call).to eq 'abc,xyz'
        end

        it 'has substitution for $Canvas.course.previousCourseIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:previous_course_ids).returns('1,2')
          expect(subject.common_variable_substitutions['$Canvas.course.previousCourseIds'].call).to eq '1,2'
        end
      end

      context 'context is a course and there is a user' do
        before(:each) {
          subject.domain_root_account = root_account
          subject.context = course
          subject.current_user = user
        }

        it 'has substitution for $Canvas.xapi.url' do
          Lti::XapiService.stubs(:create_token).returns('abcd')
          subject.stubs(:lti_xapi_url).returns('/xapi/abcd')
          expect(subject.common_variable_substitutions['$Canvas.xapi.url'].call).to eq '/xapi/abcd'
        end

        it 'has substitution for $Canvas.course.sectionIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:section_ids).returns('5,6')
          expect(subject.common_variable_substitutions['$Canvas.course.sectionIds'].call).to eq '5,6'
        end

        it 'has substitution for $Canvas.course.sectionSisSourceIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:section_sis_ids).returns('5a,6b')
          expect(subject.common_variable_substitutions['$Canvas.course.sectionSisSourceIds'].call).to eq '5a,6b'
        end
      end

      context 'user is logged in' do
        before :each do
          subject.current_user = user
        end

        it 'has substitution for $Person.name.full' do
          user.name = 'Uncle Jake'
          expect(subject.common_variable_substitutions['$Person.name.full']).to eq 'Uncle Jake'
        end

        it 'has substitution for $Person.name.family' do
          user.name = 'Uncle Jake'
          expect(subject.common_variable_substitutions['$Person.name.family']).to eq 'Jake'
        end

        it 'has substitution for $Person.name.given' do
          user.name = 'Uncle Jake'
          expect(subject.common_variable_substitutions['$Person.name.given']).to eq 'Uncle'
        end

        it 'has substitution for $Person.email.primary' do
          user.email = 'someone@somewhere'
          expect(subject.common_variable_substitutions['$Person.email.primary']).to eq 'someone@somewhere'
        end

        it 'has substitution for $Person.address.timezone' do
          expect(subject.common_variable_substitutions['$Person.address.timezone']).to eq 'Etc/UTC'
        end

        it 'has substitution for $User.image' do
          user.stubs(:avatar_url).returns('/my/pic')
          expect(subject.common_variable_substitutions['$User.image'].call).to eq '/my/pic'
        end

        it 'has substitution for $Canvas.user.id' do
          user.stubs(:id).returns(456)
          expect(subject.common_variable_substitutions['$Canvas.user.id']).to eq 456
        end

        it 'has substitution for $Canvas.xuser.allRoles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:all_roles).returns('Admin,User')
          expect(subject.common_variable_substitutions['$Canvas.xuser.allRoles'].call).to eq 'Admin,User'
        end

        it 'has substitution for $Membership.role' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:lis2_roles).returns('Admin,User')
          expect(subject.common_variable_substitutions['$Membership.role'].call).to eq 'Admin,User'
        end

        it 'has substitution for $User.id' do
          user.stubs(:id).returns(456)
          expect(subject.common_variable_substitutions['$User.id']).to eq 456
        end

        context '$Canvas.user.prefersHighContrast' do
          it 'substitutes as true' do
            user.stubs(:prefers_high_contrast?).returns(true)
            expect(subject.common_variable_substitutions['$Canvas.user.prefersHighContrast'].call).to eq 'true'
          end

          it 'substitutes as false' do
            user.stubs(:prefers_high_contrast?).returns(false)
            expect(subject.common_variable_substitutions['$Canvas.user.prefersHighContrast'].call).to eq 'false'
          end
        end


        context 'pseudonym' do
          let(:pseudonym) { Pseudonym.new }

          before :each do
            user.stubs(:find_pseudonym_for_account).returns(pseudonym)
          end

          it 'has substitution for $Canvas.user.sisSourceId' do
            pseudonym.sis_user_id = '1a2b3c'
            expect(subject.common_variable_substitutions['$Canvas.user.sisSourceId']).to eq '1a2b3c'
          end

          it 'has substitution for $Person.sourcedId' do
            pseudonym.sis_user_id = '1a2b3c'
            expect(subject.common_variable_substitutions['$Person.sourcedId']).to eq '1a2b3c'
          end


          it 'has substitution for $Canvas.user.loginId' do
            pseudonym.unique_id = 'username'
            expect(subject.common_variable_substitutions['$Canvas.user.loginId']).to eq 'username'
          end

          it 'has substitution for $User.username' do
            pseudonym.unique_id = 'username'
            expect(subject.common_variable_substitutions['$User.username']).to eq 'username'
          end
        end

        it 'has substitution for $Canvas.masqueradingUser.id' do
          logged_in_user = User.new
          logged_in_user.stubs(:id).returns(7878)
          subject.stubs(:logged_in_user).returns(logged_in_user)
          expect(subject.common_variable_substitutions['$Canvas.masqueradingUser.id']).to eq 7878
        end
      end
    end

    describe "#default_lti_params" do
      it "generates context_id" do
        expect(subject.default_lti_params[:context_id]).to eq Lti::Asset.opaque_identifier_for(account)
      end

      it "generates tool_consumer_instance_guid" do
        root_account.lti_guid = 'guid'
        expect(subject.default_lti_params[:tool_consumer_instance_guid]).to eq 'guid'
      end

      it "generates roles" do
        Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
        substitution_helper.stubs(:current_lis_roles).returns('Learner')
        expect(subject.default_lti_params[:roles]).to eq 'Learner'
      end

      it "generates ext_roles" do
        Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
        substitution_helper.stubs(:all_roles).returns('Admin,User')
        expect(subject.default_lti_params[:ext_roles]).to eq 'Admin,User'
      end

      it "generates launch_presentation_locale" do
        expect(subject.default_lti_params[:launch_presentation_locale]).to eq :en
      end

      it "generates launch_presentation_document_target" do
        expect(subject.default_lti_params[:launch_presentation_document_target]).to eq 'iframe'
      end

      it "generates user_id" do
        subject.current_user = user
        user.stubs(:roles).returns(['User'])
        expect(subject.default_lti_params[:user_id]).to eq Lti::Asset.opaque_identifier_for(user)
      end
    end
  end
end
