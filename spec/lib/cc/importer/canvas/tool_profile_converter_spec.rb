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

require File.expand_path(File.dirname(__FILE__) + '/../../../../import_helper')

describe CC::Importer::Canvas::ToolProfileConverter do
  let(:manifest) { ImportHelper.get_import_data_xml('unzipped', 'imsmanifest') }
  let(:path) { File.expand_path(File.dirname(__FILE__) + '/../../../../fixtures/importer/unzipped') }
  let(:converter) do
    Class.new do
      include CC::Importer::Canvas::ToolProfileConverter

      def initialize(manifest, path)
        @manifest = manifest
        @package_root = PackageRoot.new(path)
      end
    end.new(manifest, path)
  end

  describe '#convert_tool_profiles' do
    it 'unpacks tool profiles in the common cartridge' do
      tool_profiles = converter.convert_tool_profiles
      expect(tool_profiles.size).to eq(1)
      expect(tool_profiles.first).to eq({
        "tool_profile" => {
          "lti_version" => "LTI-2p0",
          "product_instance" => {
            "guid" => "be42ae52-23fe-48f5-a783-40ecc7ef6d5c",
            "product_info" => {
              "product_version" => "1.0",
              "product_family" => {
                "code" => "similarity detection reference tool",
                "vendor" => {
                  "code" => "Instructure.com",
                  "vendor_name" => {
                    "default_value" => "Instructure"
                  },
                  "description" => {
                    "default_value" => "Canvas Learning Management System"
                  }
                }
              },
              "description" => {
                "default_value" => "LTI 2.1 tool provider reference implementation"
              },
              "product_name" => {
                "default_value" => "similarity detection reference tool"
              }
            }
          },
          "base_url_choice" => [
            {
              "default_base_url" => "http://originality.docker",
              "selector" => {
                "applies_to" => [
                  "MessageHandler"
                ]
              }
            }
          ],
          "resource_handler" => [
            {
              "resource_type" => {
                "code" => "sumbissionsz"
              },
              "resource_name" => {
                "default_value" => "Similarity Detection Tool",
                "key" => ""
              },
              "message" => [
                {
                  "message_type" => "basic-lti-launch-request",
                  "path" => "/submission/index",
                  "enabled_capability" => [
                    "Canvas.placements.accountNavigation",
                    "Canvas.placements.courseNavigation"
                  ]
                }
              ]
            },
            {
              "resource_type" => {
                "code" => "placements"
              },
              "resource_name" => {
                "default_value" => "Similarity Detection Tool",
                "key" => ""
              },
              "message" => [
                {
                  "message_type" => "basic-lti-launch-request",
                  "path" => "/assignments/configure",
                  "enabled_capability" => [
                    "Canvas.placements.similarityDetection"
                  ]
                }
              ]
            }
          ],
          "service_offered" => [
            {
              "endpoint" => "http://originality.docker/event/submission",
              "action" => [
                "POST"
              ],
              "@id" => "http://originality.docker/lti/v2/services#vnd.Canvas.SubmissionEvent",
              "@type" => "RestService"
            }
          ]
        },
        "meta" => {
          "registration_url" => "https://register.me/register"
        },
        "migration_id" => "i964fd8107ac2c2e75e9a142971693976",
        "resource_href" => "i964fd8107ac2c2e75e9a142971693976.json"
      })
    end
  end
end
