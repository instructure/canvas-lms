#
# Copyright (C) 2017 - present Instructure, Inc.
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

RSpec.shared_context "lti2_spec_helper", :shared_context => :metadata do

  let(:account) { Account.create! }
  let(:course) { Course.create!(account: account) }
  let(:vendor_code) { 'com.instructure.test' }
  let(:developer_key) {DeveloperKey.create!(redirect_uri: 'http://www.example.com/redirect', vendor_code: vendor_code)}
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: vendor_code,
      product_code: 'abc',
      vendor_name: 'acme',
      root_account: account,
      developer_key: developer_key
    )
  end
  let(:tool_proxy) do
    tp = Lti::ToolProxy.create!(
      context: account,
      guid: SecureRandom.uuid,
      shared_secret: 'abc',
      product_family: product_family,
      product_version: '1',
      workflow_state: 'active',
      raw_data: {
        'enabled_capability' => ['Security.splitSecret'],
        'security_contract' => security_contract,
        'tool_profile' => {
          'lti_version' => 'LTI-2p0',
          'product_instance' => {
            'guid' => 'be42ae52-23fe-48f5-a783-40ecc7ef6d5c',
            'product_info' => {
              'product_version' => '1.0',
              'product_family' => {
                'code' => 'abc',
                'vendor' => {
                  'code' => '123',
                  'vendor_name' => {
                    'default_value' => 'acme'
                  },
                  'description' => {
                    'default_value' => 'example vendor'
                  }
                }
              },
              'description' => {
                'default_value' => 'example product'
              },
              'product_name' => {
                'default_value' => "learn abc's"
              }
            }
          },
          'base_url_choice' => [
            {
              'default_base_url' => 'https://www.samplelaunch.com',
              'selector' => {
                'applies_to' => [
                  'MessageHandler'
                ]
              }
            }
          ],
          'resource_handler' => [
            {
              'resource_type' => {
                'code' => 'code'
              },
              'resource_name' => {
                'default_value' => 'resource name',
                'key' => ''
              },
              'message' => [
                {
                  'message_type' => 'message_type',
                  'path' => 'https://www.samplelaunch.com/blti'
                }
              ]
            },
          ],
          'service_offered' => []
        }
      },
      lti_version: '1'
    )
    Lti::ToolProxyBinding.where(context_id: account, context_type: account.class.to_s,
                                tool_proxy_id: tp).first_or_create!
    tp
  end
  let(:resource_handler) do
    Lti::ResourceHandler.create!(
      resource_type_code: 'code',
      name: 'resource name',
      tool_proxy: tool_proxy
    )
  end
  let(:message_handler) do
    Lti::MessageHandler.create!(
      message_type: 'basic-lti-launch-request',
      launch_path: 'https://www.samplelaunch.com/blti',
      resource_handler: resource_handler,
      tool_proxy: tool_proxy
    )
  end
  let(:tool_proxy_binding) {
    Lti::ToolProxyBinding.where(context_id: account, context_type: account.class.to_s,
                                tool_proxy_id: tool_proxy).first_or_create!
  }
  let(:tool_profile) do
    {
      "lti_version" => "LTI-2p0", "product_instance" => {
        "guid" => "be42ae52-23fe-48f5-a783-40ecc7ef6d5c", "product_info" => {
          "product_version" => "1.0", "product_family" => {
            "code" => "similarity detection reference tool", "vendor" => {
              "code" => "Instructure.com", "vendor_name" => {
                "default_value" => "Instructure"
              }, "description" => {
                "default_value" => "Canvas Learning Management System"
              }
            }
          }, "description" => {
            "default_value" => "LTI 2.1 tool provider reference implementation"
          }, "product_name" => {
            "default_value" => "similarity detection reference tool"
          }
        }
      }, "base_url_choice" => [{
        "default_base_url" => "http://originality.docker", "selector" => {
          "applies_to" => ["MessageHandler"]
        }
      }], "resource_handler" => [{
        "resource_type" => {
          "code" => "sumbissions"
        }, "resource_name" => {
          "default_value" => "Similarity Detection Tool", "key" => ""
        }, "message" => [{
          "message_type" => "basic-lti-launch-request",
          "path" => "/submission/index",
          "enabled_capability" => ["Canvas.placements.accountNavigation", "Canvas.placements.courseNavigation"],
          "parameter" => []
        }]
      }, {
        "resource_type" => {
          "code" => "placements"
        }, "resource_name" => {
          "default_value" => "Similarity Detection Tool", "key" => ""
        }, "message" => [{
          "message_type" => "basic-lti-launch-request",
          "path" => "/assignments/configure",
          "enabled_capability" => ["Canvas.placements.similarityDetection"],
          "parameter" => []
        }]
      }, {
        "resource_type" => {
          "code" => "originality_reports"
        }, "resource_name" => {
          "default_value" => "Similarity Detection Tool", "key" => ""
        }, "message" => [{
          "message_type" => "basic-lti-launch-request",
          "path" => "/originality_report",
          "enabled_capability" => [],
          "parameter" => []
        }]
      }], "service_offered" => [{
        "endpoint" => "http://originality.docker/event/submission",
        "action" => ["POST"],
        "@id" => "http://originality.docker/lti/v2/services#vnd.Canvas.SubmissionEvent",
        "@type" => "RestService"
      }]
    }
  end
  let(:security_contract) do
    {
      "tp_half_shared_secret" => "shared-secret",
      "tool_service"=> [
        {"service"=>"vnd.Canvas.submission",
          "action"=>["GET"],
          "@type"=>"RestServiceProfile"},
        {"service"=>"vnd.Canvas.OriginalityReport",
          "action"=>["GET", "POST", "PUT"],
          "@type"=>"RestServiceProfile"}
      ]
    }
  end

end
