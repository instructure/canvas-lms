# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../lti_1_3_spec_helper"

class ApiRouteSetSpecController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def action_with_foobar_id
    render plain: "Action With Foobar Id: #{params[:foobar_id]}"
  end

  def action_with_foobar_id_plus_something
    render plain: "Action With Foobar Id Something: #{params[:foobar_id]}"
  end

  def action_with_id
    render plain: "Action With Id: #{params[:id]}"
  end

  def action_with_nonid
    render plain: "Action With Nonid: #{params[:some_param]}"
  end
end

RSpec.describe ApiRouteSet, type: :request do
  let(:app) { Class.new(Rails::Application) }

  before do
    allow(Rails).to receive(:application).and_return(app)
  end

  describe "a route drawn using ApiRouteSet::V1.draw { ... }" do
    before do
      app.routes.draw do
        ApiRouteSet::V1.draw(self) do
          scope(controller: :api_route_set_spec) do
            get "foobars/:foobar_id", action: "action_with_foobar_id", as: :action_with_foobar_id
            get "foobars/:foobar_id/something", action: "action_with_foobar_id_plus_something", as: :action_with_foobar_id_plus_something
            get "foobars2/:id", action: "action_with_id", as: :action_with_id

            get "nonid/:some_param", action: "action_with_nonid", as: :action_with_nonid
          end
        end
      end
    end

    def expect_no_route_matches(url)
      get(url.to_s)
      expect(response).to_not be_successful
    end

    def expect_route_matches(url, expected_response)
      get url.to_s
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(expected_response)
    end

    describe "id parameters (named 'id' or 'foo_id')" do
      it "doesn't allow slashes" do
        expect_no_route_matches "/api/v1/foobars/foo/bar"
        expect_no_route_matches "/api/v1/foobars/foo/bar/something"
        expect_no_route_matches "/api/v1/foobars2/foo/bar"
        expect_route_matches "/api/v1/foobars/foo/something", "Action With Foobar Id Something: foo"
      end

      it "doesn't allow question marks (treats as query string)" do
        expect_route_matches "/api/v1/foobars/foo?bar", "Action With Foobar Id: foo"
        expect_route_matches "/api/v1/foobars/foo?bar/something", "Action With Foobar Id: foo"
        expect_route_matches "/api/v1/foobars2/foo?bar", "Action With Id: foo"
      end

      # NOTE: this test demonstrates previous behavior, but we may not always want to special-case
      # this .json suffix. Also, it just won't parse .json if the id is in the
      # middle of a path, e.g. "foobars/foo.json/something".
      it "treats .json as a format if the id is the last part of the path" do
        expect_route_matches "/api/v1/foobars/foo.json", "Action With Foobar Id: foo"
        expect_route_matches "/api/v1/foobars2/foo.json", "Action With Id: foo"
      end

      it "allows periods" do
        expect_route_matches "/api/v1/foobars/foo.bar", "Action With Foobar Id: foo.bar"
        expect_route_matches "/api/v1/foobars/foo.bar/something", "Action With Foobar Id Something: foo.bar"
        expect_route_matches "/api/v1/foobars2/foo.bar", "Action With Id: foo.bar"
      end

      it "allows slashes, question marks, and periods when CGI-escaped" do
        expect_route_matches "/api/v1/foobars/foo%2F%3F%2Ewaz", "Action With Foobar Id: foo/?.waz"
        expect_route_matches "/api/v1/foobars/foo%2F%3F%2Ewaz/something", "Action With Foobar Id Something: foo/?.waz"
        expect_route_matches "/api/v1/foobars2/foo%2F%3F%2Ewaz", "Action With Id: foo/?.waz"
      end

      it "allows constructing URLs with ids with slashes and question marks (escaping them)" do
        expect(app.routes.url_helpers.api_v1_action_with_foobar_id_path(foobar_id: "foo/?.waz")).to \
          eq("/api/v1/foobars/foo%2F%3F.waz")
        expect(app.routes.url_helpers.api_v1_action_with_foobar_id_plus_something_path(foobar_id: "foo/?.waz")).to \
          eq("/api/v1/foobars/foo%2F%3F.waz/something")
        expect(app.routes.url_helpers.api_v1_action_with_id_path(id: "foo/?.waz")).to \
          eq("/api/v1/foobars2/foo%2F%3F.waz")
      end
    end

    describe "non-id parameters (Rails defaults)" do
      it "doesn't allow slashes, question marks, or periods" do
        expect_no_route_matches "/api/v1/nonid/foo/bar"
        expect_route_matches "/api/v1/nonid/foo?bar", "Action With Nonid: foo"
        expect_route_matches "/api/v1/nonid/foo.json", "Action With Nonid: foo"
        expect_route_matches "/api/v1/nonid/foo-bar", "Action With Nonid: foo-bar"
      end

      it "allows constructing URLs with ids with slashes and question marks (escaping them)" do
        expect(app.routes.url_helpers.api_v1_action_with_nonid_path(some_param: "foo/?waz")).to \
          eq("/api/v1/nonid/foo%2F%3Fwaz")
      end
    end
  end

  describe "a route with constraints NOT drawn using ApiRouteSet::V1.draw { ... }" do
    before do
      app.routes.draw do
        scope(controller: :anonymous) do
          get "foobars/:foobar_id",
              action: "action_with_foobar_id",
              as: :action_with_foobar_id,
              constraints: { foobar_id: %r{[^/\?]+} }
        end
      end
    end

    # NOTE: if https://github.com/rails/rails/issues/43466 is ever addressed,
    # and the ConstraintsBugHackRequirements monkey-patch becomes unnecessary,
    # it's possible this test may start failing. That is, depending on how the
    # Rails team addresses the issue, they could conceivably allow the call to
    # some_route_path() in this test to construct a URL and not raise an error:
    # at which point our monkey patch would be unnecessary.
    it "still takes into effect the parameter constraints when constructing URLs" do
      expect do
        app.routes.url_helpers.action_with_foobar_id_path(foobar_id: "foo/bar?baz")
      end.to raise_error(ActionController::UrlGenerationError)
    end
  end
end
