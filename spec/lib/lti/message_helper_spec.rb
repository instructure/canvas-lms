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

    attr_accessor :domain_root_account, :context, :current_user
  end

  describe MessageHelper do
    subject { DummyClass.new }
    let(:root_account) { Account.new }
    let(:account) { Account.new(root_account: root_account) }
    let(:course) { Course.new(account: account) }
    let(:user) { User.new }
    let(:substitution_helper) { mock(account: account) }

    before(:each) {
      subject.domain_root_account = root_account
      subject.context = account
    }

    it 'has substitution for $Canvas.api.domain' do
      subject.stubs(:request).returns(mock(host: '/my/url'))
      subject.common_variable_substitutions['$Canvas.api.domain'].call.should == 'localhost'
    end

    it 'has substitution for $Canvas.xapi.url' do
      subject.stubs(:lti_xapi_url).returns('/xapi')
      subject.common_variable_substitutions['$Canvas.xapi.url'].call.should == '/xapi'
    end

    it 'has substitution for $Canvas.account.id' do
      account.stubs(:id).returns(12345)
      subject.common_variable_substitutions['$Canvas.account.id'].should == 12345
    end

    it 'has substitution for $Canvas.account.name' do
      account.name = 'Some Account'
      subject.common_variable_substitutions['$Canvas.account.name'].should == 'Some Account'
    end

    it 'has substitution for $Canvas.account.sisSourceId' do
      account.sis_source_id = 'ab23'
      subject.common_variable_substitutions['$Canvas.account.sisSourceId'].should == 'ab23'
    end

    it 'has substitution for $Canvas.rootAccount.id' do
      root_account.stubs(:id).returns(54321)
      subject.common_variable_substitutions['$Canvas.rootAccount.id'].should == 54321
    end

    it 'has substitution for $Canvas.rootAccount.sisSourceId' do
      root_account.sis_source_id = 'cd45'
      subject.common_variable_substitutions['$Canvas.rootAccount.sisSourceId'].should == 'cd45'
    end

    it 'has substitution for $Canvas.root_account.id' do
      root_account.stubs(:id).returns(54321)
      subject.common_variable_substitutions['$Canvas.root_account.id'].should == 54321
    end

    it 'has substitution for $Canvas.root_account.sisSourceId' do
      root_account.sis_source_id = 'cd45'
      subject.common_variable_substitutions['$Canvas.root_account.sisSourceId'].should == 'cd45'
    end

    context 'context is a course' do
      before(:each) {
        subject.domain_root_account = root_account
        subject.context = course
      }

      it 'has substitution for $Canvas.course.id' do
        course.stubs(:id).returns(123)
        subject.common_variable_substitutions['$Canvas.course.id'].should == 123
      end

      it 'has substitution for $Canvas.course.sisSourceId' do
        course.sis_source_id = 'course1'
        subject.common_variable_substitutions['$Canvas.course.sisSourceId'].should == 'course1'
      end

      it 'has substitution for $Canvas.enrollment.enrollmentState' do
        Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
        substitution_helper.stubs(:enrollment_state).returns('active')
        subject.common_variable_substitutions['$Canvas.enrollment.enrollmentState'].call.should == 'active'
      end

      it 'has substitution for $Canvas.membership.roles' do
        Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
        substitution_helper.stubs(:current_canvas_roles).returns('teacher,student')
        subject.common_variable_substitutions['$Canvas.membership.roles'].call.should == 'teacher,student'
      end

      it 'has substitution for $Canvas.membership.concludedRoles' do
        Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
        substitution_helper.stubs(:concluded_lis_roles).returns('learner')
        subject.common_variable_substitutions['$Canvas.membership.concludedRoles'].call.should == 'learner'
      end
    end

    context 'user is logged in' do
      before :each do
        subject.current_user = user
      end

      it 'has substitution for $Person.name.full' do
        user.name = 'Uncle Jake'
        subject.common_variable_substitutions['$Person.name.full'].should == 'Uncle Jake'
      end

      it 'has substitution for $Person.name.family' do
        user.name = 'Uncle Jake'
        subject.common_variable_substitutions['$Person.name.family'].should == 'Jake'
      end

      it 'has substitution for $Person.name.given' do
        user.name = 'Uncle Jake'
        subject.common_variable_substitutions['$Person.name.given'].should == 'Uncle'
      end

      it 'has substitution for $Person.email.primary' do
        user.email = 'someone@somewhere'
        subject.common_variable_substitutions['$Person.email.primary'].should == 'someone@somewhere'
      end

      it 'has substitution for $Person.address.timezone' do
        subject.common_variable_substitutions['$Person.address.timezone'].should == 'Etc/UTC'
      end

      it 'has substitution for $User.image' do
        user.stubs(:avatar_url).returns('/my/pic')
        subject.common_variable_substitutions['$User.image'].call.should == '/my/pic'
      end

      it 'has substitution for $Canvas.user.id' do
        user.stubs(:id).returns(456)
        subject.common_variable_substitutions['$Canvas.user.id'].should == 456
      end

      context 'pseudonym' do
        let(:pseudonym) { Pseudonym.new }

        before :each do
          user.stubs(:find_pseudonym_for_account).returns(pseudonym)
        end

        it 'has substitution for $Canvas.user.sisSourceId' do
          pseudonym.sis_user_id = '1a2b3c'
          subject.common_variable_substitutions['$Canvas.user.sisSourceId'].should == '1a2b3c'
        end

        it 'has substitution for $Canvas.user.loginId' do
          pseudonym.unique_id = 'username'
          subject.common_variable_substitutions['$Canvas.user.loginId'].should == 'username'
        end
      end
    end
  end
end