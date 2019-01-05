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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../messages/messages_helper')

describe Message do

  describe "#get_template" do
    it "should get the template with an existing file path" do
      allow(HostUrl).to receive(:protocol).and_return("https")
      au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, au)
      template = msg.get_template('alert.email.erb')
      expect(template).to match(%r{An alert has been triggered})
    end
  end

  describe '#populate body' do
    it 'should save an html body if a template exists' do
      expect_any_instance_of(Message).to receive(:apply_html_template).and_return('template')
      user         = user_factory(:active_all => true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).to eq 'template'
    end

    it 'should sanitize html' do
      expect_any_instance_of(Message).to receive(:load_html_template).and_return [<<-ZOMGXSS, 'template.html.erb']
        <b>Your content</b>: <%= "<script>alert()</script>" %>
      ZOMGXSS
      user         = user_factory(active_all: true)
      account_user = AccountUser.create!(:account => account_model, :user => user)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).not_to include "<script>"
      expect(message.html_body).to include "<b>Your content</b>: &lt;script&gt;alert()&lt;/script&gt;"
    end
  end

  describe "parse!" do
    it "should use https when the domain is configured as ssl" do
      allow(HostUrl).to receive(:protocol).and_return("https")
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.body).to include('Account Admin')
      expect(msg.html_body).to include('Account Admin')
    end

    it "should have a sane body" do
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.html_body.scan(/<html>/).length).to eq 1
      expect(msg.html_body.index('<!DOCTYPE')).to eq 0
    end

    it "should not html escape the subject" do
      assignment_model(:title => "hey i have weird&<stuff> in my name but that's okay")
      msg = generate_message(:assignment_created, :email, @assignment)
      expect(msg.subject).to include(@assignment.title)
    end

    it "should allow over 255 char in the subject" do
      assignment_model(title: 'this is crazy ridiculous '*10)
      msg = generate_message(:assignment_created, :email, @assignment)
      expect(msg.subject.length).to be > 255
    end

    it "should default to the account time zone if the user has no time zone" do
      original_time_zone = Time.zone
      Time.zone = 'UTC'
      course_with_teacher
      account = @course.account
      account.default_time_zone = 'Pretoria'
      account.save!
      due_at = Time.zone.parse('2014-06-06 11:59:59')
      assignment_model(course: @course, due_at: due_at)
      msg = generate_message(:assignment_created, :email, @assignment)

      presenter = Utils::DatetimeRangePresenter.new(due_at, nil, :event, ActiveSupport::TimeZone.new('Pretoria'))
      due_at_string = presenter.as_string(shorten_midnight: false)

      expect(msg.body.include?(due_at_string)).to eq true
      expect(msg.html_body.include?(due_at_string)).to eq true
      Time.zone = original_time_zone
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

    describe "course nicknames" do
      before(:once) do
        course_with_student(:active_all => true, :course_name => 'badly-named-course')
        @student.course_nicknames[@course.id] = 'student-course-nick'
        @student.save!
      end

      def check_message(message, asset)
        msg = generate_message(message, :email, asset, :user => @student)
        expect(msg.html_body).not_to include 'badly-named-course'
        expect(msg.html_body).to include 'student-course-nick'
        expect(@course.name).to eq 'badly-named-course'

        msg = generate_message(message, :email, asset, :user => @teacher)
        expect(msg.html_body).to include 'badly-named-course'
        expect(msg.html_body).not_to include 'student-course-nick'
      end

      it "applies nickname to asset" do
        check_message(:grade_weight_changed, @course)
      end

      it "applies nickname to asset.course" do
        check_message(:enrollment_registration, @student.enrollments.first)
      end

      it "applies nickname to asset.context" do
        check_message(:assignment_changed, @course.assignments.create!)
      end
    end
  end

  it "should raise an error when trying to re-save an existing message" do
    message_model
    @message.body = "something else"
    expect(@message.save).to be_falsey
  end

  it "should still set new attributes defined in workflow transitions" do
    message_model(:workflow_state => "sending", :user => user_factory)
    @message.complete_dispatch
    expect(@message.reload.workflow_state).to eq "sent"
    expect(@message.sent_at).to be_present
  end

  context "named scopes" do
    it "should be able to get messages in any state" do
      m1 = message_model(:workflow_state => 'bounced', :user => user_factory)
      m2 = message_model(:workflow_state => 'sent', :user => user_factory)
      m3 = message_model(:workflow_state => 'sending', :user => user_factory)
      expect(Message.in_state(:bounced)).to eq [m1]
      expect(Message.in_state([:bounced, :sent]).sort_by(&:id)).to eq [m1, m2].sort_by(&:id)
      expect(Message.in_state([:bounced, :sent])).not_to be_include(m3)
    end

    it "should be able to search on its context" do
      user_model
      message_model(:context => @user)
      expect(Message.for(@user)).to eq [@message]
    end

    it "should have a list of messages to dispatch" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'staged', :to => 'somebody', :user => user_factory)
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
      message_model(:dispatch_at => Time.now + 100, :user => user_factory)
      expect(Message.staged).to eq [@message]
    end

    it "should have a list of messages that can be cancelled" do
      allow_any_instance_of(Message).to receive(:stage_message)
      Message.workflow_spec.states.each do |state_symbol, state|
        Message.destroy_all
        message = message_model(:workflow_state => state_symbol.to_s, :user => user_factory, :to => 'nobody')
        if state.events.any?{ |event_symbol, event| event.transitions_to == :cancelled }
          expect(Message.cancellable).to eq [message]
        else
          expect(Message.cancellable).to eq []
        end
      end
    end
  end

  it "should go back to the staged state if sending fails" do
    message_model(:dispatch_at => Time.now - 1, :workflow_state => 'sending', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user_factory)
    @message.errored_dispatch
    expect(@message.workflow_state).to eq 'staged'
    expect(@message.dispatch_at).to be > Time.now + 4.minutes
  end

  describe "#deliver" do
    it "should not deliver if canceled" do
      message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user_factory, :path_type => 'email')
      @message.cancel
      expect(@message).to receive(:deliver_via_email).never
      expect(Mailer).to receive(:create_message).never
      expect(@message.deliver).to be_nil
      expect(@message.reload.state).to eq :cancelled
    end

    it "should log errors and raise based on error type" do
      message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user_factory, :path_type => 'email')
      expect(Mailer).to receive(:create_message).and_raise("something went wrong")
      expect(ErrorReport).to receive(:log_exception)
      expect { @message.deliver }.to raise_exception("something went wrong")

      message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user_factory, :path_type => 'email')
      expect(Mailer).to receive(:create_message).and_raise(Timeout::Error.new)
      expect(ErrorReport).to receive(:log_exception).never
      expect { @message.deliver }.to raise_exception(Timeout::Error)

      message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user_factory, :path_type => 'email')
      expect(Mailer).to receive(:create_message).and_raise("450 recipient address rejected")
      expect(ErrorReport).to receive(:log_exception).never
      expect(@message.deliver).to eq false
    end

    it "completes delivery without a user" do
      message = message_model({
        dispatch_at: Time.now,
        to: 'somebody',
        updated_at: Time.now.utc - 11.minutes,
        user: nil,
        path_type: 'email'
      })
      message.workflow_state = "staged"
      allow(Mailer).to receive(:create_message).and_return(double(deliver_now: "Response!"))
      expect(message.workflow_state).to eq("staged")
      expect{ message.deliver }.not_to raise_error
    end

    context 'push' do
      before :once do
        user_model
      end

      it "deletes unreachable push endpoints" do
        ne = double()
        expect(ne).to receive(:push_json).and_return(false)
        expect(ne).to receive(:destroy)
        expect(@user).to receive(:notification_endpoints).and_return([ne])

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :path_type => 'push', :user => @user)
        @message.deliver
      end

      it "delivers to each of a user's push endpoints" do
        ne = double()
        expect(ne).to receive(:push_json).twice.and_return(true)
        expect(ne).to receive(:destroy).never
        expect(@user).to receive(:notification_endpoints).and_return([ne, ne])

        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :path_type => 'push', :user => @user)
        @message.deliver
      end
    end

    context 'SMS' do
      before :once do
        user_model
        @user.account.enable_feature!(:international_sms)
      end

      before do
        allow(Canvas::Twilio).to receive(:enabled?).and_return(true)
      end

      it "uses Twilio for E.164 paths" do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: '+18015550100',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(Canvas::Twilio).to receive(:deliver).with('+18015550100', @message.body, from_recipient_country: true)
        expect(@message).to receive(:deliver_via_email).never
        @message.deliver
      end

      it "sends as email for email-ish paths" do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: 'foo@example.com',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(@message).to receive(:deliver_via_email)
        expect(Canvas::Twilio).to receive(:deliver).never
        @message.deliver
      end

      it "sends as email for paths that don't look like either email addresses or E.164 numbers" do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: 'bogus',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(@message).to receive(:deliver_via_email)
        expect(Canvas::Twilio).to receive(:deliver).never
        @message.deliver
      end

      it 'completes dispatch when successful' do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: '+18015550100',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(Canvas::Twilio).to receive(:deliver)
        @message.deliver
        @message.reload
        expect(@message.workflow_state).to eq('sent')
      end

      it 'cancels when Twilio raises an exception' do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: '+18015550100',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(Canvas::Twilio).to receive(:deliver).and_raise('some error')
        @message.deliver
        @message.reload
        expect(@message.workflow_state).to eq('cancelled')
      end

      it 'sends from recipient country' do
        message_model(
          dispatch_at: Time.now,
          workflow_state: 'staged',
          to: '+18015550100',
          updated_at: Time.now.utc - 11.minutes,
          path_type: 'sms',
          user: @user
        )
        expect(Canvas::Twilio).to receive(:deliver).with('+18015550100', anything, from_recipient_country: true)
        @message.deliver
        @message.reload
        expect(@message.workflow_state).to eq('sent')
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
        assignment_id: assignment.id,
        user_id: user1.id,
        grade: "1.5",
        grader: @teacher,
        url: "www.instructure.com"
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

      it 'pulls the reply_to_name from the asset if there is one' do
        with_reply_to_name = build_conversation_message
        without_reply_to_name = course_model
        expect(message_model(context: without_reply_to_name).
          reply_to_name).to be_nil
        reply_to_message = message_model(context: with_reply_to_name,
                                         notification_name: "Conversation Message")
        expect(reply_to_message.reply_to_name).to eq "#{user1.short_name} via Canvas Notifications"
      end

      describe ":from_name" do
        it 'pulls from the assets directly, if possible' do
          convo_message = build_conversation_message
          message = message_model(:context => convo_message, notification_name: "Conversation Message")
          expect(message.from_name).to eq user1.short_name
        end

        it "pulls from the asset's context, if possible" do
          assign = assignment_model
          notification = Notification.create(:name => 'Assignment Changed')
          message = message_model(:context => assign, notification: notification)
          expect(message.from_name).to eq assign.context.name
        end

        it 'uses the root_account override if there is one' do
          account = Account.default
          account.settings[:outgoing_email_default_name] = "OutgoingName"
          account.save!
          expect(account.reload.settings[:outgoing_email_default_name]).to eq "OutgoingName"
          message = message_model(:context => course_model)
          expect(message.from_name).to eq "OutgoingName"
        end

        it 'uses the default host url if the asset context wont override it' do
          message = message_model()
          expect(message.from_name).to eq HostUrl.outgoing_email_default_name
        end

        it 'uses a course nickname if exists' do
          assign = assignment_model
          user = user_model(preferences: { course_nicknames: { assign.context.id => 'nickname' }})
          notification = Notification.create(:name => 'Assignment Changed')
          message = message_model(:context => assign, notification: notification, user: user)
          expect(message.from_name).to eq 'nickname'
        end

        it 'uses a course appointment group if exists' do
          @account = Account.create!
          @account.settings[:allow_invitation_previews] = false
          @account.save!
          course_with_student(:account => @account, :active_all => true, :name => 'Unnamed Course')
          cat = @course.group_categories.create(:name => 'teh category')
          ag = appointment_group_model(:contexts => [@course], :sub_context => cat)
          assign = assignment_model
          @course.offer!
          user = user_model(preferences: { course_nicknames: { assign.context.id => 'test_course' }})
          user.register!
          enroll = @course.enroll_user(user)
          enroll.accept!
          notification = Notification.create(:name => 'Assignment Group Published')
          message = message_model(:context => ag, notification: notification, user: user)
          expect(message.from_name).to eq "Unnamed Course"
        end
      end
    end

    describe "#translate" do
      it "should work with an explicit key" do
        message = message_model
        message.get_template("new_discussion_entry.email.erb") # populate @i18n_scope
        message = message.translate(:key, "value %{link}", link: 'hi')
        expect(message).to eq "value hi"
      end

      it "should work with an implicit key" do
        message = message_model
        message.get_template("new_discussion_entry.email.erb") # populate @i18n_scope
        message = message.translate("value %{link}", link: 'hi')
        expect(message).to eq "value hi"
      end
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
      expect(message.author_avatar_url).to match 'http://localhost/images/messages/avatar-50.png'
    end

    it 'loads attributes from an author owned asset' do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq user.email
      expect(message.author_avatar_url).to match 'http://localhost/images/messages/avatar-50.png'
    end

    it "doesn't reveal the author's email address when the account setting is not set" do
      account = Account.default
      account.settings[:author_email_in_notifications] = false
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq nil
      expect(message.author_avatar_url).to match 'http://localhost/images/messages/avatar-50.png'
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
        allow(User).to receive(:find).and_return(user)
        allow(user).to receive(:account).and_return(acct)
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
        allow(Account).to receive(:find).and_return(acct)
        allow(acct).to receive(:service_enabled?).and_return(true)
        message.root_account_id = Account.default.id
        expect(message.avatar_enabled?).to be_truthy
      end
    end
  end

  it 'allows urls > 255 characters' do
    url = "a" * 256
    msg = Message.new
    msg.url = url
    msg.save!
  end

  describe "#context_context" do
    it "finds context for an assignment" do
      assign = assignment_model
      message = Message.new(context: assign)
      expect(message.context_context).to eq assign.context
    end

    it "finds context for a submission" do
      sub = submission_model
      message = Message.new(context: sub)
      expect(message.context_context).to eq sub.assignment.context
    end

    it "finds context for a discussion" do
      dt = discussion_topic_model
      message = Message.new(context: dt)
      expect(message.context_context).to eq dt.context
    end
  end
end
