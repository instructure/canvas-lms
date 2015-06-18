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
  it "should send emails if configured" do
    account_model
    PluginSetting.create!(:name => 'error_reporting', :settings => {
      :action => 'email',
      :email => 'nobody@nowhere.com'
    })
    report = ErrorReport.new
    report.account = @account
    report.message = "test"
    report.subject = "subject"
    report.save!
    report.send_to_external
    m = Message.last
    expect(m).not_to be_nil
    expect(m.to).to eql("nobody@nowhere.com")
  end

  it "should not send emails if not configured" do
    account_model
    report = ErrorReport.new
    report.account = @account
    report.message = "test"
    report.subject = "subject"
    report.save!
    report.send_to_external
    m = Message.last
    expect(!!(m && m.to == "nobody@nowhere.com")).to eql(false)
  end

  it "should not fail with invalid UTF-8" do
    data = { extra: { message: "he\xffllo" } }
    described_class.log_exception_from_canvas_errors('my error', data)
  end

  it "uses an empty hash as a default for errors with no extra data" do
    data = { tags: { a: "b" } }
    expect { described_class.log_exception_from_canvas_errors('my error', data) }.
      to_not raise_error
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

  it "should use class name for category" do
    e = Exception.new("error")
    report = described_class.log_exception_from_canvas_errors(e, {extra:{}})
    expect(report.category).to eq(e.class.name)
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

end
