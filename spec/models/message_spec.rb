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
      template = msg.get_template('alert.email.erb')
      template.should match(%r{An alert has been triggered})
    end
  end

  describe '#populate body' do
    it 'should save an html body if a template exists' do
      Message.any_instance.expects(:apply_html_template).returns('template')
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      message.html_body.should == 'template'
    end

    it 'should sanitize html' do
      Message.any_instance.expects(:load_html_template).returns <<-ZOMGXSS
        <b>Your content</b>: <%= "<script>alert('haha')</script>" %>
      ZOMGXSS
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      message.html_body.should_not include "<script>"
      message.html_body.should include "<b>Your content</b>: &lt;script&gt;alert(&#x27;haha&#x27;)&lt;/script&gt;"
    end
  end

  describe "parse!" do
    it "should use https when the domain is configured as ssl" do
      HostUrl.stubs(:protocol).returns("https")
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      msg.body.should include('Account Admin')
      msg.html_body.should include('Account Admin')
    end

    it "should have a sane body" do
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      msg.html_body.scan(/<html>/).length.should == 1
      msg.html_body.index('<html>').should == 0
    end
  end

  context "named scopes" do
    it "should be able to get messages in any state" do
      m1 = message_model(:workflow_state => 'bounced', :user => user)
      m2 = message_model(:workflow_state => 'sent', :user => user)
      m3 = message_model(:workflow_state => 'sending', :user => user)
      Message.in_state(:bounced).should == [m1]
      Message.in_state([:bounced, :sent]).sort_by(&:id).should == [m1, m2].sort_by(&:id)
      Message.in_state([:bounced, :sent]).should_not be_include(m3)
    end

    it "should be able to search on its context" do
      user_model
      message_model
      @message.update_attribute(:context, @user)
      Message.for(@user).should == [@message]
    end

    it "should have a list of messages to dispatch" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'staged', :to => 'somebody', :user => user)
      Message.to_dispatch.should == [@message]
    end

    it "should not have a message to dispatch if the message's delay moves it to the future" do
      message_model(:dispatch_at => Time.now - 1, :to => 'somebody')
      @message.stage
      Message.to_dispatch.should == []
    end

    it "should filter on notification name" do
      notification_model(:name => 'Some Name')
      message_model(:notification_id => @notification.id)
      Message.by_name('Some Name').should == [@message]
    end

    it "should offer staged messages (waiting to be dispatched)" do
      message_model(:dispatch_at => Time.now + 100, :user => user)
      Message.staged.should == [@message]
    end

    it "should have a list of messages that can be cancelled" do
      Message.any_instance.stubs(:stage_message)
      Message.workflow_spec.states.each do |state_symbol, state|
        Message.destroy_all
        message = message_model(:workflow_state => state_symbol.to_s, :user => user, :to => 'nobody')
        if state.events.any?{ |event_symbol, event| event.transitions_to == :cancelled }
          Message.cancellable.should == [message]
        else
          Message.cancellable.should == []
        end
      end
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
        Mailer.expects(:create_message).never
        @message.deliver.should be_nil
        @message.reload.state.should == :cancelled
      end

      it "should log errors and raise based on error type" do
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:create_message).raises("something went wrong")
        ErrorReport.expects(:log_exception)
        expect { @message.deliver }.to raise_exception("something went wrong")

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:create_message).raises(Timeout::Error.new)
        ErrorReport.expects(:log_exception).never
        expect { @message.deliver }.to raise_exception(Timeout::Error)

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        Mailer.expects(:create_message).raises("450 recipient address rejected")
        ErrorReport.expects(:log_exception).never
        @message.deliver.should == false
      end
    end

    describe "infer_defaults" do
      it "should not break if there is no context" do
        message_model.root_account_id.should be_nil
      end

      it "should not break if the context does not have an account" do
        user_model
        message_model(:context => @user).root_account_id.should be_nil
      end

      it "should populate root_account_id if the context can chain back to a root account" do
        message_model(:context => course_model).root_account_id.should == Account.default.id
      end
    end

  end

  describe '.context_type' do
    it 'returns the correct representation of a quiz regrade run' do
      message = message_model
      regrade = Quizzes::QuizRegrade.create(:user_id => user_model.id, :quiz_id => quiz_model.id, :quiz_version => 1)
      regrade_run = Quizzes::QuizRegradeRun.create(quiz_regrade_id: regrade.id)

      message.context = regrade_run
      message.save
      message.context_type.should == "Quizzes::QuizRegradeRun"

      Message.where(id: message).update_all(context_type: 'QuizRegradeRun')

      Message.find(message.id).context_type.should == 'Quizzes::QuizRegradeRun'
    end

    it 'returns the correct representation of a quiz submission' do
      message = message_model
      submission = quiz_model.quiz_submissions.create!
      message.context = submission
      message.save
      message.context_type.should == 'Quizzes::QuizSubmission'

      Message.where(id: message).update_all(context_type: 'QuizSubmission')

      Message.find(message.id).context_type.should == 'Quizzes::QuizSubmission'
    end
  end

  describe '.asset_context_type' do
    it 'returns the correct representation of a quiz regrade run' do
      message = message_model
      regrade = Quizzes::QuizRegrade.create(:user_id => user_model.id, :quiz_id => quiz_model.id, :quiz_version => 1)
      regrade_run = Quizzes::QuizRegradeRun.create(quiz_regrade_id: regrade.id)

      message.asset_context = regrade_run
      message.save
      message.asset_context_type.should == "Quizzes::QuizRegradeRun"

      Message.where(id: message).update_all(asset_context_type: 'QuizRegradeRun')

      Message.find(message.id).asset_context_type.should == 'Quizzes::QuizRegradeRun'
    end

    it 'returns the correct representation of a quiz submission' do
      message = message_model
      submission = quiz_model.quiz_submissions.create!
      message.asset_context = submission
      message.save
      message.asset_context_type.should == 'Quizzes::QuizSubmission'

      Message.where(id: message).update_all(asset_context_type: 'QuizSubmission')

      Message.find(message.id).asset_context_type.should == 'Quizzes::QuizSubmission'
    end

  end

end
