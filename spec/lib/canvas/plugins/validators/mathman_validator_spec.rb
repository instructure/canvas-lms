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

describe Canvas::Plugins::Validators::MathmanValidator do
  describe '.validate' do
    let(:plugin_setting) do
      PluginSetting.new(
        name: 'mathman',
        settings: PluginSetting.settings_for_plugin('mathman')
      )
    end
    let(:settings) do
      {
        base_url: 'http://mathman.docker'
      }
    end

    subject(:validator) do
      Canvas::Plugins::Validators::MathmanValidator.validate(settings, plugin_setting)
    end

    it 'should return provided settings when base_url is a valid url' do
      expect(validator).to eq settings
    end

    context 'when base_rul is invalid' do
      let(:settings) do
        {
          base_url: 'wooper'
        }
      end

      it 'returns false' do
        expect(validator).to be_falsey
      end

      it 'adds errors to plugin_setting' do
        expect(plugin_setting.errors[:base]).to be_empty, 'precondition'
        validator
        expect(plugin_setting.errors[:base]).not_to be_empty
      end
    end
  end
end
