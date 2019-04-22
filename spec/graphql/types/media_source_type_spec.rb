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

require_relative "../graphql_spec_helper"
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Types::MediaSourceType do
  before(:once) do
    teacher_in_course(active_all: true)

    @media_object = media_object(
      user: @teacher,
    )
  end

  let(:media_object_type) { GraphQLTypeTester.new(@media_object, current_user: @teacher) }

  context 'with a valid media source' do
    def resolve_media_object_field(field)
      media_object_type.resolve(
        "mediaSources {
          #{field}
        }"
      )
    end

    before do
      allow(CanvasKaltura::ClientV3).to receive(:new) {
        instance_double(
          CanvasKaltura::ClientV3,
          media_sources: [
            {
              bitrate: '644580',
              content_type: 'video/mp4',
              fileExt: 'mp4',
              height: '360',
              isOriginal: '0',
              size: '8974',
              url: 'https://some-cool-url.com/',
              width: '632',
            },
          ]
        )
      }
    end

    [
      ['bitrate', '644580'],
      ['contentType', 'video/mp4'],
      ['fileExt', 'mp4'],
      ['height', '360'],
      ['isOriginal', '0'],
      ['size', '8974'],
      ['url', 'https://some-cool-url.com/'],
      ['width', '632'],
    ].each do |key, value|
      it "returns the correct #{key} for the media source" do
        expect(resolve_media_object_field(key)).to eq([value])
      end
    end
  end
end