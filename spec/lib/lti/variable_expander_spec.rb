#
# Copyright (C) 2015 Instructure, Inc.
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
  describe VariableExpander do
    let(:root_account) { Account.new }
    let(:account) { Account.new(root_account: root_account) }
    let(:course) { Course.new(account: account) }
    let(:user) { User.new }
    let(:assignment) { Assignment.new }
    let(:substitution_helper) { stub_everything }
    let(:right_now) { DateTime.now }
    let(:tool) do
      m = mock('tool')
      m.stubs(:id).returns(1)
      m.stubs(:context).returns(root_account)
      shard_mock = mock('shard')
      shard_mock.stubs(:settings).returns({encription_key: 'abc'})
      m.stubs(:shard).returns(shard_mock)
      m.stubs(:opaque_identifier_for).returns("6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f")
      m
    end
    let(:controller) do
      request_mock = mock('request')
      request_mock.stubs(:url).returns('https://localhost')
      request_mock.stubs(:host).returns('/my/url')
      request_mock.stubs(:scheme).returns('https')
      m = mock('controller')
      m.stubs(:css_url_for).with(:common).returns('/path/to/common.scss')
      m.stubs(:request).returns(request_mock)
      m.stubs(:logged_in_user).returns(user)
      m.stubs(:named_context_url).returns('url')
      view_context_mock = mock('view_context')
      view_context_mock.stubs(:stylesheet_path)
                       .returns(URI.parse(request_mock.url).merge(m.css_url_for(:common)).to_s)
      m.stubs(:view_context).returns(view_context_mock)
      m
    end

    subject { described_class.new(root_account, account, controller, current_user: user, tool: tool) }

    it 'clears the lti_helper instance variable when you set the current_user' do
      expect(subject.lti_helper).not_to be nil
      subject.current_user = nil
      expect(subject.instance_variable_get(:"@current_user")).to be nil
    end

    it 'registers expansions' do
      before_count = described_class.expansions.count
      described_class.register_expansion('test_expan', ['a'], -> { @context })
      expansions = described_class.expansions
      expect(expansions.count - before_count).to eq 1
      test_expan = expansions[:"$test_expan"]
      expect(test_expan.name).to eq 'test_expan'
      expect(test_expan.permission_groups).to eq ['a']
    end

    it 'expands registered variables' do
      described_class.register_expansion('test_expan', ['a'], -> { @context })
      expanded = subject.expand_variables!({some_name: '$test_expan'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq account
    end

    it 'expands substring variables' do
      account.stubs(:id).returns(42)
      described_class.register_expansion('test_expan', ['a'], -> { @context.id })
      expanded = subject.expand_variables!({some_name: 'my variable is buried in here ${test_expan} can you find it?'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here 42 can you find it?"
    end

    it 'handles multiple substring variables' do
      account.stubs(:id).returns(42)
      described_class.register_expansion('test_expan', ['a'], -> { @context.id })
      described_class.register_expansion('variable1', ['a'], -> { 1 })
      described_class.register_expansion('other_variable', ['a'], -> { 2 })
      expanded = subject.expand_variables!(
        {some_name: 'my variables ${variable1} is buried ${other_variable} in here ${test_expan} can you find them?'}
      )
      expect(expanded[:some_name]).to eq "my variables 1 is buried 2 in here 42 can you find them?"
    end

    it 'does not expand a substring variable if it is not valid' do
      account.stubs(:id).returns(42)
      described_class.register_expansion('test_expan', ['a'], -> { @context.id })
      expanded = subject.expand_variables!({some_name: 'my variable is buried in here ${tests_expan} can you find it?'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here ${tests_expan} can you find it?"
    end

    context 'lti1' do
      it 'handles expansion' do
        described_class.register_expansion('test_expan', ['a'], -> { @context })
        expanded = subject.expand_variables!({'some_name' => '$test_expan'})
        expect(expanded.count).to eq 1
        expect(expanded['some_name']).to eq account
      end

      it 'expands substring variables' do
        account.stubs(:id).returns(42)
        described_class.register_expansion('test_expan', ['a'], -> { @context.id })
        expanded = subject.expand_variables!({'some_name' => 'my variable is buried in here ${test_expan} can you find it?'})
        expect(expanded.count).to eq 1
        expect(expanded['some_name']).to eq "my variable is buried in here 42 can you find it?"
      end
    end
    describe "#variable expansions" do

      it 'has substitution for $Canvas.api.domain' do
        exp_hash = {test: '$Canvas.api.domain'}
        HostUrl.stubs(:context_host).returns('localhost')
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'localhost'
      end

      it 'has substitution for $Canvas.css.common' do
        exp_hash = {test: '$Canvas.css.common'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'https://localhost/path/to/common.scss'
      end

      it 'has substitution for $Canvas.api.baseUrl' do
        exp_hash = {test: '$Canvas.api.baseUrl'}
        HostUrl.stubs(:context_host).returns('localhost')
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'https://localhost'
      end

      it 'has substitution for $Canvas.account.id' do
        account.stubs(:id).returns(12345)
        exp_hash = {test: '$Canvas.account.id'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 12345
      end

      it 'has substitution for $Canvas.account.name' do
        account.name = 'Some Account'
        exp_hash = {test: '$Canvas.account.name'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'Some Account'
      end

      it 'has substitution for $Canvas.account.sisSourceId' do
        account.sis_source_id = 'abc23'
        exp_hash = {test: '$Canvas.account.sisSourceId'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'abc23'
      end

      it 'has substitution for $Canvas.rootAccount.id' do
        root_account.stubs(:id).returns(54321)
        exp_hash = {test: '$Canvas.rootAccount.id'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 54321
      end

      it 'has substitution for $Canvas.rootAccount.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        exp_hash = {test: '$Canvas.rootAccount.sisSourceId'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'cd45'
      end

      it 'has substitution for $Canvas.root_account.id' do
        root_account.stubs(:id).returns(54321)
        exp_hash = {test: '$Canvas.root_account.id'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 54321
      end

      it 'has substitution for $Canvas.root_account.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        exp_hash = {test: '$Canvas.root_account.sisSourceId'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'cd45'
      end

      it 'has substitution for $Canvas.root_account.global_id' do
        root_account.stubs(:global_id).returns(10054321)
        exp_hash = {test: '$Canvas.root_account.global_id'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 10054321
      end

      it 'has substitution for $Canvas.shard.id' do
        exp_hash = {test: '$Canvas.shard.id'}
        subject.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq Shard.current.id
      end

      context 'context is a course' do
        subject { described_class.new(root_account, course, controller, current_user: user) }

        it 'has substitution for $Canvas.course.id' do
          course.stubs(:id).returns(123)
          exp_hash = {test: '$Canvas.course.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 123
        end

        it 'has substitution for $CourseSection.sourcedId' do
          course.sis_source_id = 'course1'
          exp_hash = {test: '$CourseSection.sourcedId'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'course1'
        end

        it 'has substitution for $Canvas.course.sisSourceId' do
          course.sis_source_id = 'course1'
          exp_hash = {test: '$Canvas.course.sisSourceId'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'course1'
        end

        it 'has substitution for $Canvas.enrollment.enrollmentState' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:enrollment_state).returns('active')
          exp_hash = {test: '$Canvas.enrollment.enrollmentState'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'active'
        end

        it 'has substitution for $Canvas.membership.roles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:current_canvas_roles).returns('teacher,student')
          exp_hash = {test: '$Canvas.membership.roles'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'teacher,student'
        end

        it 'has substitution for $Canvas.membership.concludedRoles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:concluded_lis_roles).returns('learner')
          exp_hash = {test: '$Canvas.membership.concludedRoles'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'learner'
        end

        it 'has substitution for $Canvas.course.previousContextIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:previous_lti_context_ids).returns('abc,xyz')
          exp_hash = {test: '$Canvas.course.previousContextIds'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'abc,xyz'
        end

        it 'has substitution for $Canvas.course.previousCourseIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:previous_course_ids).returns('1,2')
          exp_hash = {test: '$Canvas.course.previousCourseIds'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '1,2'
        end
      end

      context 'context is a course and there is a user' do
        subject { described_class.new(root_account, course, controller, current_user: user, tool: tool) }

        it 'has substitution for $Canvas.xapi.url' do
          Lti::XapiService.stubs(:create_token).returns('abcd')
          controller.stubs(:lti_xapi_url).returns('/xapi/abcd')
          exp_hash = {test: '$Canvas.xapi.url'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '/xapi/abcd'
        end

        it 'has substitution for $Canvas.course.sectionIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:section_ids).returns('5,6')
          exp_hash = {test: '$Canvas.course.sectionIds'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '5,6'
        end

        it 'has substitution for $Canvas.course.sectionSisSourceIds' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:section_sis_ids).returns('5a,6b')
          exp_hash = {test: '$Canvas.course.sectionSisSourceIds'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '5a,6b'
        end

        it 'has substitution for $Canvas.course.startAt' do
          course.start_at = '2015-04-21 17:01:36'
          course.save!
          exp_hash = {test: '$Canvas.course.startAt'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '2015-04-21 17:01:36'
        end

        it 'has a functioning guard for $Canvas.term.startAt when term.start_at is not set' do
          term = course.enrollment_term
          exp_hash = {test: '$Canvas.term.startAt'}
          subject.expand_variables!(exp_hash)

          unless term && term.start_at
            expect(exp_hash[:test]).to eq '$Canvas.term.startAt'
          end
        end

        it 'has substitution for $Canvas.term.startAt when term.start_at is set' do
          course.enrollment_term ||= EnrollmentTerm.new
          term = course.enrollment_term

          term.start_at = '2015-05-21 17:01:36'
          term.save
          exp_hash = {test: '$Canvas.term.startAt'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '2015-05-21 17:01:36'
        end

        it 'has substitution for $Canvas.externalTool.url' do
          course.save!
          tool = course.context_external_tools.create!(:domain => 'example.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'anonymous', :name => 'tool')
          expander = described_class.new(root_account, course, controller, current_user: user, tool: tool)
          exp_hash = {test: '$Canvas.externalTool.url'}
          expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq "url"
        end
      end

      context 'context is a course with an assignment' do
        subject { described_class.new(root_account, course, controller, current_user: user, assignment: assignment) }

        it 'has substitution for $Canvas.assignment.id' do
          assignment.stubs(:id).returns(2015)
          exp_hash = {test: '$Canvas.assignment.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 2015
        end

        it 'has substitution for $Canvas.assignment.title' do
          assignment.title = 'Buy as many ducks as you can'
          exp_hash = {test: '$Canvas.assignment.title'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Buy as many ducks as you can'
        end

        it 'has substitution for $Canvas.assignment.pointsPossible' do
          assignment.stubs(:points_possible).returns(10)
          exp_hash = {test: '$Canvas.assignment.pointsPossible'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 10
        end

        it 'has substitution for $Canvas.assignment.unlockAt' do
          assignment.stubs(:unlock_at).returns(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.unlockAt'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

        it 'has substitution for $Canvas.assignment.lockAt' do
          assignment.stubs(:lock_at).returns(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.lockAt'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

        it 'has substitution for $Canvas.assignment.dueAt' do
          assignment.stubs(:due_at).returns(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.dueAt'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

      end

      context 'user is logged in' do

        it 'has substitution for $Person.name.full' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.full'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Uncle Jake'
        end

        it 'has substitution for $Person.name.family' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.family'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Jake'
        end

        it 'has substitution for $Person.name.given' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.given'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Uncle'
        end

        it 'has substitution for $Person.email.primary' do
          user.email = 'someone@somewhere'
          exp_hash = {test: '$Person.email.primary'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'someone@somewhere'
        end

        it 'has substitution for $Person.address.timezone' do
          exp_hash = {test: '$Person.address.timezone'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Etc/UTC'
        end

        it 'has substitution for $User.image' do
          user.stubs(:avatar_url).returns('/my/pic')
          exp_hash = {test: '$User.image'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '/my/pic'
        end

        it 'has substitution for $Canvas.user.id' do
          user.stubs(:id).returns(456)
          exp_hash = {test: '$Canvas.user.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 456
        end

        it 'has substitution for $Canvas.xuser.allRoles' do
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          substitution_helper.stubs(:all_roles).returns('Admin,User')
          exp_hash = {test: '$Canvas.xuser.allRoles'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Admin,User'
        end

        it 'has substitution for $Membership.role' do
          substitution_helper.stubs(:all_roles).with('lis2').returns('Admin,User')
          Lti::SubstitutionsHelper.stubs(:new).returns(substitution_helper)
          exp_hash = {test: '$Membership.role'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Admin,User'
        end

        it 'has substitution for $User.id' do
          user.stubs(:id).returns(456)
          exp_hash = {test: '$User.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 456
        end

        context '$Canvas.user.prefersHighContrast' do
          it 'substitutes as true' do
            user.stubs(:prefers_high_contrast?).returns(true)
            exp_hash = {test: '$Canvas.user.prefersHighContrast'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'true'
          end

          it 'substitutes as false' do
            user.stubs(:prefers_high_contrast?).returns(false)
            exp_hash = {test: '$Canvas.user.prefersHighContrast'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'false'
          end
        end


        context 'pseudonym' do
          let(:pseudonym) { Pseudonym.new }

          before :each do
            user.stubs(:find_pseudonym_for_account).returns(pseudonym)
          end

          it 'has substitution for $Canvas.user.sisSourceId' do
            pseudonym.sis_user_id = '1a2b3c'
            exp_hash = {test: '$Canvas.user.sisSourceId'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1a2b3c'
          end

          it 'has substitution for $Person.sourcedId' do
            pseudonym.sis_user_id = '1a2b3c'
            exp_hash = {test: '$Person.sourcedId'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1a2b3c'
          end


          it 'has substitution for $Canvas.user.loginId' do
            pseudonym.unique_id = 'username'
            exp_hash = {test: '$Canvas.user.loginId'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'username'
          end

          it 'has substitution for $User.username' do
            pseudonym.unique_id = 'username'
            exp_hash = {test: '$User.username'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'username'
          end
        end

        context 'attachment' do
          let (:attachment) do
            attachment = attachment_obj_with_context(course)
            attachment.media_object = media_object
            attachment.usage_rights = usage_rights
            attachment
          end
          let(:media_object) do
            mo = MediaObject.new
            mo.media_id = '1234'
            mo.media_type = 'video'
            mo.duration = 555
            mo.total_size = 444
            mo.title = 'some title'
            mo
          end
          let(:usage_rights) do
            ur = UsageRights.new
            ur.legal_copyright = 'legit'
            ur
          end
          subject { described_class.new(root_account, account, controller, current_user: user, tool: tool, attachment: attachment) }

          it 'has substitution for $Canvas.file.media.id when a media object is present' do
            exp_hash = {test: '$Canvas.file.media.id'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1234'
          end

          it 'has substitution for $Canvas.file.media.id when a media object is present' do
            exp_hash = {test: '$Canvas.file.media.id'}
            attachment.media_object = nil
            attachment.media_entry_id = '4567'
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '4567'
          end

          it 'has substitution for $Canvas.file.media.type' do
            exp_hash = {test: '$Canvas.file.media.type'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'video'
          end

          it 'has substitution for $Canvas.file.media.duration' do
            exp_hash = {test: '$Canvas.file.media.duration'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 555
          end

          it 'has substitution for $Canvas.file.media.size' do
            exp_hash = {test: '$Canvas.file.media.size'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 444
          end

          it 'has substitution for $Canvas.file.media.title' do
            exp_hash = {test: '$Canvas.file.media.title'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'some title'
          end

          it 'uses user_entered_title for $Canvas.file.media.title if present' do
            media_object.user_entered_title = 'user title'
            exp_hash = {test: '$Canvas.file.media.title'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'user title'
          end

          it 'has substitution for $Canvas.file.usageRights.name' do
            exp_hash = {test: '$Canvas.file.usageRights.name'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'Private (Copyrighted)'
          end

          it 'has substitution for $Canvas.file.usageRights.url' do
            exp_hash = {test: '$Canvas.file.usageRights.url'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'http://en.wikipedia.org/wiki/Copyright'
          end

          it 'has substitution for $Canvas.file.usageRights.copyright_text' do
            exp_hash = {test: '$Canvas.file.usageRights.copyrightText'}
            subject.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'legit'
          end

        end

        it 'has substitution for $Canvas.masqueradingUser.id' do
          masquerading_user = User.new
          masquerading_user.stubs(:id).returns(7878)
          user.stubs(:id).returns(42)
          subject.instance_variable_set("@current_user", masquerading_user)
          exp_hash = {test: '$Canvas.masqueradingUser.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 42
        end

        it 'has substitution for $Canvas.masqueradingUser.userId' do
          masquerading_user = User.new
          masquerading_user.stubs(:id).returns(7878)
          subject.instance_variable_set("@current_user", masquerading_user)
          exp_hash = {test: '$Canvas.masqueradingUser.userId'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f'
        end

        it 'has substitution for Canvas.module.id' do
          content_tag = mock('content_tag')
          content_tag.stubs(:context_module_id).returns('foo')
          subject.instance_variable_set('@content_tag', content_tag)
          exp_hash = {test: '$Canvas.module.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'foo'
        end

        it 'has substitution for Canvas.moduleItem.id' do
          content_tag = mock('content_tag')
          content_tag.stubs(:id).returns(7878)
          subject.instance_variable_set('@content_tag', content_tag)
          exp_hash = {test: '$Canvas.moduleItem.id'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 7878
        end

        it 'has substitution for ToolConsumerProfile.url' do
          exp_hash = {test: '$ToolConsumerProfile.url'}
          subject.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'url'
        end
      end
    end

  end
end
