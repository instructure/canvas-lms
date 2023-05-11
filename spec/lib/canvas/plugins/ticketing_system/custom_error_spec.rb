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

module Canvas::Plugins::TicketingSystem
  describe CustomError do
    let(:report) { ErrorReport.new }
    let(:delegate) { CustomError.new(report) }

    describe "#to_document" do
      it "translates an error_report to a json-able hash" do
        expect(delegate.to_document).to eq({ subject: nil,
                                             description: nil,
                                             report_type: "ERROR",
                                             error_message: nil,
                                             perceived_severity: "",
                                             account_id: nil,
                                             account_domain: nil,
                                             report_origin_url: nil,
                                             reporter: { canvas_id: "",
                                                         email: "unknown-unknowndomain-example-com@instructure.example.com",
                                                         name: "Unknown User",
                                                         role: nil,
                                                         become_user_uri: nil,
                                                         environment: nil },
                                             canvas_details: { request_context_id: nil, error_report_id: nil, sub_account: nil } })
      end
    end

    describe "#sub_account_tag" do
      let(:asset_manager) { double }

      it "prefixes the account_id with subaccount" do
        report.data["context_asset_string"] = "42"
        context = double(account_id: "123")
        allow(asset_manager).to receive(:find_by_asset_string).with("42").and_return(context)
        expect(delegate.sub_account_tag(asset_manager, context.class))
          .to eq("subaccount_123")
      end

      # since Course is the expected type, we just need to NOT send
      # a type override
      it "returns nil if the context isnt the expected type" do
        report.data["context_asset_string"] = "42"
        context = double(account_id: "123")
        allow(asset_manager).to receive(:find_by_asset_string).with("42").and_return(context)
        expect(delegate.sub_account_tag(asset_manager)).to be_nil
      end

      it "returns nil with no asset string" do
        expect(delegate.sub_account_tag(asset_manager)).to be_nil
      end
    end

    describe "#report_type" do
      it "extracts the type from the backtrace" do
        report.backtrace = "Posted as _PROBLEM_"
        expect(delegate.report_type).to eq("PROBLEM")
      end

      it "defaults to ERROR if there is no backtrace" do
        report.backtrace = nil
        expect(delegate.report_type).to eq("ERROR")
      end

      it "defaults to ERROR if the backtrace isnt regular" do
        report.backtrace = "NOT Your message"
        expect(delegate.report_type).to eq("ERROR")
      end
    end

    describe "#user_severity" do
      it "passes through the data value" do
        report.data["user_perceived_severity"] = "bad"
        expect(delegate.user_severity).to eq("bad")
      end

      it "defaults to a blank string" do
        report.data = nil
        expect(delegate.user_severity).to eq("")
      end
    end

    describe "#user_roles" do
      it "passes through the data value" do
        report.data["user_roles"] = "teacher"
        expect(delegate.user_roles).to eq("teacher")
      end

      it "defaults to a blank string" do
        report.data = nil
        expect(delegate.user_roles).to be_nil
      end
    end

    describe "#account_domain_value" do
      it "uses the domain off the account attribute" do
        allow(report).to receive_messages(account: double(domain: "www.example.com"))
        expect(delegate.account_domain_value).to eq("www.example.com")
      end

      it "is nil if no account" do
        report.account = nil
        expect(delegate.account_domain_value).to be_nil
      end
    end

    describe "#user_name" do
      it "uses the name off the user attribute" do
        allow(report).to receive_messages(user: double(name: "Stanley Stanleyson"))
        expect(delegate.user_name).to eq("Stanley Stanleyson")
      end

      it "is nil if no account" do
        report.user = nil
        expect(delegate.user_name).to eq("Unknown User")
      end
    end

    describe "#become_user_id_uri" do
      it "is nil if there's no url or user" do
        expect(delegate.become_user_id_uri).to be_nil
      end

      it "transforms the url into one that targets the user for reproduction" do
        report.url = "http://something.com/path"
        report.user_id = 42
        output_url = "http://something.com/path?become_user_id=42"
        expect(delegate.become_user_id_uri).to eq(output_url)
      end

      it "gives a resonable message when it cant parse the url" do
        report.url = "totes not ^ a URI something.com/path"
        report.user_id = 42
        output_url = "unable to parse uri: totes not ^ a URI something.com/path"
        expect(delegate.become_user_id_uri).to eq(output_url)
      end
    end

    describe "#pretty_http_env" do
      it "is nil if theres no http_env" do
        expect(delegate.pretty_http_env).to be_nil
      end

      it "maps an env hash to a json string" do
        report.http_env = { one: "two", three: "four" }
        expect(delegate.pretty_http_env).to eq(%(one: "two"\nthree: "four"))
      end
    end
  end
end
