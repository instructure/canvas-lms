#
# Copyright (C) 2016 Instructure, Inc.
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

require 'spec_helper'

module Api
  module Html
    describe TrackTag do
      describe '#to_node' do
        let(:url_helper) do
          stub({
            show_media_tracks_url: 'media/track/vtt'
          })
        end

        let(:media_track) do
          stub(
            kind: 'subtitles',
            locale: 'en',
            id: 1,
            media_object_id: 1
          )
        end

        let(:track_tag) do
          TrackTag.new(
            media_track,
            Nokogiri::XML::DocumentFragment.parse('<div></div>'),
            Nokogiri::XML::Node
          )
        end

        subject(:node) do
          track_tag.to_node(url_helper)
        end

        specify { expect(node['kind']).to eq 'subtitles' }
        specify { expect(node['srclang']).to eq 'en' }
        specify { expect(node['src']).not_to be_nil }
        specify { expect(node['label']).to match(/English/) }
      end
    end
  end
end
