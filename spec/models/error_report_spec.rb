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

describe ErrorReport do
  describe ".log_exception_from_canvas_errors" do
    it "does not fail with invalid UTF-8" do
      message = "he" +
                255.chr +
                "llo"
      data = { extra: { message: } }
      expect { described_class.log_exception_from_canvas_errors("my error", data) }
        .to_not raise_error
    end

    it "uses an empty hash as a default for errors with no extra data" do
      data = { tags: { a: "b" } }
      expect { described_class.log_exception_from_canvas_errors("my error", data) }
        .to_not raise_error
    end

    it "uses class name for category" do
      e = Exception.new("error")
      report = described_class.log_exception_from_canvas_errors(e, { extra: {} })
      expect(report.category).to eq(e.class.name)
    end

    it "ignores category 404" do
      count = ErrorReport.count
      ErrorReport.log_error("404", {})
      expect(ErrorReport.count).to eq(count)
    end

    it "ignores error classes that it's configured to overlook" do
      stub_const("ErrorReportSpecException", Class.new(StandardError))
      described_class.configure_to_ignore(["ErrorReportSpecException"])
      report = described_class.log_exception_from_canvas_errors(ErrorReportSpecException.new, {})
      expect(report).to be_nil
    end

    it "plugs together with Canvas::Errors::Info to log the user" do
      req = instance_double("request", request_method_symbol: "GET", format: "html")
      allow(Canvas::Errors::Info).to receive_messages(useful_http_env_stuff_from_request: {},
                                                      useful_http_headers: {})
      user = instance_double("User", global_id: 5)
      err = Exception.new("error")
      info = Canvas::Errors::Info.new(req, Account.default, user, {})
      report = described_class.log_exception_from_canvas_errors(err, info.to_h)
      expect(report.user_id).to eq 5
    end

    it "doesn't save the error report when we're out of region" do
      req = instance_double("request", request_method_symbol: "GET", format: "html")
      allow(Canvas::Errors::Info).to receive_messages(useful_http_env_stuff_from_request: {},
                                                      useful_http_headers: {})
      user = instance_double("User", global_id: 5)
      err = Exception.new("error")
      info = Canvas::Errors::Info.new(req, Account.default, user, {})
      expect(Shard.current).to receive(:in_current_region?).and_return(false)
      report = described_class.log_exception_from_canvas_errors(err, info.to_h)
      expect(report).to be_nil
    end
  end

  it "returns categories" do
    expect(ErrorReport.categories).to eq []
    ErrorReport.create! { |r| r.category = "bob" }
    expect(ErrorReport.categories).to eq ["bob"]
    ErrorReport.create! { |r| r.category = "bob" }
    expect(ErrorReport.categories).to eq ["bob"]
    ErrorReport.create! { |r| r.category = "george" }
    expect(ErrorReport.categories).to eq ["bob", "george"]
    ErrorReport.create! { |r| r.category = "fred" }
    expect(ErrorReport.categories).to eq %w[bob fred george]
  end

  it "filters the url when it is assigned" do
    report = ErrorReport.new
    report.url = "https://www.instructure.example.com?access_token=abcdef"
    expect(report.url).to eq "https://www.instructure.example.com?access_token=[FILTERED]"
  end

  it "filters params" do
    mock_attrs = {
      env: {
        "QUERY_STRING" => "access_token=abcdef&pseudonym[password]=zzz",
        "REQUEST_URI" => "https://www.instructure.example.com?access_token=abcdef&pseudonym[password]=zzz",
      },
      remote_ip: "",
      path_parameters: { api_key: "1" },
      query_parameters: { "access_token" => "abcdef", "pseudonym[password]" => "zzz" },
      request_parameters: { "client_secret" => "xoxo" }
    }
    mock_attrs[:url] = mock_attrs[:env]["REQUEST_URI"]
    req = double(mock_attrs)
    report = described_class.new
    report.assign_data(Canvas::Errors::Info.useful_http_env_stuff_from_request(req))
    expect(report.data["QUERY_STRING"]).to eq "?access_token=[FILTERED]&pseudonym[password]=[FILTERED]"

    expected_uri = "https://www.instructure.example.com?" \
                   "access_token=[FILTERED]&pseudonym[password]=[FILTERED]"
    expect(report.data["REQUEST_URI"]).to eq(expected_uri)
    expect(report.data["path_parameters"]).to eq({ api_key: "[FILTERED]" }.inspect)
    q_params = { "access_token" => "[FILTERED]", "pseudonym[password]" => "[FILTERED]" }
    expect(report.data["query_parameters"]).to eq(q_params.inspect)
    expect(report.data["request_parameters"]).to eq({ "client_secret" => "[FILTERED]" }.inspect)
  end

  it "does not try to assign protected fields" do
    report = described_class.new
    report.assign_data(id: 1)
    expect(report.id).to be_nil
    expect(report.data["id"]).to eq 1
  end

  it "truncates absurdly long messages" do
    report = described_class.new
    long_message = (0...100_000).map { "a" }.join
    report.assign_data(message: long_message)
    expect(report.message.length).to eq long_message.length
    report.save!
    expect(report.message.length).to be < long_message.length
  end

  describe "#safe_url?" do
    it "allows a 'normal' URL" do
      report = described_class.new
      report.url = "https://canvas.instructure.com/courses/1?enrollment_uuid=abc"
      expect(report.safe_url?).to be true
    end

    it "sanitizes javascript" do
      report = described_class.new
      report.url = "javascript:window.close()"
      expect(report.safe_url?).to be false
    end

    it "sanitizes ftp" do
      report = described_class.new
      report.url = "ftp://badserver.com/somewhere"
      expect(report.safe_url?).to be false
    end

    it "sanitizes something that's not a URI at all" do
      report = described_class.new
      report.url = "<bogus>"
      expect(report.safe_url?).to be false
    end
  end
end
