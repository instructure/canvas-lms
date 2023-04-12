# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe ErrorsController, type: :request do
  describe "reporting an error" do
    let(:path) { "/api/v1/error_reports" }

    let(:api_options) do
      {
        controller: "errors",
        action: "create",
        format: "json"
      }
    end

    before { user_with_pseudonym }

    it "processes a simple API request" do
      json = api_call :post, path, api_options, {
        error: {
          subject: "My Subject",
          email: "TestErrorsEmail@example.com",
          comments: "My Description"
        }
      }
      expect(json["logged"]).to be(true)
      expect(ErrorReport.last.email).to eq("TestErrorsEmail@example.com")
    end

    it "handles arbitrary metadata in the httpenv attribute" do
      json = api_call :post, path, api_options, {
        error: {
          subject: "My Subject",
          email: "TestErrorsEmail@example.com",
          comments: "My Description",
          http_env: {
            foo: "bar",
            meta: "data"
          }
        }
      }
      expect(json["logged"]).to be(true)
      report = ErrorReport.last
      expect(report.http_env["foo"]).to eq("bar")
      expect(report.http_env["meta"]).to eq("data")
    end
  end
end
