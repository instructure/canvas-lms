# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require "webmock/rspec"

describe ImmersiveReaderController do
  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.enable_net_connect!
  end

  it "requires a user be logged in" do
    get "authenticate"
    assert_unauthorized
  end

  it "requires the plugin be configured" do
    user_model
    user_session(@user)
    get "authenticate"
    assert_status(404)
  end

  it "authenticates with cognitive services" do
    user_model
    user_session(@user)
    stub_request(:post, "https://login.windows.net")
    allow(controller).to receive(:ir_config).and_return(
      {
        tenant_id: "faketenantid",
        client_id: "fakeclientid",
        client_secret: "fakesecret",
        subdomain: "fakesub"
      }
    )
    get "authenticate"
    expect(WebMock).to have_requested(:post, "https://login.windows.net/faketenantid/oauth2/token")
      .with(
        body:
          "grant_type=client_credentials&client_id=fakeclientid&client_secret=fakesecret&resource=https%3A%2F%2Fcognitiveservices.azure.com%2F",
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )
      .once
  end

  context "when the token request fails" do
    let_once(:user) { user_model }

    let(:response_body) { { error_description: "Some error" }.to_json }

    before do
      stub_request(
        :post,
        "https://login.windows.net/faketenantid/oauth2/token"
      ).to_return(
        status: 401,
        body: response_body,
        headers: {}
      )

      user_session(user)

      allow(controller).to receive(:ir_config).and_return(
        {
          tenant_id: "faketenantid",
          client_id: "fakeclientid",
          client_secret: "fakesecret",
          subdomain: "fakesub"
        }
      )
    end

    shared_examples_for "contexts_with_a_captured_exception" do
      it "captures the error" do
        expect(Canvas::Errors).to receive(:capture_exception).with(
          :immersive_reader,
          instance_of(ImmersiveReaderController::ServiceError),
          :warn
        )

        get "authenticate"
      end

      it "increments the error counter" do
        allow(InstStatsd::Statsd).to receive(:increment)

        expect(InstStatsd::Statsd).to receive(:increment).with(
          "immersive_reader.authentication_failure",
          tags: { status: "401" }
        )

        get "authenticate"
      end
    end

    it_behaves_like "contexts_with_a_captured_exception"

    context "and the response has an empty body" do
      let(:response_body) { "" }

      it_behaves_like "contexts_with_a_captured_exception"
    end
  end
end
