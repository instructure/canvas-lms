# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path('../spec_helper', File.dirname(__FILE__))

class SomeModel < Struct.new(:id); end

describe AssetSignature do
  def example_encode(classname, id)
    Canvas::Security.hmac_sha1("#{classname}#{id}")[0,8]
  end

  describe '.generate' do
    it 'produces a combination of id and hmac to use as a url signature' do
      asset = double(:id=>24)
      expect(AssetSignature.generate(asset)).to eq "24-#{example_encode(double.class.to_s, 24)}"
    end

    it 'produces a different hmac for each asset id' do
      asset = double(:id=>0)
      expect(AssetSignature.generate(asset)).to eq "0-#{example_encode(double.class, 0)}"
    end

    it 'produces a difference hmac for each asset class' do
      asset = SomeModel.new(24)
      expect(AssetSignature.generate(asset)).to eq "24-#{example_encode('SomeModel', 24)}"
      expect(AssetSignature.generate(asset)).not_to eq AssetSignature.generate(double(:id=>24))
    end

  end

  describe '.find_by_signature' do

    it 'finds the model if the hmac matches' do
      expect(SomeModel).to receive(:where).with(id: 24).once.and_return(double(first: nil))
      AssetSignature.find_by_signature(SomeModel, "24-#{example_encode('SomeModel',24)}")
    end

    it 'returns nil if the signature does not check out' do
      expect(SomeModel).to receive(:where).never
      expect(AssetSignature.find_by_signature(SomeModel, '24-not-the-sig')).to be_nil
    end
  end
end

