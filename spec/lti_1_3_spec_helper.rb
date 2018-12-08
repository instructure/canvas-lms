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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

RSpec.shared_context "lti_1_3_spec_helper", shared_context: :metadata do
  let(:fallback_proxy) do
    Canvas::DynamicSettings::FallbackProxy.new({
      Lti::KeyStorage::PAST => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::PRESENT => Lti::RSAKeyPair.new.to_jwk.to_json,
      Lti::KeyStorage::FUTURE => Lti::RSAKeyPair.new.to_jwk.to_json
    })
  end

  let(:developer_key) { DeveloperKey.create!(account: account) }

  let(:launch_url) { 'http://lti13testtool.docker/blti_launch' }

  let(:tool_configuration) do
    Lti::ToolConfiguration.create!(
      developer_key: developer_key,
      settings: settings
    )
  end

  let(:public_jwk) do
    {
      "kty" => "RSA",
      "e" => "AQAB",
      "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
      "kid" => "2018-09-18T21:55:18Z",
      "alg" => "RS256",
      "use" => "sig"
    }
  end

  let(:settings) do
    {
      'title' => 'LTI 1.3 Tool',
      'description' => '1.3 Tool',
      'launch_url' => launch_url,
      'custom_fields' => {'has_expansion' => '$Canvas.user.id', 'no_expansion' => 'foo'},
      'public_jwk' => public_jwk,
      'extensions' =>  [
        {
          'platform' => 'canvas.instructure.com',
          'privacy_level' => 'public',
          'tool_id' => 'LTI 1.3 Test Tool',
          'domain' => 'http://lti13testtool.docker',
          'settings' =>  {
            'icon_url' => 'https://static.thenounproject.com/png/131630-200.png',
            'selection_height' => 500,
            'selection_width' => 500,
            'text' => 'LTI 1.3 Test Tool Extension text',
            'course_navigation' =>  {
              'message_type' => 'LtiResourceLinkRequest',
              'canvas_icon_class' => 'icon-lti',
              'icon_url' => 'https://static.thenounproject.com/png/131630-211.png',
              'text' => 'LTI 1.3 Test Tool Course Navigation',
              'url' =>
              'http://lti13testtool.docker/launch?placement=course_navigation',
              'enabled' => true
            }
          }
        }
      ]
    }
  end

  before do
    allow(Canvas::DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end
end
