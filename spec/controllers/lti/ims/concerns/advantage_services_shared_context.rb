# frozen_string_literal: true

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
require File.expand_path(File.dirname(__FILE__) + '/../../../../lti_1_3_tool_configuration_spec_helper.rb')

shared_context 'advantage services context' do
  include_context 'lti_1_3_tool_configuration_spec_helper'

  let_once(:root_account) do
    Account.default
  end
  let_once(:developer_key) do
    dk = DeveloperKey.create!(account: root_account)
    dk.developer_key_account_bindings.first.update! workflow_state: DeveloperKeyAccountBinding::ON_STATE
    dk
  end
  let(:access_token_scopes) do
    %w(
       https://purl.imsglobal.org/spec/lti-ags/scope/lineitem
       https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly
       https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly
       https://canvas.instructure.com/lti/public_jwk/scope/update
       https://canvas.instructure.com/lti/data_services/scope/create
       https://canvas.instructure.com/lti/data_services/scope/show
       https://canvas.instructure.com/lti/data_services/scope/update
       https://canvas.instructure.com/lti/data_services/scope/list
       https://canvas.instructure.com/lti/data_services/scope/destroy
       https://canvas.instructure.com/lti/data_services/scope/list_event_types
       https://canvas.instructure.com/lti/account_lookup/scope/show
       https://canvas.instructure.com/lti/feature_flags/scope/show
       https://canvas.instructure.com/lti/account_external_tools/scope/create
       https://canvas.instructure.com/lti/account_external_tools/scope/update
       https://canvas.instructure.com/lti/account_external_tools/scope/list
       https://canvas.instructure.com/lti/account_external_tools/scope/show
       https://canvas.instructure.com/lti/account_external_tools/scope/destroy
    ).join(' ')
  end
  let(:access_token_signing_key) { Canvas::Security.encryption_key }
  let(:test_request_host) { 'test.host' }
  let(:access_token_jwt_hash) do
    timestamp = Time.zone.now.to_i
    {
      iss: 'https://canvas.instructure.com',
      sub: developer_key.global_id,
      aud: "http://#{test_request_host}/login/oauth2/token",
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
      settings: { use_1_3: true },
      workflow_state: 'public'
    )
  end
  let(:course_account) do
    root_account
  end
  let(:course) { course_factory(active_course: true, account: course_account) }
  let(:context) { raise 'Override in spec' }
  let(:context_id) { context.id }
  let(:unknown_context_id) { raise 'Override in spec' }
  let(:action) { raise 'Override in spec'}
  let(:params_overrides) { {} }
  let(:json) { JSON.parse(response.body).with_indifferent_access }
  let(:scope_to_remove) { raise 'Override in spec' }
  let(:http_success_status) { :ok }
  let(:expected_mime_type) { described_class::MIME_TYPE }
  let(:content_type) { nil }

  def apply_headers
    request.headers['Authorization'] = "Bearer #{access_token_jwt}" if access_token_jwt
    request.headers['Content-Type'] = content_type if content_type.present?
  end

  def send_http
    get action, params: params_overrides
  end

  def send_request
    apply_headers
    send_http
  end

  def expect_empty_response
    raise 'Abstract Method'
  end

  def remove_access_token_scope(default_scopes, to_remove)
    scopes_to_remove = [to_remove].flatten
    default_scopes.
      split(' ').
      reject { |s| scopes_to_remove.include? s }.
      join(' ')
  end
end
