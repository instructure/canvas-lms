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

require_relative "../messages/messages_helper"

describe Message do
  describe "#get_template" do
    it "gets the template with an existing file path" do
      allow(HostUrl).to receive(:protocol).and_return("https")
      au = AccountUser.create(account: account_model)
      msg = generate_message(:account_user_notification, :email, au)
      template = msg.get_template("alert.email.erb")
      expect(template).to match(/An alert has been triggered/)
    end
  end

  describe "#notification_targets" do
    it "returns an empty array when path_type is 'twitter' and no twitter service exists" do
      message_model(path_type: "twitter", user: user_factory(active_all: true))
      expect(@message.notification_targets).to eq []
    end
  end

  describe "#populate body" do
    it "saves an html body if a template exists" do
      expect_any_instance_of(Message).to receive(:apply_html_template).and_return("template")
      user         = user_factory(active_all: true)
      account_user = AccountUser.create!(account: account_model, user:)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).to eq "template"
    end

    it "sanitizes html" do
      expect_any_instance_of(Message).to receive(:load_html_template).and_return [<<~HTML, "template.html.erb"]
        <b>Your content</b>: <%= "<script>alert()</script>" %>
      HTML
      user         = user_factory(active_all: true)
      account_user = AccountUser.create!(account: account_model, user:)
      message      = generate_message(:account_user_notification, :email, account_user)

      expect(message.html_body).not_to include "<script>"
      expect(message.html_body).to include "<b>Your content</b>: &lt;script&gt;alert()&lt;/script&gt;"
    end
  end

  describe "parse!" do
    it "uses https when the domain is configured as ssl" do
      allow(HostUrl).to receive(:protocol).and_return("https")
      @au = AccountUser.create(account: account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.body).to include("Account Admin")
      expect(msg.html_body).to include("Account Admin")
    end

    it "has a sane body" do
      @au = AccountUser.create(account: account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.html_body.scan('<html dir="ltr" lang="en">').length).to eq 1
      expect(msg.html_body.index("<!DOCTYPE")).to eq 0
    end

    it "uses slack template if present" do
      @au = AccountUser.create(account: account_model)
      course_with_student
      alert = @course.alerts.create!(recipients: [:student],
                                     criteria: [
                                       criterion_type: "Interaction",
                                       threshold: 7
                                     ])
      mock_template = "slack template"
      expect_any_instance_of(Message).to receive(:get_template).with("alert.slack.erb").and_return(mock_template)
      msg = generate_message(:alert, :slack, alert)
      expect(msg.body).to eq mock_template
    end

    it "smses template if no slack template present" do
      @au = AccountUser.create(account: account_model)
      course_with_student
      alert = @course.alerts.create!(recipients: [:student],
                                     criteria: [
                                       criterion_type: "Interaction",
                                       threshold: 7
                                     ])
      mock_template = "sms template"
      expect_any_instance_of(Message).to receive(:get_template).with("alert.slack.erb").and_return(nil)
      expect_any_instance_of(Message).to receive(:get_template).with("alert.sms.erb").and_return(mock_template)
      msg = generate_message(:alert, :slack, alert)
      expect(msg.body).to eq mock_template
    end

    it "does not html escape the subject" do
      assignment_model(title: "hey i have weird&<stuff> in my name but that's okay")
      msg = generate_message(:assignment_created, :email, @assignment)
      expect(msg.subject).to include(@assignment.title)
    end

    it "allows over 255 char in the subject" do
      assignment_model(title: "this is crazy ridiculous " * 10)
      msg = generate_message(:assignment_created, :email, @assignment)
      expect(msg.subject.length).to be > 255
    end

    it "truncates the body if it exceeds the maximum text length" do
      allow(ActiveRecord::Base).to receive(:maximum_text_length).and_return(3)
      assignment_model(title: "this is a message")
      msg = generate_message(:assignment_created, :email, @assignment)
      msg.body = msg.body + ("1" * 64.kilobyte)
      expect(msg.valid?).to be_truthy
      expect(msg.body).to eq "message preview unavailable"
      msg.save!
      expect(msg.html_body).to eq "message preview unavailable"
    end

    it "defaults to the account time zone if the user has no time zone" do
      original_time_zone = Time.zone
      Time.zone = "UTC"
      course_with_teacher
      account = @course.account
      account.default_time_zone = "Pretoria"
      account.save!
      due_at = Time.zone.parse("2014-06-06 11:59:59")
      assignment_model(course: @course, due_at:)
      msg = generate_message(:assignment_created, :email, @assignment)

      presenter = Utils::DatetimeRangePresenter.new(due_at, nil, :event, ActiveSupport::TimeZone.new("Pretoria"))
      due_at_string = presenter.as_string(shorten_midnight: false)

      expect(msg.body.include?(due_at_string)).to be true
      expect(msg.html_body.include?(due_at_string)).to be true
      Time.zone = original_time_zone
    end

    it "does not html escape the user_name" do
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
      account.settings[:email_logo] = "awesomelogo.jpg"
      account.save!
      @au = AccountUser.create!(account:, user: user_model)
      msg = generate_message(:account_user_notification, :email, @au)
      expect(msg.html_body).to include("awesomelogo.jpg")
    end

    describe "course nicknames" do
      before(:once) do
        course_with_student(active_all: true, course_name: "badly-named-course")
        @student.set_preference(:course_nicknames, @course.id, "student-course-nick")
      end

      def check_message(message, asset)
        msg = generate_message(message, :email, asset, user: @student)
        expect(msg.html_body).not_to include "badly-named-course"
        expect(msg.html_body).to include "student-course-nick"
        expect(@course.name).to eq "badly-named-course"

        msg = generate_message(message, :email, asset, user: @teacher)
        expect(msg.html_body).to include "badly-named-course"
        expect(msg.html_body).not_to include "student-course-nick"
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

  describe "#author_avatar_url" do
    context "discussion entry and discussion_topic is anonymous" do
      it "returns correct url" do
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        message_model(context: @discussion_entry)

        expect(@topic).to be_anonymous
        expect(@message.author_avatar_url).to eq("https://canvas.instructure.com/images/messages/avatar-50.png")
      end
    end
  end

  describe "#author_short_name" do
    context "discussion entry and discussion_topic is anonymous" do
      it "returns discussion entry author_name" do
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        message_model(context: @discussion_entry)

        expect(@topic).to be_anonymous
        expect(@message.author_short_name).to eq(@discussion_entry.author_name)
      end
    end
  end

  describe "#infer_from_name" do
    context "discussion entry and discussion_topic is anonymous" do
      it "returns discussion entry author_name" do
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        message_model(context: @discussion_entry)

        expect(@topic).to be_anonymous
        expect(@message.from_name).to eq(@discussion_entry.author_name)
      end

      it "returns root account outgoing_email_default_name if message is inside a summary notification" do
        account = Account.default
        account.settings[:outgoing_email_default_name] = "The Root Account Default Name"
        account.save!
        expect(account.reload.settings[:outgoing_email_default_name]).to eq "The Root Account Default Name"
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        notification_model(name: "Summaries", category: "Summaries")
        message_model(context: @discussion_entry, notification_id: @notification.id, notification_name: "Summaries")
        expect(@topic).to be_anonymous
        expect(@message.from_name).to eq "The Root Account Default Name"
      end

      it "returns HostUrl outgoing_email_default_name if message is inside a summary notification" do
        HostUrl.outgoing_email_default_name = "The Host Url Default Name"
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        notification_model(name: "Summaries", category: "Summaries")
        message_model(context: @discussion_entry, notification_id: @notification.id, notification_name: "Summaries")
        expect(@topic).to be_anonymous
        expect(@message.from_name).to eq "The Host Url Default Name"
      end
    end
  end

  describe "#author_email_address" do
    context "discussion entry and discussion_topic is anonymous" do
      it "returns nil" do
        discussion_topic_model
        @topic.update(anonymous_state: "full_anonymity")
        @discussion_entry = @topic.discussion_entries.create!(user: user_model)
        message_model(context: @discussion_entry)

        expect(@topic).to be_anonymous
        expect(@message.author_email_address).to be_nil
      end
    end
  end

  it "raises an error when trying to re-save an existing message" do
    message_model
    @message.body = "something else"
    expect(@message.save).to be_falsey
  end

  it "still sets new attributes defined in workflow transitions" do
    message_model(workflow_state: "sending", user: user_factory)
    @message.complete_dispatch
    expect(@message.reload.workflow_state).to eq "sent"
    expect(@message.sent_at).to be_present
  end

  context "named scopes" do
    it "is able to get messages in any state" do
      m1 = message_model(workflow_state: "bounced", user: user_factory)
      m2 = message_model(workflow_state: "sent", user: user_factory)
      m3 = message_model(workflow_state: "sending", user: user_factory)
      expect(Message.in_state(:bounced)).to eq [m1]
      expect(Message.in_state([:bounced, :sent]).sort_by(&:id)).to eq [m1, m2].sort_by(&:id)
      expect(Message.in_state([:bounced, :sent])).not_to include(m3)
    end

    it "is able to search on its context" do
      user_model
      message_model(context: @user)
      expect(Message.for(@user)).to eq [@message]
    end

    it "has a list of messages to dispatch" do
      message_model(dispatch_at: Time.now - 1, workflow_state: "staged", to: "somebody", user: user_factory)
      expect(Message.to_dispatch).to eq [@message]
    end

    it "does not have a message to dispatch if the message's delay moves it to the future" do
      message_model(dispatch_at: Time.now - 1, to: "somebody")
      @message.stage
      expect(Message.to_dispatch).to eq []
    end

    it "filters on notification name" do
      notification_model(name: "Some Name")
      message_model(notification_id: @notification.id)
      expect(Message.by_name("Some Name")).to eq [@message]
    end

    it "offers staged messages (waiting to be dispatched)" do
      message_model(dispatch_at: Time.now + 100, user: user_factory)
      expect(Message.staged).to eq [@message]
    end

    it "has a list of messages that can be cancelled" do
      allow_any_instance_of(Message).to receive(:stage_message)
      Message.workflow_spec.states.each do |state_symbol, state|
        Message.destroy_all
        message = message_model(workflow_state: state_symbol.to_s, user: user_factory, to: "nobody")
        if state.events.any? { |_event_symbol, event| event.transitions_to == :cancelled }
          expect(Message.cancellable).to eq [message]
        else
          expect(Message.cancellable).to eq []
        end
      end
    end
  end

  it "goes back to the staged state if sending fails" do
    message_model(dispatch_at: Time.now - 1, workflow_state: "sending", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory)
    @message.errored_dispatch
    expect(@message.workflow_state).to eq "staged"
    expect(@message.dispatch_at).to be > Time.now + 4.minutes
  end

  describe "#deliver" do
    it "does not deliver if canceled" do
      message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
      @message.cancel
      expect(@message).not_to receive(:deliver_via_email)
      expect(Mailer).not_to receive(:create_message)
      expect(@message.deliver).to be_nil
      expect(@message.reload.state).to eq :cancelled
    end

    it "logs errors and raise based on error type" do
      message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
      expect(Mailer).to receive(:create_message).and_raise("something went wrong")
      expect(ErrorReport).to receive(:log_exception)
      expect { @message.deliver }.to raise_exception("something went wrong")

      message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
      expect(Mailer).to receive(:create_message).and_raise(Timeout::Error.new)
      expect(ErrorReport).not_to receive(:log_exception)
      expect { @message.deliver }.to raise_exception(Timeout::Error)

      message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
      expect(Mailer).to receive(:create_message).and_raise("450 recipient address rejected")
      expect(ErrorReport).not_to receive(:log_exception)
      expect(@message.deliver).to be false
    end

    describe "with notification service" do
      before do
        message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
        @user.account.enable_feature!(:notification_service)
      end

      it "enqueues to sqs when notification service is enabled" do
        expect(@message).to receive(:enqueue_to_sqs).and_return(true)
        @message.deliver
      end

      it "sends each target through the notification service" do
        expect(Services::NotificationService).to receive(:process).once
        @message.deliver
        expect(@message.workflow_state).to eq "sent"
      end

      it "sets transmission error on error" do
        error_string = "flagrant error"
        expect(Services::NotificationService).to receive(:process).and_raise(error_string)

        expect { @message.deliver }.to raise_error(error_string)
        expect(@message.workflow_state).to eq "staged"
        expect(@message.transmission_errors).to include(error_string)
      end
    end

    it "completes delivery without a user" do
      message = message_model({
                                dispatch_at: Time.now,
                                to: "somebody",
                                updated_at: Time.now.utc - 11.minutes,
                                user: nil,
                                path_type: "email"
                              })
      message.workflow_state = "staged"
      allow(Mailer).to receive(:create_message).and_return(double(deliver_now: "Response!"))
      expect(message.workflow_state).to eq("staged")
      expect { message.deliver }.not_to raise_error
    end

    it "logs stats on deliver" do
      allow(InstStatsd::Statsd).to receive(:increment)
      account = account_model
      @message = message_model(dispatch_at: Time.now - 1,
                               notification_name: "my_name",
                               workflow_state: "staged",
                               to: "somebody",
                               updated_at: Time.now.utc - 11.minutes,
                               path_type: "email",
                               user: @user,
                               root_account: account)
      expect(@message).to receive(:dispatch).and_return(true)
      @message.deliver
      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "message.deliver.email.my_name",
        {
          short_stat: "message.deliver",
          tags: { path_type: "email", notification_name: "my_name" }
        }
      )

      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "message.deliver.email.#{@message.root_account.global_id}",
        {
          short_stat: "message.deliver_per_account",
          tags: { path_type: "email", root_account_id: @message.root_account.global_id }
        }
      )
    end

    describe "#enqueue_to_sqs" do
      it "sets transmission error with no targets" do
        message_model(dispatch_at: Time.now, to: "somebody", workflow_state: "staged", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
        expect(@message).to receive(:notification_targets).and_return([])

        @message.enqueue_to_sqs
        expect(@message.workflow_state).to eq "transmission_error"
      end
    end

    context "push" do
      before :once do
        user_model
      end

      it "deletes unreachable push endpoints" do
        ne = double
        expect(ne).to receive(:push_json).and_return(false)
        expect(ne).to receive(:destroy)
        expect(@user).to receive(:notification_endpoints).and_return([ne])

        message_model(notification_name: "Assignment Created",
                      dispatch_at: Time.now,
                      workflow_state: "staged",
                      to: "somebody",
                      updated_at: Time.now.utc - 11.minutes,
                      path_type: "push",
                      user: @user)
        @message.deliver
      end

      it "delivers to each of a user's push endpoints" do
        ne = double
        expect(ne).to receive(:push_json).twice.and_return(true)
        expect(ne).not_to receive(:destroy)
        expect(@user).to receive(:notification_endpoints).and_return([ne, ne])

        message_model(notification_name: "Assignment Created",
                      dispatch_at: Time.now,
                      workflow_state: "staged",
                      to: "somebody",
                      updated_at: Time.now.utc - 11.minutes,
                      path_type: "push",
                      user: @user)
        @message.deliver
      end

      context "with the reduce_push_notifications settings" do
        it "allows whitelisted notification types" do
          message_model(
            dispatch_at: Time.now,
            workflow_state: "staged",
            updated_at: Time.now.utc - 11.minutes,
            path_type: "push",
            notification_name: "Assignment Created",
            user: @user
          )
          expect(@message).to receive(:deliver_via_push)
          @message.deliver
        end

        it "does not deliver notification types not on the whitelist" do
          message_model(
            dispatch_at: Time.now,
            workflow_state: "staged",
            updated_at: Time.now.utc - 11.minutes,
            path_type: "push",
            notification_name: "New Wiki Page",
            user: @user
          )
          expect(@message).not_to receive(:deliver_via_push)
          @message.deliver
        end
      end

      context "with the enable_push_notifications account setting disabled" do
        before do
          account = Account.default
          account.settings[:enable_push_notifications] = false
        end

        after do
          account = Account.default
          account.settings[:enable_push_notifications] = true
        end

        it "does not deliver notifications" do
          message_model(
            dispatch_at: Time.now,
            workflow_state: "staged",
            updated_at: Time.now.utc - 11.minutes,
            path_type: "push",
            notification_name: "New Wiki Page",
            user: @user
          )
          expect(@message).not_to receive(:deliver_via_push)
          @message.deliver
        end
      end
    end

    context "SMS" do
      before :once do
        user_model
        @user.account.enable_feature!(:international_sms)
      end

      before do
        allow(Canvas::Twilio).to receive(:enabled?).and_return(true)
      end

      it "doesn't allow sms notification" do
        message_model(
          dispatch_at: Time.zone.now,
          workflow_state: "staged",
          to: "+18015550100",
          updated_at: Time.now.utc - 11.minutes,
          path_type: "sms",
          notification_name: "Assignment Graded",
          user: @user
        )
        expect(@message).to_not receive(:deliver_via_sms)
        @message.deliver
      end
    end
  end

  describe "contextual messages" do
    let(:user1) { user_model(short_name: "David Brin") }
    let(:user2) { user_model(short_name: "Gareth Cutestory") }
    let(:course) { course_model }

    def build_conversation_message
      conversation = user1.initiate_conversation([user2])
      conversation.add_message("Some Long Message")
    end

    def build_submission
      assignment = course.assignments.new(title: "some assignment")
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

    it "can pull the short_name from the author" do
      submission = build_submission
      message = message_model(context: submission)
      expect(message.author_short_name).to eq user1.short_name
    end

    describe "infer_defaults" do
      it "does not break if there is no context" do
        message = message_model
        expect(message.root_account_id).to be_nil
        expect(message.root_account).to be_nil
        expect(message.reply_to_name).to be_nil
      end

      it "does not break if the context does not have an account" do
        user_model
        message = message_model(context: @user)
        expect(message.root_account_id).to be_nil
        expect(message.reply_to_name).to be_nil
      end

      it "populates root_account_id if the context can chain back to a root account" do
        message = message_model(context: course_model)
        expect(message.root_account).to eq Account.default
      end

      it "pulls the reply_to_name from the asset if there is one" do
        with_reply_to_name = build_conversation_message
        without_reply_to_name = course_model
        expect(message_model(context: without_reply_to_name)
          .reply_to_name).to be_nil
        reply_to_message = message_model(context: with_reply_to_name,
                                         notification_name: "Conversation Message")
        expect(reply_to_message.reply_to_name).to eq "#{user1.short_name} via Canvas Notifications"
      end

      describe ":from_name" do
        it "pulls from the assets directly, if possible" do
          convo_message = build_conversation_message
          message = message_model(context: convo_message, notification_name: "Conversation Message")
          expect(message.from_name).to eq user1.short_name
        end

        it "pulls from the asset's context, if possible" do
          assign = assignment_model
          notification = Notification.create(name: "Assignment Changed")
          message = message_model(context: assign, notification:)
          expect(message.from_name).to eq assign.context.name
        end

        it "uses the root_account override if there is one" do
          account = Account.default
          account.settings[:outgoing_email_default_name] = "OutgoingName"
          account.save!
          expect(account.reload.settings[:outgoing_email_default_name]).to eq "OutgoingName"
          message = message_model(context: course_model)
          expect(message.from_name).to eq "OutgoingName"
        end

        it "uses the default host url if the asset context wont override it" do
          message = message_model
          expect(message.from_name).to eq HostUrl.outgoing_email_default_name
        end

        it "uses a course nickname if exists" do
          assign = assignment_model
          user = user_model(preferences: { course_nicknames: { assign.context.id => "nickname" } })
          notification = Notification.create(name: "Assignment Changed")
          message = message_model(context: assign, notification:, user:)
          expect(message.from_name).to eq "nickname"
        end

        it "uses a course appointment group if exists" do
          @account = Account.create!
          @account.settings[:allow_invitation_previews] = false
          @account.save!
          course_with_student(account: @account, active_all: true, name: "Unnamed Course")
          cat = @course.group_categories.create(name: "teh category")
          ag = appointment_group_model(contexts: [@course], sub_context: cat)
          assign = assignment_model
          @course.offer!
          user = user_model(preferences: { course_nicknames: { assign.context.id => "test_course" } })
          user.register!
          enroll = @course.enroll_user(user)
          enroll.accept!
          notification = Notification.create(name: "Assignment Group Published")
          message = message_model(context: ag, notification:, user:)
          expect(message.from_name).to eq "Unnamed Course"
        end
      end
    end

    describe "#translate" do
      it "works with an explicit key" do
        message = message_model
        message.get_template("new_discussion_entry.email.erb") # populate @i18n_scope
        message = message.translate(:key, "value %{link}", link: "hi")
        expect(message).to eq "value hi"
      end

      it "works with an implicit key" do
        message = message_model
        message.get_template("new_discussion_entry.email.erb") # populate @i18n_scope
        message = message.translate("value %{link}", link: "hi")
        expect(message).to eq "value hi"
      end
    end

    describe "cross-shard urls" do
      specs_require_sharding

      it "uses relative ids in links of message body" do
        @shard2.activate do
          @c = Course.create!(account: Account.create!)
          @a = @c.assignments.create!
          @announcement = @c.announcements.create!(message: "<p>added assignment</p>\r\n<p><a title=\"assa\" href=\"/courses/#{@c.id}/assignments/#{@a.id}\"title</a></p>", title: "title")
        end
        @shard1.activate do
          @shard1_account = Account.create!(name: "new acct")
          expect_any_instance_of(Message).to receive(:link_root_account).at_least(:once).and_return(@shard1_account)
          message = generate_message("New Announcement", "email", @announcement)
          parts = message.body.split("/courses/").second.split("/assignments/")
          expect(parts.first.split("~")).to eq [@shard2.id.to_s, @c.local_id.to_s]
          expect(parts.last.split(")").first.split("~")).to eq [@shard2.id.to_s, @a.local_id.to_s]
        end
      end
    end
  end

  describe "author interface" do
    let(:user) { user_model(short_name: "Jon Stewart", email: "jon@example.com") }
    let(:authorless_message) { message_model(context: course_model(account: Account.default), context_type: "Account", context_id: Account.default.id) }
    let(:conversation_participant) { user.initiate_conversation([user_model], nil, context_type: "Account", context_id: Account.default.id) }
    let(:convo_message) { conversation_participant.add_message("Message!!!", root_account_id: Account.default.id) }
    let(:course) { course_model(account: Account.default) }

    it "loads attributes from a user owned asset" do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      submission = submission_model(user:, course:)
      message = Message.create!(context: submission)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq user.email
      expect(message.author_avatar_url).to match "http://localhost/images/messages/avatar-50.png"
    end

    it "loads attributes from an author owned asset" do
      account = Account.default
      account.settings[:author_email_in_notifications] = true
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to eq user.email
      expect(message.author_avatar_url).to match "http://localhost/images/messages/avatar-50.png"
    end

    it "doesn't reveal the author's email address when the account setting is not set" do
      account = Account.default
      account.settings[:author_email_in_notifications] = false
      account.save!
      message = Message.create!(context: convo_message)
      expect(message.author_short_name).to eq user.short_name
      expect(message.author_email_address).to be_nil
      expect(message.author_avatar_url).to match "http://localhost/images/messages/avatar-50.png"
    end

    it "doesnt break when there is no author" do
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

    it "encodes a user's avatar_url when just a path" do
      user.avatar_image_url = "path with spaces"
      user.save!
      message = Message.new(context: convo_message)
      expect(message.author_avatar_url).to eq "#{HostUrl.protocol}://#{HostUrl.context_host(user.account)}/path%20with%20spaces"
    end

    it "encodes a user's avatar_url when a url" do
      user.avatar_image_url = "http://localhost/path with spaces"
      user.save!
      message = Message.new(context: convo_message)
      expect(message.author_avatar_url).to eq "http://localhost/path%20with%20spaces"
    end

    describe "author_account" do
      it "is nil if there is no author" do
        expect(authorless_message.author_account).to be_nil
      end

      it "uses the root account if there is one" do
        message = Message.new(context: convo_message)
        message.root_account_id = Account.default.id
        expect(message.author_account).to eq Account.default
      end

      it "uses the authors account if there is no root account" do
        acct = Account.new
        allow(User).to receive(:find).and_return(user)
        allow(user).to receive(:account).and_return(acct)
        conversation_message = ConversationMessage.new
        conversation_message.author_id = user.id
        message = Message.new(context: conversation_message)
        expect(message.author_account).to eq acct
      end
    end

    describe "avatar_enabled?" do
      it "is false when there is no author" do
        expect(authorless_message.avatar_enabled?).to be_falsey
      end

      it "is true when the avatars service is enabled" do
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

  it "allows urls > 255 characters" do
    url = "a" * 256
    msg = Message.new
    msg.url = url
    expect { msg.save! }.to_not raise_error
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

  describe "Message.in_partition" do
    let(:partition) { { "created_at" => DateTime.new(2020, 8, 25) } }

    it "uses the specific partition table" do
      expect(Message.in_partition(partition).to_sql).to match(/^SELECT "messages_2020_35".* FROM .*"messages_2020_35"$/)
    end

    it "can be chained" do
      expect(Message.in_partition(partition).where(id: 3).to_sql).to match(/^SELECT "messages_2020_35".* FROM .*"messages_2020_35" WHERE "messages_2020_35"."id" = 3$/)
    end

    it "has no side-effects on other scopes" do
      expect(Message.in_partition(partition).unscoped.to_sql).to match(/^SELECT "messages".* FROM .*"messages"$/)
    end
  end

  describe "for_queue" do
    it "has a clear error path for messages that are missing" do
      queued = Message.new(id: -1, created_at: Time.zone.now).for_queue
      begin
        queued.deliver
        raise "#deliver should have failed because this message does not exist"
      rescue Delayed::RetriableError => e
        expect(e.cause.is_a?(Message::QueuedNotFound)).to be_truthy
      end
    end
  end

  describe ".infer_feature_account" do
    it "is the root account for the message when available" do
      ra = account_model
      message = Message.new(root_account: ra)
      expect(message.send(:infer_feature_account)).to eq(ra)
    end

    it "is the user's account if the RA is a dummy account" do
      Account.ensure_dummy_root_account
      root_account = Account.find(0)
      user_account = Account.default
      user = user_model
      message = Message.new(root_account_id: root_account.id, user:)
      expect(message.send(:infer_feature_account)).to eq(user_account)
    end

    it "falls back to siteadmin" do
      message = Message.new(root_account_id: nil, user_id: nil)
      expect(message.send(:infer_feature_account)).to eq(Account.site_admin)
    end
  end
end
