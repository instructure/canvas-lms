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
      expect(template).to match(%r{An alert has been triggered})
    end
  end

  describe '#populate body' do
    it 'should save an html body if a template exists' do
      Message.any_instance.expects(:apply_html_template).returns('template')
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).to eq 'template'
    end

    it 'should sanitize html' do
      Message.any_instance.expects(:load_html_template).returns <<-ZOMGXSS
        <b>Your content</b>: <%= "<script>alert('haha')</script>" %>
      ZOMGXSS
      user         = user(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).not_to include "<script>"
      expect(message.html_body).to include "<b>Your content</b>: &lt;script&gt;alert(&#x27;haha&#x27;)&lt;/script&gt;"
    end
  end

  describe "parse!" do
    it "should use https when the domain is configured as ssl" do
      HostUrl.stubs(:protocol).returns("https")
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.body).to include('Account Admin')
      expect(msg.html_body).to include('Account Admin')
    end

    it "should have a sane body" do
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.html_body.scan(/<html>/).length).to eq 1
      expect(msg.html_body.index('<html>')).to eq 0
    end

    it "should not html escape the subject" do
      assignment_model(:title => "hey i have weird&<stuff> in my name but that's okay")
      msg = generate_message(:assignment_created, :email, @assignment)
      expect(msg.subject).to include(@assignment.title)
    end

    it "should not html escape the user_name" do
      course_with_teacher
      @teacher.name = "For some reason my parent's gave me a name with an apostrophe"
      @teacher.save!

      student1 = student_in_course.user
      student2 = student_in_course.user
      conversation = @teacher.initiate_conversation([student1], false)

      conversation.add_message("some message")
      event = conversation.add_participants([student2])
      msg = generate_message(:added_to_conversation, :email, event)

      expect(msg.subject).to include(@teacher.name)
    end

    it "displays a custom logo when configured" do
      account = account_model
      account.settings[:email_logo] = 'awesomelogo.jpg'
      @au = AccountUser.create(:account => account)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.html_body).to include('awesomelogo.jpg')
    end
  end

  context "named scopes" do
    it "should be able to get messages in any state" do
      m1 = message_model(:workflow_state => 'bounced', :user => user)
      m2 = message_model(:workflow_state => 'sent', :user => user)
      m3 = message_model(:workflow_state => 'sending', :user => user)
      expect(Message.in_state(:bounced)).to eq [m1]
      expect(Message.in_state([:bounced, :sent]).sort_by(&:id)).to eq [m1, m2].sort_by(&:id)
      expect(Message.in_state([:bounced, :sent])).not_to be_include(m3)
    end

    it "should be able to search on its context" do
      user_model
      message_model
      @message.update_attribute(:context, @user)
      expect(Message.for(@user)).to eq [@message]
    end

    it "should have a list of messages to dispatch" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'staged', :to => 'somebody', :user => user)
      expect(Message.to_dispatch).to eq [@message]
    end

    it "should not have a message to dispatch if the message's delay moves it to the future" do
      message_model(:dispatch_at => Time.now - 1, :to => 'somebody')
      @message.stage
      expect(Message.to_dispatch).to eq []
    end

    it "should filter on notification name" do
      notification_model(:name => 'Some Name')
      message_model(:notification_id => @notification.id)
      expect(Message.by_name('Some Name')).to eq [@message]
    end

    it "should offer staged messages (waiting to be dispatched)" do
      message_model(:dispatch_at => Time.now + 100, :user => user)
      expect(Message.staged).to eq [@message]
    end

    it "should have a list of messages that can be cancelled" do
      Message.any_instance.stubs(:stage_message)
      Message.workflow_spec.states.each do |state_symbol, state|
        Message.destroy_all
        message = message_model(:workflow_state => state_symbol.to_s, :user => user, :to => 'nobody')
        if state.events.any?{ |event_symbol, event| event.transitions_to == :cancelled }
          expect(Message.cancellable).to eq [message]
        else
          expect(Message.cancellable).to eq []
        end
      end
    end
  end

  it "should go back to the staged state if sending fails" do
    message_model(:dispatch_at => Time.now - 1, :workflow_state => 'sending', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user)
    @message.errored_dispatch
    expect(@message.workflow_state).to eq 'staged'
    expect(@message.dispatch_at).to be > Time.now + 4.minutes
  end

  describe "#deliver" do
    it "should not deliver if canceled" do
      message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
      @message.cancel
      @message.expects(:deliver_via_email).never
      Mailer.expects(:create_message).never
      expect(@message.deliver).to be_nil
      expect(@message.reload.state).to eq :cancelled
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
      expect(@message.deliver).to eq false
    end

    context 'push' do
      before :once do
        client = mock()
        client.stubs(:create_platform_endpoint => stub(:successful? => true,
                                                       :data => {:endpoint_arn => 'endpoint_arn'}),
                     :delete_endpoint => mock(),
                     :publish => mock())
        DeveloperKey.stubs(:sns).returns(stub(:client => client))
        dk = DeveloperKey.default
        dk.update_attribute(:sns_arn, 'app_arn')
        user_model
        @access_token = @user.access_tokens.create!(developer_key: dk)
      end

      it "deletes unreachable push endpoints" do
        @access_token.notification_endpoints.create!(user: @user, token: 'registration_token')
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :path_type => 'push', :user => @user)
        DeveloperKey.sns.client.publish.expects(:successful?).raises(AWS::SNS::Errors::EndpointDisabled)
        DeveloperKey.sns.client.expects(:delete_endpoint).with(endpoint_arn: 'endpoint_arn')
        @message.deliver
      end

      it "delivers to each of a user's push endpoints" do
        @access_token.notification_endpoints.create!(user: @user, token: 'registration_token1')
        @access_token.notification_endpoints.create!(user: @user, token: 'registration_token2')
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :path_type => 'push', :user => @user)
        DeveloperKey.sns.client.expects(:publish).twice.returns(stub(:successful? => true))
        @message.deliver
      end
    end
  end

  describe 'contextual messages' do
    let(:user1){ user_model(short_name: "David Brin") }
    let(:user2){ user_model(short_name: "Gareth Cutestory") }
    let(:course){ course_model }

    def build_conversation_message
      conversation = user1.initiate_conversation([user2])
      conversation.add_message("Some Long Message")
    end

    def build_submission
      assignment = course.assignments.new(:title => "some assignment")
      assignment.workflow_state = "published"
      assignment.save
      valid_attributes = {
        :assignment_id => assignment.id,
        :user_id => user1.id,
        :grade => "1.5",
        :url => "www.instructure.com"
      }
      Submission.create!(valid_attributes)
    end

    it 'can pull the short_name from the author' do
      submission = build_submission
      message = message_model(context: submission)
      expect(message.author_short_name).to eq user1.short_name
    end

    describe "infer_defaults" do
      it "should not break if there is no context" do
        message = message_model
        expect(message.root_account_id).to be_nil
        expect(message.root_account).to be_nil
        expect(message.reply_to_name).to be_nil
      end

      it "should not break if the context does not have an account" do
        user_model
        message = message_model(:context => @user)
        expect(message.root_account_id).to be_nil
        expect(message.reply_to_name).to be_nil
      end

      it "should populate root_account_id if the context can chain back to a root account" do
        message = message_model(:context => course_model)
        expect(message.root_account).to eq Account.default
      end

      it 'pulls the reply_to_name from the asset_context if there is one' do
        with_reply_to_name = build_conversation_message
        without_reply_to_name = course_model
        expect(message_model(asset_context: without_reply_to_name, context: without_reply_to_name).
          reply_to_name).to be_nil
        reply_to_message = message_model(asset_context: with_reply_to_name,
                                         context: with_reply_to_name,
                                         notification_name: "Conversation Message")
        expect(reply_to_message.reply_to_name).to eq "#{user1.short_name} via Canvas Notifications"
      end

      describe ":from_name" do
        it 'pulls from the asset_context if there is one' do
          convo_message = build_conversation_message
          message = message_model(:context => convo_message,
            :asset_context => convo_message, notification_name: "Conversation Message")
          expect(message.from_name).to eq user1.short_name
        end

        it "can differentiate when the context and asset_context are different" do
          submission = build_submission
          message = message_model(context: submission,
            asset_context: submission.context, notification_name: "Assignment Submitted")
          expect(message.from_name).to eq submission.user.short_name
        end

        it 'uses the default host url if the asset context wont override it' do
          message = message_model()
          expect(message.from_name).to eq HostUrl.outgoing_email_default_name
        end

        it 'uses the root_account override if there is one' do
          account = Account.default
          account.settings[:outgoing_email_default_name] = "OutgoingName"
          account.save!
          expect(account.reload.settings[:outgoing_email_default_name]).to eq "OutgoingName"
          mesage = message_model(:context => course_model)
          expect(message.from_name).to eq "OutgoingName"
        end

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
      expect(message.context_type).to eq "Quizzes::QuizRegradeRun"

      Message.where(id: message).update_all(context_type: 'QuizRegradeRun')

      expect(Message.find(message.id).context_type).to eq 'Quizzes::QuizRegradeRun'
    end

    it 'returns the correct representation of a quiz submission' do
      message = message_model
      submission = quiz_model.quiz_submissions.create!
      message.context = submission
      message.save
      expect(message.context_type).to eq 'Quizzes::QuizSubmission'

      Message.where(id: message).update_all(context_type: 'QuizSubmission')

      expect(Message.find(message.id).context_type).to eq 'Quizzes::QuizSubmission'
    end
  end

  describe '.asset_context_type' do
    it 'returns the correct representation of a quiz regrade run' do
      message = message_model
      regrade = Quizzes::QuizRegrade.create(:user_id => user_model.id, :quiz_id => quiz_model.id, :quiz_version => 1)
      regrade_run = Quizzes::QuizRegradeRun.create(quiz_regrade_id: regrade.id)

      message.asset_context = regrade_run
      message.save
      expect(message.asset_context_type).to eq "Quizzes::QuizRegradeRun"

      Message.where(id: message).update_all(asset_context_type: 'QuizRegradeRun')

      expect(Message.find(message.id).asset_context_type).to eq 'Quizzes::QuizRegradeRun'
    end

    it 'returns the correct representation of a quiz submission' do
      message = message_model
      submission = quiz_model.quiz_submissions.create!
      message.asset_context = submission
      message.save
      expect(message.asset_context_type).to eq 'Quizzes::QuizSubmission'

      Message.where(id: message).update_all(asset_context_type: 'QuizSubmission')

      expect(Message.find(message.id).asset_context_type).to eq 'Quizzes::QuizSubmission'
    end

  end

  describe "author interface" do
    let(:user) { user_model(short_name: "Jon Stewart", email: 'jon@example.com') }
    let(:authorless_message) { message_model(context: course_model(account: Account.default), context_type: 'Account', context_id: Account.default.id) }
    let(:conversation_participant) { user.initiate_conversation([user_model], nil, context_type: 'Account', context_id: Account.default.id) }
    let(:convo_message) { conversation_participant.add_message("Message!!!", root_account_id: Account.default.id) }
    let(:course) { course_model(account: Account.default) }

    it 'loads attributes from a user owned asset' do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      submission = submission_model(user: user, course: course)
      message = Message.create!(context: submission)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq user.email
      expect(message.author_avatar_url).to match /secure.gravatar.com/
    end

    it 'loads attributes from an author owned asset' do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq user.email
      expect(message.author_avatar_url).to match /secure.gravatar.com/
    end

    it "doesn't reveal the author's email address when the account setting is not set" do
      account = Account.default
      account.settings[:author_email_in_notifications] = false
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq nil
      expect(message.author_avatar_url).to match /secure.gravatar.com/
    end

    it 'doesnt break when there is no author' do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      expect(authorless_message.author_short_name).to be_nil
      expect(authorless_message.author_email_address).to be_nil
      expect(authorless_message.author_avatar_url).to be_nil
    end

    it "uses an absolute url for avatar src" do
      user.avatar_image_url = user.avatar_path
      user.save!
      message = Message.new(context: convo_message)
      expect(message.author_avatar_url).to eq "#{HostUrl.protocol}://#{HostUrl.context_host(user.account)}#{user.avatar_path}"
    end

    describe 'author_account' do
      it 'is nil if there is no author' do
        expect(authorless_message.author_account).to be_nil
      end

      it 'uses the root account if there is one' do
        message = Message.new(context: convo_message)
        message.root_account_id = Account.default.id
        expect(message.author_account).to eq Account.default
      end

      it 'uses the authors account if there is no root account' do
        acct = Account.new
        User.stubs(find: user)
        user.stubs(account: acct)
        conversation_message = ConversationMessage.new
        conversation_message.author_id = user.id
        message = Message.new(context: conversation_message)
        expect(message.author_account).to eq acct
      end
    end

    describe 'avatar_enabled?' do
      it 'is false when there is no author' do
        expect(authorless_message.avatar_enabled?).to be_falsey
      end

      it 'is true when the avatars service is enabled' do
        message = Message.new(context: convo_message)
        message.root_account_id = Account.default.id
        acct = Account.default
        Account.stubs(find: acct)
        acct.stubs(service_enabled?: true)
        message.root_account_id = Account.default.id
        expect(message.avatar_enabled?).to be_truthy
      end
    end
  end

end
