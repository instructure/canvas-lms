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

require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper.rb')

describe SupportHelpers::PlagiarismPlatformController do
  include_context 'lti2_spec_helper'

  let(:user) { site_admin_user }

  describe '#resubmit_for_assignment' do
    let_once(:assignment) { assignment_model }
    let_once(:submission) { submission_model(assignment: assignment) }

    let(:params) { {assignment_id: assignment.id} }

    before do
      user_session(user)
    end

    it 'triggers a plagiarism_resubmit event for all submissions' do
      expect(Canvas::LiveEvents).to receive(:plagiarism_resubmit).with(submission)
      get :resubmit_for_assignment, params: params
    end

    context 'when user is not site admin' do
      subject { response }

      let(:user) { user_model }

      it 'redirects to login page' do
        get :resubmit_for_assignment, params: params
        expect(subject).to be_redirect
      end
    end
  end

  describe '#add_service' do
    subject do
      updated_tool_services
    end

    let(:product_code) { product_family.product_code }
    let(:service_actions) { ['GET', 'pOsT'] }
    let(:service_name) { 'vnd.Canvas.webhooksSubscription' }
    let(:updated_tool_services) do
      Lti::ToolProxy.all.map { |tp| tp.raw_data.dig('security_contract', 'tool_service') }
    end
    let(:params) do
      {
        'vendor_code' => vendor_code,
        'product_code' => product_code,
        'service' => service_name,
        'actions' => service_actions
      }
    end
    let!(:second_tool_proxy) do
      tp = tool_proxy.dup
      tp.update!(guid: SecureRandom.uuid)
      tp
    end

    before do
      user_session(user)
      get :add_service, params: params
    end

    it 'is a succesful response' do
      expect(response).to be_success
    end

    it 'adds the service to all tool proxies' do
      expect(subject.first.last['service']).to eq 'vnd.Canvas.webhooksSubscription'
      expect(subject.last.last['service']).to eq 'vnd.Canvas.webhooksSubscription'
    end

    it 'adds the correct actions to the service' do
      expect(subject.first.last['action']).to match_array [
        'GET', 'POST'
      ]
    end

    context 'errors' do
      subject { response }

      shared_examples_for 'bad requests' do
        it 'does not modify the tool proxies' do
          expect(
            updated_tool_services.first.map do |s|
              s['service']
            end
          ).not_to include service_name
        end
      end

      context 'when user is not site admin' do
        let(:user) { user_model }

        it { is_expected.to be_redirect }

        it_behaves_like 'bad requests'
      end

      context 'when product code is missing' do
        let(:params) do
          {
            'vendor_code' => vendor_code,
            'service' => service_name,
            'actions' => service_actions
          }
        end

        it { is_expected.to be_bad_request }

        it_behaves_like 'bad requests'
      end

      context 'when vendor code is missing' do
        let(:params) do
          {
            'product_code' => product_code,
            'service' => service_name,
            'actions' => service_actions
          }
        end

        it { is_expected.to be_bad_request }

        it_behaves_like 'bad requests'
      end

      context 'when service is missing' do
        let(:params) do
          {
            'vendor_code' => vendor_code,
            'product_code' => product_code,
            'actions' => service_actions
          }
        end

        it { is_expected.to be_bad_request }

        it_behaves_like 'bad requests'
      end

      context 'when actions are missing' do
        let(:params) do
          {
            'vendor_code' => vendor_code,
            'product_code' => product_code,
            'service' => service_name,
          }
        end

        it { is_expected.to be_bad_request }

        it_behaves_like 'bad requests'
      end
    end
  end
end