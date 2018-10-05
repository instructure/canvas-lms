#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require_dependency "lti/ims/names_and_roles_controller.rb"
require_dependency "lti/ims/providers/course_memberships_provider.rb"
require_dependency "lti/ims/providers/group_memberships_provider.rb"

describe Lti::Ims::NamesAndRolesController do
  include Lti::Ims::NamesAndRolesMatchers

  let(:root_account) do
    enable_1_3(Account.default)
  end
  let(:course_account) do
    root_account
  end
  let(:developer_key_account) do
    root_account
  end
  let(:course) { course_factory(active_course: true, account: course_account) }
  let(:group_record) { group(context: course) } # _record suffix to avoid conflict with group() factory mtd

  let(:developer_key) { DeveloperKey.create!(account: developer_key_account) }
  let(:access_token_subject) { developer_key.global_id }
  let(:access_token_scopes) do
    %w(https://purl.imsglobal.org/spec/lti-ags/scope/lineitem
       https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly
       https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly).join(' ')
  end
  let(:access_token_signing_key) { Canvas::Security.encryption_key }
  let(:access_token_jwt_hash) do
    timestamp = Time.zone.now.to_i
    {
      iss: 'https://canvas.instructure.com',
      sub: access_token_subject,
      aud: 'https://canvas.instructure.com/login/oauth2/token',
      iat: timestamp,
      exp: (timestamp + 1.hour.to_i),
      nbf: (timestamp - 30),
      jti: SecureRandom.uuid,
      scopes: access_token_scopes
    }
  end
  let(:access_token_jwt) do
    return nil if access_token_jwt_hash.blank?
    JSON::JWT.new(access_token_jwt_hash).sign(access_token_signing_key, :HS256).to_s
  end

  let(:tool_context) { root_account }
  let!(:tool) do
    ContextExternalTool.create!(
      context: tool_context,
      consumer_key: 'key',
      shared_secret: 'secret',
      name: 'test tool',
      url: 'http://www.tool.com/launch',
      developer_key: developer_key,
      settings: { use_1_3: true }
    )
  end

  let(:context) { raise 'Override in spec' }
  let(:context_id) { context.id }
  let(:unknown_context_id) { raise 'Override in spec' }
  let(:context_param_name) { raise 'Override in spec' }
  let(:action) { raise 'Override in spec'}
  let(:params_overrides) { {} }
  let(:json) { JSON.parse(response.body).with_indifferent_access }

  shared_examples 'mime_type check' do
    it 'does not return ims mime_type' do
      expect(response.headers['Content-Type']).not_to include described_class::MIME_TYPE
    end
  end

  shared_examples 'common request and response check' do
    # #around and #before(:context) don't have access to the right scope, #before(:example) runs too late,
    # so hack our own lifecycle hook
    let(:before_send_request) { ->{} }
    before do
      before_send_request.call
      send_request
    end

    it 'returns correct mime_type' do
      expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
    end

    it 'returns 200 success' do
      expect(response).to have_http_status :ok
    end

    it 'returns request url in payload' do
      expect(json[:id]).to eq request.url
    end

    it 'returns an empty members array' do
      expect_empty_members_array
    end

    context 'with unknown context' do
      let(:context_id) { unknown_context_id }

      it_behaves_like 'mime_type check'

      it 'returns 404 not found' do
        expect(response).to have_http_status :not_found
      end
    end

    context 'with no access token' do
      let(:access_token_jwt_hash) { nil }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing access token' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Missing Access Token')
      end
    end

    context 'with no NRPS V2 scope grant' do
      let(:access_token_scopes) do
        super().
          split(' ').
          reject { |s| s == 'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly' }.
          join(' ')
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing scope' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'NRPS v2 scope not granted')
      end
    end

    context 'with inactive developer key' do
      let(:before_send_request) do
        -> do
          developer_key.workflow_state = :inactive
          developer_key.save!
        end
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing developer key' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
      end
    end

    context 'with deleted developer key' do
      let(:before_send_request) { -> { developer_key.destroy! } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing developer key' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
      end
    end

    context 'with deleted tool' do
      let(:before_send_request) { -> { tool.destroy! } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with no tool' do
      let(:tool) { nil }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with disabled LTI 1.3/Advantage account-level features' do
      # Would also work to just override :root_account, but let's have all the setup run w/ 1.3 enabled in case
      # that has any side-effects, _then_ suddenly disable features before a NRPS call arrives... as if a customer
      # had a change of heart after initially turning on LTI/Advantage 1.3 features.
      let(:before_send_request) { -> { disable_1_3(root_account) } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about disabled LTI 1.3/Advantage features' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'LTI 1.3/Advantage features not enabled')
      end
    end

    context 'with disabled LTI 1.3/Advantage tool-level features' do
      # Would also work to just override :root_account, but let's have all the setup run w/ 1.3 enabled in case
      # that has any side-effects, _then_ suddenly disable features before a NRPS call arrives... as if a customer
      # had a change of heart after initially turning on LTI/Advantage 1.3 features.
      let(:before_send_request) { -> { disable_1_3(tool) } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about disabled LTI 1.3/Advantage features' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'LTI 1.3/Advantage features not enabled')
      end
    end

    context 'with tool and course attached to root account with no sub-accounts' do
      # the simple happy-path case.... by default :course and :developer_key are attached directly to the smae Account,
      # which has no subaccounts
      it 'returns 200 and finds the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end
    end

    # want to use let! specifically to set up data that should never be read, so rubocop gets upset
    # rubocop:disable RSpec/LetSetup
    context 'with tool attached to root account and course attached to deeply nested sub-account' do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(:name => "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(:name => "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(:name => "sub-account-1-1") }
      # place :course at the very bottom of account hierarchy. tool we care about will be way up at :root_account
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it 'returns 200 and walks up account chain to find the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end
    end

    context 'with tool attached to sub-account and course attached to another sub-account thereof' do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(:name => "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(:name => "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(:name => "sub-account-1-1") }
      # place :tool in the middle of the account hierarchy
      let(:tool_context) { sub_account_1 }
      # place :course at the very bottom of account hierarchy. tool we care about will be one level up at :sub_account_1
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it 'returns 200 and walks up account chain to find the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end
    end

    context 'with tool and course attached to same deeply nested sub-account' do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(:name => "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(:name => "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(:name => "sub-account-1-1") }
      # place :tool iat the very bottom of account hierarchy
      let(:tool_context) { sub_account_1_1 }
      # also place :course at the very bottom of account hierarchy. tool we care about is at the same level
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) one level higher in the account hierarchy to make
      # sure we're just walking the tree bottom-up
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: sub_account_1,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it 'returns 200 and finds the tool in the same sub-sub-account as the course' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end
    end

    # reversal of 'with tool attached to sub-account and course attached to another sub-account thereof'. should result
    # in a tool lookup miss (:tool is "lower" than :course in account hierarchy)
    context 'with course attached to sub-account and tool attached to another sub-account thereof' do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(:name => "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(:name => "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(:name => "sub-account-1-1") }
      # place :course in the middle of the account hierarchy. tool we care about will be one level down at sub_account_1_1
      let(:course_account) { sub_account_1 }
      # place :tool at the very bottom of account hierarchy. course care about will be one level up at :sub_account_1
      let(:tool_context) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    # another negative test, this time where :course and :tool are in completely disjoint account hierarchy branches
    context 'with course attached to sub-account and tool attached to another sub-account thereof' do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(:name => "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(:name => "sub-account-2") }
      # place :course in one account hierarchy branch
      let(:course_account) { sub_account_1 }
      # place :tool in the other account hierarchy branch
      let(:tool_context) { sub_account_2 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_nrps_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with tool attached directly to a course' do
      # place :tool in the other account hierarchy branch
      let(:tool_context) { course }
      # place another tool (associated w same developer key) in the same account that owns the course... tool search
      # should find the course-scoped tool instead
      let!(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: course_account,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true }
        )
      end

      it 'returns 200 and finds the tool attached directly to the course, ignoring the account-level tool' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end
    end
    # rubocop:enable RSpec/LetSetup

    it_behaves_like 'extra developer key and account tool check'
    it_behaves_like 'extra developer key and course tool check'

  end

  shared_examples 'extra developer key and account tool check' do
    let(:extra_tool_context) { course_account }

    it_behaves_like 'extra developer key and tool check'
  end

  shared_examples 'extra developer key and course tool check' do
    let(:extra_tool_context) { course }

    it_behaves_like 'extra developer key and tool check'
  end

  shared_examples 'extra developer key and tool check' do
    # When including, define the following:
    #   extra_tool_context: context into which to place a Tool associated with the "extra" developer key

    context 'a account chain-reachable tool is associated with a different developer key' do
      let(:developer_key_that_should_not_be_resolved_from_nrps_request) { DeveloperKey.create!(account: developer_key_account) }
      let(:tool_that_should_not_be_resolved_from_nrps_request) do
        ContextExternalTool.create!(
          context: extra_tool_context,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key_that_should_not_be_resolved_from_nrps_request,
          settings: { use_1_3: true }
        )
      end

      it 'returns 200 and finds the tool associated with the access token\'s developer key, ignoring other the other developer key and its tool' do
        expect(response).to have_http_status :ok
        expect(controller.send(:tool)).to eq tool
      end

      context 'and that developer key is the only developer key' do
        let(:before_send_request) { -> { developer_key.destroy! } }

        it_behaves_like 'mime_type check'

        it 'returns 401 unauthorized and complains about missing developer key' do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_nrps_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
        end
      end

      context 'and that tool is the only tool' do
        let(:before_send_request) { -> { tool.destroy! } }

        it_behaves_like 'mime_type check'

        it 'returns 401 unauthorized and complains about missing tool' do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_nrps_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
        end
      end
    end
  end

  shared_examples 'page size check' do
    # Needs all the same variables as 'multiple enrollments check', plus:
    #
    #   page_size_param_name - symbol naming the page size query param
    #
    let(:pagination_overrides) { { page_size_param_name => rqst_page_size } }
    let(:params_overrides) { super().merge(pagination_overrides) }

    it 'returns the first page of results, with the correct size and proper navigation links' do
      send_request
      expect_enrollment_response_page
      expect(response_links).to have_correct_pagination_urls
    end

    context 'when the page size parameter is too large' do
      let(:rqst_page_size) { 4611686018427387903 }
      let(:rsp_page_size) { 50 } # system max

      it 'defaults to the system maximum page size' do
        send_request
        expect_enrollment_response_page
        expect(response_links).to have_correct_pagination_urls
      end
    end

    context 'when a page index parameter is specified' do
      let(:rqst_page) { 2 }
      let(:rsp_page) { 2 }
      let(:pagination_overrides) { super().merge(page: rqst_page) }

      it 'returns the specified page of results, with the correct size and proper navigation links' do
        send_request
        expect_enrollment_response_page
        expect(response_links).to have_correct_pagination_urls
      end

      context 'and when the page index parameter is too large ' do
        let(:rqst_page) { total_items + 1 } # cant have more pages than there are items
        let(:rsp_page) { rqst_page }
        let(:rsp_page_size) { 30 } # don't know why, Api just does this

        it 'returns an empty members array, with the correct size and proper navigation links' do
          send_request
          expect_empty_members_array
          expect(response_links).to have_correct_pagination_urls
        end
      end
    end
  end

  shared_examples 'multiple enrollments check' do
    # When including, define the following:
    #   enrollments: array of context enrollments
    #   total_items: context's active enrollment count
    #   rsp_page: expected response page index
    #   rsp_page_size: expected response page size
    #   pass_through_param: hash of query params to be written through to pagination links
    #   params_overrides: hash of all request params

    it 'returns all enrollments sorted by user id' do
      send_request
      expect_enrollment_response_page
      expect(response_links).to have_correct_pagination_urls
    end

    context 'when a limit page size parameter is specified' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :limit }

      it_behaves_like 'page size check'
    end

    context 'when a per_page parameter is specified' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :per_page }

      it_behaves_like 'page size check'
    end

    context 'when a limit param overrides a per_page param' do
      let(:rqst_page_size) { 2 }
      let(:rsp_page_size) { 2 }
      let(:page_size_param_name) { :limit }

      # limit=2, per_page=3 ... latter should be ignored
      let(:params_overrides) { super().merge(per_page: 3) }

      it_behaves_like 'page size check'
    end
  end

  describe '#course_index' do
    let(:action) { :course_index }
    let(:context) { course }
    let(:context_param_name) { :course_id }
    let(:unknown_context_id) { course && Course.maximum(:id) + 1 }

    it_behaves_like 'common request and response check'

    # Bunch of single-enrollment tests b/c they're just so much easier to
    # debug as compared to multi-enrollment tests

    context 'when a course has a single enrollment' do
      it 'returns teacher in members array' do
        enrollment = teacher_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns student in members array' do
        enrollment = student_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns ta in members array' do
        enrollment = ta_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns observer in members array' do
        enrollment = observer_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns designer in members array' do
        enrollment = designer_in_course(course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom teacher in members array' do
        enrollment = custom_enrollment_in_course('TeacherEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom student in members array' do
        enrollment = custom_enrollment_in_course('StudentEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom ta in members array' do
        enrollment = custom_enrollment_in_course('TaEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom observer in members array' do
        enrollment = custom_enrollment_in_course('ObserverEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end

      it 'returns custom designer in members array' do
        enrollment = custom_enrollment_in_course('DesignerEnrollment', course: course, active_all: true)
        send_request
        expect_single_member(enrollment)
      end
    end

    context 'when a course has a user with multiple active enrollments' do
      it 'returns both enrollments in the same NRPS membership' do
        teacher_enrollment = teacher_in_course(course: course, active_all: true)
        student_enrollment = student_in_course(course: course, user: teacher_enrollment.user, active_all: true)
        send_request
        expect_single_member(teacher_enrollment, student_enrollment)
      end
    end

    context 'when a course has a concluded enrollment' do
      it 'does not return the concluded enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.conclude
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a deactivated enrollment' do
      it 'does not return the deactivated enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.deactivate
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a deleted enrollment' do
      it 'does not return the deleted enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.destroy # logical delete (physical wont work and will just raise a FK violation)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a rejected enrollment' do
      it 'does not return the rejected enrollment' do
        enrollment = teacher_in_course(course: course, active_all: true)
        enrollment.reject!
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a invited instructor enrollment' do
      it 'does not return the invited instructor enrollment' do
        teacher_in_course(course: course)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has a creation_pending student enrollment' do
      it 'does not return the creation_pending student enrollment' do
        student_in_course(course: course)
        send_request
        expect_empty_members_array
      end
    end

    context 'when a course has multiple enrollments' do

      let!(:teacher_enrollment) { teacher_in_course(course: course, active_all: true) }
      let!(:student_enrollment) { student_in_course(course: course, active_all: true) }
      let!(:ta_enrollment) { ta_in_course(course: course, active_all: true) }
      let!(:observer_enrollment) { observer_in_course(course: course, active_all: true) }
      let!(:designer_enrollment) { designer_in_course(course: course, active_all: true) }
      let!(:enrollments) do
        [
          teacher_enrollment,
          student_enrollment,
          ta_enrollment,
          observer_enrollment,
          designer_enrollment
        ]
      end
      let(:total_items) { enrollments.length }
      let(:rsp_page) { 1 }
      let(:rsp_page_size) { 10 } # system default
      let(:pass_thru_params) { { pass: 'thru' } }
      let(:params_overrides) { super().merge(pass_thru_params) }

      it_behaves_like 'multiple enrollments check'

      context 'and the role param specifies the LIS Instructor role' do
        let(:total_items) { 2 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor')}

        it 'limits results to Canvas Teachers and TAs' do
          send_request
          expect_enrollment_response_page_of([teacher_enrollment, ta_enrollment])
        end
      end

      context 'and the role param specifies the LIS Learner role' do
        let(:total_items) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner')}

        it 'limits results to Canvas Students' do
          send_request
          expect_enrollment_response_page_of([student_enrollment])
        end
      end

      context 'and the role param specifies the LIS TeachingAssistant role' do
        let(:total_items) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant')}

        it 'limits results to Canvas TAs' do
          send_request
          expect_enrollment_response_page_of([ta_enrollment])
        end
      end

      context 'and the role param specifies the LIS Mentor role' do
        let(:total_items) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor')}

        it 'limits results to Canvas Observers' do
          send_request
          expect_enrollment_response_page_of([observer_enrollment])
        end
      end

      context 'and the role param specifies the LIS ContentDeveloper role' do
        let(:total_items) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper')}

        it 'limits results to Canvas Designers' do
          send_request
          expect_enrollment_response_page_of([designer_enrollment])
        end
      end

      context 'and the role param specifies an unknown value' do
        let(:params_overrides) { super().merge(role: 'http://purl.imsglobal.org/total/nonsense')}

        it 'returns no course members' do
          send_request
          expect_empty_members_array
        end
      end

      context 'and a course has a user with multiple active enrollments' do
        let(:student_enrollment_2) { student_in_course(course: course, user: teacher_enrollment.user, active_all: true) }
        let(:enrollments) { super().push(student_enrollment_2) }

        context 'and the role parameter specifies the first enrollment role' do
          let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor') }

          it 'returns matching NRPS memberships grouped by user' do
            send_request
            expect_member(teacher_enrollment, student_enrollment_2, index: 0)
            expect_member(ta_enrollment, index: 1)
            expect_member_count(2)
          end
        end

        context 'and the role parameter specifies the second enrollment role' do
          let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner') }

          it 'returns matching NRPS memberships grouped by user' do
            send_request
            expect_member(teacher_enrollment, student_enrollment_2, index: 0)
            expect_member(student_enrollment, index: 1)
            expect_member_count(2)
          end
        end
      end

      context 'and role and pagination parameters are specified' do
        let(:total_items) { 2 }
        let(:rsp_page_size) { 1 }
        let(:rqst_page_size) { 1 }
        let(:rqst_page) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor') }
        let(:params_overrides) do
          super().merge(
            limit: rqst_page_size,
            page: rqst_page
          )
        end

        context 'and the first page of results are requested' do
          it 'returns the correct first page of results' do
            send_request
            expect_enrollment_response_page_of([teacher_enrollment])
            expect(response_links).to have_correct_pagination_urls
          end
        end

        context 'and the second page of results are requested' do
          let(:rqst_page) { 2 }
          let(:rsp_page) { 2 }

          it 'returns the correct second page of results' do
            send_request
            expect_enrollment_response_page_of([ta_enrollment])
            expect(response_links).to have_correct_pagination_urls
          end
        end
      end
    end
  end

  describe '#group_index' do
    let(:action) { :group_index }
    let(:context) { group_record }
    let(:context_param_name) { :group_id }
    let(:unknown_context_id) { group_record && Group.maximum(:id) + 1 }

    it_behaves_like 'common request and response check'

    context 'when a group has a single membership' do
      let(:group_record) { group_with_user(active_all: true).group }
      let(:group_member) { group_record.group_memberships.first }

      it 'returns that membership' do
        send_request
        expect_single_member(group_member)
      end
    end

    context 'when a group has a deleted membership' do
      let(:group_record) { group_with_user(active_all: true).group }
      let(:group_member) { group_record.group_memberships.first }

      it 'does not return the deleted membership' do
        group_member.destroy
        send_request
        expect_empty_members_array
      end
    end

    context 'when a group has a pending membership' do
      let(:group_record) { group_with_user(join_level: 'invitation_only').group }
      let(:group_member) { group_record.group_memberships.first }

      it 'does not return the pending membership' do
        pending("group memberships are always auto-accepted so cant test \"invited\" workflow state - see GroupMembership#auto_join")
        send_request
        expect_empty_members_array
      end
    end

    context 'when a group has multiple memberships' do

      let!(:group_leadership) do
        leader = group_membership_model(group: group_record, user: user_model)
        group_record.leader = leader.user
        group_record.save
        leader
      end
      let!(:group_membership_1) { group_membership_model(group: group_record, user: user_model) }
      let!(:group_membership_2) { group_membership_model(group: group_record, user: user_model) }
      let!(:group_membership_3) { group_membership_model(group: group_record, user: user_model) }
      let!(:group_membership_4) { group_membership_model(group: group_record, user: user_model) }
      let!(:enrollments) do
        [
          group_leadership,
          group_membership_1,
          group_membership_2,
          group_membership_3,
          group_membership_4
        ]
      end
      let(:total_items) { enrollments.length }
      let(:rsp_page) { 1 }
      let(:rsp_page_size) { 10 } # system default
      let(:pass_thru_params) { { pass: 'thru' } }
      let(:params_overrides) { super().merge(pass_thru_params) }

      it_behaves_like 'multiple enrollments check'

      context 'and the role param specifies the LIS Manager role' do
        let(:total_items) { 1 }
        let(:params_overrides) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Manager')}

        it 'limits results to the Canvas group leader' do
          send_request
          expect_enrollment_response_page_of([group_leadership])
        end
      end

      context 'and the role param specifies the LIS Member role' do
        let(:params_overrides) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Member')}

        it 'returns all group members' do
          send_request
          expect_enrollment_response_page
        end
      end

      context 'and the role param specifies an unknown value' do
        let(:params_overrides) { super().merge(role: 'http://purl.imsglobal.org/total/nonsense')}

        it 'returns no group members' do
          send_request
          expect_empty_members_array
        end
      end

      # Somewhat redundant for groups which just have two roles, one of which everyone in the group shares. But
      # still useful for anti-regression purposes to at least verify that combining role + pagination params doesn't
      # break anything
      context 'and role and pagination parameters are specified' do
        let(:rsp_page_size) { 1 }
        let(:rqst_page_size) { 1 }
        let(:rqst_page) { 1 }
        let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Member') }
        let(:params_overrides) do
          super().merge(
            limit: rqst_page_size,
            page: rqst_page
          )
        end

        context 'and the first page of results are requested' do
          it 'returns the correct first page of results' do
            send_request
            expect_enrollment_response_page_of([group_leadership])
            expect(response_links).to have_correct_pagination_urls
          end
        end

        context 'and the second page of results are requested' do
          let(:rqst_page) { 2 }
          let(:rsp_page) { 2 }

          it 'returns the correct second page of results' do
            send_request
            expect_enrollment_response_page_of([group_membership_1])
            expect(response_links).to have_correct_pagination_urls
          end
        end

        context 'and the role param limits results to the group leader' do
          let(:total_items) { 1 }
          let(:pass_thru_params) { super().merge(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Manager') }

          it 'returns the group leader' do
            send_request
            expect_enrollment_response_page_of([group_leadership])
            expect(response_links).to have_correct_pagination_urls
          end
        end
      end
    end
  end

  def send_request
    request.headers['Authorization'] = "Bearer #{access_token_jwt}" if access_token_jwt
    get action, params: { context_param_name => context_id }.merge(params_overrides)
  end

  def expect_single_member(*enrollment)
    expect_member(*enrollment)
    expect_member_count(1)
    enrollment
  end

  def expect_member(*enrollment, index: 0)
    # Not doing contain_exactly() b/c it's impossible to see which specific field is problematic in
    # any given bad element.
    expect(json[:members][index]).to match_enrollment(*enrollment)
    enrollment
  end

  def expect_empty_members_array
    expect(json[:members]).to be_empty
    expect(json[:members]).to be_a_kind_of(Array)
  end

  def expect_member_count(count)
    expect(json[:members].length).to eq(count)
  end

  def custom_enrollment_in_course(base_type_name, opts={})
    opts[:account] ||= opts[:course].account
    opts[:role] ||= custom_role(base_type_name, "Custom#{base_type_name}", opts)
    course_with_user(base_type_name, opts)
  end

  def match_enrollment(*enrollment)
    enrollment.first.is_a?(Enrollment) ? be_lti_course_membership(*enrollment) : be_lti_group_membership(*enrollment)
  end

  def expect_enrollment_response_page
    expect_enrollment_response_page_of(enrollments.
      sort_by { |e| e.user.id }.
      slice(rsp_page_size*(rsp_page-1), rsp_page_size))
  end

  def expect_enrollment_response_page_of(scoped_enrollments)
    scoped_enrollments.each_with_index { |e,i| expect_member(e, index: i) }
    expect_member_count([rsp_page_size,total_items].min)
  end

  def have_correct_pagination_urls
    total_pages = page_count(total_items, rsp_page_size)
    pass_thrus = as_query_params(pass_thru_params)

    # rubocop:disable Metrics/LineLength
    expected_links = [
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page}&per_page=#{rsp_page_size}>; rel=\"current\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page+1}&per_page=#{rsp_page_size}>; rel=\"next\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{rsp_page-1}&per_page=#{rsp_page_size}>; rel=\"prev\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=1&per_page=#{rsp_page_size}>; rel=\"first\"",
      "<http://test.host/api/lti/#{context.class.to_s.downcase}s/#{context_id}/names_and_roles?#{pass_thrus}page=#{total_pages}&per_page=#{rsp_page_size}>; rel=\"last\""
    ]
    # rubocop:enable Metrics/LineLength
    expected_links.reject! {|el| el.include?('rel="next"')} if rsp_page == total_pages
    expected_links.reject! {|el| el.include?('rel="prev"')} if rsp_page <= 1
    expected_links.reject! {|el| el.include?('rel="last"')} if rsp_page > total_pages
    match_array(expected_links)
  end

  def as_query_params(params_hash)
    params_hash.empty? ? '' : "#{params_hash.to_query}&"
  end

  def page_count(total_items, page_size)
    (total_items / page_size) + (total_items % page_size > 0 ? 1 : 0)
  end

  def response_links
    response.headers["Link"].split(",")
  end

  def enable_1_3(enableable)
    if enableable.is_a?(ContextExternalTool)
      enableable.use_1_3 = true
    elsif enableable.is_a?(Account)
      enableable.enable_feature!(:lti_1_3)
    else raise "LTI 1.3/Advantage features not relevant for #{enableable.class}"
    end
    enableable.save!
    enableable
  end

  def disable_1_3(enableable)
    if enableable.is_a?(ContextExternalTool)
      enableable.use_1_3 = false
    elsif enableable.is_a?(Account)
      enableable.disable_feature!(:lti_1_3)
    else raise "LTI 1.3/Advantage features not relevant for #{enableable.class}"
    end
    enableable.save!
    enableable
  end
end
