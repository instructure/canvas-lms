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

require 'spec_helper'

describe MessageBus::CaCert do

  let(:cert_location){ "/tmp/fake_pulsar_cert_#{SecureRandom.hex(3)}.pem" }
  let(:fake_vault_path){ 'fake/vault/path' }
  let(:conf_hash) do
    {
      'PULSAR_CERT_VAULT_PATH' => fake_vault_path,
      'PULSAR_CERT_PATH' => cert_location
    }
  end

  before(:each) do
    skip("pulsar config required to test") unless MessageBus.enabled?
    File.delete(cert_location) if File.exist?(cert_location)
    allow(Canvas::Vault).to receive(:read).with(fake_vault_path).and_return({
      certificate: "this-is-the-pulsar-cert-[NOT]"
    })
    LocalCache.cache.clear
  end

  after(:each) do
    LocalCache.cache.clear
    File.delete(cert_location) if File.exist?(cert_location)
  end

  it "gets any configured cert url to disk" do
    MessageBus::CaCert.ensure_presence!(conf_hash)
    expect(File.read(cert_location)).to eq("this-is-the-pulsar-cert-[NOT]")
  end

  it "won't fight with itself on cert writing" do
    File.delete(cert_location) if File.exist?(cert_location)
    expect(File.exist?(cert_location)).to be_falsey
    t1 = Thread.new do
      sleep(0.003)
      MessageBus::CaCert.ensure_presence!(conf_hash)
    end

    t2 = Thread.new do
      sleep(0.002)
      MessageBus::CaCert.ensure_presence!(conf_hash)
    end

    t3 = Thread.new do
      sleep(0.001)
      MessageBus::CaCert.ensure_presence!(conf_hash)
    end
    [t1, t2, t3].map(&:join)
    expect(File.read(cert_location)).to eq("this-is-the-pulsar-cert-[NOT]")
  end
end
