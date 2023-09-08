# frozen_string_literal: true

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

RSpec.describe SentryTraceScrubber, :rack do
  let(:uri) { "https://my-host.com" }
  let(:default_options) { { HTTP_SENTRY_TRACE: "8ee36e389f474d74bf28d36b6a254d31-a9e542af8c94d1dc-1" } }
  let(:stack) { described_class.new(->(_) { [200, {}, ["okay"]] }) }

  context "when the referrer is same-origin" do
    let(:env) { Rack::MockRequest.env_for(uri, default_options.merge({ ENV_REFERRER: "my-host.com" })) }

    it "leaves the sentry-trace header" do
      stack.call(env)

      expect(env["HTTP_SENTRY_TRACE"]).to eq(default_options["HTTP_SENTRY_TRACE"])
    end
  end

  context "when the referrer is cross-origin" do
    let(:env) { Rack::MockRequest.env_for(uri, default_options.merge({ ENV_REFERRER: "not-my-host.com" })) }

    it "deletes the sentry-trace header" do
      stack.call(env)

      expect(env["HTTP_SENTRY_TRACE"]).to be_nil
    end
  end

  context "when the referrer is missing" do
    let(:env) { Rack::MockRequest.env_for(uri, default_options) }

    it "deletes the sentry-trace header" do
      stack.call(env)

      expect(env["HTTP_SENTRY_TRACE"]).to be_nil
    end
  end
end
