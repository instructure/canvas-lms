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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper')
require_dependency "lti/ims/concerns/advantage_services"

shared_examples 'mime_type check' do
  it 'does not return ims mime_type' do
    expect(response.headers['Content-Type']).not_to include described_class::MIME_TYPE
  end
end

shared_examples_for "advantage services" do

  let(:extra_tool_context) { raise 'Override in spec' }

  shared_examples 'extra developer key and account tool check' do
    let(:extra_tool_context) { course_account }

    it_behaves_like 'extra developer key and tool check'
  end

  shared_examples 'extra developer key and course tool check' do
    let(:extra_tool_context) { course }

    it_behaves_like 'extra developer key and tool check'
  end

  shared_examples 'extra developer key and tool check' do
    context 'a account chain-reachable tool is associated with a different developer key' do
      let(:developer_key_that_should_not_be_resolved_from_request) { DeveloperKey.create!(account: developer_key.account) }
      let(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: extra_tool_context,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key_that_should_not_be_resolved_from_request,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it 'returns 200 and finds the tool associated with the access token\'s developer key, ignoring other the other developer key and its tool' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
      end

      context 'and that developer key is the only developer key' do
        let(:before_send_request) { -> { developer_key.destroy! } }

        it_behaves_like 'mime_type check'

        it 'returns 401 unauthorized and complains about missing developer key' do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
        end
      end

      context 'and that tool is the only tool' do
        let(:before_send_request) { -> { tool.destroy! } }

        it_behaves_like 'mime_type check'

        it 'returns 401 unauthorized and complains about missing tool' do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
        end
      end
    end
  end

  describe 'common lti advantage request and response check' do
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

    it 'returns an empty response' do
      expect_empty_response
    end

    context 'with unknown context' do
      let(:context_id) { unknown_context_id }

      it_behaves_like 'mime_type check'

      it 'returns 404 not found' do
        expect(response).to have_http_status :not_found
      end
    end

    context 'with system failure during access token validation' do
      let(:jwt_validator) { instance_double(Canvas::Security::JwtValidator) }
      let(:before_send_request) do
        -> do
          allow(Canvas::Security::JwtValidator).to receive(:new).and_return(jwt_validator)
          expect(jwt_validator).to receive(:valid?).and_raise(StandardError)
        end
      end

      it_behaves_like 'mime_type check'

      it 'returns 500 not found' do
        expect(response).to have_http_status :internal_server_error
      end
    end

    context 'with no access token' do
      let(:access_token_jwt_hash) { nil }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing access token' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Missing access token')
      end
    end

    context 'with malformed access token' do
      let(:access_token_jwt) { 'gibberish' }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing access token' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Invalid access token format')
      end
    end

    context 'with no access token scope grant' do
      let(:access_token_scopes) do
        remove_access_token_scope(super())
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing scope' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Insufficient permissions')
      end
    end

    context 'with invalid access token signature' do
      let(:access_token_signing_key) { CanvasSlug.generate(nil, 64) }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about an incorrect signature' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access token invalid - signature likely incorrect')
      end
    end

    context 'with missing access token claims' do
      let(:access_token_jwt_hash) { super().delete_if { |k| %i(sub aud exp iat jti iss).include?(k) } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing assertions' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body(
          'unauthorized',
          'Invalid access token field/s: the following assertions are missing: sub,aud,exp,iat,jti,iss'
        )
      end
    end

    context 'with invalid access token audience (\'aud\')' do
      let(:access_token_jwt_hash) { super().merge(aud: 'https://wont/match/anything') }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about an invalid aud field' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Invalid access token field/s: the \'aud\' must be the LTI Authorization endpoint')
      end
    end

    context 'with expired access token' do
      let(:access_token_jwt_hash) { super().merge(exp: (Time.zone.now.to_i - 1.hour.to_i)) }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about an expired access token' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access token expired')
      end
    end

    context 'with invalid access token issuance timestamp (\'iat\')' do
      let(:access_token_jwt_hash) { super().merge(iat: (Time.zone.now.to_i + 1.hour.to_i)) }

      it 'returns 401 unauthorized and complains about an invalid iat field' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Invalid access token field/s: the \'iat\' must not be in the future')
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
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
      end
    end

    context 'with deleted developer key' do
      let(:before_send_request) { -> { developer_key.destroy! } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing developer key' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Unknown or inactive Developer Key')
      end
    end

    context 'with unbound developer key' do
      let(:before_send_request) do
        -> {
          developer_key.developer_key_account_bindings.first.update! workflow_state: DeveloperKeyAccountBinding::OFF_STATE
        }
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing developer key' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Invalid Developer Key')
      end
    end

    context 'with deleted tool' do
      let(:before_send_request) { -> { tool.destroy! } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with no tool' do
      let(:tool) { nil }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with disabled LTI 1.3/Advantage account-level features' do
      # Would also work to just override :root_account, but let's have all the setup run w/ 1.3 enabled in case
      # that has any side-effects, _then_ suddenly disable features before a LTI Advantage call arrives... as if a
      # customer had a change of heart after initially turning on LTI/Advantage 1.3 features.
      let(:before_send_request) { -> { disable_1_3(root_account) } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about disabled LTI 1.3/Advantage features' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'LTI 1.3/Advantage features not enabled')
      end
    end

    context 'with disabled LTI 1.3/Advantage tool-level features' do
      # Would also work to just override :root_account, but let's have all the setup run w/ 1.3 enabled in case
      # that has any side-effects, _then_ suddenly disable features before a LTI Advantage call arrives... as if a
      # customer had a change of heart after initially turning on LTI/Advantage 1.3 features.
      let(:before_send_request) { -> { disable_1_3(tool) } }

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about disabled LTI 1.3/Advantage features' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'LTI 1.3/Advantage features not enabled')
      end
    end

    context 'with tool and course attached to root account with no sub-accounts' do
      # the simple happy-path case.... by default :course and :developer_key are attached directly to the same Account,
      # which has no subaccounts
      it 'returns 200 and finds the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
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
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it 'returns 200 and walks up account chain to find the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
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
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it 'returns 200 and walks up account chain to find the correct tool' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
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
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_1,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it 'returns 200 and finds the tool in the same sub-sub-account as the course' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
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
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
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
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it_behaves_like 'mime_type check'

      it 'returns 401 unauthorized and complains about missing tool' do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body('unauthorized', 'Access Token not linked to a Tool associated with this Context')
      end
    end

    context 'with tool attached directly to a course' do
      # place :tool in the other account hierarchy branch
      let(:tool_context) { course }
      # place another tool (associated w same developer key) in the same account that owns the course... tool search
      # should find the course-scoped tool instead
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: course_account,
          consumer_key: 'key2',
          shared_secret: 'secret2',
          name: 'test tool 2',
          url: 'http://www.tool2.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end

      it 'returns 200 and finds the tool attached directly to the course, ignoring the account-level tool' do
        expect(response).to have_http_status :ok
        expect(controller.tool).to eq tool
      end
    end
    # rubocop:enable RSpec/LetSetup

    it_behaves_like 'extra developer key and account tool check'
    it_behaves_like 'extra developer key and course tool check'
  end


end
