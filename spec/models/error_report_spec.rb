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
      req = instance_double(ActionDispatch::Request, request_method_symbol: "GET", format: "html")
      allow(Canvas::Errors::Info).to receive_messages(useful_http_env_stuff_from_request: {},
                                                      useful_http_headers: {})
      user = instance_double(User, global_id: 5)
      err = Exception.new("error")
      info = Canvas::Errors::Info.new(req, Account.default, user, {})
      report = described_class.log_exception_from_canvas_errors(err, info.to_h)
      expect(report.user_id).to eq 5
    end

    it "doesn't save the error report when we're out of region" do
      req = instance_double(ActionDispatch::Request, request_method_symbol: "GET", format: "html")
      allow(Canvas::Errors::Info).to receive_messages(useful_http_env_stuff_from_request: {},
                                                      useful_http_headers: {})
      user = instance_double(User, global_id: 5)
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

  it "filters password reset params" do
    mock_attrs = {
      env: { "REQUEST_URI" => "https://www.example.instructure.com/profile" },
      remote_ip: "",
      url: "https://www.example.instructure.com/profile",
      path_parameters: { controller: "profile", action: "update" },
      query_parameters: {},
      request_parameters: { "pseudonym" =>
        { "old_password" => "elitepotato", "password" => "ghosthunter", "password_confirmation" => "ghosthunter" } }
    }
    req = double(mock_attrs)
    report = described_class.new
    report.assign_data(Canvas::Errors::Info.useful_http_env_stuff_from_request(req))

    expect(report.data["request_parameters"]).to eq(
      {
        "pseudonym" =>
          {
            "old_password" => "[FILTERED]",
            "password" => "[FILTERED]",
            "password_confirmation" => "[FILTERED]"
          }
      }.inspect
    )
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

  describe "#truncate_fields_for_external" do
    let(:error_report) { ErrorReport.new }

    it "truncates the URL if it is present" do
      error_report.url = "https://www.example.com/path?query=param&another_param=long_value&another_param=long_value \
                          &another_param=long_value&another_param=long_value&another_param=long_value \
                          &another_param=long_value&another_param=long_value&another_param=long_value"
      error_report.send(:truncate_fields_for_external)
      expect(error_report.url.length).to be <= ErrorReport.maximum_string_length
    end

    it "truncates the subject if it is present" do
      error_report.subject = "a" * 200
      error_report.send(:truncate_fields_for_external)
      expect(error_report.subject.length).to be <= ErrorReport.maximum_string_length
    end

    it "does not change the URL if it is not present" do
      error_report.url = nil
      error_report.send(:truncate_fields_for_external)
      expect(error_report.url).to be_nil
    end

    it "does not change the subject if it is not present" do
      error_report.subject = nil
      error_report.send(:truncate_fields_for_external)
      expect(error_report.subject).to be_nil
    end
  end

  describe "#truncate_query_params_in_url" do
    let(:error_report) { ErrorReport.new }

    it "returns the original URL if it is within the maximum length" do
      url = "https://www.example.com/path?query=param"
      expect(error_report.send(:truncate_query_params_in_url, url, 50)).to eq(url)
    end

    it "truncates the URL if it exceeds the maximum length" do
      url = "https://www.example.com/path?query=param&another_param=long_value"
      truncated_url = error_report.send(:truncate_query_params_in_url, url, 40)
      expect(truncated_url).to eq("https://www.example.com/path?query=param")
    end

    it "handles URLs without query parameters" do
      url = "https://www.example.com/path"
      expect(error_report.send(:truncate_query_params_in_url, url, 50)).to eq(url)
    end
  end

  describe "#normalize_user_roles" do
    let(:error_report) { ErrorReport.new }

    context "when user_roles is not present in data" do
      it "does nothing when user_roles key is missing" do
        error_report.data = { "other_key" => "value" }
        expect { error_report.send(:normalize_user_roles) }.not_to change { error_report.data }
      end
    end

    context "when user_roles is an Array" do
      it "joins array elements with commas" do
        error_report.data = { "user_roles" => %w[student teacher admin] }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,teacher,admin")
      end

      it "removes duplicates from array" do
        error_report.data = { "user_roles" => %w[student teacher admin student] }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,teacher,admin")
      end

      it "handles empty array" do
        error_report.data = { "user_roles" => [] }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("")
      end

      it "handles single element array" do
        error_report.data = { "user_roles" => %w[student] }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student")
      end
    end

    context "when user_roles is a Hash" do
      it "flattens hash values and joins with commas" do
        error_report.data = { "user_roles" => { "course_1" => %w[student], "course_2" => %w[teacher admin] } }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,teacher,admin")
      end

      it "removes duplicates from hash values" do
        error_report.data = { "user_roles" => { "course_1" => %w[student admin], "course_2" => %w[teacher admin] } }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,admin,teacher")
      end

      it "handles empty hash" do
        error_report.data = { "user_roles" => {} }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("")
      end

      it "handles hash with empty arrays" do
        error_report.data = { "user_roles" => { "course_1" => [], "course_2" => [] } }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("")
      end
    end

    context "when user_roles is a String" do
      it "leaves string unchanged" do
        error_report.data = { "user_roles" => "student,teacher" }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,teacher")
      end

      it "removes duplicates from comma-separated string" do
        error_report.data = { "user_roles" => "student,admin,teacher,admin" }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("student,admin,teacher")
      end

      it "handles empty string" do
        error_report.data = { "user_roles" => "" }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("")
      end
    end

    context "when user_roles is other types" do
      it "converts integer to string" do
        error_report.data = { "user_roles" => 123 }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("123")
      end

      it "converts nil to string" do
        error_report.data = { "user_roles" => nil }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("")
      end

      it "converts boolean to string" do
        error_report.data = { "user_roles" => true }
        error_report.send(:normalize_user_roles)
        expect(error_report.data["user_roles"]).to eq("true")
      end
    end
  end
end
