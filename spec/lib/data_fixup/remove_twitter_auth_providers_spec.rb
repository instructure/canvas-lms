# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe DataFixup::RemoveTwitterAuthProviders do
  before do
    class ::AuthenticationProvider::Twitter < AuthenticationProvider; end # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration, Lint/EmptyClass
    allow(AuthenticationProvider).to receive(:find_sti_class).and_return(AuthenticationProvider::Twitter)

    @account = Account.create
    @auth_provider = @account.authentication_providers.new(auth_type: "twitter", workflow_state: "active")
    @auth_provider.save(validate: false)
    @pseudonym = @auth_provider.pseudonyms.create!(unique_id: "melon@husk", user: User.create!)
  ensure
    AuthenticationProvider.send :remove_const, :Twitter # rubocop:disable RSpec/RemoveConst
  end

  it "removes the auth providers" do
    expect(AuthenticationProvider.where(auth_type: "twitter").active).to eq([@auth_provider])
    DataFixup::RemoveTwitterAuthProviders.run
    expect(AuthenticationProvider.where(auth_type: "twitter").active).to eq([])
  end

  it "removes the pseudonyms" do
    expect(Pseudonym.where(authentication_provider_id: @auth_provider.id).active).to eq([@pseudonym])
    DataFixup::RemoveTwitterAuthProviders.run
    expect(Pseudonym.where(authentication_provider_id: @auth_provider.id).active).to eq([])
  end

  it "removes pseudos of deleted auth providers too" do
    DataFixup::RemoveTwitterAuthProviders.run
    expect(AuthenticationProvider.where(auth_type: "twitter").active).to eq([])
    expect(Pseudonym.where(authentication_provider_id: @auth_provider.id).active).to eq([])
    pseudonym = @auth_provider.pseudonyms.create!(unique_id: "phony.stark@x.com", user: User.create!)
    expect(Pseudonym.where(authentication_provider_id: @auth_provider.id).active).to eq([pseudonym])
    DataFixup::RemoveTwitterAuthProviders.run
    expect(Pseudonym.where(authentication_provider_id: @auth_provider.id).active).to eq([])
  end
end
