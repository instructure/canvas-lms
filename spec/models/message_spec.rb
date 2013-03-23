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
require File.expand_path(File.dirname(__FILE__) + '/../messages/messages_helper')

describe Message do

  describe "#get_template" do
    it "should get the template with an existing file path" do
      HostUrl.stubs(:protocol).returns("https")
      au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, au)
      file_path = File.expand_path(File.join(RAILS_ROOT, 'app', 'messages', 'alert.email.erb'))
      template = msg.get_template(file_path)
      template.should match(%r{Account Admin Notification})
    end
  end

  describe '#populate body' do
    it 'should generate a body' do
      HostUrl.stubs(:protocol).returns('https')
      user = user(:active_all => true)
      au   = AccountUser.create(:account => account_model, :user => user)
      msg  = generate_message(:account_user_notification, :email, au)
      msg.populate_body('this is a test', 'email', msg.send(:binding))
      msg.body.should eql('this is a test')
    end

    it 'should not save an html body by default' do
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      message.html_body.should be_nil
    end

    it 'should save an html body if a template exists' do
      Message.any_instance.expects(:load_html_template).returns('template')
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      message.html_body.should == 'template'
    end
  end

  describe "parse!" do
    it "should use https when the domain is configured as ssl" do
      HostUrl.stubs(:protocol).returns("https")
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      msg.body.should include('Account Admin')
    end
  end

  context "named scopes" do
    it "should be able to get messages in any state" do
      m1 = message_model(:workflow_state => 'bounced', :user => user)
      m2 = message_model(:workflow_state => 'sent', :user => user)
      m3 = message_model(:workflow_state => 'sending', :user => user)
      Message.in_state(:bounced).should eql([m1])
      Message.in_state([:bounced, :sent]).sort_by(&:id).should eql([m1, m2].sort_by(&:id))
      Message.in_state([:bounced, :sent]).should_not be_include(m3)
    end
    
    it "should be able to search on its context" do
      user_model
      message_model
      @message.update_attribute(:context, @user)
      Message.for(@user).should eql([@message])
    end
    
    it "should have a list of messages to dispatch" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'staged', :to => 'somebody', :user => user)
      Message.to_dispatch.should eql([@message])
    end
    
    it "should not have a message to dispatch if the message's delay moves it to the future" do
      message_model(:dispatch_at => Time.now - 1, :to => 'somebody')
      @message.stage
      Message.to_dispatch.should eql([])
    end
    
    it "should filter on notification name" do
      notification_model(:name => 'Some Name')
      message_model(:notification_id => @notification.id)
      Message.by_name('Some Name').should eql([@message])
    end

    it "should offer staged messages (waiting to be dispatched)" do
      message_model(:dispatch_at => Time.now + 100, :user => user)
      Message.staged.should eql([@message])
    end

    it "should go back to the staged state if sending fails" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'sending', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user)
      @message.errored_dispatch
      @message.workflow_state.should == 'staged'
      @message.dispatch_at.should > Time.now + 4.minutes
    end

    describe "#deliver" do
      it "should not deliver if canceled" do
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        @message.cancel
        @message.expects(:deliver_via_email).never
        Mailer.expects(:deliver_message).never
        @message.deliver.should be_nil
        @message.reload.state.should == :cancelled
      end

      it "should log errors and raise based on error type" do
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:deliver_message).raises("something went wrong")
        ErrorReport.expects(:log_exception)
        expect { @message.deliver }.to raise_exception("something went wrong")

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:deliver_message).raises(Timeout::Error.new)
        ErrorReport.expects(:log_exception).never
        expect { @message.deliver }.to raise_exception(Timeout::Error)

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:deliver_message).raises("450 recipient address rejected")
        ErrorReport.expects(:log_exception).never
        @message.deliver.should == false
      end
    end
  end
end
