#
# Copyright (C) 2015 Instructure, Inc.
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

require_relative '../../spec_helper.rb'

describe AccountAuthorizationConfig::PluginSettings do
  let(:klass) do
    Class.new(AccountAuthorizationConfig) do
      include AccountAuthorizationConfig::PluginSettings
      self.plugin = :custom_plugin

      def noninherited_method
        'noninherited'
      end

      plugin_settings :auth_host, noninherited_method: :renamed_setting
    end
  end

  let(:plugin) { mock() }

  before do
    Canvas::Plugin.stubs(:find).with(:custom_plugin).returns(plugin)
  end

  describe '.globally_configured?' do
    it 'chains to the plugin being enabled' do
      plugin.stubs(:enabled?).returns(false)
      expect(klass.globally_configured?).to eq false

      plugin.stubs(:enabled?).returns(true)
      expect(klass.globally_configured?).to eq true
    end
  end

  describe '.recognized_params' do
    context 'with plugin config' do
      it 'returns nothing' do
        plugin.stubs(:enabled?).returns(true)
        expect(klass.recognized_params).to eq []
      end
    end

    context 'without plugin config' do
      it 'returns plugin params' do
        plugin.stubs(:enabled?).returns(false)
        expect(klass.recognized_params).to eq [:auth_host, :noninherited_method]
      end
    end
  end

  context "settings methods" do
    let(:aac) do
      aac = klass.new
      aac.auth_host = 'host'
      aac
    end

    before do
      plugin.stubs(:settings).returns(auth_host: 'ps',
                                      noninherited_method: 'hidden',
                                      renamed_setting: 'renamed')
    end

    context "with plugin config" do
      before do
        plugin.stubs(:enabled?).returns(true)
      end

      it 'uses settings from plugin' do
        expect(aac.auth_host).to eq 'ps'
      end

      it 'uses renamed settings from plugin' do
        expect(aac.noninherited_method).to eq 'renamed'
      end
    end

    context "without plugin config" do
      before do
        plugin.stubs(:enabled?).returns(false)
      end

      it 'uses settings from plugin' do
        expect(aac.auth_host).to eq 'host'
      end
    end
  end
end
