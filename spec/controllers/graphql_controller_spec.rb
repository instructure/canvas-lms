
#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GraphQLController do
  before :once do
    student_in_course
  end

  context "graphiql" do
    it "requires a user" do
      get :graphiql
      expect(response.location).to match(/\/login$/)
    end

    it "works in production for normal users" do
      allow(Rails.env).to receive(:production?).and_return(true)
      user_session(@student)
      get :graphiql
      expect(response.status).to eq 200
    end

    it "works in production for site admins" do
      allow(Rails.env).to receive(:production?).and_return(true)
      site_admin_user(active_all: true)
      user_session(@user)
      get :graphiql
      expect(response.status).to eq 200
    end

    it "works" do
      user_session(@student)
      get :graphiql
      expect(response.status).to eq 200
    end
  end

  context "graphql, without a session" do
    it "requires a user" do
      post :execute, params: {query: "{}"}
      expect(response.location).to match(/\/login$/)
    end
  end

  context "graphql" do
    before { user_session(@student) }

    it "works" do
      post :execute, params: {query: "{}"}
      expect(JSON.parse(response.body)["errors"]).not_to be_blank
    end

    context "data dog metrics" do
      it "reports data dog metrics if requested" do
        expect(InstStatsd::Statsd).to receive(:increment).with("graphql.ASDF.count", tags: anything)
        request.headers["GraphQL-Metrics"] = "true"
        post :execute, params: {query: 'query ASDF { course(id: "1") { id } }'}
      end
    end
  end

  context "with release flag require_execute_auth disabled" do

    context "graphql, without a session" do
      it "works" do
        expect(Account.site_admin).to(
          receive(:feature_enabled?).with(:disable_graphql_authentication).and_return(true)
        )
        post :execute, params: {query: "{}"}
        expect(JSON.parse(response.body)["errors"]).not_to be_blank
      end
    end
  end

  context "datadog rest metrics" do
    require 'datadog/statsd'

    # this is the dumbest place to put this test except every where else i
    # could think of
    it "records datadog metrics if requested" do
      expect(InstStatsd::Statsd).to receive(:increment)
      get :graphiql, params: {datadog_metric: "this_is_a_test"}
    end

    it "doesn't normally datadog" do
      get :graphiql
      expect(InstStatsd::Statsd).not_to receive :increment
    end
  end
end
