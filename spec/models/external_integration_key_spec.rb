# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe ExternalIntegrationKey do
  before(:once) do
    ExternalIntegrationKey.key_type :external_key0, label: "External Key 0", rights: proc { true }
    ExternalIntegrationKey.key_type :external_key1, label: proc { "External Key 1" }, rights: { write: false }
    ExternalIntegrationKey.key_type :external_key2, rights: { read: true, write: proc { false } }
    ExternalIntegrationKey.key_type :external_key3
  end

  let!(:key_type) { :external_key0 }
  let!(:account) { Account.create! }
  let!(:external_integration_key) do
    account.external_integration_keys.create!(
      key_type:,
      key_value: "42"
    )
  end

  context "key_types" do
    it "returns types constant values" do
      types = ExternalIntegrationKey.key_types
      expect(types).to include(:external_key0)
      expect(types).to include(:external_key1)
      expect(types).to include(:external_key2)
      expect(types).to include(:external_key3)
    end
  end

  context "type" do
    it "returns a symbol" do
      eik = ExternalIntegrationKey.new
      eik.key_type = key_type.to_s
      expect(eik.key_type).to eq key_type
    end
  end

  context "label_for" do
    it "returns the correct label" do
      expect(ExternalIntegrationKey.label_for(:external_key0)).to eq "External Key 0"
      expect(ExternalIntegrationKey.label_for(:external_key1)).to eq "External Key 1"
      expect(ExternalIntegrationKey.label_for(:external_key2)).to be_nil
      expect(ExternalIntegrationKey.label_for(:external_key3)).to be_nil
    end
  end

  context "keys of type" do
    it "returns scoped external integration keys of a type" do
      eik = ExternalIntegrationKey.new
      eik.context = account
      eik.key_type = "external_key2"
      eik.key_value = "12345a"
      eik.save!
      eik2 = ExternalIntegrationKey.new
      eik2.context = account
      eik2.key_type = "external_key3"
      eik2.key_value = "12345b"
      eik2.save!
      expect(ExternalIntegrationKey.of_type("external_key3").count).to eq 1
      expect(ExternalIntegrationKey.of_type("external_key3").first.id).to eq eik2.id
    end
  end

  context "indexed_keys_for" do
    it "returns a hash of external integration keys indexed by type" do
      hash = ExternalIntegrationKey.indexed_keys_for(account)
      ExternalIntegrationKey.key_types.each do |key_type|
        expect(hash[key_type].is_a?(ExternalIntegrationKey)).to be_truthy
      end
      expect(hash.keys.sort).to eq ExternalIntegrationKey.key_types.sort
      expect(hash[key_type]).to eq external_integration_key
    end
  end

  context "grants_right_for?" do
    it "calls keytype method for specified right" do
      external_integration_key.key_type = :external_key0
      expect(external_integration_key.grants_right?(user_factory, :read)).to be_truthy
      expect(external_integration_key.grants_right?(user_factory, :write)).to be_truthy
    end

    it "returns access determined by type" do
      external_integration_key.key_type = :external_key1
      expect(external_integration_key.grants_right?(user_factory, :read)).to be_falsey
      expect(external_integration_key.grants_right?(user_factory, :write)).to be_falsey

      external_integration_key.key_type = :external_key2
      expect(external_integration_key.grants_right?(user_factory, :read)).to be_truthy
      expect(external_integration_key.grants_right?(user_factory, :write)).to be_falsey
    end

    it "defaults to false when rights method does not exist" do
      external_integration_key.key_type = :external_key3
      expect(external_integration_key.grants_right?(user_factory, :read)).to be_falsey
      expect(external_integration_key.grants_right?(user_factory, :write)).to be_falsey
    end
  end

  it "can be validated within a new account" do
    account = Account.new
    eik = account.external_integration_keys.build(key_type:)

    expect do
      eik.key_value = "42"
    end.to change {
      account.valid?
    }.from(false).to(true)
  end
end
