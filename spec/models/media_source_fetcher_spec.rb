#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe MediaSourceFetcher do
  let(:api_client) do
    mock('api_client').responds_like_instance_of(CanvasKaltura::ClientV3)
  end

  let(:fetcher) do
    MediaSourceFetcher.new(api_client)
  end

  describe '#fetch_preferred_source_url' do
    context 'when file extension and media_type are provided' do
      it 'raises an error' do
        expect {
          fetcher.fetch_preferred_source_url(media_id: 'theMediaId', file_extension: 'mp4', media_type: 'audio')
        }.to raise_error(ArgumentError, /file_extension and media_type should not both be present/)
      end
    end

    context 'when no media_sources are found' do
      it 'returns nil' do
        api_client.expects(:media_sources).with('theMediaId').returns([])

        url = fetcher.fetch_preferred_source_url(media_id: 'theMediaId', file_extension: 'mp4')

        expect(url).to eq nil
      end
    end

    context 'when file extension is provided' do
      it 'returns the url of the first media source matching that extension, ignoring media_type' do
        api_client.expects(:media_sources).with('theMediaId').returns([
          {url: 'http://example.com/nope.wmv', fileExt: 'wmv'},
          {url: 'http://example.com/yep.mp4', fileExt: 'mp4'},
          {url: 'http://example.com/nope.mp4', fileExt: 'mp4'},
        ])

        url = fetcher.fetch_preferred_source_url(media_id: 'theMediaId', file_extension: 'mp4')

        expect(url).to eq 'http://example.com/yep.mp4'
      end
    end

    context 'when media type is video' do
      it 'returns the first media source with type mp4' do
        api_client.expects(:media_sources).with('theMediaId').returns([
          {url: 'http://example.com/original.mov', fileExt: 'mov'},
          {url: 'http://example.com/web.mp4', fileExt: 'mp4'},
          {url: 'http://example.com/mobile.mp4', fileExt: 'mp4'},
        ])

        url = fetcher.fetch_preferred_source_url(media_id: 'theMediaId', media_type: 'video')

        expect(url).to eq 'http://example.com/web.mp4'
      end
    end

    context 'when media type is audio' do
      it 'returns an mp3 if one is present' do
        api_client.expects(:media_sources).with('theMediaId').returns([
          {url: 'http://example.com/yep.mp3', fileExt: 'mp3'},
          {url: 'http://example.com/no.mp4', fileExt: 'mp4'},
          {url: 'http://example.com/nope.mp4', fileExt: 'mp4'},
        ])

        url = fetcher.fetch_preferred_source_url(media_id: 'theMediaId', media_type: 'audio')

        expect(url).to eq 'http://example.com/yep.mp3'
      end

      it 'returns an mp4 when no mp3 sources exist' do
        api_client.expects(:media_sources).with('theMediaId').returns([
          {url: 'http://example.com/nomp3here.wav', fileExt: 'wav'},
          {url: 'http://example.com/butwehave.mp4', fileExt: 'mp4'},
          {url: 'http://example.com/andalso.mp4', fileExt: 'mp4'},
        ])

        url = fetcher.fetch_preferred_source_url(media_id: 'theMediaId', media_type: 'audio')

        expect(url).to eq 'http://example.com/butwehave.mp4'
      end
    end
  end
end
