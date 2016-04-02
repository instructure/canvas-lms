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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe ConditionalRelease::Service do
  Service = ConditionalRelease::Service

  def stub_config(*configs)
    ConfigFile.stubs(:load).returns(*configs)
  end

  def clear_config
    Service.reset_config_cache
  end

  before(:each) do
    clear_config
  end

  it 'is disabled by default' do
    stub_config(nil)
    expect(Service.enabled?).to be_falsy
  end

  it 'has a default config' do
    stub_config(nil)
    config = Service.config
    expect(config).not_to be_nil
    expect(config.size).to be > 0
  end

  it 'defaults protocol to canvas protocol' do
    HostUrl.stubs(:protocol).returns('foo')
    stub_config(nil)
    expect(Service.protocol).to eq('foo')
  end

  it 'overrides defaults with config file' do
    stub_config(nil, {protocol: 'foo'})
    expect(Service.config[:protocol]).not_to eql('foo')
    clear_config
    expect(Service.config[:protocol]).to eql('foo')
  end

  it 'creates urls' do
    stub_config({
      protocol: 'foo', host: 'bar',
      configure_defaults_app_path: 'some/path'
    })
    expect(Service.configure_defaults_url).to eq 'foo://bar/some/path'
  end
end
