# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe CC::Importer::Canvas::LtiResourceLinkConverter do
  subject do
    Class.new do
      include CC::Importer::Canvas::LtiResourceLinkConverter

      def initialize(manifest, path)
        @manifest = manifest
        @package_root = PackageRoot.new(path)
      end
    end.new(manifest, path)
  end

  let(:manifest) { ImportHelper.get_import_data_xml('unzipped', 'imsmanifest') }
  let(:path) { File.expand_path(File.dirname(__FILE__) + '/../../../../fixtures/importer/unzipped') }

  describe '#convert_lti_resource_links' do
    it 'extract custom params and lookup_uuid' do
      lti_resource_links = subject.convert_lti_resource_links

      expect(lti_resource_links).to include(
        a_hash_including(
          custom: {
            param1: 'some string',
            param2: 1,
            param3: 2.56,
            param4: true,
            param5: false,
            param6: 'a12.5',
            param7: '5d781f15-c6b0-4901-a1f7-2a77e7bf4982',
            param8: '+1(855)552-2338',
          },
          lookup_uuid: '1b302c1e-c0a2-42dc-88b6-c029699a7c7a',
          launch_url: 'http://lti13testtool.docker/launch'
        )
      )
    end
  end
end
