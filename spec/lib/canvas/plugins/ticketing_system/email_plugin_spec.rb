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
  describe EmailPlugin do
    describe "#export_error" do
      let(:ticketing) { double }
      let(:plugin) { EmailPlugin.new(ticketing) }
      let(:email_address) { "to-address@example.com" }
      let(:config) { { email_address: } }
      let(:report) do
        double(
          email: "from-address@example.com",
          to_document: {},
          raw_report: double,
          account_id: nil
        )
      end

      it "sends an email to the address in the configuration" do
        expect(Message).to receive(:create!).with(include(to: email_address))
        plugin.export_error(report, config)
      end

      it "uses the email from the error_report as the from address" do
        expect(Message).to receive(:create!).with(include(from: report.email))
        plugin.export_error(report, config)
      end

      it "uses the un-wrapped error-report for the mail context" do
        raw_report = ErrorReport.new
        wrapped_report = CustomError.new(raw_report)
        expect(Message).to receive(:create!).with(include(context: raw_report))
        plugin.export_error(wrapped_report, config)
      end

      it "carries through the account if the error report has one" do
        raw_report = ErrorReport.new
        account = Account.create!
        raw_report.account = account
        wrapped_report = CustomError.new(raw_report)
        message = plugin.export_error(wrapped_report, config)
        expect(message.root_account).to eq(account)
      end

      it "sends valid json as the body, with http_env" do
        raw_report = ErrorReport.new
        raw_report.http_env = {
          "HTTP_ACCEPT" => "application/json, text/javascript, application/json+canvas-string-ids, */*; q=0.01",
          "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
          "HTTP_HOST" => "localhost:3000",
          "HTTP_REFERER" => "http://localhost:3000/",
          "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36",
          "PATH_INFO" => "/error_reports",
          "QUERY_STRING" => "?",
          "REQUEST_METHOD" => "POST",
          "REQUEST_PATH" => "/error_reports",
          "REQUEST_URI" => "http://localhost:3000/error_reports",
          "SERVER_NAME" => "localhost",
          "SERVER_PORT" => "3000",
          "SERVER_PROTOCOL" => "HTTP/1.1",
          "REMOTE_ADDR" => "127.0.0.1",
          "path_parameters" => "{:action=>\"create\", :controller=>\"errors\"}",
          "query_parameters" => "{}",
          "request_parameters" => "{\"error\"=>{\"url\"=>\"http://localhost:3000/\", \"comments\"=>\"It just went to the dashboard\"}}"
        }
        wrapped_report = CustomError.new(raw_report)
        message = plugin.export_error(wrapped_report, config)
        expect { JSON.parse(message.body) }.not_to raise_error
      end
    end
  end
end
