#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Canvas::Cdn do

  before :each do
    @original_config = Canvas::Cdn.config.dup
  end

  after :each do
    Canvas::Cdn.config.replace(@original_config)
  end

  describe '.enabled?' do
    it 'returns true when the cdn config has a bucket' do
      Canvas::Cdn.config.merge! enabled: true, bucket: 'bucket_name'
      expect(Canvas::Cdn.enabled?).to eq true
    end

    it 'returns false when the cdn config does not have a bucket' do
      Canvas::Cdn.config.merge! enabled: true, bucket: nil
      expect(Canvas::Cdn.enabled?).to eq false
    end
  end

  describe '.add_brotli_to_host_if_supported' do
    it 'puts a /br on the front when brotli is supported' do
      Canvas::Cdn.config.merge! host: 'somehostname'
      request = double()
      expect(request).to receive(:headers).and_return({'Accept-Encoding'=> 'gzip, deflate, br'})
      expect(Canvas::Cdn.add_brotli_to_host_if_supported(request)).to eq "somehostname/br"
    end

    it 'does not put a /br on the front when brotli is not supported' do
      Canvas::Cdn.config.merge! host: 'somehostname'
      request = double()
      expect(request).to receive(:headers).and_return({'Accept-Encoding'=> 'gzip, deflate'})
      expect(Canvas::Cdn.add_brotli_to_host_if_supported(request)).to eq "somehostname"
    end
  end

  describe '.supports_brotli?' do
    it 'returns false when there is no request avaiable' do
      expect(Canvas::Cdn.supports_brotli?(nil)).to be_falsy
    end

    it 'returns false if user agent doesnt accept-encoding "br"' do
      request = double()
      expect(request).to receive(:headers).and_return({'Accept-Encoding' => 'gzip, deflate'})
      expect(Canvas::Cdn.supports_brotli?(request)).to be_falsy
    end

    it 'returns true when the user agent supports brotli' do
      request = double()
      expect(request).to receive(:headers).and_return({'Accept-Encoding'=> 'gzip, deflate, br'})
      expect(Canvas::Cdn.supports_brotli?(request)).to be_truthy
    end
  end
end
