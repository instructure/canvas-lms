# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::UpdateDeveloperKeyScopes do
  # Trying to actually change the routes once they were already created was
  # causing flakiness. So, create TWO rails applications with their own sets
  # of routes, and switch between them to pretend like we've changed routes.rb.
  let(:application) { CanvasRails::Application.new }
  let(:changed_routes_application) { CanvasRails::Application.new }

  before do
    application.routes.draw do
      get "/api/v1/courses" => "courses#index"
      get "/api/v1/users" => "users#index"
      get "/api/v1/accounts" => "accounts#index"
    end

    changed_routes_application.routes.draw do
      get "/api/v1/courses_changed" => "courses#index"
      get "/api/v1/users_changed" => "users#index"
      get "/api/v1/accounts" => "accounts#index"
    end
  end

  it "changes developer key scopes in batches" do
    expect(Rails.application).to receive(:routes).and_return(application.routes)
    TokenScopes.instance_variable_set(:@_api_routes, nil)
    TokenScopes.instance_variable_set(:@_all_scopes, nil)

    dk = DeveloperKey.create!(
      scopes: [
        "url:GET|/api/v1/courses",
        "url:GET|/api/v1/users",
        "url:GET|/api/v1/accounts"
      ]
    )

    # Simulate someone committing a change to routes.rb, with an
    # accompanying data fixup.
    expect(Rails.application).to receive(:routes).and_return(changed_routes_application.routes)
    TokenScopes.instance_variable_set(:@_api_routes, nil)
    TokenScopes.instance_variable_set(:@_all_scopes, nil)

    scopes_to_change = {
      "url:GET|/api/v1/courses" => "url:GET|/api/v1/courses_changed",
      "url:GET|/api/v1/users" => "url:GET|/api/v1/users_changed",
    }
    expect(DataFixup::UpdateDeveloperKeyScopes).to receive(:scope_changes)
      .at_least(:once)
      .and_return(scopes_to_change)

    DataFixup::UpdateDeveloperKeyScopes.run
    expect(dk.reload.scopes).to eq(
      [
        "url:GET|/api/v1/courses_changed",
        "url:GET|/api/v1/users_changed",
        "url:GET|/api/v1/accounts"
      ]
    )
  end

  # If there is a developer key with an invalid scope that is
  it "skips over developer keys that have an unexpected invalid scope" do
    dk = DeveloperKey.create!
    dk.scopes = [
      "url:GET|/api/v1/courses",
      "url:GET|/api/v1/invalid_endpoint"
    ]
    dk.save(validate: false)

    scopes_to_change = {
      "url:GET|/api/v1/courses" => "url:GET|/api/v1/courses_changed"
    }
    expect(DataFixup::UpdateDeveloperKeyScopes).to receive(:scope_changes)
      .at_least(:once)
      .and_return(scopes_to_change)

    expect do
      DataFixup::UpdateDeveloperKeyScopes.run
    end.not_to raise_error

    # We should have just skipped over this one, leaving the original scopes unchanged.
    expect(dk.reload.scopes).to eq(
      [
        "url:GET|/api/v1/courses",
        "url:GET|/api/v1/invalid_endpoint"
      ]
    )
  end
end
