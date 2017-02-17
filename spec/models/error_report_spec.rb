#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ErrorReport do
  describe ".log_exception_from_canvas_errors" do
    it "should not fail with invalid UTF-8" do
      message = "he"
      message << 255.chr
      message << "llo"
      data = { extra: { message: message } }
      described_class.log_exception_from_canvas_errors('my error', data)
    end

    it "uses an empty hash as a default for errors with no extra data" do
      data = { tags: { a: "b" } }
      expect { described_class.log_exception_from_canvas_errors('my error', data) }.
        to_not raise_error
    end

    it "should use class name for category" do
      e = Exception.new("error")
      report = described_class.log_exception_from_canvas_errors(e, {extra:{}})
      expect(report.category).to eq(e.class.name)
    end


    it "ignores error classes that it's configured to overlook" do
      class ErrorReportSpecException < StandardError; end
      described_class.configure_to_ignore(["ErrorReportSpecException"])
      report = described_class.log_exception_from_canvas_errors(ErrorReportSpecException.new, {})
      expect(report).to be_nil
    end

    it "should plug together with Canvas::Errors::Info to log the user" do
      req = instance_double("request", request_method_symbol: "GET", format: "html")
      allow(Canvas::Errors::Info).to receive(:useful_http_env_stuff_from_request).
        and_return({})
      allow(Canvas::Errors::Info).to receive(:useful_http_headers).and_return({})
      user = instance_double("User", global_id: 5)
      err = Exception.new("error")
      info = Canvas::Errors::Info.new(req, Account.default, user, {})
      report = described_class.log_exception_from_canvas_errors(err, info.to_h)
      expect(report.user_id).to eq 5
    end
  end

  it "should return categories" do
    expect(ErrorReport.categories).to eq []
    ErrorReport.create! { |r| r.category = 'bob' }
    expect(ErrorReport.categories).to eq ['bob']
    ErrorReport.create! { |r| r.category = 'bob' }
    expect(ErrorReport.categories).to eq ['bob']
    ErrorReport.create! { |r| r.category = 'george' }
    expect(ErrorReport.categories).to eq ['bob', 'george']
    ErrorReport.create! { |r| r.category = 'fred' }
    expect(ErrorReport.categories).to eq ['bob', 'fred', 'george']
  end

  it "should filter the url when it is assigned" do
    report = ErrorReport.new
    report.url = "https://www.instructure.example.com?access_token=abcdef"
    expect(report.url).to eq "https://www.instructure.example.com?access_token=[FILTERED]"
  end

  it "should filter params" do
    mock_attrs = {
      :env => {
          "QUERY_STRING" => "access_token=abcdef&pseudonym[password]=zzz",
          "REQUEST_URI" => "https://www.instructure.example.com?access_token=abcdef&pseudonym[password]=zzz",
      },
      :remote_ip => "",
      :path_parameters => { :api_key => "1" },
      :query_parameters => { "access_token" => "abcdef", "pseudonym[password]" => "zzz" },
      :request_parameters => { "client_secret" => "xoxo" }
    }
    mock_attrs[:url] = mock_attrs[:env]["REQUEST_URI"]
    req = mock(mock_attrs)
    report = described_class.new
    report.assign_data(Canvas::Errors::Info.useful_http_env_stuff_from_request(req))
    expect(report.data["QUERY_STRING"]).to eq "?access_token=[FILTERED]&pseudonym[password]=[FILTERED]"

    expected_uri = "https://www.instructure.example.com?"\
      "access_token=[FILTERED]&pseudonym[password]=[FILTERED]"
    expect(report.data["REQUEST_URI"]).to eq(expected_uri)
    expect(report.data["path_parameters"]).to eq({ :api_key => "[FILTERED]" }.inspect)
    q_params = { "access_token" => "[FILTERED]", "pseudonym[password]" => "[FILTERED]" }
    expect(report.data["query_parameters"]).to eq(q_params.inspect)
    expect(report.data["request_parameters"]).to eq({ "client_secret" => "[FILTERED]" }.inspect)
  end

  it "should not try to assign protected fields" do
    report = described_class.new
    report.assign_data(id: 1)
    expect(report.id).to be_nil
    expect(report.data["id"]).to eq 1
  end
end
