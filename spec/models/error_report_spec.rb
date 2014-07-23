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
    m.should_not be_nil
    m.to.should eql("nobody@nowhere.com")
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
    (!!(m && m.to == "nobody@nowhere.com")).should eql(false)
  end

  it "should not fail with invalid UTF-8" do
    ErrorReport.log_error('my error', :message => "he\xffllo")
  end

  it "should return categories" do
    ErrorReport.categories.should == []
    ErrorReport.create! { |r| r.category = 'bob' }
    ErrorReport.categories.should == ['bob']
    ErrorReport.create! { |r| r.category = 'bob' }
    ErrorReport.categories.should == ['bob']
    ErrorReport.create! { |r| r.category = 'george' }
    ErrorReport.categories.should == ['bob', 'george']
    ErrorReport.create! { |r| r.category = 'fred' }
    ErrorReport.categories.should == ['bob', 'fred', 'george']
  end

  it "should filter the url when it is assigned" do
    report = ErrorReport.new
    report.url = "https://www.instructure.example.com?access_token=abcdef"
    report.url.should == "https://www.instructure.example.com?access_token=[FILTERED]"
  end

  it "should use class name for category" do
    report = ErrorReport.log_exception(nil, e = Exception.new("error"))
    report.category.should == e.class.name
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
    report = ErrorReport.new
    report.assign_data(ErrorReport.useful_http_env_stuff_from_request(req))
    report.data["QUERY_STRING"].should == "?access_token=[FILTERED]&pseudonym[password]=[FILTERED]"
    report.data["REQUEST_URI"].should == "https://www.instructure.example.com?access_token=[FILTERED]&pseudonym[password]=[FILTERED]"
    report.data["path_parameters"].should == { :api_key => "[FILTERED]" }.inspect
    report.data["query_parameters"].should == { "access_token" => "[FILTERED]", "pseudonym[password]" => "[FILTERED]" }.inspect
    report.data["request_parameters"].should == { "client_secret" => "[FILTERED]" }.inspect
  end
end
