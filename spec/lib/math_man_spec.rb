#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

describe MathMan do
  let(:latex) do
    '\sqrt{25}+12^{12}'
  end
  let(:service_url) { 'http://www.mml-service.com' }
  let(:use_for_mml) { false }
  let(:use_for_svg) { false }

  before do
    PluginSetting.create(
      name: 'mathman',
      settings: {
        base_url: service_url,
        use_for_mml: use_for_mml,
        use_for_svg: use_for_svg
      }
    )
  end

  describe '.url_for' do
    it 'should include target string in generated url' do
      expect(MathMan.url_for(latex: latex, target: :mml)).to match(/mml/)
      expect(MathMan.url_for(latex: latex, target: :svg)).to match(/svg/)
    end
  end

  describe '.use_for_mml?' do
    it 'returns false when not appropriately configured' do
      expect(MathMan.use_for_mml?).to be_falsey
    end

    context 'when appropriately configured' do
      let(:use_for_mml) { true }

      it 'returns true' do
        expect(MathMan.use_for_mml?).to be_truthy
      end
    end
  end

  describe '.use_for_svg?' do
    it 'returns false when not appropriately configured' do
      expect(MathMan.use_for_svg?).to be_falsey
    end

    context 'when appropriately configured' do
      let(:use_for_svg) { true }

      it 'returns true' do
        expect(MathMan.use_for_svg?).to be_truthy
      end
    end
  end
end
