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
end
